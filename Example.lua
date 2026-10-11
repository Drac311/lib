-- Ejemplo de uso de DraxiLib
-- Sube DraxiLib.lua a GitHub (raw) y cargalo asi, igual que Rayfield:
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Drac311/lib/refs/heads/main/DraxiLib.lua"))()

local Window = Library:CreateWindow({
	Name = "Draxi Script",
	Footer = "Join the discord for more updates!",
	ToggleText = "DS",
	ToggleKey = Enum.KeyCode.RightShift, -- opcional
	-- StartVisible = false (por defecto): solo se ve el boton DS
})

-- Pestaña Main
local Main = Window:CreateTab("Main")

Main:CreateToggle({
	Name = "TOGGLE",
	Default = false,
	Callback = function(state)
		print("Toggle:", state)
	end,
})

Main:CreateButton({
	Name = "CLICK",
	Callback = function()
		Window:Notify({ Title = "Draxi", Content = "¡Botón presionado!", Duration = 3 })
	end,
})

Main:CreateSlider({
	Name = "WalkSpeed",
	Min = 16, Max = 100, Default = 16, Increment = 1,
	Callback = function(v)
		local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = v end
	end,
})

Main:CreateLabel("This is just the test text my friend :)")

-- La pestaña "2ndPage" (DevEx, Cobalt, InfiniteYield) ya viene creada
-- automaticamente. Para desactivarla: CreateWindow({ ScriptHub = false })

-- Puedes añadir tus propias pestañas extra:
local Extra = Window:CreateTab("Extra")

Extra:CreateInput({
	Name = "Mensaje",
	Placeholder = "Escribe...",
	Callback = function(text, enter)
		print("Input:", text, enter)
	end,
})

Extra:CreateDropdown({
	Name = "Modo",
	Options = { "Fácil", "Normal", "Difícil" },
	Default = "Normal",
	Callback = function(opt)
		print("Elegido:", opt)
	end,
})
