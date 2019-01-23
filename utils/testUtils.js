const BN = require('bn.js');

/**
 *  Increases the time in the EVM.
 *  @param seconds Number of seconds to increase the time by
 */
const fastForward = async seconds => {
  // It's handy to be able to be able to pass big numbers in as we can just
  // query them from the contract, then send them back. If not changed to
  // a number, this causes much larger fast forwards than expected without error.
  if (BN.isBN(seconds)) seconds = seconds.toNumber();

  // And same with strings.
  if (typeof seconds === 'string') seconds = parseFloat(seconds);

  await send({
    method: 'evm_increaseTime',
    params: [seconds],
  });

  await mineBlock();
};

const assertEventEqual = (
  actualEventOrTransaction,
  expectedEvent,
  expectedArgs
) => {
  // If they pass in a whole transaction we need to extract the first log, otherwise we already have what we need
  const event = Array.isArray(actualEventOrTransaction.logs)
    ? actualEventOrTransaction.logs[0]
    : actualEventOrTransaction;

  if (!event) {
    assert.fail(new Error('No event was generated from this transaction'));
  }

  // Assert the names are the same.
  assert.equal(event.event, expectedEvent);

  assertDeepEqual(event.args, expectedArgs);
  // Note: this means that if you don't assert args they'll pass regardless.
  // Ensure you pass in all the args you need to assert on.
};

/**
 *  Convenience method to assert that two objects or arrays which contain nested BN.js instances are equal.
 *  @param actual What you received
 *  @param expected The shape you expected
 */
const assertDeepEqual = (actual, expected, context) => {
  // Check if it's a value type we can assert on straight away.
  if (BN.isBN(actual) || BN.isBN(expected)) {
    assertBNEqual(actual, expected, context);
  } else if (
    typeof expected === 'string' ||
    typeof actual === 'string' ||
    typeof expected === 'number' ||
    typeof actual === 'number' ||
    typeof expected === 'boolean' ||
    typeof actual === 'boolean'
  ) {
    assert.equal(actual, expected, context);
  }
  // Otherwise dig through the deeper object and recurse
  else if (Array.isArray(expected)) {
    for (let i = 0; i < expected.length; i++) {
      assertDeepEqual(actual[i], expected[i], `(array index: ${i}) `);
    }
  } else {
    for (const key of Object.keys(expected)) {
      assertDeepEqual(actual[key], expected[key], `(key: ${key}) `);
    }
  }
};

module.exports = {
  fastForward,
  assertEventEqual,
};
