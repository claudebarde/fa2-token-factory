# 1 "./multi_asset/ligo/src/fa2_multi_token.mligo"




# 1 "./multi_asset/ligo/src/../fa2/fa2_interface.mligo" 1



type token_id = nat
type order_id = nat

type transfer_destination = {
  to_ : address;
  token_id : token_id;
  amount : nat;
}

type transfer_destination_michelson = transfer_destination michelson_pair_right_comb

type transfer = {
  from_ : address;
  txs : transfer_destination list;
}

type transfer_aux = {
  from_ : address;
  txs : transfer_destination_michelson list;
}

type transfer_michelson = transfer_aux michelson_pair_right_comb

type balance_of_request = {
  owner : address;
  token_id : token_id;
}

type balance_of_request_michelson = balance_of_request michelson_pair_right_comb

type balance_of_response = {
  request : balance_of_request;
  balance : nat;
}

type balance_of_response_aux = {
  request : balance_of_request_michelson;
  balance : nat;
}

type balance_of_response_michelson = balance_of_response_aux michelson_pair_right_comb

type balance_of_param = {
  requests : balance_of_request list;
  callback : (balance_of_response_michelson list) contract;
}

type balance_of_param_aux = {
  requests : balance_of_request_michelson list;
  callback : (balance_of_response_michelson list) contract;
}

type balance_of_param_michelson = balance_of_param_aux michelson_pair_right_comb

type operator_param = {
  owner : address;
  operator : address;
  token_id: token_id;
}

type operator_param_michelson = operator_param michelson_pair_right_comb

type update_operator =
  | Add_operator_p of operator_param
  | Remove_operator_p of operator_param

type update_operator_aux =
  | Add_operator of operator_param_michelson
  | Remove_operator of operator_param_michelson

type update_operator_michelson = update_operator_aux michelson_or_right_comb

type token_metadata = {
  token_id : token_id;
  admin : address;
  symbol : string;
  name : string;
  decimals : nat;
  extras : (string, string) map;
}

type token_metadata_michelson = token_metadata michelson_pair_right_comb

type token_metadata_param = {
  token_ids : token_id list;
  handler : (token_metadata_michelson list) -> unit;
}

type token_metadata_param_michelson = token_metadata_param michelson_pair_right_comb

type mint_tokens_params = {
    token_id: token_id;
    symbol: string;
    name: string;
    decimals: nat;
    extras : (string * string) list;
    total_supply: nat;
}

type mint_tokens_params_michelson = mint_tokens_params michelson_pair_right_comb

type order_type = Buy | Sell

type order_book_entry = { 
  order_type: order_type;
  token_id_to_sell: token_id;
  token_amount_to_sell: nat;
  token_id_to_buy: token_id;
  token_amount_to_buy: nat;
  seller: address;
}

type exchange_order_params = {
  order_type: order_type;
  token_id_to_sell: token_id;
  token_amount_to_sell: nat;
  token_id_to_buy: token_id;
  token_amount_to_buy: nat;
}

type exchange_order_params_michelson = exchange_order_params michelson_pair_right_comb

type fa2_entry_points =
  | Transfer of transfer_michelson list
  | Balance_of of balance_of_param_michelson
  | Update_operators of update_operator_michelson list
  | Token_metadata_registry of address contract
  | Mint_tokens of mint_tokens_params_michelson
  | Burn_tokens of token_id * nat
  | New_exchange_order of exchange_order_params_michelson
  | Buy_from_exchange of order_id * nat


type fa2_token_metadata =
  | Token_metadata of token_metadata_param_michelson

(* permission policy definition *)

type operator_transfer_policy =
  | No_transfer
  | Owner_transfer
  | Owner_or_operator_transfer

type operator_transfer_policy_michelson = operator_transfer_policy michelson_or_right_comb

type owner_hook_policy =
  | Owner_no_hook
  | Optional_owner_hook
  | Required_owner_hook

type owner_hook_policy_michelson = owner_hook_policy michelson_or_right_comb

type custom_permission_policy = {
  tag : string;
  config_api: address option;
}

type custom_permission_policy_michelson = custom_permission_policy michelson_pair_right_comb

type permissions_descriptor = {
  operator : operator_transfer_policy;
  receiver : owner_hook_policy;
  sender : owner_hook_policy;
  custom : custom_permission_policy option;
}

type permissions_descriptor_aux = {
  operator : operator_transfer_policy_michelson;
  receiver : owner_hook_policy_michelson;
  sender : owner_hook_policy_michelson;
  custom : custom_permission_policy_michelson option;
}

type permissions_descriptor_michelson = permissions_descriptor_aux michelson_pair_right_comb

(* permissions descriptor entrypoint
type fa2_entry_points_custom =
  ...
  | Permissions_descriptor of permissions_descriptor_michelson contract

*)


type transfer_destination_descriptor = {
  to_ : address option;
  token_id : token_id;
  amount : nat;
}

type transfer_destination_descriptor_michelson =
  transfer_destination_descriptor michelson_pair_right_comb

type transfer_descriptor = {
  from_ : address option;
  txs : transfer_destination_descriptor list
}

type transfer_descriptor_aux = {
  from_ : address option;
  txs : transfer_destination_descriptor_michelson list
}

type transfer_descriptor_michelson = transfer_descriptor_aux michelson_pair_right_comb

type transfer_descriptor_param = {
  batch : transfer_descriptor list;
  operator : address;
}

type transfer_descriptor_param_aux = {
  batch : transfer_descriptor_michelson list;
  operator : address;
}

type transfer_descriptor_param_michelson = transfer_descriptor_param_aux michelson_pair_right_comb
(*
Entrypoints for sender/receiver hooks

type fa2_token_receiver =
  ...
  | Tokens_received of transfer_descriptor_param_michelson

type fa2_token_sender =
  ...
  | Tokens_sent of transfer_descriptor_param_michelson
*)



# 5 "./multi_asset/ligo/src/fa2_multi_token.mligo" 2

# 1 "./multi_asset/ligo/src/../fa2/fa2_errors.mligo" 1



(** One of the specified `token_id`s is not defined within the FA2 contract *)
let fa2_token_undefined = "FA2_TOKEN_UNDEFINED" 
(** 
A token owner does not have sufficient balance to transfer tokens from
owner's account 
*)
let fa2_insufficient_balance = "FA2_INSUFFICIENT_BALANCE"
(** A transfer failed because of `operator_transfer_policy == No_transfer` *)
let fa2_tx_denied = "FA2_TX_DENIED"
(** 
A transfer failed because `operator_transfer_policy == Owner_transfer` and it is
initiated not by the token owner 
*)
let fa2_not_owner = "FA2_NOT_OWNER"
(**
A transfer failed because `operator_transfer_policy == Owner_or_operator_transfer`
and it is initiated neither by the token owner nor a permitted operator
 *)
let fa2_not_operator = "FA2_NOT_OPERATOR"
(** 
`update_operators` entrypoint is invoked and `operator_transfer_policy` is
`No_transfer` or `Owner_transfer`
*)
let fa2_operators_not_supported = "FA2_OPERATORS_UNSUPPORTED"
(**
Receiver hook is invoked and failed. This error MUST be raised by the hook
implementation
 *)
let fa2_receiver_hook_failed = "FA2_RECEIVER_HOOK_FAILED"
(**
Sender hook is invoked and failed. This error MUST be raised by the hook
implementation
 *)
let fa2_sender_hook_failed = "FA2_SENDER_HOOK_FAILED"
(**
Receiver hook is required by the permission behavior, but is not implemented by
a receiver contract
 *)
let fa2_receiver_hook_undefined = "FA2_RECEIVER_HOOK_UNDEFINED"
(**
Sender hook is required by the permission behavior, but is not implemented by
a sender contract
 *)
let fa2_sender_hook_undefined = "FA2_SENDER_HOOK_UNDEFINED"



# 6 "./multi_asset/ligo/src/fa2_multi_token.mligo" 2

# 1 "./multi_asset/ligo/src/../fa2/lib/fa2_operator_lib.mligo" 1
(** 
Reference implementation of the FA2 operator storage, config API and 
helper functions 
*)





# 1 "./multi_asset/ligo/src/../fa2/lib/fa2_convertors.mligo" 1
(**
Helper function to convert FA2 entrypoints input parameters between their
Michelson and internal LIGO representation.

FA2 contract implementation must conform to the Michelson entrypoints interface
outlined in the FA2 standard for interoperability with other contracts and off-chain
tools.
 *)





# 1 "./multi_asset/ligo/src/../fa2/lib/../fa2_interface.mligo" 1








































































































































































































































# 14 "./multi_asset/ligo/src/../fa2/lib/fa2_convertors.mligo" 2

let permissions_descriptor_to_michelson (d : permissions_descriptor)
    : permissions_descriptor_michelson =
  let aux : permissions_descriptor_aux = {
    operator = Layout.convert_to_right_comb d.operator;
    receiver = Layout.convert_to_right_comb d.receiver;
    sender = Layout.convert_to_right_comb d.sender;
    custom = match d.custom with
    | None -> (None : custom_permission_policy_michelson option)
    | Some c -> Some (Layout.convert_to_right_comb c)
  } in
  Layout.convert_to_right_comb (aux : permissions_descriptor_aux)

let transfer_descriptor_to_michelson (p : transfer_descriptor) : transfer_descriptor_michelson =
  let aux : transfer_descriptor_aux = {
    from_ = p.from_;
    txs = List.map 
      (fun (tx : transfer_destination_descriptor) ->
        Layout.convert_to_right_comb tx
      )
      p.txs;
  } in
  Layout.convert_to_right_comb (aux : transfer_descriptor_aux)

let transfer_descriptor_param_to_michelson (p : transfer_descriptor_param)
    : transfer_descriptor_param_michelson =
  let aux : transfer_descriptor_param_aux = {
    operator = p.operator;
    batch = List.map  transfer_descriptor_to_michelson p.batch;
  } in
  Layout.convert_to_right_comb (aux : transfer_descriptor_param_aux)

let transfer_descriptor_from_michelson (p : transfer_descriptor_michelson) : transfer_descriptor =
  let aux : transfer_descriptor_aux = Layout.convert_from_right_comb p in
  {
    from_ = aux.from_;
    txs = List.map
      (fun (txm : transfer_destination_descriptor_michelson) ->
        let tx : transfer_destination_descriptor =
          Layout.convert_from_right_comb txm in
        tx
      )
      aux.txs;
  }

let transfer_descriptor_param_from_michelson (p : transfer_descriptor_param_michelson)
    : transfer_descriptor_param =
  let aux : transfer_descriptor_param_aux = Layout.convert_from_right_comb p in
  let b : transfer_descriptor list =
    List.map transfer_descriptor_from_michelson aux.batch
  in
  {
    operator = aux.operator;
    batch = b;
  }

let transfer_from_michelson (txm : transfer_michelson) : transfer =
  let aux : transfer_aux = Layout.convert_from_right_comb txm in 
  {
    from_ = aux.from_;
    txs = List.map
      (fun (txm : transfer_destination_michelson) ->
        let tx : transfer_destination = Layout.convert_from_right_comb txm in
        tx
      )
      aux.txs;
  }

let transfers_from_michelson (txsm : transfer_michelson list) : transfer list =
  List.map transfer_from_michelson txsm

let transfer_to_michelson (tx : transfer) : transfer_michelson =
  let aux : transfer_aux = {
    from_ = tx.from_;
    txs = List.map 
      (fun (tx: transfer_destination) -> 
        let t : transfer_destination_michelson = Layout.convert_to_right_comb tx in
        t
      ) tx.txs;
  } in
  Layout.convert_to_right_comb (aux : transfer_aux)

let transfers_to_michelson (txs : transfer list) : transfer_michelson list =
  List.map transfer_to_michelson txs

let operator_param_from_michelson (p : operator_param_michelson) : operator_param =
  let op : operator_param = Layout.convert_from_right_comb p in
  op

let operator_param_to_michelson (p : operator_param) : operator_param_michelson =
  Layout.convert_to_right_comb p

let operator_update_from_michelson (uom : update_operator_michelson) : update_operator =
    let aux : update_operator_aux = Layout.convert_from_right_comb uom in
    match aux with
    | Add_operator opm -> Add_operator_p (operator_param_from_michelson opm)
    | Remove_operator opm -> Remove_operator_p (operator_param_from_michelson opm)

let operator_update_to_michelson (uo : update_operator) : update_operator_michelson =
    let aux = match uo with
    | Add_operator_p op -> Add_operator (operator_param_to_michelson op)
    | Remove_operator_p op -> Remove_operator (operator_param_to_michelson op)
    in
    Layout.convert_to_right_comb aux

let operator_updates_from_michelson (updates_michelson : update_operator_michelson list)
    : update_operator list =
  List.map operator_update_from_michelson updates_michelson

let balance_of_param_from_michelson (p : balance_of_param_michelson) : balance_of_param =
  let aux : balance_of_param_aux = Layout.convert_from_right_comb p in
  let requests = List.map 
    (fun (rm : balance_of_request_michelson) ->
      let r : balance_of_request = Layout.convert_from_right_comb rm in
      r
    )
    aux.requests 
  in
  {
    requests = requests;
    callback = aux.callback;
  } 

let balance_of_param_to_michelson (p : balance_of_param) : balance_of_param_michelson =
  let aux : balance_of_param_aux = {
    requests = List.map 
      (fun (r : balance_of_request) -> Layout.convert_to_right_comb r)
      p.requests;
    callback = p.callback;
  } in
  Layout.convert_to_right_comb (aux : balance_of_param_aux)

let balance_of_response_to_michelson (r : balance_of_response) : balance_of_response_michelson =
  let aux : balance_of_response_aux = {
    request = Layout.convert_to_right_comb r.request;
    balance = r.balance;
  } in
  Layout.convert_to_right_comb (aux : balance_of_response_aux)

let balance_of_response_from_michelson (rm : balance_of_response_michelson) : balance_of_response =
  let aux : balance_of_response_aux = Layout.convert_from_right_comb rm in
  let request : balance_of_request = Layout.convert_from_right_comb aux.request in
  {
    request = request;
    balance = aux.balance;
  }

let token_metas_to_michelson (ms : token_metadata list) : token_metadata_michelson list =
  List.map
    ( fun (m : token_metadata) ->
      let mm : token_metadata_michelson = Layout.convert_to_right_comb m in
      mm
    ) ms


# 10 "./multi_asset/ligo/src/../fa2/lib/fa2_operator_lib.mligo" 2

# 1 "./multi_asset/ligo/src/../fa2/lib/../fa2_errors.mligo" 1


















































# 11 "./multi_asset/ligo/src/../fa2/lib/fa2_operator_lib.mligo" 2

(** 
(owner, operator, token_id) -> unit
To be part of FA2 storage to manage permitted operators
*)
type operator_storage = ((address * (address * token_id)), unit) big_map

(** 
  Updates operator storage using an `update_operator` command.
  Helper function to implement `Update_operators` FA2 entrypoint
*)
let update_operators (update, storage : update_operator * operator_storage)
    : operator_storage =
  match update with
  | Add_operator_p op -> 
    Big_map.update (op.owner, (op.operator, op.token_id)) (Some unit) storage
  | Remove_operator_p op -> 
    Big_map.remove (op.owner, (op.operator, op.token_id)) storage

(**
Validate if operator update is performed by the token owner.
@param updater an address that initiated the operation; usually `Tezos.sender`.
*)
let validate_update_operators_by_owner (update, updater : update_operator * address)
    : unit =
  let op = match update with
  | Add_operator_p op -> op
  | Remove_operator_p op -> op
  in
  if op.owner = updater then unit else failwith fa2_not_owner

(**
  Generic implementation of the FA2 `%update_operators` entrypoint.
  Assumes that only the token owner can change its operators.
 *)
let fa2_update_operators (updates_michelson, storage
    : (update_operator_michelson list) * operator_storage) : operator_storage =
  let updates = operator_updates_from_michelson updates_michelson in
  let updater = Tezos.sender in
  let process_update = (fun (ops, update : operator_storage * update_operator) ->
    let u = validate_update_operators_by_owner (update, updater) in
    update_operators (update, ops)
  ) in
  List.fold process_update updates storage

(** 
  owner * operator * token_id * ops_storage -> unit
*)
type operator_validator = (address * address * token_id * operator_storage)-> unit

(**
Create an operator validator function based on provided operator policy.
@param tx_policy operator_transfer_policy defining the constrains on who can transfer.
@return (owner, operator, token_id, ops_storage) -> unit
 *)
let make_operator_validator (tx_policy : operator_transfer_policy) : operator_validator =
  let can_owner_tx, can_operator_tx = match tx_policy with
  | No_transfer -> (failwith fa2_tx_denied : bool * bool)
  | Owner_transfer -> true, false
  | Owner_or_operator_transfer -> true, true
  in
  (fun (owner, operator, token_id, ops_storage 
      : address * address * token_id * operator_storage) ->
    if can_owner_tx && owner = operator
    then unit (* transfer by the owner *)
    else if not can_operator_tx
    then failwith fa2_not_owner (* an operator transfer not permitted by the policy *)
    else if Big_map.mem  (owner, (operator, token_id)) ops_storage
    then unit (* the operator is permitted for the token_id *)
    else failwith fa2_not_operator (* the operator is not permitted for the token_id *)
  )

(**
Default implementation of the operator validation function.
The default implicit `operator_transfer_policy` value is `Owner_or_operator_transfer`
 *)
let default_operator_validator : operator_validator =
  (fun (owner, operator, token_id, ops_storage 
      : address * address * token_id * operator_storage) ->
    if owner = operator
    then unit (* transfer by the owner *)
    else if Big_map.mem (owner, (operator, token_id)) ops_storage
    then unit (* the operator is permitted for the token_id *)
    else failwith fa2_not_operator (* the operator is not permitted for the token_id *)
  )

(** 
Validate operators for all transfers in the batch at once
@param tx_policy operator_transfer_policy defining the constrains on who can transfer.
*)
let validate_operator (tx_policy, txs, ops_storage 
    : operator_transfer_policy * (transfer list) * operator_storage) : unit =
  let validator = make_operator_validator tx_policy in
  List.iter (fun (tx : transfer) -> 
    List.iter (fun (dst: transfer_destination) ->
      validator (tx.from_, Tezos.sender, dst.token_id ,ops_storage)
    ) tx.txs
  ) txs



# 7 "./multi_asset/ligo/src/fa2_multi_token.mligo" 2

(* (owner,token_id) -> balance *)
type ledger = ((address * token_id), nat) big_map

(* token_id -> total_supply *)
type token_total_supply = (token_id, nat) big_map

(* token_id -> token_metadata *)
type token_metadata_storage = (token_id, token_metadata_michelson) big_map

type multi_token_storage = {
  ledger : ledger;
  operators : operator_storage;
  token_total_supply : token_total_supply;
  token_metadata : token_metadata_storage;
  order_book: (nat, order_book_entry) big_map;
  order_id_counter: nat; // initialized to 0
}


# 1 "./multi_asset/ligo/src/../fa2/mint_tokens.mligo" 1

type token_extras = (string, string) map

let mint_tokens ((params, s): mint_tokens_params_michelson * multi_token_storage) =
    (* Converts the input to the appropriate record *)
    let p: mint_tokens_params = 
        Layout.convert_from_right_comb (params: mint_tokens_params_michelson) in
    (* Checks if the provided token ID doesn't exist *)
    if Big_map.mem p.token_id s.token_total_supply
    then
        (failwith "TOKEN_ALREADY_EXISTS": multi_token_storage)
    else
        (* Creates new metadata *)
        let make_extras (extras, data: token_extras * (string * string)): token_extras =
            Map.add data.0 data.1 extras in
        let metadata: token_metadata = {
            token_id = p.token_id;
            admin = Tezos.sender;
            symbol = p.symbol;
            name = p.name;
            decimals = p.decimals;
            extras = List.fold make_extras p.extras (Map.empty: token_extras);
        } in
        let token_metadata_michelson: token_metadata_michelson = 
            Layout.convert_to_right_comb (metadata: token_metadata) in
        let new_token_metadata: token_metadata_storage = 
            Big_map.add p.token_id token_metadata_michelson s.token_metadata in
        (* Creates new token total supply *)
        let total_supply: token_total_supply = 
            Big_map.add p.token_id p.total_supply s.token_total_supply in
        (* Adds new account in ledger *)
        let new_ledger: ledger = 
            Big_map.add (Tezos.sender, p.token_id) p.total_supply s.ledger in
        (* Returns the updated storage *)
        { s with ledger = new_ledger; 
                token_total_supply = total_supply; 
                token_metadata = new_token_metadata }
        


# 27 "./multi_asset/ligo/src/fa2_multi_token.mligo" 2

# 1 "./multi_asset/ligo/src/../fa2/burn_tokens.mligo" 1
let burn_tokens ((params, s): (token_id * nat) * multi_token_storage): multi_token_storage =
    let token_id = params.0 in
    let token_amount = params.1 in
    (* Gets token metadata *)
    let metadata_michelson: token_metadata_michelson = 
        match Big_map.find_opt token_id s.token_metadata with
        | Some mtdt -> mtdt
        | None -> (failwith "NO_TOKEN_FOUND": token_metadata_michelson) in
    let metadata: token_metadata = Layout.convert_from_right_comb metadata_michelson in
    (* Only admin is allowed to burn tokens *)
    if Tezos.sender <> metadata.admin
    then (failwith "UNAUTHORIZDED_ACTION": multi_token_storage)
    else
        (* Verifies the admin as the right amount of token *)
        let admin_balance: nat = 
            match Big_map.find_opt (Tezos.sender, token_id) s.ledger with
            | None -> (failwith "NO_BALANCE_FOUND": nat)
            | Some blc -> blc in
        if admin_balance < token_amount
        then (failwith "INSUFFICIENT_BALANCE": multi_token_storage)
        else
            (* Deducts the tokens to burn from admin's balance *)
            let new_balance: nat = abs (admin_balance - token_amount) in
            (* Updates the ledger *)
            let new_ledger = Big_map.update (Tezos.sender, token_id) (Some (new_balance)) s.ledger in
            (* Deducts the token to burn from the total supply *)
            let current_supply: nat = 
                match Big_map.find_opt token_id s.token_total_supply with
                | None -> (failwith "NO_TOTAL_SUPPLY_FOUND": nat)
                | Some supply -> supply in
            if current_supply < token_amount
            then (failwith "INSUFFICIENT_TOTAL_SUPPLY": multi_token_storage)
            else
                let new_total_supply: nat = abs (current_supply - token_amount) in
                (* returns the new storage *)
                { s with ledger = new_ledger; 
                        token_total_supply = Big_map.update token_id (Some (current_supply)) s.token_total_supply }


# 28 "./multi_asset/ligo/src/fa2_multi_token.mligo" 2

# 1 "./multi_asset/ligo/src/../fa2/exchange_functions.mligo" 1
let set_on_exchange ((params, s): exchange_order_params_michelson * multi_token_storage): multi_token_storage =
    (* Converts parameters *)
    let exchange_order: exchange_order_params = 
        Layout.convert_from_right_comb (params: exchange_order_params_michelson) in
    (* Checks if user has enough tokens to sell *)
    let user_balance: nat = 
        match Big_map.find_opt (Tezos.sender, exchange_order.token_id_to_sell) s.ledger with
        | None -> (failwith "NO_BALANCE_AVAILABLE": nat)
        | Some blc -> blc in
    if user_balance < exchange_order.token_amount_to_sell
    then (failwith "INSUFFICIENT_BALANCE": multi_token_storage)
    else
        (* Checks if the token to buy exists and if the total supply is sufficient for the buy *)
        let token_to_buy_total_supply: nat = 
            match Big_map.find_opt exchange_order.token_id_to_buy s.token_total_supply with
            | None -> (failwith "NO_TOKEN_FOUND": nat)
            | Some supply -> supply in
        if token_to_buy_total_supply < exchange_order.token_amount_to_buy
        then (failwith "INSUFFICIENT_TOTAL_SUPPLY": multi_token_storage)
        else
            (* Creates a new order *)
            let new_order: order_book_entry = {
                order_type = exchange_order.order_type;
                token_id_to_sell = exchange_order.token_id_to_sell;
                token_amount_to_sell = exchange_order.token_amount_to_sell;
                token_id_to_buy = exchange_order.token_id_to_buy;
                token_amount_to_buy = exchange_order.token_amount_to_buy;
                seller = Tezos.sender;
            } in 
            (* Creates a new order id *)
            let order_id: nat = s.order_id_counter + 1n in
            (* Places the new order *)
            let new_order_book = Big_map.add order_id new_order s.order_book in
            (* Returns the new storage *)
            { s with order_book = new_order_book; order_id_counter = order_id }
            
                

let buy_from_exchange ((params, s): (order_id * nat) * multi_token_storage): multi_token_storage =
    let order_id = params.0 in
    let token_amount = params.1 in // amount of token to buy
    (* Checks if order_id is valid *)
    if not Big_map.mem order_id s.order_book
    then (failwith "INVALID_ORDER_ID": multi_token_storage)
    else 
        (* Loads the order *)
        let order: order_book_entry = 
            match Big_map.find_opt order_id s.order_book with
            | None -> (failwith "ORDER_NOT_FOUND": order_book_entry)
            | Some ord -> ord in
        (* Checks if requested amount is equal or less than available to buy *)
        if token_amount = order.token_amount_to_sell
        then
            (* If same amount, verifies if buyer has enough balance *)
            let buyer_balance: nat = 
                match Big_map.find_opt (Tezos.sender, order.token_id_to_buy) s.ledger with
                | None -> (failwith "NO_BALANCE": nat)
                | Some blc -> blc in
            if buyer_balance < order.token_amount_to_sell
            then (failwith "INSUFFICIENT_TOKEN_BALANCE": multi_token_storage)
            else
                (* Deducts tokens from buyer's balance to credit seller's balance *)
                let buyer_deducted_ledger = 
                    Big_map.update (Tezos.sender, order.token_id_to_buy) (Some (abs (buyer_balance - order.token_amount_to_buy))) s.ledger in
                let seller_credited_ledger = 
                    match Big_map.find_opt (order.seller, order.token_id_to_buy) buyer_deducted_ledger with
                    | None -> Big_map.add (order.seller, order.token_id_to_buy) order.token_amount_to_buy s.ledger
                    | Some blc ->
                        Big_map.update (order.seller, order.token_id_to_buy) (Some (blc + order.token_amount_to_buy)) s.ledger in
                (* Deducts tokens from seller's balance to credit buyer's balance *)
                let temp_ledger1 = 
                    match Big_map.find_opt (order.seller, order.token_id_to_sell) seller_credited_ledger with
                    | None -> (failwith "NO_ACCOUNT_FOUND": ledger)
                    | Some blc -> 
                        Big_map.update (order.seller, order.token_id_to_sell) (Some (abs (blc - order.token_id_to_sell))) seller_credited_ledger in
                let temp_ledger2 =
                    match Big_map.find_opt (Tezos.sender, order.token_id_to_sell) temp_ledger1 with
                    | None -> (failwith "NO_ACCOUNT_FOUND": ledger)
                    | Some blc -> 
                        Big_map.update (Tezos.sender, order.token_id_to_sell) (Some (blc + order.token_amount_to_sell)) temp_ledger1 in
                (* Deletes the order *)
                let new_order_book = Big_map.remove order_id s.order_book in
                (* Returns updated storage *)
                { s with ledger = temp_ledger2; order_book = new_order_book }
        else if token_amount < order.token_amount_to_sell
        then
            (* If lesser amount, tokens are swapped and amount is deducted from order *)
            (failwith "INVALID_AMOUNT": multi_token_storage)
        else
            (failwith "INVALID_AMOUNT": multi_token_storage)
# 29 "./multi_asset/ligo/src/fa2_multi_token.mligo" 2

let get_balance_amt (key, ledger : (address * nat) * ledger) : nat =
  let bal_opt = Big_map.find_opt key ledger in
  match bal_opt with
  | None -> 0n
  | Some b -> b

let inc_balance (owner, token_id, amt, ledger
    : address * token_id * nat * ledger) : ledger =
  let key = owner, token_id in
  let bal = get_balance_amt (key, ledger) in
  let updated_bal = bal + amt in
  if updated_bal = 0n
  then Big_map.remove key ledger
  else Big_map.update key (Some updated_bal) ledger 

let dec_balance (owner, token_id, amt, ledger
    : address * token_id * nat * ledger) : ledger =
  let key = owner, token_id in
  let bal = get_balance_amt (key, ledger) in
  match Michelson.is_nat (bal - amt) with
  | None -> (failwith fa2_insufficient_balance : ledger)
  | Some new_bal ->
    if new_bal = 0n
    then Big_map.remove key ledger
    else Big_map.update key (Some new_bal) ledger

(**
Update leger balances according to the specified transfers. Fails if any of the
permissions or constraints are violated.
@param txs transfers to be applied to the ledger
@param validate_op function that validates of the tokens from the particular owner can be transferred. 
 *)
let transfer (txs, validate_op, storage
    : (transfer list) * operator_validator * multi_token_storage)
    : ledger =
  let make_transfer = fun (l, tx : ledger * transfer) ->
    List.fold 
      (fun (ll, dst : ledger * transfer_destination) ->
        if not Big_map.mem dst.token_id storage.token_metadata
        then (failwith fa2_token_undefined : ledger)
        else
          let u = validate_op (tx.from_, Tezos.sender, dst.token_id, storage.operators) in
          let lll = dec_balance (tx.from_, dst.token_id, dst.amount, ll) in
          inc_balance(dst.to_, dst.token_id, dst.amount, lll)
      ) tx.txs l
  in
  List.fold make_transfer txs storage.ledger
 
let get_balance (p, ledger, tokens
    : balance_of_param * ledger * token_metadata_storage) : operation =
  let to_balance = fun (r : balance_of_request) ->
    if not Big_map.mem r.token_id tokens
    then (failwith fa2_token_undefined : balance_of_response_michelson)
    else
      let key = r.owner, r.token_id in
      let bal = get_balance_amt (key, ledger) in
      let response = { request = r; balance = bal; } in
      balance_of_response_to_michelson response
  in
  let responses = List.map to_balance p.requests in
  Operation.transaction responses 0mutez p.callback


let main (param, storage : fa2_entry_points * multi_token_storage)
    : (operation  list) * multi_token_storage =
  match param with
  | Transfer txs_michelson -> 
     (* convert transfer batch into `transfer_descriptor` batch *)
    let txs = transfers_from_michelson txs_michelson in
    (* 
    will validate that a sender is either `from_` parameter of each transfer
    or a permitted operator for the owner `from_` address.
    *)
    let new_ledger = transfer (txs, default_operator_validator, storage) in
    let new_storage = { storage with ledger = new_ledger; }
    in ([] : operation list), new_storage

  | Balance_of pm -> 
    let p = balance_of_param_from_michelson pm in
    let op = get_balance (p, storage.ledger, storage.token_metadata) in
    [op], storage

  | Update_operators updates_michelson ->
    let new_ops = fa2_update_operators (updates_michelson, storage.operators) in
    let new_storage = { storage with operators = new_ops; } in
    ([] : operation list), new_storage

  | Token_metadata_registry callback ->
    (* the contract maintains token metadata in its storage - `token_metadata` big_map *)
    let callback_op = Operation.transaction Tezos.self_address 0mutez callback in
    [callback_op], storage

   | Mint_tokens params ->
    let new_storage = mint_tokens (params, storage) in
    ([] : operation list), new_storage

  | Burn_tokens params ->
    let new_storage = burn_tokens (params, storage) in
    ([] : operation list), new_storage

  | New_exchange_order params ->
    let new_storage = set_on_exchange (params, storage) in
    ([] : operation list), new_storage 

  | Buy_from_exchange params ->
    let new_storage = buy_from_exchange (params, storage) in
    ([] : operation list), new_storage 


