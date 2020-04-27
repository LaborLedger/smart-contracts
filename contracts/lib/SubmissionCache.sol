pragma solidity 0.5.13;

import "./Weeks.sol";

/**
 * @dev "SubmissionsCache" - latest submissions cached for validation and "aging".
 *
 * @dev Validation and aging rules:
 * 1. The submission is valid if:
 * - the reported week has not yet been submitted and ...
 * - the reported week has already ended and ...
 * - the reported week ended no later then 4 weeks ago
 * 2. The submission gets "aged" in 3 weeks after the week of submission
 */
contract SubmissionCache is Weeks {

    uint16[8] internal _cache;  /** @dev latest submissions, cached as follows
     * _cache[0] - the "base" - Week Index of the latest submission week (the week reported on)
     * _cache[i, where i = 1..7] - submissions for 7 weeks preceding the "base", packed into:
     *   lowest 12 bits - the "value", unsigned int - Time Units reported for the week `base - i`
     *   next 3 bits - the "age", unsigned int - `base` minus Week Index of the submission week
     *   the highest bit - the "isAged" flag - "1" if the submission has been recognized as "aged"
     */

    /**
     * @param week - Week Index to return cached submission  for
     * @return time - cached Time Units
     * @return whenWeek - Week Index of the week the time was submitted on
     * @return isAged - `true` if the submission has been "aged"
     */
    function cachedSubmission(uint16 week) public view returns (
        uint16 time,
        uint16 whenWeek,
        bool isAged
    ) {
        uint16 baseWeek = _cache[0];
        if (baseWeek != 0 && baseWeek > week) {
            uint16 i = baseWeek - week;
            if (i <= 7 && _cache[i] != 0) {
                (bool aged, uint16 age, uint16 val) = _unpackSubmission(_cache[i]);
                return (val, baseWeek - age, aged);
            }
        }
        return (time, whenWeek, isAged);
    }

    function cachedSubmissions() public view returns (
        uint16 latestWeek,
        uint16[7] memory times,
        uint16[7] memory forWeeks,
        uint16[7] memory whenWeeks,
        bool[7] memory areAged
    ) {
        latestWeek = _cache[0];
        if (latestWeek != 0) {
            uint j;
            for (uint i = 1; i <=7; i += 1) {
                if (_cache[i] != 0) {
                    (bool isAged, uint16 age, uint16 val) = _unpackSubmission(_cache[i]);
                    times[j] = val;
                    forWeeks[j] = latestWeek - uint16(i);
                    whenWeeks[j] = latestWeek - age;
                    areAged[j] = isAged;
                    j += 1;
                }
            }
        }
        return (latestWeek, times, forWeeks, whenWeeks, areAged);
    }

    /**
     * @param cache - the submission cache (i.e. _cache) to update
     * @param time - newly reported Time Units
     * @param week - Week Index of the reported week
     * @param curWeek - Week Index of the week to "age" for
     * @return newCache - updated submission cache
     * @return agedValues - Time Units of newly "aged" submissions
     * @return agedWeeks - reported weeks' Week Indexes of the newly "aged" submissions
     */
    function _updateCache(
        uint16[8] memory cache,
        uint16 time,
        uint16 week,
        uint16 curWeek
    ) internal pure returns(
        uint16[8] memory newCache,
        uint16[7] memory agedValues,
        uint16[7] memory agedWeeks
    )
    {
        uint16 oldBase = cache[0];
        require(curWeek > 0 && curWeek >= oldBase, "program bug");

        if (time != 0) {    // new submission
            newCache[0] = curWeek;
            // `newBase` declared here but not in upper scope to avoid "too deep" EVM stack
            uint16 newBase = newCache[0];

            if (oldBase > week) {
                uint16 oldInd = oldBase - week;
                require(oldInd > 7 || cache[oldInd] == 0, "duplicated submission");
            }

            require(newBase > week &&  newBase <= week + 4, "closed week submission");
            newCache[uint(newBase - week)] = time;  // packing unneeded (higher bits are 0)
        } else {
            newCache[0] = oldBase;
        }

        uint j;
        uint16 shift = newCache[0] - oldBase;       // newCache[0] - "newBase"
        uint16 curShift = curWeek - newCache[0];
        for (uint16 i = 1; i <= 7; i++ ) {
            if (cache[i] != 0) {
                (bool isAged, uint16 age, uint16 val) = _unpackSubmission(cache[i]);

                // do "aging"
                age += shift;
                if (!isAged && (age + curShift) > 3) {
                    isAged = true;
                    agedValues[j] = val;
                    agedWeeks[j] = oldBase - i;
                    j += 1;
                }

                // re-index the cache
                uint16 newInd = i + shift;
                if (newInd <= 7) {
                    // must NOT re-write new submission:
                    //   `require(time == 0 || newInd != newBase - week`)
                    // note: it can't be the case here as
                    //   `newInd != newBase - week` equals to `i != oldBase - week`
                    //   and `time !=0 && cache[oldBase - week] != 0` reverted above
                    //   and cache[i] == 0 skipped by `if` above
                    newCache[newInd] = _packSubmission(isAged, age, val);
                }
            }
        }
    }

    function _getSubmissionCache() internal view returns (uint16[8] memory) {
        return _cache;
    }

    function _setSubmissionCache(uint16[8] memory cache) internal {
        _cache = cache;
    }

    function _unpackSubmission(uint16 packed) private pure
        returns(bool isAged, uint16 age, uint16 val)
    {
        isAged = (packed & 0x8000) >> 15 == 1;
        age = (packed & 0x7000) >> 12;
        val = packed & 0x0FFF;
    }

    function _packSubmission(bool isAged, uint16 age, uint16 val) private pure
        returns(uint16 packed)
    {
        // assumed: age < 8 && val < 4096
        packed = uint16(isAged ? 0x8000 : 0) | age << 12 | val;
    }
}
