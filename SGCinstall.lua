-- SGCinstall by zenithselenium - © 2014
-- Install script for SGCraft computer controlled dialing using kode


function printHeader()
  shell.run("clear")
  print("################################################")
  print("#                                              #")
  print("#                   SGCinstall                 #")
  print("#              by: zenithselenium              #")
  print("#                                              #")
  print("################################################")
  print()
end

function readNumber(rn)
	rn[1] = tonumber(read())
end


function emulateDisk()
	if (fs.exists("/disk")) then
		print("/disk exists. Using that.")
	else
		shell.run("mkdir", "/disk")
		print("disk emulation set up")
	end
end

local tArgs = {...}


-- set up kode auth file and disk emulation
local function auth(un,pkey)
	local file = fs.open("/disk/.koderc",'w')
	file.writeLine(un)
	file.writeLine(pkey)
	file.close()
	--pastebin get jLjJR65B install
	shell.run("pastebin", "get jLjJR65B install_kode")
	shell.run("install_kode")
	shell.run("rm","install_kode")
end

-- get file via http and save it to the filename passed in
local function getAndSave(url, filename)
	local src = http.get(url)
	if src == nil then
		print("failed to get file: "..url)
		return false
	else
		local file = fs.open(filename,"w")
		file.write(src.readAll())
		file.close()
		src.close()
	end
	return true
end

local function printUsage()
	print("Lite installation script for kode and stargate control")
	print("Usage: SGCinstall <dialer/controller>")
	print()
end

function run()

	if #tArgs < 1 then
		-- Not enough arguments given, tell user how to use it
		printUsage()
		return
	end

	printHeader()
	local valid = false
	local version = ""
	local peripherals = ""

	if #tArgs == 1 and tArgs[1] == "controller" then
		emulateDisk()
		if not getAndSave("https://raw.github.com/Lobisomen/sg_control/master/SGControl.lua","/SGControl") then
			print("Failed to download SGControl")
			return
		else	
			print("Installed SGControl")
			if not getAndSave("https://raw.github.com/Lobisomen/sg_control/master/controller_startup.lua","/startup") then
				print("Failed to install startup script")
				return
			end
			print("Set SGControl to run on startup")
			print()
			print("Setting up kode auth")
			print("This username and password will be used to store your Stargate addresses on kode (https://kealper.com/projects/kode/)")
			print("Note: To synchronize addresses across multiple gates, each controller needs to be set up with the same authentication credentials.")
			print()
			print("What is the username you wish to use for your kode address repository? (this should be unique to this stargate network)")
			local kode_un = read()
			print()
			local pw_match = false
			local count = 1
			local kode_pw = ""
			while pw_match == false and count < 3 do
				print("Please enter the password you wish to use for the kode repository")
				local kode_pw1 = read()
				print("Confirm password")
				local kode_pw2 = read()
				if kode_pw1 == kode_pw2 then
					pw_match = true
					kode_pw = kode_pw2
				else
					print("Passwords do not match.")
					print()
					count = count + 1
				end
			end
			if kode_pw == "" then
				print("Please run this installer again and ensure that you enter the same password.")
				return
			end
			auth(kode_un,kode_pw)
			print("kode auth set up.")
			
			if not getAndSave("https://raw.github.com/Lobisomen/sg_control/master/button.lua","/button") then
				print("Failed to install button API")
				return
			else
				print("Installed modified button API")
				shell.run("kode", "pull addresses addresses")
				if not fs.exists("/addresses") then
					file = fs.open("/addresses","w")
					file.write("{}")
					file.close()
					shell.run("kode","make addresses")
					shell.run("kode","push addresses /addresses")
				end

				version = "SGControl"
				print()

				-- get config
				print("On what side is the monitor?")
				print("(front/left/right/back/top/bottom)")
				local monitor_side = read()

				print()
				print("On what side is the modem?")
				print("(front/left/right/back/top/bottom)")
				local modem_side = read()

				print()
				print("What is the id of the dialer?")
				local temp = {}
				local turtle = "unknown"
				if pcall(readNumber, temp) then
					turtle = temp[1]
				else 
					print("Not a number. You'll need to edit SGC_config.txt with the proper id.")				
				end

				print()
				print("What is the id of the information panel")
				local temp = {}
				local infopanel = "unknown"
				if pcall(readNumber, temp) then
					infopanel = temp[1]
				else 
					print("Not a number. You'll need to edit SGC_config.txt with the proper id.")	
				end

				print()
				print("Building config file")
				local config = fs.open("SGC_config.txt","w")
				config.writeLine(monitor_side)
				config.writeLine(modem_side)
				config.writeLine(turtle)
				config.writeLine(infopanel)
				config.close()
			end
		end 
	elseif #tArgs == 1 and tArgs[1] == "dialer" then
		if turtle == nil then
			print("Dialer must be a turtle!")
			return
		end
		if not getAndSave("https://raw.githubusercontent.com/Lobisomen/sg_control/master/SGDial.lua","/SGDial") then
			print("Failed to download SGDial")
			return
		else
			print("Installed SGDial")
			if not getAndSave("https://raw.githubusercontent.com/Lobisomen/sg_control/master/dialer_startup.lua","/startup") then
				print("Failed to install startup script")
				return
			end
			print("Set SGDial to run on startup")
			version = "SGDial"
			
			print()
			print("In what direction is the dialer from the Stargate Base?")
			print("(down/north/south/east/west)")
			print("e.g. if the dialer is to the north of the Stargate Base, enter north")
			local sg_dir = read()

			print()
			print("On what side of the dialer is the Stargate Base?")
			print("(front/top/bottom)")
			local sg_side = read()

			print()
			print("On what side of the dialer is the fuel chest?")
			print("(front/top/bottom)")
			local fc_side = read()

			print()
			print("Building config file")
			local config = fs.open("SGD_config.txt","w")
			config.writeLine(fc_side)
			config.writeLine(sg_side)
			config.writeLine(sg_dir)
			config.close()
		end

	else
		error("Illegal argument(s)")
		printUsage()
		return
	end

	print("------------------------------------------")
	print(version .. " successfully installed. You will need to edit it to input the correct sides for its peripherals "..peripherals)
	print("")
	if version == "SGDial" then
		print("This machine's id: "..os.getComputerID())
	end
	

end

run()
print("Cleaning up - removing SGCinstall")
shell.run("rm",shell.getRunningProgram())
