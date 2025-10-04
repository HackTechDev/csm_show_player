-- Luanti / Minetest Client-Side Mod
-- Mod: show_player
-- v7: Journalise explicitement les commandes **locales** (.sp / .show_player),
--     en plus des hooks (register_on_sending_chat_message / monkey-patch) pour
--     les messages réellement envoyés (ex: commandes "/").

-- =========================
-- Config
-- =========================
local MAX_HISTORY_CMDS = 200

-- =========================
-- State
-- =========================
local cmd_history = {} -- { {time=..., raw="/teleport 0,0,0", prefix="/", name="teleport", args="0,0,0"}, ... }

-- =========================
-- Utils
-- =========================
local function safe_get_player_names()
    if minetest.get_player_names then
        local ok, result = pcall(minetest.get_player_names)
        if ok and type(result) == "table" then
            return result
        end
    end
    return {}
end

local function now_string()
    local ok, str = pcall(function() return os.date("%Y-%m-%d %H:%M:%S") end)
    if ok and type(str) == "string" then
        return str
    end
    if minetest and minetest.get_us_time then
        return "t+" .. tostring(minetest.get_us_time())
    end
    return "<now>"
end

local function trim_history(t, maxn)
    while #t > maxn do
        table.remove(t, 1)
    end
end

local function parse_command(raw)
    local prefix = string.sub(raw, 1, 1) -- "." ou "/"
    local body = string.sub(raw, 2)
    local sp = string.find(body, " ", 1, true)
    local name, args
    if sp then
        name = string.sub(body, 1, sp - 1)
        args = string.sub(body, sp + 1)
    else
        name = body
        args = ""
    end
    return prefix, name, args
end

local function push_cmd_history_raw(raw)
    local prefix, name, args = parse_command(raw)
    local entry = {
        time   = now_string(),
        raw    = raw,
        prefix = prefix,
        name   = name,
        args   = args
    }
    table.insert(cmd_history, entry)
    trim_history(cmd_history, MAX_HISTORY_CMDS)
end

local function push_cmd_history_local(name, param)
    -- Reconstitue la ligne telle que tapée par l'utilisateur côté client
    local raw = "." .. tostring(name)
    if param and param ~= "" then
        raw = raw .. " " .. param
    end
    push_cmd_history_raw(raw)
end

-- =========================
-- Affichage joueurs (sans historique joueurs)
-- =========================
local function show_players()
    local names = safe_get_player_names()

    -- Si vide, mais joueur local connu => probablement solo
    if (#names == 0) and minetest.localplayer and minetest.localplayer.get_name then
        local pname = minetest.localplayer:get_name()
        if type(pname) == "string" and pname ~= "" then
            names = {pname}
        end
    end

    table.sort(names)
    local count = #names
    local header = "[Players] " .. count .. (count == 1 and " joueur" or " joueurs")
    minetest.display_chat_message(header)

    if count > 0 then
        local line, maxlen = "", 200
        for i, n in ipairs(names) do
            local piece = (i == 1 and n) or (", " .. n)
            if #line + #piece > maxlen then
                minetest.display_chat_message(line)
                line = n
            else
                line = line .. piece
            end
        end
        if line ~= "" then
            minetest.display_chat_message(line)
        end
    end
end

-- =========================
-- Hook compat: chat envoyé ("/" et messages classiques)
-- =========================
do
    local hooked = false

    if type(minetest.register_on_sending_chat_message) == "function" then
        minetest.register_on_sending_chat_message(function(message)
            if type(message) == "string" then
                local c = string.sub(message, 1, 1)
                if c == "." or c == "/" then
                    -- Attention: selon le client, les commandes "." locales peuvent ne JAMAIS passer ici.
                    push_cmd_history_raw(message)
                end
            end
            -- ne pas bloquer l'envoi
        end)
        hooked = true
    end

    if (not hooked) and type(minetest.register_on_sending_message) == "function" then
        minetest.register_on_sending_message(function(message)
            if type(message) == "string" then
                local c = string.sub(message, 1, 1)
                if c == "." or c == "/" then
                    push_cmd_history_raw(message)
                end
            end
        end)
        hooked = true
    end

    if not hooked and type(minetest.send_chat_message) == "function" then
        local original_send = minetest.send_chat_message
        minetest.send_chat_message = function(message)
            if type(message) == "string" then
                local c = string.sub(message, 1, 1)
                if c == "." or c == "/" then
                    push_cmd_history_raw(message)
                end
            end
            return original_send(message)
        end
        hooked = true
    end

    if not hooked then
        minetest.display_chat_message("[CmdHistory] Attention: impossible d'accrocher l'envoi des messages sur ce client.")
    end
end

-- =========================
-- Commandes chat exposées (on LOG explicitement les locales)
-- =========================
minetest.register_chatcommand("show_player", {
    description = "Afficher le nombre de joueurs connectés et leurs noms",
    func = function(param)
        push_cmd_history_local("show_player", param) -- LOG explicite
        show_players()
    end
})

minetest.register_chatcommand("sp", {
    description = "Alias de .show_player",
    func = function(param)
        push_cmd_history_local("sp", param) -- LOG explicite
        show_players()
    end
})

minetest.register_chatcommand("cmd_history", {
    params = "[N]",
    description = "Afficher l'historique global des commandes (. ou /) envoyées par le client",
    func = function(param)
        push_cmd_history_local("cmd_history", param) -- LOG explicite
        local n = tonumber(param or "") or 10
        if n < 1 then n = 1 end
        if n > MAX_HISTORY_CMDS then n = MAX_HISTORY_CMDS end

        if #cmd_history == 0 then
            minetest.display_chat_message("[CmdHistory] Aucun enregistrement pour cette session.")
            return
        end

        minetest.display_chat_message(string.format("[CmdHistory] Dernières %d commandes :", math.min(n, #cmd_history)))
        local start_index = math.max(1, #cmd_history - n + 1)
        for i = start_index, #cmd_history do
            local e = cmd_history[i]
            local label = (e.prefix == "." and "client") or "serveur"
            local line = string.format("%s — (%s) %s %s", e.time, label, e.name, (e.args ~= "" and e.args or ""))
            minetest.display_chat_message(line)
        end
    end
})

minetest.register_chatcommand("ch", {
    params = "[N]",
    description = "Alias de .cmd_history",
    func = function(param)
        push_cmd_history_local("ch", param) -- LOG explicite
        minetest.run_server_chatcommand("cmd_history", param) -- réutilise la logique ci-dessus
        -- Si run_server_chatcommand n'existe pas côté CSM, on recopie la fonction:
        local n = tonumber(param or "") or 10
        if n < 1 then n = 1 end
        if n > MAX_HISTORY_CMDS then n = MAX_HISTORY_CMDS end

        if #cmd_history == 0 then
            minetest.display_chat_message("[CmdHistory] Aucun enregistrement pour cette session.")
            return
        end

        minetest.display_chat_message(string.format("[CmdHistory] Dernières %d commandes :", math.min(n, #cmd_history)))
        local start_index = math.max(1, #cmd_history - n + 1)
        for i = start_index, #cmd_history do
            local e = cmd_history[i]
            local label = (e.prefix == "." and "client") or "serveur"
            local line = string.format("%s — (%s) %s %s", e.time, label, e.name, (e.args ~= "" and e.args or ""))
            minetest.display_chat_message(line)
        end
    end
})

minetest.register_chatcommand("ch_clear", {
    description = "Effacer l'historique global des commandes",
    func = function(param)
        push_cmd_history_local("ch_clear", param) -- LOG explicite
        cmd_history = {}
        minetest.display_chat_message("[CmdHistory] Historique effacé.")
    end
})
