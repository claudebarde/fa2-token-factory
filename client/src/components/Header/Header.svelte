<script lang="ts">
  import { onMount, afterUpdate, onDestroy } from "svelte";
  import { TezosToolkit } from "@taquito/taquito";
  import store from "../../store";
  import { TezBridgeWallet } from "@taquito/tezbridge-wallet";
  import { BeaconWallet } from "@taquito/beacon-wallet";
  import {
    NetworkType,
    BeaconEvent,
    defaultEventCallbacks
  } from "@airgap/beacon-sdk";
  import BigNumber from "bignumber.js";
  import { Token, UserToken } from "../../types";
  import { displayTokenAmount } from "../../utils";

  const rpcAddress =
    $store.network === "local"
      ? "http://localhost:8732"
      : "https://api.tez.ie/rpc/edonet"; //"https://edonet-tezos.giganode.io";

  const setUserTokens = async (address: string): Promise<void> => {
    // retrieves user's balances after wallet connection
    const balancePromises: Promise<UserToken>[] = [];

    if ($store.tokens) {
      let userTokens: UserToken[] = [];
      $store.tokens.forEach(token =>
        balancePromises.push(
          new Promise(async (resolve, reject) => {
            let balance = await $store.ledgerStorage.ledger.get({
              owner: address,
              token_id: token.tokenID
            });
            balance = balance ? balance.toFixed() : 0;
            resolve({
              ...$store.tokens.filter(tk => tk.tokenID === token.tokenID)[0],
              balance: BigInt(balance)
            });
          })
        )
      );
      const tempTokens: UserToken[] = await Promise.all(balancePromises);
      userTokens = tempTokens.filter(tempTk => tempTk.balance !== BigInt(0));
      store.updateUserTokens(userTokens);
    }
  };

  const initTezbridgeWallet = async () => {
    const wallet = new TezBridgeWallet();
    const userAddress = await wallet.getPKH();
    store.updateWallet(wallet);
    store.updateUserAddress(userAddress);
    store.updateWalletType("tezbridge");
    $store.Tezos.setWalletProvider(wallet);
    await setUserTokens(userAddress);
  };

  const initBeacon = async () => {
    try {
      const wallet = new BeaconWallet({
        name: "Tezos Token Factory",
        preferredNetwork: NetworkType.CUSTOM,
        disableDefaultEvents: true, // Disable all events / UI. This also disables the pairing alert.
        eventHandlers: {
          // To keep the pairing alert, we have to add the following default event handlers back
          [BeaconEvent.PAIR_INIT]: {
            handler: defaultEventCallbacks.PAIR_INIT
          },
          [BeaconEvent.PAIR_SUCCESS]: {
            handler: defaultEventCallbacks.PAIR_SUCCESS
          }
        }
      });
      await wallet.requestPermissions({
        network: { type: NetworkType.CUSTOM, rpcUrl: rpcAddress }
      });
      const userAddress = await wallet.getPKH();
      store.updateWallet(wallet);
      store.updateWalletType("beacon");
      store.updateUserAddress(userAddress);
      $store.Tezos.setWalletProvider(wallet);
      await setUserTokens(userAddress);
    } catch (err) {
      console.error(err);
    }
  };

  const disconnectWallet = () => {
    if ($store.walletType === "beacon") {
      ($store.wallet as BeaconWallet).client.destroy();
    }
    store.updateWallet(undefined);
    store.updateWalletType(undefined);
    store.updateUserAddress(undefined);
    $store.Tezos.setWalletProvider(undefined);
  };

  onMount(async () => {
    const Tezos = new TezosToolkit(rpcAddress);
    store.updateTezos(Tezos);
    // creates instances for ledger and exchange
    const ledger = await Tezos.wallet.at($store.ledgerAddress[$store.network]);
    store.updateLedgerInstance(ledger);
    const ledgerStorage: any = await ledger.storage();
    store.updateLedgerStorage(ledgerStorage);

    const exchange = await Tezos.wallet.at(
      $store.exchangeAddress[$store.network]
    );
    store.updateExchangeInstance(exchange);
    const exchangeStorage = await exchange.storage();
    store.updateExchangeStorage(exchangeStorage);
    // loads tokens data
    const bigMapID = ledgerStorage.token_total_supply.toString();
    const response = await fetch(
      `https://api.better-call.dev/v1/bigmap/${
        $store.network === "testnet" ? "edo2net" : $store.network
      }/${bigMapID}/keys`
    );
    const data = await response.json();
    const tokenPromises = [];
    data
      .map(key => +key.data.key.value)
      .forEach(async tokenID => {
        tokenPromises.push(store.formatToken(tokenID, $store.ledgerStorage));
      });
    const tokensResolved = (await Promise.all(tokenPromises)).filter(el => el);
    console.log("Tokens:", tokensResolved);
    store.updateTokens(tokensResolved);

    if ($store.userAddress) {
      await setUserTokens($store.userAddress);
    }

    if (process.env.NODE_ENV === "development") {
      // connect the wallet automatically during development
      // initBeacon();
    }
  });

  afterUpdate(async () => {
    if (
      !$store.userAddress &&
      $store.userTokens &&
      $store.userTokens.length > 0
    ) {
      console.log("deleting user tokens");
      store.updateUserTokens([]);
    }
    if ($store.userAddress && $store.userTokens === undefined) {
      await setUserTokens($store.userAddress);
    }
  });

  onDestroy(() => {
    store.updateExchangeStorage(undefined);
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
            {#if process.env.NODE_ENV === "development"}
              <p on:click={initTezbridgeWallet}>TezBridge</p>
            {/if}
            <p on:click={initBeacon}>
              {process.env.NODE_ENV === "development" ? "Other" : "Connect"}
            </p>
          </div>
        {:else}
          <img
            class="user-avatar"
            src={`https://services.tzkt.io/v1/avatars/${$store.userAddress}`}
            alt="avatar"
          />
          <div class="wallet-menu" id="wallet-connected">
            <p>
              <a
                href={`https://tzkt.io/${$store.userAddress}`}
                target="_blank"
                rel="noopener noreferrer"
                >Connected as
                {`${$store.userAddress.slice(
                  0,
                  5
                )}...${$store.userAddress.slice(-5)}`}</a
              >
            </p>
            <p on:click={disconnectWallet}>Disconnect wallet</p>
            {#if $store.userTokens}
              {#each $store.userTokens as token}
                <p style="font-size:0.8rem">
                  <a href={`#/token/${token.tokenID}`}
                    >{token.symbol}
                    balance:
                    {displayTokenAmount(
                      token.tokenID,
                      token.balance
                    ).toLocaleString("en-US")}</a
                  >
                </p>
              {/each}
            {/if}
          </div>
        {/if}
      </div>
      <div class="contracts-ready">
        <a
          href={`https://better-call.dev/${
            $store.network === "testnet" ? "edo2net" : "mainnet"
          }/${$store.ledgerAddress[$store.network]}/operations`}
          target="_blank"
          rel="noreferrer noopener nofollow"
        >
          <div
            id="ledger-contract"
            class={$store.ledgerInstance === undefined ? "red" : "green"}
            title={`Ledger Contract ${
              $store.ledgerInstance === undefined
                ? "Not Connected"
                : "Connected"
            }`}
          />
        </a>
        <a
          href={`https://better-call.dev/${
            $store.network === "testnet" ? "edo2net" : "mainnet"
          }/${$store.exchangeAddress[$store.network]}/operations`}
          target="_blank"
          rel="noreferrer noopener nofollow"
        >
          <div
            id="exchange-contract"
            class={$store.exchangeInstance === undefined ? "red" : "green"}
            title={`Exchange Contract ${
              $store.ledgerInstance === undefined
                ? "Not Connected"
                : "Connected"
            }`}
          />
        </a>
      </div>
      <div class="taquito-logo">
        <a
          href="https://tezostaquito.io"
          target="_blank"
          rel="noreferrer noopener nofollow"
          ><img
            src="images/Built-with-square.png"
            alt="built with Taquito"
          /></a
        >
      </div>
    </div>
  </div>
</header>
