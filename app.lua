pcall(require, "luarocks.loader") -- calling everything
local Pegasus = require("pegasus")
local json = require("dkjson")
local M = require("db")

local server = Pegasus:new({
    host = "127.0.0.1",
    port = 3000,
})

local MAX_BODY_BYTES = 8 * 1024
local MAX_NAME_LENGTH = 100
local MAX_QUANTITY = 1000000
local API_TOKEN = os.getenv("SHOP_API_TOKEN")

-- 1. Helper for sending JSON
local function send_json(rep, status, data)
    rep:statusCode(status)
    rep:addHeader("Content-Type", "application/json")
    rep:write(json.encode(data))
end

-- 2. Helper to read raw body of the request
local function get_raw_body(req)
    if type(req.body) == "string" and #req.body > 0 then
        if #req.body > MAX_BODY_BYTES then
            return nil, "Request body too large.", 413
        end
        return req.body
    end

    local headers = req:headers() or {}
    local content_length = tonumber(headers["Content-Length"] or headers["content-length"])

    if not content_length or content_length <= 0 then
        return nil, "Request body empty or invalid.", 400
    end

    if content_length > MAX_BODY_BYTES then
        return nil, "Request body too large.", 413
    end

    local ok, data = pcall(function()
        return req:receiveBody(content_length)
    end)

    if ok and data then
        return data
    end

    if not ok or not data then
        return nil, "Request body empty or invalid.", 400
    end
end



local function parse_item(req)
    local raw, body_err, body_status = get_raw_body(req)

    if not raw then
        return nil, body_err, body_status
    end

    local payload, _, err = json.decode(raw)
    if err or type(payload) ~= "table" then
        return nil, "Invalid JSON.", 400
    end

    if type(payload.name) ~= "string" or payload.name == "" then
        return nil, "'name' can't be an empty text.", 400
    end

    local name_length = #payload.name
    if not name_length or name_length > MAX_NAME_LENGTH then
        return nil, "'name' must be valid text up to " .. MAX_NAME_LENGTH .. " characters.", 400
    end


    local price = tonumber(payload.price)
    if not price or price < 0 or price ~= price or price == math.huge then
        return nil, "'price' must be a non-negative number.", 400
    end

    local quantity = tonumber(payload.quantity or 1)
    if not quantity or quantity < 0 or quantity % 1 ~= 0 or quantity > MAX_QUANTITY then
        return nil, "'quantity' must be an integer between 0 and " .. MAX_QUANTITY .. ".", 400
    end

    return { name = payload.name, price = price, quantity = tonumber(quantity) }
end

local function is_authorized(req)
    if not API_TOKEN then
        return true
    end

    local headers = req:headers() or {}
    -- FIXED: Added the required space after "Bearer"
    return headers["authorization"] == "Bearer " .. API_TOKEN
end

local function handle(req, rep)
    local path = req:path()
    local method = req:method()

    -- FIXED: Added a matcher for the base /items route
    local is_items_route = path:match("^/items/?$")
    local item_id = path:match("^/items/(%d+)$")

    if (method == "POST" or method == "PUT" or method == "DELETE") and not is_authorized(req) then
        send_json(rep, 401, { error = "Missing or invalid token." })
        return
    end

    -- GET show items
    if is_items_route and method == "GET" then
        M.get_all()
        send_json(rep, 200, M.items)
        return
    end

    -- POST register items
    if is_items_route and method == "POST" then
        local data, err, status = parse_item(req)

        if not data then
            send_json(rep, status or 400, { error = err })
            return -- FIXED: Added missing return to stop execution
        end

         local newId = M.create(data.name, data.price, data.quantity)

        if newId then
            send_json(rep, 201, M.get_by_id(newId))
        else
            send_json(rep, 500, { error = "Error registering in DataBase." })
        end
        return
    end

    -- GET show item by ID
    if item_id and method == "GET" then
        local item = M.get_by_id(tonumber(item_id))
        if item then
            send_json(rep, 200, item)
        else
            send_json(rep, 404, { error = "Can't find item in the shop." })
        end
        return
    end

    -- PUT update items by ID
    if item_id and method == "PUT" then
        local data, err, status = parse_item(req)
        if not data then
            send_json(rep, status or 400, { error = err })
            return
        end

        local id_num = tonumber(item_id)

       -- UPDATE
        local putter = M.update(data.name, data.price, data.quantity, id_num)

        if putter then
            send_json(rep, 200, M.get_by_id(id_num))
        else
            send_json(rep, 404, { error = "Couldn't find item for update." })
        end
        return
    end

    -- DELETE by ID
    if item_id and method == "DELETE" then
        local deleted = M.delete(tonumber(item_id))
        if deleted then
            send_json(rep, 200, { message = "Item successfully removed." })
        else
            send_json(rep, 404, { error = "Couldn't find item to remove." })
        end
        return
    end

    -- If no route matched at all
    send_json(rep, 404, { error = "Endpoint not found or Method not allowed." })
end

server:start(function(req, rep)
    local ok, err = pcall(handle, req, rep)
    if not ok then
        print("Internal error: " .. tostring(err))
        pcall(send_json, rep, 500, { error = "Internal server error. " })
    end
end)

