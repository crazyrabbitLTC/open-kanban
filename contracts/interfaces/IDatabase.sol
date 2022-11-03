// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

interface IDatabase {
    function listExists() external view returns (bool);

    function initialize(address dbController) external;

    function nodeExists(uint256 _node) external view returns (bool);

    function sizeOf() external view returns (uint256);

    function getNode(uint256 _node)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function getAdjacent(uint256 _node, bool _direction) external view returns (bool, uint256);

    function getNextNode(uint256 _node) external view returns (bool, uint256);

    function getPreviousNode(uint256 _node) external view returns (bool, uint256);

    function getSortedSpot(address _structure, uint256 _value) external view returns (uint256);

    function insertAfter(uint256 _node, uint256 _new) external returns (bool);

    function insertBefore(uint256 _node, uint256 _new) external returns (bool);

    function remove(uint256 _node) external returns (uint256);

    function pushFront(uint256 _node) external returns (bool);

    function pushBack(uint256 _node) external returns (bool);

    function popFront() external returns (uint256);

    function popBack() external returns (uint256);
}
