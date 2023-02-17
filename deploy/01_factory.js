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

/**
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

  if (networkName !== 'hardhat') {
    await hre.tenderly.verify({
      name: 'ClaimableNFT',
      address: ClaimableNFT.implementation,
    });
  } */

  let Claimable1155 = await deploy('Claimable1155', {
    from: deployer.address,
    gasLimit: 4000000,
    args: [],
  });

  console.log('Claimable1155 address: ', Claimable1155.address);

  let Factory = await deploy('Factory', {
    from: deployer.address,
    gasLimit: 4000000,
    proxy: {
      execute: {
        init: {
          methodName: 'initialize',
          args: [Claimable1155.address],
        },
      },
      proxyContract: 'OpenZeppelinTransparentProxy',
    },
    args: [],
  });

  console.log('Factory address: ', Factory.address);

  if (networkName !== 'hardhat') {
    await hre.tenderly.verify({
      name: 'Claimable1155',
      address: Claimable1155.address,
    });

    await hre.tenderly.verify({
      name: 'Factory',
      address: Factory.implementation,
    });
  }

  

};