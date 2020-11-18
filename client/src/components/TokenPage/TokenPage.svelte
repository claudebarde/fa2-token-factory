<script lang="ts">
  interface Token {
    tokenID: number;
    name: string;
    symbol: string;
    admin: string;
    decimals: number;
    totalSupply: number;
    extras: { [n: string]: string };
  }

  import { onMount, afterUpdate } from "svelte";
  import store from "../../store";
  import TokenInfo from "./TokenInfo.svelte";

  export let params;

  let tokens: Token[] = [];
  let paramToken: Token | undefined;

  onMount(async () => {
    // this will be replaced by a call to an indexer once live on the blockchain
    tokens = [];
    if ($store.ledgerStorage) {
      let tokenId = 1;
      while (true) {
        const entry = await $store.ledgerStorage.token_metadata.get(
          tokenId.toString()
        );
        if (!entry) break;

        const totalSupply = await $store.ledgerStorage.token_total_supply.get(
          tokenId.toString()
        );
        const extras = {};
        entry.extras.forEach((value, key) => (extras[key] = value));

        const token: Token = {
          tokenID: tokenId,
          name: entry.name,
          symbol: entry.symbol,
          admin: entry.admin,
          decimals: entry.decimals.toNumber(),
          totalSupply: totalSupply.toNumber(),
          extras
        };

        tokens = [...tokens, token];
        tokenId++;
      }
      console.log("Tokens:", tokens);
    }
  });

  afterUpdate(() => {
    if (params.id) {
      if (isNaN(params.id)) {
        // token symbol provided
        paramToken = tokens.filter(token => token.symbol === params.id)[0];
      } else {
        // token id provided
        paramToken = tokens.filter(token => token.tokenID === +params.id)[0];
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

      .tokens-grid {
        display: grid;
        grid-template-columns: 10% 20% 10% 20% 30% 10%;
        grid-template-rows: auto;
        align-items: center;
        width: 90%;
        background-color: white;
        border-radius: 5px;

        div {
          padding: 20px 15px;
        }
      }

      & :last-child {
        border-bottom: none;
      }
    }
  }

  .param-token {
    padding: 20px;
    margin-bottom: 40px;
    background-color: white;
    border-radius: 10px;
    width: 300px;

    div[class^="param-token"] {
      padding: 10px;
    }

    .param-token__title {
      display: flex;
      justify-content: flex-start;
      align-items: center;

      .param-token__title__icon {
        width: 30px;
        margin: 0px 20px 0px 0px;
      }
    }
  }
</style>

<main>
  <section class="head">
    <h1>Find a token</h1>
  </section>
  <section class="body">
    {#if paramToken}
      <div class="param-token">
        <div class="param-token__title">
          <div>
            <img
              class="param-token__title__icon"
              src={paramToken.extras.hasOwnProperty('icon_url') ? paramToken.extras.icon_url : 'images/tezos-coin.png'}
              alt="token icon" />
          </div>
          <div>{paramToken.name} Token</div>
        </div>
        <div class="param-token__symbol">Symbol: {paramToken.symbol}</div>
        <div class="param-token__total-supply">
          Total Supply:
          {paramToken.totalSupply.toLocaleString('en-US')}
          tokens
        </div>
        <div class="param-token__admin">
          Admin:
          <a
            href={`https://${$store.network === 'local' || $store.network === 'testnet' ? 'carthage.' : ''}tzkt.io/${paramToken.admin}`}
            target="_blank"
            rel="noopener noreferrer">
            {`${paramToken.admin.slice(0, 10)}...${paramToken.admin.slice(-10)}`}
          </a>
        </div>
        {#if $store.userAddress}
          <div class="param-token__balance">
            Your balance:
            {#await $store.ledgerStorage.ledger.get({
              owner: $store.userAddress,
              token_id: paramToken.tokenID
            })}
              fetching your balance...
            {:then balance}
              {balance.toNumber().toLocaleString('en-US')}
              tokens
            {:catch error}
              None
            {/await}
          </div>
        {/if}
      </div>
    {/if}
    <div class="tokens-grid">
      <div class="token-id"><strong>ID</strong></div>
      <div class="token-name"><strong>Name</strong></div>
      <div class="token-symbol"><strong>Symbol</strong></div>
      <div class="token-totalsupply"><strong>Total Supply</strong></div>
      <div class="token-admin"><strong>Admin</strong></div>
      <div class="token-extras"><strong>Extras</strong></div>
      {#each tokens as token}
        <TokenInfo {token} />
      {:else}
        <div />
        <div />
        <div />
        <div>No token yet!</div>
        <div />
        <div />
      {/each}
    </div>
  </section>
</main>
