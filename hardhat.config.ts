import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import process from "process";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
  networks: {
    mumbai: {
      url: "https://rpc.ankr.com/polygon_mumbai",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : []
    },
    polygon: {
      url: "https://polygon.llamarpc.com",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : []
    },
    binance: {
      url: "https://bsc.rpc.blxrbdn.com",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : []
    },
    bsct: {
      url: "https://endpoints.omniatech.io/v1/bsc/testnet/public",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : []
    },
    arbitrumGoerli: {
      url: "https://arbitrum-goerli.publicnode.com",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : []
    }
  },
  mocha: {
      timeout: 1000000000000,
  },
  etherscan: {
    apiKey: {
      polygon: process.env.ETHERSCAN_API_KEY || '',
      polygonMumbai: process.env.ETHERSCAN_API_KEY || '',
      bsc: process.env.ETHERSCAN_API_KEY || '',
      bscTestnet: process.env.ETHERSCAN_API_KEY || ''
    }
  }
};

export default config;
