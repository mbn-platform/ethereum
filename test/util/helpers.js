function checkThrown(err, check) {
  if (typeof check === 'function') {
    return check(err);
  }
  else if (check instanceof RegExp){
    return check.test(err.message);
  }
  else {
    return check === err.message;
  }
}
async function throws(check, fn) {
  try {
    await fn();
  }
  catch (err) {
    if (checkThrown(err, check)) {
      return true;
    }
    else {
      throw err;
    }
  }
  return false;
}

// Test throws capture
exports.throws = throws;
