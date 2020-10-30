type token_id = nat

type order_type = Buy | Sell

type order_book_entry = { 
  order_type: order_type;
  token_id_to_sell: token_id;
  token_amount_to_sell: nat;
  token_id_to_buy: token_id;
  token_amount_to_buy: nat;
  total_token_amount: nat;
  seller: address;
}

type exchange_order_params = {
  order_type: order_type;
  token_id_to_sell: token_id;
  token_amount_to_sell: nat;
  token_id_to_buy: token_id;
  token_amount_to_buy: nat;
  total_token_amount: nat; (* total amount of token to sell *)
}

type exchange_order_params_michelson = exchange_order_params michelson_pair_right_comb

type storage = {
  order_count: nat;
  order_book: (nat, order_book_entry) big_map;
}

let main (p, s: exchange_order_params_michelson * storage) =
  let params: exchange_order_params = Layout.convert_from_right_comb p in
  let new_order: order_book_entry = {
    order_type = params.order_type;
    token_id_to_sell = params.token_id_to_sell;
    token_amount_to_sell = params.token_amount_to_sell;
    token_id_to_buy = params.token_id_to_buy;
    token_amount_to_buy = params.token_amount_to_buy;
    total_token_amount = params.total_token_amount;
    seller = Tezos.sender
  } in
  let new_order_id: nat = s.order_count + 1n in
  
  ([] : operation list), 
  { s with order_book = Big_map.add new_order_id new_order s.order_book; order_count = new_order_id }
