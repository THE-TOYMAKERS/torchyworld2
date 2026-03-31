-- hud.lua - HUD rendering, score display, distance counter

local Utils = import "utils"

local HUD = {}

local SCREEN_W = 400
local SCREEN_H = 240

function HUD.init()
    HUD.distance = 0
    HUD.highScore = 0
    HUD.regionName = ""
    HUD.regionFadeTimer = 0
    HUD.regionFadeDuration = 90  -- 3 seconds at 30fps
    HUD.comboCount = 0
    HUD.comboFadeTimer = 0
    HUD.showHighScoreBadge = false
    HUD.airTimeBonus = 0
    HUD.bonusFadeTimer = 0
end

function HUD.update(distance, highScore, regionName, comboCount)
    -- Update distance
    HUD.distance = math.floor(distance)
    HUD.highScore = math.floor(highScore)
    HUD.showHighScoreBadge = (highScore > 0)

    -- Region name fade
    if regionName ~= HUD.regionName and regionName ~= "" then
        HUD.regionName = regionName
        HUD.regionFadeTimer = HUD.regionFadeDuration
    end
    if HUD.regionFadeTimer > 0 then
        HUD.regionFadeTimer = HUD.regionFadeTimer - 1
    end

    -- Combo display
    if comboCount > HUD.comboCount and comboCount >= 3 then
        HUD.comboFadeTimer = 45  -- 1.5 seconds
    end
    HUD.comboCount = comboCount

    -- Bonus fade
    if HUD.bonusFadeTimer > 0 then
        HUD.bonusFadeTimer = HUD.bonusFadeTimer - 1
    end
end

function HUD.showAirTimeBonus(bonus)
    HUD.airTimeBonus = bonus
    HUD.bonusFadeTimer = 60  -- 2 seconds
end

function HUD.draw()
    local gfx = playdate.graphics
    local font = gfx.getSystemFont()
    gfx.setFont(font)
    gfx.setColor(gfx.kColorBlack)

    -- Distance counter (top-right)
    local distText = HUD.distance .. "m"
    local textW = gfx.getTextSize(distText)
    -- Background box
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(SCREEN_W - textW - 14, 2, textW + 12, 18)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(SCREEN_W - textW - 14, 2, textW + 12, 18)
    gfx.drawText(distText, SCREEN_W - textW - 8, 5)

    -- High score badge (top-left)
    if HUD.showHighScoreBadge then
        local hsText = "HI:" .. HUD.highScore .. "m"
        local hsW = gfx.getTextSize(hsText)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(2, 2, hsW + 12, 18)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(2, 2, hsW + 12, 18)
        gfx.drawText(hsText, 8, 5)
    end

    -- Region name (center, fading)
    if HUD.regionFadeTimer > 0 then
        local fadeAlpha = HUD.regionFadeTimer / HUD.regionFadeDuration
        local boldFont = gfx.getSystemFont(gfx.font.kVariantBold)
        gfx.setFont(boldFont)

        local regionText = "* " .. HUD.regionName .. " *"
        local rw = gfx.getTextSize(regionText)

        -- Fade effect using position (slide up as it fades)
        local yOffset = (1 - fadeAlpha) * 10
        local ry = SCREEN_H / 2 - 30 - yOffset

        if HUD.regionFadeTimer > HUD.regionFadeDuration * 0.3 then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(SCREEN_W / 2 - rw / 2 - 8, ry - 4, rw + 16, 24)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(SCREEN_W / 2 - rw / 2 - 8, ry - 4, rw + 16, 24)
            gfx.drawTextAligned(regionText, SCREEN_W / 2, ry, kTextAlignment.center)
        end

        gfx.setFont(font)
    end

    -- Combo counter
    if HUD.comboFadeTimer > 0 then
        HUD.comboFadeTimer = HUD.comboFadeTimer - 1
        local comboText = "COMBO x" .. HUD.comboCount
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(SCREEN_W / 2 - 40, SCREEN_H - 35, 80, 16)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawTextAligned(comboText, SCREEN_W / 2, SCREEN_H - 33, kTextAlignment.center)
    end

    -- Air Time bonus popup
    if HUD.bonusFadeTimer > 0 then
        local bonusText = "+" .. HUD.airTimeBonus .. "m BONUS!"
        local bw = gfx.getTextSize(bonusText)
        local yOff = (1 - HUD.bonusFadeTimer / 60) * 20
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(SCREEN_W / 2 - bw / 2 - 6, 55 - yOff, bw + 12, 20)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(SCREEN_W / 2 - bw / 2 - 6, 55 - yOff, bw + 12, 20)
        gfx.drawTextAligned(bonusText, SCREEN_W / 2, 58 - yOff, kTextAlignment.center)
    end
end

function HUD.reset()
    HUD.init()
end

return HUD
