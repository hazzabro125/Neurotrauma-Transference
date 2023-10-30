
-- overrides

Timer.Wait(function()

    -- add funny hematology analyzer readout to robots
    local prevBloodScannerFunction = NT.ItemMethods.bloodanalyzer
    NT.ItemMethods.bloodanalyzer = function(item, usingCharacter, targetCharacter, limb)

        if NTRT.IsRobot(targetCharacter) then
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
        if NTRT.IsRobot(targetCharacter) then
            return
        end
        prevEmptybloodpackFunction(item,usingCharacter,targetCharacter,limb)
    end
    local prevAntibloodloss2Function = NT.ItemMethods.antibloodloss2
    NT.ItemMethods.antibloodloss2 = function(item, usingCharacter, targetCharacter, limb)
        if NTRT.IsRobot(targetCharacter) then
            return
        end
        prevAntibloodloss2Function(item,usingCharacter,targetCharacter,limb)
    end
    local prevBloodpackFunction = NT.ItemStartsWithMethods.bloodpack
    NT.ItemStartsWithMethods.bloodpack = function(item, usingCharacter, targetCharacter, limb)
        if NTRT.IsRobot(targetCharacter) then
            return
        end
        prevBloodpackFunction(item,usingCharacter,targetCharacter,limb)
    end

    -- make it so you can treat amputations on robots using cyberlimbs
    NTCyb.ItemMethods.cyberarm = function(item, usingCharacter, targetCharacter, limb) 
        local limbtype = HF.NormalizeLimbType(limb.type)
    
        if NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) and not NTRT.IsRobot(targetCharacter) then return end
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
    
        if NTCyb.HF.LimbIsCyber(targetCharacter,limbtype) and not NTRT.IsRobot(targetCharacter) then return end
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

end,1000)