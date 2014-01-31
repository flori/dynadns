#!/usr/bin/env lua

-- Compute a md5 sum by calling out to md5sum shell command. Lame, I know.
function md5(string)
  local filename = "/tmp/dynadns.tmp"
  local sum = io.popen("md5sum >" .. filename, "w")
  sum:write(string)
  sum:close()
  sum = io.open(filename, "r")
  local result = sum:read()
  sum:close()
  return result:match("([0-9a-f]+)")
end

-- Determine our IP on the side of our VPN endpoint using curl, ugh.
function determine_ip()
  local ip = io.popen("curl -s -H 'Host: whatismyip.akamai.com' 80.239.148.8", "r")
  local addr = ip:read()
  ip:close()
  return addr
end

-- Setup our data for the challenge/response
local address = arg[1] or determine_ip()
local ping_host, ping_password = os.getenv("PING_HOST"), os.getenv("PING_PASSWORD")
local host, port = "lilly.ping.de", 5353

-- Now, let's do this!
local socket = require("socket")
local ip = assert(socket.dns.toip(host))
local tcp = assert(socket.tcp())
tcp:settimeout(10)
assert(tcp:connect(ip, port))
local challenge = tcp:receive()
print(">>> " .. challenge)
local challenge_token = string.match(challenge, "CHA=([0-9a-f]+)")
assert(challenge_token)
local md5_response =
  md5(table.concat({ "md5", ping_host, ping_password, challenge_token, address }, ""))
local response = table.concat({ "RES=md5", md5_response, ping_host, address }, ",")
print("<<< " .. response)
tcp:send(response .. "\n")
result = tcp:receive()
print(">>> " .. result)
