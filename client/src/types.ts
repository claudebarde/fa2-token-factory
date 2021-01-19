export interface Token {
  tokenID: number;
  name: string;
  symbol: string;
  decimals: number;
  totalSupply: number;
  fixedSupply: boolean;
  admin?: string;
  authors?: string;
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
  | "fulfillOrder"
  | "transfer"
  | "tokenMetadata";

export type WalletType =
  | "tezbridge"
  | "thanos"
  | "beacon"
  | "kukai"
  | undefined;
