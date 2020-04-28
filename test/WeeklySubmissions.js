/* global artefacts, before, beforeEach, contract, describe, it, web3 */

const { shouldFail } = require('openzeppelin-test-helpers');

const WeeklySubmissions = artifacts.require("WeeklySubmissionsMock");

contract("WeeklySubmissions", async accounts => {
    let weeklySubmissions;

    before(async () =>{
        weeklySubmissions = await WeeklySubmissions.new();
    });

    describe("_extractSubmissions function", async () => {

        it("shall return expected properties", async () => {
            const {
                latestOnWeek, values, forWeeks, onWeeks, areAged
            } = await weeklySubmissions.mockExtractSubmissions(getEmptyCache());

            assert.equal(latestOnWeek, '0', "unexpected latestOnWeek");

            assert.equal(Array.isArray(values), true, "unexpected 'values' type");
            assert.equal(Array.isArray(forWeeks), true, "unexpected 'forWeeks' type");
            assert.equal(Array.isArray(onWeeks), true, "unexpected 'onWeeks' type");
            assert.equal(Array.isArray(areAged), true, "unexpected 'areAged' type");

            assert.equal(values.length, 7, "unexpected 'values' length");
            assert.equal(forWeeks.length, 7, "unexpected 'forWeeks' length");
            assert.equal(onWeeks.length, 7, "unexpected 'onWeeks' length");
            assert.equal(areAged.length, 7, "unexpected 'areAged' length");
        });

        it("shall return zero values when called before submissions", async () => {
            const {
                latestOnWeek, values, forWeeks, onWeeks, areAged
            } = await weeklySubmissions.mockExtractSubmissions(getEmptyCache());

            assert.equal(latestOnWeek, '0', "unexpected latestOnWeek");

            for (let i = 0; i<7; i++) {
                assert.equal(forWeeks[i].toString(), '0', `unexpected 'forWeeks[${i}]'`);
                assert.equal(onWeeks[i].toString(), '0', `unexpected 'onWeeks[${i}]'`);
                assert.equal(values[i].toString(), '0', `unexpected 'values[${i}]'`);
                assert.equal(areAged[i], false, `unexpected 'areAged[${i}]'`);
            }
        });
    });

    describe("_cacheSubmission function", async () => {

        it("shall cache submission for a week preceding the current week", async () => {
            const exp = {value: '110', week: '2505', curWeek: '2506'};

            const { latestOnWeek, forWeeks, values } = await submitAndGetResults(
                exp.value, exp.week, exp.curWeek);

            assert.equal(latestOnWeek.toString(), exp.curWeek, "unexpected latestOnWeek");
            assert.equal(forWeeks[0].toString(), exp.week, "unexpected forWeek");
            assert.equal(values[0].toString(), exp.value, "unexpected value");
        });

        it("shall cache submission for a week ended 4 weeks before the current week", async () => {
            const exp = {value: '110', week: '2502', curWeek: '2506'};

            const { latestOnWeek, forWeeks, values } = await submitAndGetResults(
                exp.value, exp.week, exp.curWeek);

            assert.equal(latestOnWeek.toString(), exp.curWeek, "unexpected latestOnWeek");
            assert.equal(forWeeks[0].toString(), exp.week, "unexpected forWeek");
            assert.equal(values[0].toString(), exp.value, "unexpected value");
        });

        it("shall revert submission for a the current week", async () => {
            const exp = {value: '110', week: '2506', curWeek: '2506'};
            await shouldFail(submitAndGetResults(exp.value, exp.week, exp.curWeek), "closed week submission");
        });

        it("shall revert submission for a week followed by the current week", async () => {
            const exp = {value: '110', week: '2507', curWeek: '2506'};
            await shouldFail(submitAndGetResults(exp.value, exp.week, exp.curWeek), "closed week submission");
        });

        it("shall revert submission for a week ended 5 weeks before the current week", async () => {
            const exp = {value: '110', week: '2501', curWeek: '2506'};
            await shouldFail(submitAndGetResults(exp.value, exp.week, exp.curWeek), "closed week submission");
        });

        it("shall revert being called with the current week 0", async () => {
            const exp = {value: '110', week: '0', curWeek: '0'};
            await shouldFail(submitAndGetResults(exp.value, exp.week, exp.curWeek), "closed week submission");
        });

        it("shall cache submissions for two consecutive weeks", async () => {
            const exp = {value: '110', week: '2610', curWeek: '2611'};
            const exp2 = {value: '105', week: '2611', curWeek: '2612'};

            const act = await submitAndGetResults(exp.value, exp.week, exp.curWeek);
            assert.equal(act.forWeeks[0].toString(), exp.week, "unexpected week");
            assert.equal(act.values[0].toString(), exp.value, "unexpected value");

            const act2 = await submitAndGetResults(exp2.value, exp2.week, exp2.curWeek, act.newCache);
            assert.equal(act2.forWeeks[0].toString(), exp2.week, "unexpected week");
            assert.equal(act2.values[0].toString(), exp2.value, "unexpected value");
            assert.equal(act2.forWeeks[1].toString(), exp.week, "unexpected week");
            assert.equal(act2.values[1].toString(), exp.value, "unexpected value");
        });

        it("shall revert duplicated submission for a week", async () => {
            const exp = {value: '110', week: '2610', curWeek: '2611'};
            const dupl = {value: '105', week: '2610', curWeek: '2612'};

            const {values, forWeeks, newCache} = await submitAndGetResults(exp.value, exp.week, exp.curWeek);
            assert.equal(forWeeks[0].toString(), exp.week, "unexpected week");
            assert.equal(values[0].toString(), exp.value, "unexpected value");

            await shouldFail(
                submitAndGetResults(dupl.value, dupl.week, dupl.curWeek, newCache),
                "duplicated submission"
            );
        });
    });

    describe("pre-compiled test suit", async () => {

        const getCase = getCaseGen();
        let cache = getEmptyCache();
        for (let k = 1; k<=16; k++) {
            it(`shall result as expected for the case ${k}`, async() => {
                const exp = getCase();
                const {value, week, curWeek} = exp.submission;

                const {
                    agedValues, agedWeeks, latestOnWeek, values, forWeeks, onWeeks, areAged, newCache,
                } = await submitAndGetResults(value, week, curWeek, cache);
                cache = newCache;

                assert.equal(latestOnWeek.toString(), exp.latestOnWeek, "unexpected latestOnWeek");

                for (let i = 0; i<7; i++) {
                    assert.equal(values[i].toString(), exp.values[i], `unexpected 'values[${i}]'`);
                    assert.equal(forWeeks[i].toString(), exp.forWeeks[i], `unexpected 'forWeeks[${i}]'`);
                    assert.equal(onWeeks[i].toString(), exp.onWeeks[i], `unexpected 'onWeeks[${i}]'`);
                    assert.equal(areAged[i], Boolean(exp.areAged[i]*1), `unexpected 'isAged[${i}]'`);
                    assert.equal(agedValues[i].toString(), exp.agedValues[i], `unexpected 'agedValues[${i}]'`);
                    assert.equal(agedWeeks[i].toString(), exp.agedWeeks[i], `unexpected 'agedWeeks[${i}]'`);
                }
            });
        }
    });

    async function submitAndGetResults(newValue, forWeek, curWeek, cache = getEmptyCache())
    {
        const {
            newCache, agedValues, agedWeeks
        } = await weeklySubmissions.mockCacheSubmission(cache, newValue, forWeek, curWeek);

        const {
            latestOnWeek, values, forWeeks, onWeeks, areAged
        } = await weeklySubmissions.mockExtractSubmissions(newCache);

        return { cache, newCache, agedValues, agedWeeks, latestOnWeek, values, forWeeks, onWeeks, areAged };
    }

    function getEmptyCache() {
        return ['0', '0', '0', '0', '0', '0', '0', '0'];
    }
});

function getCaseGen() {
    let count = 0;
    const suit = [
        //id;curW; newSubm  ;_cache[0];_cache[1];_cache[2];_cache[3];_cache[4];_cache[5];_cache[6];_cache[7]; agedValues           ; agedWeeks
        '01; 2604; 2602,110 ;   2604  ;  0,0,0  ; 0,0,110 ; 0,0,0   ; 0,0,0   ; 0,0,0   ; 0,0,0   ; 0,0,0   ; 0,0,0,0,0,0,0        ; 0,0,0,0,0,0,0',
        '02; 2604; 2603,80  ;   2604  ;  0,0,80 ; 0,0,110 ; 0,0,0   ; 0,0,0   ; 0,0,0   ; 0,0,0   ; 0,0,0   ; 0,0,0,0,0,0,0        ; 0,0,0,0,0,0,0',
        '03; 2605; 2604,100 ;   2605  ;  0,0,100; 0,1,80  ; 0,1,110 ; 0,0,0   ; 0,0,0   ; 0,0,0   ; 0,0,0   ; 0,0,0,0,0,0,0        ; 0,0,0,0,0,0,0',
        '04; 2605; 2601,130 ;   2605  ;  0,0,100; 0,1,80  ; 0,1,110 ; 0,0,130 ; 0,0,0   ; 0,0,0   ; 0,0,0   ; 0,0,0,0,0,0,0        ; 0,0,0,0,0,0,0',
        '05; 2606; 2605,77  ;   2606  ;  0,0,77 ; 0,1,100 ; 0,2,80  ; 0,2,110 ; 0,1,130 ; 0,0,0   ; 0,0,0   ; 0,0,0,0,0,0,0        ; 0,0,0,0,0,0,0',
        '06; 2608; 0,0      ;   2606  ;  0,0,77 ; 0,1,100 ; 1,2,80  ; 1,2,110 ; 0,1,130 ; 0,0,0   ; 0,0,0   ; 80,110,0,0,0,0,0     ; 2603,2602,0,0,0,0,0',
        '07; 2610; 2609,103 ;   2610  ;  0,0,103; 0,0,0   ; 0,0,0   ; 0,0,0   ; 1,4,77  ; 1,5,100 ; 1,6,80  ; 77,100,130,0,0,0,0   ; 2605,2604,2601,0,0,0,0',
        '08; 2610; 2608,105 ;   2610  ;  0,0,103; 0,0,105 ; 0,0,0   ; 0,0,0   ; 1,4,77  ; 1,5,100 ; 1,6,80  ; 0,0,0,0,0,0,0        ; 0,0,0,0,0,0,0',
        '09; 2610; 2607,108 ;   2610  ;  0,0,103; 0,0,105 ; 0,0,108 ; 0,0,0   ; 1,4,77  ; 1,5,100 ; 1,6,80  ; 0,0,0,0,0,0,0        ; 0,0,0,0,0,0,0',
        '10; 2610; 2606,107 ;   2610  ;  0,0,103; 0,0,105 ; 0,0,108 ; 0,0,107 ; 1,4,77  ; 1,5,100 ; 1,6,80  ; 0,0,0,0,0,0,0        ; 0,0,0,0,0,0,0',
        '11; 2611; 2610,123 ;   2611  ;  0,0,123; 0,1,103 ; 0,1,105 ; 0,1,108 ; 0,1,107 ; 1,5,77  ; 1,6,100 ; 0,0,0,0,0,0,0        ; 0,0,0,0,0,0,0',
        '12; 2612; 2611,93  ;   2612  ;  0,0,93 ; 0,1,123 ; 0,2,103 ; 0,2,105 ; 0,2,108 ; 0,2,107 ; 1,6,77  ; 0,0,0,0,0,0,0        ; 0,0,0,0,0,0,0',
        '13; 2613; 2612,67  ;   2613  ;  0,0,67 ; 0,1,93  ; 0,2,123 ; 0,3,103 ; 0,3,105 ; 0,3,108 ; 0,3,107 ; 0,0,0,0,0,0,0        ; 0,0,0,0,0,0,0',
        '14; 2614; 2613,144 ;   2614  ;  0,0,144; 0,1,67  ; 0,2,93  ; 0,3,123 ; 1,4,103 ; 1,4,105 ; 1,4,108 ; 103,105,108,107,0,0,0; 2609,2608,2607,2606,0,0,0',
        '15; 2615; 2614,116 ;   2615  ;  0,0,116; 0,1,144 ; 0,2,67  ; 0,3,93  ; 1,4,123 ; 1,5,103 ; 1,5,105 ; 123,0,0,0,0,0,0      ; 2610,0,0,0,0,0,0',
        '16; 2617; 0,0      ;   2615  ;  0,0,116; 0,1,144 ; 1,2,67  ; 1,3,93  ; 1,4,123 ; 1,5,103 ; 1,5,105 ; 67,93,0,0,0,0,0      ; 2612,2611,0,0,0,0,0',
    ];
    return () => {
        if (count >= suit.length) return null;

        let curWeek, id, agedValues, agedWeeks;
        let submission = {};
        const cache = [0, {}, {}, {}, {}, {}, {}, {}];
        [
            [id],
            [curWeek], [submission.week, submission.value],
            [cache[0]],
            [cache[1].isAged, cache[1].age, cache[1].value],
            [cache[2].isAged, cache[2].age, cache[2].value],
            [cache[3].isAged, cache[3].age, cache[3].value],
            [cache[4].isAged, cache[4].age, cache[4].value],
            [cache[5].isAged, cache[5].age, cache[5].value],
            [cache[6].isAged, cache[6].age, cache[6].value],
            [cache[7].isAged, cache[7].age, cache[7].value],
            agedValues,
            agedWeeks
        ] = suit[count++].split(';').map(s => s.trim()).map(s => s.split(','));

        const latestOnWeek = cache[0];

        const { values, forWeeks, onWeeks, areAged } = cache.slice(1).reduce(
            (acc, el, j) => {
                if(el.isAged*1 !== 0 || el.age*1 !== 0 || el.value*1 !== 0) {
                    acc.areAged[acc.ind] = el.isAged;
                    acc.values[acc.ind] = el.value;
                    acc.forWeeks[acc.ind] = (latestOnWeek*1 - j - 1).toString();
                    acc.onWeeks[acc.ind] = (latestOnWeek*1 - el.age*1).toString();
                    acc.ind += 1;
                }
                return acc;
            },
            {
                ind: 0,
                values:    ['0', '0', '0', '0', '0', '0', '0'],
                forWeeks:  ['0', '0', '0', '0', '0', '0', '0'],
                onWeeks: ['0', '0', '0', '0', '0', '0', '0'],
                areAged:   ['0', '0', '0', '0', '0', '0', '0']
            }
        );

        return {
            id,
            submission: Object.assign(submission, {curWeek}),
            cache,
            agedValues,
            agedWeeks,
            latestOnWeek,
            values,
            forWeeks,
            onWeeks,
            areAged,
        };
    }
}
