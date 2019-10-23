pragma solidity 0.5.11;

import "../WeeksAware.sol";

contract WeeksAwareMock is WeeksAware
{
    uint64 public mockPackedList;

    function CallInitWeeks(uint16 _startWeek) public {
        initWeeks(_startWeek);
    }

    function CallTestWeekAndUpdateFourWeeksList(uint16 _week, uint64 _packedList) public pure
    returns(uint64 _updatedPackedList)
    {
        return _testWeekAndUpdateFourWeeksList(_week, _packedList);
    }

    function CallAndSaveTestWeekAndUpdateFourWeeksList(uint16 _week) public {

        mockPackedList = _testWeekAndUpdateFourWeeksList(_week, mockPackedList);
    }
}
