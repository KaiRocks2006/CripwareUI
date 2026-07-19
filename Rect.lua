local Rect = {}
Rect.__index = Rect

local LocalizationService = game:GetService("LocalizationService")
local Workspace = game:GetService("Workspace")

local function GetScreenBounds(part: BasePart)
    local cam = Workspace.CurrentCamera
    local cf = part.CFrame
    local size = part.Size / 2

    -- 8 corners of the oriented bounding box
    local corners = {
        cf * Vector3.new( size.X,  size.Y,  size.Z),
        cf * Vector3.new( size.X,  size.Y, -size.Z),
        cf * Vector3.new( size.X, -size.Y,  size.Z),
        cf * Vector3.new( size.X, -size.Y, -size.Z),
        cf * Vector3.new(-size.X,  size.Y,  size.Z),
        cf * Vector3.new(-size.X,  size.Y, -size.Z),
        cf * Vector3.new(-size.X, -size.Y,  size.Z),
        cf * Vector3.new(-size.X, -size.Y, -size.Z),
    }

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, worldPos in corners do
        local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
        if onScreen then
            if screenPos.X < minX then minX = screenPos.X end
            if screenPos.Y < minY then minY = screenPos.Y end
            if screenPos.X > maxX then maxX = screenPos.X end
            if screenPos.Y > maxY then maxY = screenPos.Y end
        end
    end

    return minX, minY, maxX - minX, maxY - minY
end

local function Log(...)
    local args = ...
    local argsAsString = ""
    
    local function iterateTable(table, depth)
        local d = depth or 1
        argsAsString += string.rep("  ", d)
        for i, v in pairs(table) do
            local t: string = typeof(v)
            if t == "string" then
                argsAsString += v
                if i < #table then argsAsString += "," end
                argsAsString += "\n"
            elseif t == "table" then
                argsAsString += "{\n"
                local tmp = iterateTable(v, d + 1)
                argsAsString += "}"
                if i < #table then argsAsString += "," end
                argsAsString += "\n"
            else
                if i < #table then argsAsString += "," end
                argsAsString += tostring(v) .. "\n"
            end
        end
    end
end

function Rect.new(args)
    local self = setmetatable({}, Rect)
    if args then
        self.X = args.X or 0
        self.Y = args.Y or 0
        self.W = args.W or 0
        self.H = args.H or 0
        self.Color = args.Color or Color3.new(1, 1, 1)
        self.Fill = args.Fill or false
        self.Thickness = args.Thickness or 1
        self.Transparency = args.Transparency or 0
        self.Visible = args.Visible or false
    else
        self.X = 0
        self.Y = 0
        self.W = 0
        self.H = 0
        self.Color = Color3.new(1, 1, 1)
        self.Fill = false
        self.Thickness = 1
        self.Transparency = 0
        self.Visible = false
    end
    self.Box = nil
    return self
end

function Rect.FromPart(part: BasePart)
    local x, y, w, h = GetScreenBounds(part)
    return Rect.new({
        X = x,
        Y = y,
        W = w,
        H = h,
    })
end

function Rect.FromModel(model: Model)
    local cam = Workspace.CurrentCamera
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            local cf = part.CFrame
            local hs = part.Size / 2

            local corners = {
                cf * Vector3.new( hs.X,  hs.Y,  hs.Z),
                cf * Vector3.new( hs.X,  hs.Y, -hs.Z),
                cf * Vector3.new( hs.X, -hs.Y,  hs.Z),
                cf * Vector3.new( hs.X, -hs.Y, -hs.Z),
                cf * Vector3.new(-hs.X,  hs.Y,  hs.Z),
                cf * Vector3.new(-hs.X,  hs.Y, -hs.Z),
                cf * Vector3.new(-hs.X, -hs.Y,  hs.Z),
                cf * Vector3.new(-hs.X, -hs.Y, -hs.Z),
            }

            for _, worldPos in corners do
                local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
                if onScreen then
                    if screenPos.X < minX then minX = screenPos.X end
                    if screenPos.Y < minY then minY = screenPos.Y end
                    if screenPos.X > maxX then maxX = screenPos.X end
                    if screenPos.Y > maxY then maxY = screenPos.Y end
                end
            end
        end
    end

    -- Guard: if nothing was on screen, return a zero rect
    if minX == math.huge then
        return Rect.new()
    end

    return Rect.new({
        X = minX,
        Y = minY,
        W = maxX - minX,
        H = maxY - minY,
    })
end

function Rect:AsDrawing() 
    local d = Drawing.new('Square')
    d.Visible = self.Visible
    d.Position = Vector2.new(self.X, self.Y)
    d.Size = Vector2.new(self.W, self.H)
    d.Color = self.Color
    d.Filled = self.Fill
    d.Transparency = self.Transparency
    d.Thickness = self.Thickness
    self.Box = d
    return self.Box
end

function Rect:UpdateDrawing(part: BasePart)
    local x, y, w, h = GetScreenBounds(part)
    self.X = x
    self.Y = y
    self.W = w
    self.H = h
    if self.Box then
        self.Box.Position = Vector2.new(self.X, self.Y)
        self.Box.Size = Vector2.new(self.W, self.H)
    end
end

function Rect:UpdateDrawingFromModel(model: Model)
    local cam = Workspace.CurrentCamera
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            local cf = part.CFrame
            local hs = part.Size / 2

            local corners = {
                cf * Vector3.new( hs.X,  hs.Y,  hs.Z),
                cf * Vector3.new( hs.X,  hs.Y, -hs.Z),
                cf * Vector3.new( hs.X, -hs.Y,  hs.Z),
                cf * Vector3.new( hs.X, -hs.Y, -hs.Z),
                cf * Vector3.new(-hs.X,  hs.Y,  hs.Z),
                cf * Vector3.new(-hs.X,  hs.Y, -hs.Z),
                cf * Vector3.new(-hs.X, -hs.Y,  hs.Z),
                cf * Vector3.new(-hs.X, -hs.Y, -hs.Z),
            }

            for _, worldPos in corners do
                local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
                if onScreen then
                    if screenPos.X < minX then minX = screenPos.X end
                    if screenPos.Y < minY then minY = screenPos.Y end
                    if screenPos.X > maxX then maxX = screenPos.X end
                    if screenPos.Y > maxY then maxY = screenPos.Y end
                end
            end
        end
    end

    if minX == math.huge then
        -- Entire model off-screen — hide the box
        if self.Box then self.Box.Visible = false end
        return
    end

    self.X = minX
    self.Y = minY
    self.W = maxX - minX
    self.H = maxY - minY

    if self.Box then
        self.Box.Position = Vector2.new(self.X, self.Y)
        self.Box.Size = Vector2.new(self.W, self.H)
        self.Box.Visible = self.Visible
    end
end

function Rect:Update(instance: Instance)
    if instance:IsA("Model") then
        self:UpdateDrawing(instance)
    elseif instance:IsA("BasePart") or instance:IsA("MeshPart") then
        self:UpdateDrawingFromModel(instance)
    else

    end
end

function Rect:Destroy()
    if self.Box then
        self.Box:Remove()
        self.Box = nil
    end
end

return Rect