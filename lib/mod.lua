NUM_TIMBRES = 12

local mod = require 'core/mods'

if note_players == nil then
	note_players = {}
end

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

-- local preset_sounds = {
-- 	[1] = {
-- 		freq = 
-- 	,	sweep_time = 
-- 	,	sweep_ix = 
-- 	,	atk = 
-- 	,	car_rel = 
-- 	,	mod_rel = 
-- 	,	mod_ix = 
-- 	,	mod_ratio = 
-- 	,	fb = 
-- 	,	fold = 
-- 	,	headroom = 
-- 	,	gain = 
-- 	,	level =
-- 	}
-- }

local function oilcan_trig(timbre_num, velocity)
	timbre_num = timbre_num and timbre_num or params:get('selected_timbre')
	local msg = {}
	for k,v in ipairs(param_specs) do
		msg[k] = params:get(v.id..'_timbre_'..timbre_num)
		msg[k] = msg[k] * params:get(v.id..'_mult')
		if v.id=='gain' then 
			msg[k] = msg[k] * velocity 
		-- elseif v.id=='
		end
		msg[k] = util.clamp(msg[k],v.min,v.max)
		-- print(v.id, v.min, v.max, msg[k])
	end
	table.insert(msg,1,1)
	-- tab.print(msg)
	osc.send({'localhost',57120}, '/oilcan/trig', msg)
end

oilcan_clipboard = {
}

local function add_oilcan_params()

	params:add_group('Oilcan',#param_specs+5)
	params:add_binary('oilcan_trig','trigger')
	params:set_action('oilcan_trig', function() 
		oilcan_trig(params:get('selected_timbre'), 1)
	end)
	params:add_binary('oilcan_save','save multipliers')
	params:add_binary('oilcan_load','load multipliers')
	params:add_number('selected_timbre','timbre to play',1,NUM_TIMBRES,1)

	params:add_separator('Multipliers')
	for _,v in ipairs(param_specs) do
		params:add{
			id = v.id..'_mult'
		,	name = '*'..v.name
		,	type = 'taper'
		,	min = 0
		,	max = 10
		,	default = 1
		,	k = 5
		,	units = 'x'
		}
	end

	params:set_action('oilcan_save',function()
		for _,v in ipairs(param_specs) do oilcan_clipboard[v.id] = params:get(v.id..'_mult') end
	end)
	params:lookup_param('oilcan_save').action()
	params:set_action('oilcan_load',function()
		for _,v in ipairs(param_specs) do params:set(v.id..'_mult',oilcan_clipboard[v.id]) end
	end)

	for i=1,NUM_TIMBRES do
		params:add_group('timbre '..i, 'timbre '..i, #param_specs)
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
		end
		-- params:hide('timbre '..i)
	end

	-- I think all timbres param groups should be visible when the player is active, that way you can construct a little drumkit on one track.

	-- params:set_action("selected_timbre", function()
	-- 	local t = params:get("selected_timbre")
	-- 	for i=1,NUM_TIMBRES do
	-- 		if i == t then
	-- 			params:show("timbre "..i)
	-- 		else
	-- 			params:hide("timbre "..i)
	-- 		end
	-- 	end
	-- end)
	params:bang()
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

	function player:note_on(note, vel)
		print("note", note)
		oilcan_trig(note % 12 + 1,vel)
	end

	function player:add_params()
        add_oilcan_params(i)
    end

	note_players['oilcan'] = player
end

mod.hook.register('script_pre_init', 'oilcan pre init', function()
	add_oilcan_player()
end)