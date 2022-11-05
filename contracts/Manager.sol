// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IDatabase.sol";

interface IBoard is IERC721 {
    function safeMint(address, string memory) external returns (uint256);

    function initialize(
        address,
        string memory,
        string memory
    ) external;
}

contract Manager is AccessControlEnumerable, Initializable {
    struct Ticket {
        uint256 id;
        string name;
        string uri;
        uint256 columnId;
        uint256 statusId;
        bytes32 data;
    }
    // Mapping of Tickets
    mapping(uint256 => Ticket) public tickets;
    Ticket[] public ticketsArray;

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
        bytes32 data;
    }
    IDatabase public columns;
    mapping(uint256 => Column) public column;
    mapping(string => uint256) public columnId;
    // TODO: add enumerable mapping

    // Users
    struct User {
        address account;
        bytes32 uri;
        bytes32 data;
    }
    mapping(address => User) public users;

    // User with Role (only used for setup)
    struct UserWithRoles {
        address account;
        bytes32 uri;
        string[] roles;
        bytes32 data;
    }

    // Statuses
    struct Status {
        string name;
        bytes32 uri;
        bytes32 data;
    }
    IDatabase public statuses;
    mapping(uint256 => Status) public status;
    // Status[] public statuses;
    // string[] public statusLevels;

    // Setup
    IDatabase public dbImplementation;
    IBoard public boardImplementation;

    // NFT Board
    IBoard public board;
    // DB
    IDatabase public db;

    error TicketDoesNotExist(uint256 ticketId);
    error TicketAlreadyInColumn(uint256 ticketId, uint256 columnId);
    error TicketNotRemovedFromColumn(uint256 ticketId, uint256 columnId);
    error TicketNotAddedToColumn(uint256 ticketId, uint256 columnId);
    error CallerDoesNotHaveRequiredRole();
    error OpenTicketInvalidColumn();
    error FailedToAddTicket(uint256 ticketId);
    error InvalidColumnId(uint256 columnId);
    error InvalidStatusId(uint256 statusId);
    error ArrayLengthMismatch();

    event BoardInitalized(IBoard board, IDatabase db);
    event TicketCreated(Ticket ticket);
    event TicketMetadataUpdated(uint256 ticketId, Ticket ticket);
    event TicketMoved(uint256 ticketId, uint256 previousColumnId, uint256 newColumnId);
    event ColumnCreated(string name, bytes32 uri, uint256 id, address database, bytes32 data);
    event NewRoleCreated(string role, bytes32 roleHash, address recipient);
    event UserCreated(address account, bytes32 uri, bytes32 data);
    event StatusCreated(string name, bytes32 uri, uint256 id, address database, bytes32 data);

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
        Status[] memory _statusLevels,
        Column[] memory _columns,
        Kanban memory _kanban
    ) public initializer {
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
        statuses = IDatabase(Clones.clone(address(dbImplementation)));
        statuses.initialize(address(this));
        for (uint256 i = 0; i < _statusLevels.length; i++) {
            status[i] = _statusLevels[i];
            statuses.pushBack(i);
            emit StatusCreated(
                _statusLevels[i].name,
                _statusLevels[i].uri,
                i,
                address(statuses),
                _statusLevels[i].data
            );
        }
    }

    function _setupBoard() internal {
        board = IBoard(Clones.clone(address(boardImplementation)));
        board.initialize(address(this), "TestBoard", "TB");
        emit BoardInitalized(board, db);
    }

    function _setupColumns(Column[] memory _columns) internal {
        columns = IDatabase(Clones.clone(address(dbImplementation)));
        // initialize the database
        columns.initialize(address(this));
        for (uint256 i = 0; i < _columns.length; i++) {
            address clone = Clones.clone(address(dbImplementation));
            IDatabase(clone).initialize(address(this));
            uint256 columnIndex = uint256(uint160(clone));
            column[columnIndex] = _columns[i];
            column[columnIndex].database = IDatabase(clone);
            columns.pushBack(columnIndex);
            columnId[_columns[i].name] = columnIndex;
            emit ColumnCreated(_columns[i].name, _columns[i].uri, columnIndex, clone, _columns[i].data);
        }
    }

    function openTicket(Ticket memory ticket, address recipient) public onlyWithRoles(membersOrAdminsOrReviewers) {
        // check if column exists
        if (!columns.nodeExists(ticket.columnId)) {
            revert InvalidColumnId({ columnId: ticket.columnId });
        }
        // check if status exists
        if (!statuses.nodeExists(ticket.statusId)) {
            revert InvalidStatusId({ statusId: ticket.statusId });
        }
        // create ticket
        uint256 ticketId = board.safeMint(recipient, ticket.uri);
        Ticket memory newTicket = ticket;
        newTicket.id = ticketId;

        tickets[ticketId] = newTicket;
        ticketsArray.push(newTicket);
        // add ticket to column
        column[newTicket.columnId].database.pushBack(newTicket.id);
        emit TicketCreated(newTicket);
    }

    function moveTicketsBetweenColumns(uint256[] memory ticketIds, uint256[] memory destinationColumnIds)
        public
        onlyWithRoles(membersOrAdminsOrReviewers)
    {
        if (ticketIds.length != destinationColumnIds.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < ticketIds.length; i++) {
            _moveTicketBetweenColumns(ticketIds[i], destinationColumnIds[i]);
        }
    }

    function _moveTicketBetweenColumns(uint256 ticketId, uint256 destinationColumnId) internal returns (bool) {
        // check if ticket is on the board
        if (tickets[ticketId].id == 0) {
            revert TicketDoesNotExist({ ticketId: ticketId });
        }
        // check if destination column is valid
        if (!columns.nodeExists(destinationColumnId)) {
            revert InvalidColumnId({ columnId: destinationColumnId });
        }
        // get current
        uint256 previousColumnId = tickets[ticketId].columnId;
        // check if ticket is already in destination column
        if (previousColumnId == destinationColumnId) {
            revert TicketAlreadyInColumn({ ticketId: ticketId, columnId: destinationColumnId });
        }
        // remove ticket from current column
        column[previousColumnId].database.remove(ticketId);
        // verify it's been removed
        if (column[previousColumnId].database.nodeExists(ticketId)) {
            revert TicketNotRemovedFromColumn({ ticketId: ticketId, columnId: previousColumnId });
        }
        // add ticket to new column from the back
        column[destinationColumnId].database.pushBack(ticketId);
        // verify it's been added
        if (!column[destinationColumnId].database.nodeExists(ticketId)) {
            revert TicketNotAddedToColumn({ ticketId: ticketId, columnId: destinationColumnId });
        }
        // update ticket
        tickets[ticketId].columnId = destinationColumnId;
        // emit event
        emit TicketMoved(ticketId, previousColumnId, destinationColumnId);
        // report success
        return true;
    }

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
