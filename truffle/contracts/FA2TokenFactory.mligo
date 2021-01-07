# 1 "./smart-contracts/multi_asset/ligo/src/fa2_multi_token.mligo"




# 1 "./smart-contracts/multi_asset/ligo/src/../fa2/fa2_interface.mligo" 1



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

type mint_tokens_params = 
[@layout:comb]
{
    symbol: string;
    name: string;
    decimals: nat;
    total_supply: nat;
    extras : (string * string) list;
}

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

type token_amounts_to_swap = { to_buy: nat; to_sell: nat }

type buy_params =
[@layout:comb]
{
  order_id: order_id;
  token_to_buy: token_id;
  amount: nat;
}

type order_params =
[@layout:comb]
{
    order_id: order_id;
    amount_to_buy: nat;
    buyer: address;
    buyer_balance: nat; (* balance of token to be exchanged for the target token *)
}

type confirm_buy_params = 
[@layout:comb]
{
  order_id: order_id;
  token_ids: nat * nat; (* sold token id -> bought token id *)
  status: bool;
  from_: address * nat; (* user address with amount to debit *)
  to_: address * nat; (* user address with amount to debit *)
}

type fa2_entry_points =
  | Transfer of transfer_michelson list
  | Balance_of of balance_of_param_michelson
  | Update_operators of update_operator_michelson list
  | Token_metadata_registry of address contract
  | Mint_tokens of mint_tokens_params
  | Burn_tokens of token_id * nat
  | New_exchange_order of order_book_entry
  | Buy_from_exchange of buy_params
  | Confirm_buy_from_exchange of confirm_buy_params
  | Buy_xtz_wrapper of unit
  | Redeem_xtz_wrapper of nat
  | Update_exchange_address of address


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



# 5 "./smart-contracts/multi_asset/ligo/src/fa2_multi_token.mligo" 2

# 1 "./smart-contracts/multi_asset/ligo/src/../fa2/fa2_errors.mligo" 1



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



# 6 "./smart-contracts/multi_asset/ligo/src/fa2_multi_token.mligo" 2

# 1 "./smart-contracts/multi_asset/ligo/src/../fa2/lib/fa2_operator_lib.mligo" 1
(** 
Reference implementation of the FA2 operator storage, config API and 
helper functions 
*)





# 1 "./smart-contracts/multi_asset/ligo/src/../fa2/lib/fa2_convertors.mligo" 1
(**
Helper function to convert FA2 entrypoints input parameters between their
Michelson and internal LIGO representation.

FA2 contract implementation must conform to the Michelson entrypoints interface
outlined in the FA2 standard for interoperability with other contracts and off-chain
tools.
 *)





# 1 "./smart-contracts/multi_asset/ligo/src/../fa2/lib/../fa2_interface.mligo" 1

































































































































































































































































# 14 "./smart-contracts/multi_asset/ligo/src/../fa2/lib/fa2_convertors.mligo" 2

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


# 10 "./smart-contracts/multi_asset/ligo/src/../fa2/lib/fa2_operator_lib.mligo" 2

# 1 "./smart-contracts/multi_asset/ligo/src/../fa2/lib/../fa2_errors.mligo" 1


















































# 11 "./smart-contracts/multi_asset/ligo/src/../fa2/lib/fa2_operator_lib.mligo" 2

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



# 7 "./smart-contracts/multi_asset/ligo/src/fa2_multi_token.mligo" 2

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
  exchange_address: address;
  admin: address;
  last_token_id: token_id;
}


# 1 "./smart-contracts/multi_asset/ligo/src/../fa2/mint_tokens.mligo" 1

type token_extras = (string, string) map

let mint_tokens ((p, s): mint_tokens_params * multi_token_storage) =
    (* Creates new metadata *)
    let make_extras (extras, data: token_extras * (string * string)): token_extras =
        Map.add data.0 data.1 extras in
    (* Creates new token id *)
    let new_token_id: token_id = s.last_token_id + 1n in
    let metadata: token_metadata = {
        token_id = new_token_id;
        admin = Tezos.sender;
        symbol = p.symbol;
        name = p.name;
        decimals = p.decimals;
        extras = List.fold make_extras p.extras (Map.empty: token_extras);
    } in
    let token_metadata_michelson: token_metadata_michelson = 
        Layout.convert_to_right_comb (metadata: token_metadata) in
    let new_token_metadata: token_metadata_storage = 
        Big_map.add new_token_id token_metadata_michelson s.token_metadata in
    (* Creates new token total supply *)
    let total_supply: token_total_supply = 
        Big_map.add new_token_id p.total_supply s.token_total_supply in
    (* Adds new account in ledger *)
    let new_ledger: ledger = 
        Big_map.add (Tezos.sender, new_token_id) p.total_supply s.ledger in
    (* Returns the updated storage *)
    { s with ledger = new_ledger; 
            token_total_supply = total_supply; 
            token_metadata = new_token_metadata;
            last_token_id = new_token_id; }
        


# 28 "./smart-contracts/multi_asset/ligo/src/fa2_multi_token.mligo" 2

# 1 "./smart-contracts/multi_asset/ligo/src/../fa2/burn_tokens.mligo" 1
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


# 29 "./smart-contracts/multi_asset/ligo/src/fa2_multi_token.mligo" 2

# 1 "./smart-contracts/multi_asset/ligo/src/../fa2/remote_exchange.mligo" 1
(* Creates a new order in the remote exchange *)
let set_on_exchange ((params, s): order_book_entry * multi_token_storage): operation * multi_token_storage = 
    (* Verifies the user has enough funds *)
    let token_balance: nat = match Big_map.find_opt (Tezos.sender, params.token_id_to_sell) s.ledger with
        | None -> (failwith "NO_ACCOUNT": nat)
        | Some b -> b in
    if token_balance < params.total_token_amount
    then (failwith fa2_insufficient_balance: operation * multi_token_storage)
    else
        (* Creates call to the exchange contract *)
        let contract: order_book_entry contract = 
            match ((Tezos.get_entrypoint_opt "%create_new_order" s.exchange_address): order_book_entry contract option) with
                | None -> (failwith "UNKNOWN_CONTRACT": order_book_entry contract)
                | Some c -> c in
        (* Creates the new transaction *)
        let op = Tezos.transaction params 0mutez contract in

        op, s

(* Fulfill an order from the remote exchange *)
let buy_from_exchange ((params, s): buy_params * multi_token_storage): operation = 
    (* Fetches buyer's balance for the given token *)
    let buyer_balance = match Big_map.find_opt (Tezos.sender, params.token_to_buy) s.ledger with
        | None -> (failwith "NO_BALANCE": nat)
        | Some b -> 
            if b < params.amount
            then (failwith "INSUFFICIENT_BALANCE": nat)
            else
             b in
    (* Prepares operation to be sent to the exchange *)
    let contract: order_params contract = 
        match ((Tezos.get_entrypoint_opt "%fulfill_order" s.exchange_address): order_params contract option) with
            | None -> (failwith "UNKNOWN_CONTRACT": order_params contract)
            | Some c -> c in
    (* Creates the new transaction *)
    let buy_order: order_params = {
        order_id = params.order_id;
        amount_to_buy = params.amount;
        buyer = Tezos.sender;
        buyer_balance = buyer_balance;
    } in

    Tezos.transaction buy_order 0mutez contract

(* Receives confirmation of the order fulfilment from the remote exchange *)
let confirm_buy_from_exchange ((params, s): confirm_buy_params * multi_token_storage): multi_token_storage = 
    (* Verifies the transaction comes from the exchange *)
    if Tezos.sender <> s.exchange_address
    then (failwith fa2_tx_denied: multi_token_storage)
    else if params.status = false
    then (failwith "UNCONFIRMED_EXCHANGE": multi_token_storage)
    else
        (* Checks buyer has enough funds *)
        let buyer_balance_tkB: nat =
            match Big_map.find_opt (params.to_.0, params.token_ids.1) s.ledger with
            | None -> (failwith fa2_insufficient_balance: nat)
            | Some b -> b in
        if buyer_balance_tkB < params.to_.1
        then (failwith "BUYER_INSUFFICIENT_BALANCE": multi_token_storage)
        else
            (* Checks seller has enough funds *)
            let seller_balance_tkA: nat = 
                match Big_map.find_opt (params.from_.0, params.token_ids.0) s.ledger with
                | None -> (failwith fa2_insufficient_balance: nat)
                | Some b -> b in
            if seller_balance_tkA < params.from_.1
            then (failwith "SELLER_INSUFFICIENT_BALANCE": multi_token_storage)
            else
                (* Proceeds with the exchange of tokens *)
                let seller_address = params.from_.0 in
                let seller_to_debit = params.from_.1 in
                let buyer_address = params.to_.0 in
                let buyer_to_debit = params.to_.1 in
                (* Buyer *)
                let buyer_new_balance_tkA: nat = 
                    match Big_map.find_opt (buyer_address, params.token_ids.0) s.ledger with
                    | None -> seller_to_debit
                    | Some b -> b + seller_to_debit in
                let buyer_new_balance_tkB: nat = abs (buyer_balance_tkB - buyer_to_debit) in
                (* Seller *)
                let seller_new_balance_tkA: nat = abs (seller_balance_tkA - seller_to_debit) in
                let seller_new_balance_tkB: nat = 
                    match Big_map.find_opt (seller_address, params.token_ids.1) s.ledger with
                    | None -> buyer_to_debit
                    | Some b -> b + buyer_to_debit in
                (* Updates buyer balances in storage *)
                let new_ledger1 = 
                    Big_map.update (buyer_address, params.token_ids.0) (Some buyer_new_balance_tkA) s.ledger in
                let new_ledger2 = 
                    Big_map.update (buyer_address, params.token_ids.1) (Some buyer_new_balance_tkB) new_ledger1 in
                (* Updates seller balances in storage *)
                let new_ledger3 = 
                    Big_map.update (seller_address, params.token_ids.0) (Some seller_new_balance_tkA) new_ledger2 in
                let new_ledger4 = 
                    Big_map.update (seller_address, params.token_ids.1) (Some seller_new_balance_tkB) new_ledger3 in

                { s with ledger = new_ledger4 }

(* Updates exchange address *)
let update_exchange_address (new_address, s: address * multi_token_storage): multi_token_storage =
    if Tezos.sender = s.admin
    then { s with exchange_address = new_address }
    else (failwith "UNAUTHORIZED_ACTION": multi_token_storage)

let buy_xtz_wrapper (s: multi_token_storage): multi_token_storage =
    (* This function wraps XTZ into an FA2 tokens users can use on the platform *)
    let wrapper_id = 1n in
    (* The amount sent is turned into the wrapping token *)
    if Tezos.amount = 0mutez
    then (failwith "NO_AMOUNT_PROVIDED": multi_token_storage)
    else   
        (* checks if user already has an account with the wrapper token *)
        let user_balance = 
            match Big_map.find_opt (Tezos.sender, wrapper_id) s.ledger with
            | None -> Tezos.amount / 1mutez
            | Some blc -> blc + Tezos.amount / 1mutez in
        (* updates wToken total supply *)
        let new_token_total_supply = 
            match Big_map.find_opt wrapper_id s.token_total_supply with
            | None -> (failwith "NO_WTOKEN": nat)
            | Some supply -> supply + (Tezos.amount / 1mutez) in 
        (* Returns updated storage with balance *)
        { s with 
            ledger = Big_map.update (Tezos.sender, 1n) (Some (user_balance)) s.ledger;
            token_total_supply = Big_map.update wrapper_id (Some (new_token_total_supply)) s.token_total_supply }

let redeem_xtz_wrapper ((xtz_amount, s): nat * multi_token_storage): operation * multi_token_storage =
    let wrapper_id = 1n in
    (* checks if user has an account with XTZ wrappers in it *)
    let user_balance = 
        match Big_map.find_opt (Tezos.sender, 1n) s.ledger with
        | None -> (failwith "NO_ACCOUNT": nat)
        | Some blc -> 
            if blc = 0n 
            then (failwith "NO_BALANCE": nat) 
            else if blc < xtz_amount 
            then (failwith "INSUFFICIENT_BALANCE": nat) 
            else blc in
    (* Transfers the requested amount back to the user *)
    let recipient: unit contract = 
        match ((Tezos.get_contract_opt Tezos.sender): unit contract option) with
        | None -> (failwith "CONTRACT_ERROR": unit contract)
        | Some addr -> addr in
    let op: operation = Tezos.transaction unit (xtz_amount * 1mutez) recipient in 
    (* Deducts the amount from the balance *)
    let new_balance: nat = abs (user_balance - xtz_amount) in
    let new_ledger = Big_map.update (Tezos.sender, wrapper_id) (Some (new_balance)) s.ledger in
    (* updates wToken total supply *)
    let new_token_total_supply = 
        match Big_map.find_opt wrapper_id s.token_total_supply with
        | None -> (failwith "NO_WTOKEN": nat)
        | Some supply -> abs (supply - xtz_amount) in 
    (* Returns the updated storage and the operation *)
    (op, { s with 
        ledger = new_ledger; 
        token_total_supply = Big_map.update wrapper_id (Some (new_token_total_supply)) s.token_total_supply })
# 30 "./smart-contracts/multi_asset/ligo/src/fa2_multi_token.mligo" 2

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
    let result = set_on_exchange (params, storage) in
    [result.0], result.1 

  | Buy_from_exchange params ->
    let op = buy_from_exchange (params, storage) in
    [op], storage

  | Confirm_buy_from_exchange params ->
    let new_storage = confirm_buy_from_exchange (params, storage) in
    ([] : operation list), new_storage 

  | Buy_xtz_wrapper params ->
    let new_storage = buy_xtz_wrapper (storage) in
    ([]: operation list), new_storage

  | Redeem_xtz_wrapper params ->
    let result = redeem_xtz_wrapper (params, storage) in
    let op = result.0 in
    let new_storage = result.1 in
    [op], new_storage

  | Update_exchange_address param ->
    let new_storage = update_exchange_address (param, storage) in
    ([]: operation list), new_storage


