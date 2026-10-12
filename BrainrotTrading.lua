--[[
    Brainrot Trading (Auto Buy + Bulk Buy + Auto Roll)
    Everything lives on the Main Page: Units, Auto Buy, Bulk Buy, Auto Roll,
    manual buy, interval, extra unit and help text.
    Requires the latest DraxiLib (with CreateMultiDropdown).
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Drac311/lib/refs/heads/main/DraxiLib.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- SETTINGS (change these if your game uses different names)
-- ============================================================
local REMOTE_FOLDER = "Remotes"      -- ReplicatedStorage.Remotes
local BUY_REMOTE    = "BuyUnit"      -- ReplicatedStorage.Remotes.BuyUnit
local HELD_REMOTE   = "HeldAction"   -- ReplicatedStorage.Remotes.HeldAction

-- Bulk Buy: buys this unit every 0.2 seconds while the toggle is on
local BULK_UNIT = "Graipussi Medussi"
local BULK_INTERVAL = 0.2

-- Auto Roll: WALK to this position (PathfindingService), use the "Use" prompt inside "SummonButton", wait, repeat
local ROLL_POSITION = Vector3.new(-5.8, 3.1, -22.3)
local ROLL_DELAY = 7.5
local ARRIVE_DISTANCE = 5   -- studs: counts as "arrived" when closer than this
local WALK_TIMEOUT = 45     -- seconds before giving up on one walk attempt
local ROLL_PART_NAME = "SummonButton"
local ROLL_PROMPT_NAME = "Use"

local UNITS = {
	"La Grande Combinasion",
	"Strawberry Elephant",
	"Meowl",
	"Skibidi Toilet",
	"Dragon Cannelloni",
	"Ketchuru And Musturu",
	"Tirilikalika Tirilikalako",
	"Ketupat Kepat",
	"Noo My Examine",
	"Job Job Job Sahur",
	"Tralaledon",
	"Chillin Chili",
	"Nuclearo Dinosauro",
	"Swag Soda",
	"Nyan Cat",
	"Pepe",
	"Happy Banana Cat",
	"Smurf Cat",
	"67",
	"Ben",
	"Happy Banana Meme",
	"Trollface",
	"Illuminati",
	"Chicleteirina Bicicleteirina",
	"Chiceletira Bicicleteira",
	"Quesadilla Crocodila",
}

-- ============================================================
-- STATE
-- ============================================================
local autoBuyActive = false
local intervalSec = 45
local selected = {}
local extraUnit = ""
local buying = false
local lastBuy = -math.huge
local buyErrorShown = false

local bulkBuyActive = false
local bulkToggle = nil

local autoRollActive = false
local rollToggle = nil
local promptCache = nil

local remoteCache = {}
local remoteFailedAt = {}

-- ============================================================
-- WINDOW (created BEFORE looking for remotes, so it can never hang)
-- ============================================================
local Window = Library:CreateWindow({
	Name = "Brainrot Trading",
	Footer = "Join the discord for more updates!",
	Discord = "https://discord.gg/YOUR_INVITE",
	ToggleText = "AB",
	ToggleScale = 0.8,
	StartVisible = true,
	Scale = 1,
	ConfigName = "AutoBuy",
	-- For "Auto Execute" (2ndPage): RAW URL of THIS script (the file is called BrainrotTrading.lua in your repo)
	ScriptUrl = "https://raw.githubusercontent.com/Drac311/lib/refs/heads/main/BrainrotTrading.lua",
})

local MainTab = Window:CreateTab("Auto Buy") -- 1st call -> MainPage (everything goes here)

-- ============================================================
-- REMOTES (safe lookup with a time limit)
-- ============================================================
local function getRemote(name)
	local cached = remoteCache[name]
	if cached and cached.Parent then
		return cached
	end
	if os.clock() - (remoteFailedAt[name] or -math.huge) < 10 then
		return nil -- recent failure: don't wait again on every call
	end
	local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER) or ReplicatedStorage:WaitForChild(REMOTE_FOLDER, 5)
	local remote = folder and (folder:FindFirstChild(name) or folder:WaitForChild(name, 5))
	remoteCache[name] = remote
	if not remote then
		remoteFailedAt[name] = os.clock()
	end
	return remote
end

-- Supports both RemoteFunction and RemoteEvent
local function callRemote(name, arg)
	local remote = getRemote(name)
	if not remote then
		error("ReplicatedStorage." .. REMOTE_FOLDER .. "." .. name .. " not found")
	end
	if remote:IsA("RemoteFunction") then
		return remote:InvokeServer(arg)
	elseif remote:IsA("RemoteEvent") then
		remote:FireServer(arg)
		return true
	end
	error(name .. " is not a RemoteFunction or RemoteEvent")
end

local function buyOne(unit)
	return callRemote(BUY_REMOTE, unit)
end

-- Runs when Auto Roll is turned off
local function storeHeld()
	local ok, err = pcall(callRemote, HELD_REMOTE, "Store")
	if not ok then
		warn("[AutoRoll] Store failed: " .. tostring(err))
	end
end

-- "Exterminate Script" (2ndPage) stops everything
Window:OnDestroy(function()
	autoBuyActive = false
	bulkBuyActive = false
	if autoRollActive then
		autoRollActive = false
		task.spawn(storeHeld)
	end
end)

-- ============================================================
-- AUTO BUY
-- ============================================================
-- Final list: selected units + extra unit (no duplicates)
local function unitsToBuy()
	local list, seen = {}, {}
	for _, u in ipairs(selected) do
		if not seen[u] then
			seen[u] = true
			table.insert(list, u)
		end
	end
	local extra = extraUnit:match("^%s*(.-)%s*$")
	if extra ~= "" and not seen[extra] then
		table.insert(list, extra)
	end
	return list
end

-- isAuto = true -> stops if you turn the toggle off mid-cycle
local function buyList(list, isAuto)
	if buying or #list == 0 then
		return
	end
	buying = true
	for _, unit in ipairs(list) do
		if isAuto and not autoBuyActive then
			break
		end
		local ok, err = pcall(buyOne, unit)
		if ok then
			print("[AutoBuy] -> " .. unit)
		else
			warn("[AutoBuy] Error with " .. unit .. ": " .. tostring(err))
			if not buyErrorShown then
				buyErrorShown = true
				Window:Notify({
					Title = "Auto Buy (error)",
					Content = "Purchase failed. Check BUY_REMOTE.",
					Duration = 5,
				})
			end
		end
		task.wait(0.2)
	end
	buying = false
end

-- Checks every 0.5s whether it is time to buy (slider changes apply instantly)
task.spawn(function()
	while Window.Gui and Window.Gui.Parent do
		if autoBuyActive and not buying and (os.clock() - lastBuy) >= intervalSec then
			lastBuy = os.clock()
			buyList(unitsToBuy(), true)
		end
		task.wait(0.5)
	end
end)

-- ============================================================
-- BULK BUY: every 0.2s runs Remotes.BuyUnit:InvokeServer(BULK_UNIT)
-- (each call runs in its own thread, so the pace doesn't depend on the server reply)
-- ============================================================
task.spawn(function()
	local errorShown = false
	while Window.Gui and Window.Gui.Parent do
		if bulkBuyActive then
			if not getRemote(BUY_REMOTE) then
				-- no remote: turn itself off instead of retrying forever
				bulkBuyActive = false
				if bulkToggle then bulkToggle:Set(false, true) end
				Window:Notify({ Title = "Bulk Buy", Content = BUY_REMOTE .. " remote not found", Duration = 5 })
			else
				task.spawn(function()
					local ok, err = pcall(buyOne, BULK_UNIT)
					if not ok and not errorShown then
						errorShown = true -- only warn once so the console doesn't fill up
						warn("[BulkBuy] Error with " .. BULK_UNIT .. ": " .. tostring(err))
					end
				end)
			end
		else
			errorShown = false
		end
		task.wait(BULK_INTERVAL)
	end
end)

-- ============================================================
-- AUTO ROLL: walk to ROLL_POSITION (PathfindingService), use the "Use" prompt inside
-- "SummonButton", wait ROLL_DELAY seconds, repeat. Turning it off runs HeldAction:InvokeServer("Store").
-- ============================================================
-- Finds the "Use" ProximityPrompt (if there are several SummonButtons, picks the closest one)
local function findSummonPrompt()
	if promptCache and promptCache.Parent then
		return promptCache
	end
	local best, bestDist = nil, math.huge
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst.Name == ROLL_PART_NAME then
			local prompt = inst:FindFirstChild(ROLL_PROMPT_NAME, true)
			if prompt and prompt:IsA("ProximityPrompt") then
				local pos
				if inst:IsA("BasePart") then
					pos = inst.Position
				elseif inst:IsA("Model") then
					pos = inst:GetPivot().Position
				end
				local dist = pos and (pos - ROLL_POSITION).Magnitude or math.huge
				if not best or dist < bestDist then
					best, bestDist = prompt, dist
				end
			end
		end
	end
	promptCache = best
	return best
end

local function usePrompt(prompt)
	if fireproximityprompt then
		fireproximityprompt(prompt)
	else
		-- fallback if the executor has no fireproximityprompt
		prompt:InputHoldBegin()
		task.wait((prompt.HoldDuration or 0) + 0.1)
		prompt:InputHoldEnd()
	end
end

-- MoveTo one waypoint and wait until the humanoid gets there (or the timeout passes)
local function moveToWait(hum, pos, timeout)
	local done, reached = false, false
	local conn = hum.MoveToFinished:Connect(function(r)
		done, reached = true, r
	end)
	hum:MoveTo(pos)
	local t0 = os.clock()
	while not done and autoRollActive and os.clock() - t0 < timeout do
		task.wait()
	end
	conn:Disconnect()
	return reached
end

-- Walks to `target` following a PathfindingService path. Returns true if it arrived.
local function walkTo(target)
	local startTime = os.clock()
	local failures = 0

	while autoRollActive and os.clock() - startTime < WALK_TIMEOUT do
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp or hum.Health <= 0 then
			return false
		end
		if (hrp.Position - target).Magnitude <= ARRIVE_DISTANCE then
			return true
		end

		local path = PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
		})
		local okPath = pcall(function()
			path:ComputeAsync(hrp.Position, target)
		end)

		if okPath and path.Status == Enum.PathStatus.Success then
			local blocked = false
			local blockedConn = path.Blocked:Connect(function()
				blocked = true
			end)
			local waypoints = path:GetWaypoints()
			for i = 2, #waypoints do -- waypoint 1 is the starting position
				if not autoRollActive or blocked then
					break
				end
				local wp = waypoints[i]
				if wp.Action == Enum.PathWaypointAction.Jump then
					hum.Jump = true
				end
				if not moveToWait(hum, wp.Position, 3) then
					hum.Jump = true -- probably stuck: jump and recompute the path
					break
				end
			end
			blockedConn:Disconnect()
		else
			-- no path found: try walking straight for a moment, then retry
			failures = failures + 1
			if failures >= 5 then
				return false
			end
			moveToWait(hum, target, 2)
			task.wait(0.5)
		end
	end

	-- stopped (toggle off or timeout): make the character stop walking
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hum and hrp and not autoRollActive then
		hum:MoveTo(hrp.Position)
	end
	return hrp ~= nil and (hrp.Position - target).Magnitude <= ARRIVE_DISTANCE
end

-- returns "used", "notready", "noprompt" or "unreachable"
local function rollOnce()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return "notready"
	end
	local prompt = findSummonPrompt()
	if not prompt then
		return "noprompt"
	end
	if (hrp.Position - ROLL_POSITION).Magnitude > ARRIVE_DISTANCE then
		if not walkTo(ROLL_POSITION) then
			return "unreachable"
		end
	end
	if not autoRollActive then
		return "notready"
	end
	usePrompt(prompt)
	return "used"
end

task.spawn(function()
	local misses, unreachable = 0, 0
	while Window.Gui and Window.Gui.Parent do
		if autoRollActive then
			local ok, result = pcall(rollOnce)
			local waitTime = 1
			if not ok then
				warn("[AutoRoll] Error: " .. tostring(result))
			elseif autoRollActive then
				if result == "used" then
					misses, unreachable = 0, 0
					waitTime = ROLL_DELAY
				elseif result == "noprompt" then
					misses = misses + 1
				elseif result == "unreachable" then
					unreachable = unreachable + 1
				end
				if misses >= 3 or unreachable >= 3 then
					-- turn off without running Store (nothing was rolled)
					local reason = (misses >= 3) and (ROLL_PART_NAME .. " / " .. ROLL_PROMPT_NAME .. " prompt not found")
						or "Couldn't walk to the position"
					misses, unreachable = 0, 0
					autoRollActive = false
					if rollToggle then rollToggle:Set(false, true) end
					Window:Notify({ Title = "Auto Roll", Content = reason, Duration = 5 })
				end
			end
			-- wait (stops immediately if turned off)
			local t0 = os.clock()
			while autoRollActive and os.clock() - t0 < waitTime and Window.Gui and Window.Gui.Parent do
				task.wait(0.1)
			end
		else
			misses, unreachable = 0, 0
			task.wait(0.25)
		end
	end
end)

-- ============================================================
-- MAIN PAGE
-- ============================================================
MainTab:CreateMultiDropdown({
	Name = "Units",
	Options = UNITS,
	Default = {},
	Flag = "SelectedUnits",
	Callback = function(list)
		selected = list
	end,
})

MainTab:CreateToggle({
	Name = "Auto Buy",
	Default = false,
	Flag = "AutoBuyToggle",
	Callback = function(state)
		autoBuyActive = state
		if state then
			lastBuy = -math.huge -- buys as soon as it is turned on
			if #unitsToBuy() == 0 then
				Window:Notify({
					Title = "Auto Buy",
					Content = "Enabled, but no units are selected",
					Duration = 4,
				})
				return
			end
		end
		Window:Notify({
			Title = "Auto Buy",
			Content = state and ("Enabled (every " .. intervalSec .. "s)") or "Disabled",
			Duration = 3,
		})
	end,
})

bulkToggle = MainTab:CreateToggle({
	Name = "Bulk Buy",
	Default = false,
	Flag = false, -- not saved: it never starts by itself when you join
	Callback = function(state)
		bulkBuyActive = state
		Window:Notify({
			Title = "Bulk Buy",
			Content = state and ("Enabled: " .. BULK_UNIT .. " every " .. BULK_INTERVAL .. "s") or "Disabled",
			Duration = 3,
		})
	end,
})

rollToggle = MainTab:CreateToggle({
	Name = "Auto Roll",
	Default = false,
	Flag = false, -- not saved: it never starts by itself when you join
	Callback = function(state)
		autoRollActive = state
		if state then
			Window:Notify({
				Title = "Auto Roll",
				Content = "Enabled: walking to the button (every " .. ROLL_DELAY .. "s)",
				Duration = 3,
			})
		else
			task.spawn(storeHeld)
			Window:Notify({
				Title = "Auto Roll",
				Content = "Disabled (Store sent)",
				Duration = 3,
			})
		end
	end,
})

MainTab:CreateButton({
	Name = "Buy now",
	Callback = function()
		local list = unitsToBuy()
		if #list == 0 then
			Window:Notify({ Title = "Auto Buy", Content = "No units selected", Duration = 3 })
			return
		end
		task.spawn(function()
			buyList(list, false)
			Window:Notify({ Title = "Auto Buy", Content = "Manual purchase done", Duration = 3 })
		end)
	end,
})

MainTab:CreateSlider({
	Name = "Interval",
	Min = 5,
	Max = 120,
	Default = 45,
	Increment = 5,
	Suffix = "s",
	Flag = "Interval",
	Callback = function(v)
		intervalSec = v
	end,
})

MainTab:CreateInput({
	Name = "Extra unit",
	Placeholder = "e.g. Meowl",
	Default = "",
	Flag = "ExtraUnit",
	Callback = function(text)
		extraUnit = text or ""
	end,
})

MainTab:CreateLabel("Save (2ndPage) stores this game's settings")

-- ============================================================
Window:Notify({
	Title = "Brainrot Trading",
	Content = "Ready. Pick units on the main page.",
	Duration = 4,
})
