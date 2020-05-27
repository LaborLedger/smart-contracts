pragma solidity 0.5.13;

import "./Weeks.sol";

/**
 * @dev "Weeks List" - a list for five consecutive weeks with (on/off) flags.
 * Used to track if weeks were submitted ('on' - if a week is submitted, 'off' otherwise).
 *
 * The list is packed (encoded) into 16 bits (uint16) as follows:
 * - The highest 12 bits - Week Index of the most recent week with the flag set to "on"
 * - lowest 4 bits - 4 flags for 4 weeks preceding the most recent week (stored into the highest bits),
 *   '1' - "on", '0' - off, the lowest bit is for the week followed by the most recent one.
 *
 * For example:
 * // weeks 2503, 2502 and 2500 are submitted, weeks 2501 and 2499 have not been submitted
 * uint16 weeksList = 2503*16 + 0*8 + 1*4 + 0*2 + 1*1;
 */
contract WeeksList is Weeks {

    /**
     * @return Week Index of the most resent week and 4 flags for the four consecutive preceding weeks
     * (note: the flag for the most recent week is set to 'on' by definition)
     */
    function decodeWeeks(uint16 weeksList) public pure
    returns (uint16 mostRecent, uint8 flags)
    {
        return (weeksList >> 4, uint8(weeksList & uint16(0x0F)));
    }

    /**
     * @dev Set the flag to 'on' for a week and returns the updated list of weeks,
     * reverts if the flag for the week is already 'on' or the week is out of the allowed range.
     *
     * @param weeksList {uint16} - the weeks list to update
     * @param week {uint16} - Week Index of the week to set the flag to 'on'
     * @param startWeek {uint16} - Week Index of the earliest week in the allowed range
     * @param slidingWeek {uint16} - WeekIndex of the last week in the allowed range of 5 consecutive weeks
     * @param revertClosedAndDuplicated {bool} - revert if the week is out of the allowed range or already set 'on'
     * @return {uint16} - the updated weeks list
     */
    function _getUpdatedWeeksList(
        uint16 weeksList,
        uint16 week,
        uint16 startWeek,
        uint16 slidingWeek,
        bool revertClosedAndDuplicated
    ) internal pure returns (uint16)
    {
        require(week >= startWeek, "invalid week (too old)");

        require(slidingWeek >= week, "invalid week (not yet open)");

        if (revertClosedAndDuplicated) {
            require(slidingWeek - week <= 5, "invalid week (closed)");
        }

        (uint16 mostRecent, uint8 flags) = decodeWeeks(weeksList);
        if (mostRecent == 0) { return week << 4; }

        require(mostRecent > 4, "program bug"); // logic error (year 1970 unexpected)

        if (week == mostRecent) {
            require(!revertClosedAndDuplicated, "duplicated week");
            return weeksList;
        }

        uint16 offset = week > mostRecent ? week - mostRecent : mostRecent - week;

        if (week > mostRecent) {
            if (offset > 4) { return week << 4; }
            mostRecent = week;
            flags = (flags << offset) & 0x0F;
        }
        // if it comes here, either `(week < mostRecent)`, or `(1 <= offset <= 4)`

        if (offset > 4) {
            // `week < mostRecent`, if it comes here
            require(!revertClosedAndDuplicated, "invalid week (too old)");
            return weeksList;
        }

        uint8 weekBit = uint8(0x01) << uint8(offset - 1);
        require(!revertClosedAndDuplicated || (flags & weekBit == 0), "duplicated week");

        return uint16(mostRecent << 4) | uint16(flags | weekBit);
    }
}
