<script lang="ts">
  import { onMount } from "svelte";
  import { TezosToolkit } from "@taquito/taquito";
  import store from "../../store";
  import { TezBridgeWallet } from "@taquito/tezbridge-wallet";
  import { BeaconWallet } from "@taquito/beacon-wallet";
  import { NetworkType } from "@airgap/beacon-sdk";
  import { ThanosWallet } from "@thanos-wallet/dapp";

  const rpcAddress = "http://localhost:8732";

  const initTezbridgeWallet = async () => {
    const wallet = new TezBridgeWallet();
    const userAddress = await wallet.getPKH();
    store.updateWallet(wallet);
    store.updateUserAddress(userAddress);
    $store.Tezos.setWalletProvider(wallet);
  };

  const initBeaconWallet = async () => {
    const wallet = new BeaconWallet({ name: "Tezos Token Factory" });
    await wallet.requestPermissions({ network: { type: NetworkType.CUSTOM } });
    const userAddress = await wallet.getPKH();
    store.updateWallet(wallet);
    store.updateUserAddress(userAddress);
    $store.Tezos.setWalletProvider(wallet);
  };

  const initThanosWallet = async () => {
    if (await ThanosWallet.isAvailable()) {
      const wallet = new ThanosWallet("Tezos Token Factory");
      await wallet.connect("sandbox", { forcePermission: true });
      const userAddress = await wallet.getPKH();
      store.updateWallet(wallet);
      store.updateUserAddress(userAddress);
      $store.Tezos.setWalletProvider(wallet);
    }
  };

  onMount(async () => {
    const Tezos = new TezosToolkit(rpcAddress);
    store.updateTezos(Tezos);
    // creates instances for ledger and exchange
    const ledger = await Tezos.wallet.at($store.ledgerAddress[$store.network]);
    store.updateLedgerInstance(ledger);
    const ledgerStorage = await ledger.storage();
    store.updateLedgerStorage(ledgerStorage);

    const exchange = await Tezos.wallet.at(
      $store.ledgerAddress[$store.network]
    );
    store.updateExchangeInstance(exchange);
    const exchangeStorage = await exchange.storage();
    store.updateExchangeStorage(exchangeStorage);
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

    a {
      color: white;
      text-decoration: none;
    }

    .left {
      padding: 0px 15px;
      img {
        width: 30px;
        vertical-align: middle;
      }
    }
  }

  .navigation {
    padding: 0;
    margin: 0;
    height: 100%;
    font-size: 1.1rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0px;

    .nav-button {
      cursor: pointer;
      background-color: #2d3748;
      transition: 0.3s;
      height: 50px;
      padding: 0px 20px;
      display: flex;
      justify-content: center;
      align-items: center;

      &:hover {
        background-color: lighten(#2d3748, 10);
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
    padding: 0px 15px;
    img {
      width: 40px;
    }
  }

  .user-avatar {
    width: 50px;
  }

  .contracts-ready {
    display: flex;
    justify-content: center;
    align-items: center;
    div {
      width: 8px;
      height: 8px;
      margin: 5px;
      border-radius: 50px;

      &.red {
        background-color: #e53e3e;
      }

      &.green {
        background-color: #38a169;
      }
    }
  }
</style>

<header>
  <div class="left">
    <a href="#/">
      <img src="images/tezos-coin.png" alt="tezos-coin" />
      <span>Tezos Token Factory</span>
    </a>
  </div>
  <div class="right">
    <div class="navigation">
      <div class="nav-button"><a href="#/createtoken">Create Token</a></div>
      <div class="nav-button"><a href="#/token">Find Token</a></div>
      <div class="nav-button"><a href="#/exchange">Exchange</a></div>
      <div class="nav-button" id="wallet-button">
        {#if $store.userAddress === undefined}
          <span>Wallet</span>
          <div class="wallet-menu" id="connect-wallet">
            <p on:click={initTezbridgeWallet}>TezBridge</p>
            <p on:click={initBeaconWallet}>Beacon</p>
            <p on:click={initThanosWallet}>Thanos</p>
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
      <div class="contracts-ready">
        <div
          id="ledger-contract"
          class={$store.ledgerInstance === undefined ? 'red' : 'green'}
          title={`Ledger Contract ${$store.ledgerInstance === undefined ? 'Not Connected' : 'Connected'}`} />
        <div
          id="exchange-contract"
          class={$store.exchangeInstance === undefined ? 'red' : 'green'}
          title={`Exchange Contract ${$store.ledgerInstance === undefined ? 'Not Connected' : 'Connected'}`} />
      </div>
      <div class="taquito-logo">
        <a
          href="https://tezostaquito.io"
          target="_blank"
          rel="noreferrer noopener"><img
            src="images/Built-with-square.png"
            alt="built with Taquito" /></a>
      </div>
    </div>
  </div>
</header>
