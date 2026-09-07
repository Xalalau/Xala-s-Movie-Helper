-- Isolated tests of the actual client files. These mocks are not the GMod engine.
local root, sourceRoot = assert(arg[1]), assert(arg[2])
local passed, failed = 0, 0
local function check(name, callback)
    local ok, err = pcall(callback)
    if ok then
        passed = passed + 1
        print("PASS " .. name)
    else
        failed = failed + 1
        print("FAIL " .. name .. ": " .. tostring(err))
    end
end
local function equal(actual, expected)
    assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function contains(text, expected)
    assert(type(text) == "string" and text:find(expected, 1, true), "missing: " .. expected)
end
local function loadWithEnv(path, env)
    local fn, err
    if setfenv then
        fn, err = loadfile(path)
        if fn then setfenv(fn, env) end
    else
        fn, err = loadfile(path, "t", env)
    end
    assert(fn, err)
    return fn()
end

for _, path in ipairs({"autorun/xmh_init.lua", "xmh/language.lua",
    "xmh/client/commands_table.lua", "xmh/client/xmh_cl.lua", "xmh/client/modules/xmhtext.lua"}) do
    check("syntax: " .. path, function()
        local fn, err = loadfile(root .. "/lua/" .. path)
        assert(fn, err)
    end)
end

local function newClient(language, useLoader)
    local e = setmetatable({}, {__index = _G})
    e._G = e
    e._LANG = language or "en"
    e.SERVER, e.CLIENT = false, true
    e.xmh_lang_file, e.xmh_teleports_file = "xmh/language.txt", "xmh/teleports/test.txt"
    e.commands, e.dialogs, e.output, e.menus = {}, {}, {}, {}
    e.hooks, e.timers, e.receivers, e.console = {}, {}, {}, {}
    e.vars = {}
    local function convar(name, default)
        if e.vars[name] then return e.vars[name] end
        local v = {value = tostring(default or 0)}
        function v:GetInt() return math.floor(tonumber(self.value) or 0) end
        function v:GetFloat() return tonumber(self.value) or 0 end
        function v:GetBool() return self:GetFloat() ~= 0 end
        function v:GetString() return self.value end
        e.vars[name] = v
        return v
    end
    e.GetConVar = function(name) return convar(name) end
    e.CreateClientConVar = convar
    e.GetConVarString = function(name)
        return name == "gmod_language" and e._LANG or convar(name):GetString()
    end
    convar("sv_cheats", 1)
    convar("r_flashlightdepthres", 1024)
    convar("r_shadowrendertotexture", 1)
    e.print = function(...)
        local args = {...}
        for i = 1, select("#", ...) do args[i] = tostring(args[i]) end
        e.output[#e.output + 1] = table.concat(args, "\t")
    end
    e.Derma_Message = function(text, title, button)
        assert(type(text) == "string", "missing dialog translation")
        e.dialogs[#e.dialogs + 1] = {text = text, title = title, button = button}
        return {valid = true}
    end
    e.RunConsoleCommand = function(command, value)
        assert(type(command) == "string" and not tonumber(command), "Unknown command: " .. tostring(command))
        assert(command ~= "showconsole" and command ~= "r_shadowrendertotexture", "Command is blocked! (" .. command .. ")")
        e.commands[#e.commands + 1] = {command, value}
        if e.vars[command] then e.vars[command].value = tostring(value) end
    end
    e.IsValid = function(obj) return type(obj) == "table" and obj.valid == true end
    e.ply = {valid = true, admin = true}
    function e.ply:IsValid() return self.valid end
    function e.ply:IsAdmin() return self.admin end
    function e.ply:IsSuperAdmin() return self.admin end
    function e.ply:GetClass() return "player" end
    function e.ply:GetViewEntity() return e.viewEntity or self end
    function e.ply:GetActiveWeapon() return e.weapon end
    function e.ply:GetNWEntity() return {valid = false} end
    function e.ply:IsPlayingTaunt() return false end
    function e.ply:InVehicle() return false end
    e.weapon = {valid = true}
    e.LocalPlayer = function() return e.ply end
    e.file = {Exists = function() return false end, CreateDir = function() end}
    e.game = {SinglePlayer = function() return true end, GetMap = function() return "gm_test" end}
    e.resource = {AddFile = function() end}
    e.vgui = {Register = function() end}
    e.AddCSLuaFile = function(path)
        if path then
            local f = assert(io.open(root .. "/lua/" .. path, "rb"))
            f:close()
        end
    end
    e.hook = {Add = function(name, id, fn)
        e.hooks[name] = e.hooks[name] or {}
        e.hooks[name][id] = fn
    end, Remove = function() end}
    e.timer = {Create = function(name, _, _, fn) e.timers[name] = fn end,
        Destroy = function() end, Remove = function() end, Simple = function() end}
    e.net = {Receive = function(name, fn) e.receivers[name] = fn end,
        Start = function() end, WriteString = function() end, WriteInt = function() end,
        WriteFloat = function() end, SendToServer = function() end}
    e.concommand = {Add = function(name, fn) e.console[name] = fn end}
    e.spawnmenu = {AddToolMenuOption = function(_, _, id, _, _, _, fn) e.menus[id] = fn end}
    e.string = setmetatable({}, {__index = string})
    e.string.Explode = function(separator, text)
        local result, start = {}, 1
        while true do
            local pos = text:find(separator, start, true)
            if not pos then result[#result + 1] = text:sub(start); break end
            result[#result + 1] = text:sub(start, pos - 1)
            start = pos + #separator
        end
        return result
    end
    e.include = function(path) return loadWithEnv(root .. "/lua/" .. path, e) end
    if useLoader then
        e.include("autorun/xmh_init.lua")
    else
        e.include("xmh/language.lua")
        e.include("xmh/client/xmh_cl.lua")
    end
    e.hooks.PopulateToolMenu["All hail the menus"]()
    function e:set(name, value) self.GetConVar(name).value = tostring(value) end
    function e:run(name) return assert(self.console[name], name)(self.ply, name, {}, "") end
    function e:sync()
        self.hooks.InitPostEntity.StartSync()
        self.timers.Sync()
    end
    function e:calcView()
        return self.hooks.CalcView.StartFOVSync(self.ply, {}, {}, 90, 1, 10000)
    end
    return e
end

local function panelFor(e, section)
    local panel = {Header = {valid = true}, controls = {}, help = {}}
    local function control(kind, label, command)
        local c = {kind = kind, label = label, command = command, valid = true, choices = {}}
        function c:SetTooltip(text) self.tooltip = text end
        function c:SetEnabled(value) self.enabled = value end
        function c:IsEnabled() return self.enabled ~= false end
        function c:AddChoice(text, data, selected)
            self.choices[#self.choices + 1] = {text, data}
            if selected then self.selected = #self.choices end
            return #self.choices
        end
        function c:GetSelected()
            local entry = self.choices[self.selected]
            if entry then return entry[1], entry[2] end
        end
        function c:ChooseOptionID(id) self.selected = id end
        if command then c.DoClick = function() e.RunConsoleCommand(command) end end
        panel.controls[#panel.controls + 1] = c
        return c
    end
    function panel:Button(label, command) return control("button", label, command) end
    function panel:CheckBox(label, command) return control("checkbox", label, command) end
    function panel:NumSlider(label, command) return control("slider", label, command) end
    function panel:ComboBox(label, command) return control("combo", label, command) end
    function panel:Help(text) self.help[#self.help + 1] = text end
    function panel:ControlHelp(text) self:Help(text) end
    local title = e.XMH_LANG[e._LANG]["client_populate_menu_section" .. section]
    assert(e.menus[title], title)(panel)
    return panel
end
local function findControl(panel, kind, label)
    for _, c in ipairs(panel.controls) do
        if c.kind == kind and (not label or c.label == label) then return c end
    end
    error("missing " .. kind .. ": " .. tostring(label))
end
local function shadowPanel(e) return panelFor(e, "8") end

for _, language in ipairs({"en", "pt-BR"}) do
    for command, key in pairs({xmh_pedestrians = "pedestrians", xmh_lipsync = "lipsync", xmh_crosshair = "crosshair"}) do
        check(language .. ": " .. command .. " keeps instructions without showconsole", function()
            local e = newClient(language)
            e:run(command)
            equal(#e.commands, 0)
            equal(#e.dialogs, 1)
            equal(e.dialogs[1].text, e.XMH_LANG[language]["client_func_" .. key])
            contains(table.concat(e.output, "\n"), e.dialogs[1].text)
        end)
    end
    check(language .. ": shadow resolution report uses current value", function()
        local e = newClient(language)
        e:set("r_flashlightdepthres", 4096)
        e:run("xmh_shadowreschk")
        equal(#e.commands, 0)
        equal(#e.dialogs, 1)
        equal(e.dialogs[1].text, e.XMH_LANG[language].client_func_shadowres .. "4096x4096")
    end)
    check(language .. ": Shadows panel never binds the blocked CVar", function()
        local e = newClient(language)
        for _, c in ipairs(shadowPanel(e).controls) do
            if c.command == "r_shadowrendertotexture" then
                -- Reproduce Derma's ConVarStringThink -> SetValue write-back.
                e.RunConsoleCommand(c.command, "1")
            end
        end
    end)
    check(language .. ": manual shadows action shows commands and live value", function()
        local e = newClient(language)
        local button = findControl(shadowPanel(e), "button", e.XMH_LANG[language].client_menu_shadows_match)
        e:set("r_shadowrendertotexture", 0)
        button:DoClick()
        equal(#e.commands, 0)
        equal(#e.dialogs, 1)
        contains(e.dialogs[1].text, "r_shadowrendertotexture 1")
        contains(e.dialogs[1].text, "r_shadowrendertotexture 0")
        contains(e.dialogs[1].text, language == "en" and "Current value: 0" or "Valor atual: 0")
    end)
    for _, cheats in ipairs({0, 1}) do
        check(language .. ": Defaults skips manual shadows with sv_cheats " .. cheats, function()
            local e = newClient(language)
            e:set("sv_cheats", cheats)
            e:set("r_shadowrendertotexture", 0)
            e:run("xmh_defaults")
            equal(e.GetConVar("r_shadowrendertotexture"):GetInt(), 0)
            equal(#e.commands, 0)
        end)
    end
    check(language .. ": shadow command before opening its panel is safe", function()
        local e = newClient(language)
        e:run("xmh_shadowres")
        equal(#e.commands, 0)
        equal(#e.dialogs, 1)
        equal(e.dialogs[1].text, e.XMH_LANG[language].client_menu_shadows_select_resolution)
        equal(#e.output, 0)
    end)
    check(language .. ": client loader resolves the shipped module case", function()
        local e = newClient(language, true)
        assert(e.console.xmh_texteditor)
        assert(e.console.xmh_shadowreschk)
    end)
end

for _, value in ipairs({178, 100}) do
    check("FOV " .. value .. " is not a console command and still reaches CalcView", function()
        local e = newClient()
        e:set("xmh_fov_unlock_var", 1)
        -- Force a changed cached value for the original function-dispatch path.
        if e.xmh_commands.xmh_fov_var.value then e.xmh_commands.xmh_fov_var.value = 90 end
        e:set("xmh_fov_var", value)
        e:sync()
        equal(#e.commands, 0)
        equal(e:calcView().fov, value)
    end)
end
check("FOV returns to Defaults without dispatching 100 as a command", function()
    local e = newClient()
    e:set("xmh_fov_var", 178)
    if e.xmh_commands.xmh_fov_var.value then e.xmh_commands.xmh_fov_var.value = 178 end
    e:run("xmh_defaults")
    equal(e.GetConVar("xmh_fov_var"):GetInt(), 100)
    e:sync()
    for _, command in ipairs(e.commands) do equal(command[1], "xmh_fov_var") end
end)
check("FOV stays inactive when the existing opt-in is off", function()
    local e = newClient()
    e:set("xmh_fov_var", 178)
    equal(e:calcView(), nil)
end)
check("camera FOV remains independent of the general FOV", function()
    local e = newClient()
    e.viewEntity = {valid = true, GetClass = function() return "gmod_cameraprop" end}
    e:set("xmh_fov_var", 178)
    e:set("xmh_camera_fov", 80)
    equal(e:calcView().fov, 80)
end)
check("existing flashlight proxy still sends command then value", function()
    local e = newClient()
    e:set("xmh_fullflashlight_var", 1)
    e:sync()
    equal(#e.commands, 1)
    equal(e.commands[1][1], "r_flashlightconstant")
    equal(tonumber(e.commands[1][2]), 1) -- Lua 5.3 may stringify this as "1.0".
end)

for _, size in ipairs({"1024", "2048", "4096", "8192"}) do
    check("shadow selection initially reflects current resolution " .. size, function()
        local e = newClient()
        e:set("r_flashlightdepthres", size)
        local combo = findControl(shadowPanel(e), "combo")
        local _, data = combo:GetSelected()
        equal(data, size)
        e:run("xmh_shadowres")
        equal(#e.commands, 0)
        equal(#e.dialogs, 0)
        equal(#e.output, 0)
    end)
    check("shadow apply sends numeric data only: " .. size, function()
        local e = newClient()
        local combo = findControl(shadowPanel(e), "combo")
        e:set("r_flashlightdepthres", 512)
        for id, entry in ipairs(combo.choices) do
            if entry[2] == size then combo:ChooseOptionID(id) end
        end
        e:run("xmh_shadowres")
        equal(#e.commands, 1)
        equal(e.commands[1][1], "r_flashlightdepthres")
        equal(e.commands[1][2], size)
        equal(e.opt, nil)
        equal(#e.output, 0)
        e:run("xmh_shadowres")
        equal(#e.commands, 1)
    end)
end
check("custom initial shadow resolution is not silently overwritten", function()
    local e = newClient()
    e:set("r_flashlightdepthres", 512)
    shadowPanel(e)
    e:run("xmh_shadowres")
    equal(#e.commands, 0)
    equal(#e.dialogs, 1)
    equal(e.GetConVar("r_flashlightdepthres"):GetInt(), 512)
end)
check("removed shadow panel is handled without a NULL access", function()
    local e = newClient()
    local combo = findControl(shadowPanel(e), "combo")
    combo.valid = false
    e:run("xmh_shadowres")
    equal(#e.commands, 0)
    equal(#e.dialogs, 1)
    equal(#e.output, 0)
end)
for _, data in ipairs({"2048 x 2048", "0", "16384", 2048}) do
    check("invalid shadow option is rejected: " .. tostring(data), function()
        local e = newClient()
        local combo = findControl(shadowPanel(e), "combo")
        combo:AddChoice("Invalid resolution", data, true)
        e:run("xmh_shadowres")
        equal(#e.commands, 0)
        equal(#e.dialogs, 1)
    end)
end
check("server-distributed text editor path exists with exact casing", function()
    local f = assert(io.open(sourceRoot .. "/lua/autorun/xmh_init.lua", "rb"))
    local text = f:read("*a"); f:close()
    for path in text:gmatch('AddCSLuaFile%("([^"]+)"') do
        local included = assert(io.open(sourceRoot .. "/lua/" .. path, "rb"), path)
        included:close()
    end
end)
check("Information panel displays revision 25.6 and release date", function()
    local e = newClient()
    local panel = panelFor(e, "1")
    contains(table.concat(panel.help, "\n"), "XMH.Rev.25.6 - 07/09/2026 (dd/mm/yyyy)")
end)

print(string.format("\nRESULT: %d passed, %d failed", passed, failed))
if failed > 0 then os.exit(1) end
