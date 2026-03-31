-- game.lua - Core game loop / run state

import "utils"
import "renderer"
import "player"
import "obstacles"
import "regions"
import "airtime"
import "hud"
import "highscore"

Game = {}

-- Game states
Game.STATE_RUNNING = "running"
Game.STATE_AIRTIME = "airtime"
Game.STATE_DEAD = "dead"
Game.STATE_PAUSED = "paused"

-- Base speed (meters per frame)
Game.BASE_SPEED = 2.0

function Game.init()
    Renderer.init()
    Player.init()
    Obstacles.init()
    AirTime.init()
    HUD.init()

    Game.state = Game.STATE_RUNNING
    Game.distance = 0
    Game.speed = Game.BASE_SPEED
    Game.scrollOffset = 0
    Game.currentRegionIndex = 1
    Game.currentRegionName = Regions.definitions[1].name
    Game.lastRegionIndex = 0
    Game.deathReason = ""
    Game.isNewHighScore = false
    Game.frameCount = 0

    -- Ramp tracking
    Game.rampApproachProgress = 0
    Game.nextRampDistance = 500
    Obstacles.setLastRampDistance(0)
end

function Game.update()
    Game.frameCount = Game.frameCount + 1

    if Game.state == Game.STATE_RUNNING then
        Game.updateRunning()
    elseif Game.state == Game.STATE_AIRTIME then
        Game.updateAirTime()
    elseif Game.state == Game.STATE_DEAD then
        -- Death state handled by menu
        return "dead"
    end

    return Game.state
end

function Game.updateRunning()
    -- Calculate speed based on region
    local speedMult = Regions.getSpeedMultiplier(Game.distance)
    Game.speed = Game.BASE_SPEED * speedMult

    -- Advance distance
    Game.distance = Game.distance + Game.speed / 30  -- meters per frame at 30fps

    -- Update scroll offset for visual movement
    Game.scrollOffset = Game.scrollOffset + Game.speed * 0.5

    -- Update region
    local newRegionIndex, newRegion = Regions.getRegionForDistance(Game.distance)
    if newRegionIndex ~= Game.lastRegionIndex then
        Game.currentRegionIndex = newRegionIndex
        Game.currentRegionName = newRegion.name
        Game.lastRegionIndex = newRegionIndex
    end

    -- Handle player input
    Player.handleInput()

    -- Update player
    Player.update()

    -- Update obstacles
    Obstacles.update(Game.speed, Game.distance, Game.currentRegionIndex)

    -- Ramp approach indicator
    local distToRamp = Game.nextRampDistance - Game.distance
    if distToRamp > 0 and distToRamp < 100 then
        Game.rampApproachProgress = 1 - (distToRamp / 100)
    else
        Game.rampApproachProgress = 0
    end

    -- Check collisions
    local playerCoords = Player.screenCoords
    local collision = Obstacles.checkCollision(playerCoords, Player.getEffectivePosition())

    if collision then
        if collision.type == "death" then
            local died = Player.die()
            if died then
                Game.state = Game.STATE_DEAD
                Game.deathReason = collision.obstacle
                Game.isNewHighScore = HighScore.check(Game.distance, Game.currentRegionIndex)
            end
        elseif collision.type == "gravity_flip" then
            if not Player.isFlipping() then
                Player.startFlip()
            end
        elseif collision.type == "airtime" then
            Game.startAirTime()
        end
    end

    -- Update HUD
    HUD.update(Game.distance, HighScore.getBest(), Game.currentRegionName, Player.comboCount)
end

function Game.startAirTime()
    local region = Regions.definitions[Game.currentRegionIndex]
    Player.enterAirTime()
    AirTime.start(
        region.pipeCount,
        region.hasTimeLimit,
        region.timeLimitSeconds,
        region.hasDecoys
    )
    Game.state = Game.STATE_AIRTIME
end

function Game.updateAirTime()
    local stillActive = AirTime.update()

    if not stillActive then
        -- Air Time ended
        if AirTime.wasSolved() then
            -- Success! Bonus distance and unlock next region
            local bonus = AirTime.getBonusDistance()
            Game.distance = Game.distance + bonus
            HUD.showAirTimeBonus(bonus)
            -- Update next ramp distance
            Game.nextRampDistance = Game.distance + 500
        else
            -- Failed - continue in current region
            Game.nextRampDistance = Game.distance + 500
        end

        Obstacles.setLastRampDistance(Game.distance)
        Player.exitAirTime()
        Game.state = Game.STATE_RUNNING
        AirTime.reset()
    end
end

function Game.draw()
    local gfx = playdate.graphics

    if Game.state == Game.STATE_RUNNING or Game.state == Game.STATE_DEAD then
        -- Draw corridor
        local region = Regions.definitions[Game.currentRegionIndex]
        local platformWidth = region and region.platformWidth or 0.8
        Renderer.drawCorridor(platformWidth, Game.scrollOffset, Game.currentRegionIndex)

        -- Draw obstacles
        Obstacles.draw(Renderer)

        -- Draw Torchy
        local torchyCoords = Renderer.drawTorchy(
            Player.onCeiling,
            Player.isFlipping() and Player.flipProgress or (Player.onCeiling and 1 or 0),
            Player.invulnerable
        )
        Player.screenCoords = torchyCoords

        -- Draw ramp approach indicator
        if Game.rampApproachProgress > 0 then
            Renderer.drawRampIndicator(Game.rampApproachProgress)
        end

        -- Draw HUD (on top of everything)
        HUD.draw()

    elseif Game.state == Game.STATE_AIRTIME then
        -- Draw Air Time puzzle
        AirTime.draw()
    end
end

function Game.getDistance()
    return Game.distance
end

function Game.getRegionName()
    return Game.currentRegionName
end

function Game.getIsNewHighScore()
    return Game.isNewHighScore
end

function Game.reset()
    Game.init()
end
