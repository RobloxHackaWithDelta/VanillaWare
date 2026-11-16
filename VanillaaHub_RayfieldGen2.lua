-- Hub idea: fading (dc: fadingxy_)
-- added some stuff (LOTS OF STUFF): TastyVanillaa (dc: vanillaadev)
-- getting updates rarely cuz fading (the one writing this) is lazy as fuck (still creating some useless and good scripts for this hub) and TastyVanillaa is too busy or sleepy.
-- Key: TastyVanillaa
-- Press K to hide or show the hub.

local GEN2_URL = "https://sirius.menu/gen2" -- stable. Rolling build: https://sirius.menu/gen2-preview
local KEY = "TastyVanillaa"
local TOGGLE_KEY = Enum.KeyCode.K
local THEME = "amethyst" -- default, cobalt, ember, amethyst, frost, rose

-- Gen2 icons are asset ids (named icons like "box" do not work in Gen2)
local TAB_ICON = 93364949241311
local SETTINGS_ICON = 129180860773723

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local okLib, Rayfield = pcall(function()
    return loadstring(game:HttpGet(GEN2_URL))()
end)
if not okLib or type(Rayfield) ~= "table" then
    warn("[Vanillaa Hub] Could not load Rayfield Gen2: " .. tostring(Rayfield))
    return
end

local CATALOG = {
    {
        Tab = "JAB",
        Items = {
            { "Ms TrueHub", "A decently sized hub", "https://scriptblox.com/raw/UP-Just-a-baseplate.-MS-TRUEHUB-229118" },
            { "Krystal Dance Hub", "Krystal Dance and some random extras", "https://pastebin.com/raw/iCcnPsAT" },
            { "Uhhhhhh", "Reanimate script", "https://raw.githubusercontent.com/STEVE-916-create/Uhhhhhh/main/source/reanim.lua" },
            { "Uhhhhhh (Better)", "Improved reanimate, can crash weaker executors", "https://raw.githubusercontent.com/mxsynry/Uhhhhhh/main/source/reanim.lua" },
            { "Moon Converts", "A big pile of converts", "https://github.com/CatThatDrinksSprite/moon-convert/raw/main/Scripts/Main/Moon%20Convert.lua" },
            { "Server Admin (FE)", "Server admin convert", "https://raw.githubusercontent.com/Jskfhggjxu/My-Script/refs/heads/main/ServerHacker-X.lua" },
            { "FE Locust", "Locust by Dr Nowhere. Rejoin to disable", "https://raw.githubusercontent.com/REF829/Vanillaa/refs/heads/main/crap" },
        },
    },
    {
        Tab = "Utilities",
        Items = {
            { "Infinite Yield", "Classic admin command utility", "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source" },
            { "Nameless Admin", "Alternative admin command utility", "https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source" },
            { "Map View", "Top-down map camera (drag, zoom, waypoints)", "https://raw.githubusercontent.com/RobloxHackaWithDelta/MapR/main/MapView.lua" },
        },
    },
    {
        Tab = "Pre-Universal",
        Items = {
            { "Gelatek Hub", "Reanimate hub (a bit broken)", "https://raw.githubusercontent.com/REF829/Vanillaa/refs/heads/main/SorryITookGelatek" },
            { "Become Strange?", "No idea, try it", "https://raw.githubusercontent.com/REF829/Vanillaa/refs/heads/main/shit" },
        },
    },
    {
        Tab = "Vanillaa",
        Items = {
            { "Check Executor Stats", "Beta executor capability check", "https://raw.githubusercontent.com/REF829/Vanillaa/refs/heads/main/Test%20Executor" },
            { "Vanillaa Reanimate", "Custom reanimate", "https://raw.githubusercontent.com/REF829/Vanillaa/refs/heads/main/ActualReanimate" },
        },
    },
    {
        Tab = "Delta",
        Items = {
            { "Delta Customizations", "UI tweaks for Delta", "https://raw.githubusercontent.com/REF829/Vanillaa/refs/heads/main/DeltaCustomizationKeepSecretsss" },
        },
    },
}

---------------------------------------------------------------------
-- SlopWare features (built in, based on Slopware_Hub)
-- When you join SlopWare these turn on by themselves after the hub opens.
---------------------------------------------------------------------
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local SLOPWARE_PLACE_IDS = {} -- optional: add the game's PlaceId / GameId here, e.g. { 1234567890 }
local SLOPWARE_NAME = "slopware" -- also matched against the game name (case insensitive)
local ESP_TARGET = "CriminalBlueGuy"
local CURTAIN_NAMES = { FrontCurtain = true, BadBurger = true, BadHotdog = true, BadChicken = true }
local HITBOX_SIZE = 500 -- studs, same as Slopware_Hub. Lower it if it feels too silly
local HITBOX_TRANSPARENCY = 0.8

-- game detection: matches by PlaceId / GameId list, or by the game name (lowercase) through a matcher
local cachedGameName
local function getGameName()
    if cachedGameName then
        return cachedGameName
    end
    local names = {}
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if ok and type(info) == "table" and type(info.Name) == "string" then
        table.insert(names, info.Name)
    end
    table.insert(names, tostring(game.Name))
    cachedGameName = names
    return names
end

local function matchGame(placeIds, nameMatcher)
    for _, id in ipairs(placeIds) do
        if game.PlaceId == id or game.GameId == id then
            return true
        end
    end
    for _, name in ipairs(getGameName()) do
        local ok, result = pcall(nameMatcher, name:lower())
        if ok and result then
            return true
        end
    end
    return false
end

-- generic looping feature: step() runs every interval while on, cleanup() runs when turned off
local function makeLoopFeature(id, name, desc, interval, step, cleanup)
    local running = false
    local gen = 0
    local feature = { id = id, name = name, desc = desc }
    function feature.start()
        if running then
            return
        end
        running = true
        gen = gen + 1
        local mine = gen
        task.spawn(function()
            while running and gen == mine do
                pcall(step)
                task.wait(interval)
            end
        end)
    end
    function feature.stop()
        if not running then
            return
        end
        running = false
        pcall(cleanup)
    end
    return feature
end

-- Chill Dev ESP (highlight + "right here" tag on CriminalBlueGuy)
local espObjects = {}
local function clearEsp()
    for _, obj in ipairs(espObjects) do
        pcall(function()
            obj:Destroy()
        end)
    end
    table.clear(espObjects)
end

local function findEspTarget()
    local plr = Players:FindFirstChild(ESP_TARGET)
    if plr and plr.Character then
        return plr.Character
    end
    local found = workspace:FindFirstChild(ESP_TARGET, true)
    if found and found:IsA("Model") then
        return found
    end
    return nil
end

local espFeature = makeLoopFeature("ChillDevEsp", "Chill Dev ESP", "Highlights and tags " .. ESP_TARGET, 1, function()
    local target = findEspTarget()
    if not target then
        return
    end
    if not target:FindFirstChild("VH_ChillEsp") then
        local hl = Instance.new("Highlight")
        hl.Name = "VH_ChillEsp"
        hl.FillColor = Color3.fromRGB(255, 60, 60)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = target
        table.insert(espObjects, hl)
    end
    local adornee = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
    if adornee and not target:FindFirstChild("VH_ChillTag") then
        local bb = Instance.new("BillboardGui")
        bb.Name = "VH_ChillTag"
        bb.Adornee = adornee
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 120, 0, 30)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.Parent = target
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "right here"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = bb
        table.insert(espObjects, bb)
    end
end, clearEsp)

-- Noclip (Stepped connection so it applies before physics each frame)
local noclipConn
local noclipFeature = {
    id = "Noclip",
    name = "Noclip",
    desc = "Walk through walls",
    start = function()
        if noclipConn then
            return
        end
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then
                return
            end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end,
    stop = function()
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
    end,
}

-- Remove Curtains n More (FrontCurtain, BadBurger, BadHotdog, BadChicken)
local function sweepCurtains()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if CURTAIN_NAMES[obj.Name] then
            pcall(function()
                obj:Destroy()
            end)
        end
    end
end
local curtainFeature = makeLoopFeature("RemoveCurtains", "Remove Curtains n More", "Deletes the curtains and the bad food", 2, sweepCurtains, function() end)

-- Hitbox Expander (other players only, original sizes are restored when turned off)
local hitboxOriginals = {}
local function restoreHitboxes()
    for hrp, data in pairs(hitboxOriginals) do
        pcall(function()
            if hrp and hrp.Parent then
                hrp.Size = data.Size
                hrp.Transparency = data.Transparency
                hrp.CanCollide = data.CanCollide
            end
        end)
    end
    table.clear(hitboxOriginals)
end

local hitboxFeature = makeLoopFeature("HitboxExpander", "Hitbox Expander", "Makes other players' hitboxes huge", 0.5, function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:IsA("BasePart") then
                if not hitboxOriginals[hrp] then
                    hitboxOriginals[hrp] = {
                        Size = hrp.Size,
                        Transparency = hrp.Transparency,
                        CanCollide = hrp.CanCollide,
                    }
                end
                hrp.Size = Vector3.new(HITBOX_SIZE, HITBOX_SIZE, HITBOX_SIZE)
                hrp.Transparency = HITBOX_TRANSPARENCY
                hrp.CanCollide = false
            end
        end
    end
end, restoreHitboxes)

local SLOP_FEATURES = { espFeature, noclipFeature, curtainFeature, hitboxFeature }

---------------------------------------------------------------------
-- shared features (used by several games)
---------------------------------------------------------------------
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")

-- set to the hub's notify function once the hub is built
local uiNotify = function() end

local SPEED_VALUE = 50

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function cframeOf(inst)
    if not inst then
        return nil
    end
    if inst:IsA("BasePart") then
        return inst.CFrame
    end
    local ok, cf = pcall(function()
        return inst:GetPivot()
    end)
    return ok and cf or nil
end

-- Player ESP (every other player: highlight + name tag)
local playerEspObjects = {}
local function clearPlayerEsp()
    for _, obj in ipairs(playerEspObjects) do
        pcall(function()
            obj:Destroy()
        end)
    end
    table.clear(playerEspObjects)
end

local playerEspFeature = makeLoopFeature("PlayerEsp", "Player ESP", "Highlights and names every other player", 1, function()
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr ~= LocalPlayer and plr.Character
        if char then
            if not char:FindFirstChild("VH_PlayerEsp") then
                local hl = Instance.new("Highlight")
                hl.Name = "VH_PlayerEsp"
                hl.FillColor = Color3.fromRGB(255, 70, 70)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.6
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = char
                table.insert(playerEspObjects, hl)
            end
            local head = char:FindFirstChild("Head")
            if head and not char:FindFirstChild("VH_PlayerTag") then
                local bb = Instance.new("BillboardGui")
                bb.Name = "VH_PlayerTag"
                bb.Adornee = head
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 120, 0, 24)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.Parent = char
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = plr.DisplayName
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                label.TextStrokeTransparency = 0
                label.TextScaled = true
                label.Font = Enum.Font.GothamBold
                label.Parent = bb
                table.insert(playerEspObjects, bb)
            end
        end
    end
end, clearPlayerEsp)

-- Speed boost
local speedFeature = makeLoopFeature("Speed", "Speed Boost", "WalkSpeed " .. SPEED_VALUE, 0.25, function()
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = SPEED_VALUE
    end
end, function()
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = 16
    end
end)

-- Infinite jump
local infJumpConn
local infJumpFeature = {
    id = "InfJump",
    name = "Infinite Jump",
    desc = "Jump again in mid-air",
    start = function()
        if infJumpConn then
            return
        end
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local hum = getHumanoid()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end,
    stop = function()
        if infJumpConn then
            infJumpConn:Disconnect()
            infJumpConn = nil
        end
    end,
}

-- Fullbright
local lightingBackup
local fullbrightFeature = makeLoopFeature("Fullbright", "Fullbright", "Removes darkness and fog", 1, function()
    if not lightingBackup then
        lightingBackup = {
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            FogEnd = Lighting.FogEnd,
        }
    end
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    Lighting.FogEnd = 1000000
end, function()
    if lightingBackup then
        Lighting.Brightness = lightingBackup.Brightness
        Lighting.Ambient = lightingBackup.Ambient
        Lighting.OutdoorAmbient = lightingBackup.OutdoorAmbient
        Lighting.FogEnd = lightingBackup.FogEnd
        lightingBackup = nil
    end
end)

-- Anti AFK
local antiAfkConn
local antiAfkFeature = {
    id = "AntiAfk",
    name = "Anti AFK",
    desc = "Stops the idle kick while you farm",
    start = function()
        if antiAfkConn then
            return
        end
        antiAfkConn = LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end,
    stop = function()
        if antiAfkConn then
            antiAfkConn:Disconnect()
            antiAfkConn = nil
        end
    end,
}

---------------------------------------------------------------------
-- Build A Boat For Treasure: gold auto farm
-- Teleports through CaveStage1..10 (DarknessPart), then the golden chest, then repeats after respawn.
---------------------------------------------------------------------
local FARM_STAGE_COUNT = 10
local FARM_STAGE_WAIT = 3 -- seconds spent at each stage (raise it if stages are not counting)
local FARM_RUN_DELAY = 4 -- seconds between runs
local FARM_CHEST_TIMEOUT = 25 -- seconds to wait at the chest for the respawn

local farmRunning = false
local farmGen = 0
local farmRuns = 0
local farmPad

local function farmTeleport(cf)
    local root = getRoot()
    if not root or not cf then
        return false
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.CFrame = cf
    -- invisible pad under the character so it does not fall while it waits
    if not farmPad or not farmPad.Parent then
        farmPad = Instance.new("Part")
        farmPad.Name = "VH_FarmPad"
        farmPad.Anchored = true
        farmPad.Size = Vector3.new(14, 1, 14)
        farmPad.Transparency = 1
        farmPad.Parent = workspace
    end
    farmPad.CFrame = CFrame.new(root.Position - Vector3.new(0, 6, 0))
    return true
end

local function farmLoop(mine)
    local function alive()
        return farmRunning and farmGen == mine
    end
    while alive() do
        local stages = workspace:FindFirstChild("BoatStages")
        stages = stages and stages:FindFirstChild("NormalStages")
        if not stages or not getRoot() then
            task.wait(1)
        else
            local respawned = false
            local conn = LocalPlayer.CharacterAdded:Connect(function()
                respawned = true
            end)

            for i = 1, FARM_STAGE_COUNT do
                if not alive() then
                    break
                end
                local stage = stages:FindFirstChild("CaveStage" .. i)
                local cf = cframeOf(stage and stage:FindFirstChild("DarknessPart"))
                if cf and farmTeleport(cf) then
                    task.wait(FARM_STAGE_WAIT)
                end
            end

            local theEnd = stages:FindFirstChild("TheEnd")
            local chest = theEnd and theEnd:FindFirstChild("GoldenChest")
            local trigger = chest and chest:FindFirstChild("Trigger")
            if alive() and trigger then
                local waited = 0
                while alive() and not respawned and waited < FARM_CHEST_TIMEOUT do
                    farmTeleport(cframeOf(trigger))
                    pcall(function()
                        local root = getRoot()
                        if firetouchinterest and root and trigger:IsA("BasePart") then
                            firetouchinterest(root, trigger, 0)
                            firetouchinterest(root, trigger, 1)
                        end
                    end)
                    task.wait(1)
                    waited = waited + 1
                end
            end
            conn:Disconnect()

            if alive() then
                farmRuns = farmRuns + 1
                uiNotify("Auto Farm", "Run " .. farmRuns .. " finished.", 3)
                local waited = 0
                while alive() and not getRoot() and waited < 20 do
                    task.wait(0.5)
                    waited = waited + 0.5
                end
                task.wait(FARM_RUN_DELAY)
            end
        end
    end
end

local farmFeature = {
    id = "GoldFarm",
    name = "Auto Farm Gold",
    desc = "Runs the stages and the chest again and again",
    start = function()
        if farmRunning then
            return
        end
        farmRunning = true
        farmGen = farmGen + 1
        local mine = farmGen
        task.spawn(function()
            local ok, err = pcall(farmLoop, mine)
            if not ok then
                warn("[Vanillaa Hub] Auto farm error: " .. tostring(err))
            end
        end)
    end,
    stop = function()
        farmRunning = false
        if farmPad then
            pcall(function()
                farmPad:Destroy()
            end)
            farmPad = nil
        end
    end,
}

---------------------------------------------------------------------
-- The Food Massacre: delete teleporters (spawn points are kept)
-- Anything named like a teleporter or portal is removed. This is local to you.
---------------------------------------------------------------------
local function isTeleporter(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then
        return false
    end
    if obj:IsA("SpawnLocation") then
        return false
    end
    local n = obj.Name:lower()
    if n:find("spawn", 1, true) then
        return false
    end
    if not (n:find("teleport", 1, true) or n:find("portal", 1, true)) then
        return false
    end
    if obj:IsA("Model") and obj:FindFirstChildWhichIsA("SpawnLocation", true) then
        return false
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char and (obj == char or obj:IsDescendantOf(char)) then
            return false
        end
    end
    return true
end

local function sweepTeleporters()
    local removed = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Parent and isTeleporter(obj) then
            local ok = pcall(function()
                obj:Destroy()
            end)
            if ok then
                removed = removed + 1
            end
        end
    end
    return removed
end

local teleporterFeature = makeLoopFeature("DelTeleporters", "Delete Teleporters", "Removes teleporters, spawn points stay", 2, sweepTeleporters, function() end)

---------------------------------------------------------------------
-- game table: each supported game gets its own tab (and only that tab)
---------------------------------------------------------------------
local BABFT_PLACE_IDS = { 537413528 }
local FOOD_MASSACRE_PLACE_IDS = { 17402397767 } -- The Breakfast Massacre, change if your Food Massacre is another game
local SMILE_PLACE_IDS = {} -- optional: PlaceId / GameId of the game named :) (the Settings tab shows the current PlaceId)
local MURDURR_PLACE_IDS = { 79735281630764 }

local GAMES = {
    {
        id = "SlopWare",
        tab = "SlopWare",
        features = SLOP_FEATURES,
        autoEnable = true,
        hint = "These turn on by themselves when you join SlopWare. Use the toggles to switch any of them off.",
        detect = function()
            return matchGame(SLOPWARE_PLACE_IDS, function(n)
                return n:find(SLOPWARE_NAME, 1, true) ~= nil
            end)
        end,
    },
    {
        id = "BABFT",
        tab = "Build A Boat",
        features = { farmFeature, antiAfkFeature },
        autoEnable = false,
        hint = "Turn on Auto Farm Gold and leave it running. Each run goes through every stage, grabs the chest and starts over after the respawn.",
        detect = function()
            return matchGame(BABFT_PLACE_IDS, function(n)
                return n:find("build a boat for treasure", 1, true) ~= nil
            end)
        end,
    },
    {
        id = "FoodMassacre",
        tab = "Food Massacre",
        features = { playerEspFeature, teleporterFeature, noclipFeature, speedFeature, infJumpFeature, fullbrightFeature },
        buttons = {
            {
                name = "Delete teleporters now",
                desc = "One sweep, spawn points are kept",
                run = function()
                    local count = sweepTeleporters()
                    uiNotify("Teleporters", "Removed " .. count .. " teleporter(s).", 4)
                end,
            },
        },
        autoEnable = false,
        hint = "Player ESP, delete teleporters (spawn points are kept), noclip, speed, infinite jump and fullbright.",
        detect = function()
            return matchGame(FOOD_MASSACRE_PLACE_IDS, function(n)
                return n:find("food massacre", 1, true) ~= nil or n:find("breakfast massacre", 1, true) ~= nil
            end)
        end,
    },
    {
        id = "Smile",
        tab = ":)",
        features = { playerEspFeature, noclipFeature, speedFeature, infJumpFeature, fullbrightFeature },
        autoEnable = false,
        hint = "General tools for the game called :) (ESP, noclip, speed, infinite jump, fullbright).",
        detect = function()
            return matchGame(SMILE_PLACE_IDS, function(n)
                -- drop [tags] and spaces, then accept a name that is or starts with :)
                local stripped = n:gsub("%b[]", "")
                local compact = stripped:gsub("%s", "")
                return compact:sub(1, 2) == ":)" or compact:sub(1, 3) == ":-)"
            end)
        end,
    },
    {
        id = "MurDurr",
        tab = "MurDurr",
        features = { playerEspFeature, noclipFeature, speedFeature, infJumpFeature, fullbrightFeature },
        autoEnable = false,
        hint = "General tools for MurDurr: ESP to see where everyone (and Durr) is, noclip, speed, infinite jump and fullbright.",
        detect = function()
            return matchGame(MURDURR_PLACE_IDS, function(n)
                return n:gsub("%s", ""):find("murdurr", 1, true) ~= nil
            end)
        end,
    },
}

-- If the tab for a game does not show up, put its id here to force it: "SlopWare", "BABFT", "FoodMassacre", "Smile" or "MurDurr"
local FORCE_GAME = nil

local SHOW_ALL_TABS_IN_GAMES = false -- true = keep the normal script tabs next to the game tab

local function detectGame()
    if FORCE_GAME then
        for _, g in ipairs(GAMES) do
            if g.id == FORCE_GAME then
                return g
            end
        end
    end
    for _, g in ipairs(GAMES) do
        local ok, result = pcall(g.detect)
        if ok and result then
            return g
        end
    end
    return nil
end

---------------------------------------------------------------------
-- main hub
---------------------------------------------------------------------
local function buildHub()
    local window = Rayfield:CreateWindow({
        name = "Vanillaa Hub",
        subtitle = "Beta | Tasty Edition",
        theme = THEME,
        sidebarLayout = true,
        profile = "Vanillaa Hub",
        showName = "Vanillaa",
        configuration = {
            autoSave = true,
            autoLoad = true,
            fileName = "VanillaaHubGen2",
        },
    })

    local notifyResults = true

    local function notify(title, content, duration)
        pcall(function()
            window:Notify({
                title = title,
                content = content,
                duration = duration or 4,
            })
        end)
    end

    local function runUrl(label, url)
        local ok, err = pcall(function()
            local source = game:HttpGet(url, true)
            local fn, compileErr = loadstring(source)
            if not fn then
                error(compileErr or "script failed to compile", 0)
            end
            fn()
        end)
        if notifyResults then
            if ok then
                notify(label, "Loaded.", 3)
            else
                notify(label .. " failed", tostring(err), 6)
            end
        end
        if not ok then
            warn("[Vanillaa Hub] " .. label .. " failed: " .. tostring(err))
        end
    end

    uiNotify = notify

    -- In a supported game only that game's tab is shown (plus Settings).
    -- In any other game the normal script tabs are shown and no game tab exists.
    local activeGame = detectGame()
    if activeGame then
        local gameTab = window:CreateTab({ name = activeGame.tab, icon = TAB_ICON })
        gameTab:CreateSection({ name = activeGame.tab })
        local toggles = {}
        for i, feature in ipairs(activeGame.features) do
            toggles[i] = gameTab:CreateToggle({
                name = feature.name,
                description = feature.desc,
                value = false,
                flag = "VH_" .. activeGame.id .. "_" .. feature.id,
                callback = function(value)
                    if value then
                        feature.start()
                    else
                        feature.stop()
                    end
                end,
            })
        end
        for _, b in ipairs(activeGame.buttons or {}) do
            gameTab:CreateButton({
                name = b.name,
                description = b.desc,
                callback = function()
                    task.spawn(function()
                        local ok, err = pcall(b.run)
                        if not ok then
                            warn("[Vanillaa Hub] " .. b.name .. " failed: " .. tostring(err))
                        end
                    end)
                end,
            })
        end
        gameTab:CreateText({
            name = "Game detected: " .. activeGame.tab,
            text = activeGame.hint,
        })

        if activeGame.autoEnable then
            -- small delay so a saved config can't flip them back off right after
            task.delay(1.5, function()
                local names = {}
                for i, feature in ipairs(activeGame.features) do
                    feature.start()
                    table.insert(names, feature.name)
                    pcall(function()
                        toggles[i]:Set(true)
                    end)
                end
                notify(activeGame.tab .. " detected", table.concat(names, ", ") .. " are on.", 5)
            end)
        end
    end

    local showCatalog = (activeGame == nil) or SHOW_ALL_TABS_IN_GAMES
    for _, group in ipairs(showCatalog and CATALOG or {}) do
        local tab = window:CreateTab({ name = group.Tab, icon = TAB_ICON })
        tab:CreateSection({ name = group.Tab })
        for _, item in ipairs(group.Items) do
            local name, desc, url = item[1], item[2], item[3]
            tab:CreateButton({
                name = name,
                description = desc,
                callback = function()
                    task.spawn(runUrl, name, url)
                end,
            })
        end
    end

    local settings = window:CreateTab({ name = "Settings", icon = SETTINGS_ICON })
    settings:CreateSection({ name = "Hub" })

    settings:CreateToggle({
        name = "Show load notifications",
        value = true,
        flag = "NotifyResults",
        callback = function(value)
            notifyResults = value
        end,
    })

    settings:CreateButton({
        name = "Rejoin server",
        description = "Teleports you back into this server",
        callback = function()
            pcall(function()
                if #Players:GetPlayers() <= 1 then
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                else
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end)
        end,
    })

    local keyConn
    settings:CreateButton({
        name = "Destroy UI",
        description = "Removes the hub completely",
        callback = function()
            if keyConn then
                keyConn:Disconnect()
            end
            for _, g in ipairs(GAMES) do
                for _, feature in ipairs(g.features) do
                    pcall(feature.stop)
                end
            end
            pcall(function()
                window:Unload()
            end)
        end,
    })

    settings:CreateText({
        name = "Current game",
        text = "Name: " .. table.concat(getGameName(), " / ") .. " | PlaceId: " .. tostring(game.PlaceId) .. " | Tab: " .. (activeGame and activeGame.tab or "none"),
    })

    settings:CreateText({
        name = "Tips",
        text = "Press K to hide or show the hub. Scripts load from remote URLs, so if one fails the link is probably dead.",
    })

    keyConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == TOGGLE_KEY then
            pcall(function()
                window:ToggleHide()
            end)
        end
    end)

    notify("Vanillaa Hub", "Unlocked. Press K to toggle the UI.", 5)
end

---------------------------------------------------------------------
-- key memory: a valid key is saved and remembered for 30 days
-- after that the key window shows again, and typing the key starts a new 30 days
---------------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local KEY_FILE = "VanillaaHub_Key.json"
local KEY_LIFETIME = 30 * 24 * 60 * 60 -- 30 days in seconds

local function canUseFiles()
    return type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function"
end

local function keyStillValid()
    if not canUseFiles() then
        return false
    end
    local ok, data = pcall(function()
        if not isfile(KEY_FILE) then
            return nil
        end
        return HttpService:JSONDecode(readfile(KEY_FILE))
    end)
    if not ok or type(data) ~= "table" then
        return false
    end
    if data.key ~= KEY then
        return false
    end
    local savedAt = tonumber(data.time)
    if not savedAt then
        return false
    end
    local age = os.time() - savedAt
    return age >= 0 and age < KEY_LIFETIME
end

local function rememberKey()
    if not canUseFiles() then
        warn("[Vanillaa Hub] This executor cannot save files, so the key will be asked every time.")
        return
    end
    pcall(function()
        writefile(KEY_FILE, HttpService:JSONEncode({ key = KEY, time = os.time() }))
    end)
end

---------------------------------------------------------------------
-- key gate
---------------------------------------------------------------------
local function showKeyGate()
    local unlocked = false

    local keyWindow = Rayfield:CreateWindow({
        name = "Vanillaa Hub",
        subtitle = "Key System",
        theme = THEME,
        showName = "Vanillaa",
    })

    local keyTab = keyWindow:CreateTab({ name = "Key", icon = TAB_ICON })
    keyTab:CreateText({
        name = "Vanillaa Key System",
        text = "Vanillaa, one of the most powerful teams. Enter the key below and press Submit. The key is remembered for 30 days.",
    })

    local keyInput

    local function checkKey(text)
        if unlocked then
            return
        end
        local entered = tostring(text or ""):match("^%s*(.-)%s*$")
        if entered == KEY then
            unlocked = true
            rememberKey()
            pcall(function()
                keyWindow:Notify({ title = "Key accepted", content = "Welcome in. Saved for 30 days.", duration = 3 })
            end)
            task.defer(function()
                task.wait(0.6)
                pcall(function()
                    keyWindow:Unload()
                end)
                task.wait(0.4)
                buildHub()
            end)
        else
            pcall(function()
                keyWindow:Notify({ title = "Wrong key", content = "That key is not right, try again.", duration = 4 })
            end)
        end
    end

    keyInput = keyTab:CreateInput({
        name = "Key",
        description = "Case sensitive",
        placeholder = "Enter key...",
        forgetState = true,
        flag = "VanillaaKeyInput",
        callback = function(text)
            if text ~= nil and text ~= "" then
                checkKey(text)
            end
        end,
    })

    keyTab:CreateButton({
        name = "Submit key",
        callback = function()
            checkKey(keyInput.value)
        end,
    })
end

if keyStillValid() then
    buildHub()
else
    showKeyGate()
end
