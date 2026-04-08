local games = {
    [18326509492] = "ksv4", -- replace with actual PlaceId
}

local baseUrl = "https://raw.githubusercontent.com/not-a-smurf/roblox-scripts/main/games/"

local gameName = games[game.PlaceId]

if gameName then
    loadstring(game:HttpGet(baseUrl .. gameName .. ".lua"))()
else
    -- fallback: just load movement features in unsupported games
    print("[Loader] No script found for PlaceId: " .. game.PlaceId)
end
