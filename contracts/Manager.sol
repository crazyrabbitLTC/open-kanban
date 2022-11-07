// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IDatabase.sol";
import "./interfaces/Interfaces.sol";
// import "./Columns/ColumnManager.sol";
import "./Tickets/TicketManager.sol";

contract Manager is AccessControlEnumerable, TicketManager, Initializable {
    // This Kanbans name and description
    Kanban public kanban;

    mapping(address => User) public users;

    // Setup
    IDatabase public dbImplementation;
    IBoard public boardImplementation;

    // NFT Board
    IBoard public board;
    // DB
    IDatabase public db;

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

    function initialize(
        address _superAdmin,
        IDatabase _implementation,
        IBoard _boardImplementation,
        UserWithRoles[] memory _usersWithRoles,
        Column[] memory _columns,
        Kanban memory _kanban
    ) public initializer {
        // database implementation
        dbImplementation = _implementation;

        // board implementation
        boardImplementation = _boardImplementation;
        _setupBoard(_superAdmin);

        // Kanban details
        kanban = _kanban;

        // Users
        _setupUsersAndRoles(_usersWithRoles, _superAdmin);

        // Columns
        _setupColumns(_columns, dbImplementation);
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

    function _setupBoard(address superAdmin) internal {
        board = IBoard(Clones.clone(address(boardImplementation)));

        board.initialize(
            superAdmin,
            string(abi.encodePacked(address(board))),
            string(abi.encodePacked(address(board)))
        );
        emit BoardInitalized(board, db);
    }

    function openTickets(Ticket[] memory tickets, address[] memory recipients)
        public
        onlyWithRoles(membersOrAdminsOrReviewers)
        returns (Ticket[] memory createdTickets)
    {
        // require array length matches
        if (tickets.length != recipients.length) {
            revert ArrayLengthMismatch();
        }

        Ticket[] memory output = new Ticket[](tickets.length);
        for (uint256 i = 0; i < tickets.length; i++) {
            // check if column exists
            if (address(_getColumnByIndex(tickets[i].columnIndex).database) == address(0)) {
                revert ColumnDoesNotExist({ columnIndex: tickets[i].columnIndex });
            }

            // create ticket
            Ticket memory newTicket = _openTicket(tickets[i], recipients[i], boardImplementation);

            // add ticket to column
            _addTicketToColumn(tickets[i].columnIndex, newTicket.id);

            // add column to ticket
            _updateColumnOnTicket(tickets[i].columnIndex, newTicket.id);

            output[i] = newTicket;
        }

        return output;
    }
}
