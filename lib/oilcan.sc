Oilcan {
	*initClass {

		StartUp.add {
			"pouring oilcan".postln;
			SynthDef(\Oilcan,{
				| freq, atk, fb, sweep_time, sweep_ix, mod_ratio, mod_rel, mod_ix, car_rel, fold, headroom, gain, level |

				var car_env = EnvGen.ar(Env.perc(atk,car_rel), doneAction: Done.freeSelf);
				var mod_env = EnvGen.ar(Env.perc(atk,(car_rel*(mod_rel/100))));
				var sweep_env = EnvGen.ar(Env.perc(atk,(car_rel*(sweep_time/100)))) * sweep_ix;

				//var sample_clock = Impulse.ar(sr);
				var pitch = Clip.ar(freq + (sweep_env*5000),0,10000);

				var mod = Fold.ar(SinOscFB.ar(pitch * mod_ratio, fb) * mod_env * mod_ix * (fold+1), -1, 1);
				var car = Fold.ar(SinOsc.ar(pitch + (mod*10000)) * (fold+1), -1, 1);

				var sig = car * car_env;
				//sig = Latch.ar(sig,sample_clock);
				sig = Clip.ar(sig, 0-headroom,headroom);
				sig = (sig * gain).tanh;

				Out.ar(0,Pan2.ar(sig * level));
			}).add;

			OSCFunc.new({ |msg, time, addr, recvPort|
				var args = [[
				\freq, \sweep_time, \sweep_ix, \atk, \car_rel, \mod_rel,
				\mod_ix, \mod_ratio, \fb, \fold, \headroom, \gain, \level],
				msg[2..]].lace;
				var syn = Synth.new(\Oilcan, args);
			}, "/oilcan/trig");

/*		this.addCommand("trig", "ffffffffffffff", { |msg|
			var args = [[
				\freq, \sweep_time, \sweep_ix, \atk, \car_rel, \mod_rel,
				\mod_ix, \mod_ratio, \fb, \fold, \headroom, \gain, \level],
			msg[2..]].lace;
			var syn = Synth.new(\Oilcan, args);
		});*/

	}

}
