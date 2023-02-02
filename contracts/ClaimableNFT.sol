// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "erc721a/contracts/ERC721A.sol";
import "./Claimable.sol";

contract ClaimableNFT is Ownable, Claimable, ERC721A {

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return "ipfs://";
    }

    function setCertificateAuthority(address certificateAuthority_) external onlyOwner {
        _setDefaultCertificateAuthority(certificateAuthority_);
    }

    function _processClaim(address claimant, bytes calldata data) internal override {
        _mint(claimant, 1);
    } 

}