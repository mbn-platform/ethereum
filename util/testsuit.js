const path = require('path');

const chalk = require('chalk');

function createItem(type, parent = null, handler = null) {
  return {
    type,
    path: parent ? parent.path : [],
    status: null,
    error: null,
    parent,
    handler,
  };
}

function createSection(title, parent) {
  return {
    ...createItem('section', parent),
    path: parent ? [...parent.path, title] : [],
    title,
    ctx: Object.create(parent ? parent.ctx : {}),
    actions: [],
    total: 0,
    pass: 0,
  };
}

function createCase(title, parent, handler) {
  const root = getRoot(parent);
  return {
    ...createItem('case', parent),
    path: [...parent.path, title],
    title,
    number: root.total + 1,
    handler,
  };
}

function increaseTotalCounter(item) {
  let parent = item;
  do {
    parent.total += 1;
  } while (parent = parent.parent);
}

function increasePassCounter(item) {
  let parent = item;
  while (parent = parent.parent) {
    parent.pass += 1;
  }
}

function getRoot(section) {
  let parent = section;
  while (parent.parent) {
    parent = parent.parent;
  }
  return parent;
}

function createRunner({
  context = {},
  reporter = defaultReporter,
  cwd,
  dir,
} = {}) {
  return (handler) => {
    let total = 0;
    const root = createSection('', null);
    let section = root;

    const levers = {
      describe(title, handler) {
        const next = createSection(title, section);
        section.actions.push(next);
        const tmp = section;
        section = next;
        handler(levers);
        section = tmp;
      },
      define(handler) {
        const {ctx} = section;

        section.actions.push(createItem(
          'define',
          section,
          async () => {
            Object.assign(ctx, await handler(ctx));
          }
        ));
      },
      before(handler) {
        const {ctx} = section;

        section.actions.push(createItem(
          'before',
          section,
          () => handler(ctx),
        ));
      },
      after(handler) {
        const {ctx} = section;

        section.actions.push(createItem(
          'after',
          section,
          () => handler(ctx),
        ));
      },
      it(title, ...handlers) {
        const {ctx} = section;

        section.actions.push(
          createCase(
            title,
            section,
            async () => {
              while(handlers.length) {
                await handlers.shift()(ctx);
              }
            },
          )
        );

        increaseTotalCounter(section);
      },
    };

    handler(levers);

    const {prepareStackTrace} = Error;

    const tapeStackTrace = (error, trace) => {
      const string = prepareStackTrace(error, trace);

      const location = [...trace.map((item) => {
        const filename = path.relative(cwd, item.getFileName() || '.');
        const line = `${filename}:${item.getLineNumber()}:${item.getColumnNumber()}`;
        return line;
      })];
      error.location = location;
      return string;
    };


    const report = (item) => (error) => {
        if (! error) {
          item.status = true;
          increasePassCounter(item);
        }
        else {
          error.stack;
          item.status = false;
          item.error = error;
        }

        reporter.reportCase(item);
    };

    const wrappedCase = (item, promise) => {
      return promise.then(report(item), report(item));
    };

    // Overwrite prepareStackTrace
    Error.prepareStackTrace = tapeStackTrace;

    reporter.reportStart(root);

    return walk(section, {
      define(item) {
        const {handler, ctx} = item;
        return handler(ctx);
      },
      before(item) {
        const {handler, ctx} = item;
        return handler(ctx);
      },
      after(item) {
        const {handler, ctx} = item;
        return handler(ctx);
      },
      it(item) {
        const {handler, ctx} = item;
        return wrappedCase(item, handler(ctx));
      },
    })
    .finally(() => {
      // Restore prepare stack trace
      Error.prepareStackTrace = prepareStackTrace;
    })
    .then(() => {
      reporter.reportEnd(root);
    }, (error) => {
      if (error instanceof Error) {
        root.status = false;
        root.error = error;
        reporter.reportFatalError(root);
      }
      else {
        // It's actually an test item
        reporter.reportFatalError(error);
      }
    })
    .then(() => root);
  };
}

const order = {
  define: 1,
  before: 1,
  case: 6,
  section: 5,
  after: 10,
};

async function walk(section, test) {
  const actions = section.actions.slice()
  .sort((a, b) => order[a.type] - order[b.type]);

  for (const item of actions) {
    try {
      await runItem(item, test);
    }
    catch (error) {
      section.status = false;
      if (error instanceof Error) {
        item.status = false;
        item.error = error;
        throw item;
      }
      else {
        throw error;
      }
    }
  }
  section.status = true;
}

function runItem(item, test) {
  switch (item.type) {
    case 'section': {
      return walk(item, test);
    }
    case 'define':
    case 'before': {
      return test.before(item);
    }
    case 'after': {
      return test.after(item);
    }
    case 'case': {
      return test.it(item);
    }
    default:
      throw new Error('Unknown testsuit type "' + item.type + '".');
  }
}

module.exports = createRunner;
