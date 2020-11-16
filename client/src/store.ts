import { writable } from "svelte/store";
import { TezosToolkit, Wallet } from "@taquito/taquito";

interface State {
  Tezos: TezosToolkit;
  wallet: Wallet;
}

const initialState: State = {
  Tezos: undefined,
  wallet: undefined
};

const store = writable(initialState);

const state = {
  subscribe: store.subscribe,
  updateTezos: (tezos: TezosToolkit) =>
    store.update(store => ({ ...store, Tezos: tezos })),
  updateWallet: (wallet: Wallet) =>
    store.update(store => ({ ...store, wallet }))
};

export default state;
