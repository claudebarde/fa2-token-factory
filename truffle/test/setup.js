const CONTRACT = artifacts.require("FA2TokenFactory");
const { Tezos } = require("@taquito/taquito");
const { InMemorySigner } = require("@taquito/signer");
const { alice } = require("../scripts/sandbox/accounts");

let storage, fa2_address, fa2_instance;

const signerFactory = async pk => {
  await Tezos.setProvider({ signer: new InMemorySigner(pk) });
  return Tezos;
};

module.exports = async () => {
  fa2_instance = await CONTRACT.deployed();
  // this code bypasses Truffle config to be able to have different signers
  // until I find how to do it directly with Truffle
  await Tezos.setProvider({ rpc: "http://localhost:8732" });
  await signerFactory(alice.sk);
  /**
   * Display the current contract address for debugging purposes
   */
  console.log("Contract deployed at:", fa2_instance.address);
  fa2_address = fa2_instance.address;
  fa2_instance = await Tezos.contract.at(fa2_instance.address);
  storage = await fa2_instance.storage();

  return {
    storage,
    fa2_address,
    fa2_instance,
    signerFactory
  };
};
