// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface IFactory {
    function getFee(address token) external view returns (uint256);
}