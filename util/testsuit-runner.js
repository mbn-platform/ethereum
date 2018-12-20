const path = require('path');
const createRunner = require('./testsuit');
const TapReporter = require('./tap-reporter');
const prepareStackTrace = require('./prepare-stack-trace');

Error.prepareStackTrace = prepareStackTrace;

const file = process.argv[2];
const [files, argv] = splitArgs(process.argv.slice(2));

const cwd = process.cwd();
const dir = path.dirname(path.relative(cwd, file));

let lineLength = 80;
if (process.stdout.isTTY) {
  lineLength = process.stdout.getWindowSize()[0];
}

const reporter = new TapReporter({
  dir,
  lineLength,
});

createRunner({
  cwd,
  dir,
  reporter,
})((test) => {
  for (const file of files) {
    require(path.resolve(file))(argv)(test);
  }
})
.then((section) => {
  if (! section.status) {
    process.exit(1);
  }
})
.catch(error => {
  // We never shout to get there!
  console.error(error);
  process.exit(1);
});

function splitArgs(argv, splitter = '--') {
  const index = argv.indexOf(splitter);

  if (index < 0) {
    return [argv,[]];
  }

  return [argv.slice(0, index), argv.slice(index + 1)];
}
