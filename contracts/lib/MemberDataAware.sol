pragma solidity 0.5.11;

contract MemberDataAware
{

    enum Status {
        _,          // 0 (treated as "member does not exist")
        ACTIVE,     // 1
        ONHOLD,     // 2
        ONTRIAL,    // 3
        OFFBOARD    // 4
        // @dev: bitwise operations depend on enum options order and number
    }

    struct Member {
        Status status;
        uint8 weight;           // as a fraction of weightDivider
        uint32 joinBlock;
        uint16 startWeek;
        uint32 timeUnits;
        uint32 laborUnits;
        // Week Indexes of the four latest weeks submitted
        // @dev uint16[4] packed into uint64 to save storage slots
        uint64 latestSubmittedWeeks;
    }

    // @dev see dev notes in ProxyCallerAware.sol before (re-)moving the mapping
    mapping(address => Member) internal _members;

    event MemberJoined(address indexed member, uint16 startWeek);

    event MemberStatusModified(address indexed member, Status status);

    modifier senderIsNotMember() {
        require(_members[msg.sender].status == Status._, "Member already exists");
        _;
    }

    modifier memberExists(address member) {
        require(_members[member].status != Status._, "Member does not exists");
        _;
    }

    /**
    * @dev Returns whether given user is a member or not
    * @param member address of the member to be checked
    */
    function isMember(address member) external view returns(bool) {
        return _members[member].status != Status._;
    }

    /**
    * @dev Returns status of a member
    * @param member address of the member to be checked
    * @return Status
    */
    function getMemberStatus(address member) external view returns(Status) {
        return _members[member].status;
    }

    /**
    * @dev Returns the time member worked
    * @param member Address of the member
    * @return uint32 time in Time Units
    */
    function getMemberTimeUnits(address member) external view returns(uint32) {
        return _members[member].timeUnits;
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
