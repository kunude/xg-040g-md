module("luci.controller.alist", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/alist") then
        return
    end
    
    entry({"admin", "services", "alist"}, cbi("alist"), _("Alist"), 100)
    entry({"admin", "services", "alist", "status"}, call("action_status"), _("Status"), 10)
end

function action_status()
    local e = {}
    e.running = luci.sys.call("pgrep alist >/dev/null") == 0
    e.port = 5244
    luci.http.prepare_content("json")
    luci.http.write_json(e)
end