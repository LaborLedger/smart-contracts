pragma solidity 0.5.13;

import "./WeeksList.sol";
import "./SafeMath32.sol";
import "./Constants.sol";

contract LaborRegister is Constants, WeeksList
{
    /**
    * @dev "Labor Units"
    * "Labor Units" are the Time Units weighted with the "weight" factor for a member
    */

    using SafeMath32 for uint32;

    enum Status {
        UNKNOWN,    // 0
        ACTIVE,     // 1
        ONHOLD ,    // 2
        OFFBOARDED  // 3
    }

    struct Member {
        Status status;
        uint8 weight;               // factor (not index) to convert `time` to `labor`
        uint16 startWeek;           // Week Index of the member first week
        uint16 maxTimeWeekly;       // max Time Units allowed to submit per a week
        uint32 time;                // accepted submitted Time Units
        uint32 labor;               // Labor Units equivalent of `time`
        uint16 pendingTime;         // not yet accepted submitted Time Units (reserved)
        uint16 latestWeek;          // packed list of latest submission weeks (see `decodeWeeks`)
                                    // !! will be changed: Week Index of the latest week submitted
        uint16[7] cache;            // Cached latest submissions (reserved)
    }

    struct Adjustment {
        uint8 power;
        int16 time;
    }

    mapping(address => Member) private _members;
    // member => week => adjustment
    mapping (address => mapping (uint16 => Adjustment)) private _adjusts;

    uint256[10] __gap;              // reserved for upgrades

    event MemberJoined(
        address indexed member,
        uint16 startWeek,
        Status status,
        uint8 weight
    );

    event MemberStatusUpdated(address indexed member, Status status);

    event TimeSubmitted(
        address indexed member,
        uint16 indexed week,
        int32 labor,                // may be negative ...
        int32 time,                 //
        bytes32 uid
    );

    event MemberWeightAssigned(
        address indexed member,
        uint8 weight,
        uint32 labor                // zero or positive
    );

    event MemberMaxWeekTimeUpdated(
        address indexed member,
        uint16 maxTimeWeekly
    );

    event LaborSettled(
        address indexed member,
        uint32 labor,
        bytes32 uid
    );

    event TimeAdjusted(
        address indexed member,
        uint16 week,
        uint8 power,
        int16 time
    );

    modifier isNotMember(address user)
    {
        require(
            _members[user].status == Status.UNKNOWN,
            "member already exists"
        );
        _;
    }

    modifier memberExists(address member)
    {
        require(
            _members[member].status != Status.UNKNOWN,
            "member does not exists"
        );
        _;
    }

    /**
    * @dev Returns whether given user is a member or not
    * @param member address of the member to be checked
    */
    function isMember(address member) external view returns(bool)
    {
        return _members[member].status != Status.UNKNOWN;
    }

    /**
    * @dev Returns status of a member
    * @param member address of the member to be checked
    * @return Status
    */
    function getMemberStatus(address member) public view returns(Status)
    {
        return _members[member].status;
    }

    /**
    * @dev Returns member weight
    * @param member User whose weight needs to be returned
    */
    function getMemberWeight(address member) public view
    memberExists(member) returns(uint8)
    {
        return _members[member].weight;
    }

    /**
    * @dev Returns total number of time worked
    * @param member Address of the member
    * @return accepted time and pending time in Time Units
    */
    function getMemberTime(address member) public view
    returns(uint32 accepted, uint32 pending)
    {
        return (_members[member].time, uint32(_members[member].pendingTime));
    }

    function getMemberLabor(address member) external view
        returns(uint32 accepted, uint32 pending)
    {
        return _getMemberLabor(member);
    }

    /**
    * @dev Returns status, weight and time for a member
    * @param member Address of the member
    * @return status <Status>
    * @return weight
    * @return maxTimeWeekly in Time Units
    * @return startWeek as Week Index
    */
    function getMemberData(address member) external view
    returns (
        Status status,
        uint8 weight,
        uint16 startWeek,
        uint16 maxTimeWeekly,
        uint16 latestWeek
    )
    {
        return (
            _members[member].status,
            _members[member].weight,
            _members[member].startWeek,
            _members[member].maxTimeWeekly,
            _members[member].latestWeek
        );
    }

    function _getMemberLabor(address member) internal view
        returns(uint32 accepted, uint32 pending)
    {
        return (
            _members[member].labor,
            uint32(_members[member].pendingTime) * _members[member].weight
        );
    }

    function _joinMember(
        address member,
        Status status,
        uint8 weight,
        uint16 startWeek,
        uint16 maxTimeWeekly
    ) internal
    isNotMember(member)
    {
        _members[member].status = status ==  Status.UNKNOWN ? Status.ACTIVE : status;
        _members[member].maxTimeWeekly = maxTimeWeekly;
        _members[member].startWeek = startWeek != 0 ? startWeek : getCurrentWeek();

        if (weight != NO_WEIGHT) {
            require(_isValidWeight(weight), "invalid weight");
            _members[member].weight = weight;
            emit MemberWeightAssigned(member, weight, 0);
        }

        emit MemberJoined(member, _members[member].startWeek, _members[member].status, weight);
    }

    function _setMemberStatus(address member, Status status) internal
    memberExists(member)
    {
        require(status != Status.UNKNOWN, "invalid status");
        require(_members[member].status != Status.OFFBOARDED, "member off-boarded");
        _members[member].status = status;
        emit MemberStatusUpdated(member, status);
    }

    function _offboardMember(address member) internal
    memberExists(member)
    {
        require(_members[member].status != Status.OFFBOARDED, "already off-boarded");
        _members[member].status = Status.OFFBOARDED;
        emit MemberStatusUpdated(member, Status.OFFBOARDED);
    }

    /**
    * @dev Set member weight. Can only be done once. Only project lead can call
    * @param member User whose weight has to be set
    * @param weight Weight of the member (factor to convert time into labor)
    * @return labor Labor Units of the member accumulated so far
    */
    function _updateMemberWeight(address member, uint8 weight, bool onceOnly) internal
    memberExists(member)
    returns (uint32 labor)
    {
        require(_members[member].status != Status.OFFBOARDED, "member off-boarded");

        require(
            onceOnly && _members[member].weight == NO_WEIGHT,
            "weight already set"
        );

        require(_isValidWeight(weight), "invalid weight");
        _members[member].weight = weight;

        if ((_members[member].time != 0) && (_members[member].weight == NO_WEIGHT)) {
            labor = _members[member].time.mul(uint32(_members[member].weight));
            _members[member].labor = _members[member].labor.add(labor);
        }

        emit MemberWeightAssigned(member, weight, labor);
    }

    /**
    * @dev Allows project lead to setup a new limit on maximum weekly labor time
    * @param maxTime uint16 maximum weekly labor time in Time Units
    */
    function _setMemberTimePerWeek(address member, uint16 maxTime) internal
    memberExists(member)
    {
        require(_members[member].status != Status.OFFBOARDED, "member off-boarded");
        require(maxTime != 0, "invalid maxTimePerWeek");
        _members[member].maxTimeWeekly = maxTime;
        emit MemberMaxWeekTimeUpdated(member, maxTime);
    }

    // @notice `time` {int32} may have negative values to cancel over-submitted time
    function _submitMemberTime(
        address member,
        uint16 week,
        int32 time,
        bytes32 uid,
        bool revertClosedAndDuplicated
    ) internal memberExists(member) returns (int32 labor)
    {
        require(
            _members[member].status == Status.ACTIVE,
            "Member is not ACTIVE!!"
        );

        require(
            time > 0
            ? (time <= _members[member].maxTimeWeekly)
            : (-time <= _members[member].maxTimeWeekly),
            "time exceeds week limit"
        );

        _members[member].latestWeek = _getUpdatedWeeksList(
            _members[member].latestWeek,
            week,
            _members[member].startWeek,
            getCurrentWeek() - 1,
            revertClosedAndDuplicated
        );

        _members[member].time = _members[member].time.addSigned(time);

        if (_members[member].weight != NO_WEIGHT) {
            labor = time * _members[member].weight; // too small to overflow
            _members[member].labor = _members[member].labor.addSigned(labor);
        }

        emit TimeSubmitted(member, week, labor, time, uid);
    }

    function _settleLabor(address member, uint32 labor, bytes32 uid) internal
    {
        _members[member].labor = _members[member].labor.sub(labor);
        emit LaborSettled(member, labor, uid);
    }

    function _isValidWeight(uint8 weight) internal pure
    returns(bool)
    {
        return weight != NO_WEIGHT && weight <= MAX_WEIGHT;
    }

    function getAdjustment(address member, uint16 week) public view
    returns (uint8 power, int16 time)
    {
        return (_adjusts[member][week].power, _adjusts[member][week].time);
    }

    function _setAdjustment(address member, uint16 week, uint8 power, int16 time)
    internal
    {
        require(power > _adjusts[member][week].power, "not enough power");

        // TODO: get pending time and age of a submission for the week
        uint16 pending = MAX_MAX_TIME_WEEKLY;
        uint8 age = 3;
        require(
            // Adjusted value can't be negative or more then max weekly time limit
            time == 0 || ( time < 0
                    ? uint16(-time) <= pending
                    : uint16(time) + pending <= _members[member].maxTimeWeekly
                ),
            "too big time"
        );
        // The Lead has power to adjust within two weeks followed by the submission
        // The Arbiter (and Quorum) - starting from the 3rd week after the submission
        require(power > LEAD_POWER ? (age > 2) : (age <= 2), "week closed");

        _adjusts[member][week].power = power;
        _adjusts[member][week].time = time;

        emit TimeAdjusted(member, week, power, time);
    }

    function _clearAdjustment(address member, uint16 week) internal
    {
        _adjusts[member][week].power = 0;
        _adjusts[member][week].time = 0;
    }
}

// TODO: optimize function params to cut gas spent on bitwise operations
