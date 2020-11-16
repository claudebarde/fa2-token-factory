import { writable } from "svelte/store";
import { TezosToolkit } from "@taquito/taquito";
import { TezBridgeWallet } from "@taquito/tezbridge-wallet";

interface State {
  Tezos: TezosToolkit;
  wallet: TezBridgeWallet;
  userAddress: string | undefined;
}

const initialState: State = {
  Tezos: undefined,
  wallet: undefined,
  userAddress: undefined
};

const store = writable(initialState);

const state = {
  subscribe: store.subscribe,
  updateTezos: (tezos: TezosToolkit) =>
    store.update(store => ({ ...store, Tezos: tezos })),
  updateWallet: (wallet: TezBridgeWallet) =>
    store.update(store => ({ ...store, wallet })),
  updateUserAddress: (address: string) => {
    store.update(store => ({ ...store, userAddress: address }));
  }
};

export default state;
