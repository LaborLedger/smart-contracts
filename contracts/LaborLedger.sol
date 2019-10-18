pragma solidity 0.5.11;

import "./ProjectLeadRole.sol";
import "./WeeksAware.sol";
import "./MemberWeightAware.sol";
import "./LaborUnitsAware.sol";
import "./LaborLedgerStorage.sol";
import "./TimeUnitsAware.sol";
import "./LaborShareAware.sol";

contract LaborLedger is
    ProjectLeadRole,
    TimeUnitsAware,
    WeeksAware,
    MemberWeightAware,
    LaborUnitsAware,
    LaborShareAware,
    LaborLedgerStorage
{
    /***  Units
    *
    * Time periods (working hours) are submitted and returned in Time Units (see TimeAware.sol)
    * Week timestamps are submitted, stored and returned as Week Indexes (see WeeksAware.sol)
    * Labor-based equity pool is distributed between members in proportion to Labor Units (see LaborUnitsAware.sol)
    * The share of a member in the labor-based equity pool is measured in Share Units (see LaborShareAware.sol)
    *
    * (N.B.: safeMath lib is not used as expected values are too small to cause overflows)
    */

    event MemberAdded(address indexed member, uint16 startWeek);

    event MemberStatusModified(address indexed member, Status status);

    event TimeSubmitted(
        address indexed member,
        uint16 indexed week,
        uint16[7] weekDays
    );

    modifier senderIsNotMember(){
        require(_members[msg.sender].status == Status._, "Member already exists");
        _;
    }

    modifier memberExists(address member){
        require(_members[member].status != Status._, "Member does not exists");
        _;
    }

    /**
    * @dev Constructor, creates LaborLedger
    * @dev provide zero value(s) to input param(s) to set default value(s)
    * @param _terms uint256 project terms of collaboration (default: 0)
    * @param _startWeek uint16 project first week as Week Index (default 2595)
    */
    constructor (
        bytes32 _terms,
        uint16 _startWeek
    ) public
    {
        birthBlock = uint32(block.number);
        maxTimePerWeek = defaultMaxTimePerWeek;
        memberWeights = defaultMemberWeights;
        laborFactor = defaultLaborFactor;

        if (_terms != 0) {
            terms = sha256(abi.encodePacked(_terms));
        }
        if (_startWeek != 0) {
            require(_startWeek <= 3130, "startWeek must start by 31-Dec-2030");
            startWeek = _startWeek;
        } else {
            startWeek = getCurrentWeek();
        }
    }

    /**
    * @dev Returns whether given user is a member or not
    * @param member address of the member to be checked
    */
    function isMember(address member) external view returns(bool)
    {
        return _members[member].status != Status._;
    }

    /**
    * @dev Returns status of a member
    * @param member address of the member to be checked
    * @return Status
    */
    function getMemberStatus(address member) external view returns(Status)
    {
        return _members[member].status;
    }

    function setLaborFactor(uint16 _laborFactor) external
        onlyProjectLead
    {
        require(_laborFactor != 0, "Invalid labor factor");
        laborFactor = _laborFactor;
        emit LaborFactorModified(_laborFactor);
    }

    /**
    * @dev Allows project lead to setup a new limit on maximum weekly hours
    * @param _maxTimePerWeek uint16 maximum weekly hours in Time Units
    */
    function setMaxTimePerWeek(uint16 _maxTimePerWeek) external
        onlyProjectLead
    {
        require(_maxTimePerWeek != 0 && _maxTimePerWeek <= 2016, "invalid maxTimePerWeek");
        maxTimePerWeek = _maxTimePerWeek;
    }

    /**
    * @dev Set member weight. Once only. The project lead can call only.
    * @param user <address> Member whose weight has to be set
    * @param weightIndex <Weight> index of the user weight in memberWeights
    */
    function setMemberWeight(address user, Weight weightIndex) external
        onlyProjectLead
        memberExists(user)
    {
        require(_members[user].weight == 0, "Weight already set");

        uint8 weight = selectWeight(memberWeights, weightIndex);
        require(weight != 0, "Invalid weight index");

        _members[user].weight = weight;

        emit MemberWeightSet(user, weight);
    }

    function setMemberStatus(address member, Status status) external
        onlyProjectLead
        memberExists(member)
    {
        require(status != Status._, "Invalid status (unset)");
        require(status != Status.ONTRIAL, "ONTRIAL allowed on join only");
        require(_members[member].status != Status.OFFBOARD, "OFFBOARD can't be altered");
        if (status == Status.ACTIVE) {
            require(_members[member].status != Status.ONTRIAL, "ONTRIAL can't be set to ACTIVE");
            require(_members[member].weight != 0, "ACTIVE not allowed if weight not set");
        }

        _members[member].status = status;
        emit MemberStatusModified(member, status);
    }

    function setMemberStartWeek(address member, uint16 _startWeek) external
        onlyProjectLead
    {
        require(_members[member].startWeek == 0, 'member startWeek already set');
        require(_startWeek >= startWeek, "_startWeek precedes project startWeek");
        require(getCurrentWeek() - _startWeek <= 4, "too old startWeek");
        _members[member].startWeek = _startWeek;
    }

    /**
    * @dev Returns member weight (as a fraction of the weightDivider)
    * @param member <address> Member whose weight needs to be returned
    */
    function getMemberWeight(address member) external view
        memberExists(member)
    returns(uint8 weight, uint8 divider)
    {
        return (_members[member].weight, weightDivider);
    }

    /**
    * @dev Allows a new user (msg.sender) to join
    * @param _terms uint256 project terms of collaboration
    */
    function join(bytes32 _terms, uint16 _startWeek) external
        senderIsNotMember
    {
        require(terms == sha256(abi.encodePacked(_terms)), "Terms mismatch");

        uint16 start = _startWeek;
        if (_members[msg.sender].startWeek != 0) {
            require(_members[msg.sender].startWeek == _startWeek, "_startWeek mismatches");
        } else {
            start = getCurrentWeek();
        }
        require(start >= startWeek, "_startWeek precedes project startWeek");

        _members[msg.sender].status = Status.ONTRIAL;
        _members[msg.sender].joinBlock = uint32(block.number);
        _members[msg.sender].startWeek = start;

        emit MemberAdded(msg.sender, start);
        emit MemberStatusModified(msg.sender, Status.ONTRIAL);
    }

    /**
    * @dev Allow a member (msg.sender) to accept the weight set by the project lead
    * @param weight <uint8> for the member (msg.sender) as a fraction of weightDivider
    */
    function acceptWeight(uint8 weight) external
        memberExists(msg.sender)
    {
        require(_members[msg.sender].status == Status.ONTRIAL, "Invalid member status");
        require(_members[msg.sender].weight != 0, "Weight not yet set");
        require(_members[msg.sender].weight == weight, "Invalid weight");

        _members[msg.sender].status = Status.ACTIVE;

        if (_members[msg.sender].timeUnits != 0) {
            uint32 units = _members[msg.sender].timeUnits * weight / weightDivider * laborFactor;
            _members[msg.sender].laborUnits += units;
            laborUnits += units;
            emit LaborUnits(msg.sender, units);
        }

        emit MemberStatusModified(msg.sender, Status.ACTIVE);
        emit MemberWeightAccepted(msg.sender, weight);
    }

    /**
    * @dev Allows existing members to submit hours
    *   Submissions allowed by members only and for a week that:
    *   - has not yet been submitted
    *   - already has ended
    *   - ended no later then four weeks ago
    *   - does not precede member start week
    * @param week Week as uint16
    * @param weekDays Time worked each day in a week in Time Units
    */
    function submitTime(uint16 week, uint16[7] calldata weekDays) external
        memberExists(msg.sender)
    {
        require(
            uint8(_members[msg.sender].status) & 1 != 0,
            "Status must be ACTIVE or ONTRIAL"
        );
        require(week >= startWeek, "Week precedes project startWeek");
        require(week >= _members[msg.sender].startWeek, "Week precedes member startWeek");
        require(weekDays.length == 7, "Invalid weekDays");

        uint16 currentWeek = getCurrentWeek();

        require(currentWeek > week, "Week must be ended");
        require(currentWeek - week <= 4, "Week already closed");

        // Check if week is not in four latest weeks submitted
        uint64 updatedLatestWeeks = _testWeekAndUpdateFourWeeksList(week, _members[msg.sender].latestSubmittedWeeks);
        require(updatedLatestWeeks != _members[msg.sender].latestSubmittedWeeks, "Duplicated submission");
        _members[msg.sender].latestSubmittedWeeks = updatedLatestWeeks;

        uint16 time;
        for (uint8 i; i < 7; i++) {
            time += weekDays[i];
        }
        require(time <= maxTimePerWeek, "Time exceed limit");

        _members[msg.sender].timeUnits += time;

        uint32 labor;
        if (_members[msg.sender].status == Status.ACTIVE) {
            timeUnits += time;
            labor = time * _members[msg.sender].weight / weightDivider * laborFactor;
            _members[msg.sender].laborUnits += labor;
            laborUnits += labor;
            emit LaborUnits(msg.sender, labor);
        }
        emit TimeSubmitted(msg.sender, week, weekDays);
    }

    /**
    * @dev Returns the time member worked
    * @param member Address of the member
    * @return uint32 time in Time Units
    */
    function getMemberTimeUnits(address member) external view returns(uint32)
    {
        return _members[member].timeUnits;
    }

    /**
    * @dev Returns member share in total labor units
    * @param member Address of the member
    * @return uint32 share in Share Units
    */
    function getMemberShare(address member) external view returns(uint32)
    {
        if (laborUnits == 0) {
            return uint32(0);
        }
        return uint32( uint64(1000000) * _members[member].laborUnits / laborUnits);
    }

    /**
    * @dev Returns status, weight and timeUnits for a member
    * @param member Address of the member
    * @return joinBlock uint32 number ot the block the member joined within
    * @return status Status
    * @return weight uint8 in weightDivider(s)
    * @return timeUnits uint32 in Time Units
    * @return laborUnits uint32 in Labor Units
    */
    function getMemberData(address member) external view
    returns (
        Status status,
        uint8 weight,
        uint32 timeUnits,
        uint32 laborUnits,
        uint32 joinBlock,
        uint16 startWeek
    )
    {
        return (
        _members[member].status,
        _members[member].weight,
        _members[member].timeUnits,
        _members[member].laborUnits,
        _members[member].joinBlock,
        _members[member].startWeek
        );
    }
}

// TODO: use 'Proxy' pattern and delegateCall from 'storage' to 'logic' contract
// TODO: optimize 'function submitTime' (cycles, read to memory from storage once, ...)
// TODO: distinguish "project lead" functions (management competence) vs "DAO" functions ("pooling" competence)
// TODO: implement "mint labor units tokens" functionality
// TODO: implement ERC-20-like name, symbol, decimals, totalSupply, balanceOf methods for Labor Units

/*
function name() public view returns (string)
function symbol() public view returns (string)
function decimals() public view returns (uint8)
function balanceOf(address account) public view returns (uint256)
function totalSupply() public view returns (uint256)
*/
