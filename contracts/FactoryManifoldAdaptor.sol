// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "./IManifold1155Adaptor.sol";
import "./IFactory.sol";


contract FactoryManifoldAdaptor is IFactory, OwnableUpgradeable {
    address public implementation;

    mapping(address => uint256) private _fee;

    function initialize(
        address implementation_
    ) external initializer {
        implementation = implementation_;
        __Ownable_init();
    }

    function deployWithMinimalProxy(
        address creator_,
        bool gelatoRelayEnabled_,
        address certificateAuthority_
    ) external {
        address nft = ClonesUpgradeable.clone(implementation);

        IManifold1155Adaptor(nft).initialize(creator_, gelatoRelayEnabled_, 
            certificateAuthority_, address(this));


        OwnableUpgradeable(nft).transferOwnership(msg.sender);
    }

    function getFee(address token) public view override returns (uint256){
        return _fee[token];
    }

    function setFee(address token, uint256 value) external onlyOwner {
        _fee[token] = value;
    }

    receive() external payable {}

    function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
        token.transfer(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

}