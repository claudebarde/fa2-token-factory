const TestContract = artifacts.require("TestContract");
const { MichelsonMap } = require("@taquito/taquito");

const initialStorage = {
  order_book: new MichelsonMap(),
  order_count: 0
};

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(TestContract, initialStorage);
};
