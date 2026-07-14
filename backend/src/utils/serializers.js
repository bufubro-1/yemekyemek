function serializeUser(row) {
  return {
    id: row.id,
    nickname: row.nickname,
    username: row.username,
    email: row.email,
    createdAt: new Date(row.created_at).toISOString(),
    role: row.role,
  };
}

function serializeRestaurant(row, menuCategories = []) {
  return {
    ownerUserId: row.owner_id,
    name: row.name,
    description: row.description,
    phone: row.phone,
    address: row.address,
    menuCategories,
  };
}

module.exports = { serializeUser, serializeRestaurant };
