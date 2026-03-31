-- player.lua - Torchy character with gravity flip mechanics

import "utils"

Player = {}

-- States
Player.STATE_RUNNING = "running"
Player.STATE_FLIPPING = "flipping"
Player.STATE_DEAD = "dead"
Player.STATE_AIRTIME = "airtime"

-- Flip animation duration (frames at 30fps)
Player.FLIP_DURATION = 8

function Player.init()
    Player.onCeiling = false
    Player.state = Player.STATE_RUNNING
    Player.flipProgress = 0       -- 0 = no flip, 1 = flip complete
    Player.flipTimer = 0
    Player.flipDirection = 1      -- 1 = going to ceiling, -1 = going to floor
    Player.holdingA = false
    Player.invulnerable = false
    Player.invulnerableTimer = 0
    Player.comboCount = 0         -- consecutive successful gravity flips
    Player.lastFlipDistance = 0
    Player.screenCoords = nil     -- set by renderer each frame
    Player.gravityLocked = false  -- true when holding A to lock on ceiling
end

function Player.update()
    if Player.state == Player.STATE_DEAD then
        return
    end

    -- Handle flip animation
    if Player.state == Player.STATE_FLIPPING then
        Player.flipTimer = Player.flipTimer + 1
        Player.flipProgress = Player.flipTimer / Player.FLIP_DURATION

        if Player.flipProgress >= 1 then
            Player.flipProgress = 0
            Player.flipTimer = 0
            Player.state = Player.STATE_RUNNING
            Player.onCeiling = not Player.onCeiling
        end
    end

    -- Invulnerability timer
    if Player.invulnerable then
        Player.invulnerableTimer = Player.invulnerableTimer - 1
        if Player.invulnerableTimer <= 0 then
            Player.invulnerable = false
        end
    end
end

function Player.handleInput()
    if Player.state == Player.STATE_DEAD or Player.state == Player.STATE_AIRTIME then
        return
    end

    -- A button: gravity flip
    local aPressed = playdate.buttonJustPressed(playdate.kButtonA)
    local aHeld = playdate.buttonIsPressed(playdate.kButtonA)
    local bPressed = playdate.buttonJustPressed(playdate.kButtonB)

    if aPressed or bPressed then
        if Player.state == Player.STATE_RUNNING then
            Player.startFlip()
        end
    end

    -- Hold A to lock on ceiling
    Player.holdingA = aHeld
    if aHeld and Player.onCeiling then
        Player.gravityLocked = true
    else
        Player.gravityLocked = false
    end
end

function Player.startFlip()
    if Player.state ~= Player.STATE_RUNNING then return end
    Player.state = Player.STATE_FLIPPING
    Player.flipTimer = 0
    Player.flipProgress = 0
    Player.flipDirection = Player.onCeiling and -1 or 1
    Player.comboCount = Player.comboCount + 1
end

function Player.die()
    if Player.invulnerable then return false end
    Player.state = Player.STATE_DEAD
    return true
end

function Player.setInvulnerable(frames)
    Player.invulnerable = true
    Player.invulnerableTimer = frames
end

function Player.isFlipping()
    return Player.state == Player.STATE_FLIPPING
end

function Player.isAlive()
    return Player.state ~= Player.STATE_DEAD
end

function Player.getEffectivePosition()
    -- Returns whether player is on ceiling considering flip animation
    if Player.state == Player.STATE_FLIPPING then
        -- During flip, position is in transition
        return Player.flipProgress > 0.5 and (not Player.onCeiling) or Player.onCeiling
    end
    return Player.onCeiling
end

function Player.enterAirTime()
    Player.state = Player.STATE_AIRTIME
end

function Player.exitAirTime()
    Player.state = Player.STATE_RUNNING
    Player.onCeiling = false  -- reset to floor after Air Time
    Player.setInvulnerable(30)  -- brief invulnerability after landing
end

function Player.reset()
    Player.init()
end
