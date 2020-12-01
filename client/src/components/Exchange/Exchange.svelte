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
  let loadingBuyWtk = false;
  let openBuyWtkModal = false;
  let openConfirmNewOrder = false;

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
            ...$store.tokens.filter(token => token.tokenID !== 1)
          ];
          store.updateTokens(newTokens);
        }
        // updates user's displayed balance
        console.log($store.userTokens);
        if ($store.userTokens.filter(tk => tk.tokenID === 1).length === 1) {
          // user previously had wTK tokens
          const newTokens = $store.userTokens.map(tk => {
            if (tk.tokenID === 1) {
              return {
                ...tk,
                balance: tk.balance + +buyWTK * 10 ** tk.decimals
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
              ...$store.tokens.filter(tk => tk.tokenID === 1)[0],
              balance: +buyWTK
            }
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

  const confirmNewOrder = () => {
    if (
      $store.userAddress &&
      tokenToBuy > 0 &&
      tokenToSell > 0 &&
      !isNaN(+tokenToSellAmount) &&
      !isNaN(+tokenToBuyAmount)
    ) {
      openConfirmNewOrder = false;

      try {
        /*const op = $store.ledgerInstance.methods
          .new_exchange_order(
            "buy",
            tokenToSell,
            tokenToSellAmount,
            tokenToBuy,
            tokenToBuyAmount,
            tokenToSellAmount,
            $store.userAddress
          )
          .send();*/
      } catch (error) {
        console.log(error);
      }
    }
  };

  onMount(async () => {
    // TODO: remove for loop when using an indexer becomes possible
    for (let i = 0; i < 10; i++) {
      const order: OrderEntry = await $store.exchangeStorage.order_book.get(
        i.toString()
      );
      if (!order) {
        break;
      } else {
        orderBook = [order, ...orderBook];
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
      height: 100%;
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

      .buy-wtk {
        width: 90%;
        background-color: white;
        border-radius: 5px;
        margin: 0px 0px 20px 0px;

        & > div {
          padding: 20px 15px;
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
        grid-template-columns: 10% 35% 35% 20%;
        grid-template-rows: auto;
        align-items: center;
        width: 90%;
        background-color: white;
        border-radius: 5px;

        div {
          padding: 20px 15px;
        }
      }
    }
  }
</style>

<main>
  <section class="head">
    <h1>Exchange tokens</h1>
  </section>
  <section class="body">
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
    <div class="new-order">
      <div><strong>Exchange tokens</strong></div>
      <div class="new-order__select">
        <div>Sell:</div>
        <div class="dropdown">
          <div class="dropdown-title">
            {!tokenToSell ? 'Select' : $store.tokens.filter(tk => tk.tokenID === tokenToSell)[0].symbol}
            <span class="dropdown-title__arrow">&#9660;</span>
          </div>
          <div class="dropdown-menu">
            {#each $store.tokens as token}
              <div on:click={() => (tokenToSell = token.tokenID)}>
                {token.symbol}
              </div>
            {:else}
              <div>No token</div>
            {/each}
          </div>
        </div>
        <div>Amount: <input type="text" bind:value={tokenToSellAmount} /></div>
        <div>Buy:</div>
        <div class="dropdown">
          <div class="dropdown-title">
            {!tokenToBuy ? 'Select' : $store.tokens.filter(tk => tk.tokenID === tokenToBuy)[0].symbol}
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
            <button
              class="button blue"
              on:click={createNewOrder}>Confirm</button>
          {/if}
        </div>
      </div>
    </div>
    <div class="exchange-grid">
      <div>Order ID</div>
      <div>Selling</div>
      <div>Buying</div>
      <div>Creator</div>
      {#each orderBook as order}
        <div>{order.order_type}</div>
        <div>
          {order.token_id_to_sell}
          {order.token_amount_to_sell * order.total_token_amount}
        </div>
        <div>
          {order.token_id_to_buy}
          {order.token_amount_to_buy * order.total_token_amount}
        </div>
        <div>{order.seller}</div>
      {:else}
        <div />
        <div />
        <div>No order yet!</div>
        <div />
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
  modalType="confirmNewOrder"
  payload={{ tokenToBuy, tokenToBuyAmount, tokenToSell, tokenToSellAmount }}
  open={openConfirmNewOrder}
  close={() => (openConfirmNewOrder = false)}
  confirm={confirmNewOrder} />
