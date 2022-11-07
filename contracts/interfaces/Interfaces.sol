// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "./IDatabase.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface DataStructures {
    struct Kanban {
        string name;
        string description;
        string uri;
        bytes32 data;
    }

    struct Ticket {
        uint256 id;
        string name;
        string uri;
        uint256 columnIndex;
        bytes32 data;
    }

    // Columns
    struct Column {
        IDatabase database;
        string name;
        bytes32 uri;
        uint256 ticketCount;
        bytes32 data;
    }

    // Users
    struct User {
        address account;
        bytes32 uri;
        bytes32 data;
    }

    // User with Role (only used for setup)
    struct UserWithRoles {
        address account;
        bytes32 uri;
        string[] roles;
        bytes32 data;
    }
}

interface IBoard is IERC721 {
    function safeMint(address, string memory) external returns (uint256);

    function initialize(
        address,
        string memory,
        string memory
    ) external;

    function hasRole(bytes32, address) external view returns (bool);
}

// interface TicketManager {
//     struct Ticket {
//         string name;
//         string symbol;
//         string uri;
//         uint256 columnIndex;
//         uint256 statusId;
//         bytes32 data;
//     }

//     struct Recipient {
//         address recipient;
//         bytes32[] roles;
//     }

//     function createTicket(
//         Ticket memory ticket,
//         Recipient[] memory recipients,
//         uint256 nftImplementation,
//         uint256 govImplementation
//     ) external returns (address, uint256);
// }

interface Events is DataStructures {
    error TicketDoesNotExist(uint256 ticketId);
    error TicketAlreadyInColumn(uint256 ticketId, uint256 columnIndex);
    error TicketDoesNotExistInColumn(uint256 ticketId, uint256 columnIndex);
    error TicketNotRemovedFromColumn(uint256 ticketId, uint256 columnIndex);
    error TicketNotAddedToColumn(uint256 ticketId, uint256 columnIndex);
    error CallerDoesNotHaveRequiredRole();
    error OpenTicketInvalidColumn();
    error FailedToAddTicket(uint256 ticketId);
    error InvalidColumnId(uint256 columnId);
    error InvalidStatusId(uint256 statusId);
    error ArrayLengthMismatch();
    error ColumnsAlreadyInitialized();
    error ColumnDoesNotExist(uint256 columnIndex);

    event BoardInitalized(IBoard board, IDatabase db);
    event TicketAddedToColumn(uint256 ticketId, uint256 columnIndex);
    event TicketCreated(Ticket ticket);
    event TicketMetadataUpdated(uint256 ticketId, Ticket ticket);
    event TicketMoved(uint256 ticketId, uint256 previousColumnId, uint256 newColumnId);
    event ColumnCreated(string name, bytes32 uri, address database, bytes32 data);
    event NewRoleCreated(string role, bytes32 roleHash, address recipient);
    event UserCreated(address account, bytes32 uri, bytes32 data);
    event StatusCreated(string name, bytes32 uri, uint256 id, address database, bytes32 data);
}
