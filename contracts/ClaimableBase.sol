// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {GelatoRelayContext} from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";


uint256 constant SIGNER_AVAILABLE = 0;
uint256 constant SIGNER_USED = 1;
uint256 constant SIGNER_REVOKED = 2;


library ClaimableBaseStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256('CtorLab.contracts.storage.ClaimableBase');

    struct Layout {
        bool gelatoRelayEnabled;
        address defaultCertificateAuthority;
        mapping(address=> uint256) signerState;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}


abstract contract ClaimableBase is GelatoRelayContext{

    error InvalidSigner();
    error ZeroAddress();
    error InvalidCertificate();
    error InvalidSignature();
    error GelatoRelayNotEnabled();

    event SignerRevoked(address signer);
    event SignerUsed(address signer);

    function claim(address claimant, address signer, uint64 deadline, bytes calldata data, bytes calldata signature, bytes calldata certificate) public payable {
        bytes32 certificateHash = _verifyCertificate(signer, deadline, data, certificate);
        _verySignature(claimant, certificateHash, signer, signature);

        if(ClaimableBaseStorage.layout().signerState[signer] != SIGNER_AVAILABLE) revert InvalidSigner();

        ClaimableBaseStorage.layout().signerState[signer] = SIGNER_USED;

        emit SignerUsed(signer);
        _processClaim(claimant, data);
    }

    function claimThroughRelay(address claimant, address signer, uint64 deadline, bytes calldata data, bytes calldata signature, bytes calldata certificate) 
        external onlyGelatoRelay {

        if (!ClaimableBaseStorage.layout().gelatoRelayEnabled) revert GelatoRelayNotEnabled();
        
        _beforeTransferRelayFee(claimant, data);
        _transferRelayFee();

        claim(claimant, signer, deadline, data, signature, certificate);
    }


    function _processClaim(address claimant, bytes calldata data) internal virtual;


    function _beforeTransferRelayFee(address claimant, bytes calldata data) internal virtual {}


    function signerState(address signer) public view returns (uint256) {
        return ClaimableBaseStorage.layout().signerState[signer];
    }

    function getCertificateAuthority() public virtual view returns (address) {
        return ClaimableBaseStorage.layout().defaultCertificateAuthority;
    }

    function _setDefaultCertificateAuthority(address certificateAuthority_) internal {
        if(certificateAuthority_ == address(0)) revert ZeroAddress();
        ClaimableBaseStorage.layout().defaultCertificateAuthority = certificateAuthority_;
    }

    function gelatoRelayEnabled() public view returns(bool){
        return ClaimableBaseStorage.layout().gelatoRelayEnabled;
    }
    

    function _verifyCertificate(address signer,  uint64 deadline, bytes memory data, bytes memory certificate) internal view returns (bytes32) {
        bytes32 certificateHash = ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encodePacked(
            signer, deadline,
            address(this), block.chainid,
            data
        )));

        if(deadline < block.timestamp) revert InvalidCertificate();
        if(ECDSAUpgradeable.recover(certificateHash, certificate) != getCertificateAuthority()) revert InvalidCertificate();
    
        return certificateHash;
    }

    function _verySignature(address claimant, bytes32 certificateHash, address signer, bytes calldata signature) internal pure {

        bytes32 signautureHash = ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encodePacked(
            claimant, certificateHash
        )));

        if(ECDSAUpgradeable.recover(signautureHash, signature) != signer) revert InvalidSignature();
    }

    function _revoke(address signer) internal {
        ClaimableBaseStorage.layout().signerState[signer] = SIGNER_REVOKED;
        emit SignerRevoked(signer);
    }
}