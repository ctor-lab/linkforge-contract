// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "./interfaces/IClaimable1155.sol";
import "./interfaces/IFactory.sol";


contract Factory is IFactory, OwnableUpgradeable {
    address public implementation;

    mapping(address => uint256) private _fee;

    function initialize(
        address implementation_
    ) external initializer {
        implementation = implementation_;
        __Ownable_init();
    }

    function deployWithMinimalProxy(
        string calldata name_,
        string calldata symbol_,
        bool gelatoRelayEnabled_,
        address certificateAuthority_
    ) external {
        address nft = ClonesUpgradeable.clone(implementation);

        IClaimable1155(nft).initialize(name_, symbol_, gelatoRelayEnabled_, 
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