pragma solidity 0.5.13;

contract MemberWeightAware
{
    /***  Member weights
    *
    * Labor-based equity pool is distributed between members in proportion to Labor Units.
    * Labor Units calculated for every member as follows:
    *  Labor Units (of member) += Time Units (of member) * Weight (for member) * Labor Factor (on date of submission)
    *
    * (N.B.: safeMath lib is not used as expected values are too small to cause overflows)
    */

    // Indexes for memberWeights
    enum Weight {
        STANDARD,   // 0
        SENIOR,     // 1
        ADVISER,    // 2
        reserved    // 3
    }

    // to let the weights be fractional if needed (e.g. 1.5 = 48/32)
    uint8 constant weightDivider = 32;

    // @dev uint8[4] packed into uint32 to save storage slots
    // 1 = 32/32, 1.5 = 48/32 and 2 = 64/32 for STANDARD, SENIOR and ADVISER
    uint32 constant defaultMemberWeights = 32 * 1 + 48 * 256 + 64 * (256 * 256);

    // @dev uint8[4] packed into uint32 to save storage slots
    uint32 public memberWeights;

    event MemberWeightSet(address indexed member, uint8 weight);

    event MemberWeightAccepted(address indexed user, uint8 weight);

    // @dev "constructor" function that shall be called on the "Proxy Caller" deployment
    function initMemberWeight() internal {
        memberWeights = defaultMemberWeights;
    }

    function TimeUnitsToWeightedTimeUnits(uint32 timeUnits, uint8 weight) public pure returns(uint32) {
        return timeUnits * weight / weightDivider;
    }

    function _packWeights(uint8[4] memory weights) internal pure returns(uint32) {
        return uint32(weights[0]) | uint32(weights[1])<<8 | uint32(weights[2])<<16 | uint32(weights[3])<<24;
    }

    function selectWeight(Weight _weightIndex) internal view returns(uint8) {
        uint8 bits = uint8(_weightIndex) * 8;
        return uint8(memberWeights>>bits & 0xFF);
    }
}
