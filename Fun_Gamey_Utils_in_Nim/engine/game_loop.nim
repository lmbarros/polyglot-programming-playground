##
## Different implementations of the main game loop.
##
## The implementations shown here are based on the `blog post by Koen
## Witters <http://www.koonsolo.com/news/dewitters-gameloop/>`_ and on
## the `Game Loop chapter
## <http://gameprogrammingpatterns.com/game-loop.html>`_ on Robert
## Nystrom's book Game Programming Patterns. An additional source of
## information about game loops is Glenn Fiedler's `Fix your Timestep
## <http://gafferongames.com/game-physics/fix-your-timestep/>`_
## article.
##
## Some definitions concerning time:
##
## - *Wall time:* The time as it passes in a clock hanging on the
##   wall. This time flows continuously, and is our reference time.
##
## - *Tick time:* The time as it passes from the perspective of the
##   game logic. It tries to follow the wall time, but advances in
##   discrete steps (which means that it is usually a bit behind the
##   wall time.
##
## - *Draw time:* The time as it passes from the perspective of
##   rendering. It advances in discrete steps, trying to follow the
##   wall time (though, usually a bit behind it, like in the case of
##   tick time). Draw time means advances closely to the tick time,
##   but may be slightly ahead of it, for prediction/extrapolation
##   purposes. (Witter's post call it "interpolation", but it looks
##   more like extrapolation to me.)
##
## - *Ticks per second (TPS):* The number of times the tick time is
##   advanced in one second of wall time, which is also the number of
##   times the game state is updated per second.
##
## - *Frames per second (FPS):* The number of times the draw time is
##   advanced in one second of wall time, which is also the number of
##   times the screen is redrawn per second.
##
## **Author:** Leandro Motta Barros
##
## **TODO:** I have just one main loop type implemented for now. I
##           need to port others from Deever/FewDee.
##

import chapunim.engine.core
import chapunim.engine.util


type
  KeepRunningProcType* = proc(): bool ##
    ## A proc used to determine if the game loop shall keep
    ## running. It must return ``true`` to indicate that the game loop
    ## shall keep running, or ``false`` to indicate that it shall
    ## stop.

  RunningBehindProcType* = proc(tickInterval, clockTime: float) ##
    ## A proc used to handle the cases in which the system running the
    ## code is not fast enough to keep the requested update rate.
    ##
    ## This is typically used to humiliate the user, telling him that
    ## his computer is not fast enough to run your program (you
    ## probably want to say that more politely...) or to make
    ## something that will make your program less resource-hungry
    ## (perhaps disabling some eye candy).
    ##
    ## The first parameter passed, ``tickInterval``, is the time, in
    ## seconds, that it actually took to process the last tick or draw
    ## cycle. You can compare this with the expected time (e.g.,
    ## ``1.0/requestedFPS`` to find out by how much the program is
    ## falling behind the desired speed. (You may chose to act only if
    ## the difference is larger than a certain threshold.)
    ##
    ## The second parameter passed, ``clockTime``, is the clock time,
    ## in seconds, elapsed since the engine initialization. You can
    ## use this to check how much time has elapsed since the last time
    ## the handler was called. This lets you take action only every
    ## *n* seconds, instead of using even more cycles every time it is
    ## called (and it can be called *very* frequently, like once per
    ## frame).



proc runFixedTPSMaxFPS*(
  engine: var Engine,
  condition: KeepRunningProcType,
  desiredTPS: float,
  maxFrameSkip: int = 5,
  runningBehingHandler: RunningBehindProcType = nil) =
  ## Runs a game loop using a fixed time step (fixed at ``desiredTPS``
  ## ticks per second), and maximizing the frame rate (FPS). Up to
  ## ``maxFrameSkip`` tick events will be generated without a
  ## corresponding draw event. The loop keeps running as long as
  ## ``condition()`` remains ``true``. ``runningBehingHandler()`` gets
  ## called if the tick handlers are taking more the time necessary to
  ## keep with  ``desiredTPS``.

  let tickInterval = 1.0 / desiredTPS
  var nextTick = getTime()
  var prevDrawTime = nextTick
  var tickTime = nextTick

  while condition():
    var loops = 0

    var now = getTime()
    while now >= nextTick and loops < maxFrameSkip:
      tickTime = nextTick
      nextTick += tickInterval

      engine.tick(tickInterval, tickTime)

      let newNow = getTime()

      if loops > 0 and runningBehingHandler != nil:
        let actualTickInterval = newNow - now
        runningBehingHandler(actualTickInterval, now)
        now = getTime()
      else:
        now = newNow

      inc loops

    let drawTime = now
    let drawInterval = drawTime - prevDrawTime
    let drawAheadOfTick = drawTime - tickTime
    prevDrawTime = now

    engine.draw(drawInterval, now, tickTime, drawAheadOfTick)
