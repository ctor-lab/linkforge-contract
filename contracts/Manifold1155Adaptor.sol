// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {NATIVE_TOKEN} from  "@gelatonetwork/relay-context/contracts/constants/Tokens.sol";

import "./ClaimableCore.sol";

import "./IFactory.sol";

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";

import "./IManifold1155Adaptor.sol";

contract Manifold1155Adaptor is IManifold1155Adaptor, ClaimableCore {
 
    address public creator;

    mapping(uint256 => string) private _uri;

    error NotCreator1155();

    function initialize(
        address creator_,
        bool gelatoRelayEnabled_,
        address certificateAuthority_,
        address factory_
    ) initializer external {
        __ClaimableCore_init(gelatoRelayEnabled_, certificateAuthority_, factory_);
        
        
        if(!IERC165(creator_).supportsInterface(type(IERC1155CreatorCore).interfaceId)) {
            revert NotCreator1155();
        }

        creator = creator_;
        
    }

    function toggleGelatoRelay() external onlyOwner {
        gelatoRelayEnabled = !gelatoRelayEnabled;
    }

    function _max_mint_gasusage() internal virtual returns(uint256) {
        return 100000;
    }


    function _processClaim(address claimant, bytes calldata data) internal virtual override {
        (uint256 id, uint256 amount) = abi.decode(
            data,
            (uint256, uint256)
        );

        address[] memory to = new address[](1);
        to[0] = claimant;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = id;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        uint256 beforeGas = gasleft();

        IERC1155CreatorCore(creator).mintExtensionExisting(
            to, tokenIds, amounts
        );

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