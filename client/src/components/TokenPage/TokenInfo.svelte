<script lang="ts">
  import store from "../../store";
  import { displayTokenAmount } from "../../utils";
  import Modal from "../Modal/Modal.svelte";

  export let token, index;

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
    height: 1px;
    padding: 0px;
    overflow: hidden;
    transition-delay: 0.2s;
    transition: all 0.3s ease-in-out;

    &.open {
      height: auto;
      padding: 20px 15px;
      overflow: auto;
    }
  }

  .light-bg {
    background-color: lighten(#edf2f7, 3);
  }
</style>

<div class={`token-id ${index % 2 === 0 ? "light-bg" : ""}`}>
  {#if $store.userTokens && $store.userTokens.filter(tk => tk.tokenID === token.tokenID).length === 1}
    <strong>{token.tokenID}</strong>
  {:else}
    {token.tokenID}
  {/if}
</div>
<div class={`token-name ${index % 2 === 0 ? "light-bg" : ""}`}>
  <a href={`#/token/${token.tokenID}`}>{token.name}</a>
</div>
<div class={`token-symbol ${index % 2 === 0 ? "light-bg" : ""}`}>
  {token.symbol}
</div>
<div class={`token-total-supply ${index % 2 === 0 ? "light-bg" : ""}`}>
  {#if token.symbol === "wTK"}
    wꜩ
    {displayTokenAmount(token.tokenID, token.totalSupply).toLocaleString(
      "en-US"
    )}
  {:else}
    {displayTokenAmount(token.tokenID, token.totalSupply).toLocaleString(
      "en-US"
    )}
  {/if}
</div>
<div class={`token-admin ${index % 2 === 0 ? "light-bg" : ""}`}>
  <a
    href={`https://${
      $store.network === "local" || $store.network === "testnet"
        ? "carthage."
        : ""
    }tzkt.io/${token.admin}`}
    target="_blank"
    rel="noopener noreferrer nofollow"
  >
    {`${token.admin.slice(0, 10)}...${token.admin.slice(-10)}`}
  </a>
</div>
<div class={`token-info ${index % 2 === 0 ? "light-bg" : ""}`}>
  <button on:click={() => (open = !open)}>Info</button>
</div>
<Modal
  modalType="tokenMetadata"
  payload={token}
  {open}
  close={() => {
    open = false;
  }}
/>
