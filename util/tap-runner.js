const path = require('path');
const createRunner = require('./tap');

const file = process.argv[2];

const cwd = process.cwd();
const dir = path.dirname(path.relative(cwd, file));
const suit = require(path.resolve(cwd, file));

createRunner({
  cwd,
  dir,
})(suit)
.catch(error => {
  console.error(error);
  process.exit(1);
});
