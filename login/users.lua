-- /usr/local/openresty/site/lualib/users.lua

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