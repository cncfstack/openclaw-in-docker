-- /usr/local/openresty/site/lualib/ratelimit.lua
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

local limit = ngx.shared.rate_limit
local ip = ngx.var.remote_addr
local uri = ngx.var.uri

-- 不同接口不同限制
local limits = {
    ["/api/login"] = { count = 600, window = 60 },      -- 登录：5次/分钟
    ["default"] = { count = 60, window = 60 }         -- 默认：60次/分钟
}

local config = limits[uri] or limits["default"]
local key = "rate:" .. ip .. ":" .. uri

local current = limit:get(key) or 0
if current >= config.count then
    ngx.status = 429
    ngx.header.content_type = 'application/json'
    ngx.say('{"error":"请求过于频繁，请稍后再试"}')
    return ngx.exit(429)
end

-- 增加计数
limit:incr(key, 1, config.window)

-- 如果这是第一次设置，确保过期时间
if current == 0 then
    limit:expire(key, config.window)
end