import common

{.this:self.}

type
  Master* = ref object of Machine
    beatsPerMinute*: float
    gain: float

method init*(self: Master) =
  procCall init(Machine(self))
  name = "master"
  nInputs = 1
  nOutputs = 0
  gain = 1.0
  stereo = true
  beatsPerMinute = 128.0
  globalParams.add([
    Parameter(kind: Float, name: "volume", min: 0.0, max: 10.0, default: 1.0, value: 1.0, onchange: proc(newValue: float, voice: int) =
      self.gain = newValue
    ),
    Parameter(kind: Int, name: "bpm", min: 1.0, max: 300.0, default: 128.0, value: 128.0, onchange: proc(newValue: float, voice: int) =
      self.beatsPerMinute = newValue
    ),
  ])

method process*(self: Master) =
  cachedOutputSample = 0.0
  for input in inputs:
    cachedOutputSample += input.machine.outputSample * input.gain
  cachedOutputSample *= gain

proc newMaster*(): Master =
  result = new(Master)
  result.init()
