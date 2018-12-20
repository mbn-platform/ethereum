const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const Account = require('eth-lib/lib/account');

const {
  getAddressPath,
  getPrivatePath,
} = require('./util/web3-local.js');

module.exports = function() {
  const account = Account.create(
    crypto.randomBytes(32)
  );

  const dir = process.env.ETH
    ? path.resolve(process.env.ETH)
    : path.join(process.env.HOME, '.eth');

  if (fs.existsSync(dir)) {
    throw `Directory ${dir} already exists`;
  }

  fs.mkdirSync(dir);

  fs.writeFileSync(getPrivatePath(dir), JSON.stringify(account, null, 2));
  fs.writeFileSync(getAddressPath(dir), account.address + '\n');
};
