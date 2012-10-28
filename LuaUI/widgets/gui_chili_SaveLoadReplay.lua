--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Save/Load/Replay",
    version   = "0.4",
    desc      = "Save the game or load a savegame or replay",
    author    = "Pako",
    date      = "2012-01-13",
    license   = "GNU GPL, v2 or later",
    layer     = -2000,
    enabled   = true,
  }
end

local OpenTheWindow
local window
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local	Chili
local	Image
local	Button
local	Label
local	screen0

local inputspace

local shown
local function hideDialog()
  if shown then
    screen0:RemoveChild(window)
    shown = false
  end
end

local function makeWindow()
  	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	local screenWidth,screenHeight = Spring.GetWindowGeometry()

	Chili = WG.Chili
	Image = Chili.Image
	Button = Chili.Button
	Label = Chili.Label
	screen0 = Chili.Screen0

		local textH, buttH = 20, 20*1.85

		local osd = os.date("*t")
			local dat = ""..osd.year.."_"..osd.month.."_"..osd.day.."_"..osd.hour.."_XX_XX_"..Game.modShortName.."_"..Game.mapName
		
  local buttonStack = Chili.StackPanel:New{
					x=0,
					orientation = "vertical",
					width  = "20%",
					height = "100%",
					itemMargin = {5,5,5,5},
					resizeItems = false,
					centerItems = false,
					autosize = true,
					
					children = {
					  
					  
					  					  Button:New{
					height = buttH,
					width = "100%",
					tooltip = 'Write a savegame to "Saves/QuickSave.ssf"',
					caption = 'QuickSave',
          fontsize = textH,
          textColor = {0.95,0.7,0.7,1},
	  fontShadow = true,
					--padding ={0,0,0,0},
          OnClick = { function(self)	 
                    Spring.Echo("QuickSaving...")
		    hideDialog()
			Spring.SendCommands("savegame")
                        end, },
				},
									  					  Button:New{
					height = buttH,
					width = "100%",
					tooltip = 'Load a savegame from "Saves/QuickSave.ssf"',
					caption = 'QuickLoad',
          fontsize = textH,
          textColor = {0.7,0.7,0.95,1},
	  fontShadow = true,
					--padding ={0,0,0,0},
          OnClick = { function(self)	 
                    Spring.Echo("QuickLoading...")
		    hideDialog()
			Spring.Restart("Saves/QuickSave.ssf", "")
                        end, },
				},
				Button:New{
					height = buttH,
					width = "100%",
					tooltip = 'Reload the savegame that was loaded when the game was started',
					caption = 'Reload',
          fontsize = textH,
          textColor = {0.2,0.8,0.8,1},
	  fontShadow = true,
					--padding ={0,0,0,0},
          OnClick = { function(self)	 
                    Spring.Echo("Reloading...")
		    hideDialog()
			Spring.SendCommands("reloadgame")
                        end, },
				},
				Button:New{
					height = buttH*1.5,
					width = "100%",
					tooltip = 'Close this dialog',
					caption = 'Close',
          fontsize = textH*1.5,
          textColor = {0.3,0.3,0.3,1},
	  fontShadow = true,
					--padding ={0,0,0,0},
          OnClick = { function(self)	 
		    hideDialog()
                        end, },
				},	  
			
				}--children end
				}

		local saveFiles = VFS.DirList("Saves", "*.ssf", VFS.RAW)
		local fileLabels = {}
		local quickS 
		for k,v in ipairs(saveFiles) do
		  fileLabels[#fileLabels + 1] = 			Chili.Label:New{
					fontsize = textH*0.5,
					    caption = v:match("Saves.(.*)%.ssf") or "??",
					    HitTest = function(self,x,y)
	      return self
    end,
					}
					--[[if v:find("QuickSave") then
					  quickS =  #fileLabels
					  fileLabels[#fileLabels].font.color = {1,0.7,0,1}
					end--]]
		end
		
	local savesStack = Chili.StackPanel:New{
		margin = {0,0,0,0},
		padding = {1,1,1,1},
		x = 0,
		y = 0,
		width='100%',
		height = '100%',
		itemPadding  = {0,0,0,0},
		itemMargin  = {0,0,0,0},
					resizeItems = false,
					centerItems = false,
					autosize = true,
		  selectable    = true,
  multiSelect   = false,
  --selectedItems = {[quickS] = true},
  OnSelectItem = {function(self, selectedIdx, selected)
		  local item = self.children[selectedIdx]
		  if selected then
		    item.font.color = {1,0.7,0,1}
		    if inputspace then
		      inputspace:SetText(item.caption) --for overwriting savegames
		    end
		  else
		    item.font.color = Chili.Label.font.color
		  end
		  item:Invalidate()
		end,
		},
		children = fileLabels
	}


	local savesList  = Chili.ScrollPanel:New{
		--margin = {5,5,5,5},
		padding = {5,5,5,5},
		x = "20%",
		y = "15%",
		width='38%',
		--bottom = buttH*2,
		height = '75%',
		verticalSmartScroll = true,
		disableChildrenHitTest = false,
		backgroundColor = {1,1,1,1},
		children = {
			savesStack,
		},
	}
	
	local loadButt = Button:New{
					height = buttH,
					x = "20%",
					width = "35%",
					tooltip = 'Load a savegame',
					caption = 'Load',
          fontsize = textH,
          textColor = {0.95,0.95,0.2,1},
	  fontShadow = true,
					--padding ={0,0,0,0},
          OnClick = { function(self)	 
                    local saveG = next(savesStack.selectedItems)
		    saveG = saveG and savesStack.children[saveG]
		    if saveG and type(saveG.caption) == "string" then
		      Spring.Echo("Restarting Spring: "..saveG.caption)
			Spring.Restart("Saves/"..saveG.caption..".ssf", "")
		    else
		      Spring.Echo("Failed to load the savegame")
		    end
                        end, },
				}
	
	
	local replaysStack = Chili.StackPanel:New{
		margin = {0,0,0,0},
		padding = {1,1,1,1},
		x = 0,
		y = 0,
		width='100%',
		height = '100%',
		itemPadding  = {0,0,0,0},
		itemMargin  = {0,0,0,0},
					resizeItems = false,
					centerItems = false,
					autosize = true,
		  selectable    = true,
  multiSelect   = false,
  selectedItems = {},
  OnSelectItem = {function(self, selectedIdx, selected)
		  local item = self.children[selectedIdx]
		  if selected then
		    item.font.color = {1,0.7,0,1}
		  else
		    item.font.color = Chili.Label.font.color
		  end
		  item:Invalidate()
		end,
		},
		children = {},
	}
	
	--stackpanel always draws the whole list and can get slow when there are many -this hack draws only the visible
	--without this hack FPS got down from 166 to 96, with only 1 FPS drop
	local CallVisibleChildrenInverse = function(self, eventname, ...)
		local children = self.children
		 for i=#children,1,-1 do
		   local child = children[i]
		   if (child) and self.parent:InClientArea(self.parent:ClientToLocal(self:ClientToLocal(child.x, child.y))) then
		     local obj = child[eventname](child, ...)
		     if obj then return obj end
		   end
		 end
	end
	savesStack["_DrawChildrenInClientArea"] = function(self, event) self:_DrawInClientArea(CallVisibleChildrenInverse, self, event or 'Draw') end
	replaysStack["_DrawChildrenInClientArea"] = function(self, event) self:_DrawInClientArea(CallVisibleChildrenInverse, self, event or 'Draw') end
	
	
	local replayScroll = Chili.ScrollPanel:New{
		--margin = {5,5,5,5},
		padding = {5,5,5,5},
		x = (20+40).."%",
		y = "15%",
		width='35%',
		height = '75%',
		verticalSmartScroll = true,
		disableChildrenHitTest = false,
		backgroundColor = {1,1,1,1},
		children = {
			replaysStack,
		},
	}
	
	local replayButt = Button:New{
					height = buttH,
					x = (20+40).."%",
					width = "35%",
					tooltip = 'Load the replay list',
					caption = 'List Replays',
          fontsize = textH,
          textColor = {0.2,0.4,0.9,1},
	  fontShadow = true,
	  replaysLoaded = false,
          OnClick = { function(self)	
					  if self.replaysLoaded then
					    
					
                    local replay = next(replaysStack.selectedItems)
		    replay = replay and replaysStack.children[replay]
		    if replay and type(replay.caption) == "string" then
		      Spring.Echo("Restarting Spring: "..replay.caption)
			Spring.Restart("demos/"..replay.caption..".sdf", "")
		    else
		      Spring.Echo("Failed to load the replay")
		    end
					  else
					    self.tooltip = "Load the selected replay"
					    self:SetCaption("Load Replay")
					    self.replaysLoaded = true
					    local replayFiles = VFS.DirList("demos", "*.sdf", VFS.RAW)
		for k,v in ipairs(replayFiles) do
		  replaysStack:AddChild(			Chili.Label:New{
					fontsize = textH*0.5,
					    caption = v:match("demos.(.*)%.sdf") or v:match("Demos.(.*)%.sdf") or "??",
					    HitTest = function(self,x,y)
	      return self
    end,
					}, false)
		end
					  end
                        end, },
				}
	
			local saveButton = 						  Button:New{
					height = buttH,
					    bottom = buttH,
					    x = "3%",
					width = "16%",
					tooltip = 'Saves the game',
					caption = 'Save',
          fontsize = textH,
          textColor = {0.6,0.2,0.2,1},
	  fontShadow = true,
					--padding ={0,0,0,0},
          OnClick = { function(self)
					  
			local osd = os.date("*t")
			local dat = ""..osd.year.."_"..osd.month.."_"..osd.day.."_"..osd.hour.."_"..osd.min.."_"..osd.sec.."_"..Game.modShortName.."_"..Game.mapName
                    if inputspace and inputspace.text and inputspace.text ~= "" then
		      dat = inputspace.text
		    end
			Spring.Echo("Saving the game to 'Saves/"..dat..".ssf'...")
			Spring.SendCommands("save -y "..dat)
			savesStack:AddChild(Chili.Label:New{
					fontsize = textH*0.5,
					    caption = dat,
					    HitTest = function(self,x,y)
	      return self
    end})
                        end, },
				}
			
			local saveName 
			
			if Chili.TextInputBox then
			  inputspace = Chili.TextInputBox:New{
			  bottom = 5,
			     x = "3%",
					fontsize = textH*0.75,
					textColor = {0,0,0,1},
		height = textH,
    width = "50%",
    grabEnter = false,
		backgroundColor = {1,1,1,0.3},
    OnReturn = {function(self,text)
			    self.text = text
                 saveButton.OnClick[1](saveButton) --TODO fix
                end}
	}
	inputspace:SetText(dat)
	saveName = inputspace
			else
			  		saveName=	Chili.Label:New{
			  bottom = 5,
			     x = "3%",
					fontsize = textH*0.75,
					textColor = {0,0,0,1},
					    caption = dat..".ssf",
					}
			end
			
			window = Chili.Window:New{
		name = "Save Load dialog",
    x = screenWidth*(1-0.5)/2,
		y = screenHeight*0.4,
		width  = screenWidth*0.5,
		--height = screenHeight*0.50,
		--resizable = false,
		autosize   = false,
		--parent = screen0,
		draggable = true,
		children = {
    buttonStack,
	loadButt,
	savesList,
	replayButt,
	replayScroll,
	saveButton,
saveName,
		},
	}	
end


OpenTheWindow = function(cmd, optLine, optWords, _,isRepeat, release)
if isRepeat or release then return true end
if shown then
  hideDialog()
else
  shown = true
  if not window then makeWindow() end
  screen0:AddChild(window)
end
return true
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
include("keysym.h.lua")
function widget:KeyPress(keyCode, modKeys, isRepeat, keySet, unicode)
  if not shown then return end
  
  if keyCode == KEYSYMS.ESC then
    hideDialog()
  end
  
  return inputspace and inputspace:KeyPress(keyCode, modKeys, isRepeat, keySet, unicode, UTF8)
  
end


function widget:Shutdown()
  widgetHandler:RemoveAction("save_load", OpenTheWindow)
end


-----------------------------------------------------------------------

function widget:Initialize()
  widgetHandler:AddAction("save_load", OpenTheWindow)
  --makeWindow() --remove this after debug
end
