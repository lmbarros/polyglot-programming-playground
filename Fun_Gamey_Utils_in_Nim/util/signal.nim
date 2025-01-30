##
## Yet another implementation of signals (as in "Signals and Slots").
##
## This is a port of some D I had implemented some time ago. Though I
## haven't tried different approaches in Niml, in D I tested other
## implementations which were nicer than this one in several aspects,
## but were much slower (orders of magnitude slower) than this
## approach I have here. Since Chapunim relies heavily on event
## handlers, I judged that the additional cumbersomeness is well worth
## in this case.
##
## This implementation doesn't do anything to be thread safe (which probably
## explains to a large extent why it is faster than other implementations).
##
## **TODO:** Do some benchmarks; consider porting my D "linear map" to
##           use instead of ``Table``.
##
## **Author:** Leandro Motta Barros
##

import tables


type SlotID* = int ##
  ## The type representing a slot ID.
  ##
  ## In this implementation, every slot connected to a signal has an
  ## ID that identifies it uniquely. This is type of these IDs.

const InvalidSlotID*: SlotID = 0 ##
  ## A slot ID that is guaranteed to be different to any real event handler ID.

type
  Signal*[SlotType: proc] = tuple ##
    ## A signal. ``SlotType`` must return ``void`` or be ``{.discardable.}``.
    nextSlotID: SlotID ## The next slot ID to use
    slots: Table[SlotID, SlotType] ## Maps slot IDs to the slots themselves


proc initSignal*[SlotType](): Signal[SlotType] =
  ## Constructs a new signal that accept slots of type ``SlotType``.
  result.slots = initTable[SlotID, SlotType]()
  result.nextSlotID = InvalidSlotID + 1


proc connect*[SlotType](signal: var Signal[SlotType], slot: SlotType): SlotID =
  ## Connects ``slot`` to ``signal``. Returns an ID that can be later
  ## passed to $(D disconnect()) in order to remove the slot just
  ## added.
  signal.slots[signal.nextSlotID] = slot
  result = signal.nextSlotID
  inc signal.nextSlotID


proc disconnect*[SlotType](signal: var Signal[SlotType], slotID: SlotID) =
  ## Disconnects the slot with id ``slotID`` from ``signal``.
  signal.slots.del(slotID)


proc slotCount*[SlotType](signal: Signal[SlotType]): int =
  ## Returns the number of slots connected to ``signal``.
  result = signal.slots.len


proc emit*[SlotType, T1](signal: Signal[SlotType], p1: T1) =
  ## Calls all slots added to ``signal``.
  for k, slot in pairs(signal.slots):
    slot(p1)


proc emit*[SlotType, T1, T2](signal: Signal[SlotType], p1: T1, p2: T2) =
  ## Calls all slots added to ``signal``.
  ##
  ## **TODO:** Replace all those overloads with something (macro?)
  ##           that works for any number of arguments.
  for k, slot in pairs(signal.slots):
    slot(p1, p2)


proc emit*[SlotType, T1, T2, T3](
  signal: Signal[SlotType], p1: T1, p2: T2, p3: T3) =
  ## Calls all slots added to ``signal``.
  for k, slot in pairs(signal.slots):
    slot(p1, p2, p3)


proc emit*[SlotType, T1, T2, T3, T4](
  signal: Signal[SlotType], p1: T1, p2: T2, p3: T3, p4: T4) =
  ## Calls all slots added to ``signal``.
  for k, slot in pairs(signal.slots):
    slot(p1, p2, p3, p4)


proc emit*[SlotType, T1, T2, T3, T4, T5](
  signal: Signal[SlotType], p1: T1, p2: T2, p3: T3, p4: T4, p5: T5) =
  ## Calls all slots added to ``signal``.
  for k, slot in pairs(signal.slots):
    slot(p1, p2, p3, p4, p5)



#
# Unit tests
#

import chapunim.util.test

# Simple test that also serves as an example.
unittest:
  type eventHandlerType = proc(x: int, s: string)

  var
    theInt = 0
    theString = ""

  proc handler1(x: int, s: string) =
    theInt = 100 + x
    theString = "1: " & s

  proc handler2(x: int, s: string) =
    theInt += 200 + x
    theString = "2: " & s

  proc handler3(x: int, s: string) =
    theInt += 1_000_000

  var signal = initSignal[eventHandlerType]()

  # Connect a slot and call it
  let id1 = signal.connect(handler1)
  signal.emit(5, "Hello")
  doAssert(theInt == 105)
  doAssert(theString == "1: Hello")

  # Remove the handler, add some more handlers, call them
  signal.disconnect(id1)
  let id2 = signal.connect(handler2)
  let id3 = signal.connect(handler3)

  theInt = 0
  signal.emit(3, "Goodbye")
  doAssert(theInt == 1_000_203)
  doAssert(theString == "2: Goodbye")

  # Remove all handlers, call them again; nothing shall happen
  signal.disconnect(id2)
  signal.disconnect(id3)
  signal.emit(8, "Good night")
  doAssert(theInt == 1_000_203)
  doAssert(theString == "2: Goodbye")


# Tests procs `connect`, `disconnect` and `slotCount`
unittest:
  proc aHandler(a: float, b: int) = discard

  var signal = initSignal[aHandler.type]()

  # Initially, no slots are connected
  doAssert(signal.slotCount == 0)

  # Connect some slots
  let id1 = signal.connect(aHandler)
  let id2 = signal.connect(aHandler)
  let id3 = signal.connect(aHandler)

  # Ensure the IDs are the expected
  doAssert(id1 != InvalidSlotID)
  doAssert(id2 == id1 + 1)
  doAssert(id3 == id1 + 2)

  # Now we should have some slots connected
  doAssert(signal.slotCount == 3)

  # Disconnect a slot, check the status again
  signal.disconnect(id2)
  doAssert(signal.slotCount == 2)

  # Try disconnecting some nonexistent slots
  signal.disconnect(InvalidSlotID)
  signal.disconnect(id3 + 111)
  doAssert(signal.slotCount == 2)

  # Now, remove the remaining two slots, re-check
  signal.disconnect(id1)
  signal.disconnect(id3)

  doAssert(signal.slotCount == 0)
