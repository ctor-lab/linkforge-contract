// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

abstract contract Claimable {
    address private defaultCertificateAuthority;
    mapping(address => bool) private usedSigner;

    error UsedSigner();
    error ZeroAddress();
    error InvalidCertificate();
    error InvalidSignature();

    function claim(address claimant, address signer, uint64 deadline, bytes calldata data, bytes calldata signature, bytes calldata certificate) public {
        bytes32 certificateHash = _verifyCertificate(signer, deadline, data, certificate);
        _verySignature(claimant, certificateHash, signer, signature);

        if(usedSigner[signer]) revert UsedSigner();

        usedSigner[signer] = true;

        _processClaim(claimant, data);
    }

    function _processClaim(address claimant, bytes calldata data) internal virtual;

    function isUsedSigner(address signer) public view returns (bool) {
        return usedSigner[signer];
    }

    function getCertificateAuthority() public virtual view returns (address) {
        return defaultCertificateAuthority;
    }

    function _setDefaultCertificateAuthority(address certificateAuthority_) internal {
        if(certificateAuthority_ == address(0)) revert ZeroAddress();
        defaultCertificateAuthority = certificateAuthority_;
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
}