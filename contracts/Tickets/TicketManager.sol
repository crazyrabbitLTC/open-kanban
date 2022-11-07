// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "hardhat/console.sol";

import "../interfaces/Interfaces.sol";
import "../Columns/ColumnManager.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TicketManager is ColumnManager {
    using Counters for Counters.Counter;

    Counters.Counter private _ticketCount;

    // track all tickets
    mapping(uint256 => Ticket) internal ticketById;
    mapping(uint256 => uint256) internal ticketIdByIndex;

    function _openTicket(
        Ticket memory ticket,
        address recipient,
        IBoard board
    ) internal returns (Ticket memory) {
        // create the ticket
        console.log("OpenTicket: Minting MSG Sender: %s", msg.sender);
        console.log("OpenTicket: This Calling Address: %s", address(this));
        console.log(
            "OpenTicket: Does msg.sender have minting role? %s",
            board.hasRole(keccak256("MINTER_ROLE"), msg.sender)
        );
        console.log(
            "OpenTicket: Does this contract it have minting role? %s",
            board.hasRole(keccak256("MINTER_ROLE"), address(this))
        );

        uint256 ticketId = board.safeMint(recipient, ticket.uri);
        Ticket memory newTicket = ticket;
        newTicket.id = ticketId;

        // increment ticket count
        _ticketCount.increment();

        // setup ticket relations
        ticketById[ticketId] = newTicket;
        ticketIdByIndex[_ticketCount.current()] = ticketId;

        return newTicket;
    }

    function _addTicketToColumn(uint256 index, uint256 ticketId) internal {
        // note: no protection for duplicate tickest, be sure it's a unique ticket

        // check if column exists
        if (address(_getColumnByIndex(index).database) == address(0)) {
            revert ColumnDoesNotExist({ columnIndex: index });
        }
        // check if ticket already exists in this column
        if (_getColumnByIndex(index).database.nodeExists(ticketId)) {
            revert TicketAlreadyInColumn({ ticketId: ticketId, columnIndex: index });
        }

        _getColumnByIndex(index).database.pushBack(ticketId);

        // increment ticket count in this column
        _getColumnByIndex(index).ticketCount++;
        emit TicketAddedToColumn(ticketId, index);
    }

    function _moveTicketBetweenColumns(
        uint256 fromIndex,
        uint256 toIndex,
        uint256 ticketId
    ) internal returns (uint256) {
        // check if columns exists
        if (address(_getColumnByIndex(fromIndex).database) == address(0)) {
            revert ColumnDoesNotExist({ columnIndex: fromIndex });
        }
        if (address(_getColumnByIndex(toIndex).database) == address(0)) {
            revert ColumnDoesNotExist({ columnIndex: toIndex });
        }

        // check if ticket already exists in this column
        if (!_getColumnByIndex(fromIndex).database.nodeExists(ticketId)) {
            revert TicketDoesNotExistInColumn({ ticketId: ticketId, columnIndex: fromIndex });
        }

        // remove ticket from fromIndex
        _getColumnByIndex(fromIndex).database.remove(ticketId);

        // add ticket to toIndex
        _getColumnByIndex(toIndex).database.pushBack(ticketId);

        // decrement ticket count in fromIndex
        _getColumnByIndex(fromIndex).ticketCount--;

        // increment ticket count in toIndex
        _getColumnByIndex(toIndex).ticketCount++;

        // update the column on the ticket
        _updateColumnOnTicket(toIndex, ticketId);

        emit TicketMoved(ticketId, fromIndex, toIndex);

        return toIndex;
    }

    function _updateColumnOnTicket(uint256 newColumnIndex, uint256 ticketId) internal {
        //update ticketIdToColumnID
        ticketById[ticketId].columnIndex = newColumnIndex;
    }

    // external getters
    function getTicketById(uint256 id) external view returns (Ticket memory) {
        return _getTicketById(id);
    }

    function getTicketByIndex(uint256 index) external view returns (Ticket memory) {
        return _getTicketByIndex(index);
    }

    // internal getters
    function _getTicketById(uint256 id) internal view returns (Ticket memory) {
        return ticketById[id];
    }

    function _getTicketByIndex(uint256 index) internal view returns (Ticket memory) {
        return ticketById[ticketIdByIndex[index]];
    }
}
