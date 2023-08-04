// SPDX-License-Identifier: MIT
// Author: Ctor Lab

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {NATIVE_TOKEN} from  "@gelatonetwork/relay-context/contracts/constants/Tokens.sol";
import "solady/src/tokens/ERC721.sol";
import "solady/src/tokens/ERC2981.sol";
import "closedsea/src/OperatorFilterer.sol";


import "./LinkForgeCore.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/ILinkForge721Edition.sol";


library LinkForge721EditionStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256('CtorLab.contracts.storage.LinkForge721EditionStorage');

    struct Layout {
        address factory;
        string name;
        string symbol;
        string defaultURI;
        mapping(uint256 => string) editionURI;
        mapping(uint256 => uint256) editionCounter;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}


contract LinkForge721Edition is LinkForgeCore, ERC721, ILinkForge721Edition, ERC2981, OperatorFilterer, UUPSUpgradeable {
    uint256 constant TOKEN_ID_SEPARATOR = 1_000_000;

    uint256 constant _ROLE_MINTER =  _ROLE_0;
    uint256 constant _ROLE_URL_SETTER =  _ROLE_1;
    uint256 constant _ROLE_ROYALTY_SETTER = _ROLE_2;

    event URI(string value, uint256 indexed id);
    event Claimed(address recepiant, uint256 edition, uint256 amount, address token, uint256 fee);
    

    constructor() initializerERC721A {}
    
    function initialize(
        string calldata name_,
        string calldata symbol_,
        bool gelatoRelayEnabled_,
        address certificateAuthority_,
        address factory_
    ) initializerERC721A external { 
        // Use ERC721A's initializer since it uses unstructured storage

        LinkForge721EditionStorage.layout().name = name_;
        LinkForge721EditionStorage.layout().symbol = symbol_;
        LinkForge721EditionStorage.layout().factory = factory_;

        __LinkForgeCore_init(gelatoRelayEnabled_, certificateAuthority_);
        _registerForOperatorFiltering();
    }

    function _mintEdition(address to, uint256 edition, uint256 amount) internal {
        uint256 minted = LinkForge721EditionStorage.layout().editionCounter[edition];
        require(minted + amount <=  TOKEN_ID_SEPARATOR);
        uint256 start = TOKEN_ID_SEPARATOR * edition + minted;
        for(uint256 i = 0; i < amount; ++i) {
            uint256 tokenId = start + i;
            _mint(to, tokenId);
        }

        LinkForge721EditionStorage.layout().editionCounter[edition] += amount;
    }

    function name() public view override returns (string memory) {
        return LinkForge721EditionStorage.layout().name;
    }

    function symbol() public view override returns (string memory) {
        return LinkForge721EditionStorage.layout().symbol;
    }

    function version() public pure returns (uint256) {
        return 1;
    }

    function factory() public view returns (address) {
        return LinkForge721EditionStorage.layout().factory;
    }

    function devMint(address to, uint256 edition, uint256 amount) external onlyRolesOrOwner(_ROLE_MINTER) {
        _mintEdition(to, edition, amount);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint256 edition = tokenId / TOKEN_ID_SEPARATOR;


        if(bytes(LinkForge721EditionStorage.layout().editionURI[edition]).length > 0) {
            return LinkForge721EditionStorage.layout().editionURI[edition];
        }
        return LinkForge721EditionStorage.layout().defaultURI;
    }

    function setUri(uint256 edition, string calldata uri_) external payable onlyRolesOrOwner(_ROLE_URL_SETTER) {
        LinkForge721EditionStorage.layout().editionURI[edition] = uri_;
        emit URI(uri_, edition);
        
        if(msg.value > 0) {
            payable(factory()).transfer(msg.value);
        }
    }

    function uri(uint256 edition) public view returns(string memory) {
        if(bytes(LinkForge721EditionStorage.layout().editionURI[edition]).length > 0) {
            return LinkForge721EditionStorage.layout().editionURI[edition];
        }
        return LinkForge721EditionStorage.layout().defaultURI;
    }

    function defautURI() public view returns(string memory) {
        return LinkForge721EditionStorage.layout().defaultURI;
    }

    function setDefaultUri(string calldata defaultURI_) external onlyRolesOrOwner(_ROLE_URL_SETTER) {
        LinkForge721EditionStorage.layout().defaultURI = defaultURI_;
    }

    function _processClaim(address recepiant, bytes calldata data) internal virtual override {
        (uint256 edition, uint256 amount) = abi.decode(
            data,
            (uint256, uint256)
        );

        _mintEdition(recepiant, edition, amount);
    
        address factory_ = factory();
        address token = address(0);
        uint256 fee = 0;

        if (_isGelatoRelay(msg.sender)) {
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

            emit Claimed(recepiant, edition, amount, token, fee + _getFee());
        } else {
            require(msg.value == IFactory(factory_).getFeeSelfClaimed());
            fee = msg.value;
            payable(factory_).transfer(msg.value);
            emit Claimed(recepiant, edition, amount, address(0), 0);
        }        
    } 


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721) returns (bool) {
        return ERC2981.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId);
    }

    // UUPS

    function _authorizeUpgrade(address newImplementation) internal override view onlyOwner {
        IFactory(factory()).authorizeUpgrade721Edition(newImplementation);
    }

    // ERC2981

    function setRoyalty(address receiver_, uint96 feeNumerator_) external onlyOwnerOrRoles(_ROLE_ROYALTY_SETTER) {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

}
 
