pragma solidity 0.5.11;

import "./ProjectLeadRole.sol";


contract Prototype is ProjectLeadRole
{
    /***  Units and Week Indexes
    *
    * All submitted, stored and returned working hours are measured in Time Units
    * 1 Time Unit = 300 seconds
    * (N.B.: safeMath lib is not used as expected values are too small to cause overflows)
    *
    * Equity submitted, stored and returned in Share Units
    * 100% = 1,000,000 Share Unit
    *
    * Weeks are submitted, stored and returned as Week Indexes
    * Week Index - number of complete (Mon-Sun) ended weeks since epoch plus one
    *   - the first complete week started at 00:00:00 UTC on Monday, 5 January 1970 (UNIX Time 345600),
    *     it has WeekIndex 1
    *   - the week that started at 00:00:00 UTC on Monday, 23 September 2019 has WeekIndex 2595
    */

    enum Status {
        _,          // 0
        ACTIVE,     // 1
        ONHOLD      // 2
    }
    // Indexes for _memberWeights array
    enum Weight {
        _,          // 0
        STANDARD,   // 1
        SENIOR,     // 2
        ADVISER     // 3
    }

    struct Member {
        Status status;
        Weight weight;
        uint32 submittedHours;
        // Week Indexes of four latest submitted weeks
        uint16[4] lastSubmittedWeeks;
    }

    // @dev storage slot 1
    // sha256 of the terms of collaboration (default: sha256(<32 zero bytes>) which is 0)
    bytes32 private _terms;

    // @dev storage slot 2

    // Equity pool measured in Share Units
    // weighted-hour-based pool (default: 10%)
    uint32 private _laborEquity = 100000;
    // management pool (default: 90%)
    uint32 private _managerEquity = 900000;
    // investors pool (default: 0%)
    uint32 private _investorEquity;

    // block the contract is created within
    uint32 public birthBlock;

    // first week of the project, Week Index
    uint16 private _startWeek;

    // maximum hours in Time Units allowed for submission by a member per a week
    uint16 private _maxHoursPerWeek = 55 hours / 5 minutes;

    // total submitted hours in Time Units
    uint32 private _submittedHours;

    // submitted hours in Time Units weighted with User Weights
    uint32 private _submittedWeightedHours;

    // @dev storage slot 3
    // Working hours weights for _, STANDARD, SENIOR, ADVISER as a fraction of STANDARD (default: 0, 2/2, 3/2, 4/2)
    uint8[4] private _memberWeights = [
        0,  // ignored
        2,  // STANDARD
        3,  // SENIOR
        4   // ADVISER
    ];

    // @dev storage slot 4, ...
    mapping(address => Member) private _members;

    event MemberAdded(address indexed member);

    event MemberStatusModified(address indexed member, Status status);

    // hours in Time Units
    event HoursSubmitted(
        address indexed member,
        uint16 indexed week,
        uint16 weightedHours,
        uint16[7] dailyHours
    );

    event MemberWeightAdded(
        address indexed user,
        Weight indexed weight,
        uint32 weightedHours
    );

    // in Share Units
    event EquityModified(
        uint32 newLaborEquity,
        uint32 newManagerEquity,
        uint32 newInvestorEquity
    );


    modifier senderIsNotMember(){
        require(
            _members[msg.sender].status == Status._,
            "member already exists"
        );
        _;
    }

    modifier memberExists(address member){
        require(
            _members[member].status != Status._,
            "member does not exists"
        );
        _;
    }

    /**
    * @dev Constructor, creates Prototype
    * @dev provide zero value(s) to input param(s) to set default value(s)
    * @param terms uint256 project terms of collaboration (default: 0)
    * @param startWeek uint16 project first week as Week Index (default 2595)
    * @param laborEquity labor equity pool in Share Units
    * @param managerEquity manager equity pool in Share Units
    * @param investorEquity investor equity pool in Share Units
    * @param memberWeights uint[4] weights, as a fraction of STANDARD weight
    *  default: [0, 2, 3, 4] for _ (ignored), STANDARD, SENIOR, ADVISER
    */
    constructor (
        bytes32 terms,
        uint16 startWeek,
        uint32 laborEquity,
        uint32 managerEquity,
        uint32 investorEquity,
        uint8[4] memory memberWeights
    ) public {
        if (terms != 0) {
            _terms = sha256(abi.encodePacked(terms));
        }
        if (startWeek != 0) {
            require(startWeek <= 3130, "startWeek can't start after 31-Dec-2030");
            _startWeek = startWeek;
        } else {
            _startWeek = getCurrentWeek() - 1;
        }

        if (laborEquity != 0 || managerEquity != 0 || investorEquity != 0) {
            _setEquity(laborEquity, managerEquity, investorEquity);
        }

        if (memberWeights[uint8(Weight.STANDARD)] != 0) {
            _memberWeights = memberWeights;
        }

        birthBlock = uint32(block.number);
    }

    function getTerms() external view returns(bytes32) {
        return _terms;
    }

    function getEquity() external view
    returns(uint32 laborEquity, uint32 managerEquity, uint32 investorEquity)
    {
        return (_laborEquity, _managerEquity, _investorEquity);
    }

    function getStartWeek() external view returns (uint16) {
        return _startWeek;
    }

    function getSubmittedHours() external view returns(uint32) {
        return _submittedHours;
    }

    function getSubmittedWeightedHours() external view returns(uint32) {
        return _submittedWeightedHours;
    }

    function getMaxHoursPerWeek() external view returns (uint16) {
        return _maxHoursPerWeek;
    }

    function getMemberWeights() external view returns (uint8[4] memory) {
        return _memberWeights;
    }

    /**
    * @dev Returns whether given user is a member or not
    * @param member address of the member to be checked
    */
    function isMember(address member) external view returns(bool){
        return _members[member].status != Status._;
    }

    /**
    * @dev Returns status of a member
    * @param member address of the member to be checked
    * @return Status
    */
    function getMemberStatus(address member) external view returns(Status){
        return _members[member].status;
    }

    /**
    * @dev Allows owner of the contract to setup a new equity
    * It may not be greater than previous set equity
    * @param laborEquity New labor equity pool in Share Units
    * @param managerEquity New manager equity pool in Share Units
    * @param investorEquity New investor equity pool in Share Units
    */
    function setEquity(
        uint32 laborEquity,
        uint32 managerEquity,
        uint32 investorEquity
    ) external onlyProjectLead
    {
        _setEquity(laborEquity, managerEquity, investorEquity);
    }

    /**
    * @dev Allows project lead to setup a new limit on maximum weekly hours
    * @param maxHoursPerWeek uint16 maximum weekly hours in Time Units
    */
    function setMaxHoursPerWeek(uint16 maxHoursPerWeek)
        external
        onlyProjectLead
    {
        require(maxHoursPerWeek != 0, "invalid maxHoursPerWeek");
        require(maxHoursPerWeek <= 2016, "too big maxHoursPerWeek");
        _maxHoursPerWeek = maxHoursPerWeek;
    }

    /**
    * @dev Set user weight. Can only be done once. Only project lead can call
    * @param user User whose weight has to be set
    * @param weight Weight of the user
    */
    function setMemberWeight(
        address user,
        Weight weight
    )
        external
        onlyProjectLead
        memberExists(user)
    {
        require(_members[user].weight == Weight._, "weight already set");
        _members[user].weight = weight;

        uint32 weightedHours = _members[user].submittedHours * _memberWeights[uint8(weight)] / _memberWeights[uint8(Weight.STANDARD)];
        _submittedWeightedHours += weightedHours;

        emit MemberWeightAdded(user, weight, weightedHours);
    }

    /**
    * @dev Returns user weight
    * @param user User whose weight needs to be returned
    */
    function getUserWeight(address user)
        external
        view
        memberExists(user)
    returns(Weight)
    {
        return _members[user].weight;
    }

    /**
    * @dev Allows a new user to join
    * @param terms uint256 project terms of collaboration
    */
    function join(bytes32 terms)
        external
        senderIsNotMember
    {
        require(_terms == sha256(abi.encodePacked(terms)), "terms mismatch");
        _members[msg.sender].status = Status.ACTIVE;
        emit MemberAdded(msg.sender);
    }

    function setMemberStatus(
        address member,
        Status status
    )
        external
        onlyProjectLead
        memberExists(member)
    {
        require(status != Status._, "invalid status");
        _members[member].status = status;
        emit MemberStatusModified(member, status);
    }

    /**
    * @dev Allows existing members to submit hours
    *   Submissions allowed by members only and for a week that:
    *   - has not yet been submitted
    *   - already has ended
    *   - ended no later then four weeks ago
    * @param week Week as uint16
    * @param dayHours Time worked each day in a week in Time Units
    */
    function submitHours(
        uint16 week,
        uint16[7] calldata dayHours
    )
        external
        memberExists(msg.sender)
    {
        require(
            _members[msg.sender].status != Status.ONHOLD,
            "Member is on hold!!"
        );
        require(dayHours.length == 7, "invalid dayHours");
        require(week >= _startWeek, "invalid week (before startWeek)");

        uint16 currentWeek = getCurrentWeek();

        require(currentWeek > week, "submission for week not yet ended");
        require(currentWeek - week <= 4, "submission closed for this week");

        // Check if week is not in four latest weeks submitted
        uint16 latestWeekFound = 0xFFFF;
        uint8 indexOfLatestWeek;
        for (uint8 i; i < 4 && latestWeekFound != 0; i++) {
            require(
                week != _members[msg.sender].lastSubmittedWeeks[i],
                "duplicated submission"
            );
            if (_members[msg.sender].lastSubmittedWeeks[i] < latestWeekFound) {
                (latestWeekFound, indexOfLatestWeek) = (_members[msg.sender].lastSubmittedWeeks[i], i);
            }
        }
        // Update list of latest weeks
        _members[msg.sender].lastSubmittedWeeks[indexOfLatestWeek] = week;

        uint16 weekHours;
        for (uint8 i; i < dayHours.length; i++) {
            weekHours += dayHours[i];
        }
        require(weekHours <= _maxHoursPerWeek, "hours exceed limit");

        _members[msg.sender].submittedHours += weekHours;
        uint16 weightedHours = weekHours * _memberWeights[uint8(_members[msg.sender].weight)] / _memberWeights[uint8(Weight.STANDARD)];
        _submittedHours += weekHours;
        _submittedWeightedHours += weightedHours;

        emit HoursSubmitted(
            msg.sender,
            week,
            weightedHours,
            dayHours
        );
    }

    /**
    * @dev Returns total number of hours worked
    * @param member Address of the member
    * @return uint32 hours in Time Units
    */
    function getSubmittedHours(address member)
        external
        view
        returns(uint32)
    {
        return _members[member].submittedHours;
    }

    /**
    * @dev Returns member share in weighted-hours-based equity pool
    * @param member Address of the member
    * @return uint32 equity in ShareUnits
    */
    function getMemberEquity(address member)
        external
        view
        returns(uint64)
    {
        uint32 memberWeightedHours = _members[member].submittedHours * _memberWeights[uint8(_members[member].weight)] / _memberWeights[uint8(Weight.STANDARD)];
        return uint64(_laborEquity) * memberWeightedHours / _submittedWeightedHours;
    }

    /**
    * @dev Returns status, weight and submittedHours for a member
    * @param member Address of the member
    * @return status Status
    * @return weight Weight
    * @return submittedHours uint32 in Time Units
    */
    function getMemberData(address member)
        external
        view
        returns (
            Status status,
            Weight weight,
            uint32 submittedHours
    )
    {
        return (
            _members[member].status,
            _members[member].weight,
            _members[member].submittedHours
        );
    }

    /**
    * @dev Returns the week of the latest block
    * @return uint16 week index
    */
    function getCurrentWeek() public view returns(uint16) {
        return uint16((block.timestamp - 345600)/(7 days) + 1);
    }

    function _setEquity(
        uint32 laborEquity,
        uint32 managerEquity,
        uint32 investorEquity
    ) internal {
        require(
            managerEquity <= _managerEquity,
            "management equity can't increase"
        );

        uint totalEquity = laborEquity + managerEquity + investorEquity;
        require(totalEquity == 1000000, "equity must sum to 1000000 (100%)");

        _laborEquity = laborEquity;
        _managerEquity = managerEquity;
        _investorEquity = investorEquity;
        emit EquityModified(laborEquity, managerEquity, investorEquity);
    }
}

// TODO: optimize 'function submitHours' (cycles, read to memory from storage once, ...)
// TODO: use 'Proxy' pattern and delegateCall from 'storage' to 'logic' contract
