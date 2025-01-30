##
## Assorted utilities provided by the engine mostly for its own
## benefit, but that may also be used by clients.
##
## **Author:** Leandro Motta Barros
##

import sdl2


template getTime*(): float =
  ## Gets the current wall time, in seconds since the engine
  ## initialization.
  sdl2.getTicks().float / 1000.0


template sleep*(time: float) =
  ## Sleeps for a given number of seconds.
  sdl2.delay(uint32(time * 1000.0))
