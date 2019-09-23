pragma solidity 0.5.11;

import "./ProjectLeadRole.sol";


contract Prototype is ProjectLeadRole
{
    enum Weight {_, STANDARD, SENIOR, ADVISOR}
    enum Status { _, TRIAL, ACTIVE }

    struct Member {
        Status status;
        Weight weight;
        // in 300 second units
        uint32 submittedHours;
    }

    // terms of collaboration (keccak256-hash)
    uint256 private _terms;
    // weighted-hour-based equity pool, in basis points (0.01%)
    uint16 private _equity = 8000;
    // total submitted hours, in 300 second units
    uint32 private _submittedHours;
    // total weighted submitted hours, in 300 second units
    uint32 private _submittedWeightedHours;

    mapping(address => Member) private _members;

    event HoursSubmitted(
        address indexed member,
        uint8 indexed week,
        uint16[7] dailyHours
    );
    event UserWeightAdded(address indexed user, Weight indexed weight);
    // in basis points (0.01%)
    event EquityModified(uint16 indexed newEquity);

    modifier memberDoesNotExist(){
        require(!_members[msg.sender], "Member already exists!!");
        _;
    }

    modifier memberExist(address member){
        require(_members[member], "Member does not exists!!");
        _;
    }

    function getTerms() external view returns(uint256) {
        return _terms;
    }

    function getEquity() external view returns(uint16) {
        return _equity;
    }

    function getSubmittedHours() external view returns(uint32) {
        return _submittedHours;
    }

    function getSubmittedWeightedHours() external view returns(uint32) {
        return _submittedWeightedHours;
    }

    /**
    * @dev Returns whether given user is a member or not
    * @param member address of the member to be checked
    */
    function isMember(address member) external view returns(bool){
        return _members[member];
    }

    /**
    * @dev Allows owner of the contract to setup a new equity
    * It may not be greater than previous set equity
    * @param equity New equity in basis points (0.01%)
    */
    function setEquity(uint16 equity) external onlyProjectLead {
        require(equity < _equity, "Greater than existing equity!!");
        _equity = equity;
        emit EquityModified(equity);
    }

    /**
    * @dev Set user weight. Can only be done once. Only project lead can call this
    * @param user User whose weight has to be set
    * @param weight Weight of the user
    */
    function setUserWeight(
        address user,
        Weight weight
    )
        external
        onlyProjectLead
        memberExist(user)
    {
        require(
            _members[user][weight] == Weight._,
            "Weight already set for the user!!"
        );

        _members[user][weight] = weight;

        emit UserWeightAdded(user, weight);
    }

    /**
    * @dev Returns user weight
    * @param user User whose weight needs to be returned
    */
    function getUserWeight(address user) external view memberExist(user) returns(Weight) {
        return _members[user][weight];
    }

    /**
    * @dev Allows a new user to join
    */
    function join(uint256 terms, Status status) external memberDoesNotExist{
        require(_terms == terms, "Collaboration terms mismatch");
        _members[msg.sender][status] = status;
        emit MemberAdded(msg.sender);
    }

    /**
    * @dev Allows existing members to submit hours
    * @param week Week as uint8
    * @param dayHours Time worked each day in a week, in 300 second units
    */
    function submitHours(
        uint8 week,
        uint16[7] calldata dayHours
    )
        external
        memberExist(msg.sender)
    {
        require(_userWeights[msg.sender] != Weight._, "User weight not set!!");
        require(
            _submittedHours[msg.sender][week].length == 0,
            "Already submitted for the week!!"
        );

        require(dayHours.length == 7, "Invalid hours provided!!");
        uint256 totalSubmittedHours = 0;

        for (uint256 i = 0; i < dayHours.length; i++) {
            _submittedHours[msg.sender][week].push(dayHours[i]);
            totalSubmittedHours = totalSubmittedHours + 1;
        }
        require(
            totalSubmittedHours <= 55,
            "Total submitted houres greater than 55!!"
        );

        emit HoursSubmitted(msg.sender, week);
    }

    /**
    * @dev Returns total number of hours worked in a week by a member
    * @param memberAddress Address of the member
    * @param week bytes32 version of the week
    */
    function getTotalHours(
        address memberAddress,
        bytes32 week
    )
        external
        view
        returns(uint256 sumHours)
    {
        for (
            uint256 i = 0; i < _submittedHours[memberAddress][week].length; i++
        )
        {
            sumHours = sumHours + _submittedHours[memberAddress][week][i];
        }
        return sumHours;
    }

    /**
    * @dev Returns each day hour for a given week for a member
    * @param memberAddress Address of the member
    * @param week bytes32 version of the week
    */
    function getDayHours(
        address memberAddress,
        bytes32 week
    )
        external
        view
        returns(uint256[] memory dayHours)
    {
        dayHours = new uint256[](7);

        for (
            uint256 i = 0; i < _submittedHours[memberAddress][week].length; i++
        )
        {
            dayHours[i] = _submittedHours[memberAddress][week][i];
        }
        return dayHours;
    }
}

// return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
