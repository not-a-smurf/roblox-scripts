local games = {
    [18326509492]    = "killstreak",
    [130223052405478] = "fishpond",
}

local baseUrl = "https://raw.githubusercontent.com/not-a-smurf/roblox-scripts/main/games/"

local gameName = games[game.PlaceId]

if gameName then
    loadstring(game:HttpGet(baseUrl .. gameName .. ".lua"))()
else
    print("[Loader] No script found for PlaceId: " .. game.PlaceId .. " — loading generic")
    loadstring(game:HttpGet(baseUrl .. "generic.lua"))()
end
