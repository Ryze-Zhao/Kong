local body_transformer = require "kong.plugins.ht-log.body_transformer"
local header_transformer = require "kong.plugins.ht-log.header_transformer"
local send_http = require "kong.plugins.ht-log.send_http"

local is_body_transform_set = header_transformer.is_body_transform_set
local is_json_body = header_transformer.is_json_body
local send_payload=send_http.send_payload
local concat = table.concat
local kong = kong
local ngx = ngx


local MyFunc = {}



function MyFunc.json_array_concat(entries)
    return "[" .. table_concat(entries, ",") .. "]"
  end
  
  
function MyFunc.get_queue_id(conf)
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
  
  -- 获取request_headers，限于access阶段
 function MyFunc.get_request_headers(conf)
    local body, err, mimetype = kong.request.get_headers()
    local my_request_headers="{"
    for key, value in pairs(body) do      
      my_request_headers=my_request_headers.."\""..key.."\""..":".."\""..value.."\""..","
    end
    my_request_headers=string.sub(my_request_headers, 1, -2).."}"
    send_payload(self,conf,my_request_headers)
    kong.log.notice("my_request_headers------------------------------------------ ",my_request_headers)
  end
  -- 获取request_body，限于access阶段
 function MyFunc.get_request_body(conf)
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
function MyFunc.get_response_headers(conf)
    local body, err, mimetype = kong.response.get_headers()
    local my_response_headers="{"
    for key, value in pairs(body) do      
      my_response_headers=my_response_headers.."\""..key.."\""..":".."\""..value.."\""..","
    end
    my_response_headers=string.sub(my_response_headers, 1, -2).."}"
    kong.log.notice("my_response_headers------------------------------------------ ",my_response_headers)
  end


  -- 获取response_status，获取状态码
  function MyFunc.get_response_status(conf)
    local status = kong.response.get_status()
    kong.log.notice("my_response_status------------------------------------------ ",status)
  end

  -- 获取client_ip_port，获取IP和Port
  -- (端口同理)返回发出请求的客户端的远程地址。这将 始终返回直接连接到Kong的客户端的地址。也就是说，在负载均衡器位于Kong前面的情况下，此函数将返回负载均衡器的地址，而不是下游客户端的地址。
  function MyFunc.get_client_ip_port(conf)
    -- certificate, rewrite, access, header_filter, body_filter, log
    local client_get_ip=kong.client.get_ip()
    -- certificate, rewrite, access, header_filter, body_filter, log
    local client_get_port=kong.client.get_port()
    local ip_port="{ip:"..client_get_ip..",port:"..client_get_port.."}"
    send_payload(self,conf,ip_port)
    kong.log.notice("my_client_ip_port------------------------------------------ ",ip_port)
  end

  -- 获取client_forward_ip_port，获取转发的IP和Port
  -- (端口同理)返回发出请求的客户端的远程地址。与kong.client.get_ip此不同的是 ，当负载均衡器位于Kong前面时，此功能将考虑转发地址。
  function MyFunc.get_client_forward_ip_port(conf)
    -- certificate, rewrite, access, header_filter, body_filter, log
    local client_get_forwarded_ip=kong.client.get_forwarded_ip()
    -- certificate, rewrite, access, header_filter, body_filter, log
    local client_get_forwarded_port=kong.client.get_forwarded_port()
    local forward_ip_port="{forward_ip:"..client_get_forwarded_ip..",forward_port:"..client_get_forwarded_port.."}"
    send_payload(self,conf,forward_ip_port)
    kong.log.notice("my_client_forward_ip_port------------------------------------------ ",forward_ip_port)
  end




MyFunc.PRIORITY = 10
MyFunc.VERSION = "2.0.0"


return MyFunc
