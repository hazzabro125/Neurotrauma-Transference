NTRT = {} -- Neurotrauma RoboTrauma
NTRT.Name="Robotrauma"
NTRT.Version = "1.0"
NTRT.VersionNum = 01000301
NTRT.MinNTVersion = "A1.8.4h2"
NTRT.MinNTVersionNum = 01080402
NTRT.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTRT) end end,1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

	Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT RoboTrauma: It appears Neurotrauma isn't loaded!")
            return
        end
        if NTCyb == nil then
            print("Error loading NT RoboTrauma: It appears NT Cybernetics isn't loaded!")
            return
        end
		dofile(NTRT.Path.."/Lua/Scripts/humanupdate.lua")
		dofile(NTRT.Path.."/Lua/Scripts/items.lua")
    end,1)
	
end