# 🗡️ RPG Tavern Shop API

A lightweight RESTful API and database built from scratch in Lua, simulating an inventory system for an RPG shop.

## 📖 Overview

This project was built as a hands-on exercise to deepen my understanding of databases, REST APIs, and backend architectures. While considering exploring other backend stacks, I decided to first solidify foundational concepts using **Java** and **Lua**.

Building a modern web API in Lua presents unique challenges due to its minimalist standard library. To address this, I composed a lean stack using lightweight external modules to handle HTTP routing, JSON parsing, and relational persistence.

---

## 🛠️ Tech Stack

* **Language:** [Lua](https://www.lua.org/) 5.3 or newer
* **HTTP Server:** [Pegasus.lua](https://github.com/EvandroLG/pegasus.lua)
* **Serialization:** [dkjson](https://github.com/dhkblaszyk/dkjson)
* **Database:** [SQLite3](https://www.sqlite.org/) (via `lsqlite3`)

---

## ✨ Features

* Full CRUD operations for shop items (name, price, quantity).
* Direct SQLite persistence with schema initialization.
* Request body parsing and validation (type, size and range checks).
* Proper HTTP status codes (`200`, `201`, `400`, `401`, `404`, `413`, `500`).
* Optional token authentication for write operations.

---

## 🚀 Running locally

### 1. Install Lua, LuaRocks and system libraries

Some modules are compiled during installation, so you also need a C compiler and the SQLite and zlib headers.

**Arch Linux**

```bash
sudo pacman -S --needed lua luarocks sqlite zlib base-devel
```

**Debian / Ubuntu**

```bash
sudo apt install lua5.4 liblua5.4-dev luarocks libsqlite3-dev zlib1g-dev build-essential
```

**macOS (Homebrew)**

```bash
brew install lua luarocks sqlite
```

Check that Lua is 5.3 or newer:

```bash
lua -v
```

### 2. Install the Lua modules

`--local` installs the modules in your home folder, so `sudo` is not needed. Replace `5.4` with your Lua version if it is different.

```bash
luarocks --local --lua-version=5.4 install pegasus
luarocks --local --lua-version=5.4 install dkjson
luarocks --local --lua-version=5.4 install lsqlite3
```

Then let Lua find them (run this in every new terminal, or add it to your `~/.bashrc` / `~/.zshrc`):

```bash
eval "$(luarocks --lua-version=5.4 path)"
```

### 3. Clone and start the server

```bash
git clone https://github.com/velhotolo/RPGShopLuaAPI.git
cd RPGShopLuaAPI
lua app.lua
```

You should see `Pegasus is up on 127.0.0.1:3000`. Keep this terminal open and use a second one for the requests below.

The database file `shop.db` is created automatically on the first run, with an empty `items` table. It is not versioned in Git, so each person starts with their own empty shop.

---

## 🧪 Testing the API

The examples use `curl`; `-i` shows the HTTP status line, so you can check each response code.

**List all items**

```bash
curl -i http://127.0.0.1:3000/items
```

**Create an item** (`quantity` is optional and defaults to 1)

```bash
curl -i -X POST http://127.0.0.1:3000/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Bag of Holding", "price": 10000, "quantity": 1}'
```

**Get one item by id**

```bash
curl -i http://127.0.0.1:3000/items/1
```

**Update an item** (send all three fields)

```bash
curl -i -X PUT http://127.0.0.1:3000/items/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "Bag of Holding", "price": 9500, "quantity": 2}'
```

**Delete an item**

```bash
curl -i -X DELETE http://127.0.0.1:3000/items/1
```

**Check the validation** (should return `400 Bad Request`)

```bash
curl -i -X POST http://127.0.0.1:3000/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Cursed Coin", "price": -5}'
```

### Endpoints

| Method | Route         | Description         | Success |
|--------|---------------|---------------------|---------|
| GET    | `/items`      | List all items      | `200`   |
| GET    | `/items/{id}` | Get one item        | `200`   |
| POST   | `/items`      | Create an item      | `201`   |
| PUT    | `/items/{id}` | Replace an item     | `200`   |
| DELETE | `/items/{id}` | Remove an item      | `200`   |

### Validation rules

* `name`: required text, up to 100 characters.
* `price`: required number, `0` or greater.
* `quantity`: optional integer between `0` and `1000000` (default `1`).
* Request body: up to 8 KB; larger bodies return `413`.

---

## 🔒 Security notes

* The server listens on `127.0.0.1`, so only your own machine can reach it.
* Write operations (`POST`, `PUT`, `DELETE`) can be protected with a token. Start the server with:

  ```bash
  SHOP_API_TOKEN=choose-a-long-secret lua app.lua
  ```

  and send the token in each write request:

  ```bash
  curl -i -X DELETE http://127.0.0.1:3000/items/1 \
    -H "Authorization: Bearer choose-a-long-secret"
  ```

  Requests without a valid token get `401 Unauthorized`. Reads (`GET`) stay open.
* This is a learning project: there is no HTTPS or rate limiting, so it should not be exposed to the internet as it is.

---

## 💡 Key Takeaways & Learnings

* **Building from primitives:** Lua doesn't come with batteries included for web development; orchestrating Pegasus, JSON decoders, and raw C-based database bindings provided deep insights into how HTTP servers and database drivers interact behind the scenes.
* **SQL & identifiers:** I first implemented custom query logic to recycle the IDs of deleted items, then replaced it with SQLite's `AUTOINCREMENT` after learning that reused IDs can make old references silently point to a different item.
* **Next Steps:** Moving forward with related projects to further cement backend architecture and database management skills.
