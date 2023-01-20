NUM_TIMBRES = 12

local mod = require 'core/mods'

-- todo look into taking over grid temporarily to edit timbres

param_specs = {
	{
		id = 'freq'
	,	name = 'FREQ'
	,	min = 5
	,	max = 10000
	,	default = 115
	,	units = 'hz'
	},
	{
		id = 'sweep_time'
	,	name = 'SWEEP TIME'
	,	min = 0.001
	,	max = 100
	,	default = 0.10
	,	units = '%'
	},
	{
		id = 'sweep_ix'
	,	name = 'SWEEP INDEX'
	,	min = -1
	,	max = 1
	,	default = 0.04
	,	k = 0
	},
	{
		id = 'atk'
	,	name = 'ATTACK'
	,	min = 0
	,	max = 1
	,	default = 0
	,	units = 'sec'
	},
	{
		id = 'car_rel'
	,	name = 'RELEASE'
	,	min = 0.01
	,	max = 3
	,	default = 0.5
	,	units = 'sec'
	},
	{
		id = 'mod_rel'
	,	name = 'MOD RELEASE'
	,	min = 0.1
	,	max = 200
	,	default = 100
	,	units = '%'
	},
	{
		id = 'mod_ix'
	,	name = 'MOD INDEX'
	,	min = 0
	,	max = 1
	,	default = 0
	},
	{
		id = 'mod_ratio'
	,	name = 'OP RATIO'
	,	min = 0.001
	,	max = 32
	,	default = 1
	},
	{
		id = 'fb'
	,	name = 'FEEDBACK'
	,	min = 0
	,	max = 10
	,	default = 0
	},
	{
		id = 'fold'
	,	name = 'FOLD'
	,	min = 0
	,	max = 100
	,	default = 0
	,	units = 'x'
	,	k = 6
	},
	{
		id = 'headroom'
	,	name = 'HEADROOM'
	,	min = 0.001
	,	max = 1
	,	default = 1
	},
	{
		id = 'gain'
	,	name = 'GAIN'
	,	min = 0
	,	max = 10
	,	default = 1
	,	units = 'x'
	},
	{
		id = 'level'
	,	name = 'LEVEL'
	,	min = 0
	,	max = 5
	,	default = 1
	,	units = 'x'
	}
}

local function oilcan_trig(timbre_num, velocity)
	timbre_num = timbre_num and timbre_num or params:get('selected_timbre')
	local msg = {1}
	for k,v in ipairs(param_specs) do
		table.insert(msg,params:get(v.id..'_timbre_'..timbre_num))
		msg[k] = msg[k] * params:get(v..'_mult')
		if v=='gain' then msg[k] = msg[k] * velocity end
	end
	-- engine.trig(table.unpack(msg))
	osc.send({'localhost',57120}, 'oilcan/trig', msg)
end

local function add_oilcan_params()

	params:add_group('Oilcan',#param_specs+2) -- todo add number here
	params:add_binary('oilcan_trig','trigger')
	params:set_action('oilcan_trig',oilcan_trig)
	params:add_number('selected_timbre','timbre to play',1,NUM_TIMBRES,1)

	params:add_separator('Multipliers')
	for _,v in ipairs(param_specs) do
		params:add{
			id = v.id..'_mult'
		,	name = '*'..v.name
		,	type = 'taper'
		,	min = 0
		,	max = 2
		,	k = 4
		,	units = 'x'
		}
	end

	for i=1,NUM_TIMBRES do
		params:add_group('timbre '..i,#param_specs)
		for _,v in ipairs(param_specs) do
			params:add{
				id = v.id..'_timbre_'..i
			,	name = v.name
			,	type = 'taper'
			,	min = v.min
			,	max = v.max
			,	default = v.default
			,	k = v.k and v.k or 4
			,	units = v.units and v.units or ''
			}
			params:hide(v.id..'_timbre_'..i)
		end
	end
end

function add_oilcan_player()
	local player = {timbre_modulation = 0}

	function player:active()
        if self.name ~= nil then
            params:show('Oilcan')
			for i=1,NUM_TIMBRES do params:show('timbre '..i) end
            _menu.rebuild_params()
        end
    end

	function player:inactive()
        if self.name ~= nil then
            params:hide('Oilcan')
			for i=1,NUM_TIMBRES do params:hide('timbre '..i) end
            _menu.rebuild_params()
        end
    end

	function player:modulate(v)
		self.timbre_modulation = v
	end

	function player:describe()
		return {
			name = 'Oilcan',
			supports_bend = false,
			supports_slew = false,
			modulate_description = 'fm index',
		}
	end

	function player:play_note(note, vel)
		oilcan_trig(params:get('selected_timbre'),vel)
	end

	function player:add_params()
        add_oilcan_params(i)
    end
end

mod.hook.register('script_pre_init', 'oilcan pre init', function()
	add_oilcan_player()
end)