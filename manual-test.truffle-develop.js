/* global artifacts, web3 */

/* To run
with newly created 'truffle develop' network
$ truffle exec manual-test.truffle-develop.js --network truffle --compile
*/

/*
let collaboration = await Collaboration.new()
let implementation = await LaborLedgerImplementation.new()
let packUnpack = await MockPackUnpack.new()
let initParams = await packUnpack.pack(collaboration.address, web3.utils.fromAscii('the rest we test'), 2558, 400000, 300000, [1,2,3,4])
await implementation.init(initParams)

let inst = await LaborLedgerCaller.new(implementation.address, collaboration.address, web3.utils.fromAscii('the rest we test'), 2558, 400000, 300000, [1,2,3,4])
(await inst.getPastEvents({fromBlock:0, toBlock:1000})).map(e=>`${e.event}: ${e.raw.data}`)

let co = new web3.eth.Contract(implementation.abi, inst.address)
(await co.getPastEvents({fromBlock:0, toBlock:1000})).map(e=>`${JSON.stringify(e,null,2)}`)

*/


const {advanceBlock, advanceTimeAndBlock} = require('./scripts/truffle-test-helper')(web3);
const unixTimeNow = Number.parseInt(`${Date.now() / 1000}`);
const weekNow = Math.floor((unixTimeNow - 345600) / (7 * 24 * 3600)) + 1;
console.log(`weekNow: ${weekNow}`);

module.exports = async function(callback) {

    const LaborLedgerImplementation = artifacts.require("LaborLedgerImplementation");
    const LaborLedgerCaller = artifacts.require("LaborLedgerCaller");
    const Collaboration = artifacts.require("Collaboration");

    const [
        defaultAccount,
        projectLeadAddress,
        memberAddress,
        memberAddress2,
        memberAddress3,
        // nobody
    ] = await web3.eth.personal.getAccounts();
    console.log('>>> defaultAccount ', defaultAccount);
    console.log('>>> projectLead ', projectLeadAddress);
    console.log('>>> member ', memberAddress);
    console.log('>>> member2 ', memberAddress2);
    console.log('>>> user3 ', memberAddress3);

    const terms = 'the rest we test';
    const hashedTerms = web3.utils.fromAscii(terms);
    const startWeek = 1;
    const managerEquity = 200000;
    const investorEquity = 300000;
    const weights = [1,2,3,4];

    async function main() {
        while ((await web3.eth.getBlockNumber()) < 2) {
            await advanceBlock();
        }

        console.log('>>> started at block ', await web3.eth.getBlockNumber());

        let receipt, memberStatus;

        console.log('>>>> Collaboration.new');
        const collaboration = await Collaboration.new();
        console.log('    contract address:', collaboration.address);
        receipt = await web3.eth.getTransactionReceipt(collaboration.transactionHash);
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> LaborLedgerImplementation.new');
        const implementation = await LaborLedgerImplementation.new();
        receipt = await web3.eth.getTransactionReceipt(implementation.transactionHash);
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> LaborLedgerCaller.new');
        const caller = await LaborLedgerCaller.new(implementation.address, collaboration.address, hashedTerms, startWeek, managerEquity, investorEquity, weights);
        receipt = await web3.eth.getTransactionReceipt(caller.transactionHash);
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> LaborLedgerCaller.new (2)');
        const caller2 = await LaborLedgerCaller.new(implementation.address, collaboration.address, '0x0a0a', startWeek+1, managerEquity+1, investorEquity+1, weights);
        receipt = await web3.eth.getTransactionReceipt(caller.transactionHash);
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        const instance = new web3.eth.Contract(LaborLedgerImplementation.abi, caller.address);
        console.log(`>> instance  = ${instance.options.address}`);

        const instance2 = new web3.eth.Contract(LaborLedgerImplementation.abi, caller2.address);
        console.log(`>> instance2 = ${instance2.options.address}`);

        const {
            // acceptWeight,
            addProjectLead,
            getMemberData,
            getMemberEquity,
            getMemberStatus,
            join,
            init,
            setMemberStatus,
            setMemberWeight,
            submitHours,
            submittedHours,
            submittedWeightedHours
        } = instance.methods;

        const {
            init: init2,
            addProjectLead: addProjectLead2,
        } = instance2.methods;

        // console.log('>>>> init');
        // receipt = await init(nobody, startWeek).send({from: defaultAccount, gas: 300000});
        // console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> init');
        const initParams = collaboration.address + web3.utils.padLeft(startWeek.toString(16), 24).replace('0x', '');
        if (initParams.length !== 66) throw new Error('invalid initParams');
        await init(initParams).send({from: defaultAccount}).then(fall).catch(logErr);

        console.log('>>>> init2');
        const initParams2 = collaboration.address + web3.utils.padLeft((startWeek+1).toString(16), 24).replace('0x', '');
        if (initParams2.length !== 66) throw new Error('invalid initParams');
        await init2(initParams2).send({from: defaultAccount}).then(fall).catch(logErr);

        console.log('>>>> addProjectLead');
        receipt = await addProjectLead(projectLeadAddress).send({from: defaultAccount});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> addProjectLead second time');
        await addProjectLead(projectLeadAddress).send({from: defaultAccount}).then(fall).catch(logErr);

        console.log('>>>> addProjectLead(2)');
        receipt = await addProjectLead2(memberAddress3).send({from: defaultAccount});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> join member');
        receipt = await join(hashedTerms).send({from: memberAddress});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);
        memberStatus = await getMemberStatus(memberAddress).call();
        console.log(`>> memberStatus = ${memberStatus}`);

        console.log('>>>> set weight member');
        receipt = await setMemberWeight(memberAddress, 1).send({from: projectLeadAddress});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> join member3');
        receipt = await join(hashedTerms).send({from: memberAddress3});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        advanceTimeAndBlock(7 * 24 * 3600);

        console.log('>>>> submit hours member3');
        receipt = await submitHours(weekNow, [0, 0, 0, 5, 5, 0, 0]).send({from: memberAddress3, gas:300000});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> set member3 status hold');
        receipt = await setMemberStatus(memberAddress3, 2).send({from: projectLeadAddress});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        // console.log('>>>> set user 3 status offboard');
        // receipt = await setMemberStatus(memberAddress3, 4).send({from: projectLeadAddress});
        // console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> join member2');
        receipt = await join(hashedTerms).send({from: memberAddress2});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> set invalid statuses to member2');
        await setMemberStatus(memberAddress2, 0).send({from: projectLeadAddress}).then(fall).catch(logErr);
        await setMemberStatus(memberAddress2, 3).send({from: projectLeadAddress}).then(fall).catch(logErr);

        console.log('>>>> set weight member2');
        receipt = await setMemberWeight(memberAddress2, 2).send({from: projectLeadAddress});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> submit hours member');
        receipt = await submitHours(weekNow, [4, 4, 4, 4, 3, 1, 0]).send({from: memberAddress, gas:300000});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        advanceTimeAndBlock(7 * 24 * 3600);

        console.log('>>>> submit hours member');
        receipt = await submitHours(weekNow + 1, [34, 44, 44, 44, 36, 12, 0]).send({from: memberAddress, gas:300000});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        // console.log('>>>> accept weight by member');
        // receipt = await acceptWeight(32).send({from: memberAddress, gas:300000});
        // console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        // console.log('>>>> accept weight by member 2');
        // receipt = await acceptWeight(64).send({from: memberAddress2, gas:300000});
        // console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> submit hours member 2');
        receipt = await submitHours(weekNow + 1, [80, 80, 80, 80, 60, 0, 0]).send({from: memberAddress2, gas:300000});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> submit hours member3 being onhold');
        receipt = await submitHours(weekNow + 1, [0, 0, 0, 5, 5, 0, 0]).send({from: memberAddress3, gas:300000}).then(fall).catch(logErr);

        let memberData = await getMemberData(memberAddress).call();
        console.log(`>> member  Data = ${JSON.stringify(memberData, null, 2)}`);

        memberData = await getMemberData(memberAddress2).call();
        console.log(`>> member2 Data = ${JSON.stringify(memberData, null, 2)}`);

        memberData = await getMemberData(memberAddress3).call();
        console.log(`>> member3 Data = ${JSON.stringify(memberData, null, 2)}`);

        let memberShare = await getMemberEquity(memberAddress).call();
        console.log(`>> member  Share = ${memberShare.toString()}`);

        memberShare = await getMemberEquity(memberAddress2).call();
        console.log(`>> member2 Share = ${memberShare.toString()}`);

        memberShare = await getMemberEquity(memberAddress3).call();
        console.log(`>> member3 Share = ${memberShare.toString()}`);

        let value = await submittedHours().call();
        console.log(`>> submittedHours = ${value.toString()}`);

        value = await submittedWeightedHours().call();
        console.log(`>> submittedWeightedHours = ${value.toString()}`);

        console.log('>>> done');
    }

    let falls;
    const cb = (...args) => {
        if (falls) console.log(`!!!! It has to fall ${falls} time`);
        console.log('>>>> end');
        callback(...args);
    };
    function fall() { falls++; throw new Error('Must fall'); }
    function logErr(e) { console.log(e.message); }

    try {
        main()
            .catch(console.error)
            .finally(cb);
    } catch (e) {
        console.log('>>>> catch');
        console.error(e);
        cb();
    }
};
