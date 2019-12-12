pragma solidity 0.5.13;

contract LaborShareAware {
    /*** Labor Share
    * The share of a member in the labor-based equity pool returned in Share Units
    * 100% of the equity pool = 1,000,000 Share Unit
    */

    function laborUnitsToShareUnits(uint32 laborUnits, uint32 totalLaborUnits) public pure returns(uint32)
    {
        if (laborUnits == 0) {
            require(totalLaborUnits == 0, "Invalid total labor units");
            return uint32(0);
        }
        return uint32( uint64(1000000) * laborUnits / totalLaborUnits);
    }
}
