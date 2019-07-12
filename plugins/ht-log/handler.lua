local body_transformer = require "kong.plugins.ht-log.body_transformer"
local header_transformer = require "kong.plugins.ht-log.header_transformer"
local send_http = require "kong.plugins.ht-log.send_http"
local my_func = require "kong.plugins.ht-log.my_func"

local is_body_transform_set = header_transformer.is_body_transform_set
local is_json_body = header_transformer.is_json_body
local send_http_func=send_http.send_payload
local my_func_get_request_headers=my_func.get_request_headers
local my_func_get_request_body=my_func.get_request_body
local my_func_get_response_headers=my_func.get_response_headers
local my_func_get_response_status=my_func.get_response_status
local my_func_get_client_ip_port=my_func.get_client_ip_port
local my_func_get_client_forward_ip_port=my_func.get_client_forward_ip_port
local concat = table.concat
local kong = kong
local ngx = ngx


local ResponseTransformerHandler = {}

-- 插件构造函数
function ResponseTransformerHandler:new()
 
end

function ResponseTransformerHandler:init_worker()
  
end

function ResponseTransformerHandler:certificate(conf)
 
end

function ResponseTransformerHandler:rewrite(conf)

end

function ResponseTransformerHandler:access(conf)
  -- my_func_get_request_headers(conf)
  -- my_func_get_request_body(conf)
  -- my_func_get_client_ip_port(conf)
  -- my_func_get_client_forward_ip_port(conf)

end

function ResponseTransformerHandler:header_filter(conf)
  -- my_func_get_response_headers(conf)
  -- my_func_get_response_status(conf)
end

function ResponseTransformerHandler:body_filter(conf)
 
end

function ResponseTransformerHandler:log(conf)

end


ResponseTransformerHandler.PRIORITY = 800
ResponseTransformerHandler.VERSION = "2.0.0"


return ResponseTransformerHandler
