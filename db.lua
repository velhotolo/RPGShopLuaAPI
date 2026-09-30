local sqlite3 = require("lsqlite3")

local db = sqlite3.open("shop.db")

db:exec([[
CREATE TABLE IF NOT EXISTS items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    price REAL NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1
);
]])

local M = {}

local function findNextId()
	local check_stmt = db:prepare("SELECT if FROM items WHERE id = 1")
	if check_stmt then
		local exists = (check_stmt:step() == sqlite3.ROW)
		check_stmt:finalize()
		if not exists then
			return 1
		end
	end

	local query = [[
  SELECT MIN(t1.id +1) AS next_id 
  FROM items t1 
  LEFT JOIN items t2 ON t1.id + 1 = t2.id 
  WHERE T2.id IS NULL 
  ]]

	local stmt = db:prepare(query)
	if not stmt then
		return 1
	end

	local next_id = 1
	if stmt:step() == sqlite3.ROW then
		local row = stmt:get_named_values()
		next_id = row.next_id or 1
	end
	stmt:finalize()

	return next_id
end

function M.get_all()
	local items = {}
	local stmt = db:prepare("SELECT id, name, price, quantity FROM items ORDER BY id ASC")

	if not stmt then
		return items
	end

	while stmt:step() == sqlite3.ROW do
		local row = stmt:get_named_values()
		table.insert(items, row)
	end

	stmt:finalize()
	return items
end

function M.get_by_id(id)
	local stmt = db:prepare("SELECT id, name, price, quantity FROM items WHERE id = ?")

	if not stmt then
		return nil
	end

	stmt:bind_values(id)

	local item = nil
	if stmt:step() == sqlite3.ROW then
		item = stmt:get_named_values()
	end

	stmt:finalize()
	return item
end

function M.create(name, price, quantity)
	local new_id = findNextId()
	local stmt = db:prepare("INSERT INTO items (id, name, price, quantity) VALUES (?, ?, ?, ?)")
	if not stmt then
		return nil
	end

	stmt:bind_values(new_id, name, price, quantity)

	local res = stmt:step()
	stmt:finalize()

	if res == sqlite3.DONE then
		return new_id
	end
	return nil
end

function M.update(id, name, price, quantity)
	local stmt = db:prepare("UPDATE items SET name = ?, price = ?, quantity = ? WHERE id = ?")

	if not stmt then
		return false
	end

	stmt:bind_values(name, price, quantity, id)

	local res = stmt:step()
	stmt:finalize()

	return res == sqlite3.DONE and db:changes() > 0
end

function M.delete(id)
	local stmt = db:prepare("DELETE FROM items WHERE id = ?")

	if not stmt then
		return false
	end

	stmt:bind_values(id)

	local res = stmt:step()
	stmt:finalize()

	return res == sqlite3.DONE and db:changes() > 0
end

return M
