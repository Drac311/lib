--[[
    Draxi UI Library
    Estilo Rayfield, basada en el diseño de "Draxi Script".

    API:
        local Library = loadstring(...)()   -- o require
        local Window  = Library:CreateWindow({ Name, Footer, ToggleText, ToggleKey, Accent })
        local Tab     = Window:CreateTab("Nombre")
        Tab:CreateButton({ Name, Callback })
        Tab:CreateToggle({ Name, Default, Callback })
        Tab:CreateSlider({ Name, Min, Max, Default, Increment, Callback })
        Tab:CreateInput({ Name, Placeholder, Default, Callback })
        Tab:CreateDropdown({ Name, Options, Default, Callback })
        Tab:CreateLabel("Texto")
        Window:Notify({ Title, Content, Duration })
        Window:Destroy()
]]

local Library = {}
Library.__index = Library

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local FONT = Enum.Font.FredokaOne

local Theme = {
	Window = Color3.fromRGB(103, 103, 103),
	Title = Color3.fromRGB(72, 72, 72),
	Element = Color3.fromRGB(87, 87, 87),
	Label = Color3.fromRGB(121, 121, 121),
	Stroke = Color3.fromRGB(51, 51, 51),
	Control = Color3.fromRGB(140, 140, 140),
	ControlStroke = Color3.fromRGB(126, 126, 126),
	Accent = Color3.fromRGB(19, 235, 41),
	AccentStroke = Color3.fromRGB(13, 151, 27),
	On = Color3.fromRGB(11, 105, 6),
	Off = Color3.fromRGB(141, 6, 24),
	Text = Color3.fromRGB(0, 0, 0),
	TextDim = Color3.fromRGB(60, 60, 60),
}

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
local function New(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function Round(obj, radius)
	return New("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, obj)
end

local function Stroke(obj, color, thickness)
	return New("UIStroke", {
		Color = color or Theme.Stroke,
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, obj)
end

local function Tween(obj, props, time)
	local t = TweenService:Create(obj, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function Text(props, parent)
	props.BackgroundTransparency = 1
	props.Font = props.Font or FONT
	props.TextSize = props.TextSize or 16
	props.TextColor3 = props.TextColor3 or Theme.Text
	return New("TextLabel", props, parent)
end

local function IsPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

-- Hace arrastrable "target" usando "handle". onClick se llama si no hubo movimiento.
local function MakeDraggable(handle, target, connections, onClick)
	local dragging, startPos, startFramePos, moved = false, nil, nil, false

	table.insert(connections, handle.InputBegan:Connect(function(input)
		if IsPointer(input) then
			dragging, moved = true, false
			startPos = input.Position
			startFramePos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if not moved and onClick then
						onClick()
					end
				end
			end)
		end
	end))

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startPos
			if delta.Magnitude > 5 then
				moved = true
			end
			if moved then
				target.Position = UDim2.new(
					startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
					startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
				)
			end
		end
	end))
end

local function GetParent()
	local ok, result = pcall(function()
		return (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if ok and result then
		return result
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

---------------------------------------------------------------------
-- Ventana
---------------------------------------------------------------------
function Library:CreateWindow(config)
	config = config or {}
	local Window = { Tabs = {}, _connections = {}, _activeTab = nil }
	local connections = Window._connections

	local accent = config.Accent or Theme.Accent
	local name = config.Name or "Draxi Script"
	local footer = config.Footer or "Join the discord for more updates!"
	local toggleText = config.ToggleText or "DS"
	local toggleKey = config.ToggleKey -- Enum.KeyCode opcional

	-- ScreenGui
	local gui = New("ScreenGui", {
		Name = "DraxiLibrary",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	local okParent = pcall(function()
		gui.Parent = GetParent()
	end)
	if not okParent then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	Window.Gui = gui

	-- Ventana principal
	local WIDTH, HEIGHT, TITLE_H = 480, 320, 36
	local main = New("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(WIDTH, HEIGHT),
		Position = UDim2.new(0.5, -WIDTH / 2, 0.5, -HEIGHT / 2),
		BackgroundColor3 = Theme.Window,
		ClipsDescendants = true,
	}, gui)
	Round(main, 10)
	Stroke(main)

	-- Barra de título
	local titleBar = New("Frame", {
		Name = "TitleFrame",
		Size = UDim2.new(1, 0, 0, TITLE_H),
		BackgroundColor3 = Theme.Title,
		ZIndex = 3,
	}, main)
	Round(titleBar, 10)
	Stroke(titleBar)

	Text({
		Name = "Title",
		Size = UDim2.new(1, -90, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Text = name,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	}, titleBar)

	local function TitleButton(label, xOffset)
		local btn = New("TextButton", {
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.new(1, xOffset, 0.5, -12),
			BackgroundColor3 = Theme.Title,
			AutoButtonColor = false,
			Text = label,
			Font = FONT,
			TextSize = 16,
			TextColor3 = Theme.Text,
			ZIndex = 4,
		}, titleBar)
		Round(btn, 6)
		Stroke(btn, Theme.Stroke, 2)
		btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = Theme.Control }) end)
		btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = Theme.Title }) end)
		return btn
	end

	local closeBtn = TitleButton("X", -32)
	local minBtn = TitleButton("-", -62)

	MakeDraggable(titleBar, main, connections)

	-- Cuerpo
	local body = New("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 1, -TITLE_H),
		Position = UDim2.fromOffset(0, TITLE_H),
		BackgroundTransparency = 1,
	}, main)

	-- Sidebar (pestañas)
	local sidebar = New("ScrollingFrame", {
		Name = "Pages",
		Size = UDim2.new(0, 112, 1, -34),
		Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, body)
	New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)

	-- Contenedor de páginas
	local content = New("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -136, 1, -34),
		Position = UDim2.fromOffset(128, 8),
		BackgroundTransparency = 1,
	}, body)

	-- Footer
	Text({
		Name = "Footer",
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.new(0, 8, 1, -24),
		Text = footer,
		TextSize = 14,
		TextColor3 = Theme.TextDim,
	}, body)

	-- Botón flotante (DS)
	local toggleBtn = New("TextButton", {
		Name = "DS",
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.new(1, -66, 0.15, 0),
		BackgroundColor3 = accent,
		AutoButtonColor = false,
		Text = toggleText,
		Font = FONT,
		TextSize = 22,
		TextColor3 = Theme.Text,
	}, gui)
	Round(toggleBtn, 12)
	Stroke(toggleBtn, Theme.AccentStroke)

	local visible, minimized = true, false

	local function SetVisible(state)
		visible = state
		main.Visible = state
	end

	MakeDraggable(toggleBtn, toggleBtn, connections, function()
		SetVisible(not visible)
	end)

	if toggleKey then
		table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == toggleKey then
				SetVisible(not visible)
			end
		end))
	end

	-- Minimizar / cerrar
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		body.Visible = not minimized
		Tween(main, { Size = UDim2.fromOffset(WIDTH, minimized and TITLE_H or HEIGHT) }, 0.2)
	end)

	closeBtn.MouseButton1Click:Connect(function()
		Window:Destroy()
	end)

	-----------------------------------------------------------------
	-- Notificaciones
	-----------------------------------------------------------------
	local notifHolder = New("Frame", {
		Name = "Notifications",
		Size = UDim2.new(0, 240, 1, -20),
		Position = UDim2.new(1, -250, 0, 10),
		BackgroundTransparency = 1,
	}, gui)
	New("UIListLayout", {
		Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, notifHolder)

	function Window:Notify(opts)
		opts = opts or {}
		local toast = New("Frame", {
			Size = UDim2.new(1, 0, 0, 56),
			BackgroundColor3 = Theme.Window,
			BackgroundTransparency = 1,
		}, notifHolder)
		Round(toast, 8)
		local stroke = Stroke(toast, Theme.Stroke, 2)
		stroke.Transparency = 1

		local title = Text({
			Size = UDim2.new(1, -16, 0, 22),
			Position = UDim2.fromOffset(8, 4),
			Text = opts.Title or "Notificación",
			TextSize = 17,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = 1,
		}, toast)
		local msg = Text({
			Size = UDim2.new(1, -16, 0, 24),
			Position = UDim2.fromOffset(8, 26),
			Text = opts.Content or "",
			TextSize = 14,
			TextColor3 = Theme.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			TextTransparency = 1,
		}, toast)

		Tween(toast, { BackgroundTransparency = 0 }, 0.25)
		Tween(stroke, { Transparency = 0 }, 0.25)
		Tween(title, { TextTransparency = 0 }, 0.25)
		Tween(msg, { TextTransparency = 0 }, 0.25)

		task.delay(opts.Duration or 4, function()
			if not toast.Parent then return end
			Tween(toast, { BackgroundTransparency = 1 }, 0.25)
			Tween(stroke, { Transparency = 1 }, 0.25)
			Tween(title, { TextTransparency = 1 }, 0.25)
			Tween(msg, { TextTransparency = 1 }, 0.25)
			task.wait(0.3)
			toast:Destroy()
		end)
	end

	-----------------------------------------------------------------
	-- Pestañas
	-----------------------------------------------------------------
	function Window:CreateTab(tabName, iconId)
		local Tab = {}

		local tabBtn = New("TextButton", {
			Name = tabName,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = Theme.Window,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = #Window.Tabs + 1,
		}, sidebar)
		Round(tabBtn, 8)
		local tabStroke = Stroke(tabBtn, Theme.Stroke, 2)

		local textOffset = 8
		if iconId then
			New("ImageLabel", {
				Size = UDim2.fromOffset(20, 20),
				Position = UDim2.new(0, 8, 0.5, -10),
				BackgroundTransparency = 1,
				Image = typeof(iconId) == "number" and ("rbxassetid://" .. iconId) or iconId,
			}, tabBtn)
			textOffset = 34
		end
		Text({
			Size = UDim2.new(1, -textOffset - 6, 1, 0),
			Position = UDim2.fromOffset(textOffset, 0),
			Text = tabName,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, tabBtn)

		local page = New("ScrollingFrame", {
			Name = tabName,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.Stroke,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
		}, content)
		New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
		New("UIPadding", {
			PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
			PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 8),
		}, page)

		local function Select()
			for _, t in ipairs(Window.Tabs) do
				t._page.Visible = false
				Tween(t._btn, { BackgroundColor3 = Theme.Window }, 0.15)
				t._stroke.Color = Theme.Stroke
			end
			page.Visible = true
			Tween(tabBtn, { BackgroundColor3 = accent }, 0.15)
			tabStroke.Color = Theme.AccentStroke
			Window._activeTab = Tab
		end

		tabBtn.MouseButton1Click:Connect(Select)
		Tab._page, Tab._btn, Tab._stroke = page, tabBtn, tabStroke
		table.insert(Window.Tabs, Tab)
		if #Window.Tabs == 1 then
			Select()
		end

		-- Fila base para elementos
		local order = 0
		local function Row(height)
			order += 1
			local row = New("Frame", {
				Size = UDim2.new(1, 0, 0, height or 36),
				BackgroundColor3 = Theme.Element,
				LayoutOrder = order,
				ClipsDescendants = true,
			}, page)
			Round(row, 8)
			Stroke(row)
			return row
		end

		local function RowLabel(row, txt)
			return Text({
				Size = UDim2.new(1, -110, 0, 36),
				Position = UDim2.fromOffset(10, 0),
				Text = txt,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, row)
		end

		local function SmallButton(row, label, color, strokeColor)
			local b = New("TextButton", {
				Size = UDim2.fromOffset(64, 26),
				Position = UDim2.new(1, -74, 0, 5),
				BackgroundColor3 = color or Theme.Control,
				AutoButtonColor = false,
				Text = label,
				Font = FONT,
				TextSize = 15,
				TextColor3 = Theme.Text,
			}, row)
			Round(b, 6)
			local s = Stroke(b, strokeColor or Theme.ControlStroke, 2)
			return b, s
		end

		-- Botón
		function Tab:CreateButton(opts)
			local row = Row(36)
			RowLabel(row, opts.Name or "Button")
			local btn = SmallButton(row, opts.ButtonText or "CLICK")
			btn.MouseButton1Click:Connect(function()
				Tween(btn, { BackgroundColor3 = accent }, 0.08)
				task.delay(0.12, function() Tween(btn, { BackgroundColor3 = Theme.Control }, 0.15) end)
				if opts.Callback then
					task.spawn(opts.Callback)
				end
			end)
			return { SetName = function(_, n) row:FindFirstChildOfClass("TextLabel").Text = n end }
		end

		-- Toggle
		function Tab:CreateToggle(opts)
			local row = Row(36)
			RowLabel(row, opts.Name or "Toggle")
			local state = opts.Default == true
			local btn, btnStroke = SmallButton(row, "", Theme.Off, Color3.fromRGB(112, 4, 21))

			local Toggle = {}
			local function Render()
				btn.Text = state and "ON" or "OFF"
				Tween(btn, { BackgroundColor3 = state and Theme.On or Theme.Off })
				btnStroke.Color = state and Color3.fromRGB(12, 92, 5) or Color3.fromRGB(112, 4, 21)
			end
			function Toggle:Set(v, silent)
				state = v and true or false
				Render()
				if not silent and opts.Callback then
					task.spawn(opts.Callback, state)
				end
			end
			function Toggle:Get() return state end

			btn.MouseButton1Click:Connect(function() Toggle:Set(not state) end)
			Render()
			if state and opts.Callback then
				task.spawn(opts.Callback, state)
			end
			return Toggle
		end

		-- Label
		function Tab:CreateLabel(txt)
			order += 1
			local row = New("Frame", {
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = Theme.Label,
				LayoutOrder = order,
			}, page)
			Round(row, 8)
			Stroke(row, Color3.fromRGB(92, 92, 92))
			local lbl = Text({
				Size = UDim2.new(1, -16, 1, 0),
				Position = UDim2.fromOffset(8, 0),
				Text = txt or "",
				TextSize = 15,
				TextColor3 = Theme.TextDim,
				TextWrapped = true,
			}, row)
			return { Set = function(_, t) lbl.Text = t end }
		end

		-- Slider
		function Tab:CreateSlider(opts)
			local min, max = opts.Min or 0, opts.Max or 100
			local inc = opts.Increment or 1
			local value = math.clamp(opts.Default or min, min, max)
			local row = Row(54)

			Text({
				Size = UDim2.new(1, -90, 0, 28),
				Position = UDim2.fromOffset(10, 2),
				Text = opts.Name or "Slider",
				TextXAlignment = Enum.TextXAlignment.Left,
			}, row)
			local valLabel = Text({
				Size = UDim2.fromOffset(70, 28),
				Position = UDim2.new(1, -80, 0, 2),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextSize = 15,
			}, row)

			local bar = New("Frame", {
				Size = UDim2.new(1, -20, 0, 8),
				Position = UDim2.new(0, 10, 0, 36),
				BackgroundColor3 = Theme.Stroke,
			}, row)
			Round(bar, 4)
			local fill = New("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = accent }, bar)
			Round(fill, 4)

			local Slider = {}
			function Slider:Set(v, silent)
				v = math.clamp(math.floor(v / inc + 0.5) * inc, min, max)
				value = v
				valLabel.Text = tostring(math.floor(v * 1000 + 0.5) / 1000)
				fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
				if not silent and opts.Callback then
					task.spawn(opts.Callback, v)
				end
			end
			function Slider:Get() return value end

			local dragging = false
			local function Update(x)
				local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				Slider:Set(min + (max - min) * rel)
			end
			bar.InputBegan:Connect(function(input)
				if IsPointer(input) then
					dragging = true
					Update(input.Position.X)
				end
			end)
			table.insert(connections, UserInputService.InputEnded:Connect(function(input)
				if IsPointer(input) then dragging = false end
			end))
			table.insert(connections, UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch) then
					Update(input.Position.X)
				end
			end))

			Slider:Set(value, true)
			return Slider
		end

		-- Input (TextBox)
		function Tab:CreateInput(opts)
			local row = Row(36)
			RowLabel(row, opts.Name or "Input")
			local box = New("TextBox", {
				Size = UDim2.fromOffset(96, 26),
				Position = UDim2.new(1, -106, 0, 5),
				BackgroundColor3 = Theme.Control,
				Text = opts.Default or "",
				PlaceholderText = opts.Placeholder or "...",
				ClearTextOnFocus = false,
				Font = FONT,
				TextSize = 14,
				TextColor3 = Theme.Text,
				PlaceholderColor3 = Theme.TextDim,
			}, row)
			Round(box, 6)
			Stroke(box, Theme.ControlStroke, 2)
			box.FocusLost:Connect(function(enter)
				if opts.Callback then
					task.spawn(opts.Callback, box.Text, enter)
				end
			end)
			return {
				Set = function(_, t) box.Text = t end,
				Get = function() return box.Text end,
			}
		end

		-- Dropdown
		function Tab:CreateDropdown(opts)
			local options = opts.Options or {}
			local selected = opts.Default
			local open = false
			local row = Row(36)

			RowLabel(row, opts.Name or "Dropdown")
			local head = SmallButton(row, "", Theme.Control)
			head.Size = UDim2.fromOffset(96, 26)
			head.Position = UDim2.new(1, -106, 0, 5)
			head.TextTruncate = Enum.TextTruncate.AtEnd

			local list = New("Frame", {
				Position = UDim2.fromOffset(8, 40),
				Size = UDim2.new(1, -16, 0, 0),
				BackgroundTransparency = 1,
			}, row)
			New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)

			local Dropdown = {}
			local function Render()
				head.Text = selected and tostring(selected) or "Elegir"
			end
			function Dropdown:Set(v, silent)
				selected = v
				Render()
				if not silent and opts.Callback then
					task.spawn(opts.Callback, v)
				end
			end
			function Dropdown:Get() return selected end

			local function Toggle(state)
				open = state
				local h = 36 + (state and (#options * 28 + 6) or 0)
				Tween(row, { Size = UDim2.new(1, 0, 0, h) }, 0.2)
			end

			function Dropdown:Refresh(newOptions)
				options = newOptions
				for _, c in ipairs(list:GetChildren()) do
					if c:IsA("TextButton") then c:Destroy() end
				end
				for i, opt in ipairs(options) do
					local b = New("TextButton", {
						Size = UDim2.new(1, 0, 0, 26),
						BackgroundColor3 = Theme.Control,
						AutoButtonColor = false,
						Text = tostring(opt),
						Font = FONT,
						TextSize = 14,
						TextColor3 = Theme.Text,
						LayoutOrder = i,
					}, list)
					Round(b, 6)
					b.MouseButton1Click:Connect(function()
						Dropdown:Set(opt)
						Toggle(false)
					end)
				end
				if open then Toggle(true) end
			end

			head.MouseButton1Click:Connect(function() Toggle(not open) end)
			Dropdown:Refresh(options)
			Render()
			return Dropdown
		end

		return Tab
	end

	-----------------------------------------------------------------
	-- Script Hub (2ndPage) ya creada: DevEx, Cobalt e InfiniteYield
	-----------------------------------------------------------------
	local HUB_SCRIPTS = {
		{ Name = "DevEx", Url = "https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua" },
		{ Name = "Cobalt", Url = "https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau" },
		{ Name = "InfiniteYield", Url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source" },
	}

	function Window:LoadRemote(scriptName, url)
		Window:Notify({ Title = scriptName, Content = "Cargando...", Duration = 2 })
		task.spawn(function()
			local ok, err = pcall(function()
				local source = game:HttpGet(url)
				local fn = assert(loadstring(source))
				fn()
			end)
			if ok then
				Window:Notify({ Title = scriptName, Content = "Cargado correctamente", Duration = 3 })
			else
				warn("[DraxiLib] Error cargando " .. scriptName .. ": " .. tostring(err))
				Window:Notify({ Title = scriptName .. " (error)", Content = tostring(err):sub(1, 60), Duration = 5 })
			end
		end)
	end

	function Window:CreateScriptHub()
		local hub = Window:CreateTab("2ndPage")
		for _, s in ipairs(HUB_SCRIPTS) do
			hub:CreateButton({
				Name = s.Name,
				ButtonText = "CLICK",
				Callback = function()
					Window:LoadRemote(s.Name, s.Url)
				end,
			})
		end
		return hub
	end

	-- Se crea automáticamente (después de las pestañas que añadas tú).
	-- Desactívala con CreateWindow({ ScriptHub = false })
	if config.ScriptHub ~= false then
		task.defer(function()
			if gui.Parent then
				Window:CreateScriptHub()
			end
		end)
	end

	function Window:SetVisible(state) SetVisible(state) end

	function Window:Destroy()
		for _, c in ipairs(connections) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(connections)
		gui:Destroy()
	end

	return Window
end

return Library
