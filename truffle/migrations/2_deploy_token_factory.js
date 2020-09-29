const FA2TokenFactory = artifacts.require("FA2TokenFactory");
const { MichelsonMap } = require("@taquito/taquito");
const { alice } = require("../scripts/sandbox/accounts");

const wrapperId = 1;
const ledger = new MichelsonMap();
ledger.set(
  {
    0: alice.pkh,
    1: wrapperId
  },
  0
);

const initialStorage = {
  ledger,
  operators: new MichelsonMap(),
  token_total_supply: MichelsonMap.fromLiteral({
    [wrapperId]: 0
  }),
  token_metadata: MichelsonMap.fromLiteral({
    [wrapperId]: {
      token_id: wrapperId,
      admin: alice.pkh,
      symbol: "wTK",
      name: "wToken",
      decimals: 0,
      extras: new MichelsonMap()
    }
  }),
  order_book: new MichelsonMap(),
  order_id_counter: 0
};

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(FA2TokenFactory, initialStorage);
};
