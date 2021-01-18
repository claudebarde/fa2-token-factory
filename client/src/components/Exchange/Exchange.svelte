<script lang="ts">
  import { onMount } from "svelte";
  import store from "../../store";
  import { OrderEntry, UserToken } from "../../types";
  import Modal from "../Modal/Modal.svelte";
  import Order from "./Order.svelte";
  import { displayTokenAmount } from "../../utils";
  import ViewTransaction from "../Modal/ViewTransaction.svelte";

  let tokenToBuy: number = 0;
  let tokenToBuyAmount: string = "";
  let tokenToSell: number = 0;
  let tokenToSellAmount: string = "";
  let buyWTK: string = "";
  let redeemWTK: string = "";
  let loadingBuyWtk = false;
  let loadingRedeemWtk = false;
  let loadingConfirmNewOrder = false;
  let openBuyWtkModal = false;
  let openRedeemWtkModal = false;
  let openConfirmNewOrder = false;
  let openDeleteOrder = false;
  let openFulfillOrder = false;
  let viewTxToast = false;
  let opHash = "";

  const displayMaxAmount = (tokenID: number): string => {
    const token = $store.userTokens.filter(tk => tk.tokenID === tokenID)[0];
    if (token) {
      const balance = displayTokenAmount(token.tokenID, token.balance);

      return "Max: " + balance.toString();
    } else {
      return "";
    }
  };

  const getTokenSymbol = (tokenID: number): string => {
    if ($store.tokens.length === 0) return "N/A";

    const token = $store.tokens.filter(tk => tk.tokenID === tokenID);
    if (token.length === 0) return "N/A";
    if (!token[0].symbol) return "N/A";

    return token[0].symbol;
  };

  const buyXtzWrapper = () => {
    if (+buyWTK > 0) {
      openBuyWtkModal = true;
    }
  };

  const confirmBuyXtzWrapper = async () => {
    if (+buyWTK > 0) {
      openBuyWtkModal = false;
      try {
        loadingBuyWtk = true;
        const op = await $store.ledgerInstance.methods
          .buy_xtz_wrapper([["unit"]])
          .send({ amount: +buyWTK });

        opHash = op.opHash;
        setTimeout(() => (viewTxToast = true), 2000);
        setTimeout(() => (viewTxToast = false), 6000);

        await op.confirmation();
        // update the storage
        const newStorage: any = await $store.ledgerInstance.storage();
        store.updateLedgerStorage(newStorage);
        // update the token info
        store.updateTokens([
          ...$store.tokens.map(tk => {
            if (tk.tokenID === 1) {
              return {
                ...tk,
                totalSupply: tk.totalSupply + +buyWTK * 10 ** 6
              };
            } else {
              return tk;
            }
          })
        ]);
        // updates user's displayed balance
        let tokens: UserToken[];
        const token = $store.userTokens.filter(tk => tk.tokenID === 1);
        if (token.length === 0) {
          // the user didn't have any wTK before
          tokens = [
            ...$store.userTokens,
            {
              ...$store.tokens.filter(tk => tk.tokenID === 1)[0],
              balance: +buyWTK * 10 ** 6
            }
          ];
        } else {
          // the user already had some wTK
          tokens = $store.userTokens.map(tk => {
            if (tk.tokenID === 1) {
              return {
                ...tk,
                balance: tk.balance + +buyWTK * 10 ** 6
              };
            } else {
              return tk;
            }
          });
        }
        store.updateUserTokens(tokens);
        buyWTK = "";
      } catch (error) {
        console.log(error);
      } finally {
        loadingBuyWtk = false;
      }
    }
  };

  const redeemXtzWrapper = async () => {
    if (+redeemWTK > 0) {
      openRedeemWtkModal = true;
    }
  };

  const confirmRedeemXtzWrapper = async () => {
    openRedeemWtkModal = false;
    if (+redeemWTK > 0) {
      loadingRedeemWtk = true;

      try {
        const op = await $store.ledgerInstance.methods
          .redeem_xtz_wrapper(+redeemWTK * 10 ** 6)
          .send();

        console.log(op.opHash);
        opHash = op.opHash;
        setTimeout(() => (viewTxToast = true), 2000);
        setTimeout(() => (viewTxToast = false), 6000);

        await op.confirmation();
        // updates user's local balance
        const tokens = $store.userTokens.map(tk => {
          if (tk.tokenID === 1) {
            return {
              ...tk,
              balance: tk.balance - +redeemWTK * 10 ** +tk.decimals
            };
          } else {
            return tk;
          }
        });
        store.updateUserTokens(tokens);
        redeemWTK = "";
      } catch (error) {
        console.log(error);
      } finally {
        loadingRedeemWtk = false;
      }
    }
  };

  const createNewOrder = () => {
    if (
      $store.userAddress &&
      tokenToBuy > 0 &&
      tokenToSell > 0 &&
      !isNaN(+tokenToSellAmount) &&
      !isNaN(+tokenToBuyAmount)
    ) {
      openConfirmNewOrder = true;
    }
  };

  const confirmNewOrder = async () => {
    if (
      $store.userAddress &&
      tokenToBuy > 0 &&
      tokenToSell > 0 &&
      !isNaN(+tokenToSellAmount) &&
      !isNaN(+tokenToBuyAmount) &&
      tokenToBuy !== tokenToSell
    ) {
      openConfirmNewOrder = false;
      loadingConfirmNewOrder = true;

      const tokenToBuyDecimals = $store.tokens.filter(
        tk => tk.tokenID === tokenToBuy
      )[0].decimals;
      const tokenToSellDecimals = $store.tokens.filter(
        tk => tk.tokenID === tokenToSell
      )[0].decimals;

      try {
        const op = await $store.ledgerInstance.methods
          .new_exchange_order(
            "buy",
            [["unit"]],
            tokenToSell.toString(),
            +tokenToSellAmount * 10 ** tokenToSellDecimals,
            tokenToBuy.toString(),
            +tokenToBuyAmount * 10 ** tokenToBuyDecimals,
            +tokenToSellAmount * 10 ** tokenToSellDecimals,
            $store.userAddress
          )
          .send();

        console.log(op.opHash);
        opHash = op.opHash;
        setTimeout(() => (viewTxToast = true), 2000);
        setTimeout(() => (viewTxToast = false), 6000);

        await op.confirmation();
        // updates the local exchange storage
        const newStorage: any = await $store.exchangeInstance.storage();
        // adds new order to local order book
        const order: OrderEntry = {
          order_id: newStorage.last_order_id.toNumber(),
          created_on: new Date(Date.now()).toISOString(),
          order_type: "buy",
          token_id_to_sell: tokenToSell,
          token_amount_to_sell: +tokenToSellAmount * 10 ** tokenToSellDecimals,
          token_id_to_buy: tokenToBuy,
          token_amount_to_buy: +tokenToBuyAmount * 10 ** tokenToBuyDecimals,
          total_token_amount: +tokenToSellAmount * 10 ** tokenToSellDecimals,
          seller: $store.userAddress
        };
        store.updateOrderBook([order, ...$store.orderBook]);
        // clears UI
        tokenToBuy = 0;
        tokenToSell = 0;
        tokenToSellAmount = "";
        tokenToBuyAmount = "";
      } catch (error) {
        console.log(error);
      } finally {
        loadingConfirmNewOrder = false;
      }
    }
  };

  const fetchExchangeOrders = async () => {
    const exchangeBookId = $store.exchangeStorage.order_book.id.toNumber();
    const url = `https://api.better-call.dev/v1/bigmap/${
      $store.network === "testnet" ? "delphinet" : $store.network
    }/${exchangeBookId}/keys`;
    const response = await fetch(url);
    const data = await response.json();
    if (data && data.length > 0) {
      const orderPromises: Promise<any>[] = [];
      // removes entries that were deleted
      const filteredData = data.filter(d => d.data.value);
      filteredData.forEach(ord => {
        orderPromises.push(
          $store.exchangeStorage.order_book.get(ord.data.key_string)
        );
      });
      const orders = await Promise.all(orderPromises);
      if (orders.length > 0) {
        const ordersToLoad: OrderEntry[] = [];
        orders
          .filter(o => o)
          .forEach((ord, i) => {
            const order: OrderEntry = {
              ...ord,
              order_id: +filteredData[i].data.key_string,
              token_amount_to_buy: ord.token_amount_to_buy.toNumber(),
              token_amount_to_sell: ord.token_amount_to_sell.toNumber(),
              token_id_to_buy: ord.token_id_to_buy.toNumber(),
              token_id_to_sell: ord.token_id_to_sell.toNumber(),
              total_token_amount: ord.total_token_amount.toNumber()
            };
            ordersToLoad.push(order);
          });
        store.updateOrderBook(ordersToLoad);
      }
    }
  };

  onMount(async () => {
    if ($store.network === "local") {
      const orderPromises: Promise<any>[] = [];
      for (
        let i = 1;
        i <= $store.exchangeStorage.last_order_id.toNumber();
        i++
      ) {
        orderPromises.push($store.exchangeStorage.order_book.get(i.toString()));
      }
      const orders = await Promise.all(orderPromises);
      console.log(orders.filter(o => o));
      if (orders.length > 0) {
        orders
          .filter(o => o)
          .forEach((ord, i) => {
            const order: OrderEntry = {
              ...ord,
              order_id: i + 1,
              token_amount_to_buy: ord.token_amount_to_buy.toNumber(),
              token_amount_to_sell: ord.token_amount_to_sell.toNumber(),
              token_id_to_buy: ord.token_id_to_buy.toNumber(),
              token_id_to_sell: ord.token_id_to_sell.toNumber(),
              total_token_amount: ord.total_token_amount.toNumber()
            };
            store.updateOrderBook([order, ...$store.orderBook]);
          });
      }
    } else {
      if ($store.orderBook && $store.exchangeStorage) {
        store.updateOrderBook([]);
        await fetchExchangeOrders();
      } else {
        setTimeout(fetchExchangeOrders, 2000);
      }
    }
  });
</script>

<main>
  <section class="head">
    <h1>Exchange tokens</h1>
  </section>
  <section class="body">
    <div class="wtk-actions">
      <div class="buy-wtk">
        <div><strong>Buy wTK</strong></div>
        <div>
          Amount:
          <input type="text" bind:value={buyWTK} />&nbsp;
          {#if !$store.userAddress}
            <button class="button disabled" disabled>Connect your wallet</button
            >
          {:else if loadingBuyWtk}
            <button class="button blue" disabled>
              <span>Buying...</span><span class="spinner" />
            </button>
          {:else}
            <button class="button blue" on:click={buyXtzWrapper}>
              <span>Buy</span>
            </button>
          {/if}
        </div>
      </div>
      <div class="redeem-wtk">
        <div><strong>Redeem wTK</strong></div>
        <div>
          Amount:
          <input
            type="text"
            bind:value={redeemWTK}
            placeholder={$store.userAddress ? displayMaxAmount(1) : ""}
          />&nbsp;
          {#if !$store.userAddress}
            <button class="button disabled" disabled>Connect your wallet</button
            >
          {:else if loadingRedeemWtk}
            <button class="button blue" disabled>
              <span>Redeeming...</span><span class="spinner" />
            </button>
          {:else}
            <button class="button blue" on:click={redeemXtzWrapper}>
              <span>Redeem</span>
            </button>
          {/if}
        </div>
      </div>
    </div>
    <div class="new-order">
      <div><strong>Exchange tokens</strong></div>
      <div class="new-order__select">
        <div>Sell:</div>
        <div class="dropdown">
          <div class="dropdown-title">
            {!tokenToSell ? "Select" : getTokenSymbol(tokenToSell)}
            <span class="dropdown-title__arrow">&#9660;</span>
          </div>
          <div class="dropdown-menu">
            {#each $store.userTokens as token}
              <div on:click={() => (tokenToSell = token.tokenID)}>
                {token.symbol}
              </div>
            {:else}
              <div>No token</div>
            {/each}
          </div>
        </div>
        <div>
          Amount:
          <input
            type="text"
            bind:value={tokenToSellAmount}
            placeholder={tokenToSell > 0 ? displayMaxAmount(tokenToSell) : ""}
          />
        </div>
        <div>Buy:</div>
        <div class="dropdown">
          <div class="dropdown-title">
            {!tokenToBuy ? "Select" : getTokenSymbol(tokenToBuy)}
            <span class="dropdown-title__arrow">&#9660;</span>
          </div>
          <div class="dropdown-menu">
            {#each $store.tokens as token}
              <div on:click={() => (tokenToBuy = token.tokenID)}>
                {token.symbol}
              </div>
            {:else}
              <div>No token</div>
            {/each}
          </div>
        </div>
        <div>Amount: <input type="text" bind:value={tokenToBuyAmount} /></div>
        <div>
          {#if !$store.userAddress}
            <button class="button disabled" disabled>Connect your wallet</button
            >
          {:else}
            <button
              class={`button ${loadingConfirmNewOrder ? "disabled" : "blue"}`}
              disabled={loadingConfirmNewOrder}
              on:click={createNewOrder}>
              {#if loadingConfirmNewOrder}
                <span>Confirming...</span><span class="spinner" />
              {:else}<span>Confirm</span>{/if}
            </button>
          {/if}
        </div>
      </div>
    </div>
    <div class="exchange-grid header">
      <div>Order ID</div>
      <div>Created On</div>
      <div>Selling</div>
      <div>Buying</div>
      <div>Creator</div>
      <div />
    </div>
    <div class="orders-wrapper">
      {#each $store.orderBook as order}
        <Order
          {order}
          {getTokenSymbol}
          {openDeleteOrder}
          {openFulfillOrder}
          showViewTx={state => (viewTxToast = state)}
          passOpHash={hash => (opHash = hash)}
        />
      {:else}
        <div
          style="width:100%;text-align:center;padding: 20px;background-color:white"
        >No order yet!</div>
      {/each}
    </div>
  </section>
</main>
<Modal
  modalType="confirmWTKbuy"
  payload={buyWTK}
  open={openBuyWtkModal}
  close={() => (openBuyWtkModal = false)}
  confirm={confirmBuyXtzWrapper}
/>
<Modal
  modalType="confirmWTKredeem"
  payload={redeemWTK}
  open={openRedeemWtkModal}
  close={() => (openRedeemWtkModal = false)}
  confirm={confirmRedeemXtzWrapper}
/>
<Modal
  modalType="confirmNewOrder"
  payload={{ tokenToBuy, tokenToBuyAmount, tokenToSell, tokenToSellAmount }}
  open={openConfirmNewOrder}
  close={() => (openConfirmNewOrder = false)}
  confirm={confirmNewOrder}
/>
<ViewTransaction {opHash} show={viewTxToast} />

<style lang="scss">
  main {
    padding: 50px 0px;
    height: 90%;
    overflow: hidden;

    .head {
      padding: 20px 50px;
    }

    .body {
      padding: 50px;
      background-color: #edf2f7;
      border-top: solid 3px #a0aec0;
      height: 85%;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: flex-start;

      input[type="text"] {
        padding: 10px;
        outline: none;
        appearance: none;
        border: none;
        padding: 10px;
        margin: 0px;
        border-radius: 5px;
        color: #4a5568;
        font-family: "Montserrat", sans-serif;
        background-color: #ebf8ff;
      }

      .wtk-actions {
        display: flex;
        justify-content: space-between;
        width: 90%;
        background-color: white;
        border-radius: 5px;
        margin: 0px 0px 20px 0px;

        .buy-wtk,
        .redeem-wtk {
          & > div {
            padding: 20px 15px;
          }
        }
      }

      .new-order {
        width: 90%;
        background-color: white;
        border-radius: 5px;
        margin: 0px 0px 20px 0px;

        & > div {
          padding: 20px 15px;
        }

        .new-order__select {
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
      }

      .orders-wrapper {
        display: grid;
        overflow: auto;
        width: 90%;
        border-bottom-left-radius: 5px;
        border-bottom-right-radius: 5px;
      }
    }
  }
</style>
