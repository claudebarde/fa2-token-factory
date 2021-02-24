<script lang="ts">
  import { afterUpdate } from "svelte";
  import { validateAddress } from "@taquito/utils";
  import store from "../../store";
  import TokenInfo from "./TokenInfo.svelte";
  import { Token } from "../../types";
  import { displayTokenAmount } from "../../utils";
  import Modal from "../Modal/Modal.svelte";

  export let params;

  let paramToken: Token | undefined;
  let openTransferModal = false;
  let sendingTransfer = false;

  const transfer = async (transferParams: {
    tokenID: number;
    recipient: string;
    amount: number;
  }): Promise<void> => {
    let { tokenID, recipient, amount } = transferParams;
    if (validateAddress(recipient) === 3 && !isNaN(+amount)) {
      openTransferModal = false;
      sendingTransfer = true;
      //console.log(tokenID, recipient, amount);
      try {
        const op = await $store.ledgerInstance.methods
          .transfer([
            {
              from_: $store.userAddress,
              txs: [
                {
                  to_: recipient,
                  token_id: tokenID,
                  amount: +amount * 10 ** +paramToken.decimals
                }
              ]
            }
          ])
          .send();
        await op.confirmation();
        const tokens = $store.userTokens.map(tk => {
          if (tk.tokenID === tokenID) {
            return {
              ...tk,
              balance:
                BigInt(tk.balance) -
                BigInt(+amount) * BigInt(10 ** +paramToken.decimals)
            };
          } else {
            return tk;
          }
        });
        store.updateUserTokens(tokens);
      } catch (error) {
        console.log(error);
      } finally {
        sendingTransfer = false;
      }
    }
  };

  afterUpdate(() => {
    if (params.id && $store.tokens) {
      if (isNaN(params.id)) {
        // token symbol provided
        const token = $store.tokens.filter(token => token.symbol === params.id);
        if (token && token.length === 1) {
          paramToken = token[0];
        } else {
          paramToken = undefined;
        }
      } else {
        // token id provided
        const token = $store.tokens.filter(
          token => token.tokenID === +params.id
        );
        if (token && token.length === 1) {
          paramToken = token[0];
        } else {
          paramToken = undefined;
        }
      }
    } else {
      paramToken = undefined;
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
        grid-template-columns: 20% 20% 20% 30% 10%;
        grid-template-rows: auto;
        align-items: center;
        width: 90%;
        background-color: white;
        border-radius: 5px;
        overflow: auto;

        div {
          padding: 20px 15px;
        }
      }

      & :last-child {
        border-bottom: none;
      }
    }
  }

  .param-token__wrapper {
    height: 330px;
  }

  .param-token {
    padding: 10px 20px;
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

    .param-token__buttons {
      display: flex;
      justify-content: space-around;
    }
  }
</style>

<main>
  <section class="head">
    <h1>Find a token</h1>
  </section>
  <section class="body">
    {#if paramToken}
      <div class={$store.userAddress ? "param-token__wrapper" : ""}>
        <div class="param-token">
          <div class="param-token__title">
            <div>
              <img
                class="param-token__title__icon"
                src={paramToken.icon_url
                  ? paramToken.icon_url
                  : "images/tezos-coin.png"}
                alt="token icon"
              />
            </div>
            <div>{paramToken.name} ({paramToken.symbol})</div>
          </div>
          <div class="param-token__total-supply">
            Total Supply:
            {displayTokenAmount(
              paramToken.tokenID,
              paramToken.totalSupply
            ).toLocaleString("en-US")}
            tokens <br />
            <span style="font-size:0.8rem"
              >({paramToken.fixedSupply
                ? "Fixed supply"
                : "Changeable supply"})</span
            >
          </div>
          <div class="param-token__admin">
            Admin:
            <a
              href={`https://${
                $store.network === "local" || $store.network === "testnet"
                  ? "carthage."
                  : ""
              }tzkt.io/${paramToken.admin}`}
              target="_blank"
              rel="noopener noreferrer"
            >
              {`${paramToken.admin.slice(0, 10)}...${paramToken.admin.slice(
                -10
              )}`}
            </a>
          </div>
          {#if $store.userAddress}
            {#await $store.ledgerStorage.ledger.get({
              owner: $store.userAddress,
              token_id: paramToken.tokenID
            })}
              <div class="param-token__balance">Fetching your balance...</div>
              <div class="param-token__buttons">
                <button class="button blue">Loading</button>
              </div>
            {:then balance}
              <div class="param-token__balance">
                Your balance:
                {#if paramToken.symbol === "wTK"}
                  wꜩ
                  {displayTokenAmount(
                    paramToken.tokenID,
                    balance ? balance.toFixed() : 0
                  ).toLocaleString("en-US")}
                {:else}
                  {displayTokenAmount(
                    paramToken.tokenID,
                    balance ? balance.toFixed() : 0
                  ).toLocaleString("en-US")}
                {/if}
              </div>
              <div class="param-token__buttons">
                <a href={`#/exchange/buy/${paramToken.tokenID}`}>
                  <button class="button green">Buy</button>
                </a>
                {#if balance && balance.toNumber() > 0}
                  <button
                    class={`button ${sendingTransfer ? "disabled" : "blue"}`}
                    disabled={sendingTransfer}
                    on:click={() => (openTransferModal = true)}
                  >
                    {#if sendingTransfer}
                      <span>Transferring...</span><span class="spinner" />
                    {:else}
                      <span>Transfer</span>
                    {/if}
                  </button>
                  <a href={`#/exchange/sell/${paramToken.tokenID}`}>
                    <button class="button red">Sell</button>
                  </a>
                {/if}
              </div>
            {:catch error}
              <div class="param-token__balance">Balance: None</div>
            {/await}
          {/if}
        </div>
      </div>
    {/if}
    <div class="tokens-grid">
      <div class="token-name"><strong>Name</strong></div>
      <div class="token-symbol"><strong>Symbol</strong></div>
      <div class="token-totalsupply"><strong>Total Supply</strong></div>
      <div class="token-admin"><strong>Admin</strong></div>
      <div class="token-extras"><strong>Extras</strong></div>
    </div>
    <div
      class="tokens-grid"
      style={paramToken ? "max-height:350px" : "max-height: 700px"}
    >
      {#if $store.tokens === undefined}
        <div />
        <div />
        <div>Loading the tokens...</div>
        <div />
        <div />
      {:else}
        {#each $store.tokens as token, i}
          <TokenInfo {token} index={i} />
        {:else}
          <div />
          <div />
          <div>No token yet!</div>
          <div />
          <div />
        {/each}
      {/if}
    </div>
  </section>
</main>
<Modal
  modalType="transfer"
  payload={paramToken}
  open={openTransferModal}
  close={() => {
    openTransferModal = false;
  }}
  confirm={transfer}
/>
