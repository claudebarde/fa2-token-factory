const FA2TokenFactory = artifacts.require("FA2TokenFactory");
const { MichelsonMap } = require("@taquito/taquito");
const { alice } = require("../scripts/sandbox/accounts");
const faucet = require("../faucet");

const char2Bytes = str => Buffer.from(str, "utf8").toString("hex");

// const admin = alice.pkh;
const admin = faucet.pkh;

const wrapperId = 1;
const ledger = new MichelsonMap();
ledger.set(
  {
    owner: admin,
    token_id: wrapperId
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
      0: wrapperId,
      1: MichelsonMap.fromLiteral({
        "": char2Bytes(
          `{"name":"wToken","symbol":"wTK","decimals":"6","authors":"[Claude Barde]"}`
        )
      })
    }
  }),
  token_admins: MichelsonMap.fromLiteral({
    1: [admin, true]
  }),
  metadata: MichelsonMap.fromLiteral({
    "": char2Bytes("tezos-storage:contents"),
    contents: char2Bytes(
      JSON.stringify({
        name: "FA2 Token Factory",
        description:
          "A fungible token factory to create, mint, transfer and exchange tokens",
        authors: ["https://www.github.com/claudebarde"]
      })
    )
  }),
  admin,
  exchange_address: admin,
  last_token_id: wrapperId
};

module.exports = async (deployer, _network, accounts) => {
  deployer.deploy(FA2TokenFactory, initialStorage);
};
