pragma solidity 0.5.13;

import "../lib/SubmissionCache.sol";


contract SubmissionCacheMock is SubmissionCache {

    function mockUpdateCache(
        uint16[8] memory cache,
        uint16 time,
        uint16 week,
        uint16 curWeek
    ) public pure returns(
        uint16[8] memory newCache,
        uint16[7] memory agedValues,
        uint16[7] memory agedWeeks
    )
    {
        return _updateCache(cache, time, week, curWeek);
    }

    function mockGetSubmissionCache() public view returns (uint16[8] memory) {
        return _getSubmissionCache();
    }

    function mockSetSubmissionCache(uint16[8] memory cache) public {
        _setSubmissionCache(cache);
    }
}
