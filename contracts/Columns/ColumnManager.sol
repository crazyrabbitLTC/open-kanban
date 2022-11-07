// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "../interfaces/Interfaces.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract ColumnManager is DataStructures, Events {
    uint256 internal columnCount;
    bool internal columnsInitialized;

    mapping(address => Column) internal columnById;
    mapping(string => address) internal columnIdByName;
    mapping(uint256 => address) internal columnIdByIndex;

    function _setupColumns(Column[] memory _columns, IDatabase dbImplementation) internal {
        // allow to happen only once
        if (columnsInitialized) {
            revert ColumnsAlreadyInitialized();
        }

        for (uint256 i = 0; i < _columns.length; i++) {
            // Check if Colmun is Valid

            // create the database for the column
            address id = Clones.clone(address(dbImplementation));
            IDatabase(id).initialize(address(this));

            // create a new column object
            Column memory col = _columns[i];
            // add database to the column object
            col.database = IDatabase(id);
            // Start Column fresh
            col.ticketCount = 0;

            // Setup Column Relations
            columnById[id] = col;
            columnIdByName[col.name] = id;
            columnIdByIndex[i] = id;

            emit ColumnCreated(col.name, col.uri, address(col.database), col.data);

            // lock columns
            columnsInitialized = true;
        }

        // set number of columns
        columnCount = _columns.length;
    }

    // external setters

    // external getters
    function getColumnByName(string memory name) external view returns (Column memory) {
        return _getColumnByName(name);
    }

    function getColumnByIndex(uint256 index) external view returns (Column memory) {
        return _getColumnByIndex(index);
    }

    function getColumnById(address id) external view returns (Column memory) {
        return _getColumnById(id);
    }

    function getTotalColumns() external view returns (uint256) {
        return columnCount;
    }

    // internal getters
    function _getColumnByName(string memory name) internal view returns (Column memory) {
        return columnById[columnIdByName[name]];
    }

    function _getColumnByIndex(uint256 index) internal view returns (Column memory) {
        return columnById[columnIdByIndex[index]];
    }

    function _getColumnById(address id) internal view returns (Column memory) {
        return columnById[id];
    }

    // internal Setters
    function _setColumnByName(string memory name, Column memory _column) internal returns (Column memory) {
        columnById[columnIdByName[name]] = _column;
        return columnById[columnIdByName[name]];
    }

    function _setColumnByIndex(uint256 index, Column memory _column) internal returns (Column memory) {
        columnById[columnIdByIndex[index]] = _column;
        return columnById[columnIdByIndex[index]];
    }

    function _setColumnById(address id, Column memory _column) internal returns (Column memory) {
        columnById[id] = _column;
        return columnById[id];
    }
}
