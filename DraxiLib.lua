--[[
    Draxi UI Library  (estética idéntica al GUI original "Draxi Script")

    Uso (executor, estilo Rayfield):
        local Library = loadstring(game:HttpGet("URL_RAW_DE_ESTE_ARCHIVO"))()

        local Window = Library:CreateWindow({
            Name = "Draxi Script",
            Footer = "Join the discord for more updates!",
            Discord = "https://discord.gg/TU_INVITACION", -- se copia al pulsar el pie de la ventana
            ToggleText = "DS",
            ToggleScale = 0.8,                -- tamaño del boton DS (1 = original)
            ToggleKey = Enum.KeyCode.RightShift, -- opcional
            StartVisible = false,             -- por defecto solo se ve el boton DS
            ScriptHub = true,                 -- 2ndPage: botones de scripts (DevEx / Cobalt / InfiniteYield)
            Scale = 1,                        -- tamaño de la ventana: 0.75 / 1 / 1.25 (tambien en 2ndPage > Size)
            ConfigName = "Default",           -- los ajustes se guardan por juego
            ScriptUrl = "https://.../Script.lua", -- necesario para Auto Execute
        })

        local Tab = Window:CreateTab("Main")  -- la primera llamada usa la MainPage original
        Tab:CreateToggle({ Name, Default, Flag, Callback })
        Tab:CreateButton({ Name, Callback })
        Tab:CreateLabel("texto")
        Tab:CreateSlider({ Name, Min, Max, Default, Increment, Suffix, Flag, Callback })
        Tab:CreateInput({ Name, Placeholder, Default, Flag, Callback })
        Tab:CreateDropdown({ Name, Options, Default, Flag, Callback }) -- lista desplegable, eliges 1
        Tab:CreateMultiDropdown({ Name, Options, Default = {..}, Flag, Callback(lista) }) -- eliges las que quieras
        Window:Notify({ Title, Content, Duration })
        Window:SaveConfig() / Window:LoadConfig()
        Window:SetScale(n) / Window:SetDiscord(link) / Window:SetVisible(bool) / Window:Toggle() / Window:Destroy()

    Los elementos guardan su valor automaticamente al pulsar "Save" (o con Flag propio).
    2ndPage = scripts + Save + Size (tamaño de la GUI) + Auto Execute.
    Archivo de ajustes:  DraxiScript/<ConfigName>/<GameId>.json  (uno por juego)
]]

local Library = {}

---------------------------------------------------------------------
-- Servicios (con cloneref si existe)
---------------------------------------------------------------------
local function Service(name)
	local svc = game:GetService(name)
	if cloneref then
		local ok, clone = pcall(cloneref, svc)
		if ok and clone then
			return clone
		end
	end
	return svc
end

local TweenService = Service("TweenService")
local UserInputService = Service("UserInputService")
local Players = Service("Players")
local CoreGui = Service("CoreGui")
local HttpService = Service("HttpService")
local GuiService = Service("GuiService")

local GUI_ATTR = "DraxiLib_ScriptGui"

---------------------------------------------------------------------
-- Valores EXACTOS del diseño original
---------------------------------------------------------------------
local FONT = Font.new([[rbxasset://fonts/families/FredokaOne.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
local BORDER = Color3.fromRGB(28, 43, 54)
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

local C = {
	Green = Color3.fromRGB(19, 235, 41),
	GreenStroke = Color3.fromRGB(13, 151, 27),
	Window = Color3.fromRGB(103, 103, 103),
	Stroke = Color3.fromRGB(51, 51, 51),
	Title = Color3.fromRGB(72, 72, 72),
	Row = Color3.fromRGB(87, 87, 87),
	TextRow = Color3.fromRGB(121, 121, 121),
	TextRowStroke = Color3.fromRGB(92, 92, 92),
	Btn = Color3.fromRGB(140, 140, 140),
	BtnStroke = Color3.fromRGB(126, 126, 126),
	OnBg = Color3.fromRGB(11, 105, 6),
	OnStroke = Color3.fromRGB(12, 92, 5),
	OffBg = Color3.fromRGB(141, 6, 24),
	OffStroke = Color3.fromRGB(112, 4, 21),
	Dim = Color3.fromRGB(60, 60, 60),
	DSTextShadow = Color3.fromRGB(114, 114, 114),
}

local IMG_SHEEN = "rbxassetid://277536533"
local IMG_CLICK = "rbxassetid://126332480729476"
local IMG_SAVE = "rbxassetid://120454548627513"
local IMG_DISCORD = "rbxassetid://103969442872783"
local IMG_MAINTAB = "rbxassetid://108073516847842"
local IMG_HUBTAB = "rbxassetid://109196027383355"

local HUB_SCRIPTS = {
	{ Name = "DevEx", Url = "https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua" },
	{ Name = "Cobalt", Url = "https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau" },
	{ Name = "InfiniteYield", Url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source" },
}

---------------------------------------------------------------------
-- Helpers de construcción
---------------------------------------------------------------------
local function New(class, props, parent)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function Corner(parent)
	return New("UICorner", nil, parent)
end

local function Stroke(parent, color)
	return New("UIStroke", { Thickness = 3, Color = color }, parent)
end

local function Aspect(parent, ratio, aspectType, dominant)
	local p = { AspectRatio = ratio }
	if aspectType then p.AspectType = aspectType end
	if dominant then p.DominantAxis = dominant end
	return New("UIAspectRatioConstraint", p, parent)
end

local function Label(parent, text, props)
	local p = {
		TextWrapped = true,
		TextSize = 14,
		TextScaled = true,
		BackgroundColor3 = WHITE,
		FontFace = FONT,
		TextColor3 = BLACK,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.85, 0, 0.85, 0),
		BorderColor3 = BORDER,
		Text = text,
		Position = UDim2.new(0.48773, 0, 0.5, 0),
	}
	if props then
		for k, v in pairs(props) do
			p[k] = v
		end
	end
	return New("TextLabel", p, parent)
end

-- Boton cuadrado (ON / OFF / Click / Save)
local function SquareButton(parent, name, bg, strokeColor)
	local b = New("ImageButton", {
		Active = true,
		BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Crop,
		AutoButtonColor = false,
		ImageTransparency = 0.5,
		BackgroundColor3 = bg,
		Selectable = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.30151, 0, 0.95662, 0),
		BorderColor3 = BLACK,
		Name = name,
		Position = UDim2.new(1.20551, 0, 0.49754, 0),
	}, parent)
	Corner(b)
	Aspect(b, 1)
	Stroke(b, strokeColor)
	return b
end

local function RowFrame(parent, name, bg, strokeColor, size, pos)
	local f = New("Frame", {
		BackgroundColor3 = bg,
		Size = size,
		Position = pos,
		BorderColor3 = BORDER,
		Name = name,
	}, parent)
	Corner(f)
	Stroke(f, strokeColor)
	return f
end

-- Fila Toggle original
local function ToggleRow(parent, text)
	local f = RowFrame(parent, "Toggle", C.Row, C.Stroke, UDim2.new(0.77836, 0, 0.18905, 0), UDim2.new(0, 0, 0, 0))
	local on = SquareButton(f, "ON", C.OnBg, C.OnStroke)
	Label(on, "ON")
	Label(f, text)
	local off = SquareButton(f, "OFF", C.OffBg, C.OffStroke)
	off.Visible = false
	Label(off, "OFF", { Size = UDim2.new(1, 0, 1.02525, 0), Position = UDim2.new(0.5, 0, 0.51262, 0) })
	Aspect(f, 3.52923, Enum.AspectType.ScaleWithParentSize)
	return f, on, off
end

-- Fila ClickButton / SaveButton original
local function ClickRow(parent, text, rowName, btnName, icon, iconPos)
	local f = RowFrame(parent, rowName, C.Row, C.Stroke, UDim2.new(0.7671, 0, 0.2067, 0), UDim2.new(0, 0, 0.23159, 0))
	local b = SquareButton(f, btnName, C.Btn, C.BtnStroke)
	local ico = New("ImageLabel", {
		BackgroundColor3 = WHITE,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Image = icon,
		Size = UDim2.new(0.85, 0, 0.85, 0),
		BorderColor3 = BORDER,
		BackgroundTransparency = 1,
		Name = "TextLabel",
		Position = iconPos,
	}, b)
	local lbl = Label(f, text)
	Aspect(f, 3.52923, Enum.AspectType.ScaleWithParentSize)
	return f, b, lbl, ico
end

-- Fila Text original
local function TextRow(parent, text)
	local f = RowFrame(parent, "Text", C.TextRow, C.TextRowStroke, UDim2.new(1.02871, 0, 0.19444, 0), UDim2.new(0, 0, 0.46056, 0))
	local lbl = Label(f, text, { TextColor3 = C.Dim })
	Aspect(f, 4.3562, Enum.AspectType.ScaleWithParentSize)
	return f, lbl
end

-- Contenedor de una pagina (MainPageList / 2ndPageList)
local function PageFrame(parent, name)
	local f = New("Frame", {
		Visible = false,
		ZIndex = 2,
		BackgroundColor3 = WHITE,
		Size = UDim2.new(0.99962, 0, 0.76836, 0),
		Position = UDim2.new(0.05, 0, 0.141, 0),
		BorderColor3 = BORDER,
		Name = name,
		BackgroundTransparency = 1,
	}, parent)
	New("UIListLayout", { Padding = UDim.new(0.05, 0), SortOrder = Enum.SortOrder.LayoutOrder }, f)
	Aspect(f, 0.82337, Enum.AspectType.ScaleWithParentSize, Enum.DominantAxis.Height)
	return f
end

-- Boton de pestaña (MainPage / 2ndPage) en el panel "Pages"
local function TabButton(parent, name, icon, iconSize, iconPos, order)
	local f = New("Frame", {
		BackgroundColor3 = C.Window,
		Size = UDim2.new(1, 0, 0.15482, 0),
		Position = UDim2.new(-0.01509, 0, 0.08555, 0),
		BorderColor3 = BORDER,
		Name = name,
		LayoutOrder = order,
	}, parent)
	Corner(f)
	Stroke(f, C.Stroke)
	if icon then
		local img = New("ImageLabel", {
			BackgroundColor3 = WHITE,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = icon,
			Size = iconSize,
			BorderColor3 = BORDER,
			BackgroundTransparency = 1,
			Name = "TextLabel",
			Position = iconPos,
		}, f)
		Aspect(img, 0.98185, Enum.AspectType.ScaleWithParentSize, Enum.DominantAxis.Height)
	end
	local hit = New("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		ZIndex = 3,
		Name = "Hit",
	}, f)
	return f, hit
end

local function Tween(obj, props, time)
	local t = TweenService:Create(obj, TweenInfo.new(time or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function IsPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

---------------------------------------------------------------------
-- Executor helpers
---------------------------------------------------------------------
local function GetContainers()
	local list = {}
	if gethui then
		local ok, r = pcall(gethui)
		if ok and r then table.insert(list, r) end
	end
	table.insert(list, CoreGui)
	local lp = Players.LocalPlayer
	if lp then
		local pg = lp:FindFirstChildOfClass("PlayerGui")
		if pg then table.insert(list, pg) end
	end
	return list
end

local function CleanupOld()
	for _, container in ipairs(GetContainers()) do
		pcall(function()
			for _, child in ipairs(container:GetChildren()) do
				if child:GetAttribute(GUI_ATTR) then
					child:Destroy()
				end
			end
		end)
	end
end

local function Mount(gui)
	if syn and syn.protect_gui then
		pcall(syn.protect_gui, gui)
	end
	for _, container in ipairs(GetContainers()) do
		local ok = pcall(function()
			gui.Parent = container
		end)
		if ok and gui.Parent then
			return
		end
	end
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function HttpGet(url)
	local ok, res = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(res) == "string" and #res > 0 then
		return res
	end
	local req = (syn and syn.request) or request or http_request or (http and http.request)
	if req then
		local r = req({ Url = url, Method = "GET" })
		if r and r.Body and #r.Body > 0 then
			return r.Body
		end
	end
	error("No se pudo descargar: " .. url)
end

Library.HttpGet = HttpGet

local function CopyText(text)
	local fn = setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
	if fn then
		return (pcall(fn, text))
	end
	return false
end

---------------------------------------------------------------------
-- Ventana
---------------------------------------------------------------------
function Library:CreateWindow(config)
	config = config or {}
	local Window = { Tabs = {}, Flags = {}, _conns = {}, _saved = {} }
	local conns = Window._conns

	local titleText = config.Name or "Draxi Script"
	local footerText = config.Footer or "Join the discord for more updates!"
	local dsText = config.ToggleText or "DS"
	local dsScale = config.ToggleScale or 0.8

	local visible = config.StartVisible == true
	local minimized = false
	local active = nil

	CleanupOld()

	-- ScreenGui -------------------------------------------------------
	local gui = New("ScreenGui", {
		Name = "ScriptGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	gui:SetAttribute(GUI_ATTR, true)
	Window.Gui = gui

	-- DraxiScript (raiz) ----------------------------------------------
	local root = New("Frame", {
		BackgroundColor3 = WHITE,
		Size = UDim2.new(0.1, 0, 0.1, 0),
		Position = UDim2.new(0.9, 0, 0.148, 0),
		BorderColor3 = BORDER,
		Name = "DraxiScript",
		BackgroundTransparency = 1,
	}, gui)

	-- Boton DS
	local DS_REST = UDim2.new(0.61594, 0, 0.48039, 0)
	local DS_PRESSED = UDim2.new(0.61594 + 0.02006 * dsScale, 0, 0.48039 + 0.02961 * dsScale, 0)
	local DS_SIZE = UDim2.new(0.35678 * dsScale, 0, 0.59703 * dsScale, 0)

	local ds = New("ImageButton", {
		Active = true,
		BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Crop,
		AutoButtonColor = false,
		ImageTransparency = 0.5,
		BackgroundColor3 = C.Green,
		Selectable = false,
		ZIndex = 3,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Image = IMG_SHEEN,
		Size = DS_SIZE,
		BorderColor3 = BLACK,
		Name = "DS",
		Position = DS_REST,
	}, root)
	Corner(ds)
	Aspect(ds, 1)
	Label(ds, dsText, { Position = UDim2.new(0.5, 0, 0.5, 0) })
	Label(ds, dsText, {
		ZIndex = 2,
		TextColor3 = C.DSTextShadow,
		Position = UDim2.new(0.53, 0, 0.53, 0),
	})
	Stroke(ds, C.GreenStroke)

	-- Scaler: contenedor invisible con UIScale. Escala Gui + Pages juntos,
	-- con el punto fijo cerca del boton DS. A escala 1 es identico al original.
	local PIVOT = Vector2.new(-2.9, 0.944)
	local scaler = New("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(PIVOT.X, 0, PIVOT.Y, 0),
		AnchorPoint = PIVOT,
		ZIndex = 2,
		Name = "Scaler",
	}, root)
	local uiScale = New("UIScale", { Scale = math.clamp(config.Scale or 1, 0.5, 2) }, scaler)

	function Window:SetScale(n)
		uiScale.Scale = math.clamp(tonumber(n) or 1, 0.5, 2)
	end
	function Window:GetScale()
		return uiScale.Scale
	end

	-- Gui (ventana principal)
	local guiF = New("Frame", {
		ZIndex = 2,
		BackgroundColor3 = C.Window,
		Size = UDim2.new(2.27359, 0, 5.14316, 0),
		Position = UDim2.new(-5.139, 0, 0.944, 0),
		BorderColor3 = BORDER,
		Name = "Gui",
		Visible = visible,
	}, scaler)
	Aspect(guiF, 0.74021, nil, Enum.DominantAxis.Height)
	Corner(guiF)
	local guiStroke = Stroke(guiF, C.Stroke)

	-- TitleFrame
	local titleF = New("Frame", {
		BackgroundColor3 = C.Title,
		Size = UDim2.new(1.17643, 0, 0.21436, 0),
		Position = UDim2.new(-0.04192, 0, -0.11234, 0),
		BorderColor3 = BORDER,
		Name = "TitleFrame",
	}, guiF)
	local titleLabel = Label(titleF, titleText, {
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0.54519, 0, 0.85, 0),
		Name = "Title",
		Position = UDim2.new(0.30939, 0, 0.4996, 0),
	})
	Aspect(titleF, 3.74)
	Corner(titleF)
	Stroke(titleF, C.Stroke)

	local function TitleButton(name, pos, text, textPos)
		local b = New("ImageButton", {
			Active = true,
			BorderSizePixel = 0,
			ScaleType = Enum.ScaleType.Crop,
			AutoButtonColor = false,
			ImageTransparency = 0.5,
			BackgroundColor3 = C.Title,
			Selectable = false,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = IMG_SHEEN,
			Size = UDim2.new(0.11846, 0, 0.55826, 0),
			BorderColor3 = BLACK,
			Name = name,
			Position = pos,
		}, titleF)
		Corner(b)
		Aspect(b, 1)
		Stroke(b, C.Stroke)
		Label(b, text, { Position = textPos })
		return b
	end
	local closeBtn = TitleButton("close", UDim2.new(0.9018, 0, 0.31274, 0), "X", UDim2.new(0.5, 0, 0.5, 0))
	local minBtn = TitleButton("minimize", UDim2.new(0.74943, 0, 0.31281, 0), "-", UDim2.new(0.5, 0, 0.4133, 0))

	-- Footer
	local footerLabel = Label(guiF, footerText, {
		TextColor3 = C.Dim,
		Size = UDim2.new(0.85, 0, 0.07129, 0),
		Position = UDim2.new(0.545, 0, 0.945, 0),
	})
	Aspect(footerLabel, 8.82558, Enum.AspectType.ScaleWithParentSize)
	New("UITextSizeConstraint", { MaxTextSize = 21 }, footerLabel)

	local discordIcon = New("ImageLabel", {
		BackgroundColor3 = WHITE,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Image = IMG_DISCORD,
		Size = UDim2.new(0.09343, 0, 0.07043, 0),
		BorderColor3 = BORDER,
		BackgroundTransparency = 1,
		Name = "TextLabel",
		Position = UDim2.new(0.05864, 0, 0.94484, 0),
	}, guiF)
	Aspect(discordIcon, 0.98185, Enum.AspectType.ScaleWithParentSize, Enum.DominantAxis.Height)

	-- zona clicable del pie: copia el enlace de Discord
	local discordHit = New("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.95, 0, 0.085, 0),
		Position = UDim2.new(0.5, 0, 0.945, 0),
		ZIndex = 3,
		Name = "DiscordHit",
	}, guiF)

	-- Pages (panel de pestañas)
	local pagesF = New("Frame", {
		BackgroundColor3 = C.Window,
		Size = UDim2.new(0.42262, 0, 4.5863, 0),
		Position = UDim2.new(-5.5663, 0, 1.46503, 0),
		BorderColor3 = BORDER,
		Name = "Pages",
		BackgroundTransparency = 1,
		Visible = visible,
	}, scaler)
	New("UIListLayout", {
		Padding = UDim.new(0.011, 0),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, pagesF)

	-- DS_Shadow
	local shadow = New("Frame", {
		BorderSizePixel = 0,
		BackgroundColor3 = C.GreenStroke,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = DS_SIZE,
		Position = DS_PRESSED,
		BorderColor3 = BLACK,
		Name = "DS_Shadow",
	}, root)
	Corner(shadow)
	Aspect(shadow, 1)
	Stroke(shadow, C.GreenStroke)

	if visible then
		ds.Position = DS_PRESSED
	end

	-----------------------------------------------------------------
	-- Notificaciones
	-----------------------------------------------------------------
	local notifHolder = New("Frame", {
		Name = "Notifications",
		Size = UDim2.new(0, 260, 1, -20),
		Position = UDim2.new(1, -270, 0, 10),
		BackgroundTransparency = 1,
	}, gui)
	New("UIListLayout", {
		Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, notifHolder)

	function Window:Notify(opts)
		opts = opts or {}
		local t = New("Frame", {
			Size = UDim2.new(1, 0, 0, 58),
			BackgroundColor3 = C.Window,
			BorderColor3 = BORDER,
		}, notifHolder)
		Corner(t)
		Stroke(t, C.Stroke)
		Label(t, opts.Title or "Draxi Script", {
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(0.92, 0, 0.4, 0),
			Position = UDim2.new(0.5, 0, 0.28, 0),
		})
		Label(t, opts.Content or "", {
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = C.Dim,
			Size = UDim2.new(0.92, 0, 0.32, 0),
			Position = UDim2.new(0.5, 0, 0.7, 0),
		})
		task.delay(opts.Duration or 4, function()
			if t and t.Parent then
				t:Destroy()
			end
		end)
	end

	-----------------------------------------------------------------
	-- Discord (copiar enlace)
	-----------------------------------------------------------------
	Window.DiscordLink = config.Discord
	function Window:SetDiscord(link)
		Window.DiscordLink = link
	end
	discordHit.MouseButton1Click:Connect(function()
		local link = Window.DiscordLink
		if not link or link == "" then
			Window:Notify({ Title = "Discord", Content = "No hay enlace configurado", Duration = 3 })
		elseif CopyText(link) then
			Window:Notify({ Title = "Discord", Content = "Enlace copiado al portapapeles", Duration = 3 })
		else
			Window:Notify({ Title = "Discord", Content = tostring(link), Duration = 6 })
		end
	end)

	-----------------------------------------------------------------
	-- Configuracion POR JUEGO (Flags + Save) y Auto Execute
	-----------------------------------------------------------------
	local cfgName = tostring(config.ConfigName or "Default"):gsub("[^%w_%-]", "_")
	local gameKey = tostring((game.GameId and game.GameId ~= 0) and game.GameId or game.PlaceId)
	local baseDir = "DraxiScript/" .. cfgName
	local configPath = baseDir .. "/" .. gameKey .. ".json"
	local autoPath = baseDir .. "/_autoexec.json"

	local function EnsureFolders()
		if not (makefolder and isfolder) then return end
		for _, p in ipairs({ "DraxiScript", baseDir }) do
			if not isfolder(p) then
				makefolder(p)
			end
		end
	end

	local function ReadJson(path)
		local ok, data = pcall(function()
			if isfile and readfile and isfile(path) then
				return HttpService:JSONDecode(readfile(path))
			end
		end)
		if ok and type(data) == "table" then
			return data
		end
		return nil
	end

	local function WriteJson(path, data)
		return pcall(function()
			EnsureFolders()
			writefile(path, HttpService:JSONEncode(data))
		end)
	end

	function Window:LoadConfig()
		local data = ReadJson(configPath)
		if data and type(data.Flags) == "table" then
			Window._saved = data.Flags
			for flag, obj in pairs(Window.Flags) do
				if Window._saved[flag] ~= nil then
					obj:Set(Window._saved[flag])
				end
			end
			return true
		end
		return false
	end

	function Window:SaveConfig()
		local flags = {}
		for flag, obj in pairs(Window.Flags) do
			flags[flag] = obj:Get()
		end
		local ok, err = WriteJson(configPath, {
			Meta = { GameId = game.GameId, PlaceId = game.PlaceId, Saved = os.time() },
			Flags = flags,
		})
		if ok then
			Window:Notify({ Title = "Save", Content = "Ajustes guardados para este juego", Duration = 3 })
		else
			Window:Notify({ Title = "Save (error)", Content = "Tu executor no soporta writefile", Duration = 4 })
			warn("[DraxiLib] " .. tostring(err))
		end
	end

	-- ajustes guardados de ESTE juego (se aplican al crear cada elemento)
	do
		local d = ReadJson(configPath)
		if d and type(d.Flags) == "table" then
			Window._saved = d.Flags
		end
	end

	-- registra un Flag y devuelve el valor guardado (si existe)
	local function Bind(flag, obj)
		if flag then
			Window.Flags[flag] = obj
			return Window._saved[flag]
		end
		return nil
	end

	-- Flag automatico (Tab/Nombre) para que Save guarde TODO sin configurar nada
	local function FlagOf(tab, o)
		if o.Flag == false then
			return nil
		end
		if o.Flag then
			return o.Flag
		end
		local base = tostring(tab.Title or tab.Name) .. "/" .. tostring(o.Name or "Element")
		local flag, n = base, 1
		while Window.Flags[flag] do
			n = n + 1
			flag = base .. "#" .. n
		end
		return flag
	end

	-- Auto Execute (por juego) ------------------------------------
	local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
	local AUTOEXEC_DIRS = { "autoexec", "../autoexec", "autoexecute", "Autoexecute", "../autoexecute", "../Autoexecute" }
	local AUTOEXEC_FILE = "DraxiScript_" .. cfgName .. ".lua"

	local function BuildLoader()
		if config.AutoExecuteCode then
			return tostring(config.AutoExecuteCode)
		end
		if config.ScriptUrl then
			return 'loadstring(game:HttpGet("' .. tostring(config.ScriptUrl) .. '"))()'
		end
		return nil
	end

	-- el codigo solo se ejecuta en los juegos que tengan Auto Execute activado
	local function BuildWrapper(ids, loader)
		local list = {}
		for id in pairs(ids) do
			table.insert(list, "[" .. string.format("%q", tostring(id)) .. "]=true")
		end
		return table.concat({
			"local env = (getgenv and getgenv()) or _G",
			"local ids = {" .. table.concat(list, ",") .. "}",
			"if not game:IsLoaded() then game.Loaded:Wait() end",
			"local key = tostring((game.GameId ~= 0) and game.GameId or game.PlaceId)",
			"if ids[key] and env.__DraxiAutoRan ~= game.JobId then",
			"env.__DraxiAutoRan = game.JobId",
			loader,
			"end",
		}, "\n")
	end

	local autoData = ReadJson(autoPath)
	local autoEnabled = (autoData and type(autoData.Ids) == "table" and autoData.Ids[gameKey] == true) or false

	-- devuelve ok, info
	local function ApplyAutoExec(enabled)
		local loader = BuildLoader()
		if enabled and not loader then
			return false, "nosource"
		end
		local data = ReadJson(autoPath) or {}
		data.Ids = data.Ids or {}
		if enabled then
			data.Ids[gameKey] = true
			data.Loader = loader
		else
			data.Ids[gameKey] = nil
		end
		WriteJson(autoPath, data)

		local wrapped = nil
		if next(data.Ids) ~= nil and data.Loader then
			wrapped = BuildWrapper(data.Ids, data.Loader)
		end

		local wrote = false
		for _, dir in ipairs(AUTOEXEC_DIRS) do
			pcall(function()
				if isfolder and isfolder(dir) then
					local path = dir .. "/" .. AUTOEXEC_FILE
					if wrapped then
						writefile(path, wrapped)
						wrote = true
					elseif delfile and isfile and isfile(path) then
						delfile(path)
					end
				end
			end)
		end

		local queued = false
		if enabled and qot and wrapped then
			queued = (pcall(qot, wrapped))
		end
		return true, { wrote = wrote, queued = queued }
	end

	-- al teleportar/reentrar desde el juego, se vuelve a encolar el script
	pcall(function()
		table.insert(conns, Players.LocalPlayer.OnTeleport:Connect(function()
			if autoEnabled and qot then
				local d = ReadJson(autoPath)
				if d and d.Ids and d.Loader then
					pcall(qot, BuildWrapper(d.Ids, d.Loader))
				end
			end
		end))
	end)

	-----------------------------------------------------------------
	-- Scroll por filas (sin cambiar el aspecto de las filas)
	-----------------------------------------------------------------
	local function ApplyScroll(tab)
		local rows, h = tab._rows, tab._heights
		local n = #rows
		if not h or n == 0 then return end
		local page = tab.Page
		local limit = guiF.AbsolutePosition.Y + guiF.AbsoluteSize.Y * 0.91
		local pad = page.AbsoluteSize.Y * 0.05
		local top = page.AbsolutePosition.Y

		local function fitFrom(s)
			local y = top
			local count = 0
			for i = s, n do
				local bottom = y + (h[i] or 0)
				if bottom > limit and count > 0 then
					break
				end
				y = bottom + pad
				count = count + 1
			end
			return count
		end

		local maxOff = 0
		for off = 0, n - 1 do
			if off + fitFrom(off + 1) >= n then
				maxOff = off
				break
			end
			maxOff = off + 1
		end
		tab._maxOff = maxOff
		tab._offset = math.clamp(tab._offset, 0, maxOff)

		local fit = fitFrom(tab._offset + 1)
		for i = 1, n do
			rows[i].Visible = (i > tab._offset) and (i <= tab._offset + fit)
		end
	end

	local function Measure(tab)
		if tab._measuring then
			tab._again = true
			return
		end
		tab._measuring = true
		repeat
			tab._again = false
			for _, r in ipairs(tab._rows) do
				r.Visible = true
			end
			task.wait()
			task.wait()
			local h = {}
			for i, r in ipairs(tab._rows) do
				h[i] = r.AbsoluteSize.Y
			end
			tab._heights = h
			tab._dirty = false
			ApplyScroll(tab)
		until not tab._again
		tab._measuring = false
	end

	local function Ensure(tab)
		if tab and visible and not minimized and active == tab then
			task.spawn(Measure, tab)
		elseif tab then
			tab._dirty = true
		end
	end

	-- lista desplegable abierta (solo una a la vez)
	local openPopup = nil
	local function ClosePopup()
		if openPopup then
			local p = openPopup
			openPopup = nil
			pcall(function()
				p.Frame:Destroy()
				p.Blocker:Destroy()
			end)
		end
	end

	local function RefreshPages()
		for _, t in ipairs(Window.Tabs) do
			t.Page.Visible = (t == active) and not minimized
		end
	end

	local function SelectTab(tab)
		ClosePopup()
		active = tab
		RefreshPages()
		if tab._dirty or not tab._heights then
			Ensure(tab)
		end
	end

	local function Scroll(dir)
		ClosePopup()
		local tab = active
		if not tab or not tab._heights then return end
		tab._offset = math.clamp(tab._offset + dir, 0, tab._maxOff or 0)
		ApplyScroll(tab)
	end

	table.insert(conns, guiF:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		ClosePopup()
		for _, t in ipairs(Window.Tabs) do
			t._dirty = true
		end
		Ensure(active)
	end))

	-- ¿el puntero esta sobre la ventana?
	local function InGui(x, y)
		local inset = Vector2.new(0, 0)
		pcall(function()
			inset = GuiService:GetGuiInset()
		end)
		local p, s = guiF.AbsolutePosition, guiF.AbsoluteSize
		local function inside(px, py)
			return px >= p.X and px <= p.X + s.X and py >= p.Y and py <= p.Y + s.Y
		end
		return inside(x, y) or inside(x, y - inset.Y)
	end

	local uiBusy = false
	local touchInput, touchLastY, touchAcc = nil, 0, 0
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if not visible or minimized then return end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local m = UserInputService:GetMouseLocation()
			if InGui(m.X, m.Y) then
				Scroll(input.Position.Z > 0 and -1 or 1)
			end
		elseif input.UserInputType == Enum.UserInputType.Touch and input == touchInput and not uiBusy then
			touchAcc = touchAcc + (input.Position.Y - touchLastY)
			touchLastY = input.Position.Y
			local step = (active and active._heights and active._heights[1]) or 40
			if math.abs(touchAcc) > step then
				Scroll(touchAcc < 0 and 1 or -1)
				touchAcc = 0
			end
		end
	end))
	table.insert(conns, UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and visible and not minimized
			and InGui(input.Position.X, input.Position.Y) then
			touchInput, touchLastY, touchAcc = input, input.Position.Y, 0
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if input == touchInput then
			touchInput = nil
		end
	end))

	-----------------------------------------------------------------
	-- Arrastre
	-----------------------------------------------------------------
	local function MakeDraggable(handle, targets, onClick)
		local dragging, moved, startPos, starts = false, false, nil, nil
		table.insert(conns, handle.InputBegan:Connect(function(input)
			if IsPointer(input) then
				dragging, moved = true, false
				startPos = input.Position
				starts = {}
				for i, t in ipairs(targets) do
					starts[i] = t.Position
				end
			end
		end))
		table.insert(conns, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - startPos
				if d.Magnitude > 6 then
					moved = true
				end
				if moved then
					for i, t in ipairs(targets) do
						local s = starts[i]
						t.Position = UDim2.new(s.X.Scale, s.X.Offset + d.X, s.Y.Scale, s.Y.Offset + d.Y)
					end
				end
			end
		end))
		table.insert(conns, UserInputService.InputEnded:Connect(function(input)
			if dragging and IsPointer(input) then
				dragging = false
				if not moved and onClick then
					onClick()
				end
			end
		end))
	end

	-----------------------------------------------------------------
	-- Visibilidad / DS / minimizar / cerrar
	-----------------------------------------------------------------
	local function SetVisible(state)
		visible = state and true or false
		guiF.Visible = visible
		if not visible then
			ClosePopup()
		end
		pagesF.Visible = visible and not minimized
		Tween(ds, { Position = visible and DS_PRESSED or DS_REST }, 0.12)
		if visible then
			Ensure(active)
		end
	end

	local function SetMinimized(state)
		minimized = state and true or false
		if minimized then
			ClosePopup()
		end
		guiF.BackgroundTransparency = minimized and 1 or 0
		guiStroke.Enabled = not minimized
		footerLabel.Visible = not minimized
		discordIcon.Visible = not minimized
		pagesF.Visible = visible and not minimized
		RefreshPages()
		if not minimized then
			Ensure(active)
		end
	end

	-- el boton DS es el toggle de la GUI principal
	MakeDraggable(ds, { root }, function()
		SetVisible(not visible)
	end)
	MakeDraggable(titleF, { scaler })

	minBtn.MouseButton1Click:Connect(function()
		SetMinimized(not minimized)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		SetVisible(false)
	end)

	if config.ToggleKey then
		table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == config.ToggleKey then
				SetVisible(not visible)
			end
		end))
	end

	-----------------------------------------------------------------
	-- Tabs y elementos
	-----------------------------------------------------------------
	local TabMethods = {}
	TabMethods.__index = TabMethods

	local function Register(tab, row)
		tab._order = tab._order + 1
		row.LayoutOrder = tab._order
		table.insert(tab._rows, row)
		tab._dirty = true
		Ensure(tab)
	end

	local function Overlay(row, fn)
		local o = New("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			ZIndex = 3,
			Name = "Hit",
		}, row)
		o.MouseButton1Click:Connect(fn)
		return o
	end

	-- Boton
	function TabMethods:CreateButton(o)
		o = o or {}
		local f, b, lbl, ico = ClickRow(self.Page, o.Name or "Button", "ClickButton", "Click", IMG_CLICK, UDim2.new(0.5645, 0, 0.48465, 0))
		local function Fire()
			Tween(ico, { Size = UDim2.new(0.7, 0, 0.7, 0) }, 0.07)
			task.delay(0.09, function()
				Tween(ico, { Size = UDim2.new(0.85, 0, 0.85, 0) }, 0.1)
			end)
			if o.Callback then
				task.spawn(o.Callback)
			end
		end
		b.MouseButton1Click:Connect(Fire)
		Overlay(f, Fire)
		Register(self, f)
		return {
			Fire = Fire,
			SetName = function(_, n) lbl.Text = n end,
		}
	end

	-- Toggle
	function TabMethods:CreateToggle(o)
		o = o or {}
		local f, on, off = ToggleRow(self.Page, o.Name or "Toggle")
		local state = o.Default == true
		local T = {}
		local function Render()
			on.Visible = state
			off.Visible = not state
		end
		function T:Set(v, silent)
			state = v and true or false
			Render()
			if not silent and o.Callback then
				task.spawn(o.Callback, state)
			end
		end
		function T:Get() return state end
		on.MouseButton1Click:Connect(function() T:Set(false) end)
		off.MouseButton1Click:Connect(function() T:Set(true) end)
		Overlay(f, function() T:Set(not state) end)
		Render()
		Register(self, f)
		local saved = Bind(FlagOf(self, o), T)
		if saved ~= nil then
			T:Set(saved)
		elseif state and o.Callback then
			task.spawn(o.Callback, state)
		end
		return T
	end

	-- Label (fila Text original)
	function TabMethods:CreateLabel(text)
		local f, lbl = TextRow(self.Page, text or "")
		Register(self, f)
		return { Set = function(_, t) lbl.Text = t end }
	end

	-- Slider (misma paleta que el resto)
	function TabMethods:CreateSlider(o)
		o = o or {}
		local min, max = o.Min or 0, o.Max or 100
		local inc = o.Increment or 1
		local value = math.clamp(o.Default or min, min, max)
		local f = RowFrame(self.Page, "Slider", C.Row, C.Stroke, UDim2.new(1.02871, 0, 0.19444, 0), UDim2.new(0, 0, 0.46056, 0))
		Label(f, o.Name or "Slider", {
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(0.55, 0, 0.42, 0),
			Position = UDim2.new(0.32, 0, 0.3, 0),
		})
		local valLabel = Label(f, "", {
			TextXAlignment = Enum.TextXAlignment.Right,
			Size = UDim2.new(0.3, 0, 0.42, 0),
			Position = UDim2.new(0.81, 0, 0.3, 0),
		})
		local bar = New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			BackgroundColor3 = C.Stroke,
			Size = UDim2.new(0.92, 0, 0.16, 0),
			Position = UDim2.new(0.04, 0, 0.68, 0),
			Name = "Bar",
		}, f)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
		local fill = New("Frame", {
			BorderSizePixel = 0,
			BackgroundColor3 = C.Green,
			Size = UDim2.new(0, 0, 1, 0),
			Name = "Fill",
		}, bar)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
		Aspect(f, 4.3562, Enum.AspectType.ScaleWithParentSize)

		local S = {}
		function S:Set(v, silent)
			v = math.clamp(math.floor(v / inc + 0.5) * inc, min, max)
			value = v
			valLabel.Text = tostring(math.floor(v * 100 + 0.5) / 100) .. (o.Suffix or "")
			fill.Size = UDim2.new((max > min) and ((v - min) / (max - min)) or 0, 0, 1, 0)
			if not silent and o.Callback then
				task.spawn(o.Callback, v)
			end
		end
		function S:Get() return value end

		local dragging = false
		local function Update(x)
			local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			S:Set(min + (max - min) * rel)
		end
		bar.InputBegan:Connect(function(input)
			if IsPointer(input) then
				dragging = true
				uiBusy = true
				Update(input.Position.X)
			end
		end)
		table.insert(conns, UserInputService.InputEnded:Connect(function(input)
			if IsPointer(input) then
				dragging = false
				uiBusy = false
			end
		end))
		table.insert(conns, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				Update(input.Position.X)
			end
		end))

		S:Set(value, true)
		Register(self, f)
		local saved = Bind(FlagOf(self, o), S)
		if saved ~= nil then
			S:Set(saved)
		end
		return S
	end

	-- Input
	function TabMethods:CreateInput(o)
		o = o or {}
		local f = RowFrame(self.Page, "Input", C.Row, C.Stroke, UDim2.new(1.02871, 0, 0.19444, 0), UDim2.new(0, 0, 0.46056, 0))
		Label(f, o.Name or "Input", {
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(0.4, 0, 0.7, 0),
			Position = UDim2.new(0.26, 0, 0.5, 0),
		})
		local boxFrame = New("Frame", {
			BackgroundColor3 = C.Btn,
			Size = UDim2.new(0.5, 0, 0.62, 0),
			Position = UDim2.new(0.72, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BorderColor3 = BORDER,
		}, f)
		Corner(boxFrame)
		Stroke(boxFrame, C.BtnStroke)
		local box = New("TextBox", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.9, 0, 0.8, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = o.Default or "",
			PlaceholderText = o.Placeholder or "...",
			PlaceholderColor3 = C.Dim,
			ClearTextOnFocus = false,
			FontFace = FONT,
			TextColor3 = BLACK,
			TextScaled = true,
			TextWrapped = true,
		}, boxFrame)
		Aspect(f, 4.3562, Enum.AspectType.ScaleWithParentSize)

		local I = {}
		function I:Set(t, silent)
			box.Text = tostring(t)
			if not silent and o.Callback then
				task.spawn(o.Callback, box.Text)
			end
		end
		function I:Get() return box.Text end
		box.FocusLost:Connect(function(enter)
			if o.Callback then
				task.spawn(o.Callback, box.Text, enter)
			end
		end)
		Register(self, f)
		local saved = Bind(FlagOf(self, o), I)
		if saved ~= nil then
			I:Set(saved)
		end
		return I
	end

	-- Dropdown: se despliega una lista. Multi = false -> eliges 1 / Multi = true -> eliges las que quieras
	function TabMethods:CreateDropdown(o)
		o = o or {}
		local options = o.Options or {}
		local multi = o.Multi == true
		local nameText = o.Name or "Dropdown"
		local selected = nil -- modo simple
		local chosen = {} -- modo multiple (conjunto)
		do
			local def = o.Default
			if multi then
				if type(def) == "table" then
					for _, v in ipairs(def) do chosen[v] = true end
				elseif def ~= nil then
					chosen[def] = true
				end
			else
				selected = def
			end
		end

		-- una sola barra larga (mide lo mismo que el boton + su boton cuadrado juntos)
		local f = RowFrame(self.Page, "Dropdown", C.Row, C.Stroke, UDim2.new(1.02871, 0, 0.179, 0), UDim2.new(0, 0, 0.23159, 0))
		local lbl = Label(f, "")
		Aspect(f, 4.732, Enum.AspectType.ScaleWithParentSize)
		local D = {}

		local function ChosenList()
			local list = {}
			for _, opt in ipairs(options) do
				if chosen[opt] then
					table.insert(list, opt)
				end
			end
			return list
		end

		local function Render()
			if multi then
				local list = ChosenList()
				local txt
				if #list == 0 then
					txt = "..."
				elseif #list <= 2 then
					local names = {}
					for i, v in ipairs(list) do names[i] = tostring(v) end
					txt = table.concat(names, ", ")
				else
					txt = #list .. " selected"
				end
				lbl.Text = nameText .. ": " .. txt
			else
				lbl.Text = nameText .. ": " .. (selected ~= nil and tostring(selected) or "...")
			end
		end

		function D:Set(v, silent)
			if multi then
				chosen = {}
				if type(v) == "table" then
					for _, x in ipairs(v) do chosen[x] = true end
				elseif v ~= nil then
					chosen[v] = true
				end
				Render()
				if not silent and o.Callback then
					task.spawn(o.Callback, ChosenList())
				end
			else
				selected = v
				Render()
				if not silent and o.Callback then
					task.spawn(o.Callback, selected)
				end
			end
		end
		function D:Get()
			if multi then
				return ChosenList()
			end
			return selected
		end
		function D:Refresh(newOptions)
			options = newOptions or {}
			Render()
		end

		local function Open()
			if openPopup and openPopup.Owner == D then
				ClosePopup()
				return
			end
			ClosePopup()
			local n = #options
			if n == 0 then return end

			-- las medidas en pantalla se convierten a unidades locales (dentro de UIScale)
			local sc = uiScale.Scale
			local gap = 4
			local optH = math.max(f.AbsoluteSize.Y * 0.8 / sc, 24)
			local vis = math.min(n, 5)
			local height = vis * optH + (vis + 1) * gap
			local width = math.max(f.AbsoluteSize.X / sc, 120)
			local relX = (f.AbsolutePosition.X - guiF.AbsolutePosition.X) / sc
			local relY = (f.AbsolutePosition.Y - guiF.AbsolutePosition.Y) / sc
			local x = relX
			local y = relY + f.AbsoluteSize.Y / sc + 4
			if y + height > (guiF.AbsoluteSize.Y / sc) * 0.97 then
				y = relY - height - 4
			end
			if y < 0 then y = 4 end

			local blocker = New("TextButton", {
				Text = "",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.new(3, 0, 3, 0),
				Position = UDim2.new(-1, 0, -1, 0),
				ZIndex = 20,
				Name = "PopupBlocker",
			}, guiF)
			blocker.MouseButton1Click:Connect(ClosePopup)

			local popup = New("Frame", {
				BackgroundColor3 = C.Row,
				Size = UDim2.fromOffset(width, height),
				Position = UDim2.fromOffset(x, y),
				BorderColor3 = BORDER,
				ZIndex = 21,
				Name = "DropdownList",
			}, guiF)
			Corner(popup)
			Stroke(popup, C.Stroke)

			local scroll = New("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -gap * 2, 1, -gap * 2),
				Position = UDim2.fromOffset(gap, gap),
				CanvasSize = UDim2.new(0, 0, 0, n * optH + (n - 1) * gap),
				ScrollBarThickness = (n > 5) and 4 or 0,
				ScrollBarImageColor3 = C.Stroke,
				ZIndex = 22,
			}, popup)
			New("UIListLayout", { Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

			local function IsOn(opt)
				if multi then
					return chosen[opt] == true
				end
				return opt == selected
			end

			for i, opt in ipairs(options) do
				local on = IsOn(opt)
				local ob = New("TextButton", {
					Size = UDim2.new(1, (n > 5) and -8 or 0, 0, optH),
					BackgroundColor3 = on and C.Green or C.TextRow,
					AutoButtonColor = false,
					Text = tostring(opt),
					FontFace = FONT,
					TextScaled = true,
					TextColor3 = BLACK,
					LayoutOrder = i,
					ZIndex = 23,
				}, scroll)
				Corner(ob)
				local st = New("UIStroke", { Thickness = 2, Color = on and C.GreenStroke or C.TextRowStroke }, ob)
				New("UITextSizeConstraint", { MaxTextSize = 22 }, ob)
				ob.MouseButton1Click:Connect(function()
					if multi then
						-- marcar / desmarcar sin cerrar la lista
						if chosen[opt] then
							chosen[opt] = nil
						else
							chosen[opt] = true
						end
						local nowOn = chosen[opt] == true
						ob.BackgroundColor3 = nowOn and C.Green or C.TextRow
						st.Color = nowOn and C.GreenStroke or C.TextRowStroke
						Render()
						if o.Callback then
							task.spawn(o.Callback, ChosenList())
						end
					else
						D:Set(opt)
						ClosePopup()
					end
				end)
			end

			openPopup = { Frame = popup, Blocker = blocker, Owner = D }
		end

		Overlay(f, Open)
		Render()
		Register(self, f)
		local saved = Bind(FlagOf(self, o), D)
		if saved ~= nil then
			D:Set(saved)
		end
		return D
	end

	-- atajo: desplegable de seleccion multiple
	function TabMethods:CreateMultiDropdown(o)
		o = o or {}
		o.Multi = true
		return self:CreateDropdown(o)
	end

	local mainUsed = false
	local tabCounter = 1

	local function MakeTab(btnName, pageName, icon, iconSize, iconPos, order)
		local tab = setmetatable({ Name = btnName, _rows = {}, _order = 0, _offset = 0, _dirty = true }, TabMethods)
		tab.Page = PageFrame(guiF, pageName)
		local f, hit = TabButton(pagesF, btnName, icon, iconSize, iconPos, order)
		tab.Button = f
		hit.MouseButton1Click:Connect(function()
			SelectTab(tab)
		end)
		table.insert(Window.Tabs, tab)
		return tab
	end

	-- MainPage (original)
	Window.Main = MakeTab("MainPage", "MainPageList", IMG_MAINTAB,
		UDim2.new(0.73557, 0, 0.88052, 0), UDim2.new(0.48873, 0, 0.49681, 0), 1)

	function Window:CreateTab(tabName, icon)
		if not mainUsed then
			mainUsed = true
			Window.Main.Title = tostring(tabName or "Main")
			return Window.Main
		end
		tabCounter = tabCounter + 1
		local img = nil
		if icon then
			img = (type(icon) == "number") and ("rbxassetid://" .. icon) or tostring(icon)
		end
		local tab = MakeTab(tostring(tabName or ("Tab" .. tabCounter)), tostring(tabName or "Tab") .. "List", img,
			UDim2.new(0.73557, 0, 0.88052, 0), UDim2.new(0.48873, 0, 0.49681, 0), tabCounter)
		tab.Title = tostring(tabName or ("Tab" .. tabCounter))
		if not img then
			Label(tab.Button, tostring(tabName or "Tab"), { Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0.8, 0, 0.6, 0) })
		end
		return tab
	end

	-- Script Hub (2ndPage original): DevEx, Cobalt, InfiniteYield, Save
	function Window:LoadRemote(scriptName, url)
		Window:Notify({ Title = scriptName, Content = "Cargando...", Duration = 2 })
		task.spawn(function()
			local ok, err = pcall(function()
				local source = HttpGet(url)
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

	do
		local hub = MakeTab("2ndPage", "2ndPageList", IMG_HUBTAB,
			UDim2.new(0.96276, 0, 0.93707, 0), UDim2.new(0.54174, 0, 0.4984, 0), 1000)
		hub.Title = "2ndPage"
		Window.Hub = hub

		if config.ScriptHub ~= false then
			for _, sc in ipairs(HUB_SCRIPTS) do
				hub:CreateButton({
					Name = sc.Name,
					Callback = function()
						Window:LoadRemote(sc.Name, sc.Url)
					end,
				})
			end
		end

		-- Save (original)
		local sf, sb = ClickRow(hub.Page, "Save", "SaveButton", "Save", IMG_SAVE, UDim2.new(0.48558, 0, 0.51622, 0))
		sb.MouseButton1Click:Connect(function() Window:SaveConfig() end)
		Overlay(sf, function() Window:SaveConfig() end)
		Register(hub, sf)

		-- Size: escala de toda la GUI principal (0.75 / original / 1.25)
		local SIZE_NAMES = { "0.75x", "1x (Original)", "1.25x" }
		local SIZE_VALUES = { ["0.75x"] = 0.75, ["1x (Original)"] = 1, ["1.25x"] = 1.25 }
		local cur = uiScale.Scale
		local defaultSize = "1x (Original)"
		if math.abs(cur - 0.75) < 0.01 then defaultSize = "0.75x" end
		if math.abs(cur - 1.25) < 0.01 then defaultSize = "1.25x" end
		hub:CreateDropdown({
			Name = "Size",
			Options = SIZE_NAMES,
			Default = defaultSize,
			Callback = function(opt)
				Window:SetScale(SIZE_VALUES[opt] or 1)
			end,
		})

		-- Auto Execute (por juego)
		local initializing = true
		local autoToggle
		autoToggle = hub:CreateToggle({
			Name = "Auto Execute",
			Default = autoEnabled,
			Flag = false,
			Callback = function(state)
				if initializing then
					if state then ApplyAutoExec(true) end -- reencola al entrar
					return
				end
				local ok, info = ApplyAutoExec(state)
				if not ok then
					autoEnabled = false
					if autoToggle then autoToggle:Set(false, true) end
					Window:Notify({ Title = "Auto Execute", Content = "Falta ScriptUrl en CreateWindow", Duration = 5 })
					return
				end
				autoEnabled = state
				if not state then
					Window:Notify({ Title = "Auto Execute", Content = "Desactivado para este juego", Duration = 3 })
				elseif info.wrote then
					Window:Notify({ Title = "Auto Execute", Content = "ON: se ejecuta al volver a entrar", Duration = 4 })
				elseif info.queued then
					Window:Notify({ Title = "Auto Execute", Content = "ON (solo teleports: sin carpeta autoexec)", Duration = 5 })
				else
					Window:Notify({ Title = "Auto Execute", Content = "Tu executor no soporta auto execute", Duration = 5 })
				end
			end,
		})
		initializing = false
	end

	-- MainPage seleccionada por defecto
	SelectTab(Window.Main)

	-----------------------------------------------------------------
	-- API publica
	-----------------------------------------------------------------
	function Window:SetVisible(state) SetVisible(state) end
	function Window:Toggle() SetVisible(not visible) end
	function Window:SetTitle(t) titleLabel.Text = t end

	function Window:Destroy()
		for _, c in ipairs(conns) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(conns)
		gui:Destroy()
	end

	Mount(gui)
	return Window
end

return Library
