// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

interface IAccessControl {
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AccessControlBadConfirmation();
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address callerConfirmation) external;
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        returns (bool)
    {
        return _roles[role].hasRole[account];
    }

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address callerConfirmation)
        public
        virtual
    {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account)
        internal
        virtual
        returns (bool)
    {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    function _revokeRole(bytes32 role, address account)
        internal
        virtual
        returns (bool)
    {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract RBAC_DAO is AccessControl {
    // Token and Treasury
    IERC20 public token;
    address public treasury;

    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    // Proposal Struct
    struct Proposal {
        uint256 id;
        string description;
        uint256 voteStart;
        uint256 voteEnd;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    // Mapping of Proposal IDs to Proposals
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    // Events
    event ProposalCreated(
        uint256 id,
        string description,
        uint256 voteStart,
        uint256 voteEnd
    );
    event Voted(address voter, uint256 proposalId, bool support);
    event ProposalExecuted(uint256 proposalId);

    // Constructor
    constructor(address _tokenAddress, address _treasuryAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EXECUTOR_ROLE, msg.sender);
        token = IERC20(_tokenAddress);
        treasury = _treasuryAddress;
    }

    // Functions
    function createProposal(string memory _description, uint256 _votePeriod)
        public
    {
        proposalCount++;
        uint256 id = proposalCount;
        proposals[id] = Proposal(
            id,
            _description,
            block.timestamp,
            block.timestamp + _votePeriod,
            0,
            0,
            false
        );
        emit ProposalCreated(
            id,
            _description,
            block.timestamp,
            block.timestamp + _votePeriod
        );
    }

    function vote(uint256 _proposalId, bool _support) public {
        require(
            block.timestamp >= proposals[_proposalId].voteStart &&
                block.timestamp <= proposals[_proposalId].voteEnd,
            "Voting period is not active"
        );
        require(
            token.balanceOf(msg.sender) > 0,
            "You must hold tokens to vote"
        );

        if (_support) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }

        emit Voted(msg.sender, _proposalId, _support);
    }

    function executeProposal(uint256 _proposalId)
        public
        onlyRole(EXECUTOR_ROLE)
    {
        require(
            block.timestamp > proposals[_proposalId].voteEnd,
            "Voting period has not ended"
        );
        require(
            proposals[_proposalId].votesFor >
                proposals[_proposalId].votesAgainst,
            "Proposal failed"
        );
        require(!proposals[_proposalId].executed, "Proposal already executed");

        // Execute the proposal logic here (e.g., transfer funds, deploy contracts)
        // ...

        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function grantExecutorRole(address _executor)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(EXECUTOR_ROLE, _executor);
    }

    function revokeExecutorRole(address _executor)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(EXECUTOR_ROLE, _executor);
    }
}
