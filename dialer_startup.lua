print("Waiting 10 seconds so we don't try and wrap peripherals before they're ready")
sleep(10)
print()
local rnd = math.random(20)
print("Also waiting a random amount of time ("..rnd.."sec.) so we don't slam the server with tons of HTTP requests")
print()
sleep(rnd)

-- install any updates to this startup script
print("Updating startup script")
local start_src = http.get("https://raw.githubusercontent.com/Lobisomen/sg_control/master/dialer_startup.lua")
if start_src ~= nil then
	local file = fs.open("/startup","w")
	file.write(start_src.readAll())
	file.close()
	start_src.close()
	print("Startup script updated successfully")
else
	print("Failed to update startup script")
end

print()

-- install any updates to SGDial
print("Updating SGDial")
local sgd_src = http.get("https://raw.githubusercontent.com/Lobisomen/sg_control/master/SGDial.lua")
if sgd_src ~= nil then
	local file = fs.open("/SGDial","w")
	file.write(sgd_src.readAll())
	file.close()
	sgd_src.close()
	print("SGDial updated successfully")
else
	print("Failed to update SGDial")
end

print()
print("Starting SGDial")
shell.run("SGDial")
