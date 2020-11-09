const { Tezos } = require("@taquito/taquito");
const { alice, bob } = require("../scripts/sandbox/accounts");
const setup = require("./setup");

contract("FA2 Fungible Token Factory", () => {
  let storage, fa2_address, exchange_address, exchange_instance, signerFactory;

  const aliToken = {
    id: 2,
    symbol: "ALICE",
    name: "Alice",
    decimals: 0,
    extras: [["picture", "aliToken.png"]],
    totalSupply: 21000
  };

  const bobToken = {
    id: 3,
    symbol: "BOB",
    name: "Bob",
    decimals: 0,
    extras: [["picture", "bobToken.png"]],
    totalSupply: 20000
  };

  before(async () => {
    const config = await setup();
    storage = config.storage;
    fa2_address = config.fa2_address;
    fa2_instance = config.fa2_instance;
    signerFactory = config.signerFactory;
    exchange_address = config.exchange_address;
    exchange_instance = config.exchange_instance;
    Tezos.setRpcProvider("http://localhost:8732");

    try {
      console.log("Updating main address and exchange address in contracts...");
      // updates exchange address in main contract
      const op1 = await fa2_instance.methods
        .update_exchange_address(exchange_address)
        .send();
      await op1.confirmation();
      // updates main contract address in exchange contract
      const op2 = await exchange_instance.methods
        .update_ledger_address(fa2_address)
        .send();
      await op2.confirmation();
    } catch (error) {
      console.log(error);
    }
  });

  it("Alice should be the admin", () => {
    assert.equal(storage.admin, alice.pkh);
  });

  it("should have wToken initialized with ID 1 and 0 total supply", async () => {
    const token = await storage.token_total_supply.get("1");
    assert.equal(token.toNumber(), 0);
    const metadata = await storage.token_metadata.get("1");
    assert.equal(metadata.name, "wToken");
  });

  it("should mint Alice tokens", async () => {
    try {
      const op = await fa2_instance.methods
        .mint_tokens(
          aliToken.id,
          aliToken.symbol,
          aliToken.name,
          aliToken.decimals,
          aliToken.extras,
          aliToken.totalSupply
        )
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await fa2_instance.storage();

    const aliceBalance = await storage.ledger.get({
      owner: alice.pkh,
      token_id: aliToken.id
    });
    assert.equal(aliceBalance.toNumber(), aliToken.totalSupply);

    const totalSupply = await storage.token_total_supply.get(
      aliToken.id.toString()
    );
    assert.equal(totalSupply.toNumber(), aliToken.totalSupply);

    const metadata = await storage.token_metadata.get(aliToken.id.toString());
    assert.equal(metadata.token_id, aliToken.id);
    assert.equal(metadata.admin, alice.pkh);
    assert.equal(metadata.symbol, aliToken.symbol);
    assert.equal(metadata.name, aliToken.name);
    assert.equal(metadata.decimals, aliToken.decimals);
    const picture = await metadata.extras.get("picture");
    assert.equal(picture, aliToken.extras[0][1]);
  });

  it("should prevent Alice from exceeding her balance in transfers", async () => {
    const totalSupply = await storage.token_total_supply.get(
      aliToken.id.toString()
    );
    let err;

    try {
      const op = await fa2_instance.methods
        .transfer([
          {
            from_: alice.pkh,
            txs: [
              {
                to_: bob.pkh,
                token_id: aliToken.id,
                amount: totalSupply.toNumber() + 1
              }
            ]
          }
        ])
        .send();
      await op.confirmation();
    } catch (error) {
      err = error.message;
    }

    assert.equal(err, "FA2_INSUFFICIENT_BALANCE");
  });

  it("should let Alice transfer 10000 tokens to Bob", async () => {
    const tokenAmount = 10000;

    try {
      const op = await fa2_instance.methods
        .transfer([
          {
            from_: alice.pkh,
            txs: [{ to_: bob.pkh, token_id: aliToken.id, amount: tokenAmount }]
          }
        ])
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await fa2_instance.storage();

    const bobBalance = await storage.ledger.get({
      owner: bob.pkh,
      token_id: aliToken.id
    });

    assert.equal(bobBalance.toNumber(), tokenAmount);
  });

  it("should mint Bob tokens", async () => {
    await signerFactory(bob.sk);

    let err;

    try {
      // should fail if token ID already exists
      const op = await fa2_instance.methods
        .mint_tokens(
          aliToken.id,
          bobToken.symbol,
          bobToken.name,
          bobToken.decimals,
          bobToken.extras,
          bobToken.totalSupply
        )
        .send();
      await op.confirmation();
    } catch (error) {
      err = error.message;
    }

    assert.equal(err, "TOKEN_ALREADY_EXISTS");

    try {
      // should fail if token ID already exists
      const op = await fa2_instance.methods
        .mint_tokens(
          bobToken.id,
          bobToken.symbol,
          bobToken.name,
          bobToken.decimals,
          bobToken.extras,
          bobToken.totalSupply
        )
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await fa2_instance.storage();

    const bobBalance = await storage.ledger.get({
      owner: bob.pkh,
      token_id: bobToken.id
    });
    assert.equal(bobBalance.toNumber(), bobToken.totalSupply);
  });

  it("should mint wTokens for Alice", async () => {
    await signerFactory(alice.sk);

    const aliceBalance = await Tezos.tz.getBalance(alice.pkh);
    const contractBalance = await Tezos.tz.getBalance(fa2_address);
    const amount = 10;

    try {
      const op = await fa2_instance.methods
        .buy_xtz_wrapper([["unit"]])
        .send({ amount: amount * 10 ** 6, mutez: true });
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }
    // checks if XTZ has been deducted from Alice's balance
    const aliceNewBalance = await Tezos.tz.getBalance(alice.pkh);
    assert.isBelow(
      aliceNewBalance.toNumber(),
      aliceBalance.toNumber() - amount * 10 ** 6
    );
    // checks if contract balance has been increased
    const contractNewBalance = await Tezos.tz.getBalance(fa2_address);
    assert.equal(
      contractNewBalance.toNumber(),
      contractBalance.toNumber() + amount * 10 ** 6
    );
    // checks Alice's token balance
    storage = await fa2_instance.storage();
    const tokenBalance = await storage.ledger.get({
      owner: alice.pkh,
      token_id: 1
    });
    assert.equal(amount * 10 ** 6, tokenBalance.toNumber());
  });

  it("should transfer half of Alice's wToken balance to Bob", async () => {
    const aliceBalance = await storage.ledger.get({
      owner: alice.pkh,
      token_id: 1
    });

    try {
      const op = await fa2_instance.methods
        .transfer([
          {
            from_: alice.pkh,
            txs: [
              { to_: bob.pkh, token_id: 1, amount: aliceBalance.toNumber() / 2 }
            ]
          }
        ])
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await fa2_instance.storage();

    const bobBalance = await storage.ledger.get({
      owner: bob.pkh,
      token_id: 1
    });

    assert.equal(bobBalance.toNumber(), aliceBalance.toNumber() / 2);
  });

  it("should let Bob redeem his wTokens", async () => {
    await signerFactory(bob.sk);

    const bobBalance = await storage.ledger.get({
      owner: bob.pkh,
      token_id: 1
    });
    const contractBalance = await Tezos.tz.getBalance(fa2_address);
    const wrapperSupply = await storage.token_total_supply.get("1");

    try {
      const op = await fa2_instance.methods
        .redeem_xtz_wrapper(bobBalance.toNumber())
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await fa2_instance.storage();

    const bobNewBalance = await storage.ledger.get({
      owner: bob.pkh,
      token_id: 1
    });
    const contractNewBalance = await Tezos.tz.getBalance(fa2_address);
    const wrapperNewSupply = await storage.token_total_supply.get("1");

    assert.equal(bobNewBalance.toNumber(), 0);
    assert.equal(
      contractNewBalance.toNumber(),
      contractBalance.toNumber() - bobBalance.toNumber()
    );
    assert.equal(
      wrapperNewSupply.toNumber(),
      wrapperSupply.toNumber() - bobBalance.toNumber()
    );
  });

  it("should let Alice create an order", async () => {
    // Alice sells 1000 AliTokens for 1000 BobTokens
    await signerFactory(alice.sk);

    const exchangeStorage = await exchange_instance.storage();
    const expectedOrderId = parseInt(exchangeStorage.last_order_id) + 1;
    const tokenAmountToSell = 1;
    const tokenAmountToBuy = 2;
    const totalTokenAmount = 1000; // total token to sell
    const orderType = "sell";

    try {
      const op = await fa2_instance.methods
        .new_exchange_order(
          orderType,
          [["unit"]],
          aliToken.id,
          tokenAmountToSell,
          bobToken.id,
          tokenAmountToBuy,
          totalTokenAmount,
          alice.pkh
        )
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    const newExchangeStorage = await exchange_instance.storage();
    const orderId = newExchangeStorage.last_order_id.toNumber();

    assert.equal(orderId, expectedOrderId);

    const newOrder = await newExchangeStorage.order_book.get(
      orderId.toString()
    );
    //console.log("new order:", newOrder);

    //assert.equal(newOrder.order_type, orderType);
    assert.equal(newOrder.token_id_to_sell, aliToken.id);
    assert.equal(newOrder.token_amount_to_sell, tokenAmountToSell);
    assert.equal(newOrder.token_id_to_buy, bobToken.id);
    assert.equal(newOrder.token_amount_to_buy, tokenAmountToBuy);
    assert.equal(newOrder.total_token_amount, totalTokenAmount);
    assert.equal(newOrder.seller, alice.pkh);
  });

  it("should prevent Bob from fulfilling half of Alice's order", async () => {
    await signerFactory(bob.sk);
    let err;

    const exchangeStorage = await exchange_instance.storage();
    const orderId = await exchangeStorage.last_order_id.toNumber();
    const order = await exchangeStorage.order_book.get(orderId.toString());
    const amountToBuy =
      (order.token_amount_to_sell.toNumber() *
        order.total_token_amount.toNumber()) /
      2;

    try {
      const op = await fa2_instance.methods
        .buy_from_exchange(orderId, amountToBuy)
        .send();
      await op.confirmation();
    } catch (error) {
      err = error.message;
    }

    assert.equal(err, "WRONG_AMOUNT");
  });

  it("should let Bob fulfil Alice's order", async () => {
    // information from the exchange
    const exchangeStorage = await exchange_instance.storage();
    const orderId = await exchangeStorage.last_order_id.toNumber();
    const order = await exchangeStorage.order_book.get(orderId.toString());
    const amountToBuy = order.total_token_amount.toNumber();
    // information from the ledger
    const aliceBalanceTokenToSell = (
      await storage.ledger.get({
        owner: alice.pkh,
        token_id: order.token_id_to_sell
      })
    ).toNumber();
    let aliceBalanceTokenToBuy = await storage.ledger.get({
      owner: alice.pkh,
      token_id: order.token_id_to_buy
    });
    aliceBalanceTokenToBuy = aliceBalanceTokenToBuy
      ? aliceBalanceTokenToBuy.toNumber()
      : 0;
    let bobBalanceTokenToSell = await storage.ledger.get({
      owner: bob.pkh,
      token_id: order.token_id_to_sell
    });
    bobBalanceTokenToSell = bobBalanceTokenToSell
      ? bobBalanceTokenToSell.toNumber()
      : 0;
    const bobBalanceTokenToBuy = (
      await storage.ledger.get({
        owner: bob.pkh,
        token_id: order.token_id_to_buy
      })
    ).toNumber();

    try {
      const op = await fa2_instance.methods
        .buy_from_exchange(orderId, amountToBuy)
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    // verifies order has been removed in exchange contract
    const removedOrder = await exchangeStorage.order_book.get(
      orderId.toString()
    );
    assert.isUndefined(removedOrder);
    // new information from the ledger
    const aliceNewBalanceTokenToSell = (
      await storage.ledger.get({
        owner: alice.pkh,
        token_id: order.token_id_to_sell
      })
    ).toNumber();
    const aliceNewBalanceTokenToBuy = (
      await storage.ledger.get({
        owner: alice.pkh,
        token_id: order.token_id_to_buy
      })
    ).toNumber();
    const bobNewBalanceTokenToSell = (
      await storage.ledger.get({
        owner: bob.pkh,
        token_id: order.token_id_to_sell
      })
    ).toNumber();
    const bobNewBalanceTokenToBuy = (
      await storage.ledger.get({
        owner: bob.pkh,
        token_id: order.token_id_to_buy
      })
    ).toNumber();
    /*console.log({
      order: {
        ...order,
        token_amount_to_sell: order.token_amount_to_sell.toNumber(),
        token_amount_to_buy: order.token_amount_to_buy.toNumber(),
        total_token_amount: order.total_token_amount.toNumber()
      },
      aliceBalance: {
        tokenToSell: aliceBalanceTokenToSell + "/" + aliceNewBalanceTokenToSell,
        tokenToBuy: aliceBalanceTokenToBuy + "/" + aliceNewBalanceTokenToBuy
      },
      bobBalance: {
        tokenToSell: bobBalanceTokenToSell + "/" + bobNewBalanceTokenToSell,
        tokenToBuy: bobBalanceTokenToBuy + "/" + bobNewBalanceTokenToBuy
      }
    });*/
    // verifies swap of tokens happened in the ledger
    // on Alice's side
    assert.equal(
      aliceNewBalanceTokenToSell,
      aliceBalanceTokenToSell -
        order.total_token_amount.toNumber() *
          order.token_amount_to_sell.toNumber()
    );
    assert.equal(
      aliceNewBalanceTokenToBuy,
      aliceBalanceTokenToBuy +
        order.total_token_amount.toNumber() *
          order.token_amount_to_buy.toNumber()
    );
    // on Bob's side
    assert.equal(
      bobNewBalanceTokenToSell,
      bobBalanceTokenToSell +
        order.total_token_amount.toNumber() *
          order.token_amount_to_sell.toNumber()
    );
    assert.equal(
      bobNewBalanceTokenToBuy,
      bobBalanceTokenToBuy -
        order.total_token_amount.toNumber() *
          order.token_amount_to_buy.toNumber()
    );
  });

  /*it("should let Alice create an order", async () => {
    // Alice sells 1000 AliTokens for 1000 BobTokens
    await signerFactory(alice.sk);

    const expectedOrderId = parseInt(storage.order_id_counter) + 1;
    const tokenAmountToSell = 1;
    const tokenAmountToBuy = 2;
    const totalTokenAmount = 1000; // total token to sell
    const orderType = tokenAmountToSell < tokenAmountToBuy ? "sell" : "buy";

    try {
      const op = await fa2_instance.methods
        .new_exchange_order(
          orderType,
          [["unit"]],
          aliToken.id,
          tokenAmountToSell,
          bobToken.id,
          tokenAmountToBuy,
          totalTokenAmount
        )
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await fa2_instance.storage();

    assert.equal(expectedOrderId, parseInt(storage.order_id_counter));

    const order = await storage.order_book.get(expectedOrderId.toString());

    //assert.property(order.order_type, orderType);
    //assert.isTrue(typeof order.order_type[orderType] === "symbol");
    assert.equal(order.token_id_to_sell, aliToken.id);
    assert.equal(order.token_amount_to_sell, tokenAmountToSell);
    assert.equal(order.token_id_to_buy, bobToken.id);
    assert.equal(order.token_amount_to_buy, tokenAmountToBuy);
    assert.equal(order.total_token_amount, totalTokenAmount);
    assert.equal(order.seller, alice.pkh);
  });

  it("should let Bob fulfill Alice's order", async () => {
    await signerFactory(bob.sk);

    const bobAliTokenBalance = await storage.ledger.get({
      0: bob.pkh,
      1: aliToken.id
    });
    const bobBobTokenBalance = await storage.ledger.get({
      0: bob.pkh,
      1: bobToken.id
    });
    const aliceAliTokenBalance = await storage.ledger.get({
      0: alice.pkh,
      1: aliToken.id
    });
    const aliceBobTokenBalance = await storage.ledger.get({
      0: alice.pkh,
      1: bobToken.id
    });
    const order = await storage.order_book.get(
      storage.order_id_counter.toString()
    );

    try {
      const op = await fa2_instance.methods
        .buy_from_exchange(storage.order_id_counter, order.total_token_amount)
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await fa2_instance.storage();

    const removedOrder = await storage.order_book.get(
      storage.order_id_counter.toString()
    );
    assert.isUndefined(removedOrder);

    const bobAliTokenNewBalance = await storage.ledger.get({
      0: bob.pkh,
      1: aliToken.id
    });
    const bobBobTokenNewBalance = await storage.ledger.get({
      0: bob.pkh,
      1: bobToken.id
    });
    const aliceAliTokenNewBalance = await storage.ledger.get({
      0: alice.pkh,
      1: aliToken.id
    });
    const aliceBobTokenNewBalance = await storage.ledger.get({
      0: alice.pkh,
      1: bobToken.id
    });

    // if sell order
    const token_amount = {
      toBuy:
        order.token_amount_to_buy.toNumber() *
        order.total_token_amount.toNumber(), //bobToken
      toSell:
        order.token_amount_to_sell.toNumber() *
        order.total_token_amount.toNumber() // aliToken
    };

    // Bob's aliToken balance += Alice's aliToken to sell
    assert.equal(
      bobAliTokenBalance.toNumber() + token_amount.toSell,
      bobAliTokenNewBalance.toNumber()
    );
    // Alice's bobToken balance = Alice's bobToken to buy
    assert.equal(
      (aliceBobTokenBalance ? aliceBobTokenBalance.toNumber() : 0) +
        token_amount.toBuy,
      aliceBobTokenNewBalance.toNumber()
    );
    // Bob's bobToken balance -= Alice's bobToken to buy
    assert.equal(
      bobBobTokenBalance.toNumber() - token_amount.toBuy,
      bobBobTokenNewBalance.toNumber()
    );
    // Alice's aliToken balance -= Alice's aliToken to sell
    assert.equal(
      aliceAliTokenBalance.toNumber() - token_amount.toSell,
      aliceAliTokenNewBalance.toNumber()
    );
  });

  it("should let Bob create an order", async () => {
    await signerFactory(bob.sk);
    // Bob sells 1000 BobTokens for 1000 AliTokens

    const expectedOrderId = parseInt(storage.order_id_counter) + 1;
    const tokenAmountToSell = 2;
    const tokenAmountToBuy = 1;
    const totalTokenAmount = 500; // total token to sell
    const orderType = tokenAmountToSell < tokenAmountToBuy ? "sell" : "buy";

    try {
      const op = await fa2_instance.methods
        .new_exchange_order(
          orderType,
          [["unit"]],
          bobToken.id,
          tokenAmountToSell,
          aliToken.id,
          tokenAmountToBuy,
          totalTokenAmount
        )
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await fa2_instance.storage();

    assert.equal(expectedOrderId, parseInt(storage.order_id_counter));

    const order = await storage.order_book.get(expectedOrderId.toString());

    //assert.property(order.order_type, "buy");
    //assert.isTrue(typeof order.order_type.buy === "symbol");
    assert.equal(order.token_id_to_sell, bobToken.id);
    assert.equal(order.token_amount_to_sell, tokenAmountToSell);
    assert.equal(order.token_id_to_buy, aliToken.id);
    assert.equal(order.token_amount_to_buy, tokenAmountToBuy);
    assert.equal(order.seller, bob.pkh);
  });

  it("should let Alice get half of Bob's order", async () => {
    await signerFactory(alice.sk);

    const bobAliTokenBalance = await storage.ledger.get({
      0: bob.pkh,
      1: aliToken.id
    });
    const bobBobTokenBalance = await storage.ledger.get({
      0: bob.pkh,
      1: bobToken.id
    });
    const aliceAliTokenBalance = await storage.ledger.get({
      0: alice.pkh,
      1: aliToken.id
    });
    const aliceBobTokenBalance = await storage.ledger.get({
      0: alice.pkh,
      1: bobToken.id
    });
    const order = await storage.order_book.get(
      storage.order_id_counter.toString()
    );
    const tokens_to_buy =
      (order.total_token_amount * order.token_amount_to_sell.toNumber()) / 2;

    try {
      const op = await fa2_instance.methods
        .buy_from_exchange(storage.order_id_counter, tokens_to_buy)
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await fa2_instance.storage();

    const updatedOrder = await storage.order_book.get(
      storage.order_id_counter.toString()
    );
    assert.notEqual(
      order.token_amount_to_sell,
      updatedOrder.token_amount_to_sell
    );

    const bobAliTokenNewBalance = await storage.ledger.get({
      0: bob.pkh,
      1: aliToken.id
    });
    const bobBobTokenNewBalance = await storage.ledger.get({
      0: bob.pkh,
      1: bobToken.id
    });
    const aliceAliTokenNewBalance = await storage.ledger.get({
      0: alice.pkh,
      1: aliToken.id
    });
    const aliceBobTokenNewBalance = await storage.ledger.get({
      0: alice.pkh,
      1: bobToken.id
    });

    // Bob's aliToken balance += Alice's aliToken to sell
    assert.equal(
      bobAliTokenBalance.toNumber() + tokens_to_buy,
      bobAliTokenNewBalance.toNumber()
    );
    // Alice's bobToken balance = Alice's bobToken to buy
    assert.equal(
      (aliceBobTokenBalance ? aliceBobTokenBalance.toNumber() : 0) +
        order.total_token_amount.toNumber() / 2,
      aliceBobTokenNewBalance.toNumber()
    );
    // Bob's bobToken balance -= Alice's bobToken to buy
    assert.equal(
      bobBobTokenBalance.toNumber() - order.total_token_amount.toNumber() / 2,
      bobBobTokenNewBalance.toNumber()
    );
    // Alice's aliToken balance -= Alice's aliToken to sell
    assert.equal(
      aliceAliTokenBalance.toNumber() - order.total_token_amount.toNumber(),
      aliceAliTokenNewBalance.toNumber()
    );
  });

  it("should create and fulfill orders with random values", async () => {
    const createOrder = async ({
      expectedOrderId,
      orderType,
      tokenIdToSell,
      tokenIdToBuy,
      tokenAmountToSell,
      tokenAmountToBuy,
      totalTokenAmount
    }) => {
      // saves new order in contract and verifies the values
      try {
        const op = await fa2_instance.methods
          .new_exchange_order(
            orderType,
            [["unit"]],
            tokenIdToSell,
            tokenAmountToSell,
            tokenIdToBuy,
            tokenAmountToBuy,
            totalTokenAmount
          )
          .send();
        await op.confirmation();
      } catch (error) {
        console.log(error);
        return false;
      }
      storage = await fa2_instance.storage();

      assert.equal(expectedOrderId, parseInt(storage.order_id_counter));

      const order = await storage.order_book.get(expectedOrderId.toString());

      //assert.property(order.order_type, "buy");
      //assert.isTrue(typeof order.order_type.buy === "symbol");
      assert.equal(order.token_id_to_sell, bobToken.id);
      assert.equal(order.token_amount_to_sell, tokenAmountToSell);
      assert.equal(order.token_id_to_buy, aliToken.id);
      assert.equal(order.token_amount_to_buy, tokenAmountToBuy);
      assert.equal(order.seller, bob.pkh);

      return true;
    };

    const fulfilOrder = async (order, amount, tokens_to_buy) => {
      const bobAliTokenBalance = await storage.ledger.get({
        0: bob.pkh,
        1: aliToken.id
      });
      const bobBobTokenBalance = await storage.ledger.get({
        0: bob.pkh,
        1: bobToken.id
      });
      const aliceAliTokenBalance = await storage.ledger.get({
        0: alice.pkh,
        1: aliToken.id
      });
      const aliceBobTokenBalance = await storage.ledger.get({
        0: alice.pkh,
        1: bobToken.id
      });

      try {
        const op = await fa2_instance.methods
          .buy_from_exchange(storage.order_id_counter, tokens_to_buy)
          .send();
        await op.confirmation();
      } catch (error) {
        console.log(error);
      }

      storage = await fa2_instance.storage();

      const updatedOrder = await storage.order_book.get(
        storage.order_id_counter.toString()
      );
      assert.notEqual(
        order.token_amount_to_sell,
        updatedOrder.token_amount_to_sell
      );

      const bobAliTokenNewBalance = await storage.ledger.get({
        0: bob.pkh,
        1: aliToken.id
      });
      const bobBobTokenNewBalance = await storage.ledger.get({
        0: bob.pkh,
        1: bobToken.id
      });
      const aliceAliTokenNewBalance = await storage.ledger.get({
        0: alice.pkh,
        1: aliToken.id
      });
      const aliceBobTokenNewBalance = await storage.ledger.get({
        0: alice.pkh,
        1: bobToken.id
      });

      // Bob's aliToken balance += Alice's aliToken to sell
      assert.equal(
        bobAliTokenBalance.toNumber() + tokens_to_buy,
        bobAliTokenNewBalance.toNumber()
      );
      // Alice's bobToken balance = Alice's bobToken to buy
      assert.equal(
        (aliceBobTokenBalance ? aliceBobTokenBalance.toNumber() : 0) +
          Math.ceil(order.total_token_amount.toNumber() / amount),
        aliceBobTokenNewBalance.toNumber()
      );
      // Bob's bobToken balance -= Alice's bobToken to buy
      assert.equal(
        bobBobTokenBalance.toNumber() -
          Math.ceil(order.total_token_amount.toNumber() / amount),
        bobBobTokenNewBalance.toNumber()
      );
      // Alice's aliToken balance -= Alice's aliToken to sell
      assert.equal(
        aliceAliTokenBalance.toNumber() - tokens_to_buy,
        aliceAliTokenNewBalance.toNumber()
      );
    };

    await signerFactory(bob.sk);
    // Bob sells 1000 BobTokens for 500 AliTokens

    let expectedOrderId = parseInt(storage.order_id_counter) + 1;
    let tokenAmountToSell = 2;
    let tokenAmountToBuy = 1;
    let totalTokenAmount = 500; // total token to sell
    let orderType = tokenAmountToSell < tokenAmountToBuy ? "sell" : "buy";

    let newOrder = {
      expectedOrderId,
      orderType,
      tokenIdToSell: bobToken.id,
      tokenIdToBuy: aliToken.id,
      tokenAmountToSell,
      tokenAmountToBuy,
      totalTokenAmount
    };

    let orderCreated = await createOrder(newOrder);

    assert.isTrue(orderCreated);

    await signerFactory(alice.sk);

    let order = await storage.order_book.get(
      storage.order_id_counter.toString()
    );
    let fractionOfOrder = 3;
    let tokens_to_buy = Math.ceil(
      (order.total_token_amount * order.token_amount_to_sell.toNumber()) /
        fractionOfOrder
    );

    await fulfilOrder(order, fractionOfOrder, tokens_to_buy);

    // BOB SELLS 0 TO 1000 BOBTOKENS FOR 0 TO 500 ALITOKENS (RANDOM)

    await signerFactory(bob.sk);
    storage = await fa2_instance.storage();

    expectedOrderId = parseInt(storage.order_id_counter) + 1;
    tokenAmountToSell = Math.ceil(Math.random() * (10 - 1) + 1);
    tokenAmountToBuy = Math.ceil(Math.random() * (10 - 1) + 1);
    totalTokenAmount = Math.ceil(Math.random() * (1000 - 1) + 1); // total token to sell
    orderType = tokenAmountToSell < tokenAmountToBuy ? "sell" : "buy";

    newOrder = {
      expectedOrderId,
      orderType,
      tokenIdToSell: bobToken.id,
      tokenIdToBuy: aliToken.id,
      tokenAmountToSell,
      tokenAmountToBuy,
      totalTokenAmount
    };

    orderCreated = await createOrder(newOrder);

    assert.isTrue(orderCreated);

    await signerFactory(alice.sk);

    order = await storage.order_book.get(storage.order_id_counter.toString());
    fractionOfOrder = Math.ceil(Math.random() * (10 - 1) + 1);
    tokens_to_buy = Math.ceil(
      (order.total_token_amount * order.token_amount_to_sell.toNumber()) /
        fractionOfOrder
    );

    console.log(order, fractionOfOrder, tokens_to_buy);

    await fulfilOrder(order, fractionOfOrder, tokens_to_buy);
  });*/
});
