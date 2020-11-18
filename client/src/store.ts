import { writable } from "svelte/store";
import { TezosToolkit, ContractAbstraction, Wallet } from "@taquito/taquito";
import { TezBridgeWallet } from "@taquito/tezbridge-wallet";
import { BeaconWallet } from "@taquito/beacon-wallet";
import { ThanosWallet } from "@thanos-wallet/dapp";

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
}

const initialState: State = {
  Tezos: undefined,
  wallet: undefined,
  userAddress: undefined,
  network: process.env.NODE_ENV === "development" ? "local" : "testnet",
  ledgerAddress: {
    mainnet: "",
    testnet: "",
    local: "KT1WhGJw8cSm8zduruEssnVGzVbbxKF7E8MS"
  },
  exchangeAddress: {
    mainnet: "",
    testnet: "",
    local: "KT1CdYJJ6dkMmD5ApLmmaboEFpnxiusf2yvX"
  },
  ledgerInstance: undefined,
  ledgerStorage: undefined,
  exchangeInstance: undefined,
  exchangeStorage: undefined
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
  }
};

export default state;
