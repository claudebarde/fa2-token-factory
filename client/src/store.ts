import { writable } from "svelte/store";
import { TezosToolkit, ContractAbstraction, Wallet } from "@taquito/taquito";
import { TezBridgeWallet } from "@taquito/tezbridge-wallet";
import { BeaconWallet } from "@taquito/beacon-wallet";
import { ThanosWallet } from "@thanos-wallet/dapp";
import { Token } from "./types";

interface State {
  Tezos: TezosToolkit;
  wallet: TezBridgeWallet | BeaconWallet | ThanosWallet;
  userAddress: string | undefined;
  network: "mainnet" | "testnet" | "local";
  ledgerAddress: { mainnet: string; testnet: string; local: string };
  exchangeAddress: { mainnet: string; testnet: string; local: string };
  ledgerInstance: ContractAbstraction<Wallet> | undefined;
  ledgerStorage: any;
  exchangeInstance: ContractAbstraction<Wallet> | undefined;
  exchangeStorage: any;
  tokens: Token[];
}

const initialState: State = {
  Tezos: undefined,
  wallet: undefined,
  userAddress: undefined,
  network: process.env.NODE_ENV === "development" ? "local" : "testnet",
  ledgerAddress: {
    mainnet: "",
    testnet: "KT1DkGxeQKBjVQXpTzEzkrFWEZgxYcXEFYxZ",
    local: "KT1SGa8s6L92sxg5f3EZnyMv8Pi3J4odHWQd"
  },
  exchangeAddress: {
    mainnet: "",
    testnet: "KT1PiomgGFtHUtwPvyPWpLscV71HLxRdCkAv",
    local: "KT1GEcGA4P4RTP1JmDh8UJA6o9Amgaqqq2UF"
  },
  ledgerInstance: undefined,
  ledgerStorage: undefined,
  exchangeInstance: undefined,
  exchangeStorage: undefined,
  tokens: []
};

const store = writable(initialState);

const state = {
  subscribe: store.subscribe,
  updateTezos: (tezos: TezosToolkit) =>
    store.update(store => ({ ...store, Tezos: tezos })),
  updateWallet: (wallet: TezBridgeWallet | BeaconWallet | ThanosWallet) =>
    store.update(store => ({ ...store, wallet })),
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
  }
};

export default state;
