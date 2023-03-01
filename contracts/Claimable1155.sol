// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {NATIVE_TOKEN} from  "@gelatonetwork/relay-context/contracts/constants/Tokens.sol";

import "./ClaimableCore.sol";

import "./interfaces/IFactory.sol";
import "./interfaces/IClaimable1155.sol";

import "closedsea/src/OperatorFilterer.sol";
import "ctorlab-solidity/contracts/token/ERC2981Lite/ERC2981LiteUpgradeable.sol";

library Claimable1155Storage {
    bytes32 internal constant STORAGE_SLOT = keccak256('CtorLab.contracts.storage.Claimable1155');

    struct Layout {
        address factory;
        string name;
        string symbol;
        string defaultURI;
        mapping(uint256 => string) uri;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

contract Claimable1155 is ClaimableCore, ERC1155Upgradeable, IClaimable1155, OperatorFilterer, ERC2981LiteUpgradeable, UUPSUpgradeable {
    
    function initialize(
        string calldata name_,
        string calldata symbol_,
        bool gelatoRelayEnabled_,
        address certificateAuthority_,
        address factory_
    ) initializer external {
        __ERC1155_init("");
        Claimable1155Storage.layout().name = name_;
        Claimable1155Storage.layout().symbol = symbol_;
        Claimable1155Storage.layout().factory = factory_;

        __ClaimableCore_init(gelatoRelayEnabled_, certificateAuthority_);
        _registerForOperatorFiltering();
    }

    function name() public view returns (string memory) {
        return Claimable1155Storage.layout().name;
    }

    function symbol() public view returns (string memory) {
        return Claimable1155Storage.layout().symbol;
    }

    function version() public pure returns (uint256) {
        return 1;
    }

    function factory() public view returns (address) {
        return Claimable1155Storage.layout().factory;
    }

    function devMint(address to, uint256 id, uint256 amount) external onlyOwner {
        _mint(to, id, amount, "");
    }

    function setRoyalty(address receiver_, uint96 feeNumerator_) external onlyOwner {
        _setRoyalty(receiver_, feeNumerator_);
    }

    function _max_mint_gasusage() internal virtual returns(uint256) {
        return 50000;
    }

    function uri(uint256 id) public view override returns(string memory) {
        if(bytes(Claimable1155Storage.layout().uri[id]).length > 0) {
            return Claimable1155Storage.layout().uri[id];
        }
        return Claimable1155Storage.layout().defaultURI;
    }

    function setUri(uint256 id, string calldata uri_) external onlyOwner {
        Claimable1155Storage.layout().uri[id] = uri_;
        emit URI(uri_, id);
    }

    function setDefaultUri(string calldata defaultURI_) external onlyOwner {
        Claimable1155Storage.layout().defaultURI = defaultURI_;
    }

    function _processClaim(address claimant, bytes calldata data) internal virtual override {
        (uint256 id, uint256 amount) = abi.decode(
            data,
            (uint256, uint256)
        );
        uint256 beforeGas = gasleft();
        _mint(claimant, id, amount, "");
        uint256 afterGas = gasleft();

        address factory_ = factory();
        if (_isGelatoRelay(msg.sender)) {
            // By capping the gas usage for the mint, this prevents the griefing attack by using a smart contact as the clamant.
            if (beforeGas - afterGas > _max_mint_gasusage()) revert();

            address token = _getFeeToken();

            uint256 fee = 0;
            
            if(factory_ != address(0)) {
                IFactory(factory_).getFeeRelayed(token);

                if(fee > 0) {
                    if(token == NATIVE_TOKEN) {
                        payable(factory_).transfer(fee);
                    } else {
                        IERC20(token).transfer(factory_, fee);
                    }
                }
            }
        } else {
            require(msg.value == IFactory(factory_).getFeeSelfClaimed());
            payable(factory_).transfer(msg.value);
        }
    } 

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981LiteUpgradeable, ERC1155Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // UUPS

    function _authorizeUpgrade(address newImplementation) internal override view onlyOwner {
        IFactory(factory()).authorizeUpgrade(newImplementation);
    }
}