// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "./Claimable.sol";

contract ClaimableNFT is OwnableUpgradeable, Claimable, ERC721AUpgradeable {

    constructor() {
        _disableInitializers();
    }

    function initialize(
        bool gelatoRelayEnabled_,
        string calldata name_,
        string calldata symbol_
    ) initializerERC721A initializer public {
        gelatoRelayEnabled = gelatoRelayEnabled_;
        __ERC721A_init(name_, symbol_);
        __Ownable_init();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return "ipfs://";
    }

    function setCertificateAuthority(address certificateAuthority_) external onlyOwner {
        _setDefaultCertificateAuthority(certificateAuthority_);
    }

    function _processClaim(address claimant, bytes calldata data) internal override {
        _mint(claimant, 1);
    } 

    receive() external payable {}

    function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
        token.transferFrom(address(this), msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

}