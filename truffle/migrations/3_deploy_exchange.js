const Exchange = artifacts.require("Exchange");
const { MichelsonMap } = require("@taquito/taquito");
const { alice } = require("../scripts/sandbox/accounts");

const initialStorage = {
  last_order_id: 0,
  order_book: new MichelsonMap(),
  ledger_address: alice.pkh,
  admin: alice.pkh
};

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(Exchange, initialStorage);
};
