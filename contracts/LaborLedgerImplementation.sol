pragma solidity 0.5.13;

// TODO: add check/revert on max values here and in imported contracts
// TODO: implement invitation logic
// TODO: implement ERC-20-like methods totalSupply and balanceOf for Labor Units, as well as name, symbol, decimals
// TODO: optimize memory/function variable types to save on gas
// TODO: optimize SLOAD usage (Istanbul update with its EIP 1884 raised SLOAD gas 4 times)
// TODO: implement "mint ERC-20 labor unit tokens" functionality (call external ERC-20 contract)

import "./lib/BirthBlockAware.sol";
import "./lib/CollaborationAware.sol";
import "./lib/Constants.sol";
import "./lib/Erc20TokenLike.sol";
import "./lib/Erc165Compatible.sol";
import "./lib/ICollaboration.sol";
import "./lib/IDelegatecallInit.sol";
import "./lib/LaborShareAware.sol";
import "./lib/LaborUnitsAware.sol";
import "./lib/LedgerStatusAware.sol";
import "./lib/MemberDataAware.sol";
import "./lib/MemberWeightAware.sol";
import "./lib/ProxyCallerAware.sol";
import "./lib/RolesAware.sol";
import "./lib/TimeUnitsAware.sol";
import "./lib/WeeksAware.sol";

contract LaborLedgerImplementation is
Constants,
IDelegatecallInit,
Erc165Compatible,
ProxyCallerAware,
RolesAware,         // @dev storage slots 0, 1 (mappings)
MemberDataAware,    // @dev storage slot 2 (mapping)
LedgerStatusAware,  // @dev storage slot 3
BirthBlockAware,
WeeksAware,
CollaborationAware,
TimeUnitsAware,     // @dev storage slot 4
MemberWeightAware,
LaborUnitsAware,
LaborShareAware,
Erc20TokenLike
{
    /***  Units
    *
    * Time periods (working hours) submitted and returned in Time Units (see TimeAwareLedger.sol)
    * Timestamps (for weeks) submitted, stored and returned as Week Indexes (see WeeksAware.sol)
    * Labor-based equity pool distributed between members in proportion to Labor Units (see LaborUnitsAware.sol)
    * The share of a member in the labor-based equity pool measured in Share Units (see LaborShareAware.sol)
    */

    event TimeSubmitted(
        address indexed member,
        uint16 indexed week,
        uint16[7] weekDays
    );

    /**
    * @dev "constructor" function that will be delegatecall`ed on deployment of the "Proxy Caller"
    * @param initParams uint256 packed params for _init
    */
    function init(uint256 initParams) external returns(bytes4) {
        require(birthBlock == uint32(0), "contract already initialized");
        address _collaboration = address(initParams >>96);
        uint16 _startWeek = uint16(initParams & 0xFFFF);
        _init(_collaboration, _startWeek);
        bytes4 result = ICollaboration(_collaboration).logLaborLedger(address(this));
        require(result == LOGLABORLEDGER__INTERFACE_ID, "LogLaborLager interface unsupported");
        return INIT_INTERFACE_ID;
    }

    /**
    * @param _collaboration address Collaboration contract
    * @param _startWeek uint16 project first week as Week Index (if 0x0 provided, set to current week)
    */
    function _init(address _collaboration, uint16 _startWeek) internal {
        initBirthBlock();
        initRoles();
        initCollaboration(_collaboration);
        initWeeks(_startWeek);
        initTimeUnits();
        initMemberWeight();
        initLaborUnits();
    }

    function _supportsInterface(bytes4 interfaceID) private pure returns (bool) {
        return  interfaceID == INIT_INTERFACE_ID;
    }

    function setLaborFactor(uint16 _laborFactor) external onlyProjectQuorum {
        _setLaborFactor(_laborFactor);
    }

    /**
    * @dev Allows project lead to setup a new limit on maximum weekly hours
    * @param _maxTimePerWeek uint16 maximum weekly hours in Time Units
    */
    function setMaxTimePerWeek(uint16 _maxTimePerWeek) external onlyProjectLead {
        _setMaxTimePerWeek(_maxTimePerWeek);
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
        require(_members[user].status == Status.ONTRIAL, "Set weight allowed for ONTRIAL only");
        _setMemberWeight(user, weightIndex);
    }

    function _setMemberWeight(address user, Weight weightIndex) private
    {
        require(_members[user].weight == 0, "Weight already set");

        uint8 weight = selectWeight(weightIndex);
        require(weight != 0, "Invalid weight index");

        _members[user].weight = weight;

        emit MemberWeightSet(user, weight);
    }

    function setMemberStatus(address member, Status status) external
        onlyProjectLead
        memberExists(member)
    {
        require(status != Status.ONTRIAL, "ONTRIAL allowed on join only");
        _setMemberStatus(member, status);
    }

    function _setMemberStatus(address member, Status status) private
    {
        require(status != Status._, "Invalid status (unset)");
        require(status != _members[member].status, "Status already set");
        require(_members[member].status != Status.OFFBOARD, "OFFBOARD can't be altered");

        if (status == Status.ACTIVE) {
            require(_members[member].weight != 0, "Weight is not yet set");
        }

        _members[member].status = status;
        emit MemberStatusModified(member, status);
    }

    function setMemberStartWeek(address member, uint16 _startWeek) external
        onlyProjectLead
    {
        _setMemberStartWeek(member, _startWeek);
    }

    function _setMemberStartWeek(address member, uint16 _startWeek) private
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
    * @dev Allows a new user (msg.sender) to join and accept startWeek, status and weight
    * @param _invite uint256 project terms of collaboration
    */
    function join(bytes32 _invite, uint16 _startWeek, Status status, Weight weight) external
        senderIsNotMember
    {
        _join(msg.sender, _invite, _startWeek, status, weight);
    }

    function _validateAndApplyInvite(bytes32 _invite, uint16 _startWeek, Status status, Weight weight) private
    {
        // TODO: realize invite logic
    }

    function _join(address member, bytes32 _invite, uint16 _startWeek, Status status, Weight weight) private
    {
        _validateAndApplyInvite(_invite, _startWeek, status, weight);

        if (_startWeek == 0) {
            _startWeek = getCurrentWeek();
        }
        _setMemberStartWeek(member, _startWeek);

        if (status == Status._) {
            status = Status.ONTRIAL;
        }
        _setMemberStatus(member, status);

        if (uint8(weight) != 0) {
            _setMemberWeight(member, weight);
        }

        _members[member].joinBlock = uint32(block.number);

        emit MemberJoined(member, _startWeek);
    }

    /**
    * @dev Allow a member on trial (msg.sender) to accept the weight set by the project lead
    * @param weight <uint8> for the member (msg.sender) as a fraction of weightDivider
    */
    function acceptWeight(uint8 weight) external
        memberExists(msg.sender)
    {
        require(_members[msg.sender].status == Status.ONTRIAL, "Accept weight allowed for ONTRIAL only");
        require(_members[msg.sender].weight != 0, "Weight not set");
        require(_members[msg.sender].weight == weight, "Weight mismatches");

        _setMemberStatus(msg.sender, Status.ACTIVE);

        if (_members[msg.sender].timeUnits != 0) {
            _countMemberLabourUnits(msg.sender, _members[msg.sender].timeUnits);
        }

        emit MemberWeightAccepted(msg.sender, weight);
    }

    function _countMemberLabourUnits(address member, uint32 _timeUnits) private {
        timeUnits += _timeUnits;
        uint32 labor = timeUnitsToLaborUnits(TimeUnitsToWeightedTimeUnits(_timeUnits, _members[member].weight));
        _members[member].laborUnits += labor;
        laborUnits += labor;
        emit LaborUnits(member, labor);
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
        require(time <= maxTimePerWeek, "Time exceeds limit");

        _members[msg.sender].timeUnits += time;

        if (_members[msg.sender].status == Status.ACTIVE) {
            _countMemberLabourUnits(msg.sender, time);
        }
        emit TimeSubmitted(msg.sender, week, weekDays);
    }

    /**
    * @dev Returns member share in total labor units
    * @param member Address of the member
    * @return uint32 share in Share Units
    */
    function getMemberShare(address member) external view returns(uint32) {
        return laborUnitsToShareUnits(_members[member].laborUnits, laborUnits);
    }
}
