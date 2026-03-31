-- airtime.lua - Air Time slow-mo pipe puzzle mini-game

import "utils"

AirTime = {}

-- Pipe states: each pipe can be in one of 4 rotations (0, 1, 2, 3)
-- Rotation 0 = horizontal (aligned/solved)
-- Visual: 0=━  1=╋  2=┃  3=━(offset)
-- For simplicity: even rotation = horizontal (aligned), odd = not aligned

AirTime.STATE_INACTIVE = "inactive"
AirTime.STATE_ENTERING = "entering"    -- slow-mo transition in
AirTime.STATE_ACTIVE = "active"        -- puzzle active
AirTime.STATE_SUCCESS = "success"      -- all pipes aligned
AirTime.STATE_FAIL = "fail"            -- time ran out or player landed
AirTime.STATE_EXITING = "exiting"      -- transition back to run

-- Screen dimensions
local SCREEN_W = 400
local SCREEN_H = 240
local CENTER_X = SCREEN_W / 2
local CENTER_Y = SCREEN_H / 2

function AirTime.init()
    AirTime.state = AirTime.STATE_INACTIVE
    AirTime.pipes = {}
    AirTime.pipeCount = 3
    AirTime.selectedPipe = 1
    AirTime.timer = 0
    AirTime.maxTime = 0           -- 0 = no time limit
    AirTime.enterTimer = 0
    AirTime.exitTimer = 0
    AirTime.hasDecoys = false
    AirTime.decoyPipes = {}
    AirTime.solved = false
    AirTime.bonusDistance = 0
    AirTime.crankAngle = 0
    AirTime.lastCrankAngle = 0
    AirTime.flashTimer = 0
end

function AirTime.start(pipeCount, hasTimeLimit, timeLimitSeconds, hasDecoys)
    AirTime.state = AirTime.STATE_ENTERING
    AirTime.enterTimer = 0
    AirTime.pipeCount = pipeCount or 3
    AirTime.selectedPipe = 1
    AirTime.solved = false
    AirTime.bonusDistance = 0
    AirTime.flashTimer = 0

    -- Set up time limit
    if hasTimeLimit and timeLimitSeconds then
        AirTime.maxTime = timeLimitSeconds * 30  -- convert to frames
    else
        AirTime.maxTime = 0
    end
    AirTime.timer = 0

    -- Create pipes with random rotations (none start aligned)
    AirTime.pipes = {}
    for i = 1, AirTime.pipeCount do
        local rotation = math.random(1, 3)  -- 1, 2, or 3 (not 0 which is solved)
        table.insert(AirTime.pipes, {
            rotation = rotation,
            targetRotation = 0,   -- must reach 0 (or 4, which wraps to 0)
            solved = false,
            ring = i
        })
    end

    -- Decoy pipes (look like real pipes but can't be solved)
    AirTime.hasDecoys = hasDecoys or false
    AirTime.decoyPipes = {}
    if AirTime.hasDecoys then
        local decoyCount = math.random(1, 2)
        for i = 1, decoyCount do
            table.insert(AirTime.decoyPipes, {
                rotation = math.random(0, 3),
                ring = AirTime.pipeCount + i,
                isDecoy = true
            })
        end
    end

    -- Reset crank
    AirTime.crankAngle = playdate.getCrankPosition() or 0
    AirTime.lastCrankAngle = AirTime.crankAngle
end

function AirTime.update()
    if AirTime.state == AirTime.STATE_INACTIVE then
        return false
    end

    if AirTime.state == AirTime.STATE_ENTERING then
        AirTime.enterTimer = AirTime.enterTimer + 1
        if AirTime.enterTimer >= 30 then  -- 1 second transition
            AirTime.state = AirTime.STATE_ACTIVE
        end
        return true
    end

    if AirTime.state == AirTime.STATE_ACTIVE then
        -- Timer
        AirTime.timer = AirTime.timer + 1
        if AirTime.maxTime > 0 and AirTime.timer >= AirTime.maxTime then
            AirTime.state = AirTime.STATE_FAIL
            AirTime.exitTimer = 0
            return true
        end

        -- Handle D-pad for layer selection
        if playdate.buttonJustPressed(playdate.kButtonUp) then
            AirTime.selectedPipe = math.max(1, AirTime.selectedPipe - 1)
        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            local maxPipe = AirTime.pipeCount
            if AirTime.hasDecoys then
                maxPipe = maxPipe + #AirTime.decoyPipes
            end
            AirTime.selectedPipe = math.min(maxPipe, AirTime.selectedPipe + 1)
        end

        -- Handle crank for rotation
        local currentCrank = playdate.getCrankPosition() or 0
        local crankDelta = currentCrank - AirTime.lastCrankAngle

        -- Normalize delta to -180..180
        if crankDelta > 180 then crankDelta = crankDelta - 360 end
        if crankDelta < -180 then crankDelta = crankDelta + 360 end

        AirTime.lastCrankAngle = currentCrank

        -- Rotate selected pipe when crank moves enough
        if math.abs(crankDelta) > 30 then
            AirTime.rotatePipe(AirTime.selectedPipe, crankDelta > 0 and 1 or -1)
        end

        -- Also allow A button to rotate (tap)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            AirTime.rotatePipe(AirTime.selectedPipe, 1)
        end

        -- Check if all pipes are solved
        AirTime.checkSolved()

        return true
    end

    if AirTime.state == AirTime.STATE_SUCCESS then
        AirTime.flashTimer = AirTime.flashTimer + 1
        if AirTime.flashTimer >= 60 then  -- 2 second celebration
            AirTime.state = AirTime.STATE_EXITING
            AirTime.exitTimer = 0
        end
        return true
    end

    if AirTime.state == AirTime.STATE_FAIL then
        AirTime.exitTimer = AirTime.exitTimer + 1
        if AirTime.exitTimer >= 30 then
            AirTime.state = AirTime.STATE_INACTIVE
            return false
        end
        return true
    end

    if AirTime.state == AirTime.STATE_EXITING then
        AirTime.exitTimer = AirTime.exitTimer + 1
        if AirTime.exitTimer >= 30 then
            AirTime.state = AirTime.STATE_INACTIVE
            return false
        end
        return true
    end

    return true
end

function AirTime.rotatePipe(index, direction)
    -- Check if it's a decoy
    if index > AirTime.pipeCount then
        local decoyIdx = index - AirTime.pipeCount
        if AirTime.decoyPipes[decoyIdx] then
            AirTime.decoyPipes[decoyIdx].rotation = (AirTime.decoyPipes[decoyIdx].rotation + direction) % 4
        end
        return
    end

    -- Rotate real pipe
    if AirTime.pipes[index] then
        AirTime.pipes[index].rotation = (AirTime.pipes[index].rotation + direction) % 4
        AirTime.pipes[index].solved = (AirTime.pipes[index].rotation == 0)
    end
end

function AirTime.checkSolved()
    local allSolved = true
    for _, pipe in ipairs(AirTime.pipes) do
        if pipe.rotation ~= 0 then
            allSolved = false
            break
        end
    end

    if allSolved then
        AirTime.solved = true
        AirTime.state = AirTime.STATE_SUCCESS
        AirTime.flashTimer = 0
        -- Calculate bonus distance
        AirTime.bonusDistance = AirTime.pipeCount * 50
    end
end

function AirTime.draw()
    if AirTime.state == AirTime.STATE_INACTIVE then return end

    local gfx = playdate.graphics
    local alpha = 1.0

    -- Entering transition: fade in
    if AirTime.state == AirTime.STATE_ENTERING then
        alpha = AirTime.enterTimer / 30
    end

    -- Draw semi-transparent overlay
    if AirTime.state == AirTime.STATE_ENTERING then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, SCREEN_W, SCREEN_H)
        gfx.setColor(gfx.kColorBlack)
    end

    -- Draw "AIR TIME" title
    gfx.setColor(gfx.kColorBlack)
    local font = gfx.getSystemFont(gfx.font.kVariantBold)
    gfx.setFont(font)

    if AirTime.state == AirTime.STATE_SUCCESS then
        -- Flash effect
        if AirTime.flashTimer % 10 < 5 then
            gfx.drawTextAligned("*AIR TIME - UNLOCKED!*", CENTER_X, 15, kTextAlignment.center)
        else
            gfx.drawTextAligned("*AIR TIME*", CENTER_X, 15, kTextAlignment.center)
        end
    else
        gfx.drawTextAligned("*AIR TIME*", CENTER_X, 15, kTextAlignment.center)
    end

    -- Draw timer if applicable
    if AirTime.maxTime > 0 and AirTime.state == AirTime.STATE_ACTIVE then
        local remaining = math.max(0, AirTime.maxTime - AirTime.timer)
        local seconds = math.ceil(remaining / 30)
        local timerFont = gfx.getSystemFont()
        gfx.setFont(timerFont)
        gfx.drawTextAligned("Time: " .. seconds .. "s", CENTER_X, 32, kTextAlignment.center)

        -- Timer bar
        local barW = 100
        local barH = 6
        local barX = CENTER_X - barW / 2
        local barY = 44
        gfx.drawRect(barX, barY, barW, barH)
        local fillW = (remaining / AirTime.maxTime) * (barW - 2)
        gfx.fillRect(barX + 1, barY + 1, fillW, barH - 2)
    end

    -- Draw pipe rings (concentric circles)
    local totalPipes = AirTime.pipeCount + #AirTime.decoyPipes
    local maxRadius = 80
    local minRadius = 20
    local ringSpacing = (maxRadius - minRadius) / math.max(1, totalPipes)

    for i = 1, AirTime.pipeCount do
        local pipe = AirTime.pipes[i]
        local radius = maxRadius - (i - 1) * ringSpacing
        local isSelected = (i == AirTime.selectedPipe)
        AirTime.drawPipeRing(pipe, radius, isSelected, false)
    end

    -- Draw decoy pipes
    for i = 1, #AirTime.decoyPipes do
        local pipe = AirTime.decoyPipes[i]
        local idx = AirTime.pipeCount + i
        local radius = maxRadius - (idx - 1) * ringSpacing
        local isSelected = (idx == AirTime.selectedPipe)
        AirTime.drawPipeRing(pipe, radius, isSelected, true)
    end

    -- Draw selection indicator
    local selFont = gfx.getSystemFont()
    gfx.setFont(selFont)
    gfx.drawTextAligned("Layer " .. AirTime.selectedPipe .. "/" .. totalPipes, CENTER_X, SCREEN_H - 40, kTextAlignment.center)

    -- Instructions
    gfx.drawTextAligned("Crank/A:Rotate  D-Pad:Layer", CENTER_X, SCREEN_H - 22, kTextAlignment.center)

    -- Draw fail message
    if AirTime.state == AirTime.STATE_FAIL then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(CENTER_X - 80, CENTER_Y - 15, 160, 30)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(CENTER_X - 80, CENTER_Y - 15, 160, 30)
        gfx.drawTextAligned("TIME'S UP!", CENTER_X, CENTER_Y - 8, kTextAlignment.center)
    end
end

function AirTime.drawPipeRing(pipe, radius, isSelected, isDecoy)
    local gfx = playdate.graphics
    local cx = CENTER_X
    local cy = CENTER_Y + 10  -- offset down slightly

    -- Draw ring circle
    gfx.setColor(gfx.kColorBlack)
    if isSelected then
        gfx.setLineWidth(3)
    else
        gfx.setLineWidth(1)
    end

    gfx.drawCircleAtPoint(cx, cy, radius)
    gfx.setLineWidth(1)

    -- Draw pipe segment based on rotation
    local rotation = pipe.rotation
    local segLen = radius * 0.4
    local isSolved = (rotation == 0)

    if isDecoy then
        -- Decoys drawn with dashed lines
        gfx.setColor(gfx.kColorBlack)
    end

    if rotation == 0 then
        -- Horizontal ━ (solved!)
        gfx.setLineWidth(3)
        gfx.drawLine(cx - segLen, cy, cx + segLen, cy)
        gfx.setLineWidth(1)
        -- Draw checkmark for solved
        if not isDecoy then
            gfx.fillCircleAtPoint(cx + radius + 10, cy, 4)
        end
    elseif rotation == 1 then
        -- Cross ╋
        gfx.setLineWidth(2)
        gfx.drawLine(cx - segLen * 0.7, cy - segLen * 0.7, cx + segLen * 0.7, cy + segLen * 0.7)
        gfx.drawLine(cx - segLen * 0.7, cy + segLen * 0.7, cx + segLen * 0.7, cy - segLen * 0.7)
        gfx.setLineWidth(1)
    elseif rotation == 2 then
        -- Vertical ┃
        gfx.setLineWidth(3)
        gfx.drawLine(cx, cy - segLen, cx, cy + segLen)
        gfx.setLineWidth(1)
    elseif rotation == 3 then
        -- Diagonal
        gfx.setLineWidth(2)
        gfx.drawLine(cx - segLen, cy - segLen * 0.3, cx + segLen, cy + segLen * 0.3)
        gfx.setLineWidth(1)
    end

    -- Selection arrow
    if isSelected then
        local arrowX = cx - radius - 15
        gfx.fillPolygon(arrowX, cy - 4, arrowX, cy + 4, arrowX + 8, cy)
    end
end

function AirTime.isActive()
    return AirTime.state ~= AirTime.STATE_INACTIVE
end

function AirTime.wasSolved()
    return AirTime.solved
end

function AirTime.getBonusDistance()
    return AirTime.bonusDistance
end

function AirTime.reset()
    AirTime.init()
end
