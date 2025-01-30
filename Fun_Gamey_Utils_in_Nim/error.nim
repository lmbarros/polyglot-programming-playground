##
## Error handling, reporting and whatever else is error-related
##
## **Author:** Leandro Motta Barros
##

import sdl2
import logging


type
  ChapunimError* = object of Exception ## Base of all Chapunim exceptions.


proc raiseOnSDLError*(rc: SDL_Return; msg: string) =
  ## Raises a ``ChapunimError`` exception if ``rc`` is not an SDL
  ## success return code. The error message uses both the ``msg``
  ## string passed as parameter and the error string obtained through
  ## SDL itself. The error is logged, too.
  if rc != SdlSuccess:
    let errMsg = msg & $sdl2.getError()
    logging.error(errMsg)
    raise newException(ChapunimError, errMsg)
