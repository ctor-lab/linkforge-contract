// SPDX-License-Identifier: MIT
// Modified from Openzeppelin contracts

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";



abstract contract ERC2981 is IERC165, IERC2981 {
    struct ERC2981Layout {
        address receiver;
        uint96 feeNumerator;
    }

    bytes32 private constant STORAGE_SLOT = keccak256('CtorLab.contracts.storage.ERC2981');

    error ExceedSalePrice();
    error InvalidReceiver();


    function layout() private pure returns (ERC2981Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || 
            interfaceId == type(IERC165).interfaceId;
    }

    /**
    * @dev Sets the royalty information that applies to all ids in this contract.
    *
    * Requirements:
    *
    * - `receiver` cannot be the zero address.
    * - `feeNumerator` cannot be greater than the fee denominator.
    */
    function _setRoyalty(address receiver_, uint96 feeNumerator_) internal virtual {
        if (feeNumerator_ > _feeDenominator()) revert ExceedSalePrice();
        if (receiver_ == address(0)) revert InvalidReceiver();

        layout().receiver = receiver_;
        layout().feeNumerator = feeNumerator_;
    }

    /**
     * @dev For drop-in replacement of Openzeppelin's ERC2981 implemenatation.
     */
    function _setDefaultRoyalty(address receiver_, uint96 feeNumerator_) internal virtual {
        _setRoyalty(receiver_, feeNumerator_);
    }

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        _tokenId; // Disable warning
        uint256 royaltyAmount = (_salePrice * layout().feeNumerator) / _feeDenominator();
        return (layout().receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

}