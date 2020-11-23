<script lang="ts">
  import { onMount } from "svelte";
  import store from "../../store";
  import { OrderEntry, Token } from "../../types";

  let orderBook: OrderEntry[] = [];
  let tokenToBuy: string = "";
  let tokenToSell: string = "";
  let buyWTK: string = "";

  const buyXtzWrapper = async () => {
    if (+buyWTK > 0) {
      try {
        const op = await $store.ledgerInstance.methods
          .buy_xtz_wrapper([["unit"]])
          .send({ amount: +buyWTK });
        await op.confirmation();
        // update the storage
        const newStorage: any = await $store.ledgerInstance.storage();
        store.updateLedgerStorage(newStorage);
        // update the token info
        const newTokenInfo: Token = await newStorage.token_metadata.get("1");
        const newToken = await store.formatToken(1, newStorage);
        if (newToken) {
          const newTokens: Token[] = [
            newToken,
            ...$store.tokens.filter(token => token.tokenID !== 1)
          ];
          store.updateTokens(newTokens);
        }

        console.log("confirmed!");
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
        {:else}
          <button class="button info" on:click={buyXtzWrapper}>Buy</button>
        {/if}
      </div>
    </div>
    <div class="new-order">
      <div><strong>Exchange tokens</strong></div>
      <div class="new-order__select">
        <div>Sell:</div>
        <div class="dropdown">
          <div class="dropdown-title">
            {!tokenToSell ? 'Select' : tokenToSell}
            <span class="dropdown-title__arrow">&#9660;</span>
          </div>
          <div class="dropdown-menu">
            {#each $store.tokens as token}
              <div on:click={() => (tokenToSell = token.symbol)}>
                {token.symbol}
              </div>
            {:else}
              <div>No token</div>
            {/each}
          </div>
        </div>
        <div>Amount: <input type="text" /></div>
        <div>Buy:</div>
        <div class="dropdown">
          <div class="dropdown-title">
            {!tokenToBuy ? 'Select' : tokenToBuy}
            <span class="dropdown-title__arrow">&#9660;</span>
          </div>
          <div class="dropdown-menu">
            {#each $store.tokens as token}
              <div on:click={() => (tokenToBuy = token.symbol)}>
                {token.symbol}
              </div>
            {:else}
              <div>No token</div>
            {/each}
          </div>
        </div>
        <div>Amount: <input type="text" /></div>
        <div>
          {#if !$store.userAddress}
            <button class="button disabled" disabled>Connect your wallet</button>
          {:else}<button class="button info">Confirm</button>{/if}
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
