pragma solidity 0.5.13;

import "../lib/WeeklySubmissions.sol";


contract WeeklySubmissionsMock is WeeklySubmissions {

    function mockExtractSubmission(uint16[8] memory cache, uint16 week) public pure
    returns (
        uint16 value,
        uint16 onWeek,
        bool isAged
    ) {
        return _extractSubmission(cache, week);
    }

    function mockExtractSubmissions(uint16[8] memory cache) public pure
    returns (
        uint16 pending,
        uint16[7] memory values,
        uint16[7] memory forWeeks,
        uint16[7] memory onWeeks,
        bool[7] memory areAged
    ) {
        return _extractSubmissions(cache);
    }

    function mockCacheSubmission(
        uint16[8] memory cache,
        uint16 newValue,
        uint16 forWeek,
        uint16 curWeek
    ) public pure returns (
        uint16[8] memory newCache,
        uint16[7] memory agedValues,
        uint16[7] memory agedWeeks
    )
    {
        return _cacheSubmission(cache, newValue, forWeek, curWeek);
    }
}
