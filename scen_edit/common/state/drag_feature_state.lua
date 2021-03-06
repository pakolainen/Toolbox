DragFeatureState = AbstractState:extends{}

function DragFeatureState:init(featureId, startDiffX, startDiffZ)
    self.featureId = featureId
    self.startDiffX = startDiffX
    self.startDiffZ = startDiffZ
    self.dx = 0
    self.dz = 0
    self.featureGhostViews = {}
end

function DragFeatureState:MouseMove(x, y, dx, dy, button)
    local result, coords = Spring.TraceScreenRay(x, y, true)
    if result == "ground" then
        if not Spring.ValidFeatureID(self.featureId) then
            SCEN_EDIT.stateManager:SetState(DefaultState())
            return false
        end
        local featureX, featureY, featureZ = Spring.GetFeaturePosition(self.featureId)
        self.dx = coords[1] + self.startDiffX - featureX
        self.dz = coords[3] + self.startDiffZ - featureZ
        local featureIds = {self.featureId} --Spring.GetSelectedFeatures()
        self.featureGhostViews = {}
    
        for i = 1, #featureIds do
            local featureId = featureIds[i]
            local featureX, featureY, featureZ = Spring.GetFeaturePosition(featureId)
            local y = Spring.GetGroundHeight(featureX + self.dx, featureZ + self.dz)
            local position = { featureX + self.dx, y, featureZ + self.dz}
            self.featureGhostViews[featureId] = position
        end
    end
end

function DragFeatureState:MouseRelease(x, y, button)
    local commands = {}
    local featureIds = {self.featureId}--Spring.GetSelectedFeatures()
    for i = 1, #featureIds do
        local featureId = featureIds[i]
        local featureX, featureY, featureZ = Spring.GetFeaturePosition(featureId)

        local modelFeatureId = SCEN_EDIT.model.featureManager:getModelFeatureId(featureId)
        local moveCommand = MoveFeatureCommand(modelFeatureId, featureX + self.dx, featureY, featureZ + self.dz)
        table.insert(commands, moveCommand)
    end
    local compoundCommand = CompoundCommand(commands)
    SCEN_EDIT.commandManager:execute(compoundCommand)
    SCEN_EDIT.stateManager:SetState(DefaultState())
end

function DragFeatureState:DrawWorld()
    for featureId, pos in pairs(self.featureGhostViews) do
        gl.PushMatrix()
        gl.Color(0.1, 1, 0.1, 0.4)
        local featureType = Spring.GetFeatureDefID(featureId)
        local featureTeamId = Spring.GetFeatureTeam(featureId)
        gl.Translate(pos[1], pos[2], pos[3])

        local dirX, dirY, dirZ = Spring.GetFeatureDirection(featureId)
        local angleY = math.atan2(dirX, dirZ)
        
        if angleY ~= 0 then
            gl.Rotate(180 / math.pi * angleY, 0, 1, 0)
        end

--        gl.FeatureRaw(featureId, true)
        gl.FeatureShape(featureType, featureTeamId)
        gl.PopMatrix()
    end
end
