import { writable } from "svelte/store";
import { TezosToolkit, ContractAbstraction, Wallet } from "@taquito/taquito";
import { TezBridgeWallet } from "@taquito/tezbridge-wallet";
import { BeaconWallet } from "@taquito/beacon-wallet";
import { Token, UserToken, WalletType, OrderEntry } from "./types";

interface State {
  Tezos: TezosToolkit;
  wallet: TezBridgeWallet | BeaconWallet;
  walletType: WalletType;
  userAddress: string | undefined;
  network: "mainnet" | "testnet" | "local";
  ledgerAddress: { mainnet: string; testnet: string; local: string };
  exchangeAddress: { mainnet: string; testnet: string; local: string };
  ledgerInstance: ContractAbstraction<Wallet> | undefined;
  ledgerStorage: any;
  exchangeInstance: ContractAbstraction<Wallet> | undefined;
  exchangeStorage: any;
  tokens: Token[];
  userTokens: UserToken[];
  orderBook: OrderEntry[];
}

const initialState: State = {
  Tezos: undefined,
  wallet: undefined,
  walletType: undefined,
  userAddress: undefined,
  network: "testnet", //process.env.NODE_ENV === "development" ? "local" : "testnet",
  ledgerAddress: {
    mainnet: "",
    testnet: "KT1F3KRQ6z5xq9cDyisSE2AzUKL1JC4SwcXh",
    local: "KT1HCTmt3U4aXcTSw5zx8kEejWRpQssT674Y"
  },
  exchangeAddress: {
    mainnet: "",
    testnet: "KT1GzvNGwD9YtFp2NAY6tnUUjVnsH2cMiK8v",
    local: "KT1Lb9Afrp6H9bpdRAhBRGH8CTgonwbWUwSq"
  },
  ledgerInstance: undefined,
  ledgerStorage: undefined,
  exchangeInstance: undefined,
  exchangeStorage: undefined,
  tokens: [],
  userTokens: [],
  orderBook: []
};

const store = writable(initialState);

const state = {
  subscribe: store.subscribe,
  updateTezos: (tezos: TezosToolkit) =>
    store.update(store => ({ ...store, Tezos: tezos })),
  updateWallet: (wallet: TezBridgeWallet | BeaconWallet) =>
    store.update(store => ({ ...store, wallet })),
  updateWalletType: (walletType: WalletType) =>
    store.update(store => ({ ...store, walletType })),
  updateUserAddress: (address: string) => {
    store.update(store => ({ ...store, userAddress: address }));
  },
  updateLedgerInstance: (instance: ContractAbstraction<Wallet>) => {
    store.update(store => ({ ...store, ledgerInstance: instance }));
  },
  updateExchangeInstance: (instance: ContractAbstraction<Wallet>) => {
    store.update(store => ({ ...store, exchangeInstance: instance }));
  },
  updateLedgerStorage: (storage: any) => {
    store.update(store => ({ ...store, ledgerStorage: storage }));
  },
  updateExchangeStorage: (storage: any) => {
    store.update(store => ({ ...store, exchangeStorage: storage }));
  },
  updateTokens: (tokens: Token[]) => {
    store.update(store => ({ ...store, tokens }));
  },
  formatToken: async (tokenId: number, ledger: any): Promise<Token | null> => {
    const entry = await ledger.token_metadata.get(tokenId.toString());
    if (!entry) return null;

    const totalSupply = await ledger.token_total_supply.get(tokenId.toString());
    const extras = {};
    entry.extras.forEach((value, key) => (extras[key] = value));

    return {
      tokenID: tokenId,
      name: entry.name,
      symbol: entry.symbol,
      admin: entry.admin,
      decimals: entry.decimals.toNumber(),
      totalSupply: totalSupply.toNumber(),
      extras
    };
  },
  updateUserTokens: (tokens: UserToken[]) => {
    store.update(store => ({ ...store, userTokens: tokens }));
  },
  updateOrderBook: (orders: OrderEntry[]) => {
    store.update(store => ({ ...store, orderBook: orders }));
  }
};

export default state;
