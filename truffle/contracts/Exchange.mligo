type order_id = nat
type token_id = nat

type order_type = Buy | Sell

type order_book_entry = 
[@layout:comb]
{ 
  order_type: order_type;
  token_id_to_sell: token_id;
  token_amount_to_sell: nat;
  token_id_to_buy: token_id;
  token_amount_to_buy: nat;
  total_token_amount: nat; (* total amount of token to sell *)
  seller: address;
}

type storage =
[@layout:comb]
{
    last_order_id: order_id;
    order_book: (order_id, order_book_entry) big_map;
    ledger_address: address;
    admin: address;
}

type return = operation list * storage

type order_params =
[@layout:comb]
{
    order_id: order_id;
    amount_to_buy: nat;
    buyer: address;
}

type delete_order_params =
[@layout:comb]
{
    order_id: order_id;
    seller: address;
}

type confirm_buy_params = 
[@layout:comb]
{
  order_id: order_id;
  token_ids: nat * nat; (* token id to be sold -> token id to be bought *)
  status: bool;
  from_: address * nat; (* seller address with amount to debit *)
  to_: address * nat; (* buyer address with amount to credit *)
}

type entrypoints =
| Create_new_order of order_book_entry
| Fulfill_order of order_params
| Delete_order of order_id
| Update_ledger_address of address

(* Creates a new order *)
let create_new_order (new_order, s: order_book_entry * storage): return = 
    let new_order_id = s.last_order_id + 1n in

    ([]: operation list), 
    { s with 
        order_book = Big_map.add new_order_id new_order s.order_book; 
        last_order_id = new_order_id }

(* Fulfills an existing order *)
let fulfill_order (params, s: order_params * storage): return = 
    (* Fetches the order *)
    let order: order_book_entry = match Big_map.find_opt params.order_id s.order_book with
        | None -> (failwith "UNKNOWN_ORDER_ID": order_book_entry)
        | Some o -> o in
    if params.amount_to_buy <> order.token_amount_to_sell * order.total_token_amount
    then (failwith "WRONG_AMOUNT": return)
    else
        (* Prepares parameters to be sent back to the contract *)
        let contract: confirm_buy_params contract = 
            match ((Tezos.get_entrypoint_opt "%confirm_buy_from_exchange" s.ledger_address): confirm_buy_params contract option) with
                | None -> (failwith "UNKNOWN_CONTRACT": confirm_buy_params contract)
                | Some c -> c in
        (* Data to be sent to the ledger contract *)
        let confirm_params: confirm_buy_params = {
            order_id = params.order_id;
            token_ids = order.token_id_to_sell, order.token_id_to_buy;
            status = true;
            from_ = order.seller, order.token_amount_to_sell * order.total_token_amount;
            to_ = params.buyer, order.token_amount_to_buy * order.total_token_amount;
        } in
        let op = Tezos.transaction confirm_params 0mutez contract in
        (* Returns new operation and remove order from order book *)
        [op], { s with order_book = Big_map.remove params.order_id s.order_book }

(* Deletes an exisiting order *)
let delete_order (order_id, s: order_id * storage): return = 
    (* Fetches the order *)
    let order: order_book_entry = match Big_map.find_opt order_id s.order_book with
        | None -> (failwith "UNKNOWN_ORDER_ID": order_book_entry)
        | Some o -> o in
    (* Verifies the creator of the order asked to delete it *)
    if Tezos.sender <> order.seller
    then (failwith "UNAUTHORIZED_DELETE_ACTION": return)
    else
        ([]: operation list), { s with order_book = Big_map.remove order_id s.order_book }

(* Updates the main contract address *)
let update_ledger_address (new_address, s: address * storage): return =
    if Tezos.sender <> s.admin
    then (failwith "NOT_AN_ADMIN": return)
    else
        ([]: operation list), { s with ledger_address = new_address }

let main (entrypoints, s: entrypoints * storage): return =
    (* This contract only accepts calls from the main ledger contract or the admin *)
    if Tezos.sender <> s.ledger_address && Tezos.sender <> s.admin
    then (failwith "UNAUTHORIZED_SENDER": return)
    else
        let result = match entrypoints with
            | Create_new_order p -> create_new_order (p, s)
            | Fulfill_order p -> fulfill_order (p, s)
            | Delete_order p -> delete_order (p, s)
            | Update_ledger_address p -> update_ledger_address (p, s)
        in
        result.0, result.1