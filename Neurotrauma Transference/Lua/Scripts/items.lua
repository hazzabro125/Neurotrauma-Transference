
-- overrides

Timer.Wait(function()

    -- add funny hematology analyzer readout to robots
    local prevBloodScannerFunction = NT.ItemMethods.bloodanalyzer
    NT.ItemMethods.bloodanalyzer = function(item, usingCharacter, targetCharacter, limb)

        if NTTrans.IsRobot(targetCharacter) then
            -- print readout for robots
            local readoutstring = "Bloodtype: ERROR\nAffliction readout for the blood of "..targetCharacter.Name..":\n"
            
            readoutstring = readoutstring.."\nMISSING BLOOD SAMPLE" 

            HF.DMClient(HF.CharacterToClient(usingCharacter),readoutstring,Color(127,255,255,255))
            return
        end

        prevBloodScannerFunction(item,usingCharacter,targetCharacter,limb)
    end

    -- make bloodpacks useless
    local prevEmptybloodpackFunction = NT.ItemMethods.emptybloodpack
    NT.ItemMethods.emptybloodpack = function(item, usingCharacter, targetCharacter, limb)
        if NTTrans.IsRobot(targetCharacter) then
            return
        end
        prevEmptybloodpackFunction(item,usingCharacter,targetCharacter,limb)
    end
    local prevAntibloodloss2Function = NT.ItemMethods.antibloodloss2
    NT.ItemMethods.antibloodloss2 = function(item, usingCharacter, targetCharacter, limb)
        if NTTrans.IsRobot(targetCharacter) then
            return
        end
        prevAntibloodloss2Function(item,usingCharacter,targetCharacter,limb)
    end
    local prevBloodpackFunction = NT.ItemStartsWithMethods.bloodpack
    NT.ItemStartsWithMethods.bloodpack = function(item, usingCharacter, targetCharacter, limb)
        if NTTrans.IsRobot(targetCharacter) then
            return
        end
        prevBloodpackFunction(item,usingCharacter,targetCharacter,limb)
    end

    -- make it so you can treat amputations on robots using cyberlimbs
    NTCyb.ItemMethods.cyberarm = function(item, usingCharacter, targetCharacter, limb) 
        local limbtype = HF.NormalizeLimbType(limb.type)
    
        if NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) and not NTTrans.IsRobot(targetCharacter) then return end
        if not NT.LimbIsSurgicallyAmputated(targetCharacter,limbtype) then return end
        if limbtype ~= LimbType.LeftArm and limbtype~=LimbType.RightArm then return end
    
        if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then
            NTCyb.CyberifyLimb(targetCharacter,limbtype)

            HF.SetAfflictionLimb(targetCharacter,"ntc_loosescrews",limbtype,0)
            HF.SetAfflictionLimb(targetCharacter,"ntc_damagedelectronics",limbtype,0)
            HF.SetAfflictionLimb(targetCharacter,"ntc_bentmetal",limbtype,0)
            HF.SetAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,0)

            HF.RemoveItem(item)
        else
            HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,20)
        end
    end
    NTCyb.ItemMethods.cyberleg = function(item, usingCharacter, targetCharacter, limb) 
        local limbtype = HF.NormalizeLimbType(limb.type)
    
        if NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) and not NTTrans.IsRobot(targetCharacter) then return end
        if not NT.LimbIsSurgicallyAmputated(targetCharacter,limbtype) then return end
        if limbtype ~= LimbType.LeftLeg and limbtype~=LimbType.RightLeg then return end
    
        if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then
            NTCyb.CyberifyLimb(targetCharacter,limbtype)

            HF.SetAfflictionLimb(targetCharacter,"ntc_loosescrews",limbtype,0)
            HF.SetAfflictionLimb(targetCharacter,"ntc_damagedelectronics",limbtype,0)
            HF.SetAfflictionLimb(targetCharacter,"ntc_bentmetal",limbtype,0)
            HF.SetAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,0)

            HF.RemoveItem(item)
        else
            HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,20)
        end
    end
    NT.ItemMethods.screwdriver = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    -- don't work on stasis
    if(HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end
    if not NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) then return end
    if limbtype ~= LimbType.Head then return end
    
    if(HF.HasAffliction(targetCharacter,"ntt_unscrewed",100)) then
        HF.SetAffliction(targetCharacter,"ntt_unscrewed",0)
    else
    if(not HF.HasAfflictionLimb(targetCharacter,"ntc_loosescrews",limbtype,1)) then
            HF.AddAffliction(targetCharacter,"ntt_unscrewed",25)
        end
        end
        HF.GiveItem(targetCharacter,"ntcsfx_screwdriver")
end
    NTCyb.ItemMethods.crowbar = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if(limbtype == LimbType.Head and HF.HasAffliction(targetCharacter,"ntt_unscrewed",100)) then
        local damage = HF.GetAfflictionStrength(targetCharacter,"cerebralhypoxia",0)
        local removed = HF.GetAfflictionStrength(targetCharacter,"brainremoved",0)
        if(removed <= 0) then

            if(HF.GetSurgerySkillRequirementMet(usingCharacter,100)) then
                HF.SetAffliction(targetCharacter,"brainremoved",100,usingCharacter)
                
                if NTSP ~= nil then
                    if HF.HasAffliction(targetCharacter,"artificialbrain") then
                        HF.SetAffliction(targetCharacter,"artificialbrain",0,usingCharacter)
                        damage=100
                    end
                end
                
                if(damage < 190) then
                    local postSpawnFunction = function(item,donor,client)
                        item.DescriptionTag = donor.TeamID
                        item.Condition = 100-damage*0.5
                        if client ~= nil then
                            item.Description = client.Name
                        end
                    end

                    if SERVER then
                        -- use server spawn method
                        local prefab = ItemPrefab.GetItemPrefab("braintransplant")
                        local client = HF.CharacterToClient(targetCharacter)
                        Entity.Spawner.AddItemToSpawnQueue(prefab, usingCharacter.WorldPosition, nil, nil, function(item)
                            usingCharacter.Inventory.TryPutItem(item, nil, {InvSlotType.Any})
                            postSpawnFunction(item,targetCharacter,client)
                        end)

                        if client ~= nil then
                            client.SetClientCharacter(nil)
                     RespawnCharacterProper(targetCharacter, client, targetCharacter.JobIdentifier)
                        -- this shit is fucked
                        end
                    else
                        -- use client spawn method
                        local item = Item(ItemPrefab.GetItemPrefab("braintransplant"), usingCharacter.WorldPosition)
                        usingCharacter.Inventory.TryPutItem(item, nil, {InvSlotType.Any})
                        postSpawnFunction(item,targetCharacter,nil)
                    end
                end
            else
                HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
                HF.AddAffliction(targetCharacter,"cerebralhypoxia",50,usingCharacter)
            end

            HF.GiveItem(targetCharacter,"ntsfx_slash")

        end
    end
end

NTCyb.ItemMethods.cyberskull = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = HF.NormalizeLimbType(limb.type)

    if NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) and not NTTrans.IsRobot(targetCharacter) then return end
    if not NTTrans.LimbIsRoboticallyAmputated(targetCharacter,limbtype) then return end
    if limbtype ~= LimbType.Head then return end

    if(HF.GetSkillRequirementMet(usingCharacter,"mechanical",70)) then

            HF.SetAfflictionLimb(targetCharacter,"ntc_loosescrews",limbtype,0)
            HF.SetAfflictionLimb(targetCharacter,"ntc_damagedelectronics",limbtype,0)
            HF.SetAfflictionLimb(targetCharacter,"ntc_bentmetal",limbtype,0)
            HF.SetAfflictionLimb(targetCharacter,"ntc_materialloss",limbtype,0)
            HF.SetAfflictionLimb(targetCharacter,"transh_amputation",limbtype,0)

            HF.RemoveItem(item)
        else
            HF.AddAfflictionLimb(targetCharacter,"internaldamage",limbtype,20)
        end
    end

--[[NT.ItemMethods.cyberbodyassistant = function(item, usingCharacter, targetCharacter, limb)
    local NPCSet = LuaUserData.CreateStatic("Barotrauma.NPCSet")
    print(NPCSet)
    print(NPCSet.Get("cyberbodies", "cyberassistant", true))

    Entity.Spawner.AddCharacterToSpawnQueue("Human", usingCharacter.WorldPosition, NPCSet.Get("cyberbodies", "cyberassistant", true).NTTCreateCharacterInfo(), function(newCharacter)
    end)

end]]

NT.ItemMethods.braintransplant = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type
    local conditionmodifier = 0
    if (not HF.GetSurgerySkillRequirementMet(usingCharacter,100)) then conditionmodifier = -40 end
    local workcondition = HF.Clamp(item.Condition+conditionmodifier,0,100)
    if(HF.HasAffliction(targetCharacter,"brainremoved",1) and limbtype == LimbType.Head) then
        HF.AddAffliction(targetCharacter,"cerebralhypoxia",-(workcondition),usingCharacter)
        HF.SetAffliction(targetCharacter,"brainremoved",0,usingCharacter)
       -- print(item.DescriptionTag)
       targetCharacter.UpdateTeam()
        if item.DescriptionTag == "1" then
            targetCharacter.UpdateTeam()
            Game.GameSession.CrewManager.AddCharacter(targetCharacter)
        elseif item.DescriptionTag == "2" then
            targetCharacter.TeamID = 2
            targetCharacter.UpdateTeam()
        elseif item.DescriptionTag == "3" then
            targetCharacter.TeamID = 3
            targetCharacter.UpdateTeam()
            Game.GameSession.CrewManager.RemoveCharacter(targetCharacter, true)
        end
        targetCharacter.UpdateTeam()
        -- give character control to the donor
        if SERVER then
            local donorclient = item.Description
            local client = HF.ClientFromName(donorclient)
            if client ~= nil then
                client.SetClientCharacter(targetCharacter)
                Game.GameSession.CrewManager.RemoveCharacter(targetCharacter, true)
                targetCharacter.UpdateTeam()
                print("client was true, should have removed from crew")
            end
        end

        HF.RemoveItem(item)
    end
end

NT.ItemMethods.organscalpel_brain = function(item, usingCharacter, targetCharacter, limb) 
    local limbtype = limb.type

    if(limbtype == LimbType.Head and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1)) then
        local damage = HF.GetAfflictionStrength(targetCharacter,"cerebralhypoxia",0)
        local removed = HF.GetAfflictionStrength(targetCharacter,"brainremoved",0)
        if(removed <= 0) then

            if(HF.GetSurgerySkillRequirementMet(usingCharacter,100)) then
                HF.SetAffliction(targetCharacter,"brainremoved",100,usingCharacter)
                HF.AddAffliction(targetCharacter,"cerebralhypoxia",100,usingCharacter)
                
                if NTSP ~= nil then
                    if HF.HasAffliction(targetCharacter,"artificialbrain") then
                        HF.SetAffliction(targetCharacter,"artificialbrain",0,usingCharacter)
                        damage=100
                    end
                end
                
                if(damage < 190) then
                    local postSpawnFunction = function(item,donor,client)
                        item.DescriptionTag = donor.TeamID
                        item.Condition = 100-damage*0.5
                        if client ~= nil then
                            item.Description = client.Name
                        end
                    end

                    if SERVER then
                        -- use server spawn method
                        local prefab = ItemPrefab.GetItemPrefab("braintransplant")
                        local client = HF.CharacterToClient(targetCharacter)
                        Entity.Spawner.AddItemToSpawnQueue(prefab, usingCharacter.WorldPosition, nil, nil, function(item)
                            usingCharacter.Inventory.TryPutItem(item, nil, {InvSlotType.Any})
                            postSpawnFunction(item,targetCharacter,client)
                        end)

                        if client ~= nil then
                            client.SetClientCharacter(nil)
                     RespawnCharacterProper(targetCharacter, client, targetCharacter.JobIdentifier)
                        -- this shit is fucked
                        end
                    else
                        -- use client spawn method
                        local item = Item(ItemPrefab.GetItemPrefab("braintransplant"), usingCharacter.WorldPosition)
                        usingCharacter.Inventory.TryPutItem(item, nil, {InvSlotType.Any})
                        postSpawnFunction(item,targetCharacter,nil)
                    end
                end
            else
                HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,15,usingCharacter)
                HF.AddAffliction(targetCharacter,"cerebralhypoxia",50,usingCharacter)
            end

            HF.GiveItem(targetCharacter,"ntsfx_slash")

        end
    end
end

Hook.Add("chatMessage", "test", function(message, client)
    
    print(client.Name .. " has sent " .. message)
    RespawnCharacterProper(client.character, client, client.character.JobIdentifier)
end)
end,1000)