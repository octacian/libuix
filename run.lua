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

local function ends_with(str, ending)
	print_debug(str .. " ends with " .. ending .. "? Ending: " .. str:sub(-(#ending + 4), -5))
	return str:sub(-(#ending + 4), -5) == ending
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
local retain = 0
for line in file:lines() do
	-- if line is a header and the entry should be retained, retain 2 lines (this and the next)
	if line:find(".lua") and not (line:find("/usr/") or line:find("_spec")) and (filter == "" or ends_with(line, filter)) then
		retain = 2
	end

	-- if a line should be retained, insert it into lines and decrement retainer
	if retain > 0 then
		table.insert(lines, line)
		retain = retain - 1
	end
end

file = io.open(STATS_FILE_NAME, "w")
for _, line in ipairs(lines) do
	file:write(line .. "\n")
end
file:close()

os.execute("sleep 1")
os.execute("luacov")
os.execute("less " .. REPORT_FILE_NAME)
