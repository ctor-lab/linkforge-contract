// SPDX-License-Identifier: BUSL-1.1
// Author: Ctor Lab

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {GelatoRelayContext} from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";


int256 constant SIGNER_AVAILABLE = 0;
int256 constant SIGNER_USED = 1;
int256 constant SIGNER_REVOKED = 2;
int256 constant SIGNER_UNLIMITED = type(int256).min;


library LinkForgeBaseStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256('CtorLab.storage.contracts.LinkForgeBase');

    struct Layout {
        bool gelatoRelayEnabled;
        address defaultCertificateAuthority;
        mapping(address=> int256) signerState;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

abstract contract LinkForgeBase is GelatoRelayContext{

    error InvalidSigner();
    error ZeroAddress();
    error InvalidCertificate();
    error InvalidSignature();
    error GelatoRelayNotEnabled();

    event SignerRevoked(address indexed signer);
    event SignerUsed(address indexed signer);

    function claim(address recepiant, address signer, uint64 deadline, bytes calldata data, bytes calldata signature, bytes calldata certificate) public payable {
        bytes32 certificateHash = _verifyCertificate(signer, deadline, data, certificate);
        _verifySignature(recepiant, certificateHash, signer, signature);

        int256 signerState_ = LinkForgeBaseStorage.layout().signerState[signer];

        if(signerState_ > SIGNER_AVAILABLE) {
            revert InvalidSigner();
        } else if(signerState_ == SIGNER_AVAILABLE) {
            LinkForgeBaseStorage.layout().signerState[signer] = SIGNER_USED;
        }
        emit SignerUsed(signer);
        
        _processClaim(recepiant, data);
    }

    function claimThroughRelay(address recepiant, address signer, uint64 deadline, bytes calldata data, bytes calldata signature, bytes calldata certificate) 
        external onlyGelatoRelay {

        if (!LinkForgeBaseStorage.layout().gelatoRelayEnabled) revert GelatoRelayNotEnabled();
        
        _beforeTransferRelayFee(recepiant, data);
        _transferRelayFee();

        claim(recepiant, signer, deadline, data, signature, certificate);
    }


    function _processClaim(address recepiant, bytes calldata data) internal virtual;


    function _beforeTransferRelayFee(address recepiant, bytes calldata data) internal virtual {}


    function signerState(address signer) public view returns (int256) {
        return LinkForgeBaseStorage.layout().signerState[signer];
    }

    function getCertificateAuthority() public virtual view returns (address) {
        return LinkForgeBaseStorage.layout().defaultCertificateAuthority;
    }

    function _setDefaultCertificateAuthority(address certificateAuthority_) internal {
        LinkForgeBaseStorage.layout().defaultCertificateAuthority = certificateAuthority_;
    }

    function gelatoRelayEnabled() public view returns(bool){
        return LinkForgeBaseStorage.layout().gelatoRelayEnabled;
    }
    

    function _verifyCertificate(address signer,  uint64 deadline, bytes memory data, bytes memory certificate) virtual internal view returns (bytes32) {
        bytes32 certificateHash = ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encodePacked(
            signer, deadline,
            address(this), block.chainid,
            data
        )));

        if(deadline < block.timestamp) revert InvalidCertificate();
        if(ECDSAUpgradeable.recover(certificateHash, certificate) != getCertificateAuthority()) revert InvalidCertificate();
    
        return certificateHash;
    }

    function _verifySignature(address recepiant, bytes32 certificateHash, address signer, bytes calldata signature) virtual internal pure {

        bytes32 signautureHash = ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encodePacked(
            recepiant, certificateHash
        )));

        if(ECDSAUpgradeable.recover(signautureHash, signature) != signer) revert InvalidSignature();
    }

    function _revoke(address signer) internal {
        LinkForgeBaseStorage.layout().signerState[signer] = SIGNER_REVOKED;
        emit SignerRevoked(signer);
    }
}