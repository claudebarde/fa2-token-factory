type order_id = nat
type token_id = nat

type order_book_entry = 
[@layout:comb]
{ 
    token_id_to_sell: token_id;
    token_amount_to_sell: nat;
    token_id_to_buy: token_id;
    token_amount_to_buy: nat;
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

type new_order =
[@layout:comb]
{
    token_id_to_sell: token_id;
    token_amount_to_sell: nat;
    token_id_to_buy: token_id;
    token_amount_to_buy: nat;
}

type order_params =
[@layout:comb]
{
    order_id: order_id;
    amount_to_buy: nat;
}

type entrypoints =
| Create_new_order of new_order
| Fulfill_order of order_params
| Update_ledger_address of address

let create_new_order (params, s: new_order * storage): return = 
    ([]: operation list), s

let fulfill_order (params, s: order_params * storage): return = 
    ([]: operation list), s

let update_ledger_address (new_address, s: address * storage) =
    ([]: operation list), { s with ledger_address = new_address }

let main (entrypoints, s: entrypoints * storage): return =
    (* This contract only accepts calls from the main ledger contract or the admin *)
    if Tezos.sender <> s.ledger_address || Tezos.sender <> s.admin
    then (failwith "UNAUTHORIZED_SENDER": return)
    else
        let result = match entrypoints with
            | Create_new_order p -> create_new_order (p, s)
            | Fulfill_order p -> fulfill_order (p, s)
            | Update_ledger_address p -> update_ledger_address (p, s)
        in
        result.0, result.1