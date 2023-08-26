// SPDX-License-Identifier: BUSL-1.1
// Author: Ctor Lab

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {GelatoRelayContext} from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";


int256 constant SIGNER_AVAILABLE = 0;
int256 constant SIGNER_USED = 1;
int256 constant SIGNER_REVOKED = 2;
int256 constant SIGNER_UNLIMITED = type(int256).min;


library LinkForgePlusStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256('CtorLab.storage.contracts.LinkForgePlus');

    struct SignerInfo {
        uint64 lastUsed;
        uint32 counter;
    }

    struct Layout {
        bool gelatoRelayEnabled;
        uint64 relayCoolDown;
        mapping(address => SignerInfo) signerInfo;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

abstract contract LinkForgePlus is GelatoRelayContext{

    error InvalidSigner();
    error ZeroAddress();
    error InvalidCertificate();
    error InvalidSignature();
    error GelatoRelayNotEnabled();
    error OutdatedBlockNumber();
    error UnderCoolDownPeriod();

    event SignerRevoked(address indexed signer);
    event SignerUsed(address indexed signer);

    function maxPastBlockNumber() pure virtual internal returns(uint256) {
        return 200;
    }

    function claim(
        uint256 blockNumber, 
        address signer, 
        bytes calldata data, 
        bytes calldata signature
    ) public payable {

        if( _isGelatoRelay(msg.sender)) {
            if (!LinkForgePlusStorage.layout().gelatoRelayEnabled) revert GelatoRelayNotEnabled();

            if(LinkForgePlusStorage.layout().relayCoolDown > block.timestamp -  
                LinkForgePlusStorage.layout().signerInfo[signer].lastUsed) {

                revert UnderCoolDownPeriod();
            }

            _transferRelayFee();
        }


        if(block.number - blockNumber > maxPastBlockNumber() ) {
            revert OutdatedBlockNumber();
        }

        bytes32 message = ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encodePacked(
            signer, blockhash(blockNumber),
            address(this), block.chainid,
            data
        )));

        if(ECDSAUpgradeable.recover(message, signature) != signer) {
            revert InvalidSignature();
        }

        _processClaim(signer, data);
    }

    function _processClaim(address signer, bytes calldata data) internal virtual;

    function gelatoRelayEnabled() public view returns(bool){
        return LinkForgePlusStorage.layout().gelatoRelayEnabled;
    }
}


import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solady/src/auth/OwnableRoles.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/tokens/ERC721.sol";

import "erc721a-upgradeable/contracts/ERC721A__Initializable.sol";


library LinkForgePlus721AStorage {
    
    bytes32 internal constant STORAGE_SLOT = keccak256('CtorLab.storage.contracts.LinkForgePlus721A');


    struct Layout {
        string name;
        string symbol;
        string defaultURI;
        mapping(uint256 => address) tokenSigner;
        mapping(uint256 => uint256) edition;
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


abstract contract LinkForgePlus721PBT is LinkForgePlus, OwnableRoles, ERC721A__Initializable, ERC721, UUPSUpgradeable {
    event URI(string value, uint256 indexed id);
    event TokenConfigured(uint256 indexed id, address signer, uint256 edition);

    error TokenAlreadyConfigured();

    uint256 constant TOKEN_ID_SEPARATOR = 1_000_000;

    uint256 constant _ROLE_MINTER =  _ROLE_0;
    uint256 constant _ROLE_URL_SETTER =  _ROLE_1;
    //uint256 constant _ROLE_ROYALTY_SETTER = _ROLE_2;


    constructor() initializerERC721A {}

    function initialize(
        bool gelatoRelayEnabled_,
        string calldata name_,
        string calldata symbol_
    ) internal initializerERC721A {
        LinkForgePlusStorage.layout().gelatoRelayEnabled = gelatoRelayEnabled_;
        _initializeOwner(msg.sender);
        layout().name = name_;
        layout().symbol = symbol_;
    }

    function layout() private pure returns(LinkForgePlus721AStorage.Layout storage) {
        return LinkForgePlus721AStorage.layout();
    }

    function name() public view override returns (string memory) {
        return layout().name;
    }

    function symbol() public view override returns (string memory) {
        return layout().symbol;
    }

    function version() public pure returns (uint256) {
        return 1;
    }


    function _processClaim(address signer, bytes calldata data) internal override {
        (uint256 tokenId, address to) = abi.decode(
            data,
            (uint256, address)
        );
        if(layout().tokenSigner[tokenId] != signer) revert InvalidSigner();
        
        if(_exists(tokenId)) {
            _transfer(ownerOf(tokenId), to, tokenId);
        } else {
            _mint(to, tokenId);
        }
    }


    function addTokens(
        bool mint,
        uint256 edition,
        address[] calldata signers
    ) external onlyOwnerOrRoles(_ROLE_MINTER) {
        uint256 amount = signers.length;
        uint256 added = layout().editionCounter[edition];
        require(added + amount <=  TOKEN_ID_SEPARATOR);
        uint256 start = TOKEN_ID_SEPARATOR * edition + added;

        for(uint256 i = 0; i < amount; ++i) {
            uint256 tokenId = start + i;
            address signer = signers[i];
            layout().tokenSigner[tokenId] = signer;

            if(mint) {
                _mint(address(this), tokenId);
            }

            emit TokenConfigured(tokenId, signer, edition);
        }
    }

    function setUri(uint256 edition, string calldata uri_) external payable onlyRolesOrOwner(_ROLE_URL_SETTER) {
        layout().editionURI[edition] = uri_;
        emit URI(uri_, edition);
    }

    function uri(uint256 edition) public view returns(string memory) {
        if(bytes(layout().editionURI[edition]).length > 0) {
            return layout().editionURI[edition];
        }
        return "";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint256 edition = layout().edition[tokenId];

        if(bytes(layout().editionURI[edition]).length > 0) {
            return layout().editionURI[edition];
        }
        return string(abi.encodePacked(
            layout().defaultURI, 
            LibString.toString(tokenId)
        ));
    }


    receive() external payable {}

    function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
        token.transfer(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    // UUPS

    function _authorizeUpgrade(address newImplementation) internal override view onlyOwner {
        //IFactory(factory()).authorizeUpgrade721Edition(newImplementation);
    }


    function safeTransferFrom(address, address, uint256, bytes calldata) public payable override {
        revert();
    }


    function safeTransferFrom(address, address, uint256) public payable override {
        revert();
    }

    function transferFrom(address, address, uint256) public payable override {
        revert();
    }

    function approve(address, uint256) public payable override {
        revert();
    }

    function setApprovalForAll(address, bool) public pure override {
        revert();
    }

    function getApproved(uint256) public pure override returns (address){
        return address(0);
    }

    function isApprovedForAll(address, address) public pure override returns (bool){
        return false;
    }
}