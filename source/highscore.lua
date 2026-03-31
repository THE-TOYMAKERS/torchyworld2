-- highscore.lua - High score persistence

HighScore = {}

local SAVE_KEY = "airtime_highscore"
local SAVE_KEY_REGION = "airtime_highest_region"

function HighScore.init()
    HighScore.best = 0
    HighScore.highestRegion = 1
    HighScore.load()
end

function HighScore.load()
    local data = playdate.datastore.read()
    if data then
        HighScore.best = data.highScore or 0
        HighScore.highestRegion = data.highestRegion or 1
    end
end

function HighScore.save()
    local data = {
        highScore = HighScore.best,
        highestRegion = HighScore.highestRegion
    }
    playdate.datastore.write(data)
end

function HighScore.check(distance, regionIndex)
    local isNew = false
    if distance > HighScore.best then
        HighScore.best = distance
        isNew = true
    end
    if regionIndex > HighScore.highestRegion then
        HighScore.highestRegion = regionIndex
    end
    if isNew then
        HighScore.save()
    end
    return isNew
end

function HighScore.getBest()
    return HighScore.best
end

function HighScore.getHighestRegion()
    return HighScore.highestRegion
end

function HighScore.reset()
    HighScore.best = 0
    HighScore.highestRegion = 1
    HighScore.save()
end
