const Exchange = artifacts.require("Exchange");
const { MichelsonMap } = require("@taquito/taquito");
const { alice } = require("../scripts/sandbox/accounts");
const faucet = require("../faucet");

// const admin = alice.pkh;
const admin = faucet.pkh;

const initialStorage = {
  last_order_id: 0,
  order_book: new MichelsonMap(),
  ledger_address: admin,
  admin
};

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(Exchange, initialStorage);
};
