pragma solidity 0.5.11;

contract LaborLedgerStorage
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

    // @dev storage slot 0
    mapping(address => Member) internal _members;

    // @dev storage slot 1
    // sha256 of the terms of collaboration (default: sha256(<32 zero bytes>) which is 0)
    bytes32 public terms;

    // @dev storage slot 2

    // Block the contract is deployed in
    uint32 public birthBlock;

    // Week Index of the first week of the project
    uint16 public startWeek;

    // maximum time worked (expressed in Time Units) allowed for submission by a member per a week
    uint16 public maxTimePerWeek;

    // @dev uint8[4] packed into uint32 to save storage slots
    uint32 public memberWeights;

    // factor to convert hours (weighted with member weights) into labor units
    // (may be adjusted to account for project value appreciation)
    uint16 public laborFactor;

    // total submitted hours in Time Units
    uint32 public timeUnits;

    // total labor units supplied (contributed by members)
    uint32 public laborUnits;
}
