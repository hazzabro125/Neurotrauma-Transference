NTTrans = {} -- Neurotrauma Transference
NTTrans.Name="Transference"
NTTrans.Version = "1.0"
NTTrans.VersionNum = 01000301
NTTrans.MinNTVersion = "A1.8.4h2"
NTTrans.MinNTVersionNum = 01080402
NTTrans.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTTrans) end end,1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

	Timer.Wait(function()
        if NTC == nil then
            print("Error loading NT Transference: It appears Neurotrauma isn't loaded!")
            return
        end
        if NTCyb == nil then
            print("Error loading NT Transference: It appears NT Cybernetics isn't loaded!")
            return
        end
        dofile(NTTrans.Path.."/Lua/Scripts/helperfunctions.lua")
		dofile(NTTrans.Path.."/Lua/Scripts/humanupdate.lua")
		dofile(NTTrans.Path.."/Lua/Scripts/items.lua")
    end,1)
end