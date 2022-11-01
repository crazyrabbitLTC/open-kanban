// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/IDatabase.sol";
import "./interfaces/IBoard.sol";

contract KanbanManager is AccessControlEnumerable {
    struct Ticket {
        uint256 id;
        string name;
        string uri;
        uint256[] links;
        uint256 column;
        uint256 status;
        uint256 priority;
        uint256 estimate;
        address assignee;
        address reviewer;
        address creator;
        uint256 created;
        uint256 updated;
    }

    struct Kanban {
        string name;
        string description;
        string uri;
        bytes32 data;
    }
    // This Kanbans name and description
    Kanban public kanban;

    // Columns
    struct Column {
        string name;
        bytes32 uri;
        IDatabase database;
    }
    IDatabase public columns;
    mapping(uint256 => Column) public column;

    // Users
    struct User {
        address account;
        bytes32 uri;
        bytes32 data;
    }
    mapping(address => User) public users;

    // User with Role
    struct UserWithRoles {
        address account;
        bytes32 data;
        bytes32 uri;
        string[] roles;
    }

    // Statuses
    struct Status {
        string name;
        bytes32 uri;
        bytes32 data;
    }
    Status[] public statuses;

    // Setup
    IDatabase public dbImplementation;
    IBoard public boardImplementation;

    // Status Levels
    string[] public statusLevels;

    // Mapping of Tickets
    mapping(uint256 => Ticket) public tickets;

    // NFT Board
    IBoard public board;
    // DB
    IDatabase public db;

    bool public isIniziialized;

    error TicketDoesNotExist(uint256 ticketId);
    error CallerDoesNotHaveRequiredRole();
    error OpenTicketInvalidColumn();
    error FailedToAddTicket(uint256 ticketId);

    event BoardInitalized(IBoard board, IDatabase db);
    event ColumnAdded(string name, bytes32 uri, uint256 index, address database);
    event TicketOpened(uint256 ticketId);
    event TicketMetadataUpdated(uint256 ticketId, Ticket ticket);
    event NewRoleCreated(string role, bytes32 roleHash, address recipient);
    event UserCreated(address account, bytes32 uri, bytes32 data);
    event StatusCreated(string name, bytes32 uri, bytes32 data, uint256 index);

    // roles - priviledged
    bytes32 public constant KANBAN_ADMIN = keccak256("KANBAN_ADMIN");
    bytes32 public constant KANBAN_MEMBER = keccak256("KANBAN_MEMBER");
    bytes32 public constant KANBAN_REVIEWER = keccak256("KANBAN_REVIEWER");

    // combined roles
    bytes32[] internal membersOrAdmins = [KANBAN_ADMIN, KANBAN_MEMBER];
    bytes32[] internal membersOrAdminsOrReviewers = [KANBAN_ADMIN, KANBAN_MEMBER, KANBAN_REVIEWER];

    //modifiers
    modifier onlyIfTicketExists(uint256 _ticketId) {
        if (!db.nodeExists(_ticketId)) {
            revert TicketDoesNotExist({ ticketId: _ticketId });
        }
        _;
    }

    modifier onlyWithRoles(bytes32[] memory _role) {
        bool hasPermission = false;
        for (uint256 i = 0; i < _role.length; i++) {
            if (hasRole(_role[i], msg.sender)) {
                hasPermission = true;
                break;
            }
        }
        if (!hasPermission) {
            revert CallerDoesNotHaveRequiredRole();
        }
        _;
    }

    constructor(
        address _superAdmin,
        IDatabase _implementation,
        IBoard _boardImplementation,
        UserWithRoles[] memory _usersWithRoles,
        Status[] memory _statusLevels,
        Column[] memory _columns,
        Kanban memory _kanban
    ) {
        // database implementation
        dbImplementation = _implementation;

        // board implementation
        boardImplementation = _boardImplementation;
        _setupBoard();

        // Kanban details
        kanban = _kanban;

        // Users
        _setupUsersAndRoles(_usersWithRoles, _superAdmin);

        // Statuses
        _setupStatuses(_statusLevels);

        // Columns
        _setupColumns(_columns);
    }

    function _setupUsersAndRoles(UserWithRoles[] memory _usersWithRoles, address _superAdmin) internal {
        _setupRole(DEFAULT_ADMIN_ROLE, _superAdmin);

        for (uint256 i = 0; i < _usersWithRoles.length; i++) {
            UserWithRoles memory user = _usersWithRoles[i];
            // create user
            users[user.account] = User({ account: user.account, uri: user.uri, data: user.data });
            // asign users roles
            for (uint256 j = 0; j < user.roles.length; j++) {
                bytes32 role = keccak256(abi.encodePacked(user.roles[j]));
                _grantRole(role, user.account);
                if (role != KANBAN_ADMIN) {
                    _setRoleAdmin(role, KANBAN_ADMIN);
                }
                emit NewRoleCreated(user.roles[j], role, user.account);
            }
            emit UserCreated(user.account, user.uri, user.data);
        }
    }

    function _setupStatuses(Status[] memory _statusLevels) internal {
        for (uint256 i = 0; i < _statusLevels.length; i++) {
            Status memory status = _statusLevels[i];
            statuses.push(status);
            statusLevels.push(status.name);
            emit StatusCreated(status.name, status.uri, status.data, i);
        }
    }

    function _setupBoard() internal {
        board = IBoard(Clones.clone(address(boardImplementation)));
        emit BoardInitalized(board, db);
    }

    function _setupColumns(Column[] memory _columns) internal {
        columns = IDatabase(Clones.clone(address(dbImplementation)));

        for (uint256 i = 0; i < _columns.length; i++) {
            address clone = Clones.clone(address(dbImplementation));
            uint256 columnIndex = uint256(uint160(clone));
            column[columnIndex] = _columns[i];
            columns.pushBack(columnIndex);
            emit ColumnAdded(_columns[i].name, _columns[i].uri, columnIndex, clone);
        }
    }

    // function openTicket(Ticket calldata newTicket, address recipient)
    //     public
    //     onlyWithRoles(membersOrAdmins)
    //     returns (bool status)
    // {
    //     // //require Column exists
    //     // if (newTicket.column >= columns.length) revert OpenTicketInvalidColumn();
    //     // // create ticket
    //     // uint256 ticketId = board.safeMint(recipient, newTicket.uri);
    //     // // save ticket (to the right column!)
    //     // // if (!db.pushBack(ticketId)) revert FailedToAddTicket(ticketId);
    //     // // update ticket
    //     // tickets[ticketId] = newTicket;
    //     // emit TicketOpened(ticketId);
    //     // emit TicketMetadataUpdated(ticketId, newTicket);
    //     // return true;
    // }

    // function closeTicket(uint256 ticketId)
    //     public
    //     onlyIfTicketExists(ticketId)
    //     onlyWithRoles(membersOrAdminsOrReviewers)
    //     returns (bool status)
    // {
    //     // require that the ticket exists
    //     if (!db.nodeExists(ticketId)) revert TicketDoesNotExist({ ticketId: ticketId });
    // }

    // function moveTicket(uint256 ticketId)
    //     public
    //     onlyIfTicketExists(ticketId)
    //     onlyWithRoles(membersOrAdmins)
    //     returns (bool status, Ticket calldata)
    // {}

    // function updateTicket(uint256 ticketId)
    //     public
    //     onlyIfTicketExists(ticketId)
    //     onlyWithRoles(membersOrAdmins)
    //     returns (bool status, Ticket calldata)
    // {}

    // function updateKanban() public {}

    // function _onOpenTicket() internal {}

    // function _onCloseTicket() internal {}

    // function _onMoveTicket() internal {}

    // function _onUpdateTicket() internal {}

    // function _onUpdateKanban() internal {}

    // // internal
    // function _callModules() internal {}

    // // by signature
    // function _bySignature() public {}
}
