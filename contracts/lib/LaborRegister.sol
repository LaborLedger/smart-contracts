pragma solidity 0.5.13;

import "./AdjustableSubmissions.sol";
import "./Constants.sol";
import "./SafeMath32.sol";
import "./Weeks.sol";
import "./WeeklySubmissions.sol";

contract LaborRegister is Constants, Weeks, AdjustableSubmissions
{
    /**
    * @dev "Labor Units"
    * "Labor Units" are Time Units weighted with the "weight" factor for a member
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
        uint16 pendingTime;         // not yet accepted submitted Time Units
        uint16[8] cache;            // Cached latest submissions
    }

    mapping(address => Member) private _members;

    uint256[10] __gap;              // reserved for upgrades

    event MemberJoined(
        address indexed member,
        uint16 startWeek,
        Status status
    );

    event MemberStatusUpdated(address indexed member, Status status);

    event MemberWeightAssigned(
        address indexed member,
        uint8 weight
    );

    event MemberMaxWeekTimeUpdated(
        address indexed member,
        uint16 maxTimeWeekly
    );

    event TimeSubmitted(
        address indexed member,
        uint16 indexed week,
        uint32 labor,
        uint32 time,
        bytes32 uid
    );

    event TimeAccepted(
        address indexed member,
        uint16 indexed week,
        uint32 labor
    );

    event LaborAccepted(
        address indexed member,
        uint32 labor
    );

    event LaborSettled(
        address indexed member,
        uint32 labor,
        bytes32 uid
    );

    modifier isNotMember(address user)
    {
        require(
            _members[user].status == Status.UNKNOWN,
            "member exists"
        );
        _;
    }

    modifier memberExists(address member)
    {
        require(
            _members[member].status != Status.UNKNOWN,
            "unknown member"
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

    /**
     * Get latest (cached) submissions of a member
     * @param member - member address
     * @return pending - sum of Time Units not yet "aged"
     * @return times - Time Units submitted with last seven submissions
     * @return forWeeks - Week Index of the weeks the Time Units were submitted for
     * @return onWeeks - Week Index of the weeks the Time Units were submitted on
     * @return areAged - `true` if a submission has been "aged"
     */
    function getLastSubmissions(address member) public view memberExists(member)
    returns (
        uint16 pending,
        uint16[7] memory times,
        uint16[7] memory forWeeks,
        uint16[7] memory onWeeks,
        bool[7] memory areAged
    ) {
        return _extractSubmissions(_members[member].cache);
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
        uint16 maxTimeWeekly
    )
    {
        return (
            _members[member].status,
            _members[member].weight,
            _members[member].startWeek,
            _members[member].maxTimeWeekly
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
            emit MemberWeightAssigned(member, weight);
        }

        emit MemberJoined(member, _members[member].startWeek, _members[member].status);
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
    memberExists(member) returns (
        uint32 acceptedLabor,
        uint32 pendingLaborBefore,
        uint32 pendingLaborAfter
    ) {
        Member memory _member = _members[member];
        require(_member.status != Status.UNKNOWN, "unknown member");

        require(
            _member.status != Status.OFFBOARDED, "member off-boarded"
        );
        require(
            !onceOnly || _member.weight == NO_WEIGHT, "weight already set"
        );
        require(_isValidWeight(weight), "invalid weight");

        if (onceOnly && _member.time != 0) {
            acceptedLabor = _member.time.mul(uint32(weight));
            _member.labor = _member.labor.add(acceptedLabor);
            emit LaborAccepted(member, acceptedLabor);
        }
        if (!onceOnly && _member.weight == NO_WEIGHT) {
            (uint16 pendingTime, , , , ) = _extractSubmissions(_member.cache);
            pendingLaborBefore = uint32(pendingTime).mul(_member.weight);
            pendingLaborAfter = uint32(pendingTime).mul(weight);
        }

        _member.weight = weight;
        _members[member] = _member;
        emit MemberWeightAssigned(member, weight);
    }

    /**
    * @dev Allows project lead to setup a new limit on maximum weekly time
    * @param maxTime uint16 maximum weekly time in Time Units
    */
    function _setMemberTimePerWeek(address member, uint16 maxTime) internal
    memberExists(member)
    {
        require(
            _members[member].status != Status.OFFBOARDED, "member off-boarded"
        );
        require(
            maxTime != 0 && maxTime <= MAX_MAX_TIME_WEEKLY, "invalid maxTimePerWeek"
        );
        _members[member].maxTimeWeekly = maxTime;
        emit MemberMaxWeekTimeUpdated(member, maxTime);
    }

    function _adjustMemberTime(address member, uint16 forWeek, uint8 power, uint16 decrease)
    internal
    {
        Member memory _member = _members[member];
        require(_member.status != Status.UNKNOWN, "unknown member");

        _setAdjustment(member, forWeek, power, decrease, _member.cache);
    }

    struct SubmResults {
        uint32 acceptedTime;
        uint32 acceptedLabor;
        uint32 deniedTime;
        uint32 deniedLabor;
        uint32 newPendingTime;
        uint32 newPendingLabor;
    }

    function _submitAndAgeMemberTime(
        address member,
        uint16 week,
        uint32 newTime,
        bytes32 uid,
        bool skipAging,
        SubmResults memory results
    ) internal {
        uint16[7] memory agedValues;
        uint16[7] memory agedWeeks;

        Member memory _member = _members[member];
        require(_member.status != Status.UNKNOWN, "unknown member");
        // newLabor = 0;

        if (newTime == 0) {
            // zero time submission needs aging only
            (_member.cache, agedValues, agedWeeks) = _doAging(
                _member.cache, _member.cache[0], getCurrentWeek()
            );
        } else {
            require(
                newTime <= MAX_MAX_TIME_WEEKLY && newTime <= _member.maxTimeWeekly,
                "time exceeds limit"
            );
            uint32 newLabor = newTime.mul(_member.weight);
            emit TimeSubmitted(member, week, newLabor, newTime, uid);

            if (skipAging) {
                require(_isAgedWeek(week, getCurrentWeek()), "not aged week");
                require(_member.status != Status.OFFBOARDED, "member off-boarded");
                agedValues[0] = uint16(newTime);
                agedWeeks[0] = week;
            } else {
                require(_member.status == Status.ACTIVE, "member inactive");

                (_member.cache, agedValues, agedWeeks) = _cacheSubmission(
                    _member.cache, uint16(newTime), week, getCurrentWeek()
                );
                results.newPendingTime = newTime;
                results.newPendingLabor = newLabor;
            }
        }

        _accountAgedWeeks(member, _member, agedValues, agedWeeks, results);
        _members[member] = _member;
    }

    function _accountAgedWeeks(
        address member,
        Member memory _member,
        uint16[7] memory agedValues,
        uint16[7] memory agedWeeks,
        SubmResults memory results
    ) internal {
        uint16 aged;
        uint16 accepted;
        for (uint i = 0; i <= 7 && agedValues[i] != 0; i++ ) {
            // values are too small to overflow
            aged += agedValues[i];
            uint16 adjusted = _useAdjustment(member, agedWeeks[i], agedValues[i]);
            emit TimeAccepted(member, agedWeeks[i], adjusted);
            accepted += adjusted;
        }

        if (accepted > 0) {
            results.acceptedTime = uint32(accepted);
            _member.time = _member.time.add(results.acceptedTime);
            _member.pendingTime -= aged;

            if (_member.weight != NO_WEIGHT) {
                results.acceptedLabor = results.acceptedTime.sub(uint32(_member.weight));
                _member.labor = _member.labor.add(results.acceptedLabor);
                emit LaborAccepted(member, results.acceptedLabor);
            }
        }

        if (aged != accepted) {
            results.deniedTime = uint32(aged).sub(uint32(accepted));
            results.deniedLabor = results.deniedTime.sub(uint32(_member.weight));
        }
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
}

// TODO: optimize function params to cut gas spent on bitwise operations
