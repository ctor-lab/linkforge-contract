import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction, DeployResult} from 'hardhat-deploy/types';

import { ethers } from 'hardhat';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const {deployments, getNamedAccounts} = hre;
	const {deploy} = deployments;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  console.log('=============================');
  console.log('deployer: ', deployer.address);
  console.log('=============================');


  let LinkForge1155 = await deploy('LinkForge1155', {
    from: deployer.address,
    gasLimit: 8000000,
    args: [],
    log: true
  });

  console.log('LinkForge1155 address: ', LinkForge1155.address);

  let LinkForge721Edition = await deploy('LinkForge721Edition', {
    from: deployer.address,
    gasLimit: 8000000,
    args: [],
    log: true
  });

  console.log('LinkForge721Edition address: ', LinkForge721Edition.address); 

  let Factory = await deploy('Factory', {
    from: deployer.address,
    gasLimit: 4000000,
    proxy: {
      execute: {
        init: {
          methodName: 'initialize',
          args: [LinkForge1155.address, LinkForge721Edition.address],
        },
      },
      proxyContract: 'OpenZeppelinTransparentProxy',
    },
    args: [],
    log: true
  });



  console.log('Factory address: ', Factory.address);

  const FactoryContract = await ethers.getContractAt("Factory", Factory.address);


  if(await FactoryContract.implementation() != LinkForge1155.address) {
    await FactoryContract.setImplementation(LinkForge1155.address);
    console.log("LinkForge1155 Implementation Updated")
  }

  if(await FactoryContract.implementationLinkForge721Edition() != LinkForge721Edition.address) {
    await FactoryContract.setImplementationLinkForge721Edition(LinkForge721Edition.address);
    console.log("LinkForge721Edition Implementation Updated")
  }

  if (hre.network.name !== 'hardhat') {
    await hre.tenderly.verify({
      name: 'LinkForge1155',
      address: LinkForge1155.address,
    });

    if(Factory.implementation) {
      await hre.tenderly.verify({
        name: 'Factory',
        address: Factory.implementation,
      });
    }
    
  }
};


export default func;
func.tags = ['factory'];