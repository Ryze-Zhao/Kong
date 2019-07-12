local basic_serializer = require "kong.plugins.log-serializers.basic"
local BatchQueue = require "kong.tools.batch_queue"
local cjson = require "cjson"
local url = require "socket.url"
local http = require "resty.http"
local body_transformer = require "kong.plugins.ht-log.body_transformer"
local header_transformer = require "kong.plugins.ht-log.header_transformer"

local is_body_transform_set = header_transformer.is_body_transform_set
local is_json_body = header_transformer.is_json_body
local concat = table.concat
local kong = kong
local ngx = ngx


local cjson_encode = cjson.encode
local ngx_encode_base64 = ngx.encode_base64
local table_concat = table.concat
local fmt = string.format


local HttpLogHandler = {}


HttpLogHandler.PRIORITY = 12
HttpLogHandler.VERSION = "2.0.0"


local queues = {} -- one queue per unique plugin config

local parsed_urls_cache = {}


-- Parse host url.
-- @param `url` host url
-- @return `parsed_url` a table with host details:
-- scheme, host, port, path, query, userinfo
local function parse_url(host_url)
  local parsed_url = parsed_urls_cache[host_url]

  if parsed_url then
    return parsed_url
  end

  parsed_url = url.parse(host_url)
  if not parsed_url.port then
    if parsed_url.scheme == "http" then
      parsed_url.port = 80
    elseif parsed_url.scheme == "https" then
      parsed_url.port = 443
    end
  end
  if not parsed_url.path then
    parsed_url.path = "/"
  end

  parsed_urls_cache[host_url] = parsed_url

  return parsed_url
end


-- Sends the provided payload (a string) to the configured plugin host
-- @return true if everything was sent correctly, falsy if error
-- @return error message if there was an error
local function send_payload(self, conf, payload)
  local method = conf.method
  local timeout = conf.timeout
  local keepalive = conf.keepalive
  local content_type = conf.content_type
  local http_endpoint = conf.http_endpoint

  local ok, err
  local parsed_url = parse_url(http_endpoint)
  local host = parsed_url.host
  local port = tonumber(parsed_url.port)

  local httpc = http.new()
  httpc:set_timeout(timeout)
  ok, err = httpc:connect(host, port)
  if not ok then
    return nil, "failed to connect to " .. host .. ":" .. tostring(port) .. ": " .. err
  end

  if parsed_url.scheme == "https" then
    local _, err = httpc:ssl_handshake(true, host, false)
    if err then
      return nil, "failed to do SSL handshake with " ..
                  host .. ":" .. tostring(port) .. ": " .. err
    end
  end

  local res, err = httpc:request({
    method = method,
    path = parsed_url.path,
    query = parsed_url.query,
    headers = {
      ["Host"] = parsed_url.host,
      ["Content-Type"] = content_type,
      ["Content-Length"] = #payload,
      ["Authorization"] = parsed_url.userinfo and (
        "Basic " .. ngx_encode_base64(parsed_url.userinfo)
      ),
    },
    body = payload,
  })
  if not res then
    return nil, "failed request to " .. host .. ":" .. tostring(port) .. ": " .. err
  end

  -- always read response body, even if we discard it without using it on success
  local response_body = res:read_body()
  local success = res.status < 400
  local err_msg

  if not success then
    err_msg = "request to " .. host .. ":" .. tostring(port) ..
              " returned status code " .. tostring(res.status) .. " and body " ..
              response_body
  end

  ok, err = httpc:set_keepalive(keepalive)
  if not ok then
    -- the batch might already be processed at this point, so not being able to set the keepalive
    -- will not return false (the batch might not need to be reprocessed)
    kong.log.err("failed keepalive for ", host, ":", tostring(port), ": ", err)
  end

  return success, err_msg
end


local function json_array_concat(entries)
  return "[" .. table_concat(entries, ",") .. "]"
end


local function get_queue_id(conf)
  return fmt("%s:%s:%s:%s:%s:%s",
             conf.http_endpoint,
             conf.method,
             conf.content_type,
             conf.timeout,
             conf.keepalive,
             conf.retry_count,
             conf.queue_size,
             conf.flush_timeout)
end

-- 获取request_headers
local function get_request_headers(conf)
  local body, err, mimetype = kong.request.get_headers()
  local my_request_headers="{"
  for key, value in pairs(body) do      
    my_request_headers=my_request_headers.."\""..key.."\""..":".."\""..value.."\""..","
  end
  my_request_headers=string.sub(my_request_headers, 1, -2).."}"
  send_payload(self,conf,my_request_headers)
  kong.log.notice("my_request_headers------------------------------------------ ",my_request_headers)
end
-- 获取request_body
local function get_request_body(conf)
  local body, err, mimetype = kong.request.get_body()
  local my_request_body="{"
  for key, value in pairs(body) do      
    my_request_body=my_request_body.."\""..key.."\""..":".."\""..value.."\""..","
  end
  my_request_body=string.sub(my_request_body, 1, -2).."}"
  -- kong.response.set_header("get_body",my_request_body)
  local reqValue=nil
  reqValue="{".."client_get_ip="..kong.client.get_ip()..
  ",client_get_port="..kong.client.get_port()..
  ",client_get_forwarded_ip="..kong.client.get_forwarded_ip()..
  ",client_get_forwarded_port="..kong.client.get_forwarded_port()..
  ",request_get_scheme="..kong.request.get_scheme()..
  ",request_get_host="..kong.request.get_host()..
  ",request_get_port="..kong.request.get_port()..
  ",request_get_forwarded_scheme="..kong.request.get_forwarded_scheme()..
  ",request_get_forwarded_host="..kong.request.get_forwarded_host()..
  ",request_get_forwarded_port="..kong.request.get_forwarded_port()..
  ",request_get_http_version="..kong.request.get_http_version()..
  ",request_get_method="..kong.request.get_method()..
  ",get_path="..kong.request.get_path()..
  ",get_path_with_query="..kong.request.get_path_with_query()..
  ",get_raw_query="..kong.request.get_raw_query()..
  -- ",get_header="....
  ",get_body="..my_request_body..
 "}"

--   kong.response.set_header("client_get_ip",kong.client.get_ip())
--   kong.response.set_header("client_get_port",kong.client.get_port())
--   kong.response.set_header("client_get_forwarded_ip",kong.client.get_forwarded_ip())
--   kong.response.set_header("client_get_forwarded_port",kong.client.get_forwarded_port())

--   kong.response.set_header("request_get_scheme",kong.request.get_scheme())
--   kong.response.set_header("request_get_host",kong.request.get_host())
--   kong.response.set_header("request_get_port",kong.request.get_port())
--   kong.response.set_header("request_get_forwarded_scheme",kong.request.get_forwarded_scheme())
--   kong.response.set_header("request_get_forwarded_host",kong.request.get_forwarded_host())
--   kong.response.set_header("request_get_forwarded_port",kong.request.get_forwarded_port())
--   kong.response.set_header("request_get_http_version",kong.request.get_http_version())
--   kong.response.set_header("request_get_method",kong.request.get_method())
--   kong.response.set_header("get_path",kong.request.get_path())
--   kong.response.set_header("get_path_with_query",kong.request.get_path_with_query())
--   kong.response.set_header("get_raw_query",kong.request.get_raw_query())
--   kong.response.set_header("get_query_arg",kong.request.get_query_arg())
--   kong.response.set_header("get_header",kong.request.get_header("User-Agent"))
  -- kong.response.set_header("get_raw_body",kong.request.get_raw_body())
  kong.log.notice("my_request_body------------------------------------------ ",reqValue)
  send_payload(self,conf,reqValue)
end

-- 获取response_headers
local function get_response_headers(conf)
  local body, err, mimetype = kong.response.get_headers()
  local my_response_headers="{"
  for key, value in pairs(body) do      
    my_response_headers=my_response_headers.."\""..key.."\""..":".."\""..value.."\""..","
  end
  my_response_headers=string.sub(my_response_headers, 1, -2).."}"
  kong.log.notice("my_response_headers------------------------------------------ ",my_response_headers)
end





function HttpLogHandler:header_filter(conf)
  get_response_headers(conf)
end

function HttpLogHandler:access(conf)
  get_request_headers(conf)
  get_request_body(conf)
end

return HttpLogHandler
