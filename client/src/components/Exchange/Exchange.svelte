<script lang="ts">
  import { onMount } from "svelte";
  import store from "../../store";
  import { OrderEntry, Token } from "../../types";
  import Modal from "../Modal/Modal.svelte";

  let orderBook: OrderEntry[] = [];
  let tokenToBuy: number = 0;
  let tokenToBuyAmount: string = "";
  let tokenToSell: number = 0;
  let tokenToSellAmount: string = "";
  let buyWTK: string = "";
  let redeemWTK: string = "";
  let loadingBuyWtk = false;
  let loadingRedeemWtk = false;
  let loadingConfirmNewOrder = false;
  let loadingDeleteOrder = false;
  let openBuyWtkModal = false;
  let openRedeemWtkModal = false;
  let openConfirmNewOrder = false;
  let openDeleteOrder = false;
  let orderToDelete = 0;

  const displayMaxAmount = (tokenID: number): string => {
    const token = $store.userTokens.filter((tk) => tk.tokenID === tokenID)[0];
    if (token) {
      const balance = token.balance / 10 ** +token.decimals;

      return "Max: " + balance.toString();
    } else {
      return "";
    }
  };

  const formatCreatedOn = (timestamp: string): string => {
    const date = new Date(timestamp);

    return `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;
  };

  const getTokenSymbol = (tokenID: number): string => {
    if ($store.tokens.length === 0) return "N/A";

    const token = $store.tokens.filter((tk) => tk.tokenID === tokenID);
    if (token.length === 0) return "N/A";
    if (!token[0].symbol) return "N/A";

    return token[0].symbol;
  };

  const colorBalance = (tokenID: number, amount: number): string => {
    if (!$store.userAddress) return "";

    const token = $store.userTokens.filter((tk) => tk.tokenID === tokenID);
    if (token.length === 0) return "color:red";

    if (token[0].balance / 10 ** +token[0].decimals < amount) {
      return "color:red";
    } else {
      return "color:green";
    }
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
        await op.confirmation();
        // update the storage
        const newStorage: any = await $store.ledgerInstance.storage();
        store.updateLedgerStorage(newStorage);
        // update the token info
        const newToken = await store.formatToken(1, newStorage);
        if (newToken) {
          const newTokens: Token[] = [
            newToken,
            ...$store.tokens.filter((token) => token.tokenID !== 1),
          ];
          store.updateTokens(newTokens);
        }
        // updates user's displayed balance
        if ($store.userTokens.filter((tk) => tk.tokenID === 1).length === 1) {
          // user previously had wTK tokens
          const newTokens = $store.userTokens.map((tk) => {
            if (tk.tokenID === 1) {
              return {
                ...tk,
                balance: tk.balance + +buyWTK * 10 ** tk.decimals,
              };
            } else {
              return tk;
            }
          });

          store.updateUserTokens(newTokens);
        } else {
          // user bought wTK tokens for the first time
          const newTokens = [
            ...$store.userTokens,
            {
              ...$store.tokens.filter((tk) => tk.tokenID === 1)[0],
              balance: +buyWTK,
            },
          ];

          store.updateUserTokens(newTokens);
        }
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
        await op.confirmation();
        // updates user's local balance
        const tokens = $store.userTokens.map((tk) => {
          if (tk.tokenID === 1) {
            return {
              ...tk,
              balance: tk.balance - +redeemWTK * 10 ** +tk.decimals,
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

      try {
        const op = await $store.ledgerInstance.methods
          .new_exchange_order(
            "buy",
            [["unit"]],
            tokenToSell.toString(),
            tokenToSellAmount,
            tokenToBuy.toString(),
            tokenToBuyAmount,
            tokenToSellAmount,
            $store.userAddress
          )
          .send();
        console.log(op.opHash);
        await op.confirmation();
        // updates the local exchange storage
        const newStorage: any = await $store.exchangeInstance.storage();
        // adds new order to local order book
        const order: OrderEntry = {
          order_id: newStorage.last_order_id.toNumber(),
          created_on: new Date(Date.now()).toISOString(),
          order_type: "buy",
          token_id_to_sell: tokenToSell,
          token_amount_to_sell: +tokenToSellAmount,
          token_id_to_buy: tokenToBuy,
          token_amount_to_buy: +tokenToBuyAmount,
          total_token_amount: +tokenToSellAmount,
          seller: $store.userAddress,
        };
        orderBook = [...orderBook, order];
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

  const fulfillOrder = async (orderID: number): Promise<void> => {
    console.log(orderID);
  };

  const deleteOrder = async (): Promise<void> => {
    loadingDeleteOrder = true;
    openDeleteOrder = false;

    try {
      const op = await $store.exchangeInstance.methods
        .delete_order(orderToDelete)
        .send();
      console.log(op.opHash);
      await op.confirmation();
      // removes order from local order book
      orderBook = [
        ...orderBook.filter((ord) => ord.order_id !== orderToDelete),
      ];
    } catch (error) {
      console.log(error);
    } finally {
      loadingDeleteOrder = false;
      orderToDelete = 0;
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
      console.log(orders.filter((o) => o));
      if (orders.length > 0) {
        orders
          .filter((o) => o)
          .forEach((ord, i) => {
            const order: OrderEntry = {
              ...ord,
              order_id: i + 1,
              token_amount_to_buy: ord.token_amount_to_buy.toNumber(),
              token_amount_to_sell: ord.token_amount_to_sell.toNumber(),
              token_id_to_buy: ord.token_id_to_buy.toNumber(),
              token_id_to_sell: ord.token_id_to_sell.toNumber(),
              total_token_amount: ord.total_token_amount.toNumber(),
            };
            orderBook = [...orderBook, order];
          });
      }
    } else {
      const exchangeBookId = $store.exchangeStorage.order_book.id.toNumber();
      const url = `https://api.better-call.dev/v1/bigmap/${
        $store.network === "testnet" ? "delphinet" : $store.network
      }/${exchangeBookId}/keys`;
      const response = await fetch(url);
      const data = await response.json();
      if (data && data.length > 0) {
        const orderPromises: Promise<any>[] = [];
        data.forEach((ord) => {
          orderPromises.push(
            $store.exchangeStorage.order_book.get(ord.data.key_string)
          );
        });
        const orders = await Promise.all(orderPromises);
        if (orders.length > 0) {
          orders
            .filter((o) => o)
            .forEach((ord, i) => {
              const order: OrderEntry = {
                ...ord,
                order_id: +data[i].data.key_string,
                token_amount_to_buy: ord.token_amount_to_buy.toNumber(),
                token_amount_to_sell: ord.token_amount_to_sell.toNumber(),
                token_id_to_buy: ord.token_id_to_buy.toNumber(),
                token_id_to_sell: ord.token_id_to_sell.toNumber(),
                total_token_amount: ord.total_token_amount.toNumber(),
              };
              orderBook = [...orderBook, order];
            });
        }
      }
    }
  });
</script>

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

      .exchange-grid {
        display: grid;
        grid-template-columns: 10% 15% 15% 15% 20% 20%;
        grid-template-rows: auto;
        align-items: center;
        width: 90%;
        background-color: white;

        div {
          padding: 20px 15px;
        }

        &.header {
          border-top-left-radius: 5px;
          border-top-right-radius: 5px;
        }

        &.orders {
          width: 100%;
        }

        &.orders:nth-child(2n) {
          background-color: lighten(#edf2f7, 3);
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
            <button class="button disabled" disabled>Connect your wallet</button>
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
            placeholder={$store.userAddress ? displayMaxAmount(1) : ''} />&nbsp;
          {#if !$store.userAddress}
            <button class="button disabled" disabled>Connect your wallet</button>
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
            {!tokenToSell ? 'Select' : getTokenSymbol(tokenToSell)}
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
            placeholder={tokenToSell > 0 ? displayMaxAmount(tokenToSell) : ''} />
        </div>
        <div>Buy:</div>
        <div class="dropdown">
          <div class="dropdown-title">
            {!tokenToBuy ? 'Select' : getTokenSymbol(tokenToBuy)}
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
            <button class="button disabled" disabled>Connect your wallet</button>
          {:else}
            <button class="button blue" on:click={createNewOrder}>
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
      {#each orderBook as order}
        <div class="exchange-grid orders">
          <div>{order.order_id}</div>
          <div>{formatCreatedOn(order.created_on)}</div>
          <div>
            <span>{order.token_amount_to_sell.toLocaleString('en-US')}
              {getTokenSymbol(order.token_id_to_sell)}</span>
          </div>
          <div>
            <span
              style={$store.userAddress ? colorBalance(order.token_id_to_buy, order.token_amount_to_buy) : ''}>{order.token_amount_to_buy.toLocaleString('en-US')}
              {getTokenSymbol(order.token_id_to_buy)}</span>
          </div>
          <div>{order.seller.slice(0, 7) + '...' + order.seller.slice(-7)}</div>
          <div>
            {#if $store.userAddress && $store.userAddress === order.seller}
              {#if loadingDeleteOrder && orderToDelete === order.order_id}
                <button class="button red">
                  <span>Deleting...</span><span class="spinner" />
                </button>
              {:else}
                <button
                  class="button red"
                  on:click={() => {
                    openDeleteOrder = true;
                    orderToDelete = order.order_id;
                  }}>
                  <span>Delete</span></button>
              {/if}
            {:else}
              <button
                class="button green"
                on:click={() => fulfillOrder(order.order_id)}>Fulfill</button>
            {/if}
          </div>
        </div>
      {:else}
        <div
          style="width:100%;text-align:center;padding: 20px;background-color:white">
          No order yet!
        </div>
      {/each}
    </div>
  </section>
</main>
<Modal
  modalType="confirmWTKbuy"
  open={openBuyWtkModal}
  close={() => (openBuyWtkModal = false)}
  confirm={confirmBuyXtzWrapper} />
<Modal
  modalType="confirmWTKredeem"
  payload={redeemWTK}
  open={openRedeemWtkModal}
  close={() => (openRedeemWtkModal = false)}
  confirm={confirmRedeemXtzWrapper} />
<Modal
  modalType="confirmNewOrder"
  payload={{ tokenToBuy, tokenToBuyAmount, tokenToSell, tokenToSellAmount }}
  open={openConfirmNewOrder}
  close={() => (openConfirmNewOrder = false)}
  confirm={confirmNewOrder} />
<Modal
  modalType="deleteOrder"
  payload={orderToDelete}
  open={openDeleteOrder}
  close={() => {
    openDeleteOrder = false;
    orderToDelete = 0;
  }}
  confirm={deleteOrder} />
