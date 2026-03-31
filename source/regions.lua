-- regions.lua - Region/biome definitions and difficulty scaling

Regions = {}

Regions.definitions = {
    {
        name = "The Spine",
        startDistance = 0,
        endDistance = 500,
        difficulty = "Intro",
        speedMultiplier = 1.0,
        platformWidth = 0.9,
        obstacleFrequency = 0.3,
        obstacleTypes = {"gap", "low_ceiling"},
        pipeCount = 3,
        hasTimeLimit = false,
        hasDecoys = false,
        gapChance = 0.15,
        movingObstacles = false,
        railPlatforms = false,
        description = "Wide platforms. Tutorial pace."
    },
    {
        name = "The Breach",
        startDistance = 500,
        endDistance = 1200,
        difficulty = "Normal",
        speedMultiplier = 1.2,
        platformWidth = 0.75,
        obstacleFrequency = 0.5,
        obstacleTypes = {"gap", "low_ceiling", "side_wall", "moving_block"},
        pipeCount = 4,
        hasTimeLimit = false,
        hasDecoys = false,
        gapChance = 0.25,
        movingObstacles = true,
        railPlatforms = false,
        description = "Narrower paths. Moving obstacles."
    },
    {
        name = "The Rift",
        startDistance = 1200,
        endDistance = 2200,
        difficulty = "Hard",
        speedMultiplier = 1.4,
        platformWidth = 0.6,
        obstacleFrequency = 0.7,
        obstacleTypes = {"gap", "low_ceiling", "side_wall", "moving_block", "rail_platform", "gravity_field"},
        pipeCount = 5,
        hasTimeLimit = true,
        timeLimitSeconds = 8,
        hasDecoys = false,
        gapChance = 0.35,
        movingObstacles = true,
        railPlatforms = true,
        description = "Split platforms. Gravity flip critical."
    },
    {
        name = "The Void",
        startDistance = 2200,
        endDistance = 4000,
        difficulty = "Expert",
        speedMultiplier = 1.65,
        platformWidth = 0.4,
        obstacleFrequency = 0.85,
        obstacleTypes = {"gap", "low_ceiling", "side_wall", "moving_block", "rail_platform", "gravity_field", "dual_gap", "ramp_combo"},
        pipeCount = 5,
        hasTimeLimit = true,
        timeLimitSeconds = 6,
        hasDecoys = true,
        gapChance = 0.45,
        movingObstacles = true,
        railPlatforms = true,
        description = "Rail-thin platforms. Rapid obstacles."
    },
    {
        name = "The Endless",
        startDistance = 4000,
        endDistance = 999999,
        difficulty = "Infinite",
        speedMultiplier = 2.0,
        platformWidth = 0.35,
        obstacleFrequency = 1.0,
        obstacleTypes = {"gap", "low_ceiling", "side_wall", "moving_block", "rail_platform", "gravity_field", "dual_gap", "ramp_combo"},
        pipeCount = 5,
        hasTimeLimit = true,
        timeLimitSeconds = 5,
        hasDecoys = true,
        gapChance = 0.5,
        movingObstacles = true,
        railPlatforms = true,
        description = "Procedurally generated. No ceiling."
    }
}

function Regions.getRegionForDistance(distance)
    for i, region in ipairs(Regions.definitions) do
        if distance >= region.startDistance and distance < region.endDistance then
            return i, region
        end
    end
    return #Regions.definitions, Regions.definitions[#Regions.definitions]
end

function Regions.getSpeedMultiplier(distance)
    local _, region = Regions.getRegionForDistance(distance)
    local regionProgress = 0
    if region.endDistance - region.startDistance > 0 then
        regionProgress = (distance - region.startDistance) / (region.endDistance - region.startDistance)
        regionProgress = math.min(regionProgress, 1.0)
    end
    local nextIdx = math.min(#Regions.definitions, _ + 1)
    local nextRegion = Regions.definitions[nextIdx]
    return region.speedMultiplier + (nextRegion.speedMultiplier - region.speedMultiplier) * regionProgress * 0.5
end

function Regions.getPlatformWidth(distance)
    local _, region = Regions.getRegionForDistance(distance)
    return region.platformWidth
end

function Regions.getObstacleFrequency(distance)
    local _, region = Regions.getRegionForDistance(distance)
    return region.obstacleFrequency
end

function Regions.shouldSpawnRamp(distance, lastRampDistance)
    local interval = 500
    return (distance - lastRampDistance) >= interval
end

function Regions.getNextRegionDistance(currentDistance)
    local idx, region = Regions.getRegionForDistance(currentDistance)
    return region.endDistance
end
