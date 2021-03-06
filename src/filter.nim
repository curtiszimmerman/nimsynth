import math
import util

import common

{.this:self.}

# publically cutoff is always given in hz

type
  FilterKind* = enum
    Lowpass
    Highpass
    Bandpass
    Notch
    Peak
    LowShelf
    HighShelf

  BaseFilter* = object of RootObj
    kind*: FilterKind
    cutoff*: float
    resonance*: float

  BiquadFilter* = object of BaseFilter
    a0,a1,a2,b1,b2: float
    peakGain*: float
    z1,z2: float

  #MoogFilter* = object of BaseFilter
  #  state: array[4, float]
  #  saturation, saturationInv: float
  #  oversampleFactor: int
  #  stepSize: float

  MoogFilter* = object of BaseFilter
    p0,p1,p2,p3,p32,p33,p34: float

  OnePoleFilter* = object of BaseFilter
    a0: float
    b1: float
    z1: float

method init*(self: var BaseFilter) {.base.} =
  cutoff = 1.0
  resonance = 1.0

method process*(self: var BaseFilter, sample: float32): float32 {.base.} =
  return sample

method setCutoff*(self: var BaseFilter, cutoff: float) {.base.} =
  self.cutoff = cutoff

method setResonance*(self: var BaseFilter, q: float) {.base.} =
  self.resonance = q

method calc*(self: var BaseFilter) {.base.} =
  discard

method reset*(self: var BaseFilter) {.base.} =
  discard

##############
# BiquadFilter

method setCutoff*(self: var BiquadFilter, cutoff: float) =
  self.cutoff = clamp(cutoff, 0.0001, 0.4999)

method calc*(self: var BiquadFilter) =
  cutoff = clamp(cutoff, 0.0001, 0.499)
  var norm: float
  let V = pow(10.0, abs(peakGain) / 20.0)
  let K = tan(PI * cutoff)
  case kind:
  of Lowpass:
    norm = 1.0 / (1.0 + K / resonance + K * K)
    a0 = K * K * norm
    a1 = 2.0 * a0
    a2 = a0
    b1 = 2.0 * (K * K - 1.0) * norm
    b2 = (1.0 - K / resonance + K * K) * norm
  of Highpass:
    norm = 1.0 / (1.0 + K / resonance + K * K)
    a0 = 1.0 * norm
    a1 = -2.0 * a0
    a2 = a0
    b1 = 2.0 * (K * K - 1.0) * norm
    b2 = (1.0 - K / resonance + K * K) * norm;
  of Bandpass:
    norm = 1.0 / (1.0 + K / resonance + K * K)
    a0 = K / resonance * norm
    a1 = 0.0
    a2 = -a0
    b1 = 2.0 * (K * K - 1.0) * norm
    b2 = (1.0 - K / resonance + K * K) * norm
  of Notch:
    norm = 1.0 / (1.0 + K / resonance + K * K)
    a0 = (1.0 + K * K) * norm
    a1 = 2.0 * (K * K - 1.0) * norm
    a2 = a0
    b1 = a1
    b2 = (1.0 - K / resonance + K * K) * norm
  of Peak:
    if peakGain >= 0.0:
      norm = 1 / (1 + 1/resonance * K + K * K)
      a0 = (1 + V/resonance * K + K * K) * norm
      a1 = 2 * (K * K - 1) * norm
      a2 = (1 - V/resonance * K + K * K) * norm
      b1 = a1
      b2 = (1 - 1/resonance * K + K * K) * norm
    else:
      norm = 1 / (1 + V/resonance * K + K * K)
      a0 = (1 + 1/resonance * K + K * K) * norm
      a1 = 2 * (K * K - 1) * norm
      a2 = (1 - 1/resonance * K + K * K) * norm
      b1 = a1
      b2 = (1 - V/resonance * K + K * K) * norm
  of LowShelf:
      if peakGain >= 0.0:
        norm = 1 / (1 + sqrt(2.0) * K + K * K)
        a0 = (1 + sqrt(2.0*V) * K + V * K * K) * norm
        a1 = 2 * (V * K * K - 1) * norm
        a2 = (1 - sqrt(2.0*V) * K + V * K * K) * norm
        b1 = 2 * (K * K - 1) * norm
        b2 = (1 - sqrt(2.0) * K + K * K) * norm
      else:
        norm = 1 / (1 + sqrt(2.0*V) * K + V * K * K)
        a0 = (1 + sqrt(2.0) * K + K * K) * norm
        a1 = 2 * (K * K - 1) * norm
        a2 = (1 - sqrt(2.0) * K + K * K) * norm
        b1 = 2 * (V * K * K - 1) * norm
        b2 = (1 - sqrt(2.0*V) * K + V * K * K) * norm
  of HighShelf:
      if peakGain >= 0:
        norm = 1 / (1 + sqrt(2.0) * K + K * K)
        a0 = (V + sqrt(2.0*V) * K + K * K) * norm
        a1 = 2 * (K * K - V) * norm
        a2 = (V - sqrt(2.0*V) * K + K * K) * norm
        b1 = 2 * (K * K - 1) * norm
        b2 = (1 - sqrt(2.0) * K + K * K) * norm
      else:
        norm = 1 / (V + sqrt(2.0*V) * K + K * K)
        a0 = (1 + sqrt(2.0) * K + K * K) * norm
        a1 = 2 * (K * K - 1) * norm
        a2 = (1 - sqrt(2.0) * K + K * K) * norm
        b1 = 2 * (K * K - V) * norm
        b2 = (V - sqrt(2.0*V) * K + K * K) * norm

method normalize*(self: var BiquadFilter) =
  if a0 != 0.0:
    a1 /= a0
    a2 /= a0
    b1 /= a0
    b2 /= a0
    z1 /= a0
    z2 /= a0
    a0 = 1.0

method reset*(self: var BiquadFilter) =
  a0 = 0.0
  a1 = 0.0
  a2 = 0.0
  b1 = 0.0
  b2 = 0.0
  z1 = 0.0
  z2 = 0.0
  calc()

method process*(self: var BiquadFilter, sample: float32): float32 =
  result = sample * a0 + z1
  z1 = sample * a1 + z2 - b1 * result
  z2 = sample * a2 - b2 * result

############
# MoogFilter

proc fastTanh(x: float): float =
  let x2 = x * x
  return x * (27.0 + x2) / (27.0 + 9.0 * x2)

method setCutoff*(self: var MoogFilter, cutoff: float) =
  self.cutoff = 2.0 * PI * cutoff
  #self.cutoff = min(cutoff * 2.0 * PI / sampleRate, 1.0)


method init*(self: var MoogFilter) =
  #zeroMem(addr(state), sizeof(state))
  #saturation = 3.0
  #saturationInv = 1.0/saturation
  #oversampleFactor = 1
  #stepSize = 1.0 / (oversampleFactor.float * sampleRate)
  discard

#proc clip(value, saturation, saturationInv: float): float =
#  let v2 = if value * saturationInv > 1.0: 1.0
#    elif value * saturationInv < -1.0: -1.0
#    else: value * saturationInv
#  return (saturation * (v2 - (1.0/3.0) * v2 * v2 * v2))
#
#proc calculateDerivatives(self: var MoogFilter, input: float, dstate: var array[4, float], inState: array[4, float]) =
#  let satState0 = clip(inState[0], saturation, saturationInv)
#  let satState1 = clip(inState[1], saturation, saturationInv)
#  let satState2 = clip(inState[2], saturation, saturationInv)
#
#  dstate[0] = cutoff * (clip(input - resonance * inState[3], saturation, saturationInv) - satState0)
#  dstate[1] = cutoff * (satState0 - satState1)
#  dstate[2] = cutoff * (satState1 - satState2)
#  dstate[3] = cutoff * (satState2 - clip(inState[3], saturation, saturationInv))
#
#proc rungekutteSolver(self: var MoogFilter, input: float, state: var array[4,float]) =
#  var deriv1: array[4, float]
#  var deriv2: array[4, float]
#  var deriv3: array[4, float]
#  var deriv4: array[4, float]
#  var tmpState: array[4, float]
#
#  self.calculateDerivatives(input, deriv1, state)
#
#  for i in 0..3:
#    tmpState[i] = state[i] + 0.5 * stepSize * deriv1[i]
#
#  self.calculateDerivatives(input, deriv2, tmpState)
#
#  for i in 0..3:
#    tmpState[i] = state[i] + 0.5 * stepSize * deriv2[i]
#
#  self.calculateDerivatives(input, deriv3, tmpState)
#
#  for i in 0..3:
#    tmpState[i] = state[i] + 0.5 * stepSize * deriv3[i]
#
#  self.calculateDerivatives(input, deriv4, tmpState)
#
#  for i in 0..3:
#    state[i] += (1.0 / 6.0) * stepSize * (deriv1[i] + 2.0 * deriv2[i] + 2.0 * deriv3[i] + deriv4[i])

#method process*(self: var MoogFilter, sample: float32): float32 =
#  for i in 0..oversampleFactor:
#    self.rungekutteSolver(sample, state)
#  return state[3]

method process*(self: var MoogFilter, sample: float32): float32 =
  let k = resonance * 4.0
  result = p3 * 0.360891 + p32 * 0.417290 + p33 * 0.177896 + p34 * 0.0439725
  p34 = p33
  p33 = p32
  p32 = p3

  p0 += (fastTanh(sample - k * result) - fastTanh(p0)) * cutoff
  p1 += (fastTanh(p0) - fastTanh(p1)) * cutoff
  p2 += (fastTanh(p1) - fastTanh(p2)) * cutoff
  p3 += (fastTanh(p2) - fastTanh(p3)) * cutoff

#################
# One Pole Filter

method init*(self: var OnePoleFilter) =
  a0 = 1.0
  b1 = 0.0
  z1 = 0.0
  cutoff = 1.0

method calc*(self: var OnePoleFilter) =
  if kind == Lowpass:
    b1 = exp(-2.0 * PI * cutoff)
    a0 = 1.0 - b1
  elif kind == Highpass:
    b1 = -exp(-2.0 * PI * (0.5 - cutoff))
    a0 = 1.0 + b1


method setCutoff*(self: var OnePoleFilter, cutoff: float) =
  self.cutoff = cutoff
  calc()

method process*(self: var OnePoleFilter, sample: float32): float32 {.inline.} =
  z1 = sample * a0 + z1 * b1
  return z1

import osc

type
  FilterMachine = ref object of Machine
    filterL: BiquadFilter
    filterR: BiquadFilter
    lfoL: Osc
    lfoR: Osc
    lfoAmount: float
    lfoPhaseOffset: float

method init(self: FilterMachine) =
  procCall init(Machine(self))
  name = "filter"
  nInputs = 1
  nOutputs = 1
  stereo = true
  filterL.init()
  filterR.init()
  lfoL.kind = Sin
  lfoR.kind = Sin

  self.globalParams.add([
    Parameter(name: "filter", kind: Int, min: FilterKind.low.float, max: FilterKind.high.float, default: Lowpass.float, onchange: proc(newValue: float, voice: int) =
      self.filterL.kind = newValue.FilterKind
      self.filterR.kind = newValue.FilterKind
    , getValueString: proc(value: float, voice: int): string =
      return $value.FilterKind
    ),
    Parameter(name: "cutoff", kind: Float, min: 0.0, max: 1.0, default: 0.5, onchange: proc(newValue: float, voice: int) =
      self.filterL.cutoff = exp(lerp(-8.0, -0.8, newValue))
      self.filterR.cutoff = exp(lerp(-8.0, -0.8, newValue))
    , getValueString: proc(value: float, voice: int): string =
      return $(exp(lerp(-8.0, -0.8, value)) * sampleRate).int & " hZ"
    ),
    Parameter(name: "resonance", kind: Float, min: 0.0, max: 10.0, default: 1.0, onchange: proc(newValue: float, voice: int) =
      self.filterL.resonance = newValue
      self.filterR.resonance = newValue
    ),
    Parameter(name: "lfo freq", kind: Float, min: 0.0001, max: 60.0, default: 0.1, onchange: proc(newValue: float, voice: int) =
      self.lfoL.freq = newValue
      self.lfoR.freq = newValue
      self.lfoR.phase = self.lfoL.phase + self.lfoPhaseOffset
    ),
    Parameter(name: "lfo amp", kind: Float, min: 0.0, max: 1.0, default: 0.01, onchange: proc(newValue: float, voice: int) =
      self.lfoAmount = newValue
    ),
    Parameter(name: "lfo phase", kind: Float, min: -PI, max: PI, default: PI / 2.0, onchange: proc(newValue: float, voice: int) =
      self.lfoPhaseOffset = newValue
      self.lfoR.phase = self.lfoL.phase + self.lfoPhaseOffset
    ),
  ])

  setDefaults()


method process(self: FilterMachine) {.inline.} =
  outputSamples[0] = 0.0
  for input in mitems(self.inputs):
    outputSamples[0] += input.getSample()

  if outputSampleId mod 2 == 0:
    let oc = self.filterR.cutoff
    self.filterL.cutoff += (1.0 + lfoL.process()) * lfoAmount
    self.filterL.calc()
    outputSamples[0] = self.filterL.process(outputSamples[0])
    self.filterL.cutoff = oc
  else:
    let oc = self.filterR.cutoff
    self.filterR.cutoff += (1.0 + lfoR.process()) * lfoAmount
    self.filterR.calc()
    outputSamples[0] = self.filterR.process(outputSamples[0])
    self.filterR.cutoff = oc

proc newFilterMachine(): Machine =
  result = new(FilterMachine)
  result.init()

registerMachine("filter", newFilterMachine, "fx")

import complex

proc toComplex(x: float): TComplex = result.re = x

proc fft[T](x: openarray[T]): seq[TComplex] =
  let n = x.len
  result = newSeq[TComplex]()
  if n <= 1:
    for v in x: result.add toComplex(v)
    return
  var evens,odds = newSeq[T]()
  for i,v in x:
    if i mod 2 == 0: evens.add(v)
    else: odds.add(v)
  var (even, odd) = (fft(evens), fft(odds))

  for k in 0..<n div 2:
    result.add(even[k] + exp((0.0, -2.0*PI*float(k)/float(n))) * odd[k])

  for k in 0..<n div 2:
    result.add(even[k] - exp((0.0, -2.0*PI*float(k)/float(n))) * odd[k])

proc generateImpulse*(points: int): seq[float32] =
  result = newSeq[float32](points)
  for i in 0..<points:
    result[i] = if i == 0: 1.0 else: 0.0

proc graphResponse*(timeDomain: openarray[float32], points: int): seq[float] =
  var res = fft(timeDomain)
  result = newSeq[float](points)
  for i in 0..<points:
    result[i] = res[i].re
