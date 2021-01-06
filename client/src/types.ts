export interface Token {
  tokenID: number;
  name: string;
  symbol: string;
  admin: string;
  decimals: number;
  totalSupply: number;
  extras: { [n: string]: string };
}

export interface UserToken extends Token {
  balance: number;
}

export interface OrderEntry {
  order_id: number;
  created_on: string;
  order_type: "buy" | "sell";
  token_id_to_sell: number;
  token_amount_to_sell: number;
  token_id_to_buy: number;
  token_amount_to_buy: number;
  total_token_amount: number;
  seller: string;
}

export type ModalType =
  | "confirmWTKbuy"
  | "confirmWTKredeem"
  | "confirmNewOrder"
  | "deleteOrder"
  | "fulfillOrder";

export type WalletType =
  | "tezbridge"
  | "thanos"
  | "beacon"
  | "kukai"
  | undefined;
