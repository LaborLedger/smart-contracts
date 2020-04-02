pragma solidity 0.5.13;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "./lib/CollaborationAware.sol";
import "./lib/Constants.sol";
import "./lib/Erc165Compatible.sol";
import "./lib/interface/ILaborLedger.sol";
import "./lib/LaborLedgerRoles.sol";
import "./lib/LaborRegister.sol";
import "./lib/Operators.sol";
import "./lib/SafeMath32.sol";
import "./lib/WeeksList.sol";

contract LaborLedgerImpl is
Initializable,
Context,
Constants,
ILaborLedger,
Erc165Compatible,
LaborLedgerRoles,
CollaborationAware,
Operators,
LaborRegister
{
    /**
    * @dev "Time Units"
    * All submitted, stored and returned working hours are measured in Time Units
    * 1 Time Unit = 300 seconds
    *
    * @dev "Labor Units"
    * "Labor Units" are the Time Units weighted with the "weight" factor for a member
    *
    * @dev "Equity Units"
    * Equity submitted, stored and returned in Share Units
    * 100% = 1,000,000 Share Unit(s)
    *
    * @dev "Week Index"
    * Weeks are submitted, stored and returned as Week Indexes (refer to `Weeks.sol`)
    *
    * @notice (safeMath lib is not used as processed values are too small to cause overflows)
    */

    using SafeMath32 for uint32;

    // Indexes for `weights`
    enum WeightInd {
        JUNIOR,     // 0
        STANDARD,   // 1
        SENIOR,     // 2
        ADVISER     // 3
    }

    struct Project {
        uint32 birthBlock;          // block the contract is created within
        uint16 startWeek;           // Week Index of the project first week
        uint32 weights;             // Time Units to Labor Units conversion factors
                                    // (packed uint8[4] for JUNIOR, STANDARD, SENIOR, ADVISER)
        uint32 time;                // total submitted hours in Time Units
        uint32 labor;               // total submitted hours in Labor Units
        uint32 settledLabor;        // Labor Units converted in tokens or paid (reserved)
        uint16 _unused;             // reserved
    }

    Project private _project;

    uint256[10] __gap;              // reserved for upgrades

    function () external payable
    {
        revert("ethers unaccepted");
    }

    /**
    * @dev "constructor" to be delegatecall`ed on deployment of Proxy
    *
    * @param collaboration <address> Collaboration contract, the only mandatory param
    * (provide zero value(s) for any (all) other param(s) to set the default value(s))
    * @param projectLead <address> (optional) address of project lead
    * @param startWeek <uint16> project first week as Week Index (default - previous week)
    * @param weights <uint32> (packed uint8[4]) factors to convert Time Units in Labor Units
    */
    function initialize(
        address collaboration,
        address projectLead,
        address projectArbiter,
        address defaultOperator,
        uint16 startWeek,
        uint32 weights
    ) public initializer
    {
        CollaborationAware._initialize(collaboration);
        LaborLedgerRoles._initialize(projectLead, projectArbiter);
        Operators._initialize(defaultOperator);

        _project.birthBlock = uint32(block.number);

        if (startWeek != 0) {
            require(startWeek <= LATEST_START_WEEK, "too big startWeek");
            _project.startWeek = startWeek;
        } else {
            _project.startWeek = getCurrentWeek() - 1;
        }

        if (weights != 0) {
            _project.weights = weights;
        } else {
            _project.weights = WEIGHTS;
        }
    }

    function getWeights() external view returns(uint8[4] memory weights)
    {
        weights = _unpackWeights(_project.weights);
    }

    /**
    * @dev Returns the share of a member in total labor (of all members)
    * @param member Address of the member
    * @return uint32 share in ShareUnits
    */
    function getMemberLaborShare(address member) external view
    returns(uint64 share)
    {
        uint32 projectNetLabor = _project.labor.sub(_project.settledLabor);
        if (projectNetLabor == 0) return 0;

        uint32 memberNetLabor = _getMemberNetLabor(member);
        if (memberNetLabor == 0) return 0;

        share = uint64(HUNDRED_PERCENT) * memberNetLabor / projectNetLabor;
    }

    function setMemberStatus(address member, Status status) external
    onlyProjectLead
    {
        _setMemberStatus(member, status);
    }

    function setMemberStatusFor(address lead, address member, Status status)
    external
    {
        require(isProjectLead(lead), "unauthorized lead");
        require(isOperatorFor(_msgSender(), lead), "unauthorized operator");
        _setMemberStatus(member, status);
    }

    /**
    * @dev Set member weight. Can only be done once. Only project lead can call
    * @param member User whose weight has to be set
    * @param weightInd WeightInd of the member (the index in `weights`)
    */
    function setMemberWeight(address member, WeightInd weightInd) external
    onlyProjectLead
    {
        _setMemberWeight(member, weightInd);
    }

    function setMemberWeightFor(
        address lead,
        address member,
        WeightInd weightInd
    ) external
    {
        require(isProjectLead(lead), "unauthorized lead");
        require(isOperatorFor(_msgSender(), lead), "unauthorized operator");
        _setMemberWeight(member, weightInd);
    }

    /**
    * @dev Allows project lead to setup a new limit on maximum weekly labor time
    * @param maxTime uint16 maximum weekly labor time in Time Units
    */
    function setMemberWeekLimit(address member, uint16 maxTime) external
    onlyProjectLead
    {
        _setMemberWeekLimit(member, maxTime);
    }

    function setMemberWeekLimitFor(
        address lead,
        address member,
        uint16 maxTime
    ) external
    {
        require(isProjectLead(lead), "unauthorized lead");
        require(isOperatorFor(_msgSender(), lead), "unauthorized operator");
        _setMemberWeekLimit(member, maxTime);
    }

    /**
    * @dev Allows a new user to join
    * @param inviteHash bytes32 reserved for future use
    */
    function join(bytes32 inviteHash) external
    {
        _join(_msgSender(), inviteHash);
    }

    function joinFor(address user, bytes32 inviteHash) external
    {
        require(isOperatorFor(_msgSender(), user), "unauthorized operator");
        _join(user, inviteHash);
    }

    /**
    * @dev Allows existing members to submit hours
    *   Submissions allowed by members only and for a week that:
    *   - has not yet been submitted
    *   - already has ended
    *   - ended no later then four weeks ago
    * @param week Week as uint16
    * @param time Time worked (expressed in Time Units)
    * @param uid {bytes32} - unique ID for the submission
    */
    function submitTime(uint16 week, int32 time, bytes32 uid) external
    {
        _submitTime(_msgSender(), week, time, uid, true);
    }

    function submitTimeFor(
        address member,
        uint16 week,
        int32 time,
        bytes32 uid
    ) external
    {
        require(isOperatorFor(_msgSender(), member), "unauthorized operator");
        _submitTime(member, week, time, uid, true);
    }

    /**
     * @notice `time` is SIGNED integer
     */
    function updateTime(
        address member,
        uint16 week,
        int32 time,
        bytes32 uid
    ) external
    onlyProjectArbiter
    {
        _submitTime(member, week, time, uid, false);
    }

    function updateTimeFor(
        address arbiter,
        address member,
        uint16 week,
        int32 time,
        bytes32 uid
    ) external
    {
        require(isProjectArbiter(arbiter), "unauthorized arbiter");
        require(isOperatorFor(_msgSender(), arbiter), "unauthorized operator");
        _submitTime(member, week, time, uid, false);
    }

    function settleLabor(address member, uint32 labor, bytes32 uid) external
    onlyCollaboration returns(bytes4)
    {
        _settleLabor(member, labor, uid);
        return LABORLEDGER_IFACE;
    }

    function _setMemberWeight(address member, WeightInd weightInd) internal
    {
        uint8[4] memory weights = _unpackWeights(_project.weights);
        uint8 weight = weights[uint8(weightInd)];

        uint32 labor = _setMemberWeight(member, weight);
        _project.labor = _project.time.add(labor);
    }

    function _setMemberWeekLimit(address member, uint16 maxTime) internal
    {
        require(maxTime <= MAX_MAX_TIME_WEEKLY, "too big maxTime");
        _setMemberTimePerWeek(member, maxTime);
    }

    function _join(address member, bytes32 inviteHash) internal
    {
        (
        Status status,
        uint8 weight,
        uint16 startWeek,
        uint16 maxWeeklyTime
        ) =_decodeInvite(inviteHash);
        _joinMember(member, status, weight, startWeek, maxWeeklyTime);
        _clearInvite(inviteHash, member);
    }

    function _submitTime(
        address member,
        uint16 week,
        int32 time,
        bytes32 uid,
        bool revertClosedAndDuplicated
    ) internal
    {
        int32 labor = _submitMemberTime(member, week, time, uid, revertClosedAndDuplicated);
        _project.time = _project.time.addSigned(time);
        _project.labor = _project.time.addSigned(labor);
    }

    function _decodeInvite(bytes32 inviteHash) internal view
    returns(
        Status status,
        uint8 weight,
        uint16 startWeek,
        uint16 maxWeeklyTime
    )
    {
        bytes32 invite = _getInvite(inviteHash);
        // TODO: set member params then retrieve them via invites
        require(invite == 0, "invite params yet unsupported");
        return (
        Status.UNKNOWN, NO_WEIGHT, _project.startWeek, STD_MAX_TIME_WEEKLY
        );
    }

    function _unpackWeights(uint32 weightsPacked) private pure
    returns(uint8[4] memory weights)
    {
        weights[3] = uint8((weightsPacked >> 24) & 0xFF);
        weights[2] = uint8((weightsPacked >> 16) & 0xFF);
        weights[1] = uint8((weightsPacked >> 8) & 0xFF);
        weights[0] = uint8(weightsPacked & 0xFF);
    }

    /**
    * @dev ERC-165 supportInterface realization
    */
    function _supportInterface(bytes4 interfaceID) internal pure returns (bool)
    {
        if (interfaceID == LABORLEDGER_IFACE) return true;
        return super._supportInterface(interfaceID);
    }
}

// TODO: optimize function params to cut gas spent on bitwise operations
