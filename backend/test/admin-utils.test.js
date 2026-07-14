const test = require('node:test');
const assert = require('node:assert/strict');
const {
  quoteIdentifier,
  buildPrimaryKeyWhere,
  validateColumns,
} = require('../src/routes/admin');
const { serializeUser } = require('../src/utils/serializers');

const metadata = {
  name: 'follows',
  columns: [
    { column_name: 'follower_id', protected: false },
    { column_name: 'followed_id', protected: false },
    { column_name: 'password_hash', protected: true },
  ],
  primaryKey: ['follower_id', 'followed_id'],
};

test('identifier çift tırnakları güvenli biçimde escape eder', () => {
  assert.equal(quoteIdentifier('a"b'), '"a""b"');
});

test('composite primary key koşulunu parametreli kurar', () => {
  assert.deepEqual(
    buildPrimaryKeyWhere(metadata, { follower_id: 'one', followed_id: 'two' }, 3),
    {
      sql: '"follower_id" = $3 AND "followed_id" = $4',
      values: ['one', 'two'],
    },
  );
});

test('eksik composite primary key reddedilir', () => {
  assert.throws(
    () => buildPrimaryKeyWhere(metadata, { follower_id: 'one' }),
    /Birincil anahtar alanları gerekli/,
  );
});

test('password_hash erişimi reddedilir', () => {
  assert.throws(
    () => validateColumns(metadata, { password_hash: 'plaintext' }),
    /erişilemez/,
  );
});

test('bilinmeyen sütun reddedilir', () => {
  assert.throws(
    () => validateColumns(metadata, { arbitrary_sql: 'DROP TABLE users' }),
    /Geçersiz sütun/,
  );
});

test('kullanıcı API çıktısı parola özeti içermez', () => {
  const user = serializeUser({
    id: 'id',
    nickname: 'nickname',
    username: 'name',
    email: 'user@example.com',
    role: 'user',
    created_at: new Date('2026-01-01T00:00:00Z'),
    password_hash: 'secret-hash',
  });
  assert.equal(Object.hasOwn(user, 'passwordHash'), false);
  assert.equal(Object.hasOwn(user, 'password_hash'), false);
});
