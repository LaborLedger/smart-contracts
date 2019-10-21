pragma solidity 0.5.11;

contract LaborUnitsAware
{
    /***  Labor Units
    *
    * Labor-based equity pool is distributed between members in proportion to Labor Units.
    * Labor Units calculated for every member as follows:
    *  Labor Units (of member) += Time Units (of member) * Weight (for member) * Labor Factor (on date of submission)
    * Total Labor Units of the project is the sum of members Labor Units
    *
    * (N.B.: safeMath lib is not used as expected values are too small to cause overflows)
    */

    // factor to convert hours (weighted with member weights) into labor units
    // (may be adjusted to account for project value appreciation)
    uint16 constant defaultLaborFactor = 1000;

    // factor to convert hours (weighted with member weights) into labor units
    // (may be adjusted to account for project value appreciation)
    uint16 public laborFactor = defaultLaborFactor;

    // total labor units submitted to the ledger (by all members)
    uint32 public laborUnits;

    event LaborUnits(address indexed member, uint32 units);

    event LaborUnitsCleared(address indexed member, uint32 units);

    event LaborFactorModified(uint16 newFactor);

    function timeUnitsToLaborUnits(uint32 timeUnits) public view returns(uint32) {
        return timeUnits * laborFactor;
    }

    function _setLaborFactor(uint16 _laborFactor) internal
    {
        require(_laborFactor != 0, "Invalid labor factor");
        laborFactor = _laborFactor;
        emit LaborFactorModified(_laborFactor);
    }
}
