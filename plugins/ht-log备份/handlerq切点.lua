-- 继承BasePlugin
local BasePlugin = require "kong.plugins.base_plugin"
local HtLog = BasePlugin:extend()

HtLog.PRIORITY=10
HtLog.VERSION="0.1.0"

-- 插件构造函数
function HtLog:new()
  HtLog.super.new(self, "ht-log")
end

function HtLog:init_worker()
  HtLog.super.init_worker(self)
  -- 在这里实现自定义的逻辑
  nginx.log("成功使用自定义HtLog插件")
end

function HtLog:certificate(config)
  HtLog.super.certificate(self)
  -- 在这里实现自定义的逻辑
  nginx.log("成功使用自定义HtLog插件")
end

function HtLog:rewrite(config)
  HtLog.super.rewrite(self)
  -- 在这里实现自定义的逻辑
  nginx.log("成功使用自定义HtLog插件")
end

function HtLog:access(config)
  HtLog.super.access(self)
  -- 在这里实现自定义的逻辑
  nginx.log("成功使用自定义HtLog插件")
end

function HtLog:header_filter(config)
  HtLog.super.header_filter(self)
  -- 在这里实现自定义的逻辑
  nginx.log("成功使用自定义HtLog插件")
end

function HtLog:body_filter(config)
  HtLog.super.body_filter(self)
  -- 在这里实现自定义的逻辑
  nginx.log("成功使用自定义HtLog插件")
end

function HtLog:log(config)
  HtLog.super.log(self)
  -- 在这里实现自定义的逻辑
  nginx.log("成功使用自定义HtLog插件")
end

return HtLog