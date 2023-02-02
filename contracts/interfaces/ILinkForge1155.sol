// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface ILinkForge1155 {
    function initialize(
        string calldata name_,
        string calldata symbol_,
        bool gelatoRelayEnabled_,
        address certificateAuthority_,
        address factory
    ) external;
}