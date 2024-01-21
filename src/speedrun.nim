# ****************************************************************************************
#
#   raylib [core] example - Basic window (adapted for HTML5 platform)
#
#   NOTE: This example is prepared to compile to WebAssembly, as shown in the
#   basic_window_web.nims file. Compile with the -d:emscripten flag.
#   To run the example on the Web, run nimhttpd from the public directory and visit
#   the address printed to stdout. As you will notice, code structure is slightly
#   diferent to the other examples...
#
#   Example originally created with raylib 1.3, last time updated with raylib 1.3
#
#   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
#   BSD-like license that allows static linking with closed source software
#
#   Copyright (c) 2015-2022 Ramon Santamaria (@raysan5)
#
# ****************************************************************************************

import raylib, raymath, math

# ----------------------------------------------------------------------------------------
# Global Variables Definition
# ----------------------------------------------------------------------------------------

const
  screenWidth = 960
  screenHeight = 960
  virtualScreenWidth = 120
  virtualScreenHeight = 120
  screenRatio = screenWidth/virtualScreenWidth
  playerSize = 3

var target: RenderTexture
var level_tex: Texture2D
var level: Image
var killer: Image
var bg: Texture2D
var dt = 0.0
var pos = Vector2(x:9.0,y:16.0)
var vel = Vector2()
var remainder = Vector2()
var coyote = 0
var wall = false
var jump_buffer = 0
var jumping = false
var camera = Camera2D(
    target: Vector2(),
    offset: Vector2(),
    rotation: 0,
    zoom: 1,
  )
var level_num = 0

# ----------------------------------------------------------------------------------------
# Module functions Definition
# ----------------------------------------------------------------------------------------

proc checkTop(): bool = 
  return level.getImageColor(pos.x.int32,pos.y.int32-1) != Color(a:0) or
  level.getImageColor(pos.x.int32+1,pos.y.int32-1) != Color(a:0) or
  level.getImageColor(pos.x.int32+2,pos.y.int32-1) != Color(a:0) or
  level.getImageColor(pos.x.int32+3,pos.y.int32-1) != Color(a:0)

proc checkForKillers(): bool =
  return killer.getImageColor(pos.x.int32,pos.y.int32) != Color(a:0) or
  killer.getImageColor(pos.x.int32+1,pos.y.int32) != Color(a:0) or
  killer.getImageColor(pos.x.int32+2,pos.y.int32) != Color(a:0) or
  killer.getImageColor(pos.x.int32+3,pos.y.int32) != Color(a:0) or 
  killer.getImageColor(pos.x.int32,pos.y.int32+1) != Color(a:0) or
  killer.getImageColor(pos.x.int32+3,pos.y.int32+1) != Color(a:0) or
  killer.getImageColor(pos.x.int32,pos.y.int32+2) != Color(a:0) or
  killer.getImageColor(pos.x.int32+3,pos.y.int32+2) != Color(a:0) or
  killer.getImageColor(pos.x.int32,pos.y.int32+playerSize) != Color(a:0) or
  killer.getImageColor(pos.x.int32+1,pos.y.int32+playerSize) != Color(a:0) or
  killer.getImageColor(pos.x.int32+2,pos.y.int32+playerSize) != Color(a:0) or
  killer.getImageColor(pos.x.int32+3,pos.y.int32+playerSize) != Color(a:0)

proc playerDie() = 
  pos = Vector2(x:9.0,y:16.0)
  vel = Vector2()
  remainder = Vector2()
  coyote = 0
  jump_buffer = 0
  camera.offset = Vector2()

proc updateDrawFrame {.cdecl.} =
  # Update
  # --------------------------------------------------------------------------------------
  # TODO: Update your variables here
  # --------------------------------------------------------------------------------------
  dt = 60.0*getFrameTime()
  #pos.x = pos.x.round()
  if not wall and vel.y < 3.0: vel.y += 0.1
  if isKeyDown(D):
    if vel.x < 1.0:
      vel.x += 0.1
  elif isKeyDown(A):
    if vel.x > -1.0:
      vel.x -= 0.1
  else: vel.x = 0.0
  if isKeypressed(W):
    jump_buffer = 10
  if isKeyReleased(W) and jumping and vel.y <= 0.0:
    jumping = false
    vel.y = 0.0
  if isKeyPressed(S):
    vel.y = 3.2
    jumping = false
  if jump_buffer > 0 and (coyote > 0 or wall):
    vel.y = -1.5
    jump_buffer = 0
    if wall:
      vel.x *= -10.0
    jumping = true
  if coyote > 0: coyote -= 1
  if jump_buffer > 0: jump_buffer -= 1
  if isKeyPressed(R):
    playerDie()

  wall = false
  remainder.x += vel.x
  var move: int = remainder.x.round().int
  if move != 0:
    remainder.x-=move.float
    let signum = move.sgn().int32
    while move != 0:
      if level.getImageColor(pos.x.int32+signum,pos.y.int32) != Color(a:0) or 
      level.getImageColor(pos.x.int32+signum,pos.y.int32+1) != Color(a:0) or 
      level.getImageColor(pos.x.int32+signum,pos.y.int32+2) != Color(a:0) or 
      level.getImageColor(pos.x.int32+signum,pos.y.int32+3) != Color(a:0) and checkTop() or
      level.getImageColor(pos.x.int32+playerSize+signum,pos.y.int32) != Color(a:0) or 
      level.getImageColor(pos.x.int32+playerSize+signum,pos.y.int32+1) != Color(a:0) or 
      level.getImageColor(pos.x.int32+playerSize+signum,pos.y.int32+2) != Color(a:0) or
      level.getImageColor(pos.x.int32+playerSize+signum,pos.y.int32+3) != Color(a:0) and checkTop():
        vel.x = 0.0
        remainder.x = 0.0
        wall = true
        break
      
      pos.x += signum.float
      if level.getImageColor(pos.x.int32+playerSize,pos.y.int32+3) != Color(a:0) and not checkTop() or level.getImageColor(pos.x.int32,pos.y.int32+3) != Color(a:0) and not checkTop():
        pos.y -= 1.0
      move -= signum

  if pos.x < 0:
    pos.x = 0

  remainder.y += vel.y
  move = remainder.y.round().int
  if move != 0:
    remainder.y-=move.float
    let signum = move.sgn().int32
    while move != 0:
      if level.getImageColor(pos.x.int32,pos.y.int32+signum) != Color(a:0) or 
      level.getImageColor(pos.x.int32+1,pos.y.int32+signum) != Color(a:0) or 
      level.getImageColor(pos.x.int32+2,pos.y.int32+signum) != Color(a:0) or 
      level.getImageColor(pos.x.int32+3,pos.y.int32+signum) != Color(a:0):
        vel.y = 0.0
        remainder.y = 0.0
        break
      if level.getImageColor(pos.x.int32,pos.y.int32+playerSize+signum) != Color(a:0) or 
      level.getImageColor(pos.x.int32+1,pos.y.int32+playerSize+signum) != Color(a:0) or 
      level.getImageColor(pos.x.int32+2,pos.y.int32+playerSize+signum) != Color(a:0) or
      level.getImageColor(pos.x.int32+3,pos.y.int32+playerSize+signum) != Color(a:0):
        vel.y = 0.0
        remainder.y = 0.0
        break
      pos.y += signum.float
      move -= signum
  echo pos  
  if level.getImageColor(pos.x.int32,pos.y.int32+playerSize+1) != Color(a:0) or 
    level.getImageColor(pos.x.int32+1,pos.y.int32+playerSize+1) != Color(a:0) or 
    level.getImageColor(pos.x.int32+2,pos.y.int32+playerSize+1) != Color(a:0) or
    level.getImageColor(pos.x.int32+3,pos.y.int32+playerSize+1) != Color(a:0):
      coyote = 6
  if pos.y > virtualScreenHeight or checkForKillers():
    playerDie()
  # Draw
  # --------------------------------------------------------------------------------------

  if pos.x+2 > virtualScreenWidth/2 and pos.x+2 < level.width.float-virtualScreenWidth/2:
    camera.offset.x = -pos.x+virtualScreenWidth/2-2
  if pos.x > level.width.float or isKeyPressed(One) or isKeyPressed(Two):
    level_num += 1
    playerDie()
    level = loadImage("levels/" & $level_num & "/solid.png")
    killer = loadImage("levels/" & $level_num & "/killer.png")
    var all = level
    all.imageDraw(killer,Rectangle(x:0.0,y:0.0,width:level.width.float,height:level.height.float),Rectangle(x:0.0,y:0.0,width:level.width.float,height:level.height.float),White)
    level_tex = all.loadTextureFromImage()

  beginDrawing()
  clearBackground(Black)
  drawTexture(bg,0,0,White)
  #drawTexture(bg,Rectangle(x: -pos.x*screenRatio,y:0.0,width:screenWidth,height: screenHeight),Rectangle(x:0.0,y:0.0,width:level.width.float,height: screenHeight.float),Vector2(),0.0,White)
  beginTextureMode(target)
  clearBackground(Color(a:0))
  beginMode2D(camera)
  drawTexture(level_tex,0,0,White)
  drawRectangle(pos,Vector2(x:4.0,y:4.0),Green)
  endMode2D()
  endTextureMode()
  drawTexture(target.texture,Rectangle(x:0.0,y:virtualScreenHeight,width:virtualScreenWidth,height: -virtualScreenHeight),Rectangle(x:0.0,y:0.0,width:screenWidth.float,height: screenHeight.float),Vector2(),0.0,White)
  endDrawing()
  # --------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------
# Program main entry point
# ----------------------------------------------------------------------------------------

proc main =
  # Initialization
  # --------------------------------------------------------------------------------------
  initWindow(screenWidth, screenHeight, "THINGAMAJIG")
  target = loadRenderTexture(virtualScreenWidth,virtualScreenHeight)
  level = loadImage("levels/" & $level_num & "/solid.png")
  killer = loadImage("levels/" & $level_num & "/killer.png")
  level_tex = loadTextureFromImage(level)
  bg = loadTexture("resources/mt.png")
  when defined(emscripten):
    emscriptenSetMainLoop(updateDrawFrame, 0, 1)
  else:
    setTargetFPS(60) # Set our game to run at 60 frames-per-second
    # ------------------------------------------------------------------------------------
    # Main game loop
    while not windowShouldClose(): # Detect window close button or ESC key
      updateDrawFrame()
  # De-Initialization
  # --------------------------------------------------------------------------------------
  closeWindow() # Close window and OpenGL context
  # --------------------------------------------------------------------------------------

main()