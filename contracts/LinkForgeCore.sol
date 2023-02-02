// SPDX-License-Identifier: BUSL-1.1
// Author: Ctor Lab

pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solady/src/auth/OwnableRoles.sol";

import "./LinkForgeBase.sol";
import "erc721a-upgradeable/contracts/ERC721A__Initializable.sol";

abstract contract LinkForgeCore is LinkForgeBase, OwnableRoles, ERC721A__Initializable {
    
    function __LinkForgeCore_init(
        bool gelatoRelayEnabled_,
        address certificateAuthority_
    ) internal onlyInitializingERC721A {
        LinkForgeBaseStorage.layout().gelatoRelayEnabled = gelatoRelayEnabled_;
        _setDefaultCertificateAuthority(certificateAuthority_);
        _initializeOwner(msg.sender);
    }

    function toggleGelatoRelayEnabled() external onlyOwner {
        LinkForgeBaseStorage.layout().gelatoRelayEnabled = !LinkForgeBaseStorage.layout().gelatoRelayEnabled;
    }

    function setCertificateAuthority(address certificateAuthority_) external onlyOwner {
        _setDefaultCertificateAuthority(certificateAuthority_);
    }

    function setUnlimitedSigner(address signer) external onlyOwner {
        if(LinkForgeBaseStorage.layout().signerState[signer] != SIGNER_AVAILABLE) revert InvalidSigner();
        LinkForgeBaseStorage.layout().signerState[signer] = SIGNER_UNLIMITED;
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