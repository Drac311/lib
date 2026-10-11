-- Sube DraxiLib.lua a GitHub y pon aqui la URL RAW real (debe empezar por https://)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Drac311/lib/refs/heads/main/DraxiLib.lua"))()

local Window = Library:CreateWindow({
	Name = "Draxi Script",
	Footer = "Join the discord for more updates!",
	Discord = "https://discord.gg/TU_INVITACION", -- <- pon aqui tu enlace (se copia al pulsar el pie)
	ToggleText = "DS",
	-- ToggleScale = 0.8,                -- tamano del boton DS (1 = tamano original)
	-- ToggleKey = Enum.KeyCode.RightShift,
	ConfigName = "DraxiScript",          -- los ajustes se guardan por juego
	-- Necesario para "Auto Execute": URL RAW donde tengas alojado ESTE script
	-- ScriptUrl = "https://raw.githubusercontent.com/TU_USUARIO/TU_REPO/main/Script.lua",
})

-- MainPage: mismo contenido que el diseno original
local Main = Window:CreateTab("Main")

Main:CreateToggle({
	Name = "TOGGLE",
	Default = true,
	Callback = function(state)
		print("Toggle:", state)
	end,
})

Main:CreateButton({
	Name = "CLICK",
	Callback = function()
		Window:Notify({ Title = "Draxi Script", Content = "Click!", Duration = 3 })
	end,
})

Main:CreateLabel("This is just the test text my friend :)")

-- Slider (ej: velocidad del jugador)
Main:CreateSlider({
	Name = "WalkSpeed",
	Min = 16, Max = 200, Default = 16, Increment = 1,
	Callback = function(v)
		local char = game.Players.LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = v end
	end,
})

-- Lista desplegable (eliges 1 opcion)
Main:CreateDropdown({
	Name = "Modo",
	Options = { "Facil", "Normal", "Dificil", "Extremo" },
	Default = "Normal",
	Callback = function(opcion)
		print("Elegido:", opcion)
	end,
})

-- Todos los elementos se guardan solos al pulsar "Save" (2ndPage), por juego.
-- La 2ndPage (DevEx, Cobalt, InfiniteYield, Save) y Settings (Auto Execute) ya vienen creadas.
