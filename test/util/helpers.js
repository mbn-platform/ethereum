const web3 = require('web3');

// Ethereum handlers
exports.ether = (v) => web3.utils.toWei(String(v), 'ether');

// TAP helpers
function snapshot(ctx) {
  return ctx.evm.snapshot();
}

function rollback(ctx) {
  return ctx.evm.rollback();
}

exports.snapshot = snapshot;
exports.rollback = rollback;

exports.wrap = (fn) => async (ctx) => {
  await snapshot(ctx);
  try {
    await fn(ctx);
  }
  finally {
    await rollback(ctx);
  }
};

// Other
exports.stack = function(...fns) {
  return (arg) => {
    for (const fn of fns) {
      fn(arg);
    }
  };
};
