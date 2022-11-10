// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/IGovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IBoard is IERC721Upgradeable, IAccessControlUpgradeable {
    function initialize(
        address owner,
        string memory boardName,
        string memory boardSymbol
    ) external;

    function safeMint(address to, string memory uri) external;
}

interface ITicketGov {
    function initialize(
        IVotesUpgradeable _token,
        string memory _name,
        uint256 _block,
        uint256 _seconds,
        uint256 _propThreshold
    ) external;
}

contract TicketManagerOLD is Initializable {
    address[] public nftImplementationVersions;
    address[] public govImplementationVersions;

    error InvalidNFTImplenetation(uint256 id);
    error InvalidGovImplenetation(uint256 id);

    event Initialized(address[] nftImplementationVersions, address[] govImplementationVersions);
    event NFTCreated(address indexed nft, string name, string symbol, uint256 implementation);
    event GovCreated(address indexed gov, string name, uint256 implementation);

    event TicketCreated(
        Ticket ticket,
        Recipient[] recipients,
        address indexed nftAddress,
        uint256 id,
        address indexed gov
    );

    struct Ticket {
        string name;
        string symbol;
        string uri;
        uint256 columnId;
        uint256 statusId;
        bytes32 data;
    }

    struct Recipient {
        address recipient;
        bytes32[] roles;
    }

    struct GovSetup {
        bool required;
        IVotesUpgradeable _token;
        string _name;
        uint256 _block;
        uint256 _seconds;
        uint256 _propThreshold;
        uint256 implementationVersion;
    }

    function initialize(address nftImplementationVersion, address govImplementationVersion) public initializer {
        nftImplementationVersions.push(nftImplementationVersion);
        govImplementationVersions.push(govImplementationVersion);

        emit Initialized(nftImplementationVersions, govImplementationVersions);
    }

    function createTicket(
        Ticket memory newTicket,
        Recipient[] memory recipients,
        uint256 _nftImplementation,
        uint256 _govImplementation,
        GovSetup memory _govSetup
    ) public returns (address, uint256) {
        // create NFT
        address nft = _cloneNFT(newTicket.name, newTicket.symbol, _nftImplementation);

        // set roles
        _setRoles(nft, recipients);

        // distribute tokens
        _distributeTokens(nft, recipients, newTicket.uri);

        address gov = address(0);
        // setup governance
        if (_govSetup.required) {
            // TODO: add manager as super admin?
            gov = _cloneGovernor(
                IVotesUpgradeable(nft),
                _govSetup._name,
                _govSetup._block,
                _govSetup._seconds,
                _govSetup._propThreshold,
                _govImplementation
            );
        }
        uint256 id = uint256(uint160(nft));
        emit TicketCreated(newTicket, recipients, nft, id, gov);
        return (nft, id);
    }

    function _cloneGovernor(
        IVotesUpgradeable _token,
        string memory _name,
        uint256 _block,
        uint256 _seconds,
        uint256 _propThreshold,
        uint256 implementationVersion
    ) internal returns (address) {
        if (implementationVersion >= govImplementationVersions.length)
            revert InvalidGovImplenetation(implementationVersion);
        address gov = Clones.clone(address(govImplementationVersions[implementationVersion]));
        ITicketGov(gov).initialize(_token, _name, _block, _seconds, _propThreshold);
        emit GovCreated(gov, _name, implementationVersion);
        return gov;
    }

    function _distributeTokens(
        address nft,
        Recipient[] memory recipients,
        string memory uri
    ) internal {
        for (uint256 i = 0; i < recipients.length; i++) {
            IBoard(nft).safeMint(recipients[i].recipient, uri);
        }
    }

    function _cloneNFT(
        string memory name,
        string memory symbol,
        uint256 implementationVersion
    ) internal returns (address) {
        if (implementationVersion >= nftImplementationVersions.length)
            revert InvalidNFTImplenetation(implementationVersion);
        address nft = Clones.clone(address(nftImplementationVersions[implementationVersion]));
        IBoard(nft).initialize(address(this), name, symbol);
        emit NFTCreated(nft, name, symbol, implementationVersion);
        return nft;
    }

    function _setRoles(address nft, Recipient[] memory recipients) internal {
        for (uint256 i = 0; i < recipients.length; i++) {
            for (uint256 j = 0; j < recipients[i].roles.length; j++) {
                IBoard(nft).grantRole(recipients[i].roles[j], recipients[i].recipient);
            }
        }
    }

    // function _doStuffOnGov();
    // function _doStuffOnNFT();
}
