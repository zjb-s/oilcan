Oilcan {
	classvar <voxs;
	*initClass {
		voxs = 4.collect {nil};

		StartUp.add {
			"pouring oilcan".postln;
		  	SynthDef(\Oilcan,{
				| freq = 91,
				atk = 0,
				fb = 5,
				sweep_time = 1,
				sweep_ix = 0.05,
				mod_ratio = 1.1,
				mod_rel = 70,
				mod_ix = 0.01,
				car_rel = 0.3,
				fold = 0,
				headroom = 0.7,
				gain = 1,
				routing = 0,
				level = 1,
				gate = 1|

				var car_env = EnvGen.ar(Env.perc(atk,car_rel), doneAction: Done.freeSelf, gate: gate);
				var mod_env = EnvGen.ar(Env.perc(atk,(car_rel*(mod_rel/100))), gate: gate);
				var sweep_env = EnvGen.ar(Env.perc(atk,(car_rel*(sweep_time/100))), gate: gate) * sweep_ix;

				var pitch = Clip.ar(freq + (sweep_env*5000),0,10000);

				var mod = Fold.ar(SinOscFB.ar(pitch * mod_ratio, fb) * (fold+1), -1, 1) * mod_env * mod_ix;
				var car = Fold.ar(SinOsc.ar(pitch + (mod*10000*(1-routing))) * (fold+1), -1, 1) * car_env;

				var sig = car + (mod*routing);

				sig = Clip.ar(sig, 0-headroom,headroom);
				sig = (sig * gain).tanh;

				Out.ar(0,Pan2.ar(sig * level));
			}).add;

			OSCFunc.new({ |msg, time, addr, recvPort|
				var syn;
				var idx = msg[1];
				var args = [[
				\freq, \sweep_time, \sweep_ix, \atk, \car_rel, \mod_rel,
				\mod_ix, \mod_ratio, \fb, \fold, \headroom, \gain, \routing, \level],
				msg[2..]].lace;
				if (voxs[idx] != nil) {
					voxs[idx].free;
				};
				syn = Synth.new(\Oilcan, args);
				syn.onFree {
					if (voxs[idx] != nil && voxs[idx] === syn) {
						voxs.put(idx, nil);
					};
				};
				voxs.put(msg[1], syn);
				// "perc!!".postln;
				// args.postln;
			}, "/oilcan/trig");

		};
	}
}
