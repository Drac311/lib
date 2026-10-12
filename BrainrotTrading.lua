--[[
    Brainrot Trading (Auto Buy + Bulk Buy + Auto Roll)
    Everything lives on the Main Page: Units, Auto Buy, Bulk Buy, Auto Roll,
    manual buy, interval, extra unit and help text.
    Requires the latest DraxiLib (with CreateMultiDropdown).
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Drac311/lib/refs/heads/main/DraxiLib.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

-- Auto Roll: go to this position, use the "Use" prompt inside "SummonButton", wait, repeat
local ROLL_POSITION = Vector3.new(-5.8, 3.1, -22.3)
local ROLL_DELAY = 7.5
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
-- AUTO ROLL: go to ROLL_POSITION, use the "Use" prompt inside "SummonButton",
-- wait ROLL_DELAY seconds, repeat. Turning it off runs HeldAction:InvokeServer("Store").
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

-- returns true if the prompt was used, false if the character wasn't ready, nil if the prompt wasn't found
local function rollOnce()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	local prompt = findSummonPrompt()
	if not prompt then
		return nil
	end
	if (hrp.Position - ROLL_POSITION).Magnitude > 4 then
		hrp.CFrame = CFrame.new(ROLL_POSITION)
		task.wait(0.3) -- give the game a moment to register the new position
	end
	usePrompt(prompt)
	return true
end

task.spawn(function()
	local misses = 0
	while Window.Gui and Window.Gui.Parent do
		if autoRollActive then
			local ok, result = pcall(rollOnce)
			if not ok then
				warn("[AutoRoll] Error: " .. tostring(result))
			elseif result == nil then
				misses = misses + 1
				if misses >= 3 then
					-- the prompt doesn't exist: turn off without running Store
					misses = 0
					autoRollActive = false
					if rollToggle then rollToggle:Set(false, true) end
					Window:Notify({ Title = "Auto Roll", Content = ROLL_PART_NAME .. " / " .. ROLL_PROMPT_NAME .. " prompt not found", Duration = 5 })
				end
			elseif result == true then
				misses = 0
			end
			-- wait ROLL_DELAY seconds (stops immediately if turned off)
			local t0 = os.clock()
			while autoRollActive and os.clock() - t0 < ROLL_DELAY and Window.Gui and Window.Gui.Parent do
				task.wait(0.1)
			end
		else
			misses = 0
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
				Content = "Enabled (every " .. ROLL_DELAY .. "s)",
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
