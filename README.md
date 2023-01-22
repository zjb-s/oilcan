# oilcan
greasy percussion engine
![Untitled_Artwork 17](https://user-images.githubusercontent.com/86270534/213924876-23b20e74-ae0d-41d5-b84b-3062ad64f710.png)


## what?
* Oilcan is a monophonic digital-style percussion voice. At its core, Oilcan is two sine waves capable of basic FM synthesis. These operators are wavefolded, then mixed into two stages of clipping.
* Oilcan is arranged in *timbres.* You can think of each timbre as its own drum. Each time Oilcan triggers, it picks a timbre based on the note you're sending.
* You can find all of Oilcan's params in the `OILCAN >` param group.
### editing timbres
* Change `SELECTED TIMBRE` to edit different timbres. The selected timbre's params will populate below.
* Below the timbre params is the `MACROS` section. These params non-destructively multiply timbre params as they're played, acting as performance controls.
* Below `MACROS`, you can find trigger params for temp-saving and temp-loading timbres or macro settings. This can be used as a performance control, or to copy timbres to new slots.
* Below temp controls is the save system. *Everything is saved with your psets - this is for sharing sounds with other norns.* 

## signal flow
![Untitled_Artwork 16](https://user-images.githubusercontent.com/86270534/213921482-eb357414-9e54-44e7-be2f-e7e3c8bfe434.png)
## params
| param name | description |
|-|-|
| `FREQ` | Base frequency
| `SWEEP TIME` | Percentage of release time spent sweeping towards base frequency
| `SWEEP INDEX` | Depth of pitch sweep
| `ATTACK` | Rise time. Affects all envelopes.
| `RELEASE` | Fall time to silence. All other envelopes use this time as a reference - changing this param affects all envelopes.
| `MODULATOR RELEASE` | Percentage of release time spent releasing the modulation operator to silence.
| `MODULATOR LEVEL` | Multiplier for the modulator envelope height.
| `MODULATOR RATIO` | Multiplier for the modulator's frequency relative to base frequency.
| `FEEDBACK` | Modulator FM feedback. 0 is a sine wave, 10 is tuned noise.
| `FOLD` | Amount of wavefolding applied to operators at start of signal chain
| `HEADROOM` | Amount of headroom before the signal hard-clips. Lowering `HEADROOM` applies a filthy compression effect.
| `GAIN` | Signal multiplier into a soft-clipping waveshaper.
| `ROUTING` | Linearly pan the modulator between 0 (carrier modulation only) and 1 (mix with carrier for output)
| `LEVEL` | Clean level control.
