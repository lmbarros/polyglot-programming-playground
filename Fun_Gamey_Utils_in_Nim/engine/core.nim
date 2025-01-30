##
## The engine core itself, whatever this means.
##
## **Author:** Leandro Motta Barros
##

import sdl2
import logging
import chapunim.error
import chapunim.util.signal


type
  TickHandlerType* = proc(tickInterval, currTickTime: float) ## A
    ## handler for "tick" events, where the game state is typically
    ## updated. Receives as parameter:
    ##
    ## - ``tickInterval``: the time interval passed since the
    ##   last tick event, in seconds.
    ##
    ## - ``currentTickTime``: the current tick time measured since the
    ##   engine initialization, in seconds.

  DrawHandlerType* = proc(drawInterval, currDrawTime,
                          currTickTime, drawAheadOfTick: float) ##
    ## A handler for draw events. All the parameters received
    ## represent times in seconds; here's their meanings:
    ##
    ## - ``drawInterval``: Time since the last call to draw events.
    ##
    ## - ``currDrawTime``: The current draw time, since the engine
    ##   initialization.
    ##
    ## - ``currTickTime``: The current tick time, since the same unspecified
    ##   epoch of the draw time.
    ##
    ## - ``drawAheadOfTick``: The amount of time draw time is ahead of
    ##   tick time.

  ClickHandlerType* = proc(x: float, y: float) # TODO: dummy! remove! soon!

  EngineOptions* = tuple ##
    ## Set of options used to initialize an ``Engine``.
    windowTitle: string ## The screen/window caption.
    fullScreen: bool ## Run in full screen?
    windowResizable: bool ## If a window, make it resizable?
    useDesktopResolution: bool ## If full screen, use desktop resolution?
    screenWidth: cint ## Screen or window width, in pixels.
    screenHeight: cint ## Screen or window height, in pixels.
    screenX: cint ## Screen position along the horizontal axis.
    screenY: cint ## Screen position along the vertical axis.

  Engine* = tuple ##
    ## All the data making up The Engine.

    window: WindowPtr ## The one and only window (or "full screen").

    # ----- Low-level event handlers -----
    onClick: Signal[ClickHandlerType]



proc initEngineOptions*(): EngineOptions =
  ## Creates an ``EngineOptions`` with sensible default parameters.
  result.fullScreen = false
  result.windowResizable = false
  result.useDesktopResolution = true
  result.screenWidth = 1024
  result.screenHeight = 768
  result.screenX = SDL_WINDOWPOS_CENTERED
  result.screenY = SDL_WINDOWPOS_CENTERED


proc initEngine*(options: EngineOptions): Engine =
  ## Creates an ``Engine`` according to the passed ``options``, and
  ## start it.

  # Initialize SDL
  logging.info("Initializing SDL")
  let rc = sdl2.init(INIT_VIDEO or INIT_AUDIO)
  raiseOnSDLError(rc, "Error initializing SDL")
  logging.info("Successfully initialized SDL")

  # Create window
  var flags = SDL_WINDOW_OPENGL
  if options.fullScreen:
    flags = flags or SDL_WINDOW_FULLSCREEN
    if options.useDesktopResolution:
      flags = flags or SDL_WINDOW_FULLSCREEN_DESKTOP

  logging.info("Creating window")
  result.window = sdl2.createWindow(
    title = options.windowTitle,
    x = options.screenX,
    y = options.screenY,
    w = options.screenWidth,
    h = options.screenHeight,
    flags = flags)

  if result.window == nil:
    raiseOnSDLError(SdlError, "Error creating window")
  logging.info("Window created successfully")


proc stop*(engine: var Engine) =
  ## Finalizes the engine.
  logging.info("Shutting down SDL")
  sdl2.quit()


proc tick*(engine: var Engine, tickInterval, tickTime: float) =
  ## This must be called from the main game loop in order to keep the
  ## game logic running. Parameters passed are ``tickInterval`` (the
  ## time, in seconds, by which the "tick time" is being advanced --
  ## AKA the "delta time" since the last call to ``tick()``) and
  ## ``tickTime`` (the current tick time, in seconds, since some
  ## unspecified epoch).
  ##
  ## The implemention does things in this order:
  ##
  ## 1. Low-level event handlers are called.
  ##
  ## 2. High-level event handlers (possibly triggered by the low-level
  ##    ones) are called.
  ##
  ## 3. Tick handlers are called.
  ##
  ## **TODO:** Implement this!
  discard


proc draw*(engine: var Engine, drawInterval, currDrawTime, currTickTime,
           drawAheadOfTick: float) =
  ## This must be called from the main game loop in order to have the
  ## draw handlers called -- and thus have things rendered into the
  ## screen. Parameters passed are:
  ##
  ## - ``drawInterval``: The time, in seconds, since the last call to
  ##   ``draw()``.
  ##
  ## - ``currDrawTime``: The current draw time, in seconds, since the
  ##   engine initialization.
  ##
  ## - ``currTickTime``: The current tick time, in seconds, since the
  ##   engine initialization.
  ##
  ## - ``drawAheadOfTick``: The amount of time, in seconds, by which
  ##   the draw time is ahead of the tick time.
  ##
  ## **TODO:** Implement this!
  discard
