pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LegalRecordVault is AccessControl {
    using Counters for Counters.Counter;

    // Role Definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant JUDGE_ROLE = keccak256("JUDGE_ROLE");
    bytes32 public constant LAWYER_ROLE = keccak256("LAWYER_ROLE");

    // Record Struct
    struct LegalRecord {
        uint256 id;
        string ipfsHash;
        address uploadedBy;
        uint256 timestamp;
        bool isApproved; // For judge approval
    }

    // Mapping for records
    mapping(uint256 => LegalRecord) private records;
    Counters.Counter private recordIdCounter;

    // Events
    event RecordAdded(uint256 indexed id, string ipfsHash, address indexed uploadedBy, uint256 timestamp);
    event RecordApproved(uint256 indexed id, address indexed approvedBy);
    event RecordRejected(uint256 indexed id, address indexed rejectedBy);

    // Constructor
    constructor(address admin) {
        _setupRole(ADMIN_ROLE, admin);
        _setRoleAdmin(JUDGE_ROLE, ADMIN_ROLE);
        _setRoleAdmin(LAWYER_ROLE, ADMIN_ROLE);
    }

    // Modifier: Only admin can perform this action
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not an admin");
        _;
    }

    // Modifier: Only judges can approve/reject
    modifier onlyJudge() {
        require(hasRole(JUDGE_ROLE, msg.sender), "Not a judge");
        _;
    }

    // Function to add a new record
    function addRecord(string memory ipfsHash) external {
        require(hasRole(LAWYER_ROLE, msg.sender), "Only lawyers can add records");

        recordIdCounter.increment();
        uint256 newId = recordIdCounter.current();

        records[newId] = LegalRecord({
            id: newId,
            ipfsHash: ipfsHash,
            uploadedBy: msg.sender,
            timestamp: block.timestamp,
            isApproved: false
        });

        emit RecordAdded(newId, ipfsHash, msg.sender, block.timestamp);
    }

    // Function to approve a record
    function approveRecord(uint256 id) external onlyJudge {
        require(records[id].id != 0, "Record does not exist");
        require(!records[id].isApproved, "Record already approved");

        records[id].isApproved = true;

        emit RecordApproved(id, msg.sender);
    }

    // Function to reject a record
    function rejectRecord(uint256 id) external onlyJudge {
        require(records[id].id != 0, "Record does not exist");
        require(!records[id].isApproved, "Record already approved");

        delete records[id];

        emit RecordRejected(id, msg.sender);
    }

    // Function to retrieve a record
    function getRecord(uint256 id) external view returns (LegalRecord memory) {
        require(records[id].id != 0, "Record does not exist");
        return records[id];
    }

    // Function to assign roles
    function assignRole(bytes32 role, address account) external onlyAdmin {
        grantRole(role, account);
    }

    // Function to revoke roles
    function revokeRole(bytes32 role, address account) external onlyAdmin {
        revokeRole(role, account);
    }

    // Function to list all records (Paginated for Gas Efficiency)
    function listRecords(uint256 start, uint256 limit) external view returns (LegalRecord[] memory) {
        uint256 total = recordIdCounter.current();
        require(start < total, "Invalid start index");

        uint256 end = start + limit;
        if (end > total) {
            end = total;
        }

        LegalRecord[] memory result = new LegalRecord[](end - start);
        uint256 index = 0;

        for (uint256 i = start; i < end; i++) {
            result[index] = records[i + 1];
            index++;
        }

        return result;
    }
}
