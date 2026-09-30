# 🗡️ RPG Tavern Shop API

A lightweight RESTful API and database built from scratch in Lua, simulating an inventory system for an RPG shop.

## 📖 Overview

This project was built as a hands-on exercise to deepen my understanding of databases, REST APIs, and backend architectures. While considering exploring other backend stacks, I decided to first solidify foundational concepts using **Java** and **Lua**. 

Building a modern web API in Lua presents unique challenges due to its minimalist standard library. To address this, I composed a lean stack using lightweight external modules to handle HTTP routing, JSON parsing, and relational persistence.

---

## 🛠️️ Tech Stack

* **Language:** [Lua](https://www.lua.org/)
* **HTTP Server:** [Pegasus.lua](https://github.com/EvandroLG/pegasus.lua)
* **Serialization:** [dkjson](https://github.com/dhkblaszyk/dkjson)
* **Database:** [SQLite3](https://www.sqlite.org/) (via `lsqlite3`)

---

## ✨ Features

* Full CRUD operations for shop items (name, price, quantity).
* Direct SQLite persistence with schema initialization.
* Smart primary key reuse to fill ID gaps upon deletion.
* Request body parsing and validation.

---

## 💡 Key Takeaways & Learnings

* **Building from primitives:** Lua doesn't come with batteries included for web development; orchestrating Pegasus, JSON decoders, and raw C-based database bindings provided deep insights into how HTTP servers and database drivers interact behind the scenes.
* **SQL & Gap Filling:** Implemented custom query logic in SQLite to manage and recycle sequential identifiers cleanly.
* **Next Steps:** Moving forward with related projects to further cement backend architecture and database management skills.
