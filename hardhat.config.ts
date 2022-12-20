import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import { config as dotenvConfig } from "dotenv";
import "hardhat-gas-reporter";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";
import { resolve } from "path";
import "solidity-coverage";

import "./tasks/accounts";
import "./tasks/deploy";
import "./tasks/interaction";

dotenvConfig({ path: resolve(__dirname, "./.env") });

// Ensure that we have all the environment variables we need.
const mnemonic: string | undefined = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}

const infuraApiKey: string | undefined = process.env.INFURA_API_KEY;
if (!infuraApiKey) {
  throw new Error("Please set your INFURA_API_KEY in a .env file");
}

const chainIds = {
  "arbitrum-mainnet": 42161,
  avalanche: 43114,
  bsc: 56,
  hardhat: 31337,
  mainnet: 1,
  "optimism-mainnet": 10,
  "polygon-mainnet": 137,
  "polygon-mumbai": 80001,
  rinkeby: 4,
  goerli:5,
  baobab: 1001,
  klaytn: 8217,
};

function getChainConfig(chain: keyof typeof chainIds): NetworkUserConfig {
  let jsonRpcUrl: string = "";
  let privateKey = process.env.GOERLI_PRIVATE_KEY || "";

  switch (chain) {
    case "mainnet":
      privateKey = process.env.MAINNET_PRIVATE_KEY || "";
      break;
    case "avalanche":
      jsonRpcUrl = "https://api.avax.network/ext/bc/C/rpc";
      break;
    case "bsc":
      jsonRpcUrl = "https://bsc-dataseed1.binance.org";
      break;
    case "baobab":
      jsonRpcUrl = "https://api.baobab.klaytn.net:8651/";
      privateKey = process.env.BAOBAB_PRIVATE_KEY || "";
      break;
    case "klaytn":
      jsonRpcUrl = "https://public-node-api.klaytnapi.com/v1/cypress";
      privateKey = process.env.KLAYTN_PRIVATE_KEY || "";
      break;
    default:
      jsonRpcUrl = "https://" + chain + ".infura.io/v3/" + infuraApiKey;
  }
  return {
    accounts: [privateKey],
    chainId: chainIds[chain],
    url: jsonRpcUrl,
  };
}

const network = process.env.TESTING === "true" ? "hardhat" : process.env.DEPLOY_NETWORK || "rinkeby";

const config: HardhatUserConfig = {
  defaultNetwork: network,
  etherscan: {
    apiKey: {
      arbitrumOne: process.env.ARBISCAN_API_KEY || "",
      avalanche: process.env.SNOWTRACE_API_KEY || "",
      bsc: process.env.BSCSCAN_API_KEY || "",
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      optimisticEthereum: process.env.OPTIMISM_API_KEY || "",
      polygon: process.env.POLYGONSCAN_API_KEY || "",
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || "",
      goerli: process.env.ETHERSCAN_API_KEY || "",
      rinkeby: process.env.ETHERSCAN_API_KEY || "",
    },
  },
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: "./contracts",
    gasPrice: 50000000000,
  },
  networks: {
    hardhat: {
      accounts: {
        mnemonic,
      },
      chainId: chainIds.hardhat,
    },
    arbitrum: getChainConfig("arbitrum-mainnet"),
    avalanche: getChainConfig("avalanche"),
    bsc: getChainConfig("bsc"),
    mainnet: getChainConfig("mainnet"),
    optimism: getChainConfig("optimism-mainnet"),
    "polygon-mainnet": getChainConfig("polygon-mainnet"),
    "polygon-mumbai": getChainConfig("polygon-mumbai"),
    rinkeby: getChainConfig("rinkeby"),
    goerli: getChainConfig("goerli"),
    baobab: getChainConfig("baobab"),
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.13",
    settings: {
      metadata: {
        bytecodeHash: "none",
      },
      optimizer: {
        enabled: true,
        runs: 150,
      },
    },
  },
  typechain: {
    outDir: "src/types",
    target: "ethers-v5",
  },
};

export default config;