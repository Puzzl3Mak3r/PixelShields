---------------------------------------------
--    Important Stuff to Declare First
---------------------------------------------
local cx, cy = display.contentCenterX, display.contentCenterY
local physics = require "physics"
physics.start()
physics.setGravity( 0, 0 )
system.activate("multitouch")

local playing = true
local score = 0
local fasterM = 1
local lives = 5
local spawnD1, spawnD2 = 13, 15
local enemiesList = {}




---------------------------------------------
--    Touch Controls
---------------------------------------------

-- Create 4 touch controls
local rectUp = display.newRect( cx, cy, 707, 707 )
local rectDown = display.newRect( cx, cy, 707, 707 )
local rectLeft = display.newRect( cx, cy, 707, 707 )
local rectRight = display.newRect( cx, cy, 707, 707 )
rectUp.rotation = 45
rectDown.rotation = 135
rectLeft.rotation = 225
rectRight.rotation = 315
rectUp.fill = {0, 0, 0}
rectDown.fill = {0, 0, 0}
rectLeft.fill = {0, 0, 0}
rectRight.fill = {0, 0, 0}
rectDown.x, rectDown.y = cx, cy+500
rectUp.x, rectUp.y = cx, cy-500
rectLeft.x, rectLeft.y = cx-500, cy
rectRight.x, rectRight.y = cx+500, cy 
-- rectUp.alpha, rectDown.alpha, rectLeft.alpha, rectRight.alpha = 0.001, 0.001, 0.001, 0.001



---------------------------------------------
--    Buncha Text
---------------------------------------------

local livesText = display.newText( "Lives: " .. lives, 90, 80, native.systemFont, 35 )
local scoreText = display.newText( "Score: " .. score * 10, 90, 30, native.systemFont, 35 )
local scoreTextDeath = display.newText( "", cx, cy+40, native.systemFont, 50 )
local restartBtn = display.newText( "", cx, cy-40, native.systemFont, 50 )

-- Create 4 texts, 1 for each direction, example: "w / up arrow"
local upTextGuide = display.newText( "w / up arrow", cx, cy-250, native.systemFont, 50 )
local downTextGuide = display.newText( "s / down arrow", cx, cy+250, native.systemFont, 50 )
local leftTextGuide = display.newText( "a / left arrow", cx-250, cy, native.systemFont, 50 )
local rightTextGuide = display.newText( "d / right arrow", cx+250, cy, native.systemFont, 50 )
-- Tween all alphas out in 500ms with a delay of 900ms
local function tweenOutGuides()
    transition.to( upTextGuide, { time=500, delay=900, alpha=0, transition=easing.linear} )
    transition.to( downTextGuide, { time=500, delay=900, alpha=0, transition=easing.linear} )
    transition.to( leftTextGuide, { time=500, delay=900, alpha=0, transition=easing.linear} )
    transition.to( rightTextGuide, { time=500, delay=900, alpha=0, transition=easing.linear} )
end
tweenOutGuides()



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
        -- Remove restart button
        Runtime:removeEventListener( "touch", restart )
        restartBtn:removeSelf()
        restartBtn = nil

        -- Reset Game
        physics.start()
        timer.resumeAll()
        player:setSequence("idle")
        player:play()
        shield.rotation = 0
        shield.x, shield.y = cx, cy - offset
        spawnD1, spawnD2 = 13, 15
        fasterM = 1
        shield.alpha = 1
        playing = true
        lives = 5
        score = 0

        scoreText.text = "Score: 0"
        scoreTextDeath.text = ""
        livesText.text = "Lives: " .. lives
        livesText.text = "Lives: " .. lives

        upTextGuide.alpha = 1
        downTextGuide.alpha = 1
        leftTextGuide.alpha = 1
        rightTextGuide.alpha = 1
        tweenOutGuides()
    end
end

-- Game Over
local function gameOver()
    if lives == 0 or lives < 1 then
        -- Remove all enemies
        for i = #enemiesList, 1, -1 do
            local thisEnemy = enemiesList[i]
            table.remove( enemiesList, i )
            display.remove( thisEnemy )
        end

        -- Anounce death
        player:setSequence("dead")
        print( "Game Over" )
        playing = false
        shield.alpha = 0

        -- Anounce score and offer restart
        restartBtn = display.newText( "", cx, cy-40, native.systemFont, 50 )
        restartBtn.x, restartBtn.y = cx, cy+80
        scoreTextDeath.x, scoreTextDeath.y = cx, cy-80

        scoreTextDeath.text = "Your Score is " .. score * 10 .. "!"
        restartBtn.text = "Restart?"
        scoreText.text = ""
        livesText.text = ""

        physics.pause()
        timer.pauseAll()
        Runtime:addEventListener( "touch", restart )
    else
        -- Update Lives Text
        livesText.text = "Lives: " .. lives
    end
end

-- Flipperoonie Cool Shit
local function specificFlipFunction(self)
    if self.x > 250 and self.x < 750 and self.y > 250 and self.y < 750 then
        self.enterFrame = nil
        Runtime:removeEventListener( specificFlipFunction )
        self:setLinearVelocity( 0,0 )

        print( "Facing: ")
        print( self.dir )

        if self.dir == "up" then
            -- Move left
            transition.to( self, { time = 180, transition=easing.outSine, x=cx+200 } )
            transition.to( self, { time = 180, transition=easing.inSine, y=cy } )
            -- Move down
            transition.to( self, { time = 180, delay = 180,  transition=easing.inSine, x=cx } )
            transition.to( self, { time = 180, delay = 180,  transition=easing.outSine, y=cy+200 } )
        elseif self.dir == "down" then
            -- Move right
            transition.to( self, { time = 180, transition=easing.outSine, x=cx-200 } )
            transition.to( self, { time = 180, transition=easing.inSine, y=cy } )
            -- Move up
            transition.to( self, { time = 180, delay = 180,  transition=easing.inSine, x=cx } )
            transition.to( self, { time = 180, delay = 180,  transition=easing.outSine, y=cy-200 } )
        elseif self.dir == "left" then
            -- Move down
            transition.to( self, { time = 180, transition=easing.inSine, x=cx } )
            transition.to( self, { time = 180, transition=easing.outSine, y=cy+200 } )
            -- Move right
            transition.to( self, { time = 180, delay = 180,  transition=easing.outSine, x=cx+200 } )
            transition.to( self, { time = 180, delay = 180,  transition=easing.inSine, y=cy } )
        elseif self.dir == "right" then
            -- Move up
            transition.to( self, { time = 180, transition=easing.inSine, x=cx } )
            transition.to( self, { time = 180, transition=easing.outSine, y=cy-200 } )
            -- Move left
            transition.to( self, { time = 180, delay = 180,  transition=easing.outSine, x=cx-200 } )
            transition.to( self, { time = 180, delay = 180,  transition=easing.inSine, y=cy } )
        end
        -- Get to center
        transition.to( self, { time=180, delay=360, transition=easing.linear, x=cx, y=cy } )
    end
end

-- Collision Handler
local function onLocalCollision(self, event)
    if event.other.isShield and self.type == "UnoReverse" then
        lives = lives - 1
        gameOver()
    elseif event.other.isShield then
        -- Remove Most recent Enemy from list
        table.remove( enemiesList, 1 )

        -- Add Score
        -- Special Enemy is 3 points
        if self.type == "Flipperoonie" then
            score = score + 1
        end
        score = score + 1
        scoreText.text = "Score: " .. score * 10

        -- Remove Enemy
        display.remove( self )
        print( "hit" )
        event.isEnemy = false

        -- Lower spawn delay if score is high
        if score > 50 then
            fasterM = 1.5
        elseif score > 35 then
            spawnD1, spawnD2 = 5,7
        elseif score > 25 then
            fasterM = 1.2
        elseif score > 17 then
            spawnD1, spawnD2 = 7,9
        elseif score > 10 then
            spawnD1, spawnD2 = 10,12
        end
    end
    if event.other.isPlayer and self.type == "UnoReverse" then
        score = score + 2
        scoreText.text = "Score: " .. score
        table.remove( enemiesList, 1 )
        display.remove( self )
        event.isEnemy = false
    elseif event.other.isPlayer then
        -- Remove Enemy & Game end
        lives = lives - 1
        livesText.text = "Lives: " .. lives
        if lives < 1 then
            gameOver()
        end
        display.remove( self )
        print( "hit" )
        event.isEnemy = false
    end

    if event.other.isShield and self.type == "UnoReverse" then
        if lives < 1 then
            gameOver()
        end
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
        -- Add enemy to list
        table.insert( enemiesList, enemy )
        print( "spawn success" )

        -- Make enemy move
        -- Choose random direction / spawn location
        local orientation = {"up", "down", "left", "right"}
        local r = math.random(1, 4)
        local direction = orientation[r]
        enemy.x, enemy.y = Xpos[r], Ypos[r]

        -- Chance for special enemies
        -- Move till death
        physics.addBody(enemy, "dynamic")
        local randomSpeed = ((math.random(25, 40))/20) * fasterM
        if (math.random(1, 8) == 1) and (score > 4) then
            enemy.type = "Slow"
            enemy:scale( 1.5, 1.5 )
            enemy:setLinearVelocity( xSpeed[r], ySpeed[r] )
        elseif (math.random(1, 4) == 1) and (score > 9) then
            enemy.type = "Flipperoonie"
            enemy.dir = direction
            enemy:scale( 1.5, 1.5 )
            enemy.fill = { 1, 0, 1 }
            enemy:setLinearVelocity( xSpeed[r] * randomSpeed, ySpeed[r] * randomSpeed )
            -- Call function when x and y are in range
            enemy.enterFrame = specificFlipFunction
            Runtime:addEventListener("enterFrame", enemy)
        elseif true then
        -- elseif (math.random(1, 4) == 1) and (score > 29) then
            enemy.type = "UnoReverse"
            enemy:scale( 1.5, 1.5 )
            enemy:setLinearVelocity( xSpeed[r], ySpeed[r] )
            enemy.fill = { 0, 1, 1 }
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
--    Inputs
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
-- functions
local function doIt(var)
    if playing then
        print(var)
        print("called")
        if var == "up" then
            shield.x = cx
            shield.y = cy - offset
            shield.rotation = 0
            player:setSequence("up")
            player:play()
        elseif var == "down" then
            shield.x = cx
            shield.y = cy + offset
            shield.rotation = 180
            player:setSequence("down")
            player:play()
        elseif var == "left" then
            shield.x = cx - offset
            shield.y = cy
            shield.rotation = -90
            player:setSequence("left")
            player:play()
        elseif var == "right" then
            shield.x = cx + offset
            shield.y = cy
            shield.rotation = 90
            player:setSequence("right")
            player:play()
        end
    end
end
local function checkPress(event)
    if playing then
        -- Early restart
        if pressedKeys["r"] then
            gameOver()
        end
    end
    -- Check if keys are pressed
    if pressedKeys["w"] or pressedKeys["up"] then
        doIt("up")
    end
    if pressedKeys["a"] or pressedKeys["left"] then
        doIt("left")
    end
    if pressedKeys["s"] or pressedKeys["down"] then
        doIt("down")
    end
    if pressedKeys["d"] or pressedKeys["right"] then
        doIt("right")
    end
end
-- Add touch listeners
local function startTouchListener()
    rectUp:addEventListener   ("touch", function(event) if event.phase == "began" then doIt("up")    end end)
    rectDown:addEventListener ("touch", function(event) if event.phase == "began" then doIt("down")  end end)
    rectLeft:addEventListener ("touch", function(event) if event.phase == "began" then doIt("left")  end end)
    rectRight:addEventListener("touch", function(event) if event.phase == "began" then doIt("right") end end)
end
startTouchListener()
-- Add key press listeners
Runtime:addEventListener( "key", onKeyEvent )
Runtime:addEventListener( "key", checkPress )
