-- renderer.lua - Pseudo-3D corridor rendering with forced perspective

local Utils = import "utils"

local Renderer = {}

-- Screen dimensions
Renderer.SCREEN_W = 400
Renderer.SCREEN_H = 240

-- Vanishing point (center-ish, slightly right to give Torchy room on the left)
Renderer.VP_X = 200
Renderer.VP_Y = 120

-- Corridor parameters
Renderer.CORRIDOR_NEAR_W = 380   -- corridor width at bottom of screen
Renderer.CORRIDOR_NEAR_H = 220   -- corridor height at bottom of screen
Renderer.CORRIDOR_FAR_W = 20     -- corridor width at vanishing point
Renderer.CORRIDOR_FAR_H = 14     -- corridor height at vanishing point

-- Number of depth segments for the corridor
Renderer.NUM_SEGMENTS = 16
Renderer.SEGMENT_DEPTH = 1.0 / Renderer.NUM_SEGMENTS

-- Platform rendering
Renderer.FLOOR_Y_NEAR = 200      -- floor Y at near plane
Renderer.FLOOR_Y_FAR = Renderer.VP_Y + 7
Renderer.CEIL_Y_NEAR = 40        -- ceiling Y at near plane
Renderer.CEIL_Y_FAR = Renderer.VP_Y - 7

local gfx = playdate.graphics

function Renderer.init()
    Renderer.scrollOffset = 0
    Renderer.dashPattern = {0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55}
end

-- Get the X position of the left/right corridor walls at a given depth t (0=near, 1=far)
function Renderer.getCorridorX(t)
    local w = Utils.lerp(Renderer.CORRIDOR_NEAR_W, Renderer.CORRIDOR_FAR_W, t)
    local cx = Renderer.VP_X
    return cx - w / 2, cx + w / 2
end

-- Get the Y position of floor/ceiling at a given depth t
function Renderer.getFloorY(t)
    return Utils.lerp(Renderer.FLOOR_Y_NEAR, Renderer.FLOOR_Y_FAR, t)
end

function Renderer.getCeilY(t)
    return Utils.lerp(Renderer.CEIL_Y_NEAR, Renderer.CEIL_Y_FAR, t)
end

-- Get platform width factor based on region
function Renderer.getPlatformWidthAtDepth(t, platformWidthFactor)
    local leftX, rightX = Renderer.getCorridorX(t)
    local fullWidth = rightX - leftX
    local platWidth = fullWidth * platformWidthFactor
    local cx = (leftX + rightX) / 2
    return cx - platWidth / 2, cx + platWidth / 2
end

-- Draw the corridor background
function Renderer.drawCorridor(platformWidthFactor, scrollOffset, regionIndex)
    gfx.clear(gfx.kColorWhite)

    local vpx = Renderer.VP_X
    local vpy = Renderer.VP_Y

    -- Draw filled corridor (dark background for depth)
    -- Far wall
    local farL, farR = Renderer.getCorridorX(1.0)
    local farTop = Renderer.getCeilY(1.0)
    local farBot = Renderer.getFloorY(1.0)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(farL, farTop, farR - farL, farBot - farTop)

    -- Draw corridor segments from far to near
    for i = Renderer.NUM_SEGMENTS, 1, -1 do
        local tFar = i / Renderer.NUM_SEGMENTS
        local tNear = (i - 1) / Renderer.NUM_SEGMENTS

        local nearL, nearR = Renderer.getCorridorX(tNear)
        local fL, fR = Renderer.getCorridorX(tFar)
        local nearFloor = Renderer.getFloorY(tNear)
        local farFloor = Renderer.getFloorY(tFar)
        local nearCeil = Renderer.getCeilY(tNear)
        local farCeil = Renderer.getCeilY(tFar)

        -- Floor trapezoid
        gfx.setColor(gfx.kColorWhite)
        gfx.fillPolygon(nearL, nearFloor, fL, farFloor, fR, farFloor, nearR, nearFloor)

        -- Ceiling trapezoid
        gfx.fillPolygon(nearL, nearCeil, fL, farCeil, fR, farCeil, nearR, nearCeil)

        -- Draw grid lines on floor for depth effect
        gfx.setColor(gfx.kColorBlack)
        local segScroll = (scrollOffset * (1 - tNear * 0.8)) % (nearFloor - farFloor)

        -- Horizontal depth lines on floor
        if i % 2 == 0 then
            local lineY = nearFloor - segScroll * 0.3
            if lineY > farFloor and lineY < nearFloor then
                local lineT = (lineY - Renderer.FLOOR_Y_FAR) / (Renderer.FLOOR_Y_NEAR - Renderer.FLOOR_Y_FAR)
                lineT = Utils.clamp(1 - lineT, 0, 1)
                local ll, lr = Renderer.getCorridorX(lineT)
                gfx.drawLine(ll, lineY, lr, lineY)
            end
        end

        -- Corridor wall edges
        gfx.setLineWidth(1)
        gfx.drawLine(nearL, nearFloor, fL, farFloor)   -- left floor edge
        gfx.drawLine(nearR, nearFloor, fR, farFloor)   -- right floor edge
        gfx.drawLine(nearL, nearCeil, fL, farCeil)      -- left ceiling edge
        gfx.drawLine(nearR, nearCeil, fR, farCeil)      -- right ceiling edge

        -- Left wall
        gfx.drawLine(nearL, nearFloor, nearL, nearCeil)
        -- Right wall
        gfx.drawLine(nearR, nearFloor, nearR, nearCeil)
    end

    -- Draw scrolling floor grid lines
    Renderer.drawFloorGrid(scrollOffset, platformWidthFactor)

    -- Draw perspective lines from corners to vanishing point
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    local nearL, nearR = Renderer.getCorridorX(0)
    local nearFloor = Renderer.getFloorY(0)
    local nearCeil = Renderer.getCeilY(0)
    gfx.drawLine(nearL, nearFloor, vpx, vpy)  -- bottom-left to VP
    gfx.drawLine(nearR, nearFloor, vpx, vpy)  -- bottom-right to VP
    gfx.drawLine(nearL, nearCeil, vpx, vpy)   -- top-left to VP
    gfx.drawLine(nearR, nearCeil, vpx, vpy)   -- top-right to VP
    gfx.setLineWidth(1)
end

function Renderer.drawFloorGrid(scrollOffset, platformWidthFactor)
    local numLines = 10
    local spacing = 30
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)

    for i = 0, numLines do
        local baseZ = (i * spacing + scrollOffset * 3) % (numLines * spacing)
        local t = baseZ / (numLines * spacing)
        t = Utils.clamp(t, 0.05, 0.95)

        local leftX, rightX = Renderer.getCorridorX(t)
        local floorY = Renderer.getFloorY(t)
        local ceilY = Renderer.getCeilY(t)

        -- Floor grid line
        gfx.drawLine(leftX, floorY, rightX, floorY)
        -- Ceiling grid line (lighter - use dithered)
        if i % 2 == 0 then
            gfx.drawLine(leftX, ceilY, rightX, ceilY)
        end
    end
end

-- Draw an obstacle at a given depth position
-- obstacleType: string type of obstacle
-- t: depth position (0=near/player, 1=far/vanishing point)
-- Returns: screen coords for collision checking
function Renderer.drawObstacle(obstacleType, t, extraData)
    if t < 0 or t > 1 then return nil end

    local leftX, rightX = Renderer.getCorridorX(t)
    local floorY = Renderer.getFloorY(t)
    local ceilY = Renderer.getCeilY(t)
    local corridorW = rightX - leftX
    local corridorH = floorY - ceilY
    local cx = (leftX + rightX) / 2

    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)

    local coords = {leftX = leftX, rightX = rightX, floorY = floorY, ceilY = ceilY, t = t}

    if obstacleType == "gap" then
        -- Gap in the floor: draw warning marks
        local gapWidth = corridorW * 0.6
        local gapL = cx - gapWidth / 2
        local gapR = cx + gapWidth / 2
        -- Draw dashed lines to show gap edges
        gfx.setColor(gfx.kColorBlack)
        local markH = math.max(2, corridorH * 0.08)
        -- Hazard stripes on gap edges
        for j = 0, 3 do
            local stripeY = floorY - markH - j * 2
            if stripeY > ceilY then
                gfx.drawLine(gapL, stripeY, gapL, stripeY + markH)
                gfx.drawLine(gapR, stripeY, gapR, stripeY + markH)
            end
        end
        -- Draw X pattern in gap
        gfx.drawLine(gapL, floorY - markH, gapR, floorY)
        gfx.drawLine(gapL, floorY, gapR, floorY - markH)
        coords.type = "gap"
        coords.gapL = gapL
        coords.gapR = gapR

    elseif obstacleType == "low_ceiling" then
        -- Low ceiling block
        local blockH = math.max(4, corridorH * 0.35)
        gfx.fillRect(leftX + 2, ceilY, corridorW - 4, blockH)
        -- Draw bottom edge of the block
        gfx.setColor(gfx.kColorWhite)
        gfx.drawLine(leftX + 2, ceilY + blockH, rightX - 2, ceilY + blockH)
        coords.type = "low_ceiling"
        coords.blockBottom = ceilY + blockH

    elseif obstacleType == "side_wall" then
        -- Side wall narrows the corridor
        local side = extraData and extraData.side or "left"
        local wallW = corridorW * 0.35
        if side == "left" then
            gfx.fillRect(leftX, ceilY, wallW, corridorH)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawLine(leftX + wallW, ceilY, leftX + wallW, floorY)
            coords.wallRight = leftX + wallW
        else
            gfx.fillRect(rightX - wallW, ceilY, wallW, corridorH)
            gfx.setColor(gfx.kColorWhite)
            gfx.drawLine(rightX - wallW, ceilY, rightX - wallW, floorY)
            coords.wallLeft = rightX - wallW
        end
        coords.type = "side_wall"

    elseif obstacleType == "moving_block" then
        -- Moving block slides left-right
        local blockW = math.max(6, corridorW * 0.25)
        local blockH = math.max(6, corridorH * 0.25)
        local offsetX = extraData and extraData.offsetX or 0
        local bx = cx + offsetX * (corridorW * 0.3) - blockW / 2
        local by = ceilY + (corridorH - blockH) / 2
        gfx.fillRect(bx, by, blockW, blockH)
        -- Draw highlight
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(bx + 1, by + 1, blockW - 2, blockH - 2)
        coords.type = "moving_block"
        coords.blockX = bx
        coords.blockW = blockW
        coords.blockY = by
        coords.blockH = blockH

    elseif obstacleType == "rail_platform" then
        -- Platform narrows to a thin rail
        local railH = math.max(2, corridorH * 0.06)
        local railW = corridorW * 0.15
        local railL = cx - railW / 2
        -- Draw the rail
        gfx.fillRect(railL, floorY - railH, railW, railH)
        -- Also narrow ceiling rail
        gfx.fillRect(railL, ceilY, railW, railH)
        coords.type = "rail_platform"
        coords.railL = railL
        coords.railR = railL + railW

    elseif obstacleType == "gravity_field" then
        -- Gravity field zone - draw wavy lines
        local fieldW = corridorW * 0.5
        local fieldL = cx - fieldW / 2
        -- Draw gravity field indicator (arrows)
        gfx.setColor(gfx.kColorBlack)
        local arrowCount = math.max(1, math.floor(corridorH / 12))
        for j = 0, arrowCount do
            local ay = ceilY + j * (corridorH / arrowCount)
            -- Up/down arrows
            gfx.drawLine(cx - 3, ay, cx, ay - 4)
            gfx.drawLine(cx + 3, ay, cx, ay - 4)
            gfx.drawLine(cx - 3, ay, cx, ay + 4)
            gfx.drawLine(cx + 3, ay, cx, ay + 4)
        end
        -- Border
        gfx.drawRect(fieldL, ceilY + 2, fieldW, corridorH - 4)
        coords.type = "gravity_field"

    elseif obstacleType == "dual_gap" then
        -- Gap on BOTH floor and ceiling
        local gapWidth = corridorW * 0.5
        local gapL = cx - gapWidth / 2
        local gapR = cx + gapWidth / 2
        local markH = math.max(2, corridorH * 0.08)
        -- Floor gap
        gfx.drawLine(gapL, floorY, gapR, floorY - markH)
        gfx.drawLine(gapL, floorY - markH, gapR, floorY)
        -- Ceiling gap
        gfx.drawLine(gapL, ceilY, gapR, ceilY + markH)
        gfx.drawLine(gapL, ceilY + markH, gapR, ceilY)
        coords.type = "dual_gap"

    elseif obstacleType == "ramp" then
        -- Ramp that triggers Air Time
        local rampW = corridorW * 0.6
        local rampH = math.max(4, corridorH * 0.2)
        local rampL = cx - rampW / 2
        -- Draw ramp as a triangle
        gfx.fillPolygon(
            rampL, floorY,
            rampL + rampW, floorY,
            cx, floorY - rampH
        )
        -- Draw "AIR" text if big enough
        if corridorW > 40 then
            gfx.setColor(gfx.kColorWhite)
            gfx.setFont(gfx.getSystemFont())
            local textW = gfx.getTextSize("AIR")
            if textW < rampW then
                gfx.drawText("AIR", cx - textW / 2, floorY - rampH / 2 - 4)
            end
        end
        coords.type = "ramp"
    end

    return coords
end

-- Draw Torchy character
-- onCeiling: boolean, whether on ceiling or floor
-- flipProgress: 0-1 animation progress of flip
function Renderer.drawTorchy(onCeiling, flipProgress, invulnerable)
    local playerDepthT = 0.15  -- Torchy's depth position in the corridor
    local leftX, rightX = Renderer.getCorridorX(playerDepthT)
    local floorY = Renderer.getFloorY(playerDepthT)
    local ceilY = Renderer.getCeilY(playerDepthT)
    local corridorH = floorY - ceilY

    -- Torchy size (relative to corridor at this depth)
    local torchyW = 20
    local torchyH = 24

    -- Position
    local tx = leftX + (rightX - leftX) * 0.3 - torchyW / 2

    local baseFloorY = floorY - torchyH - 2
    local baseCeilY = ceilY + 2

    local ty
    if flipProgress > 0 and flipProgress < 1 then
        -- During flip animation
        local fromY = onCeiling and baseFloorY or baseCeilY
        local toY = onCeiling and baseCeilY or baseFloorY
        ty = Utils.lerp(fromY, toY, Utils.easeInOut(flipProgress))
    else
        ty = onCeiling and baseCeilY or baseFloorY
    end

    -- Draw Torchy body
    gfx.setColor(gfx.kColorBlack)

    -- Flash if invulnerable
    if invulnerable and playdate.getCurrentTimeMilliseconds() % 200 < 100 then
        gfx.setColor(gfx.kColorWhite)
    end

    -- Body (rounded rectangle)
    gfx.fillRoundRect(tx, ty, torchyW, torchyH, 3)

    -- Face details (white on black)
    gfx.setColor(gfx.kColorWhite)
    -- Eyes
    local eyeY = ty + 6
    if onCeiling and flipProgress >= 1 or (not onCeiling and flipProgress <= 0) then
        if onCeiling then eyeY = ty + torchyH - 10 end
    end
    gfx.fillRect(tx + 5, eyeY, 3, 3)
    gfx.fillRect(tx + 12, eyeY, 3, 3)

    -- Mouth (small line)
    gfx.drawLine(tx + 6, eyeY + 6, tx + 14, eyeY + 6)

    -- Torch flame on top (or bottom if flipped)
    gfx.setColor(gfx.kColorBlack)
    local flameX = tx + torchyW / 2
    if onCeiling and (flipProgress >= 1 or flipProgress <= 0) then
        -- Flame points down from ceiling
        local flameY = ty + torchyH
        gfx.fillPolygon(flameX - 4, flameY, flameX + 4, flameY, flameX, flameY + 8)
        -- Inner flame
        gfx.setColor(gfx.kColorWhite)
        gfx.fillPolygon(flameX - 2, flameY, flameX + 2, flameY, flameX, flameY + 5)
    else
        -- Flame points up from floor
        local flameY = ty
        gfx.fillPolygon(flameX - 4, flameY, flameX + 4, flameY, flameX, flameY - 8)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillPolygon(flameX - 2, flameY, flameX + 2, flameY, flameX, flameY - 5)
    end

    -- Return Torchy's screen position for collision detection
    return {
        x = tx,
        y = ty,
        w = torchyW,
        h = torchyH,
        depthT = playerDepthT,
        onCeiling = onCeiling
    }
end

-- Draw a ramp approach indicator
function Renderer.drawRampIndicator(progress)
    if progress <= 0 then return end
    gfx.setColor(gfx.kColorBlack)
    local barW = 60
    local barH = 8
    local bx = Renderer.SCREEN_W / 2 - barW / 2
    local by = 20
    gfx.drawRect(bx, by, barW, barH)
    gfx.fillRect(bx + 1, by + 1, (barW - 2) * progress, barH - 2)
    -- "AIR TIME" label
    local font = gfx.getSystemFont()
    gfx.setFont(font)
    gfx.drawTextAligned("AIR TIME", Renderer.SCREEN_W / 2, by - 12, kTextAlignment.center)
end

return Renderer
