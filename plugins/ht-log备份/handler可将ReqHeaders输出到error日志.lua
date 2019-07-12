local body_transformer = require "kong.plugins.response-transformer.body_transformer"
local header_transformer = require "kong.plugins.response-transformer.header_transformer"


local is_body_transform_set = header_transformer.is_body_transform_set
local is_json_body = header_transformer.is_json_body
local concat = table.concat
local kong = kong
local ngx = ngx


local ResponseTransformerHandler = {}


function ResponseTransformerHandler:header_filter(conf)
  local body, err, mimetype = kong.request.get_headers()
  local my_request_body="{"
  for key, value in pairs(body) do      
    my_request_body=my_request_body.."\""..key.."\""..":".."\""..value.."\""..","
  end
  my_request_body=string.sub(my_request_body, 1, -2).."}"
  kong.log.err("header_filter------------------------------------------ ",my_request_body)
end

ResponseTransformerHandler.PRIORITY = 10
ResponseTransformerHandler.VERSION = "2.0.0"


return ResponseTransformerHandler
