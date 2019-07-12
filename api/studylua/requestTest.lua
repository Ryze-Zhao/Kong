-- 写个关闭redis
local function close_redis(red)  
        if not red then  
            return  
        end  
        local ok, err = red:close()  
        if not ok then  
           return 
        end  
    end

local redisValue=nil
local headers=ngx.req.get_headers()
local ip=headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"
local reqTime=ngx.req.start_time()
local redisKey="Resquest:"..ip.."---"..reqTime
redisValue=table.concat({"客户端IP为：",ip,"\t请求时间为：",reqTime,"\tRedisKey为：",redisKey})

-- redis
local redis = require "resty.redis"
local red = redis:new()
red:set_timeout(1000)
-- 连接redis
local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
        return close_redis(red)
else
-- redisValue=redisValue.."\nredis connetc success===========>"
end

--请求头的内容，还有请求方式
redisValue=table.concat({redisValue,"\n请求头为：",ngx.req.raw_header(),"\n请求方式为：",ngx.req.get_method()})


--request 获取URI的?后的参数
local req_uri_args=ngx.req.get_uri_args()
for k,v in pairs(req_uri_args) do
        if type(v)=="table" then
                redisValue=table.concat({redisValue,"\nURI参数为：",k,"的值为===========>：",v})
        else
                redisValue=table.concat({redisValue,"\nURI参数为：",k,"的值为===========>：",v})
        end
end
-- for i in pairs(req_uri_args) do  
--         ngx.say("参数 ",i," 的值为===========>",req_uri_args[i])  
-- end


--request 获取Body中的参数
ngx.req.read_body()
local req_body_args =ngx.req.get_post_args()
for k,v in pairs(req_body_args) do
        if type(v)=="table" then
                if v==true then
redisValue=table.concat({redisValue,"\nBody参数为：",k})
else
redisValue=table.concat({redisValue,"\nBody参数为：",k,"的值为===========>：",v})
end
                -- ngx.say("Body参数 ",k," 的值为===========>", tableconcat(v,","))
        else
               
if v==true then
redisValue=table.concat({redisValue,"\nBody参数为：",k})
else
redisValue=table.concat({redisValue,"\nBody参数为：",k,"的值为===========>：",v})
end
               --  ngx.say("Body参数 ",k," 的值为===========>",v)
        end
end
-- ngx.say("处理结束","\n")
-- ngx.say("\n")


-- 用于存redis
ok, err = red:set(redisKey, redisValue)
if not ok then
--     ngx.say("\nset data error===========>", err)
    return
end
--ngx.say("\nset data success===========>")
--ngx.say("\n"..redisKey.."--------------"..redisValue)
close_redis(red) 