// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface IFactory {
    function getFeeRelayed(address token) external view returns (uint256);
    function getFeeSelfClaimed() external view returns(uint256);
    function authorizeUpgrade(address newImplementation) external view;
    function authorizeUpgrade721Edition(address newImplementation) external view;
}