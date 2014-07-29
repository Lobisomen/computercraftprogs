-- SGController by zenithselenium - © 2014
-- Large portions of this code is adapted from DireWolf20's portal program
-- ( http://pastebin.com/ELAFP3kT )

function loadConfig()
  local out = {}
  if not fs.exists("SGC_config.txt") then
    print("Could not find config file. Please reinstall SGControl.")
    return nil
  end
  local config = fs.open("/SGC_config.txt","r")
  out.monitor = config.readLine()
  print("monitor: "..out.monitor)
  out.modem   = config.readLine()
  print("modem: "..out.modem)
  out.dialer  = config.readLine()
  print("dialer: "..out.dialer)
  
  return out
end

local page = 1
local pages = 0
local names = {}
local dialers = {}
local remove = false
local outOfFuel = false

function printHeader()
  shell.run("clear")
  print("################################################")
  print("#                                              #")
  print("#                   SGControl                  #")
  print("#              by: zenithselenium              #")
  print("#                                              #")
  print("################################################")
  print()
end

function fillDialers(dialer)
   dialers[1] = tonumber(dialer)
end

function printTable(table)
  for k,v in pairs(table) do
    print("key: "..k)
  end
end

function fillTable()
  m.clear()
  button.clearTable()
  local totalrows = 0
  local numNames = 0
  local col = 2
  local row = 11
  local countRow = 1
  local currName = 0
  local npp = 12 --names per page
  for dialer, data in pairs(names) do
    for i,j in pairs(data) do
      totalrows = totalrows+1
    end
  end
  pages = math.ceil(totalrows/npp)
  print("Total addresses: "..totalrows)
  for dialer, data in pairs(names) do
    currName = 0
    for slot, name in pairs(data) do
      currName = currName + 1
      if currName > npp*(page-1) and currName < npp*page+1 then
        row = 4+(countRow)
        button.setTable(string.sub(name.name, 0, 17), runStuff, dialer..":"..slot, col, col+17 , row, row)
        if col == 21 then 
          col = 2 
          countRow = countRow + 2
        else 
          col = col+19 
        end
      end
    end
  end
  button.setTable("Prev Page", prevPage, "", 2, 19, 1, 1)
  button.setTable("Next Page", nextPage, "", 21, 38, 1, 1)
  button.setTable("Add Address", addAddress, "", 2, 19, 17, 17)
  button.setTable("Close Gate", closeGate, "", 21, 38, 17, 17)
  button.setTable("Remove Address", removeIt, "", 2, 19, 19, 19)
  button.setTable("Refresh", checkNames, "", 21, 38, 19, 19)
  button.label(15,3, "Page: "..tostring(page).." of "..tostring(pages))
  button.screen()
end      

function nextPage()
  if page+1 <= pages then 
    page = page+1 
  end
  fillTable()
  sleep(0.25)
end

function prevPage()
  if page-1 >= 1 then page = page-1 end
  fillTable()
  sleep(0.25)
end   
                           
function getNames()
   names = {}
   for index, dialer in pairs(dialers) do
      names[dialer] = {}
      shell.run("rm","/addresses")
      shell.run("kode","pull addresses /addresses")
      local file = fs.open("/addresses","r")
      names[dialer] = textutils.unserialize(file.readAll())
      file.close()
   end
end

function removeIt()
   remove = not remove
--   print(remove)
   button.toggleButton("Remove Address")
end

function runStuff(info)
  if remove == true then
    removeAddress(info)
  else
    dial(info)
  end      
end

function removeAddress(info)
  local dialer, slot = string.match(info, "(%d+):(%d+)")
  button.toggleButton(names[tonumber(dialer)][tonumber(slot)].name)
   
  local temp = {}
  names[tonumber(dialer)][tonumber(slot)] = nil

  local count = 1
  local addresses = names[tonumber(dialer)]
  for i = 1, #addresses do
    if addresses[i] ~= nil then
      temp[count] = addresses[i]
      count = count +1
    end
  end

  local file = fs.open("/addresses","w")
  file.write(textutils.serialize(temp))
  file.close()
  shell.run("kode","push addresses /addresses")

  remove=false
  button.toggleButton("Remove Address")
--   sleep(1)
  getNames()
  fillTable()
end   

function msgBox()
  fillTable()
  m.setBackgroundColor(2)
  for i = 5,14 do
    m.setCursorPos(8,i)
    for j = 1,25 do
      m.write(" ")
    end
  end
end

function addAddress()
  fillTable()
  msgBox()
  m.setCursorPos(12,8)
  m.setTextColor(colors.black)
  m.write("Please enter the")
  m.setCursorPos(13,9)
  m.write("new address in")
  m.setCursorPos(14,10)
  m.write("the terminal")
  m.setBackgroundColor(colors.black)
  m.setTextColor(colors.white)
  printHeader()
  print("Location Name:")
  local name = read()
  print("Address: ")
  local address = read()
  printHeader()
  local addresses = names[dialers[1]]
  addresses[#addresses + 1] = {["name"]=name,["addr"]=address}
  local file = fs.open("/addresses","w")
  file.write(textutils.serialize(addresses))
  file.close()
  shell.run("kode","push addresses /addresses")
  printHeader()
  print("Addresses updated")
  fillTable()
end

function fuelError()
  print("Stargate out of fuel.")
  msgBox()
  m.setCursorPos(15,8)
  m.setTextColor(colors.black)
  m.write("Out of fuel")
  m.setCursorPos(14,9)
  m.write("Place fuel in")
  m.setCursorPos(12,10)
  m.write("chest, then click")
  m.setCursorPos(17,11)
  m.write("Refresh")
  m.setBackgroundColor(colors.black)
  m.setTextColor(colors.white)
  outOfFuel = true
end

function closeGate()
  button.flash("Close Gate")
  rednet.send(dialers[1], "close|now")
  getNames()
  fillTable()
end

function dial(info)
  local dialer,slot = string.match(info, "(%d+):(%d+)")
  local name = names[tonumber(dialer)][tonumber(slot)].name
  local addr = names[tonumber(dialer)] [tonumber(slot)] .addr
  button.toggleButton(name)
  print("Requesting dialer to dial "..name.." ("..addr..")")
  data = "dial|"..addr
  rednet.send(tonumber(dialer), data)
  local id, msg, dis = rednet.receive(8)
  if (msg == nil) then
    term.setTextColor(colors.red)
    print("Dialer failed to respond.")
    term.setTextColor(colors.white)
  elseif msg == "nofuel" then
    fuelError()
  else
    print("Message: "..msg)
  end
  getNames()
  if not outOfFuel then 
    button.toggleButton(name)
    fillTable()
  end
end

function checkNames()
  if outOfFuel then
    m.clear()
  else
    button.flash("Refresh")
  end
   
  getNames()
  fillTable()
  outOfFuel = false
end

function controllerOfflineMessage()
  m.clear()
  m.clear()
  msgBox()
  m.setTextColor(colors.black)
  m.setCursorPos(11,9)
  m.write("Controller offline")
  m.setBackgroundColor(colors.black)
  m.setTextColor(colors.white)
end

function initializingMessage()
  m.clear()
  m.clear()
  msgBox()
  m.setTextColor(colors.black)
  m.setCursorPos(14,9)
  m.write("Initializing")
  m.setBackgroundColor(colors.black)
  m.setTextColor(colors.white)
end

function manualDialMessage()
  m.clear()
  msgBox()
  m.setTextColor(colors.black)
  m.setCursorPos(13,9)
  m.write("Manual Dialing")
  m.setBackgroundColor(colors.black)
  m.setTextColor(colors.white)
end

function manualDial()
  manualDialMessage()
  printHeader()
  print("Enter address")
  local addr = read()
  rednet.send(tonumber(dialers[1]), "dial|"..addr)
  id, msg = rednet.receive(5)
  print(msg)
  checkNames()
end

function getClick()
  event, side, x,y = os.pullEventRaw()
  if event == "monitor_touch" then
    button.checkxy(x,y)
  elseif event == "redstone" then
    --print("redstone")
    sleep(5)
    getNames()
    fillTable()
  elseif event == "terminate" then
    print("Terminating")
    controllerOfflineMessage()
    return false
  elseif event == "key" and side == 32 then
    manualDial()
  end
  return true
end


function checkDialer()
  print "Pinging dialer..."
  rednet.send(dialers[1], "ping")
  local success = false
  local id, msg, dis = rednet.receive(5)
  if (msg == nil) then
    for i = 2,5 do
      term.setTextColor(colors.red)
      print("Dialer did not respond. Trying again.")
      term.setTextColor(colors.white)
      print("Pinging dialer (attempt "..i.. " of 5)...")
      rednet.send(dialers[1], "ping")
      local id, msg, dis = rednet.receive(5)
      if (msg ~= nil) then
        success = true
        break
      end
    end
  else
    success = true
  end
  return success
end

-- 
function run()
  printHeader()
  print("Initializing...")
  print("Loading config")

  local config = loadConfig()
  if config == nil then
    return
  end
  print("Config loaded")
  m = peripheral.wrap(config.monitor)
  m.clear()
  --initializingMessage()
  rednet.open(config.modem)

  os.loadAPI("button")
  print("button API loaded")
  button.setup(m)
  print("button API initialized")
  fillDialers(config.dialer)

  if not checkDialer() then
    term.setTextColor(colors.red)
    print("Dialer failed to respond. Is it offline?")
    term.setTextColor(colors.white)
    return
  else
    print("Dialer locked in")
  end
  getNames()
  print("Addresses loaded")
  fillTable()
  print("GUI populated")
  print("Initialization complete.")
  local continue = true
  while continue do
    continue = getClick()
    --checkNames()
  end
end

run()
controllerOfflineMessage()
