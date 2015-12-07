local sceneName = "levels"
local composer = require( "composer" )

local sqlite3 = require( "sqlite3" )

local widget = require( "widget" )

local path = system.pathForFile( "data.db", system.DocumentsDirectory )
local db = sqlite3.open( path )

local scene = composer.newScene()

local maxLevels

local background
local contentWidth = display.contentWidth
local contentHeight = display.contentHeight
local originX = display.screenOriginX
local originY = display.screenOriginY
local height = contentHeight-originY*2

local textSize = contentWidth/8
local textSizeTitle = contentWidth/7
local buttonBack

local pink = { 1, 0.4, 0.4}

local starVertices = { 0,-8,1.763,-2.427,7.608,-2.472,2.853,0.927,4.702,6.472,0.0,3.0,-4.702,6.472,-2.853,0.927,-7.608,-2.472,-1.763,-2.427 }

-----------------------------------------------------------

local world = composer.getVariable("world")

local function handleLevelSelect( event )
    if ( "ended" == event.phase ) then
        -- 'event.target' is the button and '.id' is a number indicating which level to go to.  
        -- The 'game' scene will use this setting to determine which level to load.
        -- This could be done via passed parameters as well.
        
        composer.setVariable("worldTarget",world)
        composer.setVariable("levelTarget",event.target.id)
        composer.setVariable("origin",1)
        composer.gotoScene( "game", { effect = "fade", time = 200 } )
        -- Purge the game scene so we have a fresh start
        --composer.removeScene( "game", false )

        -- Go to the game scene
        --composer.gotoScene( "game", { effect="crossFade", time=333 } )
    end
end

-- Declare the Composer event handlers
-- On scene create...
function scene:create( event )
    local sceneGroup = self.view
background = display.newRect( contentWidth/2, contentHeight/2, contentWidth, height)
       background:setFillColor(0.59,0.99,0.79)
       sceneGroup:insert(background)
end

-- On scene show...
function scene:show( event )
    local sceneGroup = self.view
    if ( event.phase == "will" ) then

        local function getCurrentLevel(worldAux)
  local retCurrentLevel
    for row in db:nrows("SELECT * FROM data WHERE id="..worldAux) do
        retCurrentLevel=row.info
    end
  if(retCurrentLevel==NULL) then
      retCurrentLevel = 0
  end
  return retCurrentLevel  
end

local function getStars(worldAux, levelAux)
  local retStars
    for row in db:nrows("SELECT * FROM world"..worldAux.." WHERE id="..levelAux) do
        retStars=row.stars
    end
    if(retStars==NULL) then
      retStars = 0
    end
  return retStars
end



    -- Use a scrollView to contain the level buttons (for support of more than one full screen).
    -- Since this will only scroll vertically, lock horizontal scrolling.
    local levelSelectGroup = widget.newScrollView({
        width = contentWidth,
        height = contentHeight+originY,

        scrollWidth = contentWidth,
        scrollHeight = contentHeight+originY/2,
        backgroundColor = { 0.59,0.99,0.79 },
        horizontalScrollDisabled = true
        --x = contentWidth/2,
        --y = (contentHeight/2)+originY
    })


    -- 'xOffset', 'yOffset' and 'cellCount' are used to position the buttons in the grid.
    local xOffset = contentWidth*3/14
    local yOffset = -originY
    local cellCount = 1

    -- Define the array to hold the buttons
    local buttons = {}

    -- Read 'maxLevels' from the 'myData' table. Loop over them and generating one button for each.
if(world == 1)then
           maxLevels = 6
           elseif(world == 2)then
            maxLevels = 12
            elseif(world == 3)then
                maxLevels = 18
        end
    
    for i = 1, maxLevels do
        -- Create a button
        buttons[i] = widget.newButton({
            label = tostring( i ),
            id = tostring( i ),
            onEvent = handleLevelSelect,
            emboss = false,
            shape="roundedRect",
            width = contentWidth*2.5/14,
            height = contentWidth*2.5/14,
            font = native.systemFontBold,
            fontSize = 18,
            labelColor = { default = { 1, 1, 1 }, over = { 0.5, 0.5, 0.5 } },
            cornerRadius = 8,
            labelYOffset = -6, 
            fillColor = { default={ 1, 0.4, 0.4}, over={1, 0.4, 0.4 } },
            strokeColor = { default={ 0.8, 0.2, 0.2 }, over={ 0.333, 0.667, 1, 1 } },
            strokeWidth = 2
        })
        -- Position the button in the grid and add it to the scrollView
        buttons[i].x = xOffset
        buttons[i].y = yOffset
        levelSelectGroup:insert( buttons[i] )

        -- Check to see if the player has achieved (completed) this level.
        -- The '.unlockedLevels' value tracks the maximum unlocked level.
        -- First, however, check to make sure that this value has been set.
        -- If not set (new user), this value should be 1.

        -- If the level is locked, disable the button and fade it out.
        
        if ( i <= getCurrentLevel(world) ) then
            buttons[i]:setEnabled( true )
            buttons[i].alpha = 1.0
        else 
            buttons[i]:setEnabled( false ) 
            buttons[i].alpha = 0.5 
        end 

        -- Generate stars earned for each level, but only if:
        -- a. The 'levels' table exists 
        -- b. There is a 'stars' value inside of the 'levels' table 
        -- c. The number of stars is greater than 0 (no need to draw zero stars). 

        local star = {} 
            for j = 1, getStars(world, i) do
                print("level "..i.." stars "..getStars(world,i))
                star[j] = display.newPolygon( 0, 0, starVertices )
                star[j]:setFillColor( 1, 0.9, 0 )
                star[j].strokeWidth = 1
                star[j]:setStrokeColor( 1, 0.8, 0 )
                star[j].x = buttons[i].x + (j * 16) - 32
                star[j].y = buttons[i].y + 13
                levelSelectGroup:insert( star[j] )
        end

        -- Compute the position of the next button.
        -- This tutorial draws 5 buttons across.
        -- It also spaces based on the button width and height + initial offset from the left.
        xOffset = xOffset + contentWidth/3.5
        cellCount = cellCount + 1
        if ( cellCount > 3 ) then
            cellCount = 1
            xOffset = contentWidth*3/14
            yOffset = yOffset + contentWidth/4
        end
    end

    -- Place the scrollView into the scene and center it.
    sceneGroup:insert( levelSelectGroup )
    levelSelectGroup.x = display.contentCenterX
    levelSelectGroup.y = display.contentCenterY

    buttonBackLevels = widget.newButton
        {
          label = "back",
          shape="roundedRect",
          width = contentWidth*0.9,
          height = textSize*0.9,
          font = native.systemFontBold,
          fontSize = textSize*0.7,
          labelColor = { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 }},
          fillColor = { default={ 1, 0.4, 0.4}, over={ 1, 0.4, 0.4, 0.7 }},
          onPress = goBack
        }

        buttonBackLevels.x = display.contentCenterX
        buttonBackLevels.y = contentHeight + originY/2
        sceneGroup:insert( buttonBackLevels )


    elseif ( event.phase == "did" ) then

       

         
    end
end

-- On scene hide...
function scene:hide( event )
    local sceneGroup = self.view

    if ( event.phase == "will" ) then
    end
end

-- On scene destroy...
function scene:destroy( event )
    local sceneGroup = self.view   
end


-- Composer scene listeners

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
return scene