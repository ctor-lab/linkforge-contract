const hre = require('hardhat');
const { assert } = require('chai');

const { ethers } = hre;
const networkName = hre.network.name;

module.exports = async ({
  getNamedAccounts,
  deployments,
  getChainId,
  getUnnamedAccounts,
}) => {
  const { deploy } = deployments;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  console.log('=============================');
  console.log('deployer: ', deployer.address);
  console.log('=============================');


  let ClaimableNFT = await deploy('ClaimableNFT', {
    from: deployer.address,
    gasLimit: 4000000,
    proxy: {
      execute: {
        init: {
          methodName: 'initialize',
          args: [true, "name", "symbol"],
        },
      },
      proxyContract: 'OpenZeppelinTransparentProxy',
    },
    args: [],
  });

  console.log('ClaimableNFT address: ', ClaimableNFT.address);

  

};