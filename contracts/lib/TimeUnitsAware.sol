pragma solidity 0.5.11;

contract TimeUnitsAware
{

    /***  Time units
    * Time periods are stored and processed in Time Units
    */

    // 1 Time Unit = 300 seconds
    uint24 constant secondsInTimeUnit = 300;
    uint24 constant unitsInHour = 12;
    uint16 constant defaultMaxTimePerWeek = uint16(55 hours / secondsInTimeUnit);

    // maximum time worked (expressed in Time Units) allowed for submission by a member per a week
    uint16 public maxTimePerWeek = defaultMaxTimePerWeek;

    // total working hours in Time Units submitted to the ledger (by all members)
    uint32 public timeUnits;

    function _setMaxTimePerWeek(uint16 _maxTimePerWeek) internal
    {
        require(_maxTimePerWeek != 0 && _maxTimePerWeek <= 2016, "invalid maxTimePerWeek");
        maxTimePerWeek = _maxTimePerWeek;
    }

    //    function HoursToTimeUnits(uint32 _hours) public pure returns(uint32) {
//        return _hours * unitsInHour;
//    }
//
//    function SecondsToTimeUnits(uint32 _units) public pure returns(uint32) {
//    }
//
//    function TimeUnitsToHours(uint32 _units) public pure returns(uint32) {
//    }
//
//    function TimeUnitsToSeconds(uint32 _units) public pure returns(uint32) {
//    }
}
