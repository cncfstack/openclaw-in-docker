-- /usr/local/openresty/site/lualib/password.lua
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