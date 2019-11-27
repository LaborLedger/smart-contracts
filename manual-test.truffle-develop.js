/* global artifacts, web3 */

/* To run
with newly created 'truffle develop' network
$ truffle exec manual-test.truffle-develop.js --network truffle --compile
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
        userAddress3,
        // nobody
    ] = await web3.eth.personal.getAccounts();
    console.log('>>> defaultAccount ', defaultAccount);
    console.log('>>> projectLead ', projectLeadAddress);
    console.log('>>> member ', memberAddress);
    console.log('>>> member2 ', memberAddress2);
    console.log('>>> user3 ', userAddress3);

    // const terms = 'the rest we test';
    // const hashedTerms = web3.utils.fromAscii(terms);
    const startWeek = 1;

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
        const caller = await LaborLedgerCaller.new(implementation.address, collaboration.address, startWeek);
        receipt = await web3.eth.getTransactionReceipt(caller.transactionHash);
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        const instance = new web3.eth.Contract(LaborLedgerImplementation.abi, caller.address);

        const {
            acceptWeight,
            addProjectLead,
            getMemberData,
            getMemberShare,
            getMemberStatus,
            join,
            init,
            setMemberStatus,
            setMemberWeight,
            submitTime,
        } = instance.methods;

        // console.log('>>>> init');
        // receipt = await init(nobody, startWeek).send({from: defaultAccount, gas: 300000});
        // console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> init');
        const initParams = collaboration.address + web3.utils.padLeft(startWeek.toString(16), 24).replace('0x', '');
        if (initParams.length !== 66) throw new Error('invalid initParams');
        await init(initParams).send({from: defaultAccount}).catch(e => console.log(e.reason));

        console.log('>>>> addProjectLead');
        receipt = await addProjectLead(projectLeadAddress).send({from: defaultAccount});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> addProjectLead second time');
        await addProjectLead(projectLeadAddress).send({from: defaultAccount}).catch(e => console.log(e.reason));

        console.log('>>>> join member');
        receipt = await join(web3.utils.fromAscii('invite1'), 0, 0, 0).send({from: memberAddress});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);
        memberStatus = await getMemberStatus(memberAddress).call();
        console.log(`>> memberStatus = ${memberStatus}`);

        console.log('>>>> set weight member');
        receipt = await setMemberWeight(memberAddress, 0).send({from: projectLeadAddress});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> join user 3');
        receipt = await join(web3.utils.fromAscii('invite3'), 0, 0, 0).send({from: userAddress3});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> set user 3 status hold');
        receipt = await setMemberStatus(userAddress3, 2).send({from: projectLeadAddress});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> set user 3 status offboard');
        receipt = await setMemberStatus(userAddress3, 4).send({from: projectLeadAddress});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        advanceTimeAndBlock(7 * 24 * 3600);

        console.log('>>>> join member 2');
        receipt = await join(web3.utils.fromAscii('invite2'), 0, 0, 0).send({from: memberAddress2});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> set invalid statuses to member 2');
        await setMemberStatus(memberAddress2, 0).send({from: projectLeadAddress}).catch(e => console.log(e.reason));
        await setMemberStatus(memberAddress2, 1).send({from: projectLeadAddress}).catch(e => console.log(e.reason));
        await setMemberStatus(memberAddress2, 3).send({from: projectLeadAddress}).catch(e => console.log(e.reason));

        console.log('>>>> set weight member 2');
        receipt = await setMemberWeight(memberAddress2, 2).send({from: projectLeadAddress});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> submit hours member');
        receipt = await submitTime(weekNow, [4, 4, 4, 4, 3, 1, 0]).send({from: memberAddress, gas:300000});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        advanceTimeAndBlock(7 * 24 * 3600);

        console.log('>>>> submit hours member');
        receipt = await submitTime(weekNow + 1, [34, 44, 44, 44, 36, 12, 0]).send({from: memberAddress, gas:300000});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> accept weight by member');
        receipt = await acceptWeight(32).send({from: memberAddress, gas:300000});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> accept weight by member 2');
        receipt = await acceptWeight(64).send({from: memberAddress2, gas:300000});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        console.log('>>>> submit hours member 2');
        receipt = await submitTime(weekNow + 1, [80, 80, 80, 80, 60, 0, 0]).send({from: memberAddress2, gas:300000});
        console.log(`>> receipt = ${JSON.stringify(receipt, null, 2)}`);

        let memberData = await getMemberData(memberAddress).call();
        console.log(`>> memberData = ${JSON.stringify(memberData, null, 2)}`);

        memberData = await getMemberData(memberAddress2).call();
        console.log(`>> member2Data = ${JSON.stringify(memberData, null, 2)}`);

        memberData = await getMemberData(userAddress3).call();
        console.log(`>> user3Data = ${JSON.stringify(memberData, null, 2)}`);

        console.log('>>>> get member share');
        let memberShare = await getMemberShare(memberAddress).call();
        console.log(`>> memberShare = ${memberShare.toString()}`);

        console.log('>>>> get member2 share');
        memberShare = await getMemberShare(memberAddress2).call();
        console.log(`>> memberShare = ${memberShare.toString()}`);

        console.log('>>> done');
    }

    const cb = (...args) => {console.log('>>>> end'); callback(...args);};
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

