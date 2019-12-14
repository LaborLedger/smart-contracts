pragma solidity 0.5.13;

import "./lib/CollaborationAware.sol";
import "./lib/Constants.sol";
import "./lib/DelegatecallInitAware.sol";
import "./lib/Erc165Compatible.sol";
import "./lib/ProxyCallerAware.sol";
import "./lib/RolesAware.sol";
import "./lib/UnpackedInitParamsAware.sol";

contract LaborLedgerImplementation is
ProxyCallerAware,
Constants,
Erc165Compatible,
UnpackedInitParamsAware,
DelegatecallInitAware,
RolesAware,                 // @dev storage slots 0, 1 (mappings)
CollaborationAware          // @dev storage slot 2
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

    // Indexes for memberWeights array
    enum Weight {
        _,          // 0
        STANDARD,   // 1
        SENIOR,     // 2
        ADVISER     // 3
    }

    struct Member {
        Status status;
        uint8 weight;               // as a fraction of STANDARD weight
        uint16 maxTimeWeekly;       // max time allowed to submit per a week
        uint32 time;                // in Time Units
        uint32 weightedTime;        // in Time Units
        uint16[4] earliestWeeks;    // 4 earliest weeks submitted
    }

    // @dev storage slot 3
    // sha256 of the terms of collaboration (default: sha256(<32 zero bytes>) which is 0)
    bytes32 public terms;

    // @dev storage slot 4

    // block the contract is created within
    uint32 public birthBlock;

    // Equity pool measured in Share Units
    // labor-units-based pool
    uint32 public laborEquity;
    // management pool
    uint32 public managerEquity;
    // investors pool
    uint32 public investorEquity;

    // first week of the project, Week Index
    uint16 public startWeek;

    // total submitted hours in Time Units
    uint32 public totalTime;

    // submitted hours in Time Units weighted with User Weights
    uint32 public totalWeightedTime;

    // @dev storage slot 5
    // Labor time weights for _, STANDARD, SENIOR, ADVISER
    uint8[4] public memberWeights;

    // @dev storage slot 6, ...
    mapping(address => Member) private _members;

    event MemberJoined(address indexed member);

    event MemberStatusModified(address indexed member, Status status);

    // hours in Time Units
    event TimeSubmitted(
        address indexed member,
        uint16 indexed week,
        uint32 weightedTime,
        uint16[7] dailyTime
    );

    event MemberWeightAssigned(
        address indexed member,
        Weight weightIndex,
        uint32 weightedTime
    );

    event MemberTimePerWeekUpdated(
        address indexed member,
        uint16 maxTimeWeekly
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

    function () external payable {
        revert('ethers unaccepted');
    }

    /**
    * @dev "constructor" that will be delegatecall`ed on deployment of a LaborLedgerCaller
    * @param initParams <bytes> packed params for _init
    */
    function init(bytes calldata initParams) external returns(bytes4) {
        require(birthBlock == uint32(0), "contract already initialized");
        _init(initParams);
        return INIT_INTERFACE_ID;
    }

    /**
    * @param initParams <bytes> packed init params
    * @dev params packed into `bytes` (96 bytes):
    *   _collaboration <address> Collaboration contract
    *   _terms <bytes32> project terms of collaboration (default: 0)
    *   _startWeek <uint16> project first week as Week Index (default - previous week)
    *   _managerEquity <uint32> manager equity pool in Share Units (default 9000000)
    *   _investorEquity <uint32> investor equity pool in Share Units (default 0)
    *   _memberWeights <uint[4]> weights, as a fraction of the STANDARD weight
    *     default: [0, 2, 3, 4] for _ (ignored), STANDARD, SENIOR, ADVISER
    *
    *   _collaboration is the only mandatory param
    *   ... provide zero value(s) for any other param(s) to set default value(s)
    */
    function _init(bytes memory initParams) internal {
        (
            address _collaboration,
            bytes32 _terms,
            uint16 _startWeek,
            uint32 _managerEquity,
            uint32 _investorEquity,
            uint8[4] memory _weights
        ) = unpackInitParams(initParams);

        initCollaboration(_collaboration);
        initRoles();

        if (_terms != 0) {
            terms = sha256(abi.encodePacked(_terms));
        }
        if (_startWeek != 0) {
            require(_startWeek <= 3130, "startWeek can't start after 31-Dec-2030");
            startWeek = _startWeek;
        } else {
            startWeek = getCurrentWeek() - 1;
        }

        if (_managerEquity != 0 || _investorEquity != 0) {
            uint32 _laborEquity = 1000000 - _managerEquity - _investorEquity;
            _setEquity(_laborEquity, _managerEquity, _investorEquity);
        } else {
            // default laborEquity, managerEquity, investorEquity
            _setEquity(100000, 900000, 0);
        }

        if (_weights[uint8(Weight.STANDARD)] != 0) {
            memberWeights = _weights;
        } else {
            // default
            memberWeights = [
                0,  // ignored
                2,  // STANDARD
                3,  // SENIOR
                4   // ADVISER
            ];
        }
        birthBlock = uint32(block.number);
    }

    function getEquity() external view returns(
        uint32 laborEquityPool,
        uint32 managerEquityPool,
        uint32 investorEquityPool
    ) {
        return (laborEquity, managerEquity, investorEquity);
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
    * @dev Allows quorum to setup a new equity
    * It may not be greater than previous set equity
    * @param _laborEquity New labor equity pool in Share Units
    * @param _managerEquity New manager equity pool in Share Units
    * @param _investorEquity New investor equity pool in Share Units
    */
    function setEquity(
        uint32 _laborEquity,
        uint32 _managerEquity,
        uint32 _investorEquity
    ) external onlyProjectQuorum
    {
        require(
            _managerEquity <= managerEquity,
            "management equity can't increase"
        );
        _setEquity(_laborEquity, _managerEquity, _investorEquity);
    }

    /**
    * @dev Allows project lead to setup a new limit on maximum weekly labor time
    * @param maxTime uint16 maximum weekly labor time in Time Units
    */
    function setMemberTimePerWeek(address member, uint16 maxTime)
        external
        memberExists(member)
        onlyProjectLead
    {
        require(maxTime != 0, "invalid maxTimePerWeek");
        require(maxTime <= MAX_MAX_TIME_WEEKLY, "too big maxTime");
        _members[member].maxTimeWeekly = maxTime;
        emit MemberTimePerWeekUpdated(member, maxTime);
    }

    /**
    * @dev Set user weight. Can only be done once. Only project lead can call
    * @param user User whose weight has to be set
    * @param weightIndex Weight of the user (the index in memberWeights)
    */
    function setMemberWeight(
        address user,
        Weight weightIndex
    )
        external
        onlyProjectLead
        memberExists(user)
    {
        require(_members[user].weight == 0, "weight already set");
        require(weightIndex != Weight._, "invalid weightIndex");

        uint8 _weight = memberWeights[uint8(weightIndex)];
        _members[user].weight = _weight;

        uint32 weighted = _members[msg.sender].time * _weight;
        _members[msg.sender].weightedTime += weighted;
        totalWeightedTime += weighted;

        emit MemberWeightAssigned(user, weightIndex, weighted);
    }

    /**
    * @dev Returns user weight
    * @param user User whose weight needs to be returned
    */
    function getMemberWeight(address user)
        external
        view
        memberExists(user)
    returns(uint8)
    {
        return _members[user].weight;
    }

    /**
    * @dev Allows a new user to join
    * @param _terms uint256 project terms of collaboration
    */
    function join(bytes32 _terms)
        external
        senderIsNotMember
    {
        require(terms == sha256(abi.encodePacked(_terms)), "terms mismatch");
        _members[msg.sender].status = Status.ACTIVE;
        _members[msg.sender].maxTimeWeekly = DEF_MAX_TIME_WEEKLY;
        emit MemberJoined(msg.sender);
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
    function submitTime(
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
        require(week >= startWeek, "invalid week (before startWeek)");

        uint16 currentWeek = getCurrentWeek();

        require(currentWeek > week, "submission for week not yet ended");
        require(currentWeek - week <= 4, "submission closed for this week");

        // Check if week is not in four latest weeks submitted
        uint16 latestWeekFound = 0xFFFF;
        uint8 indexOfLatestWeek;
        for (uint8 i; i < 4 && latestWeekFound != 0; i++) {
            require(
                week != _members[msg.sender].earliestWeeks[i],
                "duplicated submission"
            );
            if (_members[msg.sender].earliestWeeks[i] < latestWeekFound) {
                (latestWeekFound, indexOfLatestWeek) = (_members[msg.sender].earliestWeeks[i], i);
            }
        }
        // Update list of latest weeks
        _members[msg.sender].earliestWeeks[indexOfLatestWeek] = week;

        uint32 submitted;
        for (uint8 i; i < dayHours.length; i++) {
            submitted += dayHours[i];
        }
        require(
            submitted <= _members[msg.sender].maxTimeWeekly,
            "time exceed limit"
        );

        _members[msg.sender].time += submitted;
        totalTime += submitted;

        uint32 weighted;
        if (_members[msg.sender].weight != 0) {
            weighted = submitted * _members[msg.sender].weight;
            _members[msg.sender].weightedTime += weighted;
            totalWeightedTime += weighted;
        }

        emit TimeSubmitted(
            msg.sender,
            week,
            weighted,
            dayHours
        );
    }

    /**
    * @dev Returns total number of hours worked
    * @param member Address of the member
    * @return uint32 hours in Time Units
    */
    function getMemberTime(address member)
        external
        view
        returns(uint32)
    {
        return _members[member].time;
    }

    /**
    * @dev Returns member share in weighted-hours-based equity pool
    * @param member Address of the member
    * @return uint32 equity in ShareUnits
    */
    function getMemberShare(address member)
        external
        view
        returns(uint64)
    {
        require(totalWeightedTime != 0, "no hours submitted yet");
        return uint64(laborEquity) * _members[member].weightedTime / totalWeightedTime;
    }

    /**
    * @dev Returns status, weight and time for a member
    * @param member Address of the member
    * @return status Status
    * @return _weight Weight
    * @return _time uint32 in Time Units
    * @return _weightedTime uint32 in Time Units
    */
    function getMemberData(address member)
        external
        view
        returns (
            Status status,
            uint8 weight,
            uint32 time,
            uint32 weightedTime
    )
    {
        return (
            _members[member].status,
            _members[member].weight,
            _members[member].time,
            _members[member].weightedTime
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
        uint32 _laborEquity,
        uint32 _managerEquity,
        uint32 _investorEquity
    ) internal {
        uint totalEquity = _laborEquity + _managerEquity + _investorEquity;
        require(totalEquity == 1000000, "equity must sum to 1000000 (100%)");

        laborEquity = _laborEquity;
        managerEquity = _managerEquity;
        investorEquity = _investorEquity;
        emit EquityModified(_laborEquity, _managerEquity, _investorEquity);
    }
}

// TODO: optimize function params to cut gas spent on bitwise operations
// TODO: minimize sload sstore operations
// TODO: optimize 'function submitTime' (cycles, read to memory from storage once, ...)
