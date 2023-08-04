import { HardhatUserConfig } from "hardhat/config";

import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";
import "hardhat-deploy";
require('hardhat-abi-exporter');

import * as tdly from "@tenderly/hardhat-tenderly";
tdly.setup();

/** @type import('hardhat/config').HardhatUserConfig */
const config: HardhatUserConfig =  {
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        // viaIR: true,
        enabled: true,
        runs: 10000,
      },
    },
  },
  networks: {
    goerli: {
      url: process.env.GOERLI_RPC_URL,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    polygon: {
      url: 'https://polygon.rpc.thirdweb.com',
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 100_000_000_000
    },
    mumbai: {
      url: 'https://polygon-mumbai.g.alchemy.com/v2/DK2lMR_zdFakSO2hWXhfogKKkfh9XZZT',
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },

    arbitrum_goerli: {
      url: 'https://arbitrum-goerli.public.blastapi.io',
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      chainId: 421613
    },   

    /*
    mainnet: {
      //url: process.env.MAINNET_RPC_URL,
      //accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    rinkeby: {
      //url: process.env.RINKEBY_RPC_URL,
      //accounts: [`0x${process.env.PRIVATE_KEY}`],
    }, */
  },
  tenderly: {
    username: "ctorlab", // tenderly username (or organization name)
    project: "project", // project name
    privateVerification: true // if true, contracts will be verified privately, if false, contracts will be verified publicly
  },

  typechain: {
    target: 'ethers-v5',
  },
};


export default config;
