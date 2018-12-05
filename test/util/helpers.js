const web3 = require('web3');

// Custom handlers
exports.ether = (v) => web3.utils.toWei(String(v), 'ether');

// TAP helpers
exports.snapshot = (ctx) => ctx.evm.snapshot();
exports.rollback = (ctx) => ctx.evm.rollback();
