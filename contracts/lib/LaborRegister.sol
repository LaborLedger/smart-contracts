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
        uint32 time;                // submitted Time Units
        uint32 labor;               // Labor Units equivalent of `time`
        uint32 settledLabor;        // Labor Units converted in tokens or paid (reserved)
        uint16 recentWeeks;         // packed list of latest submission weeks (see `decodeWeeks`)
    }

    mapping(address => Member) private _members;

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

    event MemberTimePerWeekUpdated(
        address indexed member,
        uint16 maxTimeWeekly
    );

    event LaborSettled(
        address indexed member,
        uint32 settledLabor,
        bytes32 uid
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
    * @return uint32 time in Time Units
    */
    function getMemberTime(address member) public view returns(uint32)
    {
        return _members[member].time;
    }

    function getMemberLabor(address member) external view
        returns(uint32 labor, uint32 settledLabor, uint32 netLabor)
    {
        return _getMemberLabor(member);
    }

    /**
    * @dev Returns status, weight and time for a member
    * @param member Address of the member
    * @return status <Status>
    * @return weight <uint8> as factor (not the index)
    * @return startWeek as Week Index
    */
    function getMemberData(address member) external view
    returns (
        Status status,
        uint8 weight,
        uint16 startWeek,
        uint16 recentWeeks
    )
    {
        return (
        _members[member].status,
        _members[member].weight,
        _members[member].startWeek,
        _members[member].recentWeeks
        );
    }

    function _getMemberLabor(address member) internal view
        returns(uint32 labor, uint32 settledLabor, uint32 netLabor)
    {
        return (
            _members[member].labor,
            _members[member].settledLabor,
            _members[member].labor.sub(_members[member].settledLabor)
        );
    }

    function _getMemberNetLabor(address member) internal view
        returns(uint32)
    {
        if (_members[member].labor == 0) return 0;
        return _members[member].labor.sub(_members[member].settledLabor);
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
            _members[member].weight = weight;
            emit MemberWeightAssigned(member, weight, 0);
        }

        emit MemberJoined(member, _members[member].startWeek, _members[member].status, weight);
    }

    function _setMemberStatus(address member, Status status) internal
    memberExists(member)
    {
        require(
            status != Status.UNKNOWN && status != Status.OFFBOARDED,
            "invalid status"
        );
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

        _members[member].weight = weight;

        if (_members[member].time != 0) {
            labor = _members[member].time.mul(uint32(_members[member].weight));
            _members[member].labor = _members[member].time.add(labor);
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
        emit MemberTimePerWeekUpdated(member, maxTime);
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

        _members[member].recentWeeks = _getUpdatedWeeksList(
            _members[member].recentWeeks,
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
        _members[member].settledLabor = _members[member].settledLabor.add(labor);
        require(
            _members[member].labor >= _members[member].settledLabor,
            "not enough labor units"
        );
        emit LaborSettled(member, _members[member].settledLabor, uid);
    }
}

// TODO: optimize function params to cut gas spent on bitwise operations
