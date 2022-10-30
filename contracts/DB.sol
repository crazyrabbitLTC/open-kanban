// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "solidity-linked-list/contracts/StructuredLinkedList.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract DB is Initializable, AccessControlEnumerableUpgradeable, UUPSUpgradeable {
    using StructuredLinkedList for StructuredLinkedList.List;

    StructuredLinkedList.List public list;

    // errors
    error AccessError();

    // Create a new role identifier for the Database controller role
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DB_CONTROLLER = keccak256("DB_CONTROLLER");

    // events
    event DbInsertAfter(uint256 _node, uint256 _new);
    event DbInsertBefore(uint256 _node, uint256 _new);
    event DbRemove(uint256 _node);
    event DbPushFront(uint256 _new);
    event DbPushBach(uint256 _new);
    event DbPopFront(uint256 _node);
    event DbPopBack(uint256 _node);

    // modifiers
    modifier onlyDBController() {
        if (!hasRole(DB_CONTROLLER, msg.sender)) {
            revert AccessError();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DB_CONTROLLER, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    // TODO: implement this
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {
        // TODO: Who can do it? When? How?
    }

    // function listExists(List storage self) internal view returns (bool);
    function listExists() public view returns (bool) {
        return list.listExists();
    }

    // function nodeExists(List storage self, uint256 _node) internal view returns (bool);
    function nodeExists(uint256 _node) public view returns (bool) {
        return list.nodeExists(_node);
    }

    // function sizeOf(List storage self) internal view returns (uint256);
    function sizeOf() public view returns (uint256) {
        return list.sizeOf();
    }

    // function getNode(List storage self, uint256 _node) internal view returns (bool, uint256, uint256);
    function getNode(uint256 _node)
        public
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return list.getNode(_node);
    }

    // function getAdjacent(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256);
    function getAdjacent(uint256 _node, bool _direction) public view returns (bool, uint256) {
        return list.getAdjacent(_node, _direction);
    }

    // function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256);
    function getNextNode(uint256 _node) public view returns (bool, uint256) {
        return list.getNextNode(_node);
    }

    // function getPreviousNode(List storage self, uint256 _node) internal view returns (bool, uint256);
    function getPreviousNode(uint256 _node) public view returns (bool, uint256) {
        return list.getPreviousNode(_node);
    }

    // function getSortedSpot(List storage self, address _structure, uint256 _value) internal view returns (uint256);
    function getSortedSpot(address _structure, uint256 _value) public view returns (uint256) {
        return list.getSortedSpot(_structure, _value);
    }

    // function insertAfter(List storage self, uint256 _node, uint256 _new) internal returns (bool);
    function insertAfter(uint256 _node, uint256 _new) public onlyDBController returns (bool) {
        bool result = list.insertAfter(_node, _new);
        emit DbInsertAfter(_node, _new);
        return result;
    }

    // function insertBefore(List storage self, uint256 _node, uint256 _new) internal returns (bool);
    function insertBefore(uint256 _node, uint256 _new) public onlyDBController returns (bool) {
        bool result = list.insertBefore(_node, _new);
        emit DbInsertBefore(_node, _new);
        return result;
    }

    // function remove(List storage self, uint256 _node) internal returns (uint256);
    function remove(uint256 _node) public onlyDBController returns (uint256) {
        uint256 node = list.remove(_node);
        emit DbRemove(node);
        return node;
    }

    // function pushFront(List storage self, uint256 _node) internal returns (bool);
    function pushFront(uint256 _node) public onlyDBController returns (bool) {
        bool result = list.pushFront(_node);
        emit DbPushFront(_node);
        return result;
    }

    // function pushBack(List storage self, uint256 _node) internal returns (bool);
    function pushBack(uint256 _node) public onlyDBController returns (bool) {
        bool result = list.pushBack(_node);
        emit DbPushBach(_node);
        return result;
    }

    // function popFront(List storage self) internal returns (uint256);
    function popFront() public onlyDBController returns (uint256) {
        uint256 node = list.popFront();
        emit DbPopFront(node);
        return node;
    }

    // function popBack(List storage self) internal returns (uint256);
    function popBack() public onlyDBController returns (uint256) {
        uint256 node = list.popBack();
        emit DbPopBack(node);
        return node;
    }
}

// interface
// function listExists(List storage self) internal view returns (bool);
// function nodeExists(List storage self, uint256 _node) internal view returns (bool);
// function sizeOf(List storage self) internal view returns (uint256);
// function getNode(List storage self, uint256 _node) internal view returns (bool, uint256, uint256);
// function getAdjacent(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256);
// function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256);
// function getPreviousNode(List storage self, uint256 _node) internal view returns (bool, uint256);
// function getSortedSpot(List storage self, address _structure, uint256 _value) internal view returns (uint256);
// function insertAfter(List storage self, uint256 _node, uint256 _new) internal returns (bool);
// function insertBefore(List storage self, uint256 _node, uint256 _new) internal returns (bool);
// function remove(List storage self, uint256 _node) internal returns (uint256);
// function pushFront(List storage self, uint256 _node) internal returns (bool);
// function pushBack(List storage self, uint256 _node) internal returns (bool);
// function popFront(List storage self) internal returns (uint256);
// function popBack(List storage self) internal returns (uint256);
