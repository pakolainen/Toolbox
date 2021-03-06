--//=============================================================================
local Chili
if WG.Chili then
    Chili = WG.Chili

UnitDefsView = Chili.LayoutPanel:Inherit {
  --TODO: figure out how to use DrawItemBackground with correct class name, in this case "unitdefsview"
  classname = "imagelistview", 

  autosize = true,

  autoArrangeH = false,
  autoArrangeV = false,
  centerItems  = false,

  iconX     = 64,
  iconY     = 64,

  itemMargin    = {1, 1, 1, 1},

  selectable  = true,
  multiSelect = false,
  columns = 5,

  items = {},
  unitTerrainId = 1,
  unitTypesId = 1,
  teamId = 1,
}

local this = UnitDefsView 
local inherited = this.inherited

--//=============================================================================

function UnitDefsView:New(obj)
  obj = inherited.New(self, obj)
  obj:PopulateUnitDefsView()
  return obj
end

function SCEN_EDIT.getUnitDefBuildPic(unitDef)
    unitImagePath = "unitpics/" .. unitDef.buildpicname
    local fileExists = VFS.FileExists(unitImagePath)
    if not fileExists then
        unitImagePath = "buildicons/_1to1_128x128/" .. unitDef.name .. ".png"
    end
    return unitImagePath
end

--//=============================================================================
function UnitDefsView:PopulateUnitDefsView()
    self:Clear()
    local unitTerrainId = self.unitTerrainId
    local unitTypesId = self.unitTypesId
    for id, unitDef in pairs(UnitDefs) do
        correctType = unitTypesId == 2 and unitDef.isBuilding or
            unitTypesId == 1 and not unitDef.isBuilding or
            unitTypesId == 3
        
        -- BEAUTIFUL, MARVEL AT IT'S GLORY FOR IT ILLUMINATES US ALL
        correctTerrain = unitTerrainId == 1 and (not unitDef.canFly and
        not unitDef.floater and not unitDef.canSubmerge and unitDef.waterline == 0 and unitDef.minWaterDepth <= 0) or
            unitTerrainId == 2 and unitDef.canFly or
            unitTerrainId == 3 and (unitDef.canHover or unitDef.floater or unitDef.waterline > 0 or unitDef.minWaterDepth > 0) or
            unitTerrainId == 4
        if correctType and correctTerrain then
            local unitImagePath = SCEN_EDIT.getUnitDefBuildPic(unitDef)
            self:AddImage(unitDef.humanName, unitDef.id, unitImagePath)
        end
    end
    self.rows = #self.items / self.columns + 1
	self:SelectItem(0)
end

function UnitDefsView:SelectTerrainId(unitTerrainId)
    self.unitTerrainId = unitTerrainId
    self:PopulateUnitDefsView()
end

function UnitDefsView:SelectUnitTypesId(unitTypesId)
    self.unitTypesId = unitTypesId
    self:PopulateUnitDefsView()
end

function UnitDefsView:SelectTeamId(teamId)
    self.teamId = teamId
end

local function ExtractFileName(filepath)
  filepath = filepath:gsub("\\", "/")
  local lastChar = filepath:sub(-1)
  if (lastChar == "/") then
    filepath = filepath:sub(1,-2)
  end
  local pos,b,e,match,init,n = 1,1,1,1,0,0
  repeat
    pos,init,n = b,init+1,n+1
    b,init,match = filepath:find("/",init,true)
  until (not b)
  if (n==1) then
    return filepath
  else
    return filepath:sub(pos+1)
  end
end

--//=============================================================================

function UnitDefsView:AddImage(name, id, imagefile)
  table.insert(self.items, {name=name, id=id})
  self:AddChild(Chili.LayoutPanel:New{
    width  = self.iconX+10,
    height = self.iconY+20,
    padding = {0,0,0,0},
    itemPadding = {0,0,0,0},
    itemMargin = {0,0,0,0},
    rows = 2,
    columns = 1,

    children = {
      Chili.Image:New {
        width  = self.iconX,
        height = self.iconY,
        passive = true,
        file = ':clr' .. self.iconX .. ',' .. self.iconY .. ':' .. imagefile,
      },
      Chili.Label:New {
        width = self.iconX+10,
        height = 20,
        align = 'center',
        autosize = false,
        caption = name,
      },
    },
  })
end

function UnitDefsView:Clear()
    self.children = {}
    self.items = {}
end

--//=============================================================================

function UnitDefsView:DrawItemBkGnd(index)
  local cell = self._cells[index]
  local itemPadding = self.itemPadding

  if (self.selectedItems[index]) then
    self:DrawItemBackground(cell[1] - itemPadding[1],cell[2] - itemPadding[2],cell[3] + itemPadding[1] + itemPadding[3],cell[4] + itemPadding[2] + itemPadding[4],"selected")
  else
    self:DrawItemBackground(cell[1] - itemPadding[1],cell[2] - itemPadding[2],cell[3] + itemPadding[1] + itemPadding[3],cell[4] + itemPadding[2] + itemPadding[4],"normal")
  end
end

--//=============================================================================

function UnitDefsView:HitTest(x,y)
  local cx,cy = self:LocalToClient(x,y)
  local obj = inherited.HitTest(self,cx,cy)
  if (obj) then return obj end
  local itemIdx = self:GetItemIndexAt(cx,cy)
  return (itemIdx>=0) and self
end


function UnitDefsView:MouseDblClick(x,y)
  local cx,cy = self:LocalToClient(x,y)
  local itemIdx = self:GetItemIndexAt(cx,cy)

  if (itemIdx<0) then return end

  self:CallListeners(self.OnDblClickItem, self.items[itemIdx], itemIdx)
  return self
end

end

--//=============================================================================
