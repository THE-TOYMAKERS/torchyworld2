-- utils.lua - Utility functions for Air Time

Utils = {}

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function Utils.sign(x)
    if x > 0 then return 1
    elseif x < 0 then return -1
    else return 0 end
end

function Utils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Utils.mapRange(value, inMin, inMax, outMin, outMax)
    return outMin + (outMax - outMin) * ((value - inMin) / (inMax - inMin))
end

function Utils.easeInOut(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

function Utils.easeOut(t)
    return 1 - (1 - t) * (1 - t)
end

function Utils.easeIn(t)
    return t * t
end

function Utils.randomFloat(min, max)
    return min + math.random() * (max - min)
end

function Utils.drawDashedLine(x1, y1, x2, y2, dashLen, gapLen)
    local dx = x2 - x1
    local dy = y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return end
    local nx = dx / len
    local ny = dy / len
    local pos = 0
    while pos < len do
        local startX = x1 + nx * pos
        local startY = y1 + ny * pos
        local endPos = math.min(pos + dashLen, len)
        local endX = x1 + nx * endPos
        local endY = y1 + ny * endPos
        playdate.graphics.drawLine(startX, startY, endX, endY)
        pos = endPos + gapLen
    end
end

-- Playdate import: global table, no return needed
