<script lang="ts">
  import { onMount } from "svelte";
  import { TezosToolkit } from "@taquito/taquito";
  import store from "../../store";
  import { TezBridgeWallet } from "@taquito/tezbridge-wallet";
  import App from "src/App.svelte";

  const initTezbridgeWallet = async () => {
    const wallet = new TezBridgeWallet();
    const userAddress = await wallet.getPKH();
    store.updateWallet(wallet);
    store.updateUserAddress(userAddress);
  };

  onMount(() => {
    store.updateTezos(new TezosToolkit("http://localhost:8732"));
  });
</script>

<style lang="scss">
  header {
    margin: 0px;
    padding: 0px;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 1.2rem;
    background-color: #2d3748;
    color: white;

    div {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0px 10px;
    }
  }

  .navigation {
    padding: 0;
    margin: 0;
    height: 100%;
    font-size: 1.1rem;

    .nav-button {
      cursor: pointer;
      background-color: #2d3748;
      transition: 0.3s;
      height: 50px;

      &:hover {
        background-color: lighten(#2d3748, 10);
      }

      a {
        color: white;
        text-decoration: none;
      }
    }

    #wallet-button {
      position: relative;

      .wallet-menu {
        display: none;
        position: absolute;
        top: 50px;
        right: 0;
        flex-direction: column;
        background-color: lighten(#2d3748, 10);
        padding: 0;

        &#connect-wallet {
          width: 150px;

          p {
            width: 110px;
          }
        }

        &#wallet-connected {
          width: 400px;

          p {
            width: 360px;
          }
        }

        p {
          margin: 0;
          padding: 10px 20px;
          text-align: center;
          transition: 0.2s;
        }
        p:hover {
          background-color: lighten(#2d3748, 20);
        }
      }

      &:hover .wallet-menu {
        display: flex;
      }
    }
  }

  .taquito-logo {
    width: 40px;
  }

  .user-avatar {
    width: 50px;
  }
</style>

<header>
  <div>Tezos Token Factory</div>
  <div>
    <div class="navigation">
      <div class="nav-button"><a href="#/createtoken">Create Token</a></div>
      <div class="nav-button"><a href="#/token">Find Token</a></div>
      <div class="nav-button" id="wallet-button">
        {#if $store.userAddress === undefined}
          <span>Wallet</span>
          <div class="wallet-menu" id="connect-wallet">
            <p on:click={initTezbridgeWallet}>TezBridge</p>
            <p>Beacon</p>
            <p>Thanos</p>
          </div>
        {:else}
          <img
            class="user-avatar"
            src={`https://services.tzkt.io/v1/avatars/${$store.userAddress}`}
            alt="avatar" />
          <div class="wallet-menu" id="wallet-connected">
            <p>
              <a
                href={`https://tzkt.io/${$store.userAddress}`}
                target="_blank"
                rel="noopener noreferrer">Connected as
                {`${$store.userAddress.slice(0, 5)}...${$store.userAddress.slice(-5)}`}</a>
            </p>
          </div>
        {/if}
      </div>
    </div>
    <div>
      <a
        href="https://tezostaquito.io"
        target="_blank"
        rel="noreferrer noopener"><img
          src="images/Built-with-square.png"
          alt="built with Taquito"
          class="taquito-logo" /></a>
    </div>
  </div>
</header>
