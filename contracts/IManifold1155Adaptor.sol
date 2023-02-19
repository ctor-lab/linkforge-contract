// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface IManifold1155Adaptor {
    function initialize(
        address creator_,
        bool gelatoRelayEnabled_,
        address certificateAuthority_,
        address factory
    ) external;
}