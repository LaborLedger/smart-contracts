pragma solidity 0.5.11;

contract WeeksAware
{
    /***  Week Indexes
    *
    * Week timestamps are processed and stored as Week Indexes
    * Week Index - number of complete (Mon-Sun) ended weeks since epoch plus one
    *   - the first complete week started at 00:00:00 UTC on Monday, 5 January 1970 (UNIX Time 345600),
    *     it has WeekIndex 1
    *   - the week that started at 00:00:00 UTC on Monday, 23 September 2019 has WeekIndex 2595
    *
    * (N.B.: safeMath lib is not used as expected values are too small to cause overflows)
    */

    // Week Index of the first week of the ledger
    uint16 public startWeek;

    constructor (uint16 _startWeek) public
    {
        if (_startWeek != 0) {
            require(_startWeek <= 3130, "startWeek must start by 31-Dec-2030");
            startWeek = _startWeek;
        } else {
            startWeek = getCurrentWeek();
        }
    }

    /**
    * @dev Returns the week of the latest block
    * @return uint16 week index
    */
    function getCurrentWeek() public view returns(uint16) {
        return uint16((block.timestamp - 345600)/(7 days) + 1);
    }

    /**
    * @dev Check if a week is on a list of four weeks
    *      return unchanged list if the week is on the list
    *      otherwise replace the latest week on the list with the tested week and return the updated list
    * @param _week uint16 the tested week
    * @param _packedList uint64 the packed list of four weeks
    *        (4x uint16 are packed into the single uint64)
    * @return _updatedPackedList uint64 updated packed list of four weeks
    */
    function _testWeekAndUpdateFourWeeksList(uint16 _week, uint64 _packedList) internal pure
    returns(uint64 _updatedPackedList) {
        uint64 _weeks = _packedList;
        uint16 latestWeekFound = 0xFFFF;
        uint8 indexOfLatestWeek;

        // find the latest week in the list checking if _week is already on the list
        for (uint8 i; i < 4 && latestWeekFound != 0; i++) {
            uint16 w = uint16(_weeks & 0xFFFF);
            if (_week == w) {
                return _packedList;
            }
            if (w < latestWeekFound) {
                (latestWeekFound, indexOfLatestWeek) = (w, i);
            }
            _weeks = _weeks>>16;
        }

        // Update the list of weeks (save _week in the position of the indexOfLatestWeek)
        uint8 bits = indexOfLatestWeek * 16;
        _updatedPackedList = _packedList & ~(uint64(0xFFFF)<<bits);
        _updatedPackedList |= _week<<bits;
        return _updatedPackedList;
    }
}
