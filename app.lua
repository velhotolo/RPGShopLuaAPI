pcall(require, "luarocks.loader") -- calling everything
local Pegasus = require("pegasus")
local json = require("dkjson")
local db = require("db")

local server = Pegasus:new({
	port = 3000,
	location = "./public",
})

-- 1. Helper for sending JSON
local function send_json(rep, status, data)
	rep.status = status
	rep:addHeader("Content-Type", "application/json")
	rep:write(json.encode(data))
end

-- 2. Helper to read raw body of the request
local function get_raw_body(req)
	if req.body and type(req.body) == "string" and #req.body > 0 then
		return req.body
	end

	local headers = req:headers() or {}
	local content_length = tonumber(headers["Content-Length"] or headers["content-length"])

	if content_length and content_length > 0 then
		local ok, data = pcall(function()
			return req:receiveBody(content_length)
		end)
		if ok and data then
			return data
		end
	end

	return nil
end

local function parse_item(req)
	local raw = get_raw_body(req)
	if not raw then
		return nil, "Body request empty of invalid."
	end

	local payload, _, err = json.decode(raw)
	if err or type(payload) ~= "table" then
		return nil, "Invalid JSON."
	end

	if type(payload.name) ~= "string" or payload.name == "" then
		return nil, "'name' can't be an empty text."
	end

	local price = tonumber(payload.price)
	if not price or price < 0 then
		return nil, "'price' must be positive."
	end

	local quantity = tonumber(payload.quantity or 1)
	if not quantity or quantity < 0 or quantity % 1 ~= 0 then
		return nil, "'quantity' must be a positive integer."
	end

	return { name = payload.name, price = price, quantity = quantity }
end
server:start(function(req, rep)
	local path = req:path()
	local method = req:method()
	local item_id = path:match("^/items/(%d+)$")

	-- GET show items
	if path == "/items" and method == "GET" then
		local items = db.get_all()
		send_json(rep, 200, items)
		return
	end

	-- GET show item by ID
	if item_id and method == "GET" then
		local item = db.get_by_id(tonumber(item_id))
		if item then
			send_json(rep, 200, item)
		else
			send_json(rep, 404, { error = "Can't find item in the shop." })
		end
		return
	end
	local new_id = 0

	-- POST register items
	if path == "/items" and method == "POST" then
		local raw = get_raw_body(req)
		local payload = raw and json.decode(raw)

		if type(payload) ~= "table" or type(payload.name) ~= "string" or payload.name == "" then
			send_json(rep, 400, { error = "Please type in the 'name'." })
			return
		end

		new_id = db.create(payload.name, payload.price, payload.quantity)
		if new_id then
			send_json(rep, 201, db.get_by_id(new_id))
		else
			send_json(rep, 500, { error = "Error registering in DataBase." })
		end
		return
	end

	-- PUT update items by ID
	if item_id and method == "PUT" then
		local data, err = parse_item(req)
		if not data then
			send_json(rep, 400, { error = err })
			return
		end

		local id_num = tonumber(item_id)
		if db.update(data.name, data.price, data.quantity) then
			send_json(rep, 200, db.get_by_id(id_num))
		else
			send_json(rep, 404, { error = "Couldn't find item for update." })
		end
		return
	end

	-- DELETE by ID
	if item_id and method == "DELETE" then
		local deleted = db.delete(tonumber(item_id))
		if deleted then
			send_json(rep, 200, { message = "Item successfully removed." })
		else
			send_json(rep, 404, { error = "Couldn't find item to remove." })
		end
		return
	end

	send_json(rep, 404, { error = "Can't find route." })
end)
