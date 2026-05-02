const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizeRows } = require('../utils/fileParser');

test('normalizes headerless two-column leads', () => {
  const leads = normalizeRows([
    ['Kedar Dalvi', 7506263908],
    ['Ayesha Khan', '9876543210'],
  ]);

  assert.deepEqual(leads, [
    { name: 'Kedar Dalvi', phone: '7506263908' },
    { name: 'Ayesha Khan', phone: '9876543210' },
  ]);
});

test('skips name and phone header row', () => {
  const leads = normalizeRows([
    ['Name', 'Phone Number'],
    ['Rahul Sharma', '9000000000'],
  ]);

  assert.deepEqual(leads, [
    { name: 'Rahul Sharma', phone: '9000000000' },
  ]);
});

test('supports serial number, name, phone rows', () => {
  const leads = normalizeRows([
    ['Sr No', 'Name', 'Mobile'],
    [1, 'Priya Shah', '9111111111'],
  ]);

  assert.deepEqual(leads, [
    { name: 'Priya Shah', phone: '9111111111' },
  ]);
});
