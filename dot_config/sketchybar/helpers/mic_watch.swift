// Watch the default input device and trigger sketchybar's mic_change event
// with MUTED=true|false whenever its mute flag or input volume changes
// (Push Mic Control mutes through CoreAudio). Built by sketchybarrc.
import CoreAudio
import Foundation

let sketchybar = "/opt/homebrew/bin/sketchybar"
let queue = DispatchQueue.main

func address(_ selector: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal)
  -> AudioObjectPropertyAddress
{
  AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
}

func read<T: BitwiseCopyable>(_ object: AudioObjectID, _ addr: AudioObjectPropertyAddress, _ initial: T) -> T? {
  var addr = addr
  var value = initial
  var size = UInt32(MemoryLayout<T>.size)
  return AudioObjectGetPropertyData(object, &addr, 0, nil, &size, &value) == noErr ? value : nil
}

let defaultInput = address(kAudioHardwarePropertyDefaultInputDevice)
let muteAddr = address(kAudioDevicePropertyMute, kAudioDevicePropertyScopeInput)
let volumeAddr = address(kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyScopeInput)

var device = AudioObjectID(kAudioObjectUnknown)
var lastState: Bool?

let changed: AudioObjectPropertyListenerBlock = { _, _ in update() }

func update() {
  let muted = read(device, muteAddr, UInt32(0)) == 1 || read(device, volumeAddr, Float32(1)) == 0
  guard muted != lastState else { return }
  lastState = muted
  let process = Process()
  process.executableURL = URL(fileURLWithPath: sketchybar)
  process.arguments = ["--trigger", "mic_change", "MUTED=\(muted)"]
  try? process.run()
}

func watchDefaultDevice() {
  for addr in [muteAddr, volumeAddr] {
    var addr = addr
    AudioObjectRemovePropertyListenerBlock(device, &addr, queue, changed)
  }
  device = read(AudioObjectID(kAudioObjectSystemObject), defaultInput, AudioObjectID(kAudioObjectUnknown))
    ?? AudioObjectID(kAudioObjectUnknown)
  for addr in [muteAddr, volumeAddr] {
    var addr = addr
    AudioObjectAddPropertyListenerBlock(device, &addr, queue, changed)
  }
  lastState = nil
  update()
}

var defaultInputAddr = defaultInput
AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defaultInputAddr, queue) { _, _ in
  watchDefaultDevice()
}
watchDefaultDevice()
dispatchMain()
