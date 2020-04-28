pragma solidity 0.5.13;

/**
 * @dev "SubmissionsCache" - lib to support submissions timing and "aging".
 * All functions are "pure".
 *
 * @dev Timing and aging rules:
 * 0. One only submission for a week is allowed
 * 1. A submission is valid if:
 * - the reported week has not yet been submitted and ...
 * - the reported week has already ended and ...
 * - the reported week ended no later then 4 weeks ago
 * 2. The submission gets "aged" in 3 weeks after the week of submission
 *
 * @dev Submission cache
 * The functions bellow work with submissions cached as follows.
 * uint16[8] cache; // up to seven latest submissions cached, where:
 * - cache[0] - the "base" - Week Index of the latest submission week (when it was submitted)
 * - cache[i, where i = 1..7] - submissions for 7 weeks preceding the "base", packed into:
 *   lowest 12 bits - the "value", unsigned int - the value submitted for the week `base - i`
 *   next 3 bits - the "age", unsigned int - `base` minus Week Index of the submission week
 *   the highest bit - the "isAged" flag - "1" if the submission has been recognized as "aged"
 * (note the difference between submitted "for a week" vs. "on a week"):
 */
contract WeeklySubmissions {

    /**
     * @param cache - submissions cache
     * @param forWeek - Week Index to return cached submission for
     * @return value - cached value
     * @return onWeek - Week Index of the week the value was submitted on
     * @return isAged - `true` if the submission has been "aged"
     */
    function _extractSubmission(uint16[8] memory cache, uint16 forWeek) internal pure
    returns (
        uint16 value,
        uint16 onWeek,
        bool isAged
    ) {
        uint16 baseWeek = cache[0];
        if (baseWeek != 0 && baseWeek > forWeek) {
            uint16 i = baseWeek - forWeek;
            if (i <= 7 && cache[i] != 0) {
                (bool aged, uint16 age, uint16 val) = _unpackSubmission(cache[i]);
                return (val, baseWeek - age, aged);
            }
        }
        return (value, onWeek, isAged);
    }

    /**
     * @param cache - submissions cache
     * @return values - values submitted with last submissions
     * @return forWeeks - Week Index of the weeks the values were submitted for
     * @return onWeeks - Week Index of the weeks the values were submitted on
     * @return areAged - `true` if a submission has been "aged"
     */
    function _extractSubmissions(uint16[8] memory cache) internal pure
    returns (
        uint16 latestOnWeek,
        uint16[7] memory values,
        uint16[7] memory forWeeks,
        uint16[7] memory onWeeks,
        bool[7] memory areAged
    ) {
        latestOnWeek = cache[0];
        if (latestOnWeek != 0) {
            uint j;
            for (uint i = 1; i <=7; i += 1) {
                if (cache[i] != 0) {
                    (bool isAged, uint16 age, uint16 val) = _unpackSubmission(cache[i]);
                    values[j] = val;
                    forWeeks[j] = latestOnWeek - uint16(i);
                    onWeeks[j] = latestOnWeek - age;
                    areAged[j] = isAged;
                    j += 1;
                }
            }
        }
        return (latestOnWeek, values, forWeeks, onWeeks, areAged);
    }

    /**
     * @param cache - the submission cache to update
     * @param newValue - newly submitted value
     * @param forWeek - Week Index of the week the new value submitted for
     * @param curWeek - Week Index of the current week (for aging)
     * @return newCache - updated submission cache
     * @return agedValues - values of newly "aged" submissions
     * @return agedWeeks - "for" weeks' Week Indexes of the newly "aged" submissions
     */
    function _cacheSubmission(
        uint16[8] memory cache,
        uint16 newValue,
        uint16 forWeek,
        uint16 curWeek
    ) internal pure returns(
        uint16[8] memory newCache,
        uint16[7] memory agedValues,
        uint16[7] memory agedWeeks
    )
    {
        uint16 oldBase = cache[0];
        require(curWeek > 0 && curWeek >= oldBase, "program bug");

        if (newValue != 0) {    // new submission
            newCache[0] = curWeek;
            // declared here (not in upper scope) to avoid "too deep" EVM stack
            uint16 newBase = newCache[0];

            if (oldBase > forWeek) {
                uint16 oldInd = oldBase - forWeek;
                require(oldInd > 7 || cache[oldInd] == 0, "duplicated submission");
            }

            require(newBase > forWeek &&  newBase <= forWeek + 4, "closed week submission");
            newCache[uint(newBase - forWeek)] = newValue; // packing unneeded (higher bits 0)
        } else {
            newCache[0] = oldBase;
        }

        uint j;
        uint16 shift = newCache[0] - oldBase; // newCache[0] - "newBase"
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
                    //   `require(newValue == 0 || newInd != newBase - forWeek`)
                    // note: it can't be the case here as
                    //   `newInd != newBase - forWeek` equals to `i != oldBase - forWeek`
                    //   and `newValue !=0 && cache[oldBase - forWeek] != 0` reverted above
                    //   and cache[i] == 0 skipped by `if` above
                    newCache[newInd] = _packSubmission(isAged, age, val);
                }
            }
        }
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
        require(age < 8 && val < 4096, "program bug");
        packed = uint16(isAged ? 0x8000 : 0) | age << 12 | val;
    }
}
