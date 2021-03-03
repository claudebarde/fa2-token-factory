import { get } from "svelte/store";

import store from "./store";

export const displayTokenAmount = (
  tokenID: number,
  amount: bigint
): bigint | string => {
  const { tokens } = get(store);

  if (tokens.length === 0) return "N/A";

  const token = tokens.filter(tk => tk.tokenID === tokenID);
  if (token.length === 0) return "N/A";
  if (token[0].decimals === undefined) return "N/A";

  if (tokenID === 1) {
    // wTK doesn't have 18 zero padding
    return BigInt(amount) / BigInt(10 ** token[0].decimals);
  } else {
    return BigInt(amount) / BigInt(10 ** token[0].decimals);
  }
};
