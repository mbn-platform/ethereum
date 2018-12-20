const path = require('path');
const {EventEmitter} = require('events'); // FIXME Replace with EventEmitter3

const chalk = require('chalk');

class TapReporter extends EventEmitter {
  constructor({dir, lineLength, output = console.log}) {
    super();

    this.dir = dir;
    this.lineLength = lineLength;

    if (output) {
      this.on('output', output);
    }
  }

  reportCase(item) {
    const prefix = '  ';
    const {number, path} = item;

    let status;
    let title = (item.title || item.type);
    let location = chalk.gray('# ' + path.join(' :: '));
    let msg;

    if (item.error) {
      const {error} = item;
      status = chalk.bold.red('not ok');

      if (error.assertion) {
        msg = toYamlLike({
          message: error.message,
          operator: error.assertion.params.operator,
          actual: error.assertion.params.actual,
          expect: error.assertion.params.expected,
          location: error.location || error.stack.replace(error.message, ''),
        }, {dir: this.dir});
      }
      else {
        msg = toYamlLike({
          message: error.message,
          location: error.location,
        }, {dir: this.dir});
      }
    }
    else if (item.type === 'case') {
      status = chalk.bold.green('ok');
    }
    else {
      return;
    }

    this.output(
      wordWrap(location, this.lineLength, prefix, 1)
    );
    this.output(
      wordWrap(`${status} ${number} - ${title}`, this.lineLength, prefix, 1)
    );
    if (msg) {
      this.output(
        wordWrap(`---\n${msg}\n...`, this.lineLength, prefix)
      );
    }
  }

  reportStart({total}) {
    this.output('TAP version 13');
    this.output(Math.min(1, total) + '..' + total + '\n');
  }

  reportEnd({total, pass}) {
    const fail = total - pass;
    const rate = (total !== 0)
      ? pass / total
      : 0

    this.output('');
    this.output('# test: ' + chalk.bold(total));
    this.output('# pass: ' + chalk.bold(pass));
    this.output('# fail: ' + chalk.bold(fail));
    this.output('# rate: ' + chalk.bold((rate * 100).toFixed(2)) + '%');
  }

  reportFatalError(item) {
    let msg = 'Bail out!';
    msg += ' ' + (item.title || item.type) + ' at ' + item.path.join(' / ') + '\n';
    if (item.error) {
      console.log(item.error);
      msg += item.error.stack;
    }
    this.output('\n' + msg);
  }

  output(msg) {
    this.emit('output', msg);
  }
}

// Wordwrap output
function cutline(text, length) {
  const line = text.slice(0, length);
  const rn = line.match(/\r|\r?\n/);
  if (rn) {
    return line.slice(0, rn.index + rn[0].length);
  }
  else if (line.length === length) {
    const space = line.match(/\s+(?=\S*$)/);
    if (space) {
      return line.slice(0, space.index + 1);
    }
  }

  return line;
}

function wordWrap(text, length, prefix, skip = 0) {
  const indent = prefix.length;
  const out = [];
  let i = 0;
  while(text.length) {
    let maxLength = skip > 0 ? length : length - indent;
    let linePrefix = skip > 0 ? '' : prefix;

    let line = cutline(text, maxLength);

    text = text.slice(line.length);
    out.push(linePrefix + line.trimEnd());
  }

  return out.join('\n');
}

// Yaml output

function isMultiline(value) {
  return /\r|\r?\n/.test(value);
}

function isEscapeable(value) {
  return /^(\s|\w)+$/.test(value) === false;
}

function escape(value) {
    return '"' + value.replace(/\\/g, '\\\\')
    .replace(/\"/g, '\\\"') + '\"';
}

function safeValue(value, indent) {
  const _value = String(value);
  if (isMultiline(_value)) {
    return '>\n' + wordWrap(_value, 80, indent);
  }
  else if (isEscapeable(_value)) {
    return escape(_value);
  }

  return value;
}

function toYamlLike(values, {indent = 0, dir} = {}) {
  const keys = Object.getOwnPropertyNames(values);
  const maxLength = keys.reduce((result, key) => Math.max(result, key.length), 0);
  const out = [];
  const prefix = ' '.repeat(indent);
  for (const key of keys) {
    const align = ' '.repeat(maxLength - key.length);
    const value = values[key];
    const coloredKey = chalk.grey(key + ':');
    if (Array.isArray(value)) {
      out.push(`${prefix}${coloredKey}`);
      value.forEach((item) => {
        if (! item.startsWith(dir + path.sep)) {
          item = chalk.gray(safeValue(item));
        }
        else {
          item = safeValue(item);
        }
        out.push(`${prefix}  - ${item}`);
      });
    }
    else if (value !== undefined) {
      out.push(`${prefix}${coloredKey} ${align}${safeValue(value, prefix + '  ')}`);
    }
  }
  return out.join('\n');
}

module.exports = TapReporter;
