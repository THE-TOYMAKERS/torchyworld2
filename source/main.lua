-- main.lua - Air Time: Torchy's Endless Gravity Run
-- Entry point and game state machine

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"

local gfx = playdate.graphics

-- Import game modules (Playdate import makes globals available)
import "game"
import "menu"
import "highscore"

-- App states
local APP_STATE_TITLE = "title"
local APP_STATE_PLAYING = "playing"
local APP_STATE_DEATH = "death"

local appState = APP_STATE_TITLE

-- Initialize
function setupGame()
    math.randomseed(playdate.getSecondsSinceEpoch())
    HighScore.init()
    Menu.init()
    gfx.setBackgroundColor(gfx.kColorWhite)
    playdate.display.setRefreshRate(30)
end

setupGame()

-- Main update loop
function playdate.update()
    if appState == APP_STATE_TITLE then
        updateTitle()
    elseif appState == APP_STATE_PLAYING then
        updatePlaying()
    elseif appState == APP_STATE_DEATH then
        updateDeath()
    end

    -- Update timers
    playdate.timer.updateTimers()
end

function updateTitle()
    Menu.update()
    Menu.drawTitle()

    local action = Menu.handleInput()
    if action == "start" then
        startGame()
    end

    -- Show crank indicator on title
    playdate.ui.crankIndicator:update()
end

function startGame()
    Game.init()
    appState = APP_STATE_PLAYING
end

function updatePlaying()
    local gameState = Game.update()
    Game.draw()

    if gameState == "dead" then
        -- Transition to death screen
        local distance = Game.getDistance()
        local regionName = Game.getRegionName()
        local isNewHighScore = Game.getIsNewHighScore()

        Menu.setDeathInfo(distance, regionName, isNewHighScore)
        Menu.reset()
        appState = APP_STATE_DEATH
    end
end

function updateDeath()
    Menu.update()

    local distance = Game.getDistance()
    local regionName = Game.getRegionName()
    local isNewHighScore = Game.getIsNewHighScore()

    Menu.drawDeath(distance, regionName, HighScore.getBest(), isNewHighScore)

    local action = Menu.handleInput()
    if action == "start" then
        startGame()
    end
end

-- System menu items
local sysMenu = playdate.getSystemMenu()

sysMenu:addMenuItem("Restart", function()
    if appState == APP_STATE_PLAYING then
        startGame()
    end
end)

sysMenu:addMenuItem("Title Screen", function()
    appState = APP_STATE_TITLE
    Menu.init()
end)

-- Handle crank dock/undock
function playdate.crankDocked()
    -- Show crank indicator when docked during Air Time
end

function playdate.crankUndocked()
    -- Crank is ready
end

-- Game focus
function playdate.gameWillPause()
    -- Save high score when pausing
    HighScore.save()
end

function playdate.deviceWillSleep()
    HighScore.save()
end
