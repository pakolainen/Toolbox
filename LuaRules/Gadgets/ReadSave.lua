function gadget:GetInfo()
	return {
	name	= "Load Save Game",
	version = "1.8",
	desc	= "Loads Save Game State.",
	author	= "Pako",
	date	= "2012.01.13",
	license = "",
	layer	= 0,
	enabled = true
	}
end

--TODO check if unsynced Loading works
--NOTE keep this backwards and forwards compatible!! (make ReadSave2.lua gadget if needed)
--TODO save the mission files to GG. table and when the game is saved in writeSave try to include the mission state
--TODO make sure the layer is correct for other gadgets to save/load themselves properly (GG overwriting..)
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
gadget.filesToLoad = {"loader_gadget.lua"} --savegame code can override this if needed

function gadget:Load(zipF)
  Spring.Echo('Loading the savegame gadget...')
  local i = 0
  while i < #gadget.filesToLoad do
    i = i+1
    local fileName = gadget.filesToLoad[i]
    zipF:open(fileName)
    local chunk, err = loadstring(zipF:read("*all"), fileName)
    if chunk then
    --setfenv(chunk, gadget)
      local success, err = pcall(chunk) --probably only overwrites the synced gadget
    if (not success) then
      Spring.Echo('Failed to execute savegame: '..fileName..'(' .. err .. ')')
    end
    else
        Spring.Echo('Failed to load savegame file: '..fileName.." : " .. err)
    end
  end
  
  for name,func in pairs(gadget) do --dynamically enable the loaded callins --same as what is commented below but only the needed ones --TODO prints some warnings for Lua callouts
    if type(func) == "function" then
      gadgetHandler:UpdateCallIn(name) --TODO check if really a callIn or maybe pcall
    end
  end
  Spring.Echo('Savegame loading finished correctly.')
  return true
end
--[[
function gadget:GameFrame(f) --gameFrame is the only needed call if no mission
end

local callIns = {
  'Shutdown',

  'GamePreload',
  'GameStart',
  'GameOver',
  'TeamDied',

  --'GameFrame',

  'ViewResize',  -- FIXME ?

  'TextCommand',  -- FIXME ?
  'GotChatMsg',
  'RecvLuaMsg',

  -- Unit CallIns
  'UnitCreated',
  'UnitFinished',
  'UnitFromFactory',
  'UnitDestroyed',
  'UnitExperience',
  'UnitIdle',
  'UnitCmdDone',
  'UnitPreDamaged',
  'UnitDamaged',
  'UnitTaken',
  'UnitGiven',
  'UnitEnteredRadar',
  'UnitEnteredLos',
  'UnitLeftRadar',
  'UnitLeftLos',
  'UnitSeismicPing',
  'UnitLoaded',
  'UnitUnloaded',
  'UnitCloaked',
  'UnitDecloaked',
  'StockpileChanged',
  'ShieldPreDamaged',

  -- Feature CallIns
  'FeatureCreated',
  'FeatureDestroyed',

  -- Projectile CallIns
  'ProjectileCreated',
  'ProjectileDestroyed',

  -- Misc Synced CallIns
  'Explosion',

  -- LuaRules CallIns
  'CommandFallback',
  --'AllowCommand', --these would need return true ?
  --'AllowUnitCreation',
  --'AllowUnitTransfer',
  --'AllowUnitBuildStep',
  --'AllowFeatureCreation',
  --'AllowFeatureBuildStep',
  --'AllowResourceLevel',
  --'AllowResourceTransfer',
  --'AllowStartPosition',
  --'AllowDirectUnitControl',
  'MoveCtrlNotify',
  'TerraformComplete',
  }

for i=1, #callIns,1 do
    gadget[callIns[i] ] = function(self) end --add all callIns for missions
end
--]]


