
-- This file contains a bunch of useful functions that see heavy use in the other scripts.
NTTrans.HF = {} -- Helperfunctions

function NTTrans.CyberifyLimb(character,limbtype)
    
    if limbtype == LimbType.Head then 
        HF.SetAfflictionLimb(character,"ntt_cyberskull",limbtype,100)
    end
    if limbtype == LimbType.Torso then 
        HF.SetAfflictionLimb(character,"ntt_cyberchest",limbtype,100)
    end
end


local function MoveInvSlot(oldCharacter, newCharacter, invSlot)
    local item = oldCharacter.Inventory.GetItemInLimbSlot(invSlot)
    if (item ~= nil) then
        item.Drop() -- drop item to the ground
        local index = newCharacter.Inventory.FindLimbSlot(invSlot)
        newCharacter.Inventory.TryPutItem(item, index, true, false) -- move item to new character
    end
end

local function MoveAllItems(oldCharacter, newCharacter)
    for _, it in pairs(oldCharacter.Inventory.FindAllItems(nil, true, nil)) do
        for i=8,30,1 do
            if newCharacter.Inventory.CanBePutInSlot(it, i, false) then
                if newCharacter.Inventory.TryPutItem(it, i, false, false) then
                    break
                end
                
            end
        end
    end
    
end

local function RespawnCharacter(character, jobID)
    local characterID = "human"
    print("Respawning " .. character.Name .. " as " .. characterID)

    Entity.Spawner.AddCharacterToSpawnQueue(characterID, character.WorldPosition, function(newCharacter)
        local client = nil
        for key, value in pairs(Client.ClientList) do
            if value.Character == character then
                client = value
            end
        end

        MoveInvSlot(character, newCharacter, InvSlotType.Card)
        MoveInvSlot(character, newCharacter, InvSlotType.Headset)
        MoveInvSlot(character, newCharacter, InvSlotType.RightHand)
        MoveInvSlot(character, newCharacter, InvSlotType.LeftHand)
        MoveInvSlot(character, newCharacter, InvSlotType.Head)
        MoveInvSlot(character, newCharacter, InvSlotType.InnerClothes)
        MoveInvSlot(character, newCharacter, InvSlotType.OuterClothes)
        MoveInvSlot(character, newCharacter, InvSlotType.Bag)

        MoveAllItems(character, newCharacter)



        newCharacter.TeamID = character.TeamID
        newCharacter.SetOriginalTeam(character.TeamID)
        newCharacter.UpdateTeam()
        Game.GameSession.CrewManager.AddCharacter(newCharacter)

    
        Entity.Spawner.AddEntityToRemoveQueue(character)

        if Game.IsSingleplayer then
            local info = CharacterInfo(characterID, character.Name, character.Name)
            info.Job = Job(JobPrefab.Get(jobID))
            newCharacter.Info = info
            

            while true do
                Game.GameSession.CrewManager.SelectNextCharacter()
                if (Character.Controlled ~= nil and not Entity.Spawner.IsInRemoveQueue(Character.Controlled)) then
                    break
                end
            end
        elseif Game.IsMultiplayer then
        end

        

        if client == nil then
            return
        end


        client.SetClientCharacter(newCharacter)

        local info = CharacterInfo(characterID, client.Name, client.Name)
        info.Job = Job(JobPrefab.Get(jobID))
        info.Head = client.CharacterInfo.Head
        info.Head.HairIndex = 0
        info.Head.BeardIndex = 0
        info.Head.MoustacheIndex = 0
        info.Head.FaceAttachmentIndex = 0
        newCharacter.Info = info

        print("Character respawned and added to crew list")
    end)
end

function RespawnCharacterProper(character, client, jobID)
    local characterID = "human"
    print("Respawning " .. character.Name .. " as " .. characterID)

    Entity.Spawner.AddCharacterToSpawnQueue(characterID, character.WorldPosition, function(newCharacter)

        MoveInvSlot(character, newCharacter, InvSlotType.Card)
        MoveInvSlot(character, newCharacter, InvSlotType.Headset)
        MoveInvSlot(character, newCharacter, InvSlotType.RightHand)
        MoveInvSlot(character, newCharacter, InvSlotType.LeftHand)
        MoveInvSlot(character, newCharacter, InvSlotType.Head)
        MoveInvSlot(character, newCharacter, InvSlotType.InnerClothes)
        MoveInvSlot(character, newCharacter, InvSlotType.OuterClothes)
        MoveInvSlot(character, newCharacter, InvSlotType.Bag)

        MoveAllItems(character, newCharacter)



        newCharacter.TeamID = character.TeamID
        newCharacter.SetOriginalTeam(character.TeamID)
        newCharacter.UpdateTeam()

        Game.GameSession.CrewManager.AddCharacter(newCharacter)

    
        Entity.Spawner.AddEntityToRemoveQueue(character)

        if Game.IsSingleplayer then
            

            while true do
                Game.GameSession.CrewManager.SelectNextCharacter()
                if (Character.Controlled ~= nil and not Entity.Spawner.IsInRemoveQueue(Character.Controlled)) then
                    break
                end
            end
        elseif Game.IsMultiplayer then
        end

        for affliction in character.CharacterHealth.GetAllAfflictions(function(a) end) do
            local limb = character.CharacterHealth.GetAfflictionLimb(affliction)
            newCharacter.CharacterHealth.ApplyAffliction(limb, affliction, true, true)
        end
        local info = CharacterInfo(characterID, character.Name, character.Name)
        info.Job = Job(JobPrefab.Get(jobID))
        info.Head = character.Info.Head
        info.AdditionalTalentPoints = character.Info.AdditionalTalentPoints
    

        newCharacter.Info = info
        for talent in character.Info.UnlockedTalents do
            newCharacter.GiveTalent(talent, false)
        end
        newCharacter.Info.GiveExperience(character.Info.ExperiencePoints)
        newCharacter.Info.AdditionalTalentPoints = character.Info.AdditionalTalentPoints

        newCharacter.Info.SetSkillLevel("mechanical", character.GetSkillLevel("mechanical"))
        newCharacter.Info.SetSkillLevel("medical", character.GetSkillLevel("medical"))
        newCharacter.Info.SetSkillLevel("electrical", character.GetSkillLevel("electrical"))
        newCharacter.Info.SetSkillLevel("weapons", character.GetSkillLevel("weapons"))
        newCharacter.Info.SetSkillLevel("helm", character.GetSkillLevel("helm"))

        print("Character respawned and added to crew list")
    end)
end


function RerollGender(character, jobID)
    local characterID = "human"

    Entity.Spawner.AddCharacterToSpawnQueue(characterID, character.WorldPosition, function(newCharacter)
       local client = HF.CharacterToClient(character)

        MoveInvSlot(character, newCharacter, InvSlotType.Card)
        MoveInvSlot(character, newCharacter, InvSlotType.Headset)
        MoveInvSlot(character, newCharacter, InvSlotType.RightHand)
        MoveInvSlot(character, newCharacter, InvSlotType.LeftHand)
        MoveInvSlot(character, newCharacter, InvSlotType.Head)
        MoveInvSlot(character, newCharacter, InvSlotType.InnerClothes)
        MoveInvSlot(character, newCharacter, InvSlotType.OuterClothes)
        MoveInvSlot(character, newCharacter, InvSlotType.Bag)

        MoveAllItems(character, newCharacter)



        newCharacter.TeamID = character.TeamID
        newCharacter.SetOriginalTeam(character.TeamID)
        newCharacter.UpdateTeam()

        Entity.Spawner.AddEntityToRemoveQueue(character)

            local info = CharacterInfo(characterID, character.Name, character.Name)
            info.Job = Job(JobPrefab.Get(jobID))


            newCharacter.Info = info
            print(character.Name)
        if SERVER then
            if client ~= nil then
                client.SetClientCharacter(newCharacter)
            end
        end
    end)
    end

function NTTrans.RoboticallyAmputateHead(character,strength,traumampstrength)
    strength = strength or 100
    traumampstrength = traumampstrength or 0
    
    limbtype = HF.NormalizeLimbType(limbtype)
    HF.SetAffliction(character,"transh_amputation",strength)

    HF.SetAffliction(character,"th_amputation",traumampstrength)
    local client = HF.CharacterToClient(character)
    if client ~= nil then
    client.SetClientCharacter(nil) end
end

function NTTrans.LimbIsRoboticallyAmputated(character,limbtype)
    local limbtoaffliction = {}
    limbtoaffliction[LimbType.RightLeg] = "srl_amputation"
    limbtoaffliction[LimbType.LeftLeg] = "sll_amputation"
    limbtoaffliction[LimbType.RightArm] = "sra_amputation"
    limbtoaffliction[LimbType.LeftArm] = "sla_amputation"
    limbtoaffliction[LimbType.Head] = "transh_amputation"
    if limbtoaffliction[limbtype] == nil then return false end
    return HF.HasAffliction(character,limbtoaffliction[limbtype],0.1)
end

--[[function NTTrans.SummonRobot(character)
    humanPrefab = NPCSet.Get("cyberbodies", "cyberassistant", true)
    Entity.Spawner.AddCharacterToSpawnQueue("Human", character.WorldPosition, humanPrefab.CreateCharacterInfo(), function(newCharacter)
     newCharacter.TeamID = 1
     newCharacter.UpdateTeam()
     Game.GameSession.CrewManager.AddCharacter(newCharacter)
    end)
end]]

function NTTCreateCharacterInfo(randSync)
    randSync = randSync or Rand.RandSync.Unsynced -- Default value for randSync if not provided
    
    local characterElement = ToolBox.SelectWeightedRandom(CustomCharacterInfos, function(info) return info.commonness end, randSync).element
    local characterInfo

    if characterElement == nil then
        characterInfo = CharacterInfo.new(CharacterPrefab.HumanSpeciesName, GetJobPrefab(randSync), Identifier, randSync)
    else
        characterInfo = CharacterInfo.new(characterElement, Identifier)
    end

    if characterInfo.Job ~= nil and not MathUtils.NearlyEqual(SkillMultiplier, 1.0) then
        for _, skill in ipairs(characterInfo.Job:GetSkills()) do
            local newSkill = skill.Level * SkillMultiplier
            skill:IncreaseSkill(newSkill - skill.Level, false)
        end
        characterInfo.Salary = characterInfo:CalculateSalary()
    end

    characterInfo.HumanPrefabIds = {NpcSetIdentifier, Identifier}
    characterInfo:GiveExperience(ExperiencePoints)

    return characterInfo
end