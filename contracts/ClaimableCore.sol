// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ClaimableBase.sol";


abstract contract ClaimableCore is ClaimableBase, OwnableUpgradeable {

    constructor() {
        _disableInitializers();
    }

    function __ClaimableCore_init(
        bool gelatoRelayEnabled_,
        address certificateAuthority_
    ) internal onlyInitializing {
        ClaimableBaseStorage.layout().gelatoRelayEnabled = gelatoRelayEnabled_;
        _setDefaultCertificateAuthority(certificateAuthority_);
        __Ownable_init();
    }

    function toggleGelatoRelayEnabled() external onlyOwner {
        ClaimableBaseStorage.layout().gelatoRelayEnabled = !ClaimableBaseStorage.layout().gelatoRelayEnabled;
    }

    function setCertificateAuthority(address certificateAuthority_) external onlyOwner {
        _setDefaultCertificateAuthority(certificateAuthority_);
    }

    function revokeSigners(address[] calldata signers) external onlyOwner {
        for(uint256 i=0;i<signers.length;) {
            _revoke(signers[i]);
            unchecked {
                ++i;
            }
        }
    }

    receive() external payable {}

    function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
        token.transfer(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}