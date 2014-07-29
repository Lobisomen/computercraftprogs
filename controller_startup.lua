print("Waiting 10 seconds so we don't try and wrap peripherals before they're ready")
sleep(10)
print()
local rnd = math.random(20)
print("Also waiting a random amount of time ("..rnd.."sec.) so we don't slam the server with tons of HTTP requests")
print()
sleep(rnd)

-- install any updates to this startup script
print("Updating startup script")
local start_src = http.get("https://raw.github.com/Lobisomen/sg_control/master/controller_startup.lua")
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

-- install any updates to button api that might be there
print("Updating button API")
local button_src = http.get("https://raw.github.com/Lobisomen/sg_control/master/button.lua")
if button_src ~= nil then
	local file = fs.open("/button","w")
	file.write(button_src.readAll())
	file.close()
	button_src.close()
	print("Button API updated successfully")
else
	print("Failed to update button API")
end

print()

-- install any updates to SGControl
print("Updating SGControl")
local sgc_src = http.get("https://raw.github.com/Lobisomen/sg_control/master/SGControl.lua")
if sgc_src ~= nil then
	local file = fs.open("/SGControl","w")
	file.write(sgc_src.readAll())
	file.close()
	sgc_src.close()
	print("SGControl updated successfully")
else
	print("Failed to update SGControl")
end
print()
print("Starting up SGControl")
shell.run("SGControl")
