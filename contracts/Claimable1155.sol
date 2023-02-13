// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ClaimableCore.sol";



contract Claimable1155 is ClaimableCore, ERC1155Upgradeable {
    function initialize() initializer external {
        __ERC1155_init("");
    }

    function _max_mint_gasusage() internal virtual returns(uint256) {
        return 50000;
    }


    function _processClaim(address claimant, bytes calldata data) internal virtual override {
        (uint256 id) = abi.decode(
            data,
            (uint256)
        );
        uint256 beforeGas = gasleft();
        _mint(claimant, id, 1, "");
        uint256 afterGas = gasleft();

        if (_isGelatoRelay(msg.sender)) {
            // By capping the gas usage for the mint, this prevents the griefing attack by using a smart contact as the clamant.
            if (beforeGas - afterGas > _max_mint_gasusage()) revert();
        }
    } 


}