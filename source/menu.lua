-- menu.lua - Title screen, death screen, high score boom screen

local Utils = import "utils"

local Menu = {}

local SCREEN_W = 400
local SCREEN_H = 240
local CENTER_X = SCREEN_W / 2
local CENTER_Y = SCREEN_H / 2

-- Menu states
Menu.STATE_TITLE = "title"
Menu.STATE_DEATH = "death"
Menu.STATE_HIGHSCORE = "highscore"

function Menu.init()
    Menu.state = Menu.STATE_TITLE
    Menu.animTimer = 0
    Menu.deathDistance = 0
    Menu.deathRegion = ""
    Menu.isNewHighScore = false
    Menu.selectedOption = 1
    Menu.titleFlameOffset = 0
end

function Menu.update()
    Menu.animTimer = Menu.animTimer + 1
    Menu.titleFlameOffset = math.sin(Menu.animTimer * 0.1) * 3
end

function Menu.drawTitle()
    local gfx = playdate.graphics
    gfx.clear(gfx.kColorWhite)

    -- Title
    local boldFont = gfx.getSystemFont(gfx.font.kVariantBold)
    local normalFont = gfx.getSystemFont()

    -- Draw Torchy character in title
    Menu.drawTitleTorchy()

    -- Game title
    gfx.setFont(boldFont)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned("*AIR TIME*", CENTER_X, 30, kTextAlignment.center)

    gfx.setFont(normalFont)
    gfx.drawTextAligned("Torchy's Endless Gravity Run", CENTER_X, 55, kTextAlignment.center)

    -- Decorative line
    gfx.drawLine(CENTER_X - 80, 75, CENTER_X + 80, 75)

    -- Menu options
    local options = {"Press A to Play", "Crank to view controls"}
    local startY = 130

    for i, opt in ipairs(options) do
        local y = startY + (i - 1) * 25
        if i == 1 then
            -- Blinking "Press A"
            if Menu.animTimer % 40 < 30 then
                gfx.drawTextAligned(opt, CENTER_X, y, kTextAlignment.center)
            end
        else
            gfx.drawTextAligned(opt, CENTER_X, y, kTextAlignment.center)
        end
    end

    -- Version
    gfx.drawTextAligned("v1.0", SCREEN_W - 30, SCREEN_H - 20, kTextAlignment.center)

    -- Draw corridor preview in background
    Menu.drawTitleCorridor()
end

function Menu.drawTitleTorchy()
    local gfx = playdate.graphics
    local tx = CENTER_X - 10
    local ty = 85 + Menu.titleFlameOffset

    -- Body
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRoundRect(tx, ty, 20, 24, 3)

    -- Eyes
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(tx + 5, ty + 6, 3, 3)
    gfx.fillRect(tx + 12, ty + 6, 3, 3)

    -- Mouth
    gfx.drawLine(tx + 6, ty + 12, tx + 14, ty + 12)

    -- Flame
    gfx.setColor(gfx.kColorBlack)
    local flameX = tx + 10
    local flameY = ty
    gfx.fillPolygon(flameX - 4, flameY, flameX + 4, flameY, flameX, flameY - 10)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillPolygon(flameX - 2, flameY, flameX + 2, flameY, flameX, flameY - 6)
end

function Menu.drawTitleCorridor()
    local gfx = playdate.graphics
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(1)

    -- Simple corridor lines in background
    local vpx = CENTER_X
    local vpy = SCREEN_H - 30

    -- Floor perspective lines
    gfx.drawLine(0, SCREEN_H, vpx, vpy)
    gfx.drawLine(SCREEN_W, SCREEN_H, vpx, vpy)

    -- Some depth lines
    for i = 1, 4 do
        local t = i * 0.2
        local y = SCREEN_H - (SCREEN_H - vpy) * t
        local hw = (SCREEN_W / 2) * (1 - t * 0.8)
        gfx.drawLine(vpx - hw, y, vpx + hw, y)
    end
end

function Menu.drawDeath(distance, regionName, highScore, isNewHighScore)
    local gfx = playdate.graphics
    gfx.clear(gfx.kColorWhite)

    local boldFont = gfx.getSystemFont(gfx.font.kVariantBold)
    local normalFont = gfx.getSystemFont()

    if isNewHighScore then
        Menu.drawHighScoreBoom(distance, regionName)
        return
    end

    -- Death screen
    gfx.setFont(boldFont)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned("*GAME OVER*", CENTER_X, 30, kTextAlignment.center)

    -- Torchy fallen
    Menu.drawDeadTorchy()

    -- Stats
    gfx.setFont(normalFont)
    local statsY = 110

    -- Distance
    gfx.drawTextAligned("Distance: " .. math.floor(distance) .. "m", CENTER_X, statsY, kTextAlignment.center)

    -- Region
    gfx.drawTextAligned("Region: " .. regionName, CENTER_X, statsY + 20, kTextAlignment.center)

    -- High score
    gfx.drawTextAligned("Best: " .. math.floor(highScore) .. "m", CENTER_X, statsY + 40, kTextAlignment.center)

    -- Decorative line
    gfx.drawLine(CENTER_X - 60, statsY + 60, CENTER_X + 60, statsY + 60)

    -- Restart prompt
    if Menu.animTimer % 40 < 30 then
        gfx.drawTextAligned("Press A to retry", CENTER_X, SCREEN_H - 40, kTextAlignment.center)
    end
end

function Menu.drawHighScoreBoom(distance, regionName)
    local gfx = playdate.graphics
    local boldFont = gfx.getSystemFont(gfx.font.kVariantBold)
    local normalFont = gfx.getSystemFont()

    -- Flashy high score screen
    gfx.setColor(gfx.kColorBlack)

    -- Border flash effect
    if Menu.animTimer % 8 < 4 then
        gfx.fillRect(0, 0, SCREEN_W, 4)
        gfx.fillRect(0, SCREEN_H - 4, SCREEN_W, 4)
        gfx.fillRect(0, 0, 4, SCREEN_H)
        gfx.fillRect(SCREEN_W - 4, 0, 4, SCREEN_H)
    end

    gfx.setFont(boldFont)
    gfx.drawTextAligned("*HIGH SCORE BOOM!*", CENTER_X, 25, kTextAlignment.center)

    -- Stars/sparkles
    for i = 1, 6 do
        local sx = CENTER_X + math.cos(Menu.animTimer * 0.05 + i) * (60 + i * 15)
        local sy = 50 + math.sin(Menu.animTimer * 0.07 + i * 1.5) * 15
        gfx.fillCircleAtPoint(sx, sy, 2)
    end

    -- Big distance number
    gfx.setFont(boldFont)
    local distText = math.floor(distance) .. "m"
    gfx.drawTextAligned(distText, CENTER_X, 70, kTextAlignment.center)

    -- NEW RECORD label
    if Menu.animTimer % 20 < 15 then
        gfx.drawTextAligned("*NEW RECORD!*", CENTER_X, 100, kTextAlignment.center)
    end

    gfx.setFont(normalFont)
    gfx.drawTextAligned("Region: " .. regionName, CENTER_X, 130, kTextAlignment.center)

    -- Decorative line
    gfx.drawLine(CENTER_X - 80, 155, CENTER_X + 80, 155)

    -- Torchy celebrating
    Menu.drawCelebratingTorchy()

    -- Restart
    if Menu.animTimer % 40 < 30 then
        gfx.drawTextAligned("Press A to play again", CENTER_X, SCREEN_H - 30, kTextAlignment.center)
    end
end

function Menu.drawDeadTorchy()
    local gfx = playdate.graphics
    local tx = CENTER_X - 12
    local ty = 70

    -- Body (tilted/fallen)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRoundRect(tx, ty, 24, 20, 3)

    -- X eyes (dead)
    gfx.setColor(gfx.kColorWhite)
    -- Left X
    gfx.drawLine(tx + 5, ty + 5, tx + 9, ty + 9)
    gfx.drawLine(tx + 5, ty + 9, tx + 9, ty + 5)
    -- Right X
    gfx.drawLine(tx + 14, ty + 5, tx + 18, ty + 9)
    gfx.drawLine(tx + 14, ty + 9, tx + 18, ty + 5)

    -- Frown
    gfx.drawLine(tx + 8, ty + 15, tx + 16, ty + 13)

    -- No flame (dead torch)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(tx + 12, ty, tx + 12, ty - 6)
    -- Smoke puffs
    local smokeY = ty - 8 - math.abs(math.sin(Menu.animTimer * 0.1)) * 4
    gfx.drawCircleAtPoint(tx + 12, smokeY, 3)
    gfx.drawCircleAtPoint(tx + 14, smokeY - 4, 2)
end

function Menu.drawCelebratingTorchy()
    local gfx = playdate.graphics
    local bounce = math.sin(Menu.animTimer * 0.15) * 5
    local tx = CENTER_X - 10
    local ty = 165 + bounce

    -- Body
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRoundRect(tx, ty, 20, 24, 3)

    -- Happy eyes (^_^)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(tx + 4, ty + 7, tx + 8, ty + 5)
    gfx.drawLine(tx + 8, ty + 5, tx + 10, ty + 7)
    gfx.drawLine(tx + 12, ty + 7, tx + 14, ty + 5)
    gfx.drawLine(tx + 14, ty + 5, tx + 18, ty + 7)

    -- Smile
    gfx.drawLine(tx + 6, ty + 14, tx + 10, ty + 16)
    gfx.drawLine(tx + 10, ty + 16, tx + 14, ty + 14)

    -- Big flame (celebrating)
    gfx.setColor(gfx.kColorBlack)
    local flameX = tx + 10
    local flameH = 12 + math.abs(bounce)
    gfx.fillPolygon(flameX - 5, ty, flameX + 5, ty, flameX, ty - flameH)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillPolygon(flameX - 3, ty, flameX + 3, ty, flameX, ty - flameH * 0.6)
end

function Menu.handleInput()
    if playdate.buttonJustPressed(playdate.kButtonA) then
        return "start"
    end
    return nil
end

function Menu.setDeathInfo(distance, regionName, isNewHighScore)
    Menu.deathDistance = distance
    Menu.deathRegion = regionName
    Menu.isNewHighScore = isNewHighScore
    Menu.animTimer = 0
end

function Menu.reset()
    Menu.animTimer = 0
    Menu.selectedOption = 1
end

return Menu
