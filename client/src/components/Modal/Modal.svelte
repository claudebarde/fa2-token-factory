<script lang="ts">
  import { fly, fade } from "svelte/transition";
  import { ModalType } from "../../types";
  import store from "../../store";
  import { displayTokenAmount } from "../../utils";

  export let modalType: ModalType;
  export let open = false;
  export let payload: any = undefined;
  export let close: (p?: any) => any | undefined; //should be a function
  export let confirm: (p?: any) => any | undefined; //should be a function

  let transferRecipient = "";
  let transferAmount = "";

  const calculateExchangeRate = async (): Promise<{
    amountToSell: number;
    amountToBuy: number;
    totalAmount: number;
  }> => {
    const {
      tokenToSell,
      tokenToBuy,
      tokenToBuyAmount,
      tokenToSellAmount
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
    min-width: 400px;

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

  input[type="text"] {
    padding: 10px;
    border: none;
    border-radius: 3px;
    background-color: #edf2f7;
    outline: none;
    width: 90%;
    font-family: "Montserrat", sans-serif;
  }
</style>

{#if open}
  <div class="modal-wrapper">
    <div class="background" transition:fade={{ duration: 200 }} />
    <div class="modal" transition:fly={{ y: 100, duration: 500 }}>
      <div
        class="modal__close"
        on:click={() => {
          transferAmount = "";
          transferRecipient = "";
          close();
        }}
      >
        <span>&#10006;</span>
      </div>
      <div class="modal__body">
        {#if modalType === "confirmWTKbuy"}
          <p>Would you like to buy {payload} wTK tokens?</p>
        {:else if modalType === "confirmNewOrder"}
          <p>
            You are about to create a new exchange order with the following
            details:
          </p>
          <p>
            Exchange:
            {(+payload.tokenToSellAmount).toLocaleString("en-US")}
            {$store.tokens.filter(tk => tk.tokenID === payload.tokenToSell)[0]
              .symbol}
            for
            {(+payload.tokenToBuyAmount).toLocaleString("en-US")}
            {$store.tokens.filter(tk => tk.tokenID === payload.tokenToBuy)[0]
              .symbol}
          </p>
          <p>Confirm this new order?</p>
        {:else if modalType === "deleteOrder"}
          <p>Would you like to delete the order number {payload}?</p>
        {:else if modalType === "confirmWTKredeem"}
          <p>Would you like to redeem {payload} wTK for {payload} XTZ?</p>
        {:else if modalType === "fulfillOrder"}
          {#if payload}
            <p>
              Are you sure you want to confirm
              <br />the exchange of
              {displayTokenAmount(
                payload.token_id_to_buy,
                payload.token_amount_to_buy
              )}
              {$store.tokens.filter(
                tk => tk.tokenID === payload.token_id_to_buy
              )[0].symbol}
              for
              {displayTokenAmount(
                payload.token_id_to_sell,
                payload.token_amount_to_sell
              )}
              {$store.tokens.filter(
                tk => tk.tokenID === payload.token_id_to_sell
              )[0].symbol}?
            </p>
          {:else}
            <p>No order ID provided</p>
          {/if}
        {:else if modalType === "transfer"}
          <p>Transfer {payload.name} to another address</p>
          <div>
            <label for="transfer-to">
              Recipient:
              <input
                type="text"
                id="transfer-to"
                bind:value={transferRecipient}
              />
            </label>
          </div>
          <br />
          <div>
            <label for="transfer-amount">
              Amount:
              <input
                type="text"
                id="transfer-amount"
                bind:value={transferAmount}
              />
            </label>
          </div>
          <p>
            {#if +payload.decimals > 0 && +transferAmount > 0}
              <span style="font-size:0.8rem">
                This will be converted to {(
                  +transferAmount *
                  10 ** +payload.decimals
                ).toLocaleString("en-US")} µ{payload.symbol} for the transfer.
              </span>
            {:else}
              &nbsp;
            {/if}
          </p>
        {:else if modalType === "tokenMetadata"}
          <h3>Token metadata for {payload.name}</h3>
          {#each Object.keys(payload) as prop}
            {#if !["tokenID", "name", "symbol", "totalSupply", "admin"].includes(prop)}
              <p>{prop}: {payload[prop]}</p>
            {/if}
          {/each}
        {:else}This is an empty modal{/if}
      </div>
      <div class="modal__footer">
        {#if modalType !== "tokenMetadata"}
          <button
            class={`button ${
              modalType === "transfer" &&
              (!transferRecipient || !transferAmount)
                ? "disabled"
                : "green"
            }`}
            disabled={modalType === "transfer" &&
              (!transferRecipient || !transferAmount)}
            on:click={() => {
              if (modalType === "transfer") {
                confirm({
                  tokenID: payload.tokenID,
                  recipient: transferRecipient,
                  amount: transferAmount
                });
              } else {
                if (confirm) confirm();
              }
            }}>Confirm</button
          >&nbsp;
        {/if}
        <button
          class="button red"
          on:click={() => {
            transferAmount = "";
            transferRecipient = "";
            close();
          }}
        >
          {#if modalType === "tokenMetadata"}
            Close
          {:else}
            Cancel
          {/if}
        </button>
      </div>
    </div>
  </div>
{/if}
