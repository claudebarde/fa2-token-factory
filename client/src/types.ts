export interface Token {
  tokenID: number;
  name: string;
  symbol: string;
  decimals: number;
  totalSupply: bigint;
  fixedSupply: boolean;
  admin?: string;
  authors?: string;
}

export interface UserToken extends Token {
  balance: bigint;
}

export interface OrderEntry {
  order_id: number;
  created_on: string;
  order_type: "buy" | "sell";
  token_id_to_sell: number;
  token_amount_to_sell: bigint;
  token_id_to_buy: number;
  token_amount_to_buy: bigint;
  total_token_amount: bigint;
  seller: string;
}

export type ModalType =
  | "confirmWTKbuy"
  | "confirmWTKredeem"
  | "confirmNewOrder"
  | "deleteOrder"
  | "fulfillOrder"
  | "transfer"
  | "tokenMetadata";

export type WalletType =
  | "tezbridge"
  | "thanos"
  | "beacon"
  | "kukai"
  | undefined;

export enum ExchangeError {
  NOBUYTOKEN,
  NOSELLTOKEN,
  IDENTICALBUYANDSELL,
  INVALIDSELLVALUE,
  INVALIDBUYVALUE
}
