-- Doesn't work with RE4R. Things feel more obscured in this one than the others. Did find:
-- - GameObjects that start with "DropItem_" with a number of question marks after -> chainsaw.DropItem (component)
--   -> _ItemData -> ItemID, Count, AmmoItemID, AmmoCount, Durability
--      OR
--   -> _Item -> _ItemId, _CurrentDurability, _CurrentItemCount, _ItemType (lists things like "Powder(4)"), _ItemSize (size in inv, e.g., "_1x1_")
-- - _Item -> _ItemType in the above has Key(0), Ammo(1), Parts(3), Powder(4), Gun(5), Melee(6), Throwing(7), etc.
-- - Could mean that the chainsaw.InteractHolder (component) is the source of interactions that we'd want to hook somewhere
-- - This mod has the item interaction stuff in it, I think:
--   - https://www.nexusmods.com/residentevil42023/mods/1063
-- - These mods also have a lot of relevant Lua code for inventory items, but not ground items: 
--   - https://www.nexusmods.com/residentevil42023/mods/896
--   - https://www.nexusmods.com/residentevil42023/mods/126
--   - https://www.nexusmods.com/residentevil42023/mods/1057
--

local Inspect = {}
Inspect.currentMapID = nil -- only used by RE2R and RE3R currently

local InspectItem = {}
local InspectPlayer = {}
local InspectTypewriter = {}

function InspectItem.GetName(gameObject)
    return gameObject:call("get_Name()") or ""
end

function InspectItem.GetParentName(gameObject)
    local transform = sdk.to_managed_object(gameObject:call('get_Transform()'))
    local transform_parent = sdk.to_managed_object(transform:call('get_Parent()'))

    if transform_parent then
        local gameobject_parent = sdk.to_managed_object(transform_parent:call('get_GameObject()'))
        local comp_item_positions = nil
        
        if game == "RE2R" or game == "RE3R" then
            comp_item_positions = gameobject_parent:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("item.ItemPositions")))
        end

        if game == "RE7" then
            comp_item_positions = gameobject_parent:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("Item")))
        end

        -- only return the parent name if it's an item; otherwise, we don't care
        if comp_item_positions then
            return gameobject_parent:call("get_Name()") or ""
        else
            return ""
        end
    end

    return ""
end

function InspectItem.GetFolderPath(gameObject)
    local gameobject_folder = gameObject:call("get_Folder()")
    
    if gameobject_folder then 
        return gameobject_folder:call("get_Path()") 
    end

    return ""
end

function InspectPlayer.GetPosition()
    local player_position = nil

    if game == "RE2R" or game == "RE3R" then
        local player_manager = sdk.get_managed_singleton(sdk.game_namespace("PlayerManager"))
        player_position = player_manager:call("get_CurrentPosition()")
    end

    if game == "RE7" or game == "RE8" then
        local player_object = player.gameobj -- apparently REF defines this? -- probably just EMV tbh
        local player_transform = player_object:call("get_Transform")
        player_position = player_transform:call("get_Position")
    end

    if game == "RE9" then
        local playerLeon = scene:call("findGameObject(System.String)", "cp_A000")
        local playerGrace = scene:call("findGameObject(System.String)", "cp_A100")
        local playerMystery = scene:call("findGameObject(System.String)", "cp_A200")
        local playerTransform

        if playerLeon ~= nil then
            playerTransform = playerLeon:call("get_Transform()")
        elseif playerGrace ~= nil then
            playerTransform = playerGrace:call("get_Transform()")
        elseif playerMystery ~= nil then
            playerTransform = playerMystery:call("get_Transform()")
        else
            return "Unknown"
        end

        if playerTransform ~= nil then
            player_position = playerTransform:call("get_UniversalPosition")
        end
    end

    local x = Inspect._Round(player_position.x)
    local y = Inspect._Round(player_position.y)
    local z = Inspect._Round(player_position.z)

    return { x = x, y = y, z = z }
end

function InspectPlayer.GetPositionString()
    local pos = InspectPlayer.GetPosition()

    if not pos then return "" end

    return "[" .. pos["x"] .. ", " .. pos["y"] .. ", " .. pos["z"] .. "]"
end

function InspectTypewriter.IsTypewriter(gameObject)
    local gameobject_name = InspectItem.GetName(gameObject)
    local gameobject_parent = InspectItem.GetParentName(gameObject)

    if game == "RE2R" or game == "RE3R" then
        if string.match(gameobject_name, "Typewriter") then
            return true
        end
    end

    if game == "RE7" then
        if string.match(gameobject_name, "SaveMenuInteract") then
            return true
        end
    end

    if game == "RE8" then
        if string.match(gameobject_name, "InteractManualSave") then
            return true
        end
    end

    return false
end

function InspectTypewriter.GetLocationId(gameObject)
    if game == "RE2R" or game == "RE3R" then
        local comp_gimmick_control = gameObject:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("gimmick.action.GimmickControl")))
        
        return comp_gimmick_control:call("get_MyLocation()")
    end

    if game == "RE7" then
        local comp_interact_base = gameObject:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("InteractObjectBase")))
        local search_object = comp_interact_base:get_field("_SearchObject")
        local comp_map_object = search_object:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("MapObject")))
        local map_data = comp_map_object:get_field("Data")

        return map_data:get_field("Chapter")
    end

    if game == "RE8" then
        local systemObject = scene:call("findGameObject(System.String)", "SystemObject")
        local mapManagerComp = systemObject:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("MapManager")))
        local mapInfo = mapManagerComp:get_field("<currentRoomUnit>k__BackingField")

        return mapInfo:get_field("ZoneID")
    end

    return nil
end

function InspectTypewriter.GetMapId(gameObject)
    if game == "RE2R" then
        local comp_gimmick_control = gameObject:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("gimmick.action.GimmickControl")))
        local comp_gimmick_body = comp_gimmick_control:call("get_MyGimmickBody()")
        
        return comp_gimmick_body:get_field("AssignMapID")
    end

    if game == "RE3R" then
        local comp_gimmick_control = gameObject:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("gimmick.action.GimmickControl")))
        
        return comp_gimmick_control:call("getMapIdForMapClearing()")
    end

    if game == "RE7" then
        local comp_interact_base = gameObject:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("InteractObjectBase")))
        local search_object = comp_interact_base:get_field("_SearchObject")
        local comp_map_object = search_object:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("MapObject")))
        local map_data = comp_map_object:get_field("Data")

        return map_data:get_field("RoomID")
    end

    if game == "RE8" then
        local systemObject = scene:call("findGameObject(System.String)", "SystemObject")
        local mapManagerComp = systemObject:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("MapManager")))
        local mapInfo = mapManagerComp:get_field("<currentRoomUnit>k__BackingField")

        return mapInfo:get_field("MapID")
    end

    return nil
end

function Inspect.GetGameByGameName()
    local gameName = reframework:get_game_name()

    if not gameName then
        return nil
    end

    if gameName == "re2" or gameName == "re3" or gameName == "re4" then
        gameName = gameName .. "r" -- add the "remake" on the end
    end

    return string.upper(gameName)
end

function Inspect.GetGameByNamespace()
    local namespace_name = sdk.game_namespace("")

    if namespace_name == "app.ropeway." then return "RE2R" end
    if namespace_name == "offline." then return "RE3R" end -- what a stupid namespace name
    if namespace_name == "app." then
        -- this is a silly way to tell the difference between RE7 and RE8
        if player.gameobj:get_Name() == "Pl1000" then 
            return "RE7"
        elseif player == nil then -- for some reason, player doesn't exist in RE9, possibly an EMV change
            return "RE9"
        else -- player.gameobj:get_Name() == "pl1000"
            return "RE8" 
        end
    end
    if namespace_name == "chainsaw." then return "RE4R" end -- awesome namespace name

    return nil
end

function Inspect.Log(message, value)
    if not message and not value then 
        log.debug("")
        return
    end

    if not value then
        log.debug("| REF_Inspect | " .. tostring(message))
        return
    end

    log.debug("| REF_Inspect | " .. tostring(message) .. ": " .. tostring(value))
end

function Inspect._Setup()
    Inspect._SetupHook()
end

function Inspect._SetupHook()
    if game == "RE2R" or game == "RE3R" then
        -- main interactions hook
        local interactType = sdk.find_type_definition(sdk.game_namespace("gimmick.action.FeedbackFSM"))

        if interactType then
            local interact_method = interactType:get_method("execute")

            sdk.hook(interact_method, function(args)
                local compFeedbackFSM = sdk.to_managed_object(args[2])
                local parentOfComponent = sdk.to_managed_object(compFeedbackFSM:get_field('_Owner'))

                Inspect.Log() -- intentional line break
                Inspect.Log("Item Object", InspectItem.GetName(parentOfComponent))
                Inspect.Log("Parent Object", InspectItem.GetParentName(parentOfComponent))
                Inspect.Log("Folder Path", InspectItem.GetFolderPath(parentOfComponent))
                Inspect.Log("Player Position", InspectPlayer.GetPositionString())

                if InspectTypewriter.IsTypewriter(parentOfComponent) then
                    Inspect.Log("Typewriter Location ID", InspectTypewriter.GetLocationId(parentOfComponent))
                    Inspect.Log("Typewriter Map ID", InspectTypewriter.GetMapId(parentOfComponent))
                end
            end)
        end

        -- map switching (i.e., room switching) hook
        local interactType = sdk.find_type_definition(sdk.game_namespace("EnvironmentStandbyManager"))

        if interactType then
            local interact_method = interactType:get_method("getStandbyController")

            sdk.hook(interact_method, function(args)
                local compEnvStandby = sdk.to_managed_object(args[2])
                local currentMapID = compEnvStandby:call("get_CurrentMap")

                if currentMapID ~= Inspect.currentMapID then
                    Inspect.currentMapID = currentMapID
                    Inspect.Log("Current Map ID", currentMapID)
                end
            end)
        end
    end

    if game == "RE7" then
        local interactType = sdk.find_type_definition(sdk.game_namespace("InteractObjectBase"))

        if interactType then
            local interact_method = interactType:get_method("FsmExecute")

            sdk.hook(interact_method, function(args)
                local compFeedbackFSM = sdk.to_managed_object(args[2])
                local parentOfComponent = sdk.to_managed_object(compFeedbackFSM:call("get_GameObject"))

                Inspect.Log() -- intentional line break
                Inspect.Log("Item Object", InspectItem.GetName(parentOfComponent))
                Inspect.Log("Parent Object", InspectItem.GetParentName(parentOfComponent))
                Inspect.Log("Folder Path", InspectItem.GetFolderPath(parentOfComponent))
                Inspect.Log("Player Position", InspectPlayer.GetPositionString())

                if InspectTypewriter.IsTypewriter(parentOfComponent) then
                    Inspect.Log("Recorder Location ID", InspectTypewriter.GetLocationId(parentOfComponent))
                    Inspect.Log("Recorder Map ID", InspectTypewriter.GetMapId(parentOfComponent))
                end
            end)
        end
    end

    if game == "RE8" then
        local interactType = sdk.find_type_definition(sdk.game_namespace("InteractBase"))

        if interactType then
            local interact_method = interactType:get_method("SuccessInteract")

            sdk.hook(interact_method, function(args)
                local interactBasic = sdk.to_managed_object(args[2])
                local interactItemGet = interactBasic:get_field("ParentObject")
                local interactItemGetComp = interactItemGet:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("InteractItemGet")))

                -- if it's not an item to get, just have it display information for the first object instead
                local itemObject = interactItemGet

                -- if it is an item to get, have it find the actual item object and use that
                if interactItemGetComp ~= nil then
                     itemObject = interactItemGetComp:get_field("ItemSetGameObject")
                end

                local itemObjectTransform = itemObject:call("get_Transform")

                -- TODO: move getting transform position (and itemObjectTransform above) into a method for getting position like GetName gets name
                local universalPosition = itemObjectTransform:call("get_Position")
                local positionValues = { universalPosition.x, universalPosition.y, universalPosition.z }

                Inspect.Log() -- intentional line break
                Inspect.Log("Item Object", InspectItem.GetName(itemObject))
                Inspect.Log("Item Position", "[" .. tostring(table.concat(positionValues, ",")) .. "]")
                Inspect.Log("Folder Path", InspectItem.GetFolderPath(itemObject))
                Inspect.Log("Player Position", InspectPlayer.GetPositionString())

                if InspectTypewriter.IsTypewriter(itemObject) then
                    Inspect.Log("Typewriter Location ID", InspectTypewriter.GetLocationId(itemObject))
                    Inspect.Log("Typewriter Map ID", InspectTypewriter.GetMapId(itemObject))
                end

                --local itemObjectConfigureComp = itemObject:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("ItemGetConfigure")))
                --> itemObjectConfigureComp -> <references>k__BackingField -> <itemCore>k__BackingField -> <work>k__BackingField --> ItemID, etc.
            end)
        end
    end

    if game == "RE9" then
        local interactType = sdk.find_type_definition(sdk.game_namespace("InteractTrigger"))
        local interactMethod = interactType:get_method("onProcessEvent")

        sdk.hook(interactMethod, function(args)
            local objWithTrigger = sdk.to_managed_object(args[2]) -- app.InteractTriggerKeyInput
        
            if objWithTrigger == nil then return end

            local obj = objWithTrigger:call("get_TargetGameObject")

            if obj == nil then return end

            --local objName = obj:call("get_Name()")
            local objItemComp = obj:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("ItemCore")))
            local objGimmickComp = obj:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("GimmickCore")))
            local folderPath = obj:call("get_Folder()"):call("get_Path()")
            local objPos = obj:call("get_Transform()"):call("get_UniversalPosition()")
            local posX = string.format("%.2f", objPos:get_field("x"))
            local posY = string.format("%.2f", objPos:get_field("y"))
            local posZ = string.format("%.2f", objPos:get_field("z"))

            local parentT = obj:call("get_Transform()"):call("get_Parent()")
            local parentObj = nil
            local parentObjName = ""

            if parentT ~= nil then
                parentObj = parentT:call("get_GameObject()")
                parentObjName = parentObj:call("get_Name()")
            end

            local inspectType = nil

            Inspect.Log() -- intentional line break

            if objItemComp ~= nil then
                local itemID = objItemComp:call("get_ItemID()")
                local itemIDStr = itemID:call("ToString()")
                
                -- local itemContainer = itemContext:call("get_ItemContainer()")
                -- local parentSpawner = nil

                -- parentSpawner = parentObj:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("ItemSpawner")))
                -- 
                -- -- the _AssignSectionID values are different between ItemCore and ItemSpawner for enemy-dropped item, for some reason

                inspectType = "ITEM"
            end -- if objItemComp

            if objGimmickComp ~= nil then
                local objFileComp = obj:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("GmFileV2")))
                local objLockComp = obj:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("GmLockV2")))
                local objSwitchComp = obj:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("GmSwitchV2")))

                if objFileComp ~= nil then
                    inspectType = "FILE"
                elseif objLockComp ~= nil and objSwitchComp ~= nil then
                    inspectType = "LOCK AND SWITCH"
                elseif objLockComp ~= nil then
                    inspectType = "LOCK"
                elseif objSwitchComp ~= nil then
                    inspectType = "SWITCH"
                else
                    inspectType = "MINOR GIMMICK"
                end
            end -- if objGimmickComp


            if parentT ~= nil then
                local parentGimmickComp = parentObj:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("GimmickCore")))

                if parentGimmickComp ~= nil then
                    local typewriterComp = parentObj:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("GmTypewriterV3")))
                    local itemboxComp = parentObj:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("GmItemBoxV2")))
                    
                    if typewriterComp ~= nil then
                        inspectType = "TYPEWRITER"
                    elseif itemboxComp ~= nil then
                        inspectType = "ITEMBOX"
                    else
                        inspectType = "GIMMICK"
                    end
                end
            end
 
            if inspectType == nil then
                inspectType = "UNKNOWN"
            end

            Inspect.Log("Inspect Type", inspectType)
            Inspect.Log("Item Object", Inspect._Sanitize(InspectItem.GetName(obj)))
            Inspect.Log("Parent Object", Inspect._Sanitize(parentObjName))
            Inspect.Log("Folder Path", Inspect._Sanitize(folderPath))
            
            if objItemComp ~= nil then
                local itemContext = objItemComp:get_field("_Context")
                local itemContextID = itemContext:call("get_ContextID()"):call("ToString()")
                local itemStaySection = itemContext:call("get_StaySection()"):call("ToString()")
                local itemSpawnSection = itemContext:call("get_SpawnSection()"):call("ToString()")
                local objItemParent = itemContext:call("get_ParentObject()")
                local objItemParentName = nil

                if objItemParent ~= nil then
                    objItemParentName = objItemParent:call("get_Name()")
                end
                
                Inspect.Log("Item Context ID", tostring(itemContextID))
                Inspect.Log("Item Context Parent", Inspect._Sanitize(tostring(objItemParentName)))
                Inspect.Log("Item Stay Section", tostring(itemStaySection))
                Inspect.Log("Item Spawn Section", tostring(itemSpawnSection))
            end

            Inspect.Log("Location Position", "[" .. Inspect._Round(posX) .. ", " .. Inspect._Round(posY) .. ", " .. Inspect._Round(posZ) .. "]")
            Inspect.Log("Player Position", InspectPlayer.GetPositionString())
        end,
        function (ret) return ret end)
    end
end

function Inspect._Round(number)
    return math.ceil(number * 100) / 100 -- two decimal places
end

function Inspect._Sanitize(str)
    return str:gsub("[^A-Za-z0-9()'-_ /]", ".")
end

-- this gets used a lot, so just define it outside the function scopes
game = Inspect.GetGameByGameName()

-- had this logic for game by namespace coded, so leaving it in case it's somehow needed
if game == nil then
    game = Inspect.GetGameByNamespace()
end

-- run all the setup once
re.on_pre_application_entry("UpdateBehavior", function()
    if not Inspect.didInit then
        Inspect.didInit = true

        Inspect._Setup()
    end
end)

Inspect.Log("Script loaded!")

if game ~= nil then
    Inspect.Log("Game identified as " .. tostring(game) .. ".")
end
