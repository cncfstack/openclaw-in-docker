-- /usr/local/openresty/site/lualib/users.lua
-- MIT License

-- Copyright (c) 2026 藏云阁

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local password = require "password"

-- 从环境变量安全获取凭据（带默认值防崩溃）
local function get_env(name, default)
    local value = os.getenv(name)
    if value and value ~= "" then
        return value
    end
    ngx.log(ngx.WARN, "Environment variable ", name, " not set, using default value")
    return default
end


local openclaw_user = get_env("OPENCLAW_USER", "openclaw")
local openclaw_password = get_env("OPENCLAW_PASSWORD", "openclaw")

local _M = {}

local function create_user(username, plain_password, email, role)
    return {
        username = username,
        password_hash = password.hash(plain_password),  -- 自动哈希化
        email = email,
        role = role,
        created_at = os.time()
    }
end

_M[openclaw_user] = create_user(openclaw_user, openclaw_password, "user@openclaw.ai", "user")

return _M