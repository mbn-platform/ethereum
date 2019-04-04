const Web3 = require('web3');
const ganache = require('ganache-cli');
const dayjs = require('dayjs');

exports.mountWeb3 = ({
  totalAccounts = 100,
  defaultBalance = 1000,
  startDate = dayjs('1971-01-01').startOf('day').toDate(),
} = {}) => async function mountWeb3(ctx, next) {
  const provider = ganache.provider({
    total_accounts: totalAccounts,
    default_balance_ether: defaultBalance,
    time: startDate,
  });

  // Prevent max listeners warning at startup. But still prevents from blowing.
  provider.setMaxListeners(100);

  const web3 = new Web3(provider);

  try {
    await next({
      ...ctx,
      web3,
    });
  }
  finally {
    await new Promise((resolve, reject) => {
      provider.close((err) => {
        if (err) {
          reject;
        }
        else {
          resolve();
        }
      });
    });
  }
};
exports.mountAccounts = (layout = null) => async function mountAccounts(ctx, next) {
  const {web3} = ctx;

  let accounts = await web3.eth.getAccounts();
  if (layout) {
    const namedAccounts = [];
    for (const [name, index] of Object.entries(layout)) {
      namedAccounts[name] = accounts[index];
    }
    accounts = namedAccounts;
  }
  return next({...ctx, accounts});
};

exports.mountEvm = (prop = 'web3') => async function mountEvm({[prop]: web3, ...ctx}, next) {
  const snapshots = [];

  function snapshot() {
    return evmCall(web3, 'evm_snapshot')
    .then((result) => {
      snapshots.push(result);
    });
  }

  function rollback() {
    return evmCall(web3, 'evm_revert', [snapshots.pop()]);
  }

  function increaseTime(seconds) {
    return evmCall(web3, 'evm_increaseTime', [seconds]);
  }
  await next({
    ...ctx,
    [prop]: web3,
    evm: {snapshot, rollback, increaseTime},
  });
};

exports.mountWeb3Utils = (prop = 'web3') => async (ctx, next) => {
  const web3 = ctx[prop];

  const utils = {
    toWei(value, unit = 'ether') {
      return web3.utils.toWei(String(value), unit);
    },
    fromWei(value, unit = 'ether') {
      return web3.utils.fromWei(value, unit);
    },
    getBalance(address, unit = 'ether') {
      return web3.eth.getBalance(address)
      .then(value => web3.utils.fromWei(value, unit));
    },
  };

  return next({
    ...ctx,
    utils,
  });
};

function evmCall(web3, method, params = []) {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send({
      jsonrpc: '2.0',
      method,
      params,
      id: Date.now(),
    }, (err, out) => {
      if (err) {
        reject(err);
      }
      else {
        resolve(out.result);
      }
    });
  });
}

exports.snapshot = async ({evm}, next) => {
  await evm.snapshot();
  try {
    await next();
  }
  finally {
    await evm.rollback();
  }
};
