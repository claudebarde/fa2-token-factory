<script lang="ts">
  import store from "../../store";
  import { push } from "svelte-spa-router";
  import { Token } from "../../types";
  import { char2Bytes } from "@taquito/tzip16";

  let name = "";
  let symbol = "";
  let totalSupply = "";
  let decimals = "0";
  let author = "";
  let iconURL = "";
  let website = "";
  let emailAddress = "";
  let username = "";
  let inputError = false;
  let loading = false;

  const createNewToken = async () => {
    if (
      name &&
      symbol &&
      author &&
      symbol.length <= 5 &&
      totalSupply &&
      !isNaN(+totalSupply) &&
      decimals &&
      !isNaN(+decimals)
    ) {
      inputError = false;
      loading = true;
      // sends details to smart contract
      try {
        const tokenID = +$store.ledgerStorage.last_token_id + 1;
        /*const extras: [string, string][] = [];
        if (iconURL) extras.push(["icon_url", iconURL]);
        if (website) extras.push(["website", website]);
        if (emailAddress) extras.push(["email_address", emailAddress]);
        if (username) extras.push(["username", username]);*/

        const op = await $store.ledgerInstance.methods
          .mint_tokens(
            char2Bytes(
              `{"name":"${name}","symbol":"${symbol}","decimals":"${decimals}","authors":"[${author}]"}`
            ),
            totalSupply
          )
          .send();
        console.log(tokenID, op.opHash);
        await op.confirmation();
        // updates the token list
        let newToken: Token = {
          tokenID,
          name,
          symbol,
          decimals: +decimals,
          totalSupply: +totalSupply,
        };

        store.updateTokens([...$store.tokens, newToken]);
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
          <label for="token-name">Name:
            <input type="text" id="token-name" bind:value={name} /></label>
          <label for="token-symbol">Symbol:
            <input
              type="text"
              id="token-symbol"
              bind:value={symbol}
              maxlength="5" /></label>
        </div>
        <div class="card-body-element">
          <label for="token-decimals">Decimals:
            <input type="text" bind:value={decimals} />
          </label>
          <label for="token-total-supply">Total supply:
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
              <button class="button" on:click={createNewToken}>Confirm</button>
            {/if}
          {:else}
            <button class="button" disabled>Please connect your wallet</button>
          {/if}
        </div>
      </div>
    </div>
  </section>
</main>
