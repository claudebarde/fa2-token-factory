const FA2TokenFactory = artifacts.require("FA2TokenFactory");
const { MichelsonMap } = require("@taquito/taquito");

const initialStorage = {
  ledger: new MichelsonMap(),
  operators: new MichelsonMap(),
  token_total_supply: new MichelsonMap(),
  token_metadata: new MichelsonMap(),
  order_book: new MichelsonMap(),
  order_id_counter: 0
};

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(FA2TokenFactory, initialStorage);
};
