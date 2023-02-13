// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";



import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Claimable.sol";


abstract contract ClaimableCore is Claimable, OwnableUpgradeable {

    constructor() {
        _disableInitializers();
    }

    function __ClaimableCore_init(
        bool gelatoRelayEnabled_,
        address certificateAuthority_
    ) external initializer {
        gelatoRelayEnabled = gelatoRelayEnabled_;
        _setDefaultCertificateAuthority(certificateAuthority_);
        __Ownable_init();
    }

    function setCertificateAuthority(address certificateAuthority_) external onlyOwner {
        _setDefaultCertificateAuthority(certificateAuthority_);
    }

    receive() external payable {}

    function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
        token.transferFrom(address(this), msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}