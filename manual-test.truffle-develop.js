// truffle exec manual-test.truffle-develop.js --network truffle
/* global web3, artifacts */

module.exports = (cb) => {
    try {
        runTest(web3, artifacts, cb).then(() => {
            console.log('SUCCESS');
            if (typeof cb === 'function') return cb();
        });
    } catch(e) {
        console.error(e);
        if (typeof cb === 'function') return cb(e);
    }
};

async function runTest(web3, artifacts, cb) {

    const {advanceBlock, advanceTimeAndBlock} = require('./scripts/truffle-test-helper')(web3);
    const unixTimeNow = Number.parseInt(`${Date.now() / 1000}`);
    const weekNow = Math.floor((unixTimeNow - 345600) / (7 * 24 * 3600)) + 1;
    console.log(`weekNow: ${weekNow}`);

    const accounts = await web3.eth.personal.getAccounts();
    let [ deployer, member1, member2, member3, user4, quorum, inviter, lead, arbiter, operator ] = accounts;
    let defaultOpts = {from: deployer, gas: 5000000};
    console.log('defaultOpts = ', defaultOpts);

    while ((await web3.eth.getBlockNumber()) < 2) {
        await advanceBlock();
    }
    console.log('started at block ', await web3.eth.getBlockNumber());

    const CollaborationProxy = artifacts.require("CollaborationProxy") || fall("artifacts CollaborationProxy");
    const CollaborationImpl = artifacts.require("CollaborationImpl") || fall("artifacts CollaborationImpl");
    const LaborLedgerImpl = artifacts.require("LaborLedgerImpl") || fall("artifacts LaborLedgerImpl");
    const OzProxyAdmin = artifacts.require("OzProxyAdmin") || fall("artifacts OzProxyAdmin");

    let proxyAdmin = await OzProxyAdmin.new(defaultOpts) || fall("OzProxyAdmin.new");
    expect(web3.utils.isAddress(proxyAdmin.address), `OzProxyAdmin ${proxyAdmin.address}`);

    let collabImpl = (await CollaborationImpl.new(defaultOpts)) || fall("CollaborationImpl.new");
    expect(web3.utils.isAddress(collabImpl.address), `CollaborationImpl ${collabImpl.address}`);

    let ledgerImpl = await LaborLedgerImpl.new(defaultOpts);
    expect(web3.utils.isAddress(ledgerImpl.address), `LaborLedgerImpl ${ledgerImpl.address}`);

    let collabProxy = await CollaborationProxy.new(collabImpl.address, proxyAdmin.address, '0x33ff', quorum, inviter, 300000, 200000, 500000, ledgerImpl.address, lead, arbiter, operator, 2500, 0x04030201, defaultOpts);
    expect(web3.utils.isAddress(collabProxy.address), `CollaborationProxy ${collabProxy.address}`);

    let collab = new web3.eth.Contract(CollaborationImpl.abi, collabProxy.address);
    let ldgrAddr = await collab.methods.getLaborLedger().call();
    let ledger = new web3.eth.Contract(LaborLedgerImpl.abi, ldgrAddr);
    expect(web3.utils.isAddress(ledger.options.address), `laborLedger (proxy) ${ledger.options.address}`);

    expect(
        await compareStrings(()=>web3.eth.getStorageAt(collabProxy.address, '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc'), collabImpl.address),
        `collabProxy.address ${collabProxy.address}`);
    expect(
        await compareStrings(()=>web3.eth.getStorageAt(collabProxy.address, '0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103'), proxyAdmin.address),
        "getStorageAt adminslot");
    expect(
        await compareStrings(()=>proxyAdmin.getProxyAdmin(ldgrAddr), proxyAdmin.address),
        "proxyAdmin.getProxyAdmin 1");
    expect(
        await compareStrings(()=>proxyAdmin.getProxyAdmin(collabProxy.address), proxyAdmin.address),
        "proxyAdmin.getProxyAdmin 2");
    expect(
        await compareStrings(()=>ledger.methods.getCollaboration().call(), collab.options.address),
        "getCollaboration");

    expect(
        await compareStrings(()=>collab.methods.getUid().call(), web3.utils.padRight(0x33ff, 64)),
        "getUid");

    await collab.methods.getEquity().call();
    await shouldRevert(()=>collab.methods.setEquity('600000','250000','150000').call(), 'caller does not have the Quorum role');
    expect(await collab.methods.isQuorum(quorum).call(), "isQuorum");

    await shouldRevert(()=>collab.methods.setEquity('600000','250000','150000').call({from:quorum}), 'management equity cant increase');
    await shouldRevert(()=>collab.methods.setEquity('250000','150000','400000').call({from:quorum}), 'sum must be exactly 1000000');
    await collab.methods.setEquity('250000','150000','600000').send({from:quorum});

    let pools = await collab.methods.getEquity().call();
    expect(pools.laborEquityPool === '600000', "laborEquityPool");
    expect(pools.managerEquityPool === '250000', "managerEquityPool");
    expect(pools.investorEquityPool === '150000', "investorEquityPool");

    await shouldRevert(()=>collab.methods.newInvite(web3.utils.keccak256('AudaC'), web3.utils.fromAscii('one')).call(), 'caller does not have the Inviter role');

    let thisWeek = await ledger.methods.getCurrentWeek().call();
    let invHash = web3.utils.keccak256('AudaC');
    let invData3 = await ledger.methods.encodeInviteData(1,2,1*thisWeek-4,500,33).call();
    await shouldRevert(()=>collab.methods.newInvite(invHash, invData3).send({from:member3}), ' caller does not have the Inviter role');

    expect(await collab.methods.isInviter(inviter).call(), "isInviter");
    await collab.methods.newInvite(invHash, invData3).send({from:inviter});
    expect(await collab.methods.isInvite(invHash).call(), "isInvite");

    await ledger.methods.join(web3.utils.fromAscii('AudaC'),1,2,1*thisWeek-4,500,33).send({from:member3});

    await ledger.methods.submitTime(1*thisWeek-2,167,'0x45').send({from:member3});

    await shouldRevert(()=>ledger.methods.submitTime(1*thisWeek-2,233,'0x44').send({from:member3}), 'duplicated submission');
    await shouldRevert(()=>ledger.methods.submitTime(1*thisWeek-1,1233,'0x45').send({from:member3}), 'time exceeds week limit');
    await shouldRevert(()=>ledger.methods.submitTime(1*thisWeek-6,50,'0x46').send({from:member3}), 'invalid week (too old)');
    await shouldRevert(()=>ledger.methods.submitTime(1*thisWeek,50,'0x46').send({from:member3}), 'invalid week (not yet open)');
    await shouldRevert(()=>ledger.methods.submitTime(1*thisWeek-2,1233,'0x45').send({from:member2}), 'member does not exists');

    await ledger.methods.submitTime(1*thisWeek-1,233,'0x44').send({from:member3});

    let membData = await ledger.methods.getMemberData(member3).call();
    let decodedWeeks = await ledger.methods.decodeWeeks(membData.recentWeeks).call();
    expect(decodedWeeks.mostRecent*1 === 1*thisWeek-1, "decodedWeeks.mostRecent");
    expect(decodedWeeks.flags*1 === 1, "decodedWeeks.flags");
    expect(await ledger.methods.getMemberTime(member3).call() === '400', "getMemberTime");
    let membLabor = await ledger.methods.getMemberLabor(member3).call();
    expect(membLabor.netLabor*1 === 1200, "netLabor");

    let invData2 = await ledger.methods.encodeInviteData(1,1,1*thisWeek-3,500,32).call();
    await collab.methods.newInvite(invHash, invData2).send({from:inviter});
    shouldRevert(()=>ledger.methods.join(web3.utils.fromAscii('AudaC'),1,1,1*thisWeek-3,500,31).send({from:member2}), 'mismatched invite data');
    shouldRevert(()=>ledger.methods.join(member3, web3.utils.fromAscii('AudaC'),1,1,1*thisWeek-3,500,32).send({from:operator}), 'member already exists');

    await ledger.methods.join(member2, web3.utils.fromAscii('AudaC'),1,1,1*thisWeek-3,500,32).send({from:operator});
    await ledger.methods.submitTime(1*thisWeek-1,333,'0x44').send({from:member2});
    await ledger.methods.submitTime(1*thisWeek-3,333,'0x44').send({from:member2});
    await ledger.methods.submitTime(1*thisWeek-2,333,'0x44').send({from:member2});
    await ledger.methods.updateTime(arbiter, member2, 1*thisWeek-3, -99, '0x77').send({from: operator});

    membData = await ledger.methods.getMemberData(member2).call();
    decodedWeeks = await ledger.methods.decodeWeeks(membData.recentWeeks).call();
    expect(decodedWeeks.mostRecent*1 === 1*thisWeek-1, "decodedWeeks.mostRecent member2");
    expect(decodedWeeks.flags*1 === 3, "decodedWeeks.flags member2");

    expect(await ledger.methods.getMemberTime(member2).call() === '900', "getMemberTime(member2)");
    expect(await ledger.methods.getMemberNetLabor(member2).call() === '1800', "getMemberNetLabor(member2)");

    expect(await ledger.methods.getTotalTime().call() === '1300', "getTotalTime()");
    let totalLabor = await ledger.methods.getTotalLabor().call();
    expect(totalLabor.labor*1 === 3000, "totalLabor.labor");
    expect(totalLabor.netLabor*1 === 3000, "totalLabor.netLabor");
    expect(totalLabor.settledLabor*1 === 0, "totalLabor.settledLabor");

    expect(await ledger.methods.getMemberLaborShare(member2).call() === '600000', "getMemberLaborShare(member2)");
    expect(await ledger.methods.getMemberLaborShare(member3).call() === '400000', "getMemberLaborShare(member3)");

    expect(await collab.methods.getMemberLaborEquity(member2).call() === '360000', "getMemberLaborEquity(member2)");
    expect(await collab.methods.getMemberLaborEquity(member3).call() === '240000', "getMemberLaborEquity(member3)");

    expect(true, '*** END');

    function fall(msg) {
        console.error(msg);
        return cb(new Error(msg));
    }

    function expect(success, msg) {
        if (success) {
            console.log(`PASSED: ${msg}`);
        } else {
            fall(`FAILED: ${msg}`);
        }
    }

    async function shouldRevert(fn, msg) {
        try {
            await fn().then(()=> fall('it MUST have been reverted !!!'));
        } catch(_) {
            console.log(`PASSED: (reverted) ${msg}`);
        }
    }

    async function compareStrings(fn, expected, caseInsensitive = true) {
        let val = await fn().then(a => caseInsensitive ? a.toLowerCase() : a);
        return val === (caseInsensitive ? expected.toLowerCase() : expected);
    }
}
