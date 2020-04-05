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

    function getBirthBlock() external view returns(uint32)
    {
        return _project.birthBlock;
    }

    function getStartWeek() external view returns(uint16)
    {
        return (_project.startWeek);
    }

    function getWeights() external view returns(uint8[4] memory weights)
    {
        weights = _unpackWeights(_project.weights);
    }

    function getTotalTime() external view returns(uint32)
    {
        return (_project.time);
    }

    function getTotalLabor() external view
        returns(uint32 labor, uint32 settledLabor, uint32 netLabor)
    {
        return (
            _project.labor,
            _project.settledLabor,
            _project.labor - _project.settledLabor
        );
    }

    function getMemberNetLabor(address member) external view returns(uint32) {
        return _getMemberNetLabor(member);
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

        uint32 netLabor = _getMemberNetLabor(member);
        if (netLabor == 0) return 0;

        share = uint64(HUNDRED_PERCENT) * netLabor / projectNetLabor;
    }

    function setMemberStatus(address member, Status status) external
    onlyProjectLead
    {
        _setMemberStatus(member, status);
    }

    function setMemberStatus(address lead, address member, Status status)
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
        _setMemberWeight(member, weightInd, true);
    }

    function setMemberWeight(
        address lead,
        address member,
        WeightInd weightInd
    ) external
    {
        require(isProjectLead(lead), "unauthorized lead");
        require(isOperatorFor(_msgSender(), lead), "unauthorized operator");
        _setMemberWeight(member, weightInd, true);
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

    function setMemberWeekLimit(
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
    * @param invite Invitation
    */
    function join(
        bytes calldata invite,
        Status status,
        WeightInd weightInd,
        uint16 startWeek,
        uint16 maxTimeWeekly,
        uint160 terms
    ) external
    {
        _join(_msgSender(), invite, status, weightInd, startWeek, maxTimeWeekly, terms);
    }

    function join(
        address user,
        bytes calldata invite,
        Status status,
        WeightInd weightInd,
        uint16 startWeek,
        uint16 maxTimeWeekly,
        uint terms
    ) external
    {
        require(isOperatorFor(_msgSender(), user), "unauthorized operator");
        _join(user, invite, status, weightInd, startWeek, maxTimeWeekly, terms);

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

    function submitTime(
        address member,
        uint16 week,
        int32 time,
        bytes32 uid
    ) external
    {
        require(isOperatorFor(_msgSender(), member), "unauthorized operator");
        _submitTime(member, week, time, uid, true);
    }

    function updateMemberWeight(address member, WeightInd weightInd) external
    onlyProjectArbiter
    {
        _setMemberWeight(member, weightInd, false);
    }

    function updateMemberWeight(
        address arbiter,
        address member,
        WeightInd weightInd
    ) external
    {
        require(isProjectArbiter(arbiter), "unauthorized arbiter");
        require(isOperatorFor(_msgSender(), arbiter), "unauthorized operator");
        _setMemberWeight(member, weightInd, false);
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

    function updateTime(
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

    function getWeight(WeightInd weightInd) public view returns(uint8 weight)
    {
        uint8[4] memory weights = _unpackWeights(_project.weights);
        weight = weights[uint8(weightInd)];
    }

    function encodeInviteData (
        uint status, uint weightInd, uint startWeek, uint maxWeeklyTime, uint terms
    ) public pure returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(status, weightInd, startWeek, maxWeeklyTime, terms)
        );
    }

    function _setMemberWeight(address member, WeightInd weightInd, bool onceOnly) internal
    {
        uint32 labor = _setMemberWeight(member, getWeight(weightInd), onceOnly);
        _project.labor = _project.time.add(labor);
    }

    function _setMemberWeekLimit(address member, uint16 maxTime) internal
    {
        require(maxTime <= MAX_MAX_TIME_WEEKLY, "too big maxTime");
        _setMemberTimePerWeek(member, maxTime);
    }

    function _join(
        address member,
        bytes memory invite,
        Status status,
        WeightInd weightInd,
        uint16 startWeek,
        uint16 maxWeeklyTime,
        uint terms
    ) internal
    {
        _validateInvite(
            invite,
            uint(status),
            uint(weightInd),
            uint(startWeek),
            uint(maxWeeklyTime),
            terms
        );
        uint16 wTime = maxWeeklyTime == 0 ? STD_MAX_TIME_WEEKLY : maxWeeklyTime;

        _joinMember(member, status, getWeight(weightInd), startWeek, wTime);
        _clearInvite(invite);
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

    function _validateInvite(
        bytes memory invite,
        uint status,
        uint weightInd,
        uint startWeek,
        uint maxWeeklyTime,
        uint terms
    ) internal view
    {
        require(
            uint(_getInvite(invite)) == uint(
                encodeInviteData(status, weightInd, startWeek, maxWeeklyTime, terms)
            ), "invite data unmatched"
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
