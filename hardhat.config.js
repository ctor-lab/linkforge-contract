require("@nomicfoundation/hardhat-toolbox");
require('hardhat-deploy');
require('hardhat-deploy-ethers');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
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
    mumbai: {
      url: 'https://polygon-mumbai.g.alchemy.com/v2/DK2lMR_zdFakSO2hWXhfogKKkfh9XZZT',
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },

    arbitrum_goerli: {
      url: 'https://goerli-rollup.arbitrum.io/rpc',
      accounts: [`0x${process.env.PRIVATE_KEY}`],
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
};
