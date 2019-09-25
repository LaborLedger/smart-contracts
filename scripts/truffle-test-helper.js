//Source (slightly adopted): https://gist.github.com/AndyWatt83/dae87c8c2c4bf5a6096d1950d0b8964e

module.exports = (web3) => {

    if (!web3.version.startsWith('1.2')) throw new Error("web3 version 1.2 expected");

    advanceTimeAndBlock = async (time) => {
        await advanceTime(time);
        await advanceBlock();

        return Promise.resolve(web3.eth.getBlock('latest'));
    };

    advanceTime = (time) => {
        return new Promise((resolve, reject) => {
            web3.eth.currentProvider.send({
                jsonrpc: "2.0",
                method: "evm_increaseTime",
                params: [time],
                id: new Date().getTime()
            }, (err, result) => {
                if (err) {
                    return reject(err);
                }
                return resolve(result);
            });
        });
    };

    advanceBlock = () => {
        return new Promise((resolve, reject) => {
            web3.eth.currentProvider.send({
                jsonrpc: "2.0",
                method: "evm_mine",
                id: new Date().getTime()
            }, (err, result) => {
                if (err) {
                    return reject(err);
                }
                const newBlockHash = web3.eth.getBlock('latest').hash;

                return resolve(newBlockHash)
            });
        });
    };

    return {
        advanceTime,
        advanceBlock,
        advanceTimeAndBlock
    };
};
