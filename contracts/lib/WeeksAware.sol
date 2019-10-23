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

    // @dev "constructor" function that shall be called on the "Proxy Caller" deployment
    function initWeeks(uint16 _startWeek) internal
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
    * @param week uint16 the tested week
    * @param packedList uint64 the packed list of four weeks
    *        (4x uint16 are packed into the single uint64)
    * @return updatedPackedList uint64 updated packed list of four weeks
    */
    function _testWeekAndUpdateFourWeeksList(uint16 week, uint64 packedList) internal pure
    returns(uint64 updatedPackedList)
    {
        uint16[4] memory _weeks = [
            uint16(packedList & 0xFFFF),
            uint16((packedList>>16) & 0xFFFF),
            uint16((packedList>>32) & 0xFFFF),
            uint16((packedList>>48) & 0xFFFF)
        ];
        uint16 _oldestWeek = 0xFFFF;
        uint8 _indexOfOldestWeek;

        // find the latest week in the list checking if _week is already on the list
        for (uint8 i; i < 4 && _oldestWeek != 0; i++) {
            if (week == _weeks[i]) {
                return packedList;
            }
            if (_weeks[i] < _oldestWeek) {
                (_oldestWeek, _indexOfOldestWeek) = (_weeks[i], i);
            }
        }

        // Replace the oldest week with the new one and pack the array
        _weeks[_indexOfOldestWeek] = week;
        updatedPackedList  = uint64(_weeks[3])<<48;
        updatedPackedList |= uint64(_weeks[2])<<32;
        updatedPackedList |= uint64(_weeks[1])<<16;
        updatedPackedList |= uint64(_weeks[0]);
        return updatedPackedList;
    }
}
