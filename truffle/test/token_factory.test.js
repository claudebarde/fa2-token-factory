const { Tezos } = require("@taquito/taquito");
const { alice, bob } = require("../scripts/sandbox/accounts");
const setup = require("./setup");

contract("FA2 Fungible Token Factory", () => {
  let storage;
  let fa2_address;
  let fa2_instance;
  let signerFactory;

  const aliToken = {
    id: 1,
    symbol: "ALICE",
    name: "Alice",
    decimals: 0,
    extras: [["picture", "aliToken.png"]],
    totalSupply: 21000000
  };

  const bobToken = {
    id: 2,
    symbol: "BOB",
    name: "Bob",
    decimals: 0,
    extras: [["picture", "bobToken.png"]],
    totalSupply: 2000000
  };

  before(async () => {
    const config = await setup();
    storage = config.storage;
    fa2_address = config.fa2_address;
    fa2_instance = config.fa2_instance;
    signerFactory = config.signerFactory;
    Tezos.setRpcProvider("http://localhost:8732");
  });

  it("should show initial counter at 0", () => {
    assert.equal(storage.order_id_counter, 0);
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
      0: alice.pkh,
      1: aliToken.id
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
      0: bob.pkh,
      1: aliToken.id
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
      0: bob.pkh,
      1: bobToken.id
    });
    assert.equal(bobBalance.toNumber(), bobToken.totalSupply);
  });

  it("should let Alice create an order", async () => {
    await signerFactory(alice.sk);

    const expectedOrderId = parseInt(storage.order_id_counter) + 1;
    const tokenAmountToSell = 1000;
    const tokenAmountToBuy = 1000;

    try {
      const op = await fa2_instance.methods
        .new_exchange_order(
          "buy",
          [["unit"]],
          aliToken.id,
          tokenAmountToSell,
          bobToken.id,
          tokenAmountToBuy
        )
        .send();
      await op.confirmation();
    } catch (error) {
      console.log(error);
    }

    storage = await fa2_instance.storage();

    assert.equal(expectedOrderId, parseInt(storage.order_id_counter));

    const order = await storage.order_book.get(expectedOrderId.toString());

    assert.property(order.order_type, "buy");
    assert.isTrue(typeof order.order_type.buy === "symbol");
    assert.equal(order.token_id_to_sell, aliToken.id);
    assert.equal(order.token_amount_to_sell, tokenAmountToSell);
    assert.equal(order.token_id_to_buy, bobToken.id);
    assert.equal(order.token_amount_to_buy, tokenAmountToBuy);
    assert.equal(order.seller, alice.pkh);
  });

  it("should let Bob fulfill Alice's order", async () => {
    await signerFactory(bob.sk);

    const bobBalance = await storage.ledger.get({
      0: bob.pkh,
      1: aliToken.id
    });
    const aliceBalance = await storage.ledger.get({
      0: alice.pkh,
      1: aliToken.id
    });
    const order = await storage.order_book.get(
      storage.order_id_counter.toString()
    );

    try {
      const op = await fa2_instance.methods
        .buy_from_exchange(storage.order_id_counter, order.token_amount_to_sell)
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
  });
});
