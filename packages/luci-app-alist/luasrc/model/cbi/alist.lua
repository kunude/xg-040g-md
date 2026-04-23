local fs = require "nixio.fs"
local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()

m = Map("alist", "Alist Configuration", "Configure Alist file listing service")

s = m:section(TypedSection, "alist", "Alist Settings")
s.anonymous = true
s.addremove = false

enabled = s:option(Flag, "enabled", "Enable Alist service")
enabled.default = 0
enabled.rmempty = false

port = s:option(Value, "port", "Port", "Port to listen on")
port.default = "5244"
port.datatype = "port"
port.rmempty = false

data_dir = s:option(Value, "data_dir", "Data Directory", "Directory to store alist data")
data_dir.default = "/etc/alist"
data_dir.rmempty = false

log_level = s:option(List, "log_level", "Log Level")
log_level.default = "info"
log_level:value("trace", "Trace")
log_level:value("debug", "Debug")
log_level:value("info", "Info")
log_level:value("warn", "Warn")
log_level:value("error", "Error")

s:option(Button, "_restart", "Restart Service"):depends("enabled", "1")

return m