pragma solidity 0.5.13;

/**
 * @dev "WeeklySubmissions" - lib to support submissions timing and "aging".
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
 * uint16[8] cache; // where:
 * - cache[0] - the "base" - Week Index of the latest submission week (when it was submitted)
 * - cache[i, where i = 1..7] - submissions for 7 weeks preceding the "base", packed into:
 *   lowest 12 bits - the "value", uint, submitted for the week ("for" week) `base - i`
 *   next 3 bits - the "age", uint, `base` minus Week Index of the submission week ("on" week)
 *   the highest bit - the "isAged" flag - "1" if the submission has been recognized as "aged"
 *
 * @notice
 * - "for" week ("forWeek") means the week the submission made for (the reported week)
 * - "on" week ("onWeek"), or a "submission week", mean the week the submission made on
 */
contract WeeklySubmissions {

    /**
     * Extract the submission for a week from the cache
     * @param cache - submissions cache
     * @param forWeek - Week Index to return cached submission for
     * @return value - cached value
     * @return onWeek - Week Index of the week the value was submitted on
     * @return isAged - `true` if the submission has been "aged"
     */
    function _extractSubmission(uint16[8] memory cache, uint16 forWeek)
    internal pure returns (
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
     * Extract all cached submissions
     * @param cache - submissions cache
     * @return pending - sum of not yet "aged" values
     * @return values - values submitted with last submissions
     * @return forWeeks - Week Index of the weeks the values were submitted for
     * @return onWeeks - Week Index of the weeks the values were submitted on
     * @return areAged - `true` if a submission has been "aged"
     */
    function _extractSubmissions(uint16[8] memory cache)
    internal pure returns (
        uint16 pending,
        uint16[7] memory values,
        uint16[7] memory forWeeks,
        uint16[7] memory onWeeks,
        bool[7] memory areAged
    ) {
        uint16 latestOnWeek = cache[0];
        if (latestOnWeek != 0) {
            uint j;
            for (uint i = 1; i <=7; i += 1) {
                if (cache[i] != 0) {
                    (bool isAged, uint16 age, uint16 val) = _unpackSubmission(cache[i]);
                    if (!isAged) { pending += val; }
                    values[j] = val;
                    forWeeks[j] = latestOnWeek - uint16(i);
                    onWeeks[j] = latestOnWeek - age;
                    areAged[j] = isAged;
                    j += 1;
                }
            }
        }
    }

    /**
     * @param week - Week Index of the week being submitted (reported)
     * @param curWeek - Week Index of the current week
     */
    function _isAgedWeek(uint16 week, uint16 curWeek)
    internal pure returns(bool)
    {
        return curWeek > week && (curWeek - week) >= 4;
    }

    /**
     * Add a new submission to the cache
     * @param cache - the submission cache to update
     * @param newValue - newly submitted value
     * @param forWeek - Week Index of the week the new value submitted for
     * @param curWeek - Week Index of the current week (for aging)
     * @return newCache - updated submission cache
     * @return agedValues - values of newly "aged" submissions
     * @return agedWeeks - "forWeek" Week Indexes of newly "aged" submissions
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
    ) {
        uint16 base = newValue == 0 ? cache[0] : curWeek;
        (newCache, agedValues, agedWeeks) = _doAging(cache, base, curWeek);

        if (newValue != 0) {
            uint i = uint(newCache[0] - forWeek);
            require(i >=1 && i <= 4, "closed week submission");
            require(i > 7 || newCache[i] == 0, "duplicated submission");
            // since `isAged` and `age` are zero, packing unneeded
            newCache[i] = newValue;
        }
    }

    /**
     * Re-build and "age" the cache for the new base week
     * @param cache - the submission cache to update
     * @param newBase - the new base week (its Week Index)
     * @return newCache - updated submission cache
     * @return agedValues - values of newly "aged" submissions
     * @return agedWeeks - "forWeek" Week Indexes of newly "aged" submissions
     */
    function _doAging(uint16[8] memory cache, uint16 newBase, uint16 curWeek)
    internal pure returns(
        uint16[8] memory newCache,
        uint16[7] memory agedValues,
        uint16[7] memory agedWeeks
    ) {
        require(curWeek > 0 && curWeek >= cache[0], "invalid curWeek");
        require(newBase >= cache[0], "invalid base week");

        newCache[0] = newBase;

        uint16 shift = newCache[0] - cache[0];
        uint16 curShift = curWeek - newCache[0];

        uint j;
        for (uint16 i = 1; i <= 7; i++ ) {
            if (cache[i] != 0) {
                (bool isAged, uint16 age, uint16 val) = _unpackSubmission(cache[i]);

                // update the submission `age`
                age += shift;

                // remember newly aged submissions
                if (!isAged && (age + curShift) > 3) {
                    isAged = true;
                    agedValues[j] = val;
                    agedWeeks[j] = cache[0] - i;
                    j += 1;
                }

                // move the submission to the proper position in the `newCache`
                uint16 newInd = i + shift;
                if (newInd <= 7) {
                    newCache[newInd] = _packSubmission(isAged, age, val);
                }
            }
        }
    }

    function _unpackSubmission(uint16 packed)
    private pure returns(bool isAged, uint16 age, uint16 val)
    {
        isAged = (packed & 0x8000) >> 15 == 1;
        age = (packed & 0x7000) >> 12;
        val = packed & 0x0FFF;
    }

    function _packSubmission(bool isAged, uint16 age, uint16 val)
    private pure returns(uint16 packed)
    {
        require(age < 8 && val < 4096, "program bug");
        packed = uint16(isAged ? 0x8000 : 0) | age << 12 | val;
    }
}
