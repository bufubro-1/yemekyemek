const test = require('node:test');
const assert = require('node:assert/strict');

const {
  normalizeCategoryNames,
  serializeMenuCategory,
  serializeMenuItem,
} = require('../src/routes/restaurants');

test('kategori adlarındaki boşlukları temizler', () => {
  assert.deepEqual(
    normalizeCategoryNames(['  Ana Yemekler  ', 'Tatlılar']),
    ['Ana Yemekler', 'Tatlılar'],
  );
});

test('kategori adlarını büyük küçük harfe duyarsız tekilleştirir', () => {
  assert.deepEqual(
    normalizeCategoryNames([
      'Tatlılar',
      'tatlılar',
      'İçecekler',
      'İÇECEKLER',
    ]),
    ['Tatlılar', 'İçecekler'],
  );
});

test('kategori sırasını korur', () => {
  assert.deepEqual(
    normalizeCategoryNames([
      'Çorbalar',
      'Ana Yemekler',
      'Tatlılar',
    ]),
    ['Çorbalar', 'Ana Yemekler', 'Tatlılar'],
  );
});

test('menü kategorisini API biçimine dönüştürür', () => {
  assert.deepEqual(
    serializeMenuCategory({
      id: 'category-id',
      name: 'Tatlılar',
      sort_order: 2,
      item_count: '4',
    }),
    {
      id: 'category-id',
      name: 'Tatlılar',
      sortOrder: 2,
      itemCount: 4,
    },
  );
});

test('menü ürününü API biçimine dönüştürür', () => {
  assert.deepEqual(
    serializeMenuItem({
      id: 'item-id',
      category_id: 'category-id',
      name: 'Mercimek Çorbası',
      description: 'Günlük hazırlanır.',
      price: '120.50',
      is_available: true,
      sort_order: 1,
      created_at: new Date('2026-08-27T12:00:00Z'),
    }),
    {
      id: 'item-id',
      categoryId: 'category-id',
      name: 'Mercimek Çorbası',
      description: 'Günlük hazırlanır.',
      price: 120.5,
      isAvailable: true,
      sortOrder: 1,
      createdAt: '2026-08-27T12:00:00.000Z',
    },
  );
});