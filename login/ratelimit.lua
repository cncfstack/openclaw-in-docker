-- /usr/local/openresty/site/lualib/ratelimit.lua
local limit = ngx.shared.rate_limit
local ip = ngx.var.remote_addr
local uri = ngx.var.uri

-- 不同接口不同限制
local limits = {
    ["/api/login"] = { count = 60, window = 60 },      -- 登录：5次/分钟
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