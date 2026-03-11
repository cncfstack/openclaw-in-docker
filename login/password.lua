-- /usr/local/openresty/site/lualib/password.lua

local resty_sha256 = require "resty.sha256"
local str = require "resty.string"  -- 保留但仅使用 to_hex
local random = require "resty.random"

-- 新增 hex_to_binary 函数（替代缺失的 from_hex）
local function hex_to_binary(hex)
    return (hex:gsub('..', function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

local _M = {}

function _M.hash(password)
    local salt = random.bytes(16)
    local sha256 = resty_sha256:new()
    sha256:update(password)
    sha256:update(salt)
    return str.to_hex(salt) .. ":" .. str.to_hex(sha256:final())
end

function _M.verify(password, stored_hash)
    local salt_hex, hash = stored_hash:match("^(.+):(.+)$")
    
    if not salt_hex or not hash then
        local sha256 = resty_sha256:new()
        sha256:update(password)
        return str.to_hex(sha256:final()) == stored_hash
    end
    
    -- 关键修复：使用自定义 hex_to_binary 替代 from_hex
    local salt = hex_to_binary(salt_hex)
    local sha256 = resty_sha256:new()
    sha256:update(password)
    sha256:update(salt)
    
    return str.to_hex(sha256:final()) == hash
end

return _M