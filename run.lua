#! /usr/bin/lua5.1

--[[ run.lua usage
	- Run with no arguments to run unit tests and generate coverage reports.
	- Run with one argument to only test and generate coverage reports for files where the argument is a
	  substring of the file name.
]]

local STATS_FILE_NAME = "luacov.stats.out"
local REPORT_FILE_NAME = "luacov.report.out"
local DEBUG = os.getenv("DEBUG") == "true" and true or false

local function print_debug(...)
	if DEBUG then print(...) end
end

local function exec(cmd)
	print("> " .. cmd)
	os.execute(cmd)
end

os.remove(STATS_FILE_NAME)

local filter = arg[1]
if filter == nil then filter = "" end

local pattern = ""
if filter ~= "" then
	pattern = ("--pattern='%s_spec'"):format(filter)
end

exec(("busted --lua=lua5.1 --coverage %s ."):format(pattern))

local file = io.open(STATS_FILE_NAME, "r")
local lines = {}
local ignore_line = 0
for line in file:lines() do
	if ignore_line == 1 then
		print_debug(tostring(ignore_line) .. "- "  .. " " .. line)
		ignore_line = 0
	elseif line:find("/usr/") or line:find("_spec") or (ignore_line == 0 and filter ~= "" and not line:find(filter)) then
		ignore_line = 1
		print_debug(tostring(ignore_line) .. "! "  .. " " .. line)
	else
		print_debug(tostring(ignore_line) .. "+ "  .. " " .. line)
		table.insert(lines, line)
		if ignore_line == -1 then
			if line:find(":") then ignore_line = 0 end
		else ignore_line = -1 end
	end
end
file:close()

file = io.open(STATS_FILE_NAME, "w")
for _, line in ipairs(lines) do
	file:write(line .. "\n")
end
file:close()

os.execute("sleep 1")
os.execute("luacov")
os.execute("less " .. REPORT_FILE_NAME)
