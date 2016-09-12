import pico
import sdl2

import common
import machineview
import layoutview

import master

proc audioCallback(userdata: pointer, stream: ptr uint8, len: cint) {.cdecl.} =
  var samples = cast[ptr array[int.high,float32]](stream)
  var nSamples = len div sizeof(float32)
  for i in 0..<nSamples:
    # for all machines attached to master
    samples[i] = masterMachine.process()
    if i < 1024:
      sampleBuffer[i] = samples[i]

proc keyFunc(key: KeyboardEventPtr, down: bool): bool =
  # handle global keys
  let scancode = key.keysym.scancode
  if down:
    case scancode:
    of SDL_SCANCODE_F1:
      currentView = vLayoutView
      return true
    of SDL_SCANCODE_F2:
      currentView = vMachineView
      return true
    of SDL_SCANCODE_SLASH:
      baseOctave -= 1
      return true
    of SDL_SCANCODE_APOSTROPHE:
      baseOctave += 1
      return true
    else:
      discard
  if currentView.key(key, down):
    return true
  return false


proc init() =
  loadSpriteSheet("spritesheet.png")
  setAudioCallback(audioCallback)
  setKeyFunc(keyFunc)


  machines = newSeq[Machine]()
  masterMachine = newMaster()
  machines.add(masterMachine)

  vLayoutView = newLayoutView()
  vMachineView = newMachineView(masterMachine)
  currentView = vLayoutView

proc update(dt: float) =
  if currentView != nil:
    currentView.update(dt)

proc draw() =
  if currentView != nil:
    currentView.draw()

pico.init(false)
pico.run(init, update, draw)