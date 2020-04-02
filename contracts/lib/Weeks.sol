pragma solidity 0.5.13;

/**
 * @dev "Week Index"
 * Week Index - number of complete (Mon-Sun) ended weeks since epoch plus one
 *   - the first complete week started at 00:00:00 UTC on Monday, 5 January 1970 (UNIX Time 345600),
 *     it has WeekIndex 1
 *   - the week that started at 00:00:00 UTC on Monday, 23 September 2019 has WeekIndex 2595
 *
 */

contract Weeks {

    /**
    * @return uint16 Week Index
    */
    function weekIndex(uint unixTime) public pure returns(uint16)
    {
        return uint16((unixTime - 345600)/(7 days) + 1);
    }

    /**
    * @return uint16 Week Index of the latest block
    */
    function getCurrentWeek() public view returns(uint16)
    {
        return weekIndex(block.timestamp);
    }
}
