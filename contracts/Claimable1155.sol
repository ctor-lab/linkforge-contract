// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {NATIVE_TOKEN} from  "@gelatonetwork/relay-context/contracts/constants/Tokens.sol";

import "./ClaimableCore.sol";

import "./IFactory.sol";


contract Claimable1155 is ClaimableCore, ERC1155Upgradeable {
 
    string public name;
    string public symbol;

    mapping(uint256 => string) private _uri;

    function initialize(
        string calldata name_,
        string calldata symbol_,
        bool gelatoRelayEnabled_,
        address certificateAuthority_,
        address factory_
    ) initializer external {
        __ERC1155_init("");
        name = name_;
        symbol = symbol_;

        __ClaimableCore_init(gelatoRelayEnabled_, certificateAuthority_, factory_);
        
    }

    function toggleGelatoRelay() external onlyOwner {
        gelatoRelayEnabled = !gelatoRelayEnabled;
    }

    function _max_mint_gasusage() internal virtual returns(uint256) {
        return 50000;
    }

    function uri(uint256 id) public view override returns(string memory) {
        return _uri[id];
    }

    function setUri(uint256 id, string calldata uri_) external onlyOwner {
        _uri[id] = uri_;
        emit URI(uri_, id);
    }

    function _processClaim(address claimant, bytes calldata data) internal virtual override {
        (uint256 id, uint256 amount) = abi.decode(
            data,
            (uint256, uint256)
        );
        uint256 beforeGas = gasleft();
        _mint(claimant, id, amount, "");
        uint256 afterGas = gasleft();

        if (_isGelatoRelay(msg.sender)) {
            // By capping the gas usage for the mint, this prevents the griefing attack by using a smart contact as the clamant.
            if (beforeGas - afterGas > _max_mint_gasusage()) revert();

            address token = _getFeeToken();

            uint256 fee = IFactory(factory).getFee(token);

            if(fee > 0) {
                if(token == NATIVE_TOKEN) {
                    payable(factory).transfer(fee);
                } else {
                    IERC20(token).transfer(factory, fee);
                }
            }
        } 
    } 
}