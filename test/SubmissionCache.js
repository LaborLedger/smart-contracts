/* global artefacts, before, beforeEach, contract, describe, it, web3 */

const { shouldFail } = require('openzeppelin-test-helpers');

const SubmissionCache = artifacts.require("SubmissionCacheMock");

contract("SubmissionCache", async accounts => {
    let submissionCache;

    describe("cachedSubmissions function", async () => {

        beforeEach(async () =>{
            submissionCache = await SubmissionCache.new();
        });

        it("shall return one BN and tree arrays of seven BNs each", async () => {
            const {latestWeek, times, forWeeks, whenWeeks, areAged} = await submissionCache.cachedSubmissions();
            assert.equal(latestWeek, '0', "unexpected latestWeek");

            assert.equal(Array.isArray(times), true, "unexpected 'times' type");
            assert.equal(Array.isArray(forWeeks), true, "unexpected 'forWeeks' type");
            assert.equal(Array.isArray(whenWeeks), true, "unexpected 'whenWeeks' type");
            assert.equal(Array.isArray(areAged), true, "unexpected 'areAged' type");

            assert.equal(times.length, 7, "unexpected 'times' length");
            assert.equal(forWeeks.length, 7, "unexpected 'forWeeks' length");
            assert.equal(whenWeeks.length, 7, "unexpected 'whenWeeks' length");
            assert.equal(areAged.length, 7, "unexpected 'areAged' length");
        });

        it("shall return zero values when called before submissions", async () => {
            const {latestWeek, times, forWeeks, whenWeeks, areAged} = await submissionCache.cachedSubmissions();
            assert.equal(latestWeek, '0', "unexpected latestWeek");

            for (let i = 0; i<7; i++) {
                assert.equal(forWeeks[i].toString(), '0', `unexpected 'forWeeks[${i}]'`);
                assert.equal(whenWeeks[i].toString(), '0', `unexpected 'whenWeeks[${i}]'`);
                assert.equal(times[i].toString(), '0', `unexpected 'whenWeeks[${i}]'`);
                assert.equal(areAged[i], false, `unexpected 'areAged[${i}]'`);
            }
        });
    });

    describe("_updateCache function", async () => {

        beforeEach(async () =>{
            submissionCache = await SubmissionCache.new();
        });

        it("shall allow submission for a week preceding the current week", async () => {
            const exp = {time: '110', week: '2505', curWeek: '2506'};

            const { latestWeek, forWeeks, times } = await submitAndGetResults(
                exp.time, exp.week, exp.curWeek);

            assert.equal(latestWeek.toString(), exp.curWeek, "unexpected curWeek");
            assert.equal(forWeeks[0].toString(), exp.week, "unexpected week");
            assert.equal(times[0].toString(), exp.time, "unexpected time");
        });

        it("shall allow submission for a week ended 4 weeks before the current week", async () => {
            const exp = {time: '110', week: '2502', curWeek: '2506'};

            const { latestWeek, forWeeks, times } = await submitAndGetResults(
                exp.time, exp.week, exp.curWeek);

            assert.equal(latestWeek.toString(), exp.curWeek, "unexpected curWeek");
            assert.equal(forWeeks[0].toString(), exp.week, "unexpected week");
            assert.equal(times[0].toString(), exp.time, "unexpected time");
        });

        it("shall revert submission for a the current week", async () => {
            const exp = {time: '110', week: '2506', curWeek: '2506'};
            await shouldFail(submitAndGetResults(exp.time, exp.week, exp.curWeek), " closed week submission");
        });

        it("shall revert submission for a week followed by the current week", async () => {
            const exp = {time: '110', week: '2507', curWeek: '2506'};
            await shouldFail(submitAndGetResults(exp.time, exp.week, exp.curWeek), " closed week submission");
        });

        it("shall revert submission for a week ended 5 weeks before the current week", async () => {
            const exp = {time: '110', week: '2501', curWeek: '2506'};
            await shouldFail(submitAndGetResults(exp.time, exp.week, exp.curWeek), " closed week submission");
        });

        it("shall revert being called with the current week 0", async () => {
            const exp = {time: '110', week: '0', curWeek: '0'};
            await shouldFail(submitAndGetResults(exp.time, exp.week, exp.curWeek), " closed week submission");
        });
    });

    describe("pre-compiled test suit", async () => {

        before(async () =>{
            submissionCache = await SubmissionCache.new();
        });

        const getCase = getCaseGen();
        for (let k = 1; k<=16; k++) {
            it(`shall result as expected for the case ${k}`, async() => {
                const exp = getCase();
                const {time, week, curWeek} = exp.submission;

                const {
                    agedValues, agedWeeks, latestWeek, times, forWeeks, whenWeeks, areAged
                } = await submitAndGetResults(time, week, curWeek);

                assert.equal(latestWeek.toString(), exp.latestWeek, "unexpected latestWeek");

                for (let i = 0; i<7; i++) {
                    assert.equal(times[i].toString(), exp.times[i], `unexpected 'times[${i}]'`);
                    assert.equal(forWeeks[i].toString(), exp.forWeeks[i], `unexpected 'forWeeks[${i}]'`);
                    assert.equal(whenWeeks[i].toString(), exp.whenWeeks[i], `unexpected 'whenWeeks[${i}]'`);
                    assert.equal(areAged[i], Boolean(exp.areAged[i]*1), `unexpected 'isAged[${i}]'`);
                    assert.equal(agedValues[i].toString(), exp.agedValues[i], `unexpected 'agedValues[${i}]'`);
                    assert.equal(agedWeeks[i].toString(), exp.agedWeeks[i], `unexpected 'agedWeeks[${i}]'`);
                }
            });
        }
    });

    async function submitAndGetResults(time, week, curWeek) {
        const cache = await submissionCache.mockGetSubmissionCache();

        const {newCache, agedValues, agedWeeks} = await submissionCache.mockUpdateCache(cache, time, week, curWeek);
        await submissionCache.mockSetSubmissionCache(newCache);

        const {latestWeek, times, forWeeks, whenWeeks, areAged} = await submissionCache.cachedSubmissions();

        return { cache, newCache, agedValues, agedWeeks, latestWeek, times, forWeeks, whenWeeks, areAged };
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
            [curWeek], [submission.week, submission.time],
            [cache[0]],
            [cache[1].isAged, cache[1].age, cache[1].time],
            [cache[2].isAged, cache[2].age, cache[2].time],
            [cache[3].isAged, cache[3].age, cache[3].time],
            [cache[4].isAged, cache[4].age, cache[4].time],
            [cache[5].isAged, cache[5].age, cache[5].time],
            [cache[6].isAged, cache[6].age, cache[6].time],
            [cache[7].isAged, cache[7].age, cache[7].time],
            agedValues,
            agedWeeks
        ] = suit[count++].split(';').map(s => s.trim()).map(s => s.split(','));

        const latestWeek = cache[0];

        const { times, forWeeks, whenWeeks, areAged } = cache.slice(1).reduce(
            (acc, el, j) => {
                if(el.isAged*1 !== 0 || el.age*1 !== 0 || el.time*1 !== 0) {
                    acc.areAged[acc.ind] = el.isAged;
                    acc.times[acc.ind] = el.time;
                    acc.forWeeks[acc.ind] = (latestWeek*1 - j - 1).toString();
                    acc.whenWeeks[acc.ind] = (latestWeek*1 - el.age*1).toString();
                    acc.ind += 1;
                }
                return acc;
            },
            {
                ind: 0,
                times:     ['0', '0', '0', '0', '0', '0', '0'],
                forWeeks:  ['0', '0', '0', '0', '0', '0', '0'],
                whenWeeks: ['0', '0', '0', '0', '0', '0', '0'],
                areAged:   ['0', '0', '0', '0', '0', '0', '0']
            }
        );


        return {
            id,
            submission: Object.assign(submission, {curWeek}),
            cache,
            agedValues,
            agedWeeks,
            latestWeek,
            times,
            forWeeks,
            whenWeeks,
            areAged,
        };
    }
}
