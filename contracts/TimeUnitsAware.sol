pragma solidity 0.5.11;

contract TimeUnitsAware
{

    /***  Time units
    *
    * Time periods are stored and processed in Time Units
    * 1 Time Unit = 300 seconds
    */

    uint24 constant secondsInTimeUnit = 300;
    uint16 constant defaultMaxTimePerWeek = uint16(55 hours / secondsInTimeUnit);

//    function HoursToTimeUnits(uint256 _hours) public pure returns(uint256) {
//        return _hours * 300;
//    }
//
//    function TimeUnitsToHours() public pure returns() {
//
//    }
}
