// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "./ClaimableCore.sol";

contract Claimable721 is ClaimableCore, ERC721AUpgradeable {

    function initialize(
        string calldata name_,
        string calldata symbol_,
        bool gelatoRelayEnabled_,
        address certificateAuthority_
    ) initializerERC721A initializer public {
        __ClaimableCore_init(
            gelatoRelayEnabled_,
            certificateAuthority_
        );

        __ERC721A_init(name_, symbol_);
        __Ownable_init();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return "ipfs://";
    }

    function _processClaim(address claimant, bytes calldata data) internal override {
        _mint(claimant, 1);
    } 

}