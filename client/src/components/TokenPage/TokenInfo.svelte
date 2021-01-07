<script lang="ts">
  import store from "../../store";
  import { displayTokenAmount } from "../../utils";

  export let token;

  let open = false;
</script>

<style lang="scss">
  div {
    padding: 20px 15px;
  }

  .token-info {
    padding: 16px 15px 15px 15px;
    button {
      outline: none;
      appearance: none;
      border: none;
      background-color: #edf2f7;
      padding: 6px 20px;
      margin: 0px;
      border-radius: 5px;
      transition: 0.3s;
      color: #4a5568;
      font-family: "Montserrat", sans-serif;

      &:hover:enabled {
        background-color: darken(#edf2f7, 5);
        cursor: pointer;
      }
    }
  }

  .token-info-details {
    grid-column: 1 / 7;
    border-bottom: solid 1px #a0aec0;
    height: 0px;
    padding: 0px;
    overflow: hidden;
    transition-delay: 0.2s;
    transition: all 0.3s ease-in-out;

    &.open {
      height: auto;
      padding: 20px 15px;
      overflow: auto;
      border-top: solid 1px #a0aec0;
    }
  }
</style>

<div class="token-id">{token.tokenID}</div>
<div class="token-name">
  <a href={`#/token/${token.tokenID}`}>{token.name}</a>
</div>
<div class="token-symbol">{token.symbol}</div>
<div class="token-totalsupply">
  {#if token.symbol === 'wTK'}
    wꜩ
    {displayTokenAmount(token.tokenID, token.totalSupply).toLocaleString('en-US')}
  {:else}
    {displayTokenAmount(token.tokenID, token.totalSupply).toLocaleString('en-US')}
  {/if}
</div>
<div class="token-admin">
  <a
    href={`https://${$store.network === 'local' || $store.network === 'testnet' ? 'carthage.' : ''}tzkt.io/${token.admin}`}
    target="_blank"
    rel="noopener noreferrer nofollow">
    {`${token.admin.slice(0, 10)}...${token.admin.slice(-10)}`}
  </a>
</div>
<div class="token-info">
  <button on:click={() => (open = !open)}>Info</button>
</div>
<div class={`token-info-details ${open ? 'open' : ''}`}>
  {#each Object.keys(token.extras) as key}
    <p>{key}: {token.extras[key]}</p>
  {:else}
    <p>No additional information</p>
  {/each}
</div>
