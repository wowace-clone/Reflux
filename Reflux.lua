-- DeepCopy function.
local function DeepCopy(t, lookup_table)
	local copy = {}
	if type(t) ~= "table" then return t end
	for i,v in pairs(t) do
		if type(v) ~= "table" then
			copy[i] = v
		else
			lookup_table = lookup_table or {}
			lookup_table[t] = copy
			if lookup_table[v] then
				copy[i] = lookup_table[v] -- we already copied this table. reuse the copy.
			else
				copy[i] = DeepCopy(v,lookup_table) -- not yet copied. copy it.
			end
		end
	end
	return copy
end
-- Setup ace profiles if we find any
local function setAceProfile(profile)
	local ls_ace = false
	-- Ace DB 3 check
	if LibStub then
		local AceDB = LibStub:GetLibrary("AceDB-3.0",true)
		if AceDB and AceDB.db_registry then
			for db in pairs(AceDB.db_registry) do
				if not db.parent then --db.sv is a ref to the saved vairable name
					db:SetProfile(profile)
				end
			end
		end
	end
	-- Ace DB 2 check is thoery we shoul dbe able to check this via LibStub
	-- However someone may have some anceitn copy of Ace2 that was never upgraded to LibStub
	-- AceLibrary delegate to LibStub so its all good
	if AceLibrary then
		local AceDB = AceLibrary("AceDB-2.0")
		if AceDB and AceDB.registry then
			for db in pairs(AceDB.registry) do
				db:SetProfile(profile)
			end
		end
	end	
end
-- Copy ace profiles if we find any
local function copyAceProfile(profile)
	local ls_ace = false
	-- Ace DB 3 check
	if LibStub then
		local AceDB = LibStub:GetLibrary("AceDB-3.0",true)
		if AceDB and AceDB.db_registry then
			for db in pairs(AceDB.db_registry) do
				if not db.parent then --db.sv is a ref to the saved vairable name
					db:CopyProfile(profile,false)
				end
			end
		end
	end
	-- Ace DB 2 check is thoery we shoul dbe able to check this via LibStub
	-- However someone may have some anceitn copy of Ace2 that was never upgraded to LibStub
	-- AceLibrary delegate to LibStub so its all good
	if AceLibrary then
		local AceDB = AceLibrary("AceDB-2.0")
		if AceDB and AceDB.registry then
			for db in pairs(AceDB.registry) do
				db:CopyProfileFrom(profile)
			end
		end
	end	
end
-- Delete Ace profile
local function deleteAceProfile(profile)
	local ls_ace = false
	-- Ace DB 3 check
	if LibStub then
		local AceDB = LibStub:GetLibrary("AceDB-3.0",true)
		if AceDB and AceDB.db_registry then
			for db in pairs(AceDB.db_registry) do
				if not db.parent then --db.sv is a ref to the saved vairable name
					db:DeleteProfile(profile)
				end
			end
		end
	end
	-- Ace DB 2 check is thoery we shoul dbe able to check this via LibStub
	-- However someone may have some anceitn copy of Ace2 that was never upgraded to LibStub
	-- AceLibrary delegate to LibStub so its all good
	if AceLibrary then
		local AceDB = AceLibrary("AceDB-2.0")
		if AceDB and AceDB.registry then
			for db in pairs(AceDB.registry) do
				db:DeleteProfile(profile,true)
			end
		end
	end	
end
-- Show help
local function showHelp()
	print("/reflux switch [profile name]")
	print("This switches to a given profile. Emulated variables are only touched if you previously created a profile in reflux. This automatically Reloads the UI")
	print("/reflux create [profile name]")
	print("This created a profile set.")
	print("/reflux add [saved variable]")
	print("This will add a given saved variable to the profile emulation. You will need to get this name from the .toc file")
	print("/reflux save")
	print("This saves the emulated profiles.")
	print("/reflux cleardb")
	print("This will clear out all Reflux saved information.")
	print("/reflux show")
	print("This will show you what the active profile is, and all emulated variables.")
end
-- Store Addon state
local function storeAddonState(tbl)
	local index = 1
	local count = GetNumAddOns()
	while index < count do
		local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(index)
		tbl[name]=enabled
	end
end
local function restoreAddonState(tbl)
	for k,v in pairs(tbl) do
		if v then
			EnableAddOn(k)
		else
			DisableAddOn(k)
		end
	end
	ReloadUI()
end

SlashCmdList["REFLUX"] = function (msg)
	local cmd, arg = strmatch(msg, "%s*([^%s]+)%s*(.*)");
	if cmd == nil or strlen(cmd) < 1 then
		showHelp()
		return
	end
	-- Create or use the existing saved varaibles.
	-- We are never used till after a player logs in.
	RefluxDB = RefluxDB or { profiles = { }, activeProfile=false, emulated={}, addons = {} }
	if cmd == "show" then
		if RefluxDB.activeProfile then
			print("Active Profile is "..RefluxDB.activeProfile)
		else
			print("There is no active profile")
		end
		for k,v in pairs(RefluxDB.profiles) do
			print(k.." is an available profile.")
		end
		if RefluxDB.emulated then
			if #RefluxDB.emulated == 0 then
				print("Nothing is being emulated")
			end
			for index,var in pairs(RefluxDB.emulated) do
				print(var.." is being emulated.")
			end
		end
	elseif cmd == "switch" then
		-- Check RefluxDB to see if we have a createdProfile called xxx
		if RefluxDB.profiles[arg] then
			-- do a dep copy of all the saved off tables
			for k,v in pairs(RefluxDB.profiles[arg]) do
				if v and k then
					setglobal(k,DeepCopy(v))
				end
			end
		end
		setAceProfile(arg)
		RefluxDB.activeProfile=arg
		ReloadUI()
	elseif cmd == "switchaddons" then
		if RefluxDB.addons[arg] then
			restoreAddonState(RefluxDB.addons[arg])
		end
	elseif cmd == "cleardb" then
		RefluxDB = { profiles = { }, activeProfile=false, emulated={},addons = {} }
		print("Reflux database cleared.")
	elseif cmd == "save" then
		if not RefluxDB.activeProfile then
			print("No profiles are active, please create or switch to one.")
			return
		end
		if RefluxDB.profiles[RefluxDB.activeProfile] then
			for index,var in ipairs(RefluxDB.emulated) do
				RefluxDB.profiles[RefluxDB.activeProfile][var]=getglobal(var)
				print("Saving "..var)
			end
		else
			print("No emulations saved.")
		end
		if arg == "addons" then
			RefluxDB.addons[RefluxDB.activeProfile] = {}
			storeAddonState(RefluxDB.addons[RefluxDB.activeProfile])
			print("Saving addons")
		end
	elseif cmd == "create" and strlen(arg) > 1 then
		setAceProfile(arg)
		RefluxDB.profiles[arg] = {}
		RefluxDB.activeProfile=arg
		for index,var in ipairs(RefluxDB.emulated) do
			setglobal(var,nil)
		end
		ReloadUI()
	elseif cmd == "copy" and strlen(arg) > 1 then
		if not RefluxDB.activeProfile then
			print("You need to activate a profile before you can copy from another profile")
			return
		end
		copyAceProfile(arg)
		if RefluxDB.profiles[arg] then
			RefluxDB.profiles[RefluxDB.activeProfile] = DeepCopy(RefluxDB.profiles[arg])
			RefluxDB.addons[RefluxDB.activeProfile] = DeepCopy(RefluxDB.addons[arg])
		else
			print(arg.." not found.")
		end
	elseif cmd == "delete" and strlen(arg) > 1 then
		if RefluxDB.profiles[arg] then
			RefluxDB.profiles[arg] = nil
			RefluxDB.addons[arg] = nil
		end
		deleteAceProfile(arg)
		if arg == RefluxDB.activeProfile then
			RefluxDB.activeProfile = false
		end
	elseif cmd == "add" and strlen(arg) > 1 then
		if RefluxDB.emulated then
			if getglobal(arg) then
				tinsert(RefluxDB.emulated,arg)
				print(arg.." Added to emulation list.")
			else
				print(arg.." not found, please check the spelling it is case sensistive.")
			end
		end
	else
		showHelp()
	end
end

SLASH_REFLUX1 = "/reflux"