-- Example.lua (subelo a tu repo con este nombre: Auto Execute lo vuelve a cargar con ScriptUrl)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Drac311/lib/refs/heads/main/DraxiLib.lua"))()

local Window = Library:CreateWindow({
	Name = "Draxi Script",
	Footer = "Join the discord for more updates!",
	Discord = "https://discord.gg/TU_INVITACION", -- <- pon aqui tu enlace (se copia al pulsar el pie)
	ToggleText = "DS",
	-- ToggleScale = 0.8,                -- tamano del boton DS (1 = tamano original)
	-- Scale = 1,                        -- tamano de la ventana: 0.75 / 1 / 1.25 (tambien en 2ndPage > Size)
	-- ToggleKey = Enum.KeyCode.RightShift,
	ConfigName = "DraxiScript",          -- los ajustes se guardan por juego
	ScriptUrl = "https://raw.githubusercontent.com/Drac311/lib/refs/heads/main/Example.lua",    -- para "Auto Execute" (URL RAW de ESTE archivo)
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

-- Desplegable: eliges 1 opcion
Main:CreateDropdown({
	Name = "Modo",
	Options = { "Facil", "Normal", "Dificil", "Extremo" },
	Default = "Normal",
	Callback = function(opcion)
		print("Elegido:", opcion)
	end,
})

-- Desplegable multiple: marcas / desmarcas las que quieras (la lista no se cierra al elegir)
Main:CreateMultiDropdown({
	Name = "Armas",
	Options = { "Espada", "Arco", "Escudo", "Pocion", "Hacha" },
	Default = { "Espada" },
	Callback = function(seleccionadas)
		print("Seleccionadas:", table.concat(seleccionadas, ", "))
	end,
})

-- 2ndPage ya viene creada: DevEx, Cobalt, InfiniteYield, Save, Size y Auto Execute.
-- "Save" guarda los ajustes de ESTE juego (cada juego tiene su archivo).
