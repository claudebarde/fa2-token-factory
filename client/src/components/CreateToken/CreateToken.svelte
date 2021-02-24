<script lang="ts">
  import store from "../../store";
  import { push } from "svelte-spa-router";
  import { Token } from "../../types";
  import { char2Bytes } from "@taquito/tzip16";
  import ViewTransaction from "../Modal/ViewTransaction.svelte";
  import { padAmountBeforeTx } from "../../utils";

  let name = "";
  let symbol = "";
  let totalSupply = "";
  let fixedTotalSupply = true;
  let decimals = "0";
  let author = "";
  let iconURL = "";
  let website = "";
  let emailAddress = "";
  let username = "";
  let inputError = false;
  let loading = false;
  let opHash = "";
  let viewTxToast = false;

  const isFormComplete = (name, symbol, author, totalSupply, decimals) => {
    return (
      name &&
      symbol &&
      author &&
      symbol.length <= 5 &&
      totalSupply &&
      !isNaN(+totalSupply) &&
      !!decimals &&
      !isNaN(+decimals)
    );
  };

  const createNewToken = async () => {
    if (isFormComplete(name, symbol, author, totalSupply, decimals)) {
      inputError = false;
      loading = true;
      // sends details to smart contract
      try {
        const tokenID = +$store.ledgerStorage.last_token_id + 1;
        const paddedTotalSupply = padAmountBeforeTx(
          null,
          BigInt(+totalSupply) * BigInt(10 ** +decimals)
        );
        // creates array for additional metadata
        let additionalMetadata = [];
        if (iconURL.trim() && isNaN(+iconURL))
          additionalMetadata.push({ 0: "icon_url", 1: char2Bytes(iconURL) });
        if (website.trim() && isNaN(+website))
          additionalMetadata.push({ 0: "website", 1: char2Bytes(website) });
        if (emailAddress.trim() && isNaN(+emailAddress))
          additionalMetadata.push({
            0: "email_address",
            1: char2Bytes(emailAddress)
          });
        if (username.trim() && isNaN(+username))
          additionalMetadata.push({ 0: "username", 1: char2Bytes(username) });

        const op = await $store.ledgerInstance.methods
          .mint_tokens(
            [
              { 0: "name", 1: char2Bytes(name) },
              { 0: "symbol", 1: char2Bytes(symbol) },
              { 0: "decimals", 1: char2Bytes(decimals) },
              { 0: "authors", 1: char2Bytes(`[${author}]`) },
              ...additionalMetadata
            ],
            paddedTotalSupply,
            fixedTotalSupply
          )
          .send();

        console.log(tokenID, op.opHash);
        opHash = op.opHash;
        setTimeout(() => (viewTxToast = true), 2000);
        setTimeout(() => (viewTxToast = false), 6000);

        await op.confirmation();
        // updates the token list
        let newToken: Token = {
          tokenID,
          name,
          symbol,
          decimals: +decimals,
          totalSupply: paddedTotalSupply,
          fixedSupply: fixedTotalSupply,
          admin: $store.userAddress,
          authors: `[${author}]`
        };

        store.updateTokens([...$store.tokens, newToken]);
        store.updateUserTokens([
          ...$store.userTokens,
          { ...newToken, balance: paddedTotalSupply }
        ]);
        // resets the UI
        name = "";
        symbol = "";
        totalSupply = "";
        decimals = "0";
        author = "";
        iconURL = "";
        website = "";
        emailAddress = "";
        username = "";
        // navigates to token page
        push(`/token/${tokenID}`);
      } catch (error) {
        console.error(error);
      } finally {
        loading = false;
      }
    } else {
      inputError = true;
      loading = false;
      console.log("missing value");
    }
  };
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
    }
  }

  #fixed-total-supply {
    float: right;
    font-size: 0.8rem;
    cursor: pointer;

    input[type="checkbox"] {
      appearance: none;
    }
  }
</style>

<main>
  <section class="head">
    <h1>Create a new token</h1>
  </section>
  <section class="body">
    <div class="card">
      <div class="card-header">Insert here the details of the new token</div>
      <div class="card-body">
        <div class="card-body-element">
          <label for="token-name"
            >Name:
            <input type="text" id="token-name" bind:value={name} /></label
          >
          <label for="token-symbol"
            >Symbol:
            <input
              type="text"
              id="token-symbol"
              bind:value={symbol}
              maxlength="5"
            /></label
          >
        </div>
        <div class="card-body-element">
          <label for="token-decimals"
            >Decimals:
            <input type="text" bind:value={decimals} />
          </label>
          <label for="token-total-supply"
            >Total supply:
            <span
              id="fixed-total-supply"
              on:click={() => (fixedTotalSupply = !fixedTotalSupply)}
              >{fixedTotalSupply ? "Fixed" : "Changeable"}
              <input type="checkbox" bind:checked={fixedTotalSupply} /></span
            >
            <input type="text" bind:value={totalSupply} />
          </label>
        </div>
        <div class="card-body-element">
          <label for="token-creator">
            Creator:
            <input type="text" bind:value={author} />
          </label>
        </div>
        <details>
          <summary>Optional information</summary>
          <div class="card-body-element">
            <div>Icon URL:</div>
            <div><input type="text" bind:value={iconURL} /></div>
          </div>
          <div class="card-body-element">
            <div>Website:</div>
            <div><input type="text" bind:value={website} /></div>
          </div>
          <div class="card-body-element">
            <div>Email address:</div>
            <div><input type="text" bind:value={emailAddress} /></div>
          </div>
          <div class="card-body-element">
            <div>Social media username:</div>
            <div><input type="text" bind:value={username} /></div>
          </div>
        </details>
        <div class="disclaimer">
          The information you are about to confirm will be saved into a public
          blockchain, accessible to everyone and unchangeable.<br />Please
          review it properly before confirming.
        </div>
        <div class="card-error">
          {#if inputError}
            <p>The provided details are incorrect.</p>
          {:else}
            <p>&nbsp;</p>
          {/if}
        </div>
        <div class="card-buttons">
          {#if $store.userAddress}
            {#if loading}
              <button class="button" disabled>
                <span>Confirming...</span><span class="spinner" />
              </button>
            {:else}
              <button
                class={`button ${
                  isFormComplete(name, symbol, author, totalSupply, decimals)
                    ? "green"
                    : "disabled"
                }`}
                disabled={!isFormComplete(
                  name,
                  symbol,
                  author,
                  totalSupply,
                  decimals
                )}
                on:click={createNewToken}>Confirm</button
              >
            {/if}
          {:else}
            <button class="button" disabled>Please connect your wallet</button>
          {/if}
        </div>
      </div>
    </div>
  </section>
</main>
<ViewTransaction {opHash} show={viewTxToast} />
