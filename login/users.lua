-- /usr/local/openresty/site/lualib/users.lua
-- 实际应用中应从数据库读取

local password = require "password"  -- 添加在文件顶部

local _M = {}

-- 创建用户函数（自动哈希化）
local function create_user(username, plain_password, email, role)
    return {
        username = username,
        password_hash = password.hash(plain_password),  -- 自动计算哈希
        email = email,
        role = role,
        created_at = os.time()
    }
end


-- 预置测试用户（密码自动哈希化）
_M["admin"] = create_user("admin", "admin123", "admin@example.com", "admin")
_M["openclaw"] = create_user("openclaw", "openclaw", "user@openclaw.ai", "user")

return _M