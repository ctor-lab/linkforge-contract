// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./interfaces/IClaimable1155.sol";
import "./interfaces/IFactory.sol";


contract Factory is IFactory, OwnableUpgradeable {
    address public implementation;

    mapping(address => uint256) private _feeRelayed;
    uint256 private _feeSelfClaimed;

    function initialize(
        address implementation_
    ) external initializer {
        implementation = implementation_;
        __Ownable_init();
    }

    function deploy(
        string calldata name_,
        string calldata symbol_,
        bool gelatoRelayEnabled_,
        address certificateAuthority_
    ) external {
        address nft = address(new ERC1967Proxy(implementation, ""));

        IClaimable1155(nft).initialize(name_, symbol_, gelatoRelayEnabled_, 
            certificateAuthority_, address(this));

        OwnableUpgradeable(nft).transferOwnership(msg.sender);
    }

    function getFeeRelayed(address token) public view override returns (uint256){
        return _feeRelayed[token];
    }

    function getFeeSelfClaimed() public view override returns (uint256){
        return _feeSelfClaimed;
    }

    function setFeeRelayed(address token, uint256 value) external onlyOwner {
        _feeRelayed[token] = value;
    }

    function setFeeSelfClaimed(address token, uint256 value) external onlyOwner {
        _feeRelayed[token] = value;
    }

    function authorizeUpgrade(address newImplementation) public view {
        require(newImplementation == implementation);
    }

    receive() external payable {}

    function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
        token.transfer(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

}