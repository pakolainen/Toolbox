function gadget:GetInfo()
	return {
	name	= "Write Save Game",
	version = "1.8",
	desc	= "Writes Save Game State.",
	author	= "Argh, Pako",
	date	= "January 8, 2010 - 2012",
	license = "(C) Wolfe Games, 2010, released under GPL v.2",
	layer	= 0,
	enabled = true
	}
end

--[[
This gadget basically writes a synced gadget into the savegame zip for ReadSave gadget to load
-Only WriteSave.lua and ReadSave.lua needed in a game 
  *still games' own gadgets need to make sure they can load and save themselves correctly
  *storing the gadget's state in GG could work but UnitIDs and some other data changes so they need to be translated eg. with GG.oldToNewUnitID table
  *GG table is saved and loaded
-to save: /save [-y] filename.ssf
-to load: doubleclick the savefile or do "spring filename.ssf" or Spring.Restart("Saves/filename.ssf", "")

--]]

--TODO fix selfD commands
--handle stockpile
--if unsynced mission data becomes possible do it in other files 
--NOTE always keep backwards and forwards compatible!!
--TODO add projectiles
--TODO set directions (should be possible without movecontrol enable)
--TODO better rounding
--TODO check if the delays are even needed for the recent engines
--BUG? resources seems to be off? - maybe a start_game or end_game gadget is interfiering?
--TODO custom parameters???!!!
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not (gadgetHandler:IsSyncedCode()) then
  
local SaveLine --= zipFile:write--Spring.SendLuaUIMsg--Spring.Echo

local writeMission = "save_mission|" --save_mission|fileName.lua|code...
local resetMission = "clear_mission" --call always before saving again
local ccLen = resetMission:len()
if writeMission:len()~=resetMission:len() then error("idiot") end

local missionFiles = {}

function gadget:RecvLuaMsg(msg, playerID) --mission support... filename can be anything --this is totally untested but should work ok...I can't develop properly until BA faggots release at least one mission
  --Spring.Echo("RecvLuaMsg",msg)
  if msg:len() < ccLen then return end
  local hh = msg:sub(1, ccLen)
  if hh == writeMission then
	local starts,ends,fileName = msg:find("|(.+)|")
	if tostring(fileName) then
	  msg = msg:sub(ends)
	  missionFiles[fileName] = (missionFiles[fileName] or "") .. msg	
	  return true
	end
  elseif hh == resetMission then
    missionFiles = {}
  end
end

local function dumpTable(tab) --TODO make sure reloading GG dont fack up things and it is done before any other gadget is loaded
   if type(tab) == 'table' then
	--Spring.Echo("found table")

	local tmp = {}
	if #tab ~= nil then
	for a, b in pairs(tab) do
		if dumpTable(b) ~= nil then
			if type(a) == "number" then
				table.insert(tmp, "["..a.."]" .. '=' .. dumpTable(b))
			else
				table.insert(tmp, a .. '=' .. dumpTable(b))
			end
		else 
			return "nil" 
		end
	end
	end
	if tmp ~= nil then
		return '{' .. table.concat(tmp, ',') .. '}'
	else
		return 'nil'
	end
	elseif type(tab) == 'string' then
		return "'" .. tab .. "'"
	elseif type(tab) == 'function' then
		return "nil"
	elseif type(tab) == 'nil' then
		return "nil"
	elseif type(tab) == 'number' then
		return tab	
	else
		return tab
	end
end

local function copyCommandQueue(u,x,y,z) --TODO check the STATE defaults
	local st = '	do	local cuID = uID\n	DelayedCall(function()\n			'--write this only if actually giving commands
	local states = Spring.GetUnitStates(u)
	if (states ~= nil) then
	     if 2 ~= states.firestate then
		SaveLine(st..'GiveOrderToUnit(cuID, CMD.FIRE_STATE,{'..states.firestate..'}, {})')
		st = "			"
	     end
	    --if 0 ~= states.movestate then --TODO check the default moveState...
		SaveLine(st..'GiveOrderToUnit(cuID, CMD.MOVE_STATE,{'..states.movestate..'}, {})')
		st = "			"
	    --end
	    if states["repeat"] then
		SaveLine(st..'GiveOrderToUnit(cuID, CMD.REPEAT,{'..(states["repeat"] and 1 or 0)..'}, {})')
		st = "			"
	    end
	    if states.active ~= nil then
    		SaveLine(st..'GiveOrderToUnit(cuID, CMD.ONOFF,{'..(states.active and 1 or 0)..'}, {})')
		st = "			"
	    end
	    if states.cloak then --mines are cloaked already...
		SaveLine(st..'GiveOrderToUnit(cuID, CMD.CLOAK,{'..(states.cloak and 1 or 0)..'}, {})')
		st = "			"
	    end
	    if states.trajectory then
		SaveLine(st..'GiveOrderToUnit(cuID, CMD.TRAJECTORY,{'..(states.trajectory and 1 or 0)..'}, {})')
		st = "			"
	    end
  	end
 
	local queue = Spring.GetCommandQueue(u);
	if (queue ~= nil and #queue > 0) then
		st = "			"
		for k,v in ipairs(queue) do  --  in order
			local opts = v.options
			local par
			for i=1,#v.params do
			  local p = v.params[i] ~= nil and tostring(v.params[i])
			  if p then 
			    par = (par and (par .. ", ") or "") .. p
			  else
			    break
			  end
			end
			local cId = CMD[v.id] and "CMD."..CMD[v.id] or v.id --if CMD numbers change in future
			if (not opts.internal) and v.params[3] ~= nil then --??internal
					--Build standard orders as one string
					SaveLine(st..'GiveOrderToUnit(cuID,'..cId..',{'..par..'},'..opts.coded..')')
			elseif v.params[1] and v.params[3] == nil and v.params[2] == nil then
				if Spring.ValidUnitID(v.params[1]) then
					local x,y,z = Spring.GetUnitPosition(v.params[1])
					if x ~= nil then
						SaveLine(st..'if GG.oldToNewUnitID['..v.params[1]..'] then')
						SaveLine(st..'	GiveOrderToUnit(cuID,'..cId..',{'..'GG.oldToNewUnitID['..v.params[1]..']},'..opts.coded..')')
						SaveLine(st..'end')
					end
				elseif tonumber(v.params[1]) and Spring.ValidFeatureID(v.params[1]-Game.maxUnits) then
					local x,y,z = Spring.GetFeaturePosition(v.params[1]-Game.maxUnits)
					if x ~= nil then
						SaveLine(st..'if GG.oldToNewFeatID['..v.params[1]-Game.maxUnits..'] then')
						SaveLine(st..'	GiveOrderToUnit(cuID,'..cId..',{ Game.maxUnits + '..'GG.oldToNewFeatID['..v.params[1]-Game.maxUnits..'] },'..opts.coded..')')
						SaveLine(st..'end')
					end
				elseif (not opts.internal) then --??
					SaveLine(st..'GiveOrderToUnit(cuID,'..cId..',{'..(tostring(par))..'},'..opts.coded..')')
				end
			elseif v.params[1] == nil then
			  		SaveLine(st..'GiveOrderToUnit(cuID,'..cId..',{},'..opts.coded..')')
			end
		end
	end

	local buildqueue = Spring.GetRealBuildQueue(u) --FIX dont do for constructors
	if (buildqueue ~= nil) then
		for udid,buildPair in ipairs(buildqueue) do
			local udid, count = next(buildPair, nil)
			while(count > 0)do
			  local opt = ""
			  if count >= 100 then
			    count = count - 100
			    opt = '"shift", "ctrl"'
			  elseif count >= 20 then
			    count = count - 20
			    opt = '"ctrl"'
			  elseif count >= 5 then
			    count = count - 5
			    opt = '"shift"'
			  else
			    count = count - 1
			  end
			  SaveLine(st..'GiveOrderToUnit(cuID,'.. -tonumber(udid) ..',{'..count..'},{'..opt..'})')
			  st = "			"
			end
		end
  	end 
	if not st:find("DelayedCall") then
	  SaveLine('	end ) end')
	end
end

--function gadget:RecvLuaMsg(msg, playerID)
function gadget:Save ( zip )
  
	  for name, code in pairs(missionFiles) do
	    Spring.Echo("Gadget writing an additional save file (".. tostring(name) ..")...")
	    zip:open(name)
	    zip:write(code)
	  end
	  Spring.Echo("Gadget writing a save file (loader_gadget.lua)...")
	  zip:open("loader_gadget.lua")
	  SaveLine = function(l) zip:write(l.."\n") end
	  Spring.Echo("Gadget saving the game state...")

		SaveLine('function gadget:GetInfo()')
		SaveLine('	return {')
		SaveLine('		name = "SaveGame Loader",')
		SaveLine('		desc = "Load the saved game state.",')
		SaveLine('		author = "Argh, Pako",')
		SaveLine('		date = "January 8, 2010 - 2012",')
		SaveLine('		license = "GPL, v.2, 2010",')
		SaveLine('		layer = 1,')
		SaveLine('		enabled = true,')
		SaveLine('	}')
		SaveLine('end')
-------------------------------------------------------------------------------------------------------------------extra files		
		SaveLine('gadget.filesToLoad = {"loader_gadget.lua"}')
	for name, code in pairs(missionFiles) do
		SaveLine('Spring.Echo("Savegame gadget loading additional files...")')
		SaveLine('gadget.filesToLoad[#gadget.filesToLoad + 1] = "' .. tostring(name) .. '"')
	end
		SaveLine('Spring.Echo("Savegame gadget loading the game...")')
-------------------------------------------------------------------------------------------------------------------Speedups and variables		
		SaveLine('local u, health, maxhealth, paralyze, capture, build')
		SaveLine('local initFrame = Spring.GetGameFrame() or 0') --for /reloadgame
		SaveLine('local delayedCalls = {}')
		SaveLine('local validTable = {}')
		SaveLine('local validFTable = {}')
		SaveLine('GG.oldToNewUnitID = {}')
		SaveLine('GG.oldToNewFeatID = {}')
		SaveLine('local CreateUnit = Spring.CreateUnit')
		SaveLine('local GiveOrderToUnit = Spring.GiveOrderToUnit')
		SaveLine('local CreateFeature = Spring.CreateFeature')
		SaveLine('local SetUnitHealth = Spring.SetUnitHealth')

-------------------------------------------------------------------------------------------------------------------Begin Synced
		SaveLine('if (gadgetHandler:IsSyncedCode()) then')

		SaveLine('local function DelayedCall(fun)')
		SaveLine('	delayedCalls[#delayedCalls+1] = fun')
		SaveLine('end\n')
		
		SaveLine('if gadget.GameFrame then gadget.PREV_GameFrame = gadget.GameFrame end') --TODO switch back after init is done
		SaveLine('function gadget:GameFrame(f)')
		SaveLine('	if gadget.PREV_GameFrame then gadget:PREV_GameFrame(f) end') --from LuaUI
-------------------------------------------------------------------------------------------------------------------Frame 1
		SaveLine('if f == initFrame + 2 then')
		SaveLine('	Spring.Echo("Savegame gadget destroying old units and features...")')
-----------------------------------------------------------------------------------------------------------------Destroy all old Units
		SaveLine('	local Spring_DestroyUnit, units = Spring.DestroyUnit, Spring.GetAllUnits()')
		SaveLine('	for i=1,#units do')
		SaveLine('		local b = units[i]')
		SaveLine('		if not validTable[b] then')
		SaveLine('			Spring_DestroyUnit(b,false,true)')
		SaveLine('		end')
		SaveLine('	end')		
-----------------------------------------------------------------------------------------------------------------Destroy all old Features
		SaveLine('	local Spring_DestroyFeature, features = Spring.DestroyFeature, Spring.GetAllFeatures()')
		SaveLine('	for i=1,#features do')
		SaveLine('		local b = features[i]')
		SaveLine('		if not validFTable[b] then')
		SaveLine('			Spring_DestroyFeature(b)')
		SaveLine('		end')
		SaveLine('	end')

-------------------------------------------------------------------------------------------------------------------Write resource states
		 local currentLevel, storage, pull, income, expense, share, sent, received 
		for i=0,#Spring.GetTeamList() - 1 do
			currentLevel, storage, pull, income, expense, share, sent, received = Spring.GetTeamResources(i,"metal")
			if currentLevel ~= nil then
				SaveLine('	Spring.SetTeamResource('..i..',"ms",'..storage..')')
				SaveLine('	Spring.SetTeamResource('..i..',"m",'..currentLevel..')')
			end
			currentLevel, storage, pull, income, expense, share, sent, received = Spring.GetTeamResources(i,"energy")
			if currentLevel ~= nil then
				SaveLine('	Spring.SetTeamResource('..i..',"es",'..storage..')')
				SaveLine('	Spring.SetTeamResource('..i..',"e",'..currentLevel..')')
			end
		end
	
		local onu = GG.oldToNewUnitID
		local onf = GG.oldToNewFeatID
		GG.oldToNewUnitID = nil
		GG.oldToNewFeatID = nil
		for a,b in pairs (GG) do
   			SaveLine('	GG.' .. tostring(a) ..'=' .. dumpTable(b))
		end
		GG.oldToNewUnitID = onu --restore for continuing the game
		GG.oldToNewFeatID = onf
-------------------------------------------------------------------------------------------------------------------End of Frame 1
		SaveLine('end')	

-------------------------------------------------------------------------------------------------------------------Frame 35
-----------------------------------------------------------------------------------------------------------------Delayed Functions (Guard, etc.)
SaveLine('if f == initFrame + 35 then')
		SaveLine('Spring.Echo("Savegame gadget issuing commands...")')
		SaveLine('	for i=1,#delayedCalls do')
		SaveLine('		local fun = delayedCalls[i]')
		SaveLine('		fun()')
		SaveLine('	end')
		--SaveLine('	GG.oldToNewUnitID = {}') --keep these for missions
		--SaveLine('	GG.oldToNewFeatID = {}')
		--SaveLine('	gadgetHandler.RemoveGadget("SaveGame")')
		SaveLine('end')

-------------------------------------------------------------------------------------------------------------------GameStart
		SaveLine('if f == initFrame + 1 then')
		SaveLine('	Spring.Echo("Savegame gadget creating units and features...")')
-----------------------------------------------------------------------------------------------------------------Start Feature Writing
		local myFeatures = Spring.GetAllFeatures()
		SaveLine('	local fID')
		SaveLine('	local CreateFeature = Spring.CreateFeature')
		if myFeatures[1] ~= nil then
			for _,u in ipairs(myFeatures) do
				local ud = Spring.GetFeatureDefID(u)
				local x,y,z = Spring.GetFeaturePosition(u)
				local heading = Spring.GetFeatureHeading(u)
				if heading == 16384 then heading = 1 end
				if heading == 32767 then heading = 2 end
				if heading == -16384 then heading = 3 end
				local Featurename = FeatureDefs[ud].name
					SaveLine('	fID = CreateFeature("'..Featurename..'",'..math.floor(x+0.5)..','..math.floor(y+0.5)..','..math.floor(z+0.5)..','..heading..')')
					local rezUdName, bFacing = Spring.GetFeatureResurrect(u)
					if rezUdName and rezUdName ~= "" then
					  SaveLine('	Spring.SetFeatureResurrect(fID, "'..rezUdName..'", '.. tostring(bFacing) ..')') --should be pcall?
					end
					SaveLine('	GG.oldToNewFeatID['..u..'] = fID')
					SaveLine('	validFTable[fID]=1')
					
			end
		end
-----------------------------------------------------------------------------------------------------------------End Feature Writing
-----------------------------------------------------------------------------------------------------------------Start Unit Writing
		SaveLine('	local uID')
		local GetUnitTeam = Spring.GetUnitTeam
		for _,u in ipairs(Spring.GetAllUnits()) do
			local ud = Spring.GetUnitDefID(u)
			local x,y,z = Spring.GetUnitBasePosition(u)
			local heading = Spring.GetUnitHeading(u)
			local saveheading = heading
			if heading == 16384 then heading = 1 end
			if heading == 32767 then heading = 2 end
			if heading == -16384 then heading = 3 end

			if heading ~= 1 and heading ~= 2 and heading ~= 3 then
				heading = 0
			end

			local Unitname = UnitDefs[ud].name
			health, maxhealth, paralyze, capture, build = Spring.GetUnitHealth(u)
			if build < 1 then
				SaveLine('	uID = CreateUnit("'..Unitname..'",'..math.floor(x+0.5)..','..math.floor(y+0.5)..','..math.floor(z+0.5)..','..heading..','..GetUnitTeam(u)..','..'true)')
			else
				SaveLine('	uID = CreateUnit("'..Unitname..'",'..math.floor(x+0.5)..','..math.floor(y+0.5)..','..math.floor(z+0.5)..','..heading..','..GetUnitTeam(u)..')')
			end
			SaveLine('	SetUnitHealth(uID,'.. string.format("%.2f",health or 1) ..','..capture..','..paralyze..','..build..')')
			SaveLine('	GG.oldToNewUnitID['..u..'] = uID')

			SaveLine('	validTable[uID] = 1')
			if UnitDefs[ud].canMove or UnitDefs[ud].canFly then
				if saveheading ~= 0 and saveheading ~= 16384 and saveheading ~= 32767 and saveheading ~=  -16384 then
					--SaveLine('Spring.MoveCtrl.Enable(uID);Spring.MoveCtrl.SetRotation(uID,0,'..saveheading..',0)Spring.MoveCtrl.Disable(uID)')
				end
			end
			local myqueue = Spring.GetCommandQueue(u);
			if myqueue and #myqueue > 0 then
				copyCommandQueue(u,x,y,z)
			end
		end
		SaveLine('end')
		SaveLine('end')
		SaveLine('end')
		
		if zip.close then zip:close() end
		Spring.Echo("Finished saving the game. (^ignore the retarted engine warning)")
end

end