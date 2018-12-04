const path = require('path');
const createRunner = require('./tap');

const suit = require(path.resolve(process.cwd(), process.argv[2]));

createRunner()(suit)
.catch(error => {
  console.error(error);
  process.exit(1);
});
