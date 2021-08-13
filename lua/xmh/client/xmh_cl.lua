--[[
   \   XALA'S MOVIE HELPER
 =3 ]]  Revision = "XMH.Rev.25.5 - 13/08/2021 (dd/mm/yyyy)" --[[
 =o |   License: MIT
   /   Created by: Xalalau Xubilozo
  |
   \   Garry's Mod Brasil
 =< |   http://www.gmbrblog.blogspot.com.br/
 =b |   https://github.com/xalalau/GMod/tree/master/Xala's%20Movie%20Helper
   /   Enjoy! - Aproveitem!
]]

----------------------------
-- Global variables
----------------------------

local xmh_adm = false
local shadows_combobox
local teleport_combobox
local teleport_positions = {}
local mark_clear = { -- Cleanup table
    ["Cleanup"] = 1,
    ["HideShow"] = 1,
    ["Flashlight"] = 1,
    ["General"] = 1,
    ["NPCMovement"] = 1,
    ["Physics"] = 1,
    ["Shadows"] = 1,
    ["PlayerView"] = 1,
    ["Weapons"] = 1,
    ["Defauts"] = 0
}
local supported_langs = {
 "en",
 "pt-BR",
 "game",
}
local xmh_enable_localplayer = 0

----------------------------
-- General
----------------------------

-- Returns DForm ComboBoxes selected values
local function getComboBoxSelection(combo)
    if combo:GetSelected() == nil then
        return nil
    end
    local words = string.Explode(" ", combo:GetSelected())
    local name = ""
    local space = 0
    for k,v in pairs(words) do
        if v != "nil" then
            if space == 0 then
                name = name..v
                space = 1
            else
                name = name.." "..v
            end
        end
    end
    return name
end

----------------------------
-- Admin
----------------------------

-- Sets admin var on players first spawn
net.Receive("XMH_XMHAdmin",function(ply)
    xmh_adm = net.ReadBool()
end)

-- Checks admin privilegies
-- Returns true or false
local function checkAdmin()
    local ply = LocalPlayer()
    if ply:IsValid() then
        if ply:IsAdmin() or ply:IsSuperAdmin() then
            return true
        end
    end
    return false
end

-- Renews admin privileges (Not very usefull without Derma/HTML, but ok...)
local function AdminCheck()
    if checkAdmin() == true and xmh_adm == false then
        xmh_adm = true
    elseif checkAdmin() == false and xmh_adm == true then
        xmh_adm = false
    end
end

----------------------------
-- Language
----------------------------

-- Checks if a given language is supported
local function isLanguageValid(language)
    for k,v in pairs(supported_langs) do
        if v == language then
            return true
        end
    end
    return false
end

-- Changes missing translations to English
local function checkLanguage(language)
    for k,v in pairs(XMH_LANG["en"]) do
        if not XMH_LANG[language][k] then
            print("XMH - Warning! Missing " .. k .. " translation for " .. language .. ". Switching to English...")
            XMH_LANG[language][k] = v
        end
    end
end

-- Loads the correct language
local function loadDefaultLanguage()
    if !file.Exists(xmh_lang_file, "DATA") then
        if isLanguageValid(_LANG) == false then
            _LANG = "en"
        end
    else
        _LANG = file.Read(xmh_lang_file, "DATA")
        print(XMH_LANG[_LANG]["client_lang_forced"].."'".. _LANG.."'!")
    end
    if _LANG != "en" then
        checkLanguage(_LANG)
    end
end

-- Forces to use a given language (if it's supported)
local function forceLanguage(ply,_,_,language)
    if isLanguageValid(language) == false then
        print(XMH_LANG[_LANG]["client_lang_not_supported"])
        for k,v in pairs(supported_langs) do
            print(v)
        end
        return
    end
    print(XMH_LANG[_LANG]["client_lang_forced"].."'".. language.."'!")
    print(XMH_LANG[_LANG]["client_lang_restart"])
    if language == "game" then
        file.Delete(xmh_lang_file)
        return
    end
    file.Write(xmh_lang_file, language)
end

loadDefaultLanguage()

----------------------------
-- Console variables
----------------------------

-- "Server(*)" and "Client" indicate where the code runs
-- The values of the "Server" variables (without *) need to be stored globaly in xmh_sv.lua file

CreateClientConVar("xmh_corpses_var"           ,32  ,false,false) -- Server
CreateClientConVar("xmh_knockback_var"         ,1   ,false,false) -- Server
CreateClientConVar("xmh_noclipspeed_var"       ,5   ,false,false) -- Server
CreateClientConVar("xmh_footsteps_var"         ,1   ,false,false) -- Server
CreateClientConVar("xmh_voiceicons_var"        ,1   ,false,false) -- Server
CreateClientConVar("xmh_runspeed_var"          ,500 ,false,false) -- Server*
CreateClientConVar("xmh_walkspeed_var"         ,250 ,false,false) -- Server*
CreateClientConVar("xmh_jumpheight_var"        ,200 ,false,false) -- Server*
CreateClientConVar("xmh_npcwalkrun_var"        ,1   ,false,false) -- Server
CreateClientConVar("xmh_aidisabled_var"        ,0   ,false,false) -- Server
CreateClientConVar("xmh_aidisable_var"         ,0   ,false,false) -- Server
CreateClientConVar("xmh_person_var"            ,0   ,false,false) --   Client
CreateClientConVar("xmh_shake_var"             ,0   ,false,false) --   Client
CreateClientConVar("xmh_skybox_var"            ,0   ,false,false) --   Client
CreateClientConVar("xmh_mode_var"              ,0   ,false,false) -- Server
CreateClientConVar("xmh_invisible_var"         ,1   ,false,false) -- Server*
CreateClientConVar("xmh_invisibleall_var"      ,1   ,false,false) -- Server
CreateClientConVar("xmh_toolgun_var"           ,1   ,false,false) --   Client
CreateClientConVar("xmh_toolgunmute_var"       ,1   ,false,false) --   Client
CreateClientConVar("xmh_decals_var"            ,2048,false,false) --   Client (Unnecessary convar, but without this the command always starts with value 1 (game bug))
CreateClientConVar("xmh_cleanup_var"           ,0   ,false,false) -- Server
CreateClientConVar("xmh_save_var"              ,0   ,false,false) --   Client
CreateClientConVar("xmh_physgun_var"           ,1   ,false,false) --   Client
CreateClientConVar("xmh_chatvoice_var"         ,1   ,false,false) --   Client
CreateClientConVar("xmh_throwforce_var"        ,1000,false,false) -- Server
CreateClientConVar("xmh_falldamage_var"        ,0   ,false,false) -- Server
CreateClientConVar("xmh_fullflashlight_var"    ,0   ,false,false) --   Client (Unnecessary convar, but without this the command always starts with value 1 (game bug))
CreateClientConVar("xmh_timescale_var"         ,1   ,false,false) -- Server
CreateClientConVar("xmh_wfriction_var"         ,8   ,false,false) -- Server
CreateClientConVar("xmh_weapammitem_var"       ,1   ,false,false) --   Client
CreateClientConVar("xmh_error_var"             ,1   ,false,false) --   Client
CreateClientConVar("xmh_fov_unlock_var"        ,0   ,false,false) --   Client
CreateClientConVar("xmh_fov_var"               ,100 ,false,false) --   Client
CreateClientConVar("xmh_viewmodel_var"         ,1   ,false,false) --   Client
CreateClientConVar("xmh_clcleanup_var"         ,1   ,false,false) --   Client
CreateClientConVar("xmh_cldisplay_var"         ,1   ,false,false) --   Client
CreateClientConVar("xmh_clfl_var"              ,1   ,false,false) --   Client
CreateClientConVar("xmh_clgeneral_var"         ,1   ,false,false) --   Client
CreateClientConVar("xmh_clnpcmove_var"         ,1   ,false,false) --   Client
CreateClientConVar("xmh_clphysics_var"         ,1   ,false,false) --   Client
CreateClientConVar("xmh_clshadows_var"         ,1   ,false,false) --   Client
CreateClientConVar("xmh_cltp_var"              ,1   ,false,false) --   Client
CreateClientConVar("xmh_clweapons_var"         ,1   ,false,false) --   Client
CreateClientConVar("xmh_checkuncheck_var"      ,1   ,false,false) --   Client
CreateClientConVar("xmh_editallweapons_var"    ,0   ,false,false) --   Client
CreateClientConVar("xmh_editweaponsallplys_var",0   ,false,false) -- Server
CreateClientConVar("xmh_defaultsall_var"       ,0   ,false,false) --   Client
CreateClientConVar("xmh_camera_fov"            ,100 ,false,false) --   Client

CreateClientConVar("xmh_make_invisibility_admin_only_var",0,false,false) -- Server (Special cvar only option)
CreateClientConVar("xmh_positionname_var" ,XMH_LANG[_LANG]["client_var_teleport"],false,false) -- Client

----------------------------
-- Position
----------------------------

-- Loads the map saved teleport_positions file
local function LoadTeleports()
    if file.Exists(xmh_teleports_file, "DATA") then
        teleport_positions = util.JSONToTable(file.Read(xmh_teleports_file, "DATA"))

        for k,v in pairs(teleport_positions) do
            teleport_combobox:AddChoice(k)
        end
    end
end

-- Adds a new teleport point and saves the teleport_positions to a file
local function CreateTeleport(ply)
    if IsValid(ply) then
        local name = GetConVar("xmh_positionname_var"):GetString()

        if name == "" then return end

        if teleport_positions[name] == nil then
            teleport_combobox:AddChoice(name)
        end

        local vec1 = ply:GetEyeTrace().HitPos
        local vec2 = ply:GetShootPos()

        teleport_positions[name] = { pos = ply:GetPos(), ang = (vec1 - vec2):Angle() }

        file.Write(xmh_teleports_file, util.TableToJSON(teleport_positions))
    end
end

-- Teleports the player to a point
local function TeleportToPos()
    local vecTab = teleport_positions[getComboBoxSelection(teleport_combobox)]

    if vecTab == nil then return end

    net.Start       ("XMH_TeleportPlayer")
    net.WriteVector (vecTab.pos          )
    net.WriteAngle  (vecTab.ang          )
    net.SendToServer(                    )
end

-- Deletes a teleport point and refreshs the teleport_positions file
local function DeleteTeleportPos()
    local locationName = getComboBoxSelection(teleport_combobox)

    if not locationName then return end

    local qPanel = vgui.Create("DFrame")
        qPanel:SetTitle(XMH_LANG[_LANG]["client_menu_position_delete_msg1"])
        qPanel:SetSize(285, 110)
        qPanel:SetPos(10, 10)
        qPanel:SetDeleteOnClose(true)
        qPanel:SetVisible(true)
        qPanel:SetDraggable(true)
        qPanel:ShowCloseButton(true)
        qPanel:MakePopup(true)
        qPanel:Center()

    local text = vgui.Create("DLabel", qPanel)
        text:SetPos(40, 25)
        text:SetSize(275, 25)
        text:SetText(XMH_LANG[_LANG]["client_menu_position_delete_msg2"])

    local panel = vgui.Create("DPanel", qPanel)
        panel:SetPos(5, 50)
        panel:SetSize(275, 20)

    local save = vgui.Create("DLabel", panel)
        save:SetPos(10, -2)
        save:SetSize(275, 25)
        save:SetText(locationName)
        save:SetTextColor(Color(0, 0, 0, 255))

    local buttonYes = vgui.Create("DButton", qPanel)
        buttonYes:SetPos(22, 75)
        buttonYes:SetText(XMH_LANG[_LANG]["client_menu_position_delete_confirm"])
        buttonYes:SetSize(120, 30)
        buttonYes.DoClick = function()
            teleport_positions[locationName] = nil
            teleport_combobox:Clear()
            for k,v in pairs(teleport_positions) do
                teleport_combobox:AddChoice(k)
            end
            file.Write(xmh_teleports_file, util.TableToJSON(teleport_positions))
            qPanel:Close()
        end

    local buttonNo = vgui.Create("DButton", qPanel)
        buttonNo:SetPos(146, 75)
        buttonNo:SetText(XMH_LANG[_LANG]["client_menu_position_delete_deny"])
        buttonNo:SetSize(120, 30)
        buttonNo.DoClick = function()
            qPanel:Close()
        end
end

local function SetRespawnPoint()
    LocalPlayer():PrintMessage(HUD_PRINTTALK, XMH_LANG[_LANG]["client_menu_position_set_msg"] .." (" .. tostring(LocalPlayer():GetPos()) .. ")")
    net.Start("XMH_SetRespawn")
    net.SendToServer()
end

local function UnsetRespawnPoint()
    LocalPlayer():PrintMessage(HUD_PRINTTALK, XMH_LANG[_LANG]["client_menu_position_unset_msg"])
    net.Start("XMH_SetRespawn")
        net.WriteBool(true)
    net.SendToServer()
end

----------------------------
-- Mixed panel functions
----------------------------

-- Turns skybox into green
function XMH_GreenSkybox(skybox_bool)
    local SourceSkyname = GetConVar("sv_skyname"):GetString()
    local SourceSkyPre    = {"lf","ft","rt","bk","dn","up"}

    -- Render 6 side skybox materials on every map or simple materials on the skybox on maps with env_skypainted entity
    if SourceSkyname == "painted" then
        if skybox_bool == 1 then
            hook.Add("PostDraw2DSkyBox", "xmh_renderskybox", function()
                local distance = 200
                local width = distance * 2.01
                local height = distance * 2.01

                -- Render our fake skybox around the player
                render.OverrideDepthEnable(true, false)

                cam.Start3D(Vector(0, 0, 0), EyeAngles())
                    render.SetMaterial(Material("skybox/green")) -- ft
                    render.DrawQuadEasy(Vector(0,-distance,0), Vector(0,1,0), width, height, Color(255,255,255,255), 180)
                    render.SetMaterial(Material("skybox/green")) -- bk
                    render.DrawQuadEasy(Vector(0,distance,0), Vector(0,-1,0), width, height, Color(255,255,255,255), 180)
                    render.SetMaterial(Material("skybox/green")) -- lf
                    render.DrawQuadEasy(Vector(-distance,0,0), Vector(1,0,0), width, height, Color(255,255,255,255), 180)
                    render.SetMaterial(Material("skybox/green")) -- rt
                    render.DrawQuadEasy(Vector(distance,0,0), Vector(-1,0,0), width, height, Color(255,255,255,255), 180)
                    render.SetMaterial(Material("skybox/green")) -- up
                    render.DrawQuadEasy(Vector(0,0,distance), Vector(0,0,-1), width, height, Color(255,255,255,255), 0)
                    render.SetMaterial(Material("skybox/green")) -- dn
                    render.DrawQuadEasy(Vector(0,0,-distance), Vector(0,0,1), width, height, Color(255,255,255,255), 0)
                cam.End3D()

                render.OverrideDepthEnable(false, false)
            end)
        else
            hook.Remove("PostDraw2DSkyBox", "xmh_renderskybox")
        end
    -- Change skybox materials on maps without env_skypainted entity
    else
        local SourceSkyMat    = {
            Material("skybox/"..SourceSkyname.."lf"),
            Material("skybox/"..SourceSkyname.."ft"),
            Material("skybox/"..SourceSkyname.."rt"),
            Material("skybox/"..SourceSkyname.."bk"),
            Material("skybox/"..SourceSkyname.."dn"),
            Material("skybox/"..SourceSkyname.."up"),
        }
        local T, A

        if Material("skybox/backup"..SourceSkyPre[1]):Width() == 2 then -- Backup sky textures
            for A = 1,6 do
                T = SourceSkyMat[A]:GetTexture("$basetexture") 
                Material("skybox/backup"..SourceSkyPre[A]):SetTexture("$basetexture",T)
            end
        end
        if skybox_bool == 1 then -- Green sky
            T = Material("skybox/green"):GetTexture("$basetexture")
            for A = 1,6 do 
                SourceSkyMat[A]:SetTexture("$basetexture",T)
            end
        else -- Original sky
            for A = 1,6 do
                T = Material("skybox/backup"..SourceSkyPre[A]):GetTexture("$basetexture")
                SourceSkyMat[A]:SetTexture("$basetexture",T)
            end
        end
    end
end

-- Removes toolgun effects
-- Note: Garry added gmod_drawtooleffects later, but I'm not going to touch it
function XMH_ToolGunEffect(toolgun_bool)
    local GModToolgunMat = {
        Material("effects/select_ring"),
        Material("effects/tool_tracer"),
        Material("effects/select_dot" ),
    }
    local T, A

    if Material("effects/backup"..1):Width() == 2 then -- Backup toolgun textures
        for A = 1,3 do 
            T = GModToolgunMat[A]:GetTexture("$basetexture") 
            Material("effects/backup"..A):SetTexture("$basetexture",T)
        end
    end
    if toolgun_bool == 0 then -- Remove textures
        T = Material("erase"):GetTexture("$basetexture") 
        for A = 1,3 do
            GModToolgunMat[A]:SetTexture("$basetexture",T)
        end
    else -- Restore textures
        for A = 1,3 do
            T = Material("effects/backup"..A):GetTexture("$basetexture")
            GModToolgunMat[A]:SetTexture("$basetexture",T)
        end
    end
end

-- Hides missing models
function XMH_Error(error_bool)
    -- for k,v in pairs(ents.FindByModel("models/error.mdl")) do -- Didn't work
    for k,v in pairs(ents.GetAll()) do
        if v:GetModel() == "models/error.mdl" then
            if error_bool == 0 then
                v:SetNoDraw(true)
                hook.Add( "PlayerSpawnEffect", "PlayerSpawnEffect_xmh", function(ply,effect)
                    return effect != "models/error.mdl"
                end)
            else
                v:SetNoDraw(false)
                hook.Remove("PlayerSpawnEffect", "PlayerSpawnEffect_xmh")
            end
        end
    end
end

-- Turns NPCs into pedestrians
local function Pedestrians()
    print("")
    print("___________________________________________________________")
    print("")
    print(XMH_LANG[_LANG]["client_func_pedestrians"])
    print("___________________________________________________________")
    print("")
    RunConsoleCommand("showconsole")
end

-- Enables automatic playermodel lipsync
local function LipSync()
    print("")
    print("___________________________________________________________")
    print("")
    print(XMH_LANG[_LANG]["client_func_lipsync"])
    print("___________________________________________________________")
    print("")
    RunConsoleCommand("showconsole")
end

-- Removes the crosshair
local function HideCrosshair()
    print("")
    print("___________________________________________________________")
    print("")
    print(XMH_LANG[_LANG]["client_func_crosshair"])
    print("___________________________________________________________")
    print("")
    RunConsoleCommand("showconsole")
end

-- Shows the current shadows resolution
local function ShadowResChk()
    local aux = GetConVar("r_flashlightdepthres"):GetInt()
    local aux = XMH_LANG[_LANG]["client_func_shadowres"].. aux .. "x" .. aux
    print("___________________________________________________________")
    print("")
    print(aux)
    print("___________________________________________________________")
    RunConsoleCommand("showconsole")
end

-- Changes the shadows resolution
function ShadowRes()
    opt = getComboBoxSelection(shadows_combobox)
    print(opt)
    if opt == nil then
        return
    end
    if (opt != "0" and opt != GetConVar("r_flashlightdepthres"):GetString()) then
        RunConsoleCommand("r_flashlightdepthres", opt)
    end
end

-- Remove dead corpses from de ground
local function ClearCorpses()
    net.Start       ("XMH_RunOneLineLua")
    net.WriteString ("xmh_clearcorpses" )
    net.SendToServer(                   )
end

-- Restores broken windows
local function RepairWindows()
    net.Start       ("XMH_RepairWindows")
    net.SendToServer(                   )
end

-- Hides decals and spraws
local function ClearDecals() 
    RunConsoleCommand("r_cleardecals") -- This removes decals
    RunConsoleCommand("r_cleardecals") -- And this removes sprays
end

-- Hides physgun effects
function XMH_PhysgunEffects(physgun_bool)
    if physgun_bool == 0 then
        RunConsoleCommand("effects_freeze"   , "0")
        RunConsoleCommand("effects_unfreeze" , "0")
        RunConsoleCommand("physgun_drawbeams", "0")
        RunConsoleCommand("physgun_halo"     , "0")
    else
        RunConsoleCommand("effects_freeze"   , "1")
        RunConsoleCommand("effects_unfreeze" , "1")
        RunConsoleCommand("physgun_drawbeams", "1")
        RunConsoleCommand("physgun_halo"     , "1")
    end
end

-- Hides the current view and world models
function XMH_ViewWorldModels()
    if GetConVar("xmh_viewmodel_var"):GetInt() == 0 then
        RunConsoleCommand("impulse", "200")
        hook.Add("PlayerSwitchWeapon", "PlayerSwitchWeapon_xmh", function(ply)
            timer.Create("Treme",0.1,1,function() -- needed delay
                RunConsoleCommand("impulse", "200")
                RunConsoleCommand("xmh_viewmodel_var", "1")
            end)
        end)
    else
        RunConsoleCommand("impulse", "200")
        hook.Remove("PlayerSwitchWeapon", "PlayerSwitchWeapon_xmh")
    end
end

-- Alternates between first person and third person
function XMH_Person(person_bool)
    if person_bool == 1 then
        RunConsoleCommand("thirdperson")
    else
        RunConsoleCommand("firstperson")
    end
end

-- """Earthquake""" simulator
function XMH_Shake(shake_bool)
    if shake_bool == 1 then
        timer.Create("Shake",1,1000,function() util.ScreenShake(LocalPlayer():GetPos(), 5, 5, 10, 5000) end)
    else
        timer.Remove("Shake")
        RunConsoleCommand("shake_stop")
    end
end

-- Enables client automatic game saving
function XMH_AutoSave(save_bool)
    if save_bool == 1 then
        timer.Create("AutoSave",360,0,function()
            print(XMH_LANG[_LANG]["client_func_game_saved"])
            RunConsoleCommand("gm_save")
        end)
    else
        timer.Destroy("AutoSave")
    end
end

-- Runs a command (it's used for the sub_type "fix" from commands_table.lua file)
function XMH_RunCommand(command, value)
    RunConsoleCommand(command, tostring(value))
end

-- Resets the decals and changes it's quantity
function XMH_DecalsQuantity(decals_quant)
    ClearDecals()
    RunConsoleCommand("r_decals", tostring(decals_quant))
end

-- Adds/Deletes hooks for derma invisibility
function XMH_SetInvisibilityHook(hook_name, hook_bool)
    if hook_bool == 0 then
        hook.Add(hook_name, hook_name.."_xmh", function(ply)
            return 0
        end)
    else
        hook.Remove(hook_name, hook_name.."_xmh")
    end
end

-- Prints messages from server
net.Receive("XMH_PrintMessage",function()
    LocalPlayer():PrintMessage( HUD_PRINTTALK, XMH_LANG[_LANG][net.ReadString()] )
end)

-- Drops weapon(s)
local function DropWeapon()
    local all_weapons = GetConVar("xmh_editallweapons_var"):GetInt()

    net.Start       ("XMH_HandleWeapons")
    net.WriteString ("xmh_dropweapon"   )
    net.WriteInt    (all_weapons, 2     )
    net.SendToServer(                   )
end

-- Drops weapon(s)
function XMH_ToolGunMute( value, command )
    if not game.SinglePlayer() then
        if value == 0 then
            local toolsounds = "weapons/airboat/airboat_gun_lastshot2.wav;weapons/airboat/airboat_gun_lastshot1.wav"
            hook.Add("EntityEmitSound", "NoTool", function(data)
                for k, v in pairs(string.Explode(";", toolsounds)) do
                    if v == data["SoundName"] then
                        return false
                    end
                end
            end)
        else
            hook.Remove( "EntityEmitSound", "NoTool" )
        end
    end
    net.Start       ("XMH_ToolGunMute")
    net.WriteString (command          )
    net.WriteInt    (value, 2         )
    net.SendToServer(                 )
end

-- Removes weapon(s)
local function RemoveWeapon()
    local all_weapons = GetConVar("xmh_editallweapons_var"):GetInt()

    net.Start       ("XMH_HandleWeapons")
    net.WriteString ("xmh_removeweapon" )
    net.WriteInt    (all_weapons, 2     )
    net.SendToServer(                   )
end

-- Removes primary ammo
local function RemovePrimaryAmmo()
    local all_weapons = GetConVar("xmh_editallweapons_var"):GetInt()

    net.Start       ("XMH_HandleWeapons"    )
    net.WriteString ("xmh_removeprimaryammo")
    net.WriteInt    (all_weapons, 2         )
    net.SendToServer(                       )
end

-- Removes secondary ammo
local function RemoveSecondaryAmmo()
    local all_weapons = GetConVar("xmh_editallweapons_var"):GetInt()

    net.Start       ("XMH_HandleWeapons"      )
    net.WriteString ("xmh_removesecondaryammo")
    net.WriteInt    (all_weapons, 2           )
    net.SendToServer(                         )
end

-- Gives GMod weapons
local function GiveGModWeapons()
    net.Start       ("XMH_HandleWeapons")
    net.WriteString ("xmh_givegmweapons")
    net.SendToServer(                   )
end

-- Gives HL2 weapons
local function GiveHL2Weapons()
    net.Start       ("XMH_HandleWeapons" )
    net.WriteString ("xmh_givehl2weapons")
    net.SendToServer(                    )
end

-- Clears dropped weapons and ammo
local function ClearWeaponsItems()
    net.Start       ("XMH_ClearWeaponsItems")
    net.SendToServer(                       )
end

----------------------------
-- [Import] Commands table
----------------------------

-- It needs to be here! Do not move this section
include("xmh/client/commands_table.lua")

----------------------------
-- "Defaults"
----------------------------

-- Checks or unchecks all the sections at once
local function CheckUncheck()
    local value = GetConVar("xmh_checkuncheck_var"):GetInt()

    if value == 1 then
        value = 0
        RunConsoleCommand("xmh_checkuncheck_var", "0")
    else
        value = 1
        RunConsoleCommand("xmh_checkuncheck_var", "1")
    end
    for k,_ in pairs(xmh_commands) do
        if xmh_commands[k].category == "Defaults" then
            RunConsoleCommand(k, tostring(value))
        end
    end
end

-- Checks or unchecks a section
local function SetSectionsToReset(section, value) 
    mark_clear[section] = value
end

-- Sets all the commands in the checked sections to defaults
local function Defaults()
    if ( GetConVar("xmh_defaultsall_var"):GetInt() == 1 ) then
        net.Start        ("XMH_DefaultsAll"           )
        net.WriteInt     (mark_clear["Cleanup"]    , 2)
        net.WriteInt     (mark_clear["HideShow"]    , 2)
        net.WriteInt     (mark_clear["Flashlight"] , 2)
        net.WriteInt     (mark_clear["General"]    , 2)
        net.WriteInt     (mark_clear["NPCMovement"], 2)
        net.WriteInt     (mark_clear["Physics"]    , 2)
        net.WriteInt     (mark_clear["Shadows"]    , 2)
        net.WriteInt     (mark_clear["PlayerView"], 2)
        net.WriteInt     (mark_clear["Weapons"]    , 2)
        net.SendToServer (                            )
    end

    local current_value

    for k,_ in pairs(xmh_commands) do
        if mark_clear[xmh_commands[k].category] == 1 then -- Is the category marked for cleaning?
            if (xmh_commands[k].cheat == true and GetConVar("sv_cheats"):GetInt() == 1) or xmh_commands[k].cheat == false then -- Is the cheats sittuation ok?
                if (xmh_commands[k].admin == true and checkAdmin() == true) or xmh_commands[k].admin == false then -- Is admin or user ok?
                    current_value = tonumber(string.format("%.2f", GetConVar(k):GetFloat())) -- Getting the value...
                    if (xmh_commands[k].default != current_value) then -- Are the values different?
                        RunConsoleCommand (k, tostring(xmh_commands[k].default))
                    end
                end
            end
        end
    end
end

-- Receives a "defaults order" and run it
net.Receive("XMH_DefaultsAll",function(_,ply)
    local backup = table.Copy(mark_clear)
    mark_clear["Cleanup"]     = net.ReadInt(2)
    mark_clear["HideShow"]     = net.ReadInt(2)
    mark_clear["Flashlight"]  = net.ReadInt(2)
    mark_clear["General"]     = net.ReadInt(2)
    mark_clear["NPCMovement"] = net.ReadInt(2)
    mark_clear["Physics"]     = net.ReadInt(2)
    mark_clear["Shadows"]     = net.ReadInt(2)
    mark_clear["PlayerView"] = net.ReadInt(2)
    mark_clear["Weapons"]     = net.ReadInt(2)
    Defaults()
    mark_clear["Cleanup"]     = backup["Cleanup"]
    mark_clear["HideShow"]     = backup["HideShow"]
    mark_clear["Flashlight"]  = backup["Flashlight"]
    mark_clear["General"]     = backup["General"]
    mark_clear["NPCMovement"] = backup["NPCMovement"]
    mark_clear["Physics"]     = backup["Physics"]
    mark_clear["Shadows"]     = backup["Shadows"]
    mark_clear["PlayerView"] = backup["PlayerView"]
    mark_clear["Weapons"]     = backup["Weapons"]
end)

----------------------------
-- Syncing
----------------------------

-- Gets net "int 2" infos
net.Receive("XMH_SyncValuesInt2",function()
    local value = net.ReadInt(2)
    local command = net.ReadString()
    xmh_commands[command].value = value
    RunConsoleCommand(command, tostring(value))
end)

-- Gets net "int 16" infos
net.Receive("XMH_SyncValuesInt16",function()
    local value = net.ReadInt(16)
    local command = net.ReadString()
    xmh_commands[command].value = value
    RunConsoleCommand(command, tostring(value))
end)

-- Gets net "float" infos
net.Receive("XMH_SyncValuesFloat",function()
    local value = net.ReadFloat()
    local command = net.ReadString()
    xmh_commands[command].value = value
    RunConsoleCommand(command, tostring(value))
end)

-- Doesn't let some options reset at players respawn
net.Receive("XMH_PlayerRespawn",function()
    xmh_commands["xmh_runspeed_var"].value = 500
    xmh_commands["xmh_walkspeed_var"].value = 250
    xmh_commands["xmh_jumpheight_var"].value = 200
    -- Is "ivisible all" set to 1 and you aren't the guy who turned it on? yes = get invisible.
    -- Did you set yourself to be invisible and it's permitted for players OR you are admin? Yes = get invisible.
    if (net.ReadInt(2) == 0 and net.ReadString() != LocalPlayer():Nick()) or 
    (GetConVar("xmh_invisible_var"):GetInt() == 0 and (GetConVar("xmh_make_invisibility_admin_only_var"):GetInt() == 0 or checkAdmin() == true)) then
        net.Start       ("XMH_Invisible")
        net.WriteInt    (0, 2           )
        net.SendToServer(               )
    end
end)

-- This timer syncs our "xmh_" cvars with their menu states and applies the changes to the game
timer.Create("Sync",0.50,0,function()
    if ( xmh_enable_localplayer == 1 ) then
        local current_value, prefix, var_type

        AdminCheck()

        for k,_ in pairs(xmh_commands) do
            prefix = string.Explode("_", k)
            if prefix[1] == "xmh" then -- Is it a "xmh_" var?
                if xmh_commands[k].command_type != "runconsolecommand" then -- Is the type ok?
                    if (xmh_commands[k].cheat == true and GetConVar("sv_cheats"):GetInt() == 1) or xmh_commands[k].cheat == false then -- Is the cheats sittuation ok?
                        if (xmh_commands[k].admin == true and checkAdmin() == true) or xmh_commands[k].admin == false then -- Is admin or user ok?
                            current_value = tonumber(string.format("%.2f", GetConVar(k):GetFloat())) -- Getting the value...
                            if (xmh_commands[k].value != current_value) then -- Are the values different?
                                -- Yes = applying changes...
                                if xmh_commands[k].command_type == "net" then
                                    if xmh_commands[k].var_type == "int2" then
                                        net.Start       (xmh_commands[k].func)
                                        net.WriteString (k                   )
                                        net.WriteInt    (current_value, 2     )
                                        net.SendToServer(                    )
                                    elseif xmh_commands[k].var_type == "int16" then
                                        net.Start       (xmh_commands[k].func)
                                        net.WriteString (k                   )
                                        net.WriteInt    (current_value, 16    )
                                        net.SendToServer(                    )
                                    elseif xmh_commands[k].var_type == "float" then
                                        net.Start       (xmh_commands[k].func)
                                        net.WriteString (k                   )
                                        net.WriteFloat  (current_value        )
                                        net.SendToServer(                    )
                                    end
                                elseif xmh_commands[k].command_type == "function" then
                                    if xmh_commands[k].sub_type == nil then
                                        if xmh_commands[k].category == "Defaults" then
                                            SetSectionsToReset(xmh_commands[k].value2, current_value)
                                        else
                                        xmh_commands[k].func(current_value, k)
                                        end
                                    elseif xmh_commands[k].sub_type == "fix" then
                                        xmh_commands[k].func(xmh_commands[k].real_command, current_value)
                                    end
                                elseif xmh_commands[k].command_type == "hook" then
                                    xmh_commands[k].func(xmh_commands[k].value2, current_value)
                                end
                                xmh_commands[k].value = current_value -- Setting the auxiliar commands[k].value var...
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Force our FOV. It's intrusive on other addons
hook.Add("CalcView", "StartFOVSync", function(ply, origin, angles, fov, znear, zfar)
    if not GetConVar("xmh_fov_unlock_var"):GetBool() and ply:GetViewEntity():GetClass() != "gmod_cameraprop" then return end

    -- Don't control custom camera entities
	if ply:GetViewEntity() != ply and ply:GetViewEntity():GetClass() != "gmod_cameraprop" then return end

    -- Don't control the camera when the player is doing some actions
    if ply:GetViewEntity() == ply and (ply:IsPlayingTaunt() or ply:InVehicle()) then return end

    -- From here I still conflict with addons that change the player's view, and there are many. That's why I created an option
    -- to enable our FOV. So, I'm manually adding to support to 3 addons plus some rare generic cases to make it a little smoother
	if IsValid(ply:GetNWEntity("ScriptedVehicle")) then return end -- Hoverboard, maybe other addons
    if ply.RagdollFightArenaSpectator or ply.RagdollFightArena then return end  -- Ragdoll Fight
    if ply:GetViewEntity().CalcView or ply:GetActiveWeapon().CalcView then return end -- Entities with anexed CalcView, like Advanced Camera

    local view = {
		["origin"] = origin,
		["angles"] = angles,
		["fov"] = fov,
		["znear"] = znear,
		["zfar"] = zfar,
		["drawviewer"] = false,
	}

    -- Set our FOV
    --   Ignore it if the weapon has a CalcView field
    --   Try to ""detect"" weapons with active zoom by modifying the fov only when it's in the default players range
    local weapon = ply:GetActiveWeapon()
    if (not IsValid(weapon) or not weapon.CalcView) and fov >= 75 and fov <= 100 then 
        -- Cameras
        if ply:GetViewEntity():GetClass() == "gmod_cameraprop" then
            view.fov = GetConVar("xmh_camera_fov"):GetInt()
        -- Player
        else
            view.fov = GetConVar("xmh_fov_var"):GetInt()
        end
    end

    return view
end)

-- Avoid calling LocalPlayer() until all entities are loaded
hook.Add("InitPostEntity", "StartSync", function()
	xmh_enable_localplayer = 1
end)

----------------------------
-- Console commands
----------------------------

-- These are used for options that can interact normally/directly with the tool's functions
concommand.Add("xmh_defaults"           , Defaults           )
concommand.Add("xmh_cleardecals"        , ClearDecals        )
concommand.Add("xmh_clearcorpses"       , ClearCorpses       )
concommand.Add("xmh_shadowres"          , ShadowRes          )
concommand.Add("xmh_shadowreschk"       , ShadowResChk       )
concommand.Add("xmh_pedestrians"        , Pedestrians        )
concommand.Add("xmh_repairwindows"      , RepairWindows      )
concommand.Add("xmh_lipsync"            , LipSync            )
concommand.Add("xmh_crosshair"          , HideCrosshair      )
concommand.Add("xmh_checkuncheck"       , CheckUncheck       )
concommand.Add("xmh_forcelanguage"      , forceLanguage      )
concommand.Add("xmh_saveteleport"       , CreateTeleport     )
concommand.Add("xmh_teleporttopos"      , TeleportToPos      )
concommand.Add("xmh_setrespawnpoint"    , SetRespawnPoint    )
concommand.Add("xmh_unsetrespawnpoint"  , UnsetRespawnPoint  )
concommand.Add("xmh_deleteteleportpos"  , DeleteTeleportPos  )
concommand.Add("xmh_dropweapon"         , DropWeapon         )
concommand.Add("xmh_removeweapon"       , RemoveWeapon       )
concommand.Add("xmh_removeprimaryammo"  , RemovePrimaryAmmo  )
concommand.Add("xmh_removesecondaryammo", RemoveSecondaryAmmo)
concommand.Add("xmh_removesecondaryammo", RemoveSecondaryAmmo)
concommand.Add("xmh_givegmweapons"      , GiveGModWeapons    )
concommand.Add("xmh_givehl2weapons"     , GiveHL2Weapons     )
concommand.Add("xmh_clearweaponsitems"  , ClearWeaponsItems  )

----------------------------
-- Panel
----------------------------

local xmh_menu
local sv_cheats_menus = {}

local function UpdateSVCheatsMenus(panelName)
    if not sv_cheats_menus[panelName] then return end

    local sv_cheats = GetConVar("sv_cheats"):GetInt() == 1 and true or false
    local cheat_menus_enabled = sv_cheats_menus[panelName][1]:IsEnabled() and true or false

    if sv_cheats and not cheat_menus_enabled or not sv_cheats and cheat_menus_enabled then
        for k,v in ipairs(sv_cheats_menus[panelName]) do
            v:SetEnabled(sv_cheats)
        end
    end
end

local function SetSVCheatsMenus(pnl)
    local panelName = tostring(pnl)
    sv_cheats_menus[panelName] = {}
    local sv_cheats_menu = sv_cheats_menus[panelName]

    -- Disabled because sometimes menus aren't updated until they are scrolled to the top or they simply don't updated
    --[[
    function pnl:Paint()
        UpdateSVCheatsMenus(panelName)
    end
    ]]

    return sv_cheats_menu
end

local function Cleanup(Panel)
    local sv_cheats_menu = SetSVCheatsMenus(Panel.Header)

    if checkAdmin() == true then
        xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_cleanup_corpses"         ], "xmh_clearcorpses")
        xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_cleanup_corpses_desc"    ])
    end
    xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_cleanup_decals"          ], "xmh_cleardecals")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_cleanup_decals_desc"     ])
    xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_cleanup_decalsmodel"     ], "cl_removedecals")
    xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_cleanup_decalsmodel_desc"])
    xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_cleanup_sounds"          ], "stopsound")
    xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_cleanup_sounds_desc"     ])
    if checkAdmin() == true then
        xmh_menu = Panel:Button   (XMH_LANG[_LANG]["client_menu_cleanup_windows"         ], "xmh_repairwindows")
        xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_cleanup_windows_desc"    ])
        xmh_menu = Panel:Button   (XMH_LANG[_LANG]["client_menu_cleanup_wpnsitems"       ], "xmh_clearweaponsitems")
        xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_cleanup_wpnsitems_desc"  ])
        xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_cleanup_auto"            ], "xmh_cleanup_var")
        xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_cleanup_auto_desc"       ])
    end
end

local function Flashlight(Panel)
    local sv_cheats_menu = SetSVCheatsMenus(Panel.Header)

    xmh_menu = Panel:CheckBox  (XMH_LANG[_LANG]["client_menu_flashlight_lock"           ], "r_flashlightlockposition")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_flashlight_lock_desc"      ])
    xmh_menu = Panel:CheckBox  (XMH_LANG[_LANG]["client_menu_flashlight_brightness"     ], "xmh_fullflashlight_var")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_flashlight_brightness_desc"])
    xmh_menu = Panel:CheckBox  (XMH_LANG[_LANG]["client_menu_flashlight_area"           ], "r_flashlightdrawfrustum")
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_flashlight_area_desc"      ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_flashlight_minr"           ], "r_flashlightnear", 1, 1000, 0)
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_flashlight_minr_desc"      ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_flashlight_maxr"           ], "r_flashlightfar", 1, 10000, 0)
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_flashlight_maxr_desc"      ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_flashlight_fov"            ], "r_flashlightfov", 1, 179, 0)
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_flashlight_fov_desc"       ])
end

local function General(Panel)
    local sv_cheats_menu = SetSVCheatsMenus(Panel.Header)

    xmh_menu = Panel:Button    (XMH_LANG[_LANG]["client_menu_general_editor"       ], "xmh_texteditor")
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_general_editor_desc"  ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_general_fontsize"     ], "xmh_textfont_var", 13, 30, 0)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_general_fontsize_desc"])
    if not game.SinglePlayer() then
        xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_general_lipsync"      ], "xmh_lipsync")
        table.insert(sv_cheats_menu, xmh_menu)
        xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_general_lipsync_desc" ])
    end
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_general_green"        ], "xmh_skybox_var")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_general_green_desc"   ])
    if checkAdmin() == true then
        xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_general_autosave"     ], "xmh_save_var")
        xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_general_autosave_desc"])
    end
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_general_lod"          ], "r_lod", -1, 5, 0)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_general_lod_desc"     ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_general_pupil"        ], "r_eyesize", -0.5, 0.5, 2)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_general_pupil_desc"   ])
end

local function HideShow(Panel)
    local sv_cheats_menu = SetSVCheatsMenus(Panel.Header)

    xmh_menu = Panel:Button   (XMH_LANG[_LANG]["client_menu_display_crosshair"        ], "xmh_crosshair")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_crosshair_desc"   ]                 )
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_wvmodels"         ], "xmh_viewmodel_var")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_wvmodels_desc"    ])
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_vmodels"          ], "r_drawviewmodel")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_vmodels_desc"     ])
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_invisible"        ], "xmh_invisible_var")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_invisible_desc"   ])
    if checkAdmin() == true and not game.SinglePlayer() then
        xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_invisibleall"     ], "xmh_invisibleall_var")
        xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_invisibleall_desc"])
    end
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_tgun"             ], "xmh_toolgun_var" )
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_tgun_desc"        ])
    if checkAdmin() == true then
        xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_tgunsound"        ], "xmh_toolgunmute_var" )
        xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_tgunsound_desc"   ])
    end
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_pgun"             ], "xmh_physgun_var")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_pgun_desc"        ])
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_errors"           ], "xmh_error_var")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_errors_desc"      ])
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_misc"             ], "xmh_weapammitem_var")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_misc_desc"        ])
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_voicen"           ], "xmh_chatvoice_var")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_voicen_desc"      ])
    if checkAdmin() == true then
        if not game.SinglePlayer() then
            xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_voicei"           ], "xmh_voiceicons_var")
            table.insert(sv_cheats_menu, xmh_menu)
            xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_voicei_desc"      ])
        end
        xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_foot"             ], "xmh_footsteps_var")
        table.insert(sv_cheats_menu, xmh_menu)
        xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_foot_desc"        ])
    end
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_decmod"           ], "r_drawmodeldecals")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_decmod_desc"      ])
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_particles"        ], "r_drawparticles")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_particles_desc"   ])
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_3dskybox"         ], "r_3dsky")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_3dskybox_desc"    ])
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_water"            ], "cl_show_splashes")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_water_desc"       ])
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_ropes"            ], "r_drawropes")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_ropes_desc"       ])
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_laser"            ], "r_DrawBeams")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_laser_desc"       ])
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_display_ents"             ], "r_drawentities")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_display_ents_desc"        ])
    if checkAdmin() == true then
        xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_display_corpses"          ], "xmh_corpses_var", 0, 200, 0)
        xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_display_corpses_desc"     ])
    end
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_display_deathn"           ], "hud_deathnotice_time", 0, 12, 0)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_display_deathn_desc"      ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_display_bchat"            ], "hud_saytext_time", 0, 24, 0)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_display_bchat_desc"       ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_display_decals"           ], "xmh_decals_var", 1, 5096, 0)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_display_decals_desc"      ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_display_detail"           ], "cl_detaildist", 0, 20000, 0)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_display_detail_desc"      ])
end

local function Informations(Panel)
    Panel:Help            ("Xala's Movie Helper"                             )
    if checkAdmin() == true then
        Panel:ControlHelp (XMH_LANG[_LANG]["client_menu_info_admin_on"       ])
    else
        Panel:ControlHelp (XMH_LANG[_LANG]["client_menu_info_admin_off"      ])
    end
    Panel:Help            (XMH_LANG[_LANG]["client_menu_info_sv_cheats_msg"  ])
    Panel:ControlHelp     (XMH_LANG[_LANG]["client_menu_info_sv_cheats_desc" ])
    Panel:Help            (""                                                )
    Panel:Help            (XMH_LANG[_LANG]["client_menu_info_tags"           ])
    if checkAdmin() == true then
        Panel:ControlHelp (XMH_LANG[_LANG]["client_menu_info_tags_desc_admin"])
    else
        Panel:ControlHelp (XMH_LANG[_LANG]["client_menu_info_tags_desc_ply"  ])
    end
    Panel:Help            (XMH_LANG[_LANG]["client_menu_info_tags_1"         ])
    Panel:Help            (XMH_LANG[_LANG]["client_menu_info_tags_2"         ])
    if checkAdmin() == true then
        Panel:Help        (XMH_LANG[_LANG]["client_menu_info_tags_3"         ])
    end
    Panel:Help            (XMH_LANG[_LANG]["client_menu_info_tags_4"         ])
    Panel:Help            (XMH_LANG[_LANG]["client_menu_info_tags_5"         ])
    Panel:Help            (XMH_LANG[_LANG]["client_menu_info_tags_6"         ])
    Panel:Help            (XMH_LANG[_LANG]["client_menu_info_tags_7"         ])
    Panel:Help            (""                                                )
    Panel:Help            (XMH_LANG[_LANG]["client_menu_info_hint_1"         ])
    Panel:Help            (XMH_LANG[_LANG]["client_menu_info_hint_2"         ])
    Panel:Help            (""                                                )
    Panel:Help            (Revision                                          )
    Panel:ControlHelp     (XMH_LANG[_LANG]["client_menu_info_credits"        ])
end

local function NPCMovement(Panel)
    local sv_cheats_menu = SetSVCheatsMenus(Panel.Header)

    xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_npcmov_select"             ], "npc_select")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_npcmov_select_desc"        ])
    xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_npcmov_move"               ], "npc_go")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_npcmov_move_desc"          ])
    if checkAdmin() == true then
        xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_npcmov_run"                ], "xmh_npcwalkrun_var") -- Bug: npc_go_do_run allways returns 1...
        table.insert(sv_cheats_menu, xmh_menu)
        xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_npcmov_run_desc"           ])
    end
    xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_npcmov_random"             ], "npc_go_random")
    xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_npcmov_random_desc"        ])
    if checkAdmin() == true and game.SinglePlayer() then
        xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_npcmov_turnpedestrian"     ], "xmh_pedestrians" )
        xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_npcmov_turnpedestrian_desc"])
    end
    Panel:Help("________________________________")
    if checkAdmin() == true then
        Panel:Help                (XMH_LANG[_LANG]["client_menu_npcmov_mov_msg"            ])
        xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_npcmov_ai_disabled"        ], "xmh_aidisabled_var")
        table.insert(sv_cheats_menu, xmh_menu)
        xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_npcmov_ai_disabled_desc"   ])
        xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_npcmov_ai_disable"         ], "xmh_aidisable_var")
        table.insert(sv_cheats_menu, xmh_menu)
        xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_npcmov_ai_disable_desc"    ])
    else
        Panel:Help(XMH_LANG[_LANG]["client_menu_npcmov_note"])
    end
end

local function Physics(Panel)
    local sv_cheats_menu = SetSVCheatsMenus(Panel.Header)

    if checkAdmin() == true then
        xmh_menu = Panel:CheckBox  (XMH_LANG[_LANG]["client_menu_physics_motion"       ], "xmh_mode_var")
        table.insert(sv_cheats_menu, xmh_menu)
        xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_physics_motion_desc"  ])
        xmh_menu = Panel:CheckBox  (XMH_LANG[_LANG]["client_menu_physics_fall"         ], "xmh_falldamage_var")
        table.insert(sv_cheats_menu, xmh_menu)
        xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_physics_fall_desc"    ])
        xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_physics_time"         ], "xmh_timescale_var", 0.06, 2.99, 2)
        table.insert(sv_cheats_menu, xmh_menu)
        xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_physics_time_desc"    ])
        xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_physics_push"         ], "xmh_knockback_var", -9999, 9999, 0)
        table.insert(sv_cheats_menu, xmh_menu)
        xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_physics_push_desc"    ])
    end
        xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_physics_pgunf"        ], "physgun_wheelspeed", 0, 100, 0)
        xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_physics_pgunf_desc"   ])
    if checkAdmin() == true then
        xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_physics_throw"        ], "xmh_throwforce_var", 0, 20000, 0)
        table.insert(sv_cheats_menu, xmh_menu)
        xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_physics_throw_desc"   ])
        xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_physics_noclip"       ], "xmh_noclipspeed_var", 1, 300, 0)
        table.insert(sv_cheats_menu, xmh_menu)
        xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_physics_noclip_desc"  ])
    end
        xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_physics_walk"         ], "xmh_walkspeed_var", 1, 10000, 0)
        xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_physics_walk_desc"    ])
        xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_physics_run"          ], "xmh_runspeed_var", 1, 10000, 0)
        xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_physics_run_desc"     ])
        xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_physics_jump"         ], "xmh_jumpheight_var", 0, 4000, 0)
        xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_physics_jump_desc"    ])
    if checkAdmin() == true then
        xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_physics_friction"     ], "xmh_wfriction_var", -20, 50, 0)
        xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_physics_friction_desc"])
    end
end

local function PlayerView(Panel)
    local sv_cheats_menu = SetSVCheatsMenus(Panel.Header)
    local DCollapsible

    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_playerview_shake"        ], "xmh_shake_var")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_shake_desc"   ])

    Panel:Help("")
    DCollapsible = vgui.Create("DCollapsibleCategory", Panel)
    DCollapsible:SetLabel(XMH_LANG[_LANG]["client_menu_playerview_fov_section"])
    DCollapsible:Dock(TOP)

    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_playerview_vfov"         ], "viewmodel_fov", 0, 360, 0)
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_vfov_desc"    ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_playerview_cfov"         ], "xmh_camera_fov", 1, 359, 0)
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_cfov_desc"    ])
    xmh_menu = Panel:CheckBox  (XMH_LANG[_LANG]["client_menu_playerview_fov_unlock"   ], "xmh_fov_unlock_var")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_fov_unlock_desc" ])
    Panel:ControlHelp          (XMH_LANG[_LANG]["client_menu_playerview_fov_unlock_notes"])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_playerview_fov"          ], "xmh_fov_var", 1, 359, 0)
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_fov_desc"     ])

    Panel:Help("")
    DCollapsible = vgui.Create("DCollapsibleCategory", Panel)
    DCollapsible:SetLabel(XMH_LANG[_LANG]["client_menu_playerview_thirdp_section"])
    DCollapsible:Dock(TOP)

    xmh_menu = Panel:CheckBox  (XMH_LANG[_LANG]["client_menu_playerview_enable"            ], "xmh_person_var")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_enable_desc"       ])
    xmh_menu = Panel:CheckBox  (XMH_LANG[_LANG]["client_menu_playerview_info"              ], "cam_showangles")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_info_desc"         ])
    xmh_menu = Panel:CheckBox  (XMH_LANG[_LANG]["client_menu_playerview_colision"          ], "cam_collision")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_colision_desc"     ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_playerview_distance"          ], "cam_idealdist", 30, 200, 0)
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_distance_desc"     ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_playerview_cam_downup"        ], "cam_idealdistup", -120, 120, 0)
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_cam_downup_desc"   ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_playerview_cam_leftright"     ], "cam_idealdistright", -200, 200, 0)
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_cam_leftright_desc"])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_playerview_ang_downup"        ], "cam_idealpitch", 0, 90, 0)
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_ang_downup_desc"   ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_playerview_and_leftright"     ], "cam_idealyaw", -135, 135, 0)
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_and_leftright_desc"])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_playerview_spinvel"           ], "cam_ideallag", 0, 6000, 0)
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_playerview_spinvel_desc"      ])
end

local function Shadows(Panel)
    local sv_cheats_menu = SetSVCheatsMenus(Panel.Header)

    local resolution = XMH_LANG[_LANG]["client_menu_shadows_res_p1"]..GetConVar("r_flashlightdepthres"):GetInt()..XMH_LANG[_LANG]["client_menu_shadows_res_p2"]
    xmh_menu = Panel:Button(XMH_LANG[_LANG]["client_menu_shadows_res_desc"       ], "xmh_shadowreschk")
    xmh_menu:SetTooltip(resolution)
    shadows_combobox = Panel:ComboBox(XMH_LANG[_LANG]["client_menu_shadows_combo"])
    shadows_combobox:AddChoice("1024 x 1024", "1024")
    shadows_combobox:AddChoice("2048 x 2048", "2048")
    shadows_combobox:AddChoice("4096 x 4096", "4096")
    shadows_combobox:AddChoice("8192 x 8192", "8192")
    xmh_menu = Panel:Button    (XMH_LANG[_LANG]["client_menu_shadows_change"         ], "xmh_shadowres")
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_shadows_change_desc"    ])
    Panel:ControlHelp          (XMH_LANG[_LANG]["client_menu_shadows_notes"          ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_shadows_bleeding"       ], "mat_slopescaledepthbias_shadowmap", 1, 16, 0)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_shadows_bleeding_desc"  ])
    xmh_menu = Panel:NumSlider (XMH_LANG[_LANG]["client_menu_shadows_blur"           ], "r_projectedtexture_filter", 0, 20, 2)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_shadows_blur_desc"      ])
    xmh_menu = Panel:CheckBox  (XMH_LANG[_LANG]["client_menu_shadows_brightness"     ], "mat_fullbright")
    table.insert(sv_cheats_menu, xmh_menu)
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_shadows_brightness_desc"])
    xmh_menu = Panel:CheckBox  (XMH_LANG[_LANG]["client_menu_shadows_match"          ], "r_shadowrendertotexture")
    xmh_menu:SetTooltip        (XMH_LANG[_LANG]["client_menu_shadows_match_desc"     ])
end

local function Position(Panel)
    Panel:Help("")
    DCollapsible = vgui.Create("DCollapsibleCategory", Panel)
    DCollapsible:SetLabel(XMH_LANG[_LANG]["client_menu_position_section1"])
    DCollapsible:Dock(TOP)

    Panel:TextEntry         (XMH_LANG[_LANG]["client_menu_position_name"       ], "xmh_positionname_var")
    xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_position_save"       ], "xmh_saveteleport")
    xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_position_save_desc"  ])
    Panel:Help              ("")
    teleport_combobox = Panel:ComboBox(XMH_LANG[_LANG]["client_menu_position_destination"])
    LoadTeleports()
    xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_position_delete"     ], "xmh_deleteteleportpos")
    xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_position_delete_desc"])
    xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_position_go"         ], "xmh_teleporttopos")
    xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_position_go_desc"    ])

    Panel:Help("")
    DCollapsible = vgui.Create("DCollapsibleCategory", Panel)
    DCollapsible:SetLabel(XMH_LANG[_LANG]["client_menu_position_section2"])
    DCollapsible:Dock(TOP)

    xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_position_respawn"           ], "xmh_setrespawnpoint")
    xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_position_respawn_desc"      ])
    xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_position_respawn_clear"     ], "xmh_unsetrespawnpoint")
    xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_position_respawn_clear_desc"])
end

local function Weapons(Panel)
    if checkAdmin() == true and not game.SinglePlayer() then
        xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_weapons_plyall"        ], "xmh_editweaponsallplys_var")
        xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_weapons_plyall_desc"   ])
    end
    Panel:Help                ("")
    xmh_menu = Panel:Button   (XMH_LANG[_LANG]["client_menu_weapons_drop"          ], "xmh_dropweapon")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_weapons_drop_desc"     ])
    xmh_menu = Panel:Button   (XMH_LANG[_LANG]["client_menu_weapons_remove"        ], "xmh_removeweapon")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_weapons_remove_desc"   ])
    xmh_menu = Panel:Button   (XMH_LANG[_LANG]["client_menu_weapons_dropammop"     ], "xmh_removeprimaryammo")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_weapons_dropammop_desc"])
    xmh_menu = Panel:Button   (XMH_LANG[_LANG]["client_menu_weapons_dropammos"     ], "xmh_removesecondaryammo")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_weapons_dropammop_desc"])
    xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_weapons_all"           ], "xmh_editallweapons_var")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_weapons_all_desc"      ])
    Panel:Help                ("")
    xmh_menu = Panel:Button   (XMH_LANG[_LANG]["client_menu_weapons_givegm"        ], "xmh_givegmweapons")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_weapons_givegm_desc"   ])
    xmh_menu = Panel:Button   (XMH_LANG[_LANG]["client_menu_weapons_givehl2"       ], "xmh_givehl2weapons")
    xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_weapons_givehl2_desc"  ])
end

local function Defaults(Panel)
    Panel:Button             (XMH_LANG[_LANG]["client_menu_defaults_select_"          ], "xmh_checkuncheck")
    Panel:CheckBox           (XMH_LANG[_LANG]["client_populate_menu_section2"         ], "xmh_clcleanup_var")
    Panel:CheckBox           (XMH_LANG[_LANG]["client_populate_menu_section4"         ], "xmh_clfl_var")
    Panel:CheckBox           (XMH_LANG[_LANG]["client_populate_menu_section5"         ], "xmh_clgeneral_var")
    Panel:CheckBox           (XMH_LANG[_LANG]["client_populate_menu_section6"         ], "xmh_clnpcmove_var")
    if checkAdmin() == true then
        Panel:CheckBox       (XMH_LANG[_LANG]["client_populate_menu_section7"         ], "xmh_clphysics_var")
    end
    Panel:CheckBox           (XMH_LANG[_LANG]["client_populate_menu_section10"        ], "xmh_cltp_var")
    Panel:CheckBox           (XMH_LANG[_LANG]["client_populate_menu_section8"         ], "xmh_clshadows_var")
    Panel:CheckBox           (XMH_LANG[_LANG]["client_populate_menu_section3"         ], "xmh_cldisplay_var")
    Panel:CheckBox           (XMH_LANG[_LANG]["client_populate_menu_section12"        ], "xmh_clweapons_var")
    if checkAdmin() == false then
        xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_defaults_set_ply"           ], "xmh_defaults")
        xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_defaults_set_ply_desc"      ])
    elseif checkAdmin() == true then
        xmh_menu = Panel:Button (XMH_LANG[_LANG]["client_menu_defaults_set_admin"         ], "xmh_defaults")
        xmh_menu:SetTooltip     (XMH_LANG[_LANG]["client_menu_defaults_set_admin_desc"    ])
        if not game.SinglePlayer() then
            xmh_menu = Panel:CheckBox (XMH_LANG[_LANG]["client_menu_defaults_set_admin_all"     ], "xmh_defaultsall_var")
            xmh_menu:SetTooltip       (XMH_LANG[_LANG]["client_menu_defaults_set_admin_all_desc"])
        end
    end
end

hook.Add("PopulateToolMenu", "All hail the menus", function ()
    spawnmenu.AddToolMenuOption("Utilities", "Xala's Movie Helper", XMH_LANG[_LANG]["client_populate_menu_section1"] , XMH_LANG[_LANG]["client_populate_menu_section1"] , "", "", Informations)
    spawnmenu.AddToolMenuOption("Utilities", "Xala's Movie Helper", XMH_LANG[_LANG]["client_populate_menu_section2"] , XMH_LANG[_LANG]["client_populate_menu_section2"] , "", "", Cleanup     )
    spawnmenu.AddToolMenuOption("Utilities", "Xala's Movie Helper", XMH_LANG[_LANG]["client_populate_menu_section3"] , XMH_LANG[_LANG]["client_populate_menu_section3"] , "", "", HideShow  )
    spawnmenu.AddToolMenuOption("Utilities", "Xala's Movie Helper", XMH_LANG[_LANG]["client_populate_menu_section4"] , XMH_LANG[_LANG]["client_populate_menu_section4"] , "", "", Flashlight  )
    spawnmenu.AddToolMenuOption("Utilities", "Xala's Movie Helper", XMH_LANG[_LANG]["client_populate_menu_section5"] , XMH_LANG[_LANG]["client_populate_menu_section5"] , "", "", General     )
    spawnmenu.AddToolMenuOption("Utilities", "Xala's Movie Helper", XMH_LANG[_LANG]["client_populate_menu_section6"] , XMH_LANG[_LANG]["client_populate_menu_section6"] , "", "", NPCMovement )
    spawnmenu.AddToolMenuOption("Utilities", "Xala's Movie Helper", XMH_LANG[_LANG]["client_populate_menu_section7"] , XMH_LANG[_LANG]["client_populate_menu_section7"] , "", "", Physics     )
    spawnmenu.AddToolMenuOption("Utilities", "Xala's Movie Helper", XMH_LANG[_LANG]["client_populate_menu_section8"] , XMH_LANG[_LANG]["client_populate_menu_section8"] , "", "", Shadows     )
    spawnmenu.AddToolMenuOption("Utilities", "Xala's Movie Helper", XMH_LANG[_LANG]["client_populate_menu_section9"] , XMH_LANG[_LANG]["client_populate_menu_section9"] , "", "", Position    )
    spawnmenu.AddToolMenuOption("Utilities", "Xala's Movie Helper", XMH_LANG[_LANG]["client_populate_menu_section10"], XMH_LANG[_LANG]["client_populate_menu_section10"], "", "", PlayerView )
    spawnmenu.AddToolMenuOption("Utilities", "Xala's Movie Helper", XMH_LANG[_LANG]["client_populate_menu_section12"], XMH_LANG[_LANG]["client_populate_menu_section12"], "", "", Weapons     )
    spawnmenu.AddToolMenuOption("Utilities", "Xala's Movie Helper", XMH_LANG[_LANG]["client_populate_menu_section11"], XMH_LANG[_LANG]["client_populate_menu_section11"], "", "", Defaults    )
end)
