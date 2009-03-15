-- Basic Addon, nothing fancy

SlashCmdList["REFLUX"] = function (message)
	if strlen(message) < 1 then
		print("/reflux <profile name>")
		return
	end
	local ls_ace = false
	-- Ace DB 3 check
	if LibStub then
		local AceDB = LibStub:GetLibrary("AceDB-3.0",true)
		if AceDB and AceDB.db_registry then
			for db in pairs(AceDB.db_registry) do
				if not db.parent then
					db:SetProfile(message)
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
				db:SetProfile(message)
			end
		end
	end	
	ReloadUI()
end

SLASH_REFLUX1 = "/reflux"