<script lang="ts">
  import { fly, fade } from "svelte/transition";
  import { ModalType } from "../../types";
  import store from "../../store";

  export let modalType: ModalType;
  export let open = false;
  export let payload: any = undefined;
  export let close: (p?: any) => any | undefined; //should be a function
  export let confirm: (p?: any) => any | undefined; //should be a function

  const calculateExchangeRate = async (): Promise<{
    amountToSell: number;
    amountToBuy: number;
    totalAmount: number;
  }> => {
    const {
      tokenToSell,
      tokenToBuy,
      tokenToBuyAmount,
      tokenToSellAmount,
    } = payload;
    let amountToSell = 0;
    let amountToBuy = 0;
    let totalAmount = 0;

    if (tokenToSell >= tokenToBuy) {
      amountToSell = 1;
      amountToBuy = Math.round(+tokenToBuyAmount / +tokenToSellAmount);
      totalAmount = tokenToSell;
    } else {
      amountToBuy = 1;
      amountToSell = Math.round(+tokenToSellAmount / +tokenToBuyAmount);
      totalAmount = tokenToBuy;
    }

    return { amountToSell, amountToBuy, totalAmount };
  };
</script>

<style lang="scss">
  .modal-wrapper {
    position: absolute;
    top: 0;
    left: 0;
    height: 100%;
    width: 100%;
    display: grid;
    place-items: center;
  }

  .background {
    background-color: black;
    opacity: 0.5;
    position: absolute;
    top: 0;
    left: 0;
    height: 100%;
    width: 100%;
  }

  .modal {
    background-color: white;
    position: relative;
    padding: 30px;
    border-radius: 10px;
    max-width: 40%;

    .modal__close {
      color: #374251;
      border: solid 4px #374251;
      border-radius: 50px;
      position: absolute;
      top: -15px;
      right: -15px;
      height: 26px;
      width: 26px;
      background-color: white;
      text-align: center;
      font-size: 20px;
      cursor: pointer;
      transition: 0.3s;

      span {
        vertical-align: middle;
      }

      &:hover {
        color: #f04444;
      }
    }

    .modal__body {
      margin-bottom: 30px;
    }

    .modal__footer {
      width: 100%;
      display: flex;
      justify-content: flex-end;
    }
  }
</style>

{#if open}
  <div class="modal-wrapper">
    <div class="background" transition:fade={{ duration: 200 }} />
    <div class="modal" transition:fly={{ y: 100, duration: 500 }}>
      <div class="modal__close" on:click={close}><span>&#10006;</span></div>
      <div class="modal__body">
        {#if modalType === 'confirmWTKbuy'}
          <p>Confirm new wTK buy?</p>
        {:else if modalType === 'confirmNewOrder'}
          <p>
            You are about to create a new exchange order with the following
            details:
          </p>
          {#await calculateExchangeRate() then val}
            <p>
              Exchange:
              {payload.tokenToSellAmount}
              {$store.tokens.filter((tk) => tk.tokenID === payload.tokenToSell)[0].symbol}
              for
              {payload.tokenToBuyAmount}
              {$store.tokens.filter((tk) => tk.tokenID === payload.tokenToBuy)[0].symbol}
            </p>
          {/await}
          <p>Confirm this new order?</p>
        {:else if modalType === 'deleteOrder'}
          <p>Would you like to delete the order number {payload}?</p>
        {:else if modalType === 'confirmWTKredeem'}
          <p>Would you like to redeem {payload} wTK for {payload} XTZ?</p>
        {:else}This is an empty modal{/if}
      </div>
      <div class="modal__footer">
        <button
          class="button green"
          on:click={() => {
            if (confirm) confirm();
          }}>Confirm</button>&nbsp;
        <button class="button red" on:click={close}>Cancel</button>
      </div>
    </div>
  </div>
{/if}
