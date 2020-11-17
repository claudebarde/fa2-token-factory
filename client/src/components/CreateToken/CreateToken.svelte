<script lang="ts">
  import store from "../../store";

  let name = "";
  let symbol = "";
  let totalSupply = "";
  let decimals = "0";
  let iconURL = "";
  let website = "";
  let emailAddress = "";
  let username = "";
  let inputError = false;

  const createNewToken = async () => {
    if (
      name &&
      symbol &&
      symbol.length <= 5 &&
      totalSupply &&
      !isNaN(+totalSupply) &&
      decimals &&
      !isNaN(+decimals)
    ) {
      inputError = false;
      // sends details to smart contract
      try {
        const tokenID = +$store.ledgerStorage.last_token_id + 1;
        const extras: [string, string][] = [];
        if (iconURL) extras.push(["icon_url", iconURL]);
        if (website) extras.push(["website", website]);
        if (emailAddress) extras.push(["email_address", emailAddress]);
        if (username) extras.push(["username", username]);

        const op = await $store.ledgerInstance.methods
          .mint_tokens(symbol, name, decimals, totalSupply, extras)
          .send();
        console.log(tokenID, op.opHash);
        await op.confirmation();
      } catch (error) {
        console.error(error);
      }
    } else {
      inputError = true;
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
          <div>Name:</div>
          <div><input type="text" bind:value={name} /></div>
        </div>
        <div class="card-body-element">
          <div>Symbol:</div>
          <div><input type="text" bind:value={symbol} maxlength="5" /></div>
        </div>
        <div class="card-body-element">
          <div>Total supply:</div>
          <div><input type="text" bind:value={totalSupply} /></div>
        </div>
        <div class="card-body-element">
          <div>Decimals:</div>
          <div><input type="text" bind:value={decimals} /></div>
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
            <button on:click={createNewToken}>Confirm</button>
          {:else}<button disabled>Please connect your wallet</button>{/if}
        </div>
      </div>
    </div>
  </section>
</main>
