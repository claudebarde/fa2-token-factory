import { writable } from "svelte/store";
import { TezosToolkit, ContractAbstraction, Wallet } from "@taquito/taquito";
import { TezBridgeWallet } from "@taquito/tezbridge-wallet";
import { BeaconWallet } from "@taquito/beacon-wallet";
import { Token, UserToken, WalletType, OrderEntry } from "./types";
import { bytes2Char } from "@taquito/tzip16";

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
  tokens: Token[] | undefined;
  userTokens: UserToken[] | undefined;
  orderBook: OrderEntry[];
}

//delphinet ledger: "KT1QrBZwRKSRCdnSAngLnTjfB75zuynib9cV"

const initialState: State = {
  Tezos: undefined,
  wallet: undefined,
  walletType: undefined,
  userAddress: undefined,
  network: "testnet", //process.env.NODE_ENV === "development" ? "local" : "testnet",
  ledgerAddress: {
    mainnet: "",
    testnet: "KT1JL5UB3XQ7xMunxdt3CcASpDTD7hRKZ4FR", // "KT1EDfz96aRkbhS6TPJ7P1HbbQF8963mVZQK",
    local: "KT1HCTmt3U4aXcTSw5zx8kEejWRpQssT674Y"
  },
  exchangeAddress: {
    mainnet: "",
    testnet: "KT1NeQPgw5VMLVEoBT6pJYvAp13gLJ3JAtdD", // "KT1PMGdzKm5t2zd2wibM4HNDcd2sdS8Y8uDw",
    local: "KT1Lb9Afrp6H9bpdRAhBRGH8CTgonwbWUwSq"
  },
  ledgerInstance: undefined,
  ledgerStorage: undefined,
  exchangeInstance: undefined,
  exchangeStorage: undefined,
  tokens: undefined,
  userTokens: undefined,
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
    // sorts token alphabetically by symbol
    const newTokens = [...tokens];
    newTokens.sort((a, b) =>
      a.symbol > b.symbol ? 1 : b.symbol > a.symbol ? -1 : 0
    );
    store.update(store => ({ ...store, tokens: newTokens }));
  },
  formatToken: async (tokenId: number, ledger: any): Promise<Token | null> => {
    const token = await ledger.token_metadata.get(tokenId.toString());
    if (!token) return null;

    const totalSupply = await ledger.token_total_supply.get(tokenId.toString());
    const admin = await ledger.token_admins.get(tokenId.toString());

    let metadata: {
      name: string;
      decimals: number;
      symbol: string;
      authors: string;
    } = {
      name: "",
      decimals: 0,
      symbol: "",
      authors: ""
    };
    for (let entry of token[1].entries()) {
      metadata[entry[0]] = bytes2Char(entry[1]);
    }

    if (metadata.hasOwnProperty("")) {
      // empty key indicates a JSON string of metadata
      const jsonMetadata = JSON.parse(metadata[""]);
      delete metadata[""];
      metadata = { ...metadata, ...jsonMetadata };
    }

    return {
      tokenID: tokenId,
      admin: admin[0],
      totalSupply: BigInt(totalSupply.toFixed()),
      fixedSupply: admin[1],
      ...metadata
    };
  },
  updateUserTokens: (tokens: UserToken[]) => {
    // sorts token alphabetically by symbol
    const newTokens = [...tokens];
    newTokens.sort((a, b) =>
      a.symbol > b.symbol ? 1 : b.symbol > a.symbol ? -1 : 0
    );
    store.update(store => ({ ...store, userTokens: newTokens }));
  },
  updateOrderBook: (orders: OrderEntry[]) => {
    store.update(store => ({ ...store, orderBook: orders }));
  }
};

export default state;
