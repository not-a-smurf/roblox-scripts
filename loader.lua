local games = {
    [18326509492]     = "killstreak",  -- Killstreak Swords V4
    [130223052405478] = "fishpond",    -- Own a Fish Pond

    -- Peroxide (replace 0 with actual PlaceId, run print(game.PlaceId) in each map)
    [11041522464] = "peroxide",  -- Soul Society
    [9096881148] = "peroxide",  -- Katakura Town
    [10550161545] = "peroxide",  -- Hueco Mundo
    [0] = "peroxide",  -- Hell
    [0] = "peroxide",  -- Menos Forest
    [0] = "peroxide",  -- Time Gates
    [0] = "peroxide",  -- PvP Servers
}

-- Peroxide PlaceIds (add all of them here so generic doesnt load in Peroxide)
local peroxideIds = {
    -- Fill these in as you visit each map with print(game.PlaceId)
    -- [9096881148] = true,  -- example
}

local baseUrl = "https://raw.githubusercontent.com/not-a-smurf/roblox-scripts/main/games/"

local gameName = games[game.PlaceId]

if gameName then
    loadstring(game:HttpGet(baseUrl .. gameName .. ".lua"))()
elseif not peroxideIds[game.PlaceId] then
    print("[Loader] No script found for PlaceId: " .. game.PlaceId .. " — loading generic")
    loadstring(game:HttpGet(baseUrl .. "generic.lua"))()
else
    print("[Loader] Peroxide map detected but not yet configured: " .. game.PlaceId)
end
