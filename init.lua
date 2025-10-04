-- Luanti / Minetest Client-Side Mod
-- Mod: show_player
-- Commande : .show_player -> affiche le nombre de joueurs et leurs noms
-- v2: Suppression de minetest.is_singleplayer() (indisponible en CSM).
--     Si la liste est vide mais qu'un joueur local existe, on affiche son nom.

local function safe_get_player_names()
    if minetest.get_player_names then
        local ok, result = pcall(minetest.get_player_names)
        if ok and type(result) == "table" then
            return result
        end
    end
    return {}
end

local function show_players()
    local names = safe_get_player_names()

    -- Si la liste est vide mais que le client a un joueur local, considérer que c'est (très probablement) du solo
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

minetest.register_chatcommand("show_player", {
    description = "Afficher le nombre de joueurs connectés et leurs noms",
    func = function(param)
        show_players()
    end
})

minetest.register_chatcommand("sp", {
    description = "Alias de .show_player",
    func = function(param)
        show_players()
    end
})
