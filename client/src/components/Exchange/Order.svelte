<script lang="ts">
  import store from "../../store";
  import { UserToken } from "../../types";
  import Modal from "../Modal/Modal.svelte";

  export let order, getTokenSymbol, openDeleteOrder, openFulfillOrder;

  let loadingDeleteOrder = false;
  let loadingFulfillOrder = false;

  const formatCreatedOn = (timestamp: string): string => {
    const date = new Date(timestamp);

    return `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;
  };

  const displayTokenDecimals = (
    tokenID: number,
    amount: number
  ): number | string => {
    if ($store.tokens.length === 0) return "N/A";

    const token = $store.tokens.filter((tk) => tk.tokenID === tokenID);
    if (token.length === 0) return "N/A";
    if (token[0].decimals === undefined) return "N/A";

    return amount / 10 ** token[0].decimals;
  };

  const availableBalance = (tokenID: number, amount: number): boolean => {
    if (!$store.userAddress) return false;

    const token = $store.userTokens.filter((tk) => tk.tokenID === tokenID);
    if (token.length === 0) return false;

    if (token[0].balance / 10 ** +token[0].decimals < amount) {
      return false;
    } else {
      return true;
    }
  };

  const fulfillOrder = async (): Promise<void> => {
    if (order.order_id) {
      loadingFulfillOrder = true;
      const orders = $store.orderBook.filter(
        (ord) => ord.order_id === order.order_id
      );
      if (orders.length === 1) {
        const order = orders[0];

        try {
          const op = await $store.ledgerInstance.methods
            .buy_from_exchange(
              order.order_id,
              order.token_id_to_buy,
              order.token_amount_to_sell
            )
            .send();
          await op.confirmation();
          // updates user's balances
          let tokens: UserToken[];
          if (
            $store.userTokens.filter(
              (tk) => tk.tokenID === order.token_id_to_buy
            ).length === 0
          ) {
            // if users didn't have before the token they just bought
            tokens = [
              ...$store.userTokens,
              {
                ...$store.tokens.filter(
                  (tk) => tk.tokenID === order.token_id_to_buy
                )[0],
                balance: order.token_amount_to_buy,
              },
            ];
          } else {
            // if users already had the token
            tokens = $store.userTokens.map((tk) => {
              if (tk.tokenID === order.token_id_to_buy) {
                return {
                  ...tk,
                  balance: tk.balance - order.token_amount_to_buy,
                };
              } else if (tk.tokenID === order.token_id_to_sell) {
                return {
                  ...tk,
                  balance: tk.balance - order.token_amount_to_sell,
                };
              } else {
                return tk;
              }
            });
          }
          store.updateUserTokens(tokens);
          // removes order from order book
          store.updateOrderBook([
            ...$store.orderBook.filter(
              (ord) => ord.order_id !== order.order_id
            ),
          ]);
        } catch (error) {
          console.log(error);
        } finally {
          loadingFulfillOrder = false;
        }
      }
    }
  };

  const deleteOrder = async (): Promise<void> => {
    loadingDeleteOrder = true;
    openDeleteOrder = false;

    try {
      const op = await $store.exchangeInstance.methods
        .delete_order(order.order_id)
        .send();
      console.log(op.opHash);
      await op.confirmation();
      // removes order from local order book
      store.updateOrderBook([
        ...$store.orderBook.filter((ord) => ord.order_id !== order.order_id),
      ]);
    } catch (error) {
      console.log(error);
    } finally {
      loadingDeleteOrder = false;
    }
  };
</script>

<div class="exchange-grid orders">
  <div>{order.order_id}</div>
  <div>{formatCreatedOn(order.created_on)}</div>
  <div>
    <span>{displayTokenDecimals(order.token_id_to_sell, order.token_amount_to_sell).toLocaleString('en-US')}
      {getTokenSymbol(order.token_id_to_sell)}</span>
  </div>
  <div>
    <span
      style={$store.userAddress ? (availableBalance(order.token_id_to_buy, order.token_amount_to_buy) ? 'color:green' : 'color:red') : ''}>
      {displayTokenDecimals(order.token_id_to_buy, order.token_amount_to_buy).toLocaleString('en-US')}
      {getTokenSymbol(order.token_id_to_buy)}</span>
  </div>
  <div>{order.seller.slice(0, 7) + '...' + order.seller.slice(-7)}</div>
  <div>
    {#if $store.userAddress && $store.userAddress === order.seller}
      {#if loadingDeleteOrder}
        <button class="button red">
          <span>Deleting...</span><span class="spinner" />
        </button>
      {:else}
        <button
          class="button red"
          on:click={() => {
            openDeleteOrder = true;
          }}>
          <span>Delete</span></button>
      {/if}
    {:else if loadingFulfillOrder}
      <button class="button red">
        <span>Confirming...</span><span class="spinner" />
      </button>
    {:else}
      <button
        class={`button ${$store.userAddress ? (availableBalance(order.token_id_to_buy, order.token_amount_to_buy) ? 'green' : 'red') : ''}`}
        on:click={() => {
          openFulfillOrder = true;
        }}>Fulfill</button>
    {/if}
  </div>
</div>
<Modal
  modalType="deleteOrder"
  payload={order.order_id}
  open={openDeleteOrder}
  close={() => {
    openDeleteOrder = false;
  }}
  confirm={deleteOrder} />
<Modal
  modalType="fulfillOrder"
  payload={order.order_id ? $store.orderBook.filter((ord) => ord.order_id === order.order_id)[0] : undefined}
  open={openFulfillOrder}
  close={() => {
    openFulfillOrder = false;
  }}
  confirm={fulfillOrder} />
