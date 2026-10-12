--[[
    Draxi Brainrot Trading (Auto Buy + Bulk Buy)
    - Todo en la Main Page: unidades (multi), Auto Buy, Bulk Buy (cada 0.2s), compra manual,
      intervalo, unidad extra y ayuda
    Requiere la ultima version de DraxiLib (con CreateMultiDropdown).
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Drac311/lib/refs/heads/main/DraxiLib.lua"))()

-- ============================================================
-- AJUSTES (cambialos aqui si tu juego usa otros nombres)
-- ============================================================
local REMOTE_FOLDER = "Remotes" -- ReplicatedStorage.Remotes
local REMOTE_NAME   = "BuyUnit" -- ReplicatedStorage.Remotes.BuyUnit

-- Bulk Buy: compra esta unidad cada 0.2 segundos mientras el toggle este activado
local BULK_UNIT = "Graipussi Medussi"
local BULK_INTERVAL = 0.2

local UNIDADES = {
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
-- ESTADO
-- ============================================================
local autoBuyActivo = false
local intervaloSeg = 45
local seleccionadas = {}
local unidadExtra = ""
local comprando = false
local ultimaCompra = -math.huge
local remoteCache = nil
local avisoRemote = false
local bulkBuyActivo = false
local bulkToggle = nil
local ultimoFalloRemote = -math.huge

-- ============================================================
-- VENTANA (se crea ANTES de buscar el remote, asi nunca se queda colgada)
-- ============================================================
local Window = Library:CreateWindow({
	Name = "Draxi Auto Buy",
	Footer = "Join the discord for more updates!",
	Discord = "https://discord.gg/TU_INVITACION",
	ToggleText = "AB",
	ToggleScale = 0.8,
	StartVisible = true,
	Scale = 1,
	ConfigName = "AutoBuy",
	-- Para "Auto Execute" (2ndPage): URL RAW de ESTE script (el archivo se llama BrainrotTrading.lua en tu repo)
	ScriptUrl = "https://raw.githubusercontent.com/Drac311/lib/refs/heads/main/BrainrotTrading.lua",
})

local AutoTab = Window:CreateTab("Auto Buy") -- 1a llamada -> MainPage (aqui va todo)

-- Al pulsar "Exterminar Script" (2ndPage) se para la auto compra
Window:OnDestroy(function()
	autoBuyActivo = false
	bulkBuyActivo = false
end)

-- ============================================================
-- REMOTE (busqueda segura, con tiempo limite)
-- ============================================================
local function getRemote()
	if remoteCache and remoteCache.Parent then
		return remoteCache
	end
	if os.clock() - ultimoFalloRemote < 10 then
		return nil -- fallo reciente: no volver a esperar en cada llamada
	end
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild(REMOTE_FOLDER) or rs:WaitForChild(REMOTE_FOLDER, 5)
	local remote = folder and (folder:FindFirstChild(REMOTE_NAME) or folder:WaitForChild(REMOTE_NAME, 5))
	remoteCache = remote
	if not remote then
		ultimoFalloRemote = os.clock()
	end
	return remote
end

-- Soporta RemoteFunction y RemoteEvent
local function comprarUna(unidad)
	local remote = getRemote()
	if not remote then
		error("No existe ReplicatedStorage." .. REMOTE_FOLDER .. "." .. REMOTE_NAME)
	end
	if remote:IsA("RemoteFunction") then
		return remote:InvokeServer(unidad)
	elseif remote:IsA("RemoteEvent") then
		remote:FireServer(unidad)
		return true
	end
	error(REMOTE_NAME .. " no es un RemoteFunction ni un RemoteEvent")
end

-- Lista final: seleccionadas + unidad extra (sin repetidos)
local function listaACComprar()
	local lista, visto = {}, {}
	for _, u in ipairs(seleccionadas) do
		if not visto[u] then
			visto[u] = true
			table.insert(lista, u)
		end
	end
	local extra = unidadExtra:match("^%s*(.-)%s*$")
	if extra ~= "" and not visto[extra] then
		table.insert(lista, extra)
	end
	return lista
end

-- esAuto = true -> se corta si apagas el toggle a mitad del ciclo
local function comprar(lista, esAuto)
	if comprando or #lista == 0 then
		return
	end
	comprando = true
	for _, unidad in ipairs(lista) do
		if esAuto and not autoBuyActivo then
			break
		end
		local ok, err = pcall(comprarUna, unidad)
		if ok then
			print("[AutoBuy] -> " .. unidad)
		else
			warn("[AutoBuy] Error con " .. unidad .. ": " .. tostring(err))
			if not avisoRemote then
				avisoRemote = true
				Window:Notify({
					Title = "Auto Buy (error)",
					Content = "No se pudo comprar. Revisa REMOTE_NAME.",
					Duration = 5,
				})
			end
		end
		task.wait(0.2)
	end
	comprando = false
end

-- ============================================================
-- BUCLE: comprueba cada 0.5s si ya toca comprar
-- (el intervalo del slider se aplica al instante)
-- ============================================================
task.spawn(function()
	while Window.Gui and Window.Gui.Parent do
		if autoBuyActivo and not comprando and (os.clock() - ultimaCompra) >= intervaloSeg then
			ultimaCompra = os.clock()
			comprar(listaACComprar(), true)
		end
		task.wait(0.5)
	end
end)

-- ============================================================
-- BULK BUY: cada 0.2s ejecuta Remotes.BuyUnit:InvokeServer(BULK_UNIT)
-- (cada llamada va en su propio hilo, asi el ritmo no depende de la respuesta del servidor)
-- ============================================================
task.spawn(function()
	local avisoError = false
	while Window.Gui and Window.Gui.Parent do
		if bulkBuyActivo then
			if not getRemote() then
				-- sin remote: se apaga solo para no quedarse reintentando
				bulkBuyActivo = false
				if bulkToggle then bulkToggle:Set(false, true) end
				Window:Notify({ Title = "Bulk Buy", Content = "No existe el remote BuyUnit", Duration = 5 })
			else
				task.spawn(function()
					local ok, err = pcall(comprarUna, BULK_UNIT)
					if not ok and not avisoError then
						avisoError = true -- solo se avisa una vez para no llenar la consola
						warn("[BulkBuy] Error con " .. BULK_UNIT .. ": " .. tostring(err))
					end
				end)
			end
		else
			avisoError = false
		end
		task.wait(BULK_INTERVAL)
	end
end)

-- ============================================================
-- MAIN PAGE: COMPRA
-- ============================================================
AutoTab:CreateMultiDropdown({
	Name = "Unidades",
	Options = UNIDADES,
	Default = {},
	Flag = "UnidadesSeleccionadas",
	Callback = function(lista)
		seleccionadas = lista
	end,
})

AutoTab:CreateToggle({
	Name = "Auto Buy",
	Default = false,
	Flag = "AutoBuyToggle",
	Callback = function(estado)
		autoBuyActivo = estado
		if estado then
			ultimaCompra = -math.huge -- compra nada mas activarlo
			if #listaACComprar() == 0 then
				Window:Notify({
					Title = "Auto Buy",
					Content = "Activado, pero no hay unidades elegidas",
					Duration = 4,
				})
				return
			end
		end
		Window:Notify({
			Title = "Auto Buy",
			Content = estado and ("Activado (cada " .. intervaloSeg .. "s)") or "Desactivado",
			Duration = 3,
		})
	end,
})

bulkToggle = AutoTab:CreateToggle({
	Name = "Bulk Buy",
	Default = false,
	Flag = false, -- no se guarda: asi nunca arranca solo al entrar
	Callback = function(estado)
		bulkBuyActivo = estado
		Window:Notify({
			Title = "Bulk Buy",
			Content = estado and ("Activado: " .. BULK_UNIT .. " cada " .. BULK_INTERVAL .. "s") or "Desactivado",
			Duration = 3,
		})
	end,
})

AutoTab:CreateButton({
	Name = "Comprar ahora",
	Callback = function()
		local lista = listaACComprar()
		if #lista == 0 then
			Window:Notify({ Title = "Auto Buy", Content = "No hay unidades seleccionadas", Duration = 3 })
			return
		end
		task.spawn(function()
			comprar(lista, false)
			Window:Notify({ Title = "Auto Buy", Content = "Compra manual ejecutada", Duration = 3 })
		end)
	end,
})

-- ============================================================
-- AJUSTES (tambien en la Main Page)
-- ============================================================
AutoTab:CreateSlider({
	Name = "Intervalo",
	Min = 5,
	Max = 120,
	Default = 45,
	Increment = 5,
	Suffix = "s",
	Flag = "Intervalo",
	Callback = function(v)
		intervaloSeg = v
	end,
})

AutoTab:CreateInput({
	Name = "Unidad extra",
	Placeholder = "Ej: Meowl",
	Default = "",
	Flag = "UnidadExtra",
	Callback = function(texto)
		unidadExtra = texto or ""
	end,
})

AutoTab:CreateLabel("Save (2ndPage) guarda los ajustes de este juego")

-- ============================================================
Window:Notify({
	Title = "Draxi Auto Buy",
	Content = "Listo. Elige unidades en 'Auto Buy'.",
	Duration = 4,
})
