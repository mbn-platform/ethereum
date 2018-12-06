const web3 = require('web3');

// Ethereum handlers
exports.ether = (v) => web3.utils.toWei(String(v), 'ether');

// TAP helpers
exports.snapshot = (ctx) => ctx.evm.snapshot();
exports.rollback = (ctx) => ctx.evm.rollback();

// Other
exports.stack = function(...fns) {
  return (arg) => {
    for (const fn of fns) {
      fn(arg);
    }
  };
};
