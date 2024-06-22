---------------------------------------------
--    Important Stuff to Declare First
---------------------------------------------
local cx, cy = display.contentCenterX, display.contentCenterY
physics = require "physics"
physics.start()
physics.setGravity( 0, 0 )
local playing = true
local score = 0
local fasterM = 1
local spawnD1, spawnD2 = 13, 15
local restart = false
local scoreText = display.newText( "Score: " .. score, 70, 30, native.systemFont, 30 )
local scoreTextDeath = display.newText( "", cx, cy+40, native.systemFont, 50 )
local restartBtn = display.newText( "", cx, cy-40, native.systemFont, 50 )
-- physics.setDrawMode( "hybrid" )



---------------------------------------------
--    Visual Elements
---------------------------------------------

-- Create Player & Player Hitbox
local playerFrameSize =
{
    width = 17*5,
    height = 13*5,
    numFrames = 6
}
local playerSheet = graphics.newImageSheet( "AssetResources/smileySheet.png", playerFrameSize )
    -- sequences table
    local playerSequences = {
      {
        name="right",
        frames= { 1 }, -- frame indexes of animation, in image sheet
        time = 1
      },
      {
        name="left",
        frames= { 2 }, -- frame indexes of animation, in image sheet
        time = 1
      },
      {
        name="idle",
        frames= { 3 }, -- frame indexes of animation, in image sheet
        time = 1
      },
      {
        name="up",
        frames= { 4 }, -- frame indexes of animation, in image sheet
        time = 1
      },
      {
        name="down",
        frames= { 5 }, -- frame indexes of animation, in image sheet
        time = 1
      },
      {
        name="dead",
        frames= { 6 }, -- frame indexes of animation, in image sheet
        time = 1
      }
    }
local player = display.newSprite( playerSheet, playerSequences )
local playerHitbox = display.newRect( 0, 0, 80, 70 )
player:setSequence("idle")
player:play()
player.x , player.y = cx , cy
playerHitbox.x, playerHitbox.y, playerHitbox.alpha = player.x, player.y, 0
player:scale( 1.2, 1.2 )
physics.addBody( playerHitbox, "static" )
playerHitbox.isPlayer = true


-- Make shield
local shield = display.newImageRect( "AssetResources/shield.png", 155/1.3, 50/1.3 )
local offset = 80
shield.isShield = true
shield.x = cx
shield.y = cy - offset
physics.addBody( shield, "static" )


-- Enemy information
local orientation = {"up", "down", "left", "right"}
local enemySpeed = 3.5
local Xpos      = {cx, cx, 0, (cx*2)}
local Ypos      = {0, (cy*2), cy, cy}
local xSpeed    = {0, 0, 100*enemySpeed, -100*enemySpeed}
local ySpeed    = {100*enemySpeed, -100*enemySpeed, 0, 0}
local option = false




---------------------------------------------
--    Functions
---------------------------------------------

-- Restart
local function restart(event)
    if event.phase == "began" then
        print( "restart" )
        Runtime:removeEventListener( restart )
        physics.start()
        timer.resumeAll()
        player:setSequence("idle")
        player:play()
        shield.rotation = 0
        shield.x, shield.y = cx, cy - offset
        spawnD1, spawnD2 = 13, 15
        fasterM = 1

        score = 0

        scoreText.text = "Score: 0"
        scoreTextDeath.text = ""
        restartBtn.text = ""

        shield.alpha = 1

        playing = true
    end
end

-- Game Over
local function gameOver()
    player:setSequence("dead")
    print( "Game Over" )
    playing = false
    restartBtn.x, restartBtn.y = cx, cy+80
    scoreTextDeath.x, scoreTextDeath.y = cx, cy-80

    scoreTextDeath.text = "Your Score is " .. score .. "!"
    restartBtn.text = "Restart?"
    scoreText.text = ""

    shield.alpha = 0

    physics.pause()
    timer.pauseAll()
    Runtime:addEventListener( "touch", restart )
end

-- Collision Handler
local function onLocalCollision(self, event)
    if event.other.isShield then
        -- Add Score
        -- Special Enemy is 3 points
        if event.isSpecial then
            score = score + 2
        end
        score = score + 1
        scoreText.text = "Score: " .. score

        -- Remove Enemy
        display.remove( self )
        print( "hit" )
        event.isEnemy = false

        -- Lower spawn delay if score is high
        if score > 50 then
            fasterM = 1.5
        elseif score > 35 then
            spawnD1, spawnD2 = 2,3
        elseif score > 25 then
            spawnD1, spawnD2 = 5,7
            fasterM = 1.2
        elseif score > 17 then
            spawnD1, spawnD2 = 7,9
        elseif score > 10 then
            spawnD1, spawnD2 = 10,12
        end
    end
    if event.other.isPlayer then
        -- Remove Enemy & Game end
        gameOver()
        display.remove( self )
        print( "hit" )
        event.isEnemy = false
    end
end

-- Spawn enemies
function spawnEnemies()
    if option and playing then
        option = false
        -- Create enemy
        -- local enemy = display.newImageRect( "enemy.png", 20, 20 )
        enemy = display.newRect( 0, 0, 20, 20 )
        enemy.fill = { 1, 0, 0 }
        enemy.isEnemy = true
        print( "spawn success" )

        -- Make enemy move
        -- Choose random direction / spawn
        local r = math.random(1, 4)
        local direction = orientation[r]
        enemy.x, enemy.y = Xpos[r], Ypos[r]

        -- 1 in 8 chance to spawn special enemy
        -- Move till death
        physics.addBody(enemy, "dynamic")
        local randomSpeed = ((math.random(25, 40))/20) * fasterM
        if (math.random(1, 8) == 1) and (score > 20) then
            enemy.type = "Reverse"
            enemy:scale( 1.5, 1.5 )
            enemy:setLinearVelocity( xSpeed[r], ySpeed[r] )
        elseif (math.random(1, 4) == 1) and (score > 50) then
            enemy.type = "Flipperoonie"
            enemy:scale( 1.5, 1.5 )
            enemy.fill = { 0, 0, 1 }
            enemy:setLinearVelocity( xSpeed[r] * randomSpeed, ySpeed[r] * randomSpeed )
        else
            enemy.type = "Normal"
            enemy:setLinearVelocity( xSpeed[r] * randomSpeed, ySpeed[r] * randomSpeed )
        end

        if enemy.y <= -10 or enemy.y >= (2*cy+10) or enemy.x <= -10 or enemy.x >= (2*cx+10) then
            display.remove( enemy )
        end

        -- Collision detection
        enemy.collision = onLocalCollision
        enemy:addEventListener( "collision" )
    end
end Runtime:addEventListener( "enterFrame", spawnEnemies ) -- Run every frame

-- Spawn Loop every random 2000ms to 5000ms spawns
local count = 0
local randm = math.random(spawnD1, spawnD2)
local function randomiseSpawnTimings()
    count = count + 1
    -- print( "count is: " .. count ) -- Annoying :(
        if count == randm then
        option = true
        randm = math.random(spawnD1, spawnD2)
        count = 0
    end
end
timer.performWithDelay(120,randomiseSpawnTimings,0)



---------------------------------------------
--    Key Presses
---------------------------------------------

-- Check Key presses
local pressedKeys = {}
local function onKeyEvent(event)
    if event.phase == "down" then
        pressedKeys[event.keyName] = true
    elseif event.phase == "up" then
        pressedKeys[event.keyName] = false
    else
        pressedKeys[event.keyName] = false
    end
end
local function checkPress(event)
    if playing then
        if pressedKeys["w"] or pressedKeys["up"] then
            shield.x = cx
            shield.y = cy - offset
            shield.rotation = 0
            player:setSequence("up")
            player:play()
        end
        if pressedKeys["a"] or pressedKeys["left"] then
            shield.x = cx - offset
            shield.y = cy
            shield.rotation = -90
            player:setSequence("left")
            player:play()
        end
        if pressedKeys["s"] or pressedKeys["down"] then
            shield.x = cx
            shield.y = cy + offset
            shield.rotation = 180
            player:setSequence("down")
            player:play()
        end
        if pressedKeys["d"] or pressedKeys["right"] then
            shield.x = cx + offset
            shield.y = cy
            shield.rotation = 90
            player:setSequence("right")
            player:play()
        end
        if not pressedKeys["w"] or not pressedKeys["a"] or not pressedKeys["s"] or not pressedKeys["d"] then
            player:setSequence("idle")
            player:play()
        end
    end
end
Runtime:addEventListener( "key", onKeyEvent )
Runtime:addEventListener( "key", checkPress )