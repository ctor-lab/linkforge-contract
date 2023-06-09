// SPDX-License-Identifier: MIT
// Author: Ctor Lab

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {NATIVE_TOKEN} from  "@gelatonetwork/relay-context/contracts/constants/Tokens.sol";
import "solady/src/tokens/ERC1155.sol";
import "solady/src/tokens/ERC2981.sol";
import "closedsea/src/OperatorFilterer.sol";


import "./LinkForgeCore.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/ILinkForge1155.sol";



library LinkForge1155Storage {
    bytes32 internal constant STORAGE_SLOT = keccak256('CtorLab.contracts.storage.LinkForge1155');

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

contract LinkForge1155 is LinkForgeCore, ERC1155, ILinkForge1155, ERC2981, OperatorFilterer, UUPSUpgradeable {
    
    uint256 constant _ROLE_MINTER =  _ROLE_0;
    uint256 constant _ROLE_URL_SETTER =  _ROLE_1;
    uint256 constant _ROLE_ROYALTY_SETTER = _ROLE_2;


    event Claimed(address recepiant, uint256 tokenId, uint256 amount, address token, uint256 fee);

    constructor() initializerERC721A {}

    function initialize(
        string calldata name_,
        string calldata symbol_,
        bool gelatoRelayEnabled_,
        address certificateAuthority_,
        address factory_
    ) initializerERC721A external { 
        // Use ERC721A's initializer since it uses unstructured storage

        LinkForge1155Storage.layout().name = name_;
        LinkForge1155Storage.layout().symbol = symbol_;
        LinkForge1155Storage.layout().factory = factory_;

        __LinkForgeCore_init(gelatoRelayEnabled_, certificateAuthority_);
        _registerForOperatorFiltering();
    }

    function name() public view returns (string memory) {
        return LinkForge1155Storage.layout().name;
    }

    function symbol() public view returns (string memory) {
        return LinkForge1155Storage.layout().symbol;
    }

    function version() public pure returns (uint256) {
        return 1;
    }

    function factory() public view returns (address) {
        return LinkForge1155Storage.layout().factory;
    }

    function devMint(address to, uint256 id, uint256 amount) external onlyRolesOrOwner(_ROLE_MINTER) {
        _mint(to, id, amount, "");
    }

    function _max_mint_gasusage() internal virtual returns(uint256) {
        return 50000;
    }

    function uri(uint256 id) public view override returns(string memory) {
        if(bytes(LinkForge1155Storage.layout().uri[id]).length > 0) {
            return LinkForge1155Storage.layout().uri[id];
        }
        return LinkForge1155Storage.layout().defaultURI;
    }

    function setUri(uint256 id, string calldata uri_) external payable onlyRolesOrOwner(_ROLE_URL_SETTER) {
        LinkForge1155Storage.layout().uri[id] = uri_;
        emit URI(uri_, id);
        
        if(msg.value > 0) {
            payable(factory()).transfer(msg.value);
        }
    }

    function defautURI() public view returns(string memory) {
        return LinkForge1155Storage.layout().defaultURI;
    }

    function setDefaultUri(string calldata defaultURI_) external onlyRolesOrOwner(_ROLE_URL_SETTER) {
        LinkForge1155Storage.layout().defaultURI = defaultURI_;
    }

    function _processClaim(address recepiant, bytes calldata data) internal virtual override {
        (uint256 id, uint256 amount) = abi.decode(
            data,
            (uint256, uint256)
        );
        uint256 beforeGas = gasleft();
        _mint(recepiant, id, amount, "");
        uint256 afterGas = gasleft();

        address factory_ = factory();
        address token = address(0);
        uint256 fee = 0;

        if (_isGelatoRelay(msg.sender)) {
            // By capping the gas usage for the mint, this prevents the griefing attack by using a smart contact as the clamant.
            if (beforeGas - afterGas > _max_mint_gasusage()) revert();

            token = _getFeeToken();
            
            if(factory_ != address(0)) {
                // protocol fee
                fee = IFactory(factory_).getFeeRelayed(token);

                if(fee > 0) {
                    if(token == NATIVE_TOKEN) {
                        payable(factory_).transfer(fee);
                    } else {
                        IERC20(token).transfer(factory_, fee);
                    }
                }
            }

            emit Claimed(recepiant, id, amount, token, fee + _getFee());
        } else {
            require(msg.value == IFactory(factory_).getFeeSelfClaimed());
            fee = msg.value;
            payable(factory_).transfer(msg.value);
            emit Claimed(recepiant, id, amount, address(0), 0);
        }        
    } 

    // Operator filter

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC1155) returns (bool) {
        return ERC2981.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId);
    }

    // UUPS

    function _authorizeUpgrade(address newImplementation) internal override view onlyOwner {
        IFactory(factory()).authorizeUpgrade(newImplementation);
    }

    // ERC2981

    function setRoyalty(address receiver_, uint96 feeNumerator_) external onlyOwnerOrRoles(_ROLE_ROYALTY_SETTER) {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }
}