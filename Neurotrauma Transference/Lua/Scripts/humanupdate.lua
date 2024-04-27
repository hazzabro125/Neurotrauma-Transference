
NTTrans.Afflictions = { -- afflictions that we should not entirely ignore for robots
    givein={},
    t_paralysis={getonly=true},
    sym_unconsciousness={},

    brainremoved={getonly=true},--we need all of these for unconsciousness
    hypoxemia={getonly=true},
    cerebralhypoxia={getonly=true},
    coma={getonly=true},
    t_arterialcut={getonly=true},
    seizure={getonly=true},
    opiateoverdose={getonly=true},

    lockedhands={},

    stun={},
    anesthesia={getonly=true},--needed for stun

    luabotomy={}
}       
NTTrans.LimbAfflictions = {-- same deal
    -- oh wow, this is looking rather empty.
}   
NTTrans.CharStats = {-- dito
    lockleftarm={},
    lockrightarm={},
    lockleftleg={},
    lockrightleg={},
    wheelchaired={},
    speedmultiplier={leaveempty=true}
}
NTTrans.RemovedAfflictions = { -- afflictions that are periodically removed from robots
    "huskinfection",
    "bleeding",
    "bleedingnonstop",
    "nausea",
    "organdamage",
    "psychosis",
    "concussion",
    "bloodloss",

    "cardiacarrest",
    "respiratoryarrest",
    "pneumothorax",
    "tamponade",
    "heartattack",

    "heartremoved",
    "lungremoved",
    "liverremoved",
    "kidneyremoved",

    "cerebralhypoxia",
    "heartdamage",
    "lungdamage",
    "liverdamage",
    "kidneydamage",
    "bonedamage",
    "organdamage",

    "sepsis",
    "immunity",
    "bloodpressure",
    "hypoxemia",
    "hemotransfusionshock",
    "internalbleeding",
    "acidosis",
    "alkalosis",
    "stroke",
    "coma",
	"t_paralysis",
	"ll_fracture",
	"rl_fracture",
	"ra_fracture",
	"la_fracture",
	"h_fracture",
    "n_fracture",
	"t_fracture",
	
	"ll_arterialcut",
	"rl_arterialcut",
	"ra_arterialcut",
	"la_arterialcut",
	"h_arterialcut",
	"t_arterialcut",
	
    -- theres so many things that a robot shouldnt have...
    "analgesia","anesthesia",
    "drunk", -- this one might be fun to not disable, your choice
    "afadrenaline",
    "afadrenaline","afantibiotics","afthiamine",
    "afsaline","afringerssolution","afstreptokinase","afmannitol",
    "afpressuredrug"
}         

-- its better to have it like this than verbosely plastering it all over the place
NTTrans.IsRobot = function(character)
    --return true
    return not character.IsFemale and not character.IsMale
end

local limbtypes = {
    LimbType.Torso,
    LimbType.Head,
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
}

Timer.Wait(function()

    -- lets override this badboy to not give a shit about robots (for most afflictions)
    NT.UpdateHuman = function(character)

        -- pre humanupdate hooks
        for key, val in pairs(NTC.PreHumanUpdateHooks) do
            val(character)
        end

        local TableContains = function(table,identifier)
            return table[identifier] ~= nil
        end

        local charData = {character=character,afflictions={},stats={}}
        local charIsRobot = NTTrans.IsRobot(character)
    
        -- fetch all the current affliction data
        for identifier,data in pairs(NT.Afflictions) do
            if not charIsRobot or TableContains(NTTrans.Afflictions,identifier) then
                local strength = HF.GetAfflictionStrength(character,identifier,data.default or 0)
                charData.afflictions[identifier] = {prev=strength,strength=strength}
            end
        end
        -- fetch and calculate all the current stats
        for identifier,data in pairs(NT.CharStats) do
            if not charIsRobot or TableContains(NTTrans.CharStats,identifier) then
                if data.getter ~= nil and (not charIsRobot or NTTrans.CharStats[identifier].leaveempty == nil) then charData.stats[identifier] = data.getter(charData)
                else charData.stats[identifier] = data.default or 1 end
            end
        end
        -- update non-limb-specific afflictions
        for identifier,data in pairs(NT.Afflictions) do
            if not charIsRobot or (TableContains(NTTrans.Afflictions,identifier) and NTTrans.Afflictions[identifier].getonly == nil) then
                if data.update ~= nil then
                data.update(charData,identifier) end
            end
        end
        
    
        -- update and apply limb specific stuff
        local function FetchLimbData(type)
            
            local keystring = tostring(type).."afflictions"
            charData[keystring] = {}
            for identifier,data in pairs(NT.LimbAfflictions) do
                if not charIsRobot or TableContains(NTTrans.LimbAfflictions,identifier) then
                    local strength = HF.GetAfflictionStrengthLimb(character,type,identifier,data.default or 0)
                    charData[keystring][identifier] = {prev=strength,strength=strength}
                end
            end
        end
        local function UpdateLimb(type)
            local keystring = tostring(type).."afflictions"
            for identifier,data in pairs(NT.LimbAfflictions) do
                if not charIsRobot or (TableContains(NTTrans.LimbAfflictions,identifier) and NTTrans.LimbAfflictions[identifier].getonly == nil) then
                    if data.update ~= nil then
                    data.update(charData,charData[keystring],identifier,type) end
                end
            end
        end
        local function ApplyLimb(type)
            local keystring = tostring(type).."afflictions"
            for identifier,data in pairs(charData[keystring]) do
                local newval = HF.Clamp(
                data.strength,
                NT.LimbAfflictions[identifier].min or 0,
                NT.LimbAfflictions[identifier].max or 100)
                if newval ~= data.prev then
                    if NT.LimbAfflictions[identifier].apply == nil then
                        HF.SetAfflictionLimb(character,identifier,type,newval)
                    else
                        NT.LimbAfflictions[identifier].apply(charData,identifier,type,newval)
                    end
                end
            end
        end
    
        -- stasis completely halts activity in limbs
        if not charData.stats.stasis then
            for type in limbtypes do
                FetchLimbData(type)
            end
            for type in limbtypes do
                UpdateLimb(type)
            end
            for type in limbtypes do
                ApplyLimb(type)
            end
        end
    
        -- non-limb-specific late update (useful for things that use stats that are altered by limb specifics)
        for identifier,data in pairs(NT.Afflictions) do
            if not charIsRobot or TableContains(NTTrans.Afflictions,identifier) then
                if data.lateupdate ~= nil then
                data.lateupdate(charData,identifier) end
            end
        end
    
        -- apply non-limb-specific changes
        for identifier,data in pairs(charData.afflictions) do
            local newval = HF.Clamp(
                data.strength,
                NT.Afflictions[identifier].min or 0,
                NT.Afflictions[identifier].max or 100)
            if newval ~= data.prev then
                if NT.Afflictions[identifier].apply == nil then
                    HF.SetAffliction(character,identifier,newval)
                else
                    NT.Afflictions[identifier].apply(charData,identifier,newval) 
                end
            end
        end
    
        -- compatibility
        NTC.TickCharacter(character)
        -- humanupdate hooks
        for key, val in pairs(NTC.HumanUpdateHooks) do
            val(character)
        end
    
        NTC.CharacterSpeedMultipliers[character] = nil
    end

    NTC.AddHumanUpdateHook(NTTrans.UpdateRobot)
end,1)

function NTTrans.UpdateRobot(character)
    if not NTTrans.IsRobot(character) then return end
    if character.IsPlayer then
    end

if not HF.HasAffliction(character, "ntt_resistance", 1) then
    if character.IsOnPlayerTeam then
        RerollGender(character,character.JobIdentifier)
    else
        HF.SetAffliction(character,"ntt_resistance",100)
        end
    end

    --make fresh robots spawn with cyberlimbs
    if HF.GetAfflictionStrength(character,"robotspawned") < 0.5 then
        character.UpdateTeam()  
        for limbtype in limbtypes do
            NTCyb.CyberifyLimb(character,limbtype)
            NTTrans.CyberifyLimb(character,limbtype)
        end
         
        HF.SetAffliction(character,"robotspawned",100)
    end

    -- remove fleshy afflictions
    for identifier in NTTrans.RemovedAfflictions do
        if HF.GetAfflictionStrength(character,identifier) > 0 then
            HF.SetAffliction(character,identifier,0)
        end
    end
end

Timer.Wait(function()

    -- this is some super cursed shit
    -- remove the registered cybernetics human update hook
    local i = 1
    local removeIndex = -1
    for func in NTC.PreHumanUpdateHooks do
        if func == NTCyb.UpdateHuman then
            removeIndex = i
        end
        i = i + 1
    end
    if removeIndex ~= -1 then table.remove(NTC.PreHumanUpdateHooks,removeIndex) end

    -- register the new and improved one
    NTC.AddPreHumanUpdateHook(NTTrans.UpdateHuman)

end,1000)

function NTTrans.UpdateHuman(character)

    local velocity = 0
    if 
        character ~= nil and 
        character.AnimController ~= nil and 
        character.AnimController.MainLimb ~= nil and 
        character.AnimController.MainLimb.body ~= nil and 
        character.AnimController.MainLimb.body.LinearVelocity ~= nil then
            velocity = character.AnimController.MainLimb.body.LinearVelocity.Length() end

    local isRobot = NTTrans.IsRobot(character)

    local function updateLimb(character,limbtype) 
        if not NTCyb.HF.LimbIsCyber(character,limbtype) then return end
        NTTrans.ConvertDamageTypes(character,limbtype)

        local limb = character.AnimController.GetLimb(limbtype)

        -- cyber stats
        local loosescrews = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_loosescrews",0)
        local damagedelectronics = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_damagedelectronics",0)
        local bentmetal = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_bentmetal",0)
        local materialloss = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_materialloss",0)
    
        -- water damage if unprotected
        if character.PressureProtection <= 1000 then
            -- in water?
            local inwater = false
            if limb~=nil and limb.InWater then inwater=true end
            if inwater then
                -- add damaged electronics
                Timer.Wait(function(limb)
                    if limb ~= nil then
                        local spawnpos = limb.WorldPosition
                        HF.SpawnItemAt("ntcvfx_malfunction",spawnpos) end
                end,math.random(1,500))
                HF.AddAfflictionLimb(character,"ntc_damagedelectronics",limbtype,(2-HF.BoolToNum(isRobot,1))*(1+loosescrews/100)*(1+materialloss/100)*NT.Deltatime)
            end
        end

        -- moving around damages if loose screws high enough
        if loosescrews > 30 and velocity > 1 then
            HF.AddAfflictionLimb(character,"ntc_materialloss",limbtype,HF.Clamp(velocity,0, 5)*(loosescrews/500)*NT.Deltatime)
            HF.AddAfflictionLimb(character,"ntc_loosescrews",limbtype,HF.Clamp(velocity,0,5)/50*NT.Deltatime)
        end
        

        -- losing the limb

        if isRobot then
            if materialloss >= 99 and not NTTrans.LimbIsRoboticallyAmputated(character,limbtype) then
                if limbtype == LimbType.Head then
                NTTrans.RoboticallyAmputateHead(character)
                HF.SetAffliction(character,"brainremoved",100)
                HF.GiveItem(character,"ntcsfx_cyberdeath")
                else
                --NTCyb.UncyberifyLimb(character,limbtype)
                NT.SurgicallyAmputateLimb(character,limbtype)
                HF.GiveItem(character,"ntcsfx_cyberdeath")
                end
    
                return
            end
        else
            -- losing the limb
            if materialloss >= 99 then
                NTCyb.UncyberifyLimb(character,limbtype)
                NT.TraumamputateLimbMinusItem(character,limbtype)
                HF.GiveItem(character,"ntcsfx_cyberdeath")
                HF.AddAfflictionLimb(character,"internaldamage",limbtype,HF.RandomRange(30,60))
                HF.AddAfflictionLimb(character,"foreignbody",limbtype,HF.RandomRange(10,25))
                return
            end
        end

        

        -- limb malfunction due to damaged electronics
        local malfunction = (damagedelectronics > 20 and HF.Chance((damagedelectronics/120)^4))
        if malfunction then
            HF.SpawnItemAt("ntcvfx_malfunction",limb.WorldPosition)
        end
        local locklimb = damagedelectronics >= 99 or bentmetal >= 99 or malfunction
            
        local function lockLimb()
            local limbIdentifierLookup = {}
            limbIdentifierLookup[LimbType.LeftArm] = "lockleftarm"
            limbIdentifierLookup[LimbType.RightArm] = "lockrightarm"
            limbIdentifierLookup[LimbType.LeftLeg] = "lockleftleg"
            limbIdentifierLookup[LimbType.RightLeg] = "lockrightleg"
            if limbIdentifierLookup[limbtype]==nil then return end
            NTC.SetSymptomTrue(character,limbIdentifierLookup[limbtype])
        end

        if locklimb then lockLimb() end

        -- slowdown due to bent metal
        if bentmetal > 5 and (limbtype == LimbType.LeftLeg or limbtype==LimbType.RightLeg) then
            NTC.MultiplySpeed(character,1-(bentmetal/100)*0.5)
        end
    end

    updateLimb(character,LimbType.Torso)
    updateLimb(character,LimbType.Head)
    updateLimb(character,LimbType.LeftLeg)
    updateLimb(character,LimbType.RightLeg)
    updateLimb(character,LimbType.LeftArm)
    updateLimb(character,LimbType.RightArm)

end

function NTTrans.ConvertDamageTypes(character,limbtype)

    local isRobot = NTTrans.IsRobot(character)

    if isRobot then
        local headloss = HF.GetAfflictionStrengthLimb(character,LimbType.Head,"ntc_materialloss",0)
        local torsoloss = HF.GetAfflictionStrengthLimb(character,LimbType.Torso,"ntc_materialloss",0)
        local rlegloss = HF.GetAfflictionStrengthLimb(character,LimbType.RightLeg,"ntc_materialloss",0)
        local llegloss = HF.GetAfflictionStrengthLimb(character,LimbType.LeftLeg,"ntc_materialloss",0)
        local rarmloss = HF.GetAfflictionStrengthLimb(character,LimbType.RightArm,"ntc_materialloss",0)
        local larmloss = HF.GetAfflictionStrengthLimb(character,LimbType.LeftArm,"ntc_materialloss",0)

        local systemshock = HF.GetAfflictionStrength(character,"ntt_systemshock",0)
        local prevsystemshock = systemshock

        systemshock = torsoloss+0.5*(headloss)+0.125*(rlegloss+llegloss+rarmloss+larmloss)

        HF.ApplyAfflictionChange(character,"ntt_systemshock",systemshock,prevsystemshock,0,100)

        if systemshock >= 99 then
            HF.AddAffliction(character,"rinternaldamage",10000)
            end
    end

    if isRobot or NTCyb.HF.LimbIsCyber(character,limbtype) then
        
        -- /// fetch stats ///

        -- physical damage types
        local bleeding = HF.GetAfflictionStrengthLimb(character,limbtype,"bleeding",0)
        local burn = HF.GetAfflictionStrengthLimb(character,limbtype,"burn",0)
        local lacerations = HF.GetAfflictionStrengthLimb(character,limbtype,"lacerations",0)
        local gunshotwound = HF.GetAfflictionStrengthLimb(character,limbtype,"gunshotwound",0)
        local bitewounds = HF.GetAfflictionStrengthLimb(character,limbtype,"bitewounds",0)
        local explosiondamage = HF.GetAfflictionStrengthLimb(character,limbtype,"explosiondamage",0)
        local blunttrauma = HF.GetAfflictionStrengthLimb(character,limbtype,"blunttrauma",0)
        local internaldamage = HF.GetAfflictionStrengthLimb(character,limbtype,"internaldamage",0)
        local foreignbody = HF.GetAfflictionStrengthLimb(character,limbtype,"foreignbody",0)

        -- cyber stats
        local loosescrews = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_loosescrews",0)
        local prevloosescrews = loosescrews
        local damagedelectronics = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_damagedelectronics",0)
        local prevdamagedelectronics = damagedelectronics
        local bentmetal = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_bentmetal",0)
        local prevbentmetal = bentmetal
        local materialloss = HF.GetAfflictionStrengthLimb(character,limbtype,"ntc_materialloss",0)
        local prevmaterialloss = materialloss

        -- calculate damage conversion

        local function damageChance(val,chance)
            if val > 0.01 and HF.Chance(chance) then return val end
            return 0
        end

        loosescrews = loosescrews + 1*(
            0.25*damageChance(lacerations,0.75)+
            1*damageChance(explosiondamage,0.8)+
            0.5*damageChance(blunttrauma,0.5)+
            1*damageChance(internaldamage,0.75)+
            0.5*damageChance(bitewounds,0.5)+
            0.75*damageChance(foreignbody,0.75))

        damagedelectronics = damagedelectronics + 0.5*(1+prevmaterialloss/50)*(
            2*damageChance(burn,0.75)+
            0.75*damageChance(gunshotwound,0.85)+
            0.25*damageChance(bitewounds,0.5)+
            0.5*damageChance(explosiondamage,0.5)+
            1*damageChance(blunttrauma,0.5)+
            1*damageChance(internaldamage,0.75)+
            0.75*damageChance(foreignbody,0.75))

        bentmetal = bentmetal + 1*(
            0.25*damageChance(burn,0.85)+
            0.25*damageChance(lacerations,0.5)+
            0.5*damageChance(bitewounds,0.5)+
            1*damageChance(explosiondamage,0.85)+
            2*damageChance(blunttrauma,0.75))

        materialloss = materialloss + (1+prevloosescrews/50)*(
            0.5*damageChance(lacerations,0.75)+
            0.8*damageChance(gunshotwound,0.8)+
            0.6*damageChance(bitewounds,0.75)+
            1*explosiondamage+
            0.5*damageChance(foreignbody,0.8))


        -- /// apply changes ///

        HF.ApplyAfflictionChangeLimb(character,limbtype,"burn",0,burn,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"bleeding",0,bleeding,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"lacerations",0,lacerations,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"gunshotwound",0,gunshotwound,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"bitewounds",0,bitewounds,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"explosiondamage",0,explosiondamage,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"blunttrauma",0,blunttrauma,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"internaldamage",0,internaldamage,0,200)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"foreignbody",0,foreignbody,0,100)
        
        HF.ApplyAfflictionChangeLimb(character,limbtype,"ntc_loosescrews",loosescrews,prevloosescrews,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"ntc_damagedelectronics",damagedelectronics,prevdamagedelectronics,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"ntc_bentmetal",bentmetal,prevbentmetal,0,100)
        HF.ApplyAfflictionChangeLimb(character,limbtype,"ntc_materialloss",materialloss,prevmaterialloss,0,100)
        

        NT.DislocateLimb(character,limbtype,-1000)
        NT.BreakLimb(character,limbtype,-1000)
        NT.ArteryCutLimb(character,limbtype,-1000)

        HF.SetAfflictionLimb(character,"arteriesclamp",limbtype,0)
        HF.SetAfflictionLimb(character,"surgeryincision",limbtype,0)
        HF.SetAfflictionLimb(character,"clampedbleeders",limbtype,0)

        HF.SetAfflictionLimb(character,"drilledbones",limbtype,0)
        HF.SetAfflictionLimb(character,"retractedskin",limbtype,0)
        HF.SetAfflictionLimb(character,"suturedi",limbtype,0)
        HF.SetAfflictionLimb(character,"suturedw",limbtype,0)

        if not isRobot then
            if limbtype == LimbType.LeftLeg then
                HF.SetAffliction(character,"tll_amputation",0)
                HF.SetAffliction(character,"sll_amputation",0)
            end
            if limbtype == LimbType.RightLeg then
                HF.SetAffliction(character,"trl_amputation",0)
                HF.SetAffliction(character,"srl_amputation",0)
            end
            if limbtype == LimbType.LeftArm then
                HF.SetAffliction(character,"tla_amputation",0)
                HF.SetAffliction(character,"sla_amputation",0)
            end
            if limbtype == LimbType.RightArm then
                HF.SetAffliction(character,"tra_amputation",0)
                HF.SetAffliction(character,"sra_amputation",0)
            end
        end
        

    end
end

Hook.Add("character.created", "convertJobs", function(character)
    Timer.Wait(function()
        if character.info ~= null then
            local jobID = character.Info.Job.Prefab.Identifier
            local jobIDStr = tostring(character.Info.Job.Prefab.Identifier)
            if jobIDStr:match("speciesjob") and character.IsHuman then
                RerollGender(character, jobID)

            end
        end
    end, 1000)
end)