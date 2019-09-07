pragma solidity 0.5.11;

import "./ProjectLeadRole.sol";


contract Prototype is ProjectLeadRole
{
    enum Weight {_, STANDARD, SENIOR, ADVISOR}
    //Mapping of whether member exists or not
    mapping(address => bool) private _members;

    mapping(address => mapping(bytes32 => uint256[])) private _submittedHours;

    mapping(address => Weight) private _userWeights;

    event MemberAdded(address indexed member);
    event HoursSubmitted(
        address indexed member,
        bytes32 indexed week
    );
    event UserWeightAdded(address indexed user, Weight indexed weight);

    modifier memberDoesNotExist(){
        require(!_members[msg.sender], "Member already exists!!");
        _;
    }

    modifier memberExist(address member){
        require(_members[member], "Member does not exists!!");
        _;
    }

    /**
    * @dev Returns whether given user is a member or not
    * @param member address of the member to be checked
    */
    function isMember(address member) external view returns(bool){
        return _members[member];
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
            _userWeights[user] == Weight._,
            "Weight already set for the user!!"
        );

        _userWeights[user] = weight;

        emit UserWeightAdded(user, weight);
    }

    /**
    * @dev Returns user weight
    * @param user User whose weight needs to be returned
    */
    function getUserWeight(address user) external view returns(Weight) {
        return _userWeights[user];
    }

    /**
    * @dev Allows a new user to join
    */
    function join() external memberDoesNotExist{
        _members[msg.sender] = true;

        emit MemberAdded(msg.sender);
    }

    /**
    * @dev Allows existing members to submit hours
    * @param week Week in bytes32 format
    * @param dayHours Number of hours worked each day in a week
    */
    function submitHours(
        bytes32 week,
        uint[7] calldata dayHours
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
