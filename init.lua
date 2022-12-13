function Load(name)
	local resourceName = GetCurrentResourceName()
	local chunk = LoadResourceFile(resourceName, ('data/%s.lua'):format(name))
	if chunk then
		local err
		chunk, err = load(chunk, ('@@%s/data/%s.lua'):format(resourceName, name), 't')
		if err then
			error(('\n^1 %s'):format(err), 0)
		end
		return chunk()
	end
end

-------------------------------------------------------------------------------
-- Settings
-------------------------------------------------------------------------------
Config = {}
Config.MaxDistance = 2.0 -- It's possible to interact with entities through walls so this should be low
Config.Debug = false -- Enable debug options
Config.Standalone = false -- If you are not using ESX, set this to true, else let it on false

Config.EnableDefaultOptions = true -- Enable default options (Toggling vehicle doors)
Config.DisableInVehicle = false -- Disable the target eye whilst being in a vehicle

-- Key to open the target
Config.OpenKey = 'LMENU' -- Left Alt
Config.OpenControlKey = 19 -- Control for keypress detection also Left Alt for the eye itself, controls are found here https://docs.fivem.net/docs/game-references/controls/
Config.MenuControlKey = 238 -- Control for keypress detection on the context menu, this is the Right Mouse Button, controls are found here https://docs.fivem.net/docs/game-references/controls/

-------------------------------------------------------------------------------
-- Target Configs
-------------------------------------------------------------------------------
Config.CircleZones = {}
Config.BoxZones = {}
Config.PolyZones = {}
Config.TargetBones = {}
Config.TargetEntities = {}
Config.TargetModels = {}
Config.GlobalPedOptions = {}
Config.GlobalVehicleOptions = {}
Config.GlobalObjectOptions = {}
Config.GlobalPlayerOptions = {}
Config.Peds = {}

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------
local function JobCheck() return true end
local function ItemCount() return true end

if not Config.Standalone then
    ESX = nil
    Citizen.CreateThread(function()
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(0)
        end

        while ESX.GetPlayerData().job == nil do
            Citizen.Wait(10)
        end

        ESX.PlayerData = ESX.GetPlayerData()
    end)

    ItemCount = function(item)
        for _, v in pairs(PlayerData.items) do
            if v.name == item then
                return true
            end
        end
        return false
    end

    JobCheck = function(job)
        if type(job) == 'table' then
            job = job[ESX.PlayerData.job.name]
            if job and ESX.PlayerData.job.grade.level >= job then
                return true
            end
        elseif job == 'all' or job == ESX.PlayerData.job.name then
            return true
        end
        return false
    end

    RegisterNetEvent('esx:playerLoaded', function()
        ESX.PlayerData = ESX.GetPlayerData().job
        SpawnPeds()
    end)

    RegisterNetEvent('esx:setJob', function(JobInfo)
        ESX.PlayerData.job = JobInfo
    end)
else
    local firstSpawn = false
    AddEventHandler('playerSpawned', function()
        if not firstSpawn then
            SpawnPeds()
            firstSpawn = true
        end
    end)
end

function CheckOptions(data, entity, distance)
	if distance and data.distance and distance > data.distance then return false end
	if data.job and not JobCheck(data.job) then return false end
	if data.item and not ItemCount(data.item) then return false end
	if data.canInteract and not data.canInteract(entity, distance, data) then return false end
	return true
end