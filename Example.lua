-- Sube DraxiLib.lua a GitHub y pon aqui la URL RAW real (debe empezar por https://)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/TU_USUARIO/TU_REPO/main/DraxiLib.lua"))()

local Window = Library:CreateWindow({
	Name = "Draxi Script",
	Footer = "Join the discord for more updates!",
	ToggleText = "DS",
	-- ToggleKey = Enum.KeyCode.RightShift, -- opcional
	-- StartVisible = false (por defecto): solo se ve el boton DS
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

-- La 2ndPage (DevEx, Cobalt, InfiniteYield, Save) ya viene creada.
