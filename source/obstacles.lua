-- obstacles.lua - Obstacle generation and management

local Utils = import "utils"
local Regions = import "regions"

local Obstacles = {}

-- Obstacle pool
Obstacles.active = {}
Obstacles.spawnTimer = 0
Obstacles.spawnInterval = 60  -- frames between spawns (adjusted by region)
Obstacles.lastRampDistance = 0
Obstacles.rampActive = false

function Obstacles.init()
    Obstacles.active = {}
    Obstacles.spawnTimer = 0
    Obstacles.lastRampDistance = 0
    Obstacles.rampActive = false
end

function Obstacles.createObstacle(obstacleType, distance)
    local obs = {
        type = obstacleType,
        depth = 1.0,          -- starts at far end (vanishing point)
        spawnDistance = distance,
        active = true,
        extraData = {}
    }

    -- Set up type-specific data
    if obstacleType == "side_wall" then
        obs.extraData.side = math.random() > 0.5 and "left" or "right"
    elseif obstacleType == "moving_block" then
        obs.extraData.offsetX = 0
        obs.extraData.moveSpeed = Utils.randomFloat(0.02, 0.05)
        obs.extraData.moveDir = math.random() > 0.5 and 1 or -1
        obs.extraData.movePhase = math.random() * math.pi * 2
    end

    return obs
end

function Obstacles.update(speed, distance, regionIndex)
    local region = Regions.definitions[regionIndex]
    if not region then return end

    -- Update spawn interval based on region
    local baseInterval = 45
    Obstacles.spawnInterval = math.max(15, baseInterval / region.obstacleFrequency)

    -- Move existing obstacles toward the player
    local moveSpeed = speed * 0.008
    local toRemove = {}

    for i, obs in ipairs(Obstacles.active) do
        obs.depth = obs.depth - moveSpeed

        -- Update moving blocks
        if obs.type == "moving_block" and obs.extraData then
            obs.extraData.movePhase = (obs.extraData.movePhase or 0) + (obs.extraData.moveSpeed or 0.03)
            obs.extraData.offsetX = math.sin(obs.extraData.movePhase)
        end

        -- Remove if past the player
        if obs.depth < -0.1 then
            table.insert(toRemove, i)
        end
    end

    -- Remove expired obstacles (reverse order to maintain indices)
    for i = #toRemove, 1, -1 do
        table.remove(Obstacles.active, toRemove[i])
    end

    -- Check if we should spawn a ramp for Air Time
    if Regions.shouldSpawnRamp(distance, Obstacles.lastRampDistance) and not Obstacles.rampActive then
        Obstacles.spawnRamp(distance)
        return  -- don't spawn other obstacles near a ramp
    end

    -- Spawn new obstacles
    Obstacles.spawnTimer = Obstacles.spawnTimer + 1
    if Obstacles.spawnTimer >= Obstacles.spawnInterval then
        Obstacles.spawnTimer = 0
        Obstacles.spawnObstacle(distance, region)
    end
end

function Obstacles.spawnObstacle(distance, region)
    if #Obstacles.active >= 12 then return end  -- cap active obstacles

    -- Pick a random obstacle type from the region's allowed types
    local types = region.obstacleTypes
    if not types or #types == 0 then return end

    local obstacleType = types[math.random(1, #types)]

    -- Don't spawn ramp_combo too often
    if obstacleType == "ramp_combo" and math.random() > 0.3 then
        obstacleType = types[math.random(1, math.min(3, #types))]
    end

    local obs = Obstacles.createObstacle(obstacleType, distance)
    table.insert(Obstacles.active, obs)
end

function Obstacles.spawnRamp(distance)
    local obs = Obstacles.createObstacle("ramp", distance)
    table.insert(Obstacles.active, obs)
    Obstacles.rampActive = true
end

function Obstacles.checkCollision(playerCoords, playerOnCeiling)
    if not playerCoords then return nil end

    local playerDepth = playerCoords.depthT
    local collisionRange = 0.06  -- depth range for collision

    for _, obs in ipairs(Obstacles.active) do
        if obs.active and math.abs(obs.depth - playerDepth) < collisionRange then
            local hit = Obstacles.testCollision(obs, playerCoords, playerOnCeiling)
            if hit then
                return hit
            end
        end
    end

    return nil
end

function Obstacles.testCollision(obs, playerCoords, playerOnCeiling)
    local obsType = obs.type

    if obsType == "gap" then
        -- Gap: player dies if on floor
        if not playerOnCeiling then
            return {type = "death", obstacle = "gap"}
        end
    elseif obsType == "low_ceiling" then
        -- Low ceiling: player dies if on ceiling
        if playerOnCeiling then
            return {type = "death", obstacle = "low_ceiling"}
        end
    elseif obsType == "side_wall" then
        -- Side wall: always hits (must dodge with timing)
        return {type = "death", obstacle = "side_wall"}
    elseif obsType == "moving_block" then
        -- Moving block: check position overlap
        -- Simplified: if the block is roughly centered, it hits
        local offsetX = obs.extraData and obs.extraData.offsetX or 0
        if math.abs(offsetX) < 0.5 then
            return {type = "death", obstacle = "moving_block"}
        end
    elseif obsType == "rail_platform" then
        -- Rail: must be precisely on the rail (narrow tolerance)
        -- For now, slight random chance of death based on region
        if math.random() < 0.15 then
            return {type = "death", obstacle = "rail_platform"}
        end
    elseif obsType == "gravity_field" then
        -- Auto-flips gravity
        return {type = "gravity_flip", obstacle = "gravity_field"}
    elseif obsType == "dual_gap" then
        -- Gap on both floor and ceiling - must be mid-flip
        return {type = "death", obstacle = "dual_gap"}
    elseif obsType == "ramp" then
        -- Ramp triggers Air Time
        obs.active = false
        Obstacles.rampActive = false
        return {type = "airtime", obstacle = "ramp"}
    end

    return nil
end

function Obstacles.draw(Renderer)
    -- Draw obstacles from far to near for proper depth ordering
    table.sort(Obstacles.active, function(a, b) return a.depth > b.depth end)

    for _, obs in ipairs(Obstacles.active) do
        if obs.depth >= 0 and obs.depth <= 1 then
            Renderer.drawObstacle(obs.type, obs.depth, obs.extraData)
        end
    end
end

function Obstacles.reset()
    Obstacles.init()
end

function Obstacles.getRampActive()
    return Obstacles.rampActive
end

function Obstacles.setLastRampDistance(d)
    Obstacles.lastRampDistance = d
end

return Obstacles
