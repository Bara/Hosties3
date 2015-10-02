public Cvar_AddCVarInt(Handle plugin, numParams)
{
	char feature[64], sFeature[64];
	GetNativeString(1, feature, sizeof(feature));
	Hosties3_StringToLower(feature, sFeature, sizeof(sFeature));
	Hosties3_RemoveSpaces(sFeature, sFeature, sizeof(sFeature));

	char cvar[128], sCvar[128];
	GetNativeString(2, cvar, sizeof(cvar));
	Hosties3_StringToLower(cvar, sCvar, sizeof(sCvar));
	Hosties3_RemoveSpaces(sCvar, sCvar, sizeof(sCvar));

	int value = GetNativeCell(3);

	bool bFound = false;

	for (int i = 0; i < GetArraySize(g_hCvarCache); i++)
	{
		new iCache[CvarCache];
		GetArrayArray(g_hCvarCache, i, iCache[0]);

		if (StrEqual(iCache[fFeature], sFeature, false) && StrEqual(iCache[fCvar], sCvar, false))
		{
			bFound = true;
			return StringToInt(iCache[fValue]);
		}
	}

	if(!bFound)
	{
		if (Hosties3_IsSQLValid(g_hDatabase))
		{
			char sQuery[2048];
			Format(sQuery, sizeof(sQuery), "INSERT INTO `hosties3_settings` (`modul`, `name`, `value`, `type`) VALUES ('%s', '%s', '%d', '%s')", sFeature, sCvar, value, "int");
			SQLQuery(sQuery);
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Error: Database handle is invalid!");
		}

		return value;
	}
	return false;
}

public Cvar_AddCVarBool(Handle plugin, numParams)
{
	char feature[64], sFeature[64];
	GetNativeString(1, feature, sizeof(feature));
	Hosties3_StringToLower(feature, sFeature, sizeof(sFeature));
	Hosties3_RemoveSpaces(sFeature, sFeature, sizeof(sFeature));

	char cvar[128], sCvar[128];
	GetNativeString(2, cvar, sizeof(cvar));
	Hosties3_StringToLower(cvar, sCvar, sizeof(sCvar));
	Hosties3_RemoveSpaces(sCvar, sCvar, sizeof(sCvar));

	bool value = GetNativeCell(3);

	bool bFound = false;

	for (int i = 0; i < GetArraySize(g_hCvarCache); i++)
	{
		new iCache[CvarCache];
		GetArrayArray(g_hCvarCache, i, iCache[0]);

		if (StrEqual(iCache[fFeature], sFeature, false) && StrEqual(iCache[fCvar], sCvar, false))
		{
			bFound = true;
			return bool:StringToInt(iCache[fValue]);
		}
	}

	if(!bFound)
	{
		if (Hosties3_IsSQLValid(g_hDatabase))
		{
			char sQuery[2048];
			Format(sQuery, sizeof(sQuery), "INSERT INTO `hosties3_settings` (`modul`, `name`, `value`, `type`) VALUES ('%s', '%s', '%d', '%s')", sFeature, sCvar, value, "bool");
			SQLQuery(sQuery);
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Error: Database handle is invalid!");
		}

		return value;
	}
	return false;
}

public Cvar_AddCVarFloat(Handle plugin, numParams)
{
	char feature[64], sFeature[64];
	GetNativeString(1, feature, sizeof(feature));
	Hosties3_StringToLower(feature, sFeature, sizeof(sFeature));
	Hosties3_RemoveSpaces(sFeature, sFeature, sizeof(sFeature));

	char cvar[128], sCvar[128];
	GetNativeString(2, cvar, sizeof(cvar));
	Hosties3_StringToLower(cvar, sCvar, sizeof(sCvar));
	Hosties3_RemoveSpaces(sCvar, sCvar, sizeof(sCvar));

	float value = GetNativeCell(3);

	bool bFound = false;

	for (int i = 0; i < GetArraySize(g_hCvarCache); i++)
	{
		new iCache[CvarCache];
		GetArrayArray(g_hCvarCache, i, iCache[0]);

		if (StrEqual(iCache[fFeature], sFeature, false) && StrEqual(iCache[fCvar], sCvar, false))
		{
			bFound = true;
			return _:StringToFloat(iCache[fValue]);
		}
	}

	if(!bFound)
	{
		if (Hosties3_IsSQLValid(g_hDatabase))
		{
			char sQuery[2048];
			Format(sQuery, sizeof(sQuery), "INSERT INTO `hosties3_settings` (`modul`, `name`, `value`, `type`) VALUES ('%s', '%s', '%f', '%s')", sFeature, sCvar, value, "float");
			SQLQuery(sQuery);
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Error: Database handle is invalid!");
		}

		return _:value;
	}
	return false;
}

public Cvar_AddCVarString(Handle plugin, numParams)
{
	char feature[64], sFeature[64];
	GetNativeString(1, feature, sizeof(feature));
	Hosties3_StringToLower(feature, sFeature, sizeof(sFeature));
	Hosties3_RemoveSpaces(sFeature, sFeature, sizeof(sFeature));

	char cvar[128], sCvar[128];
	GetNativeString(2, cvar, sizeof(cvar));
	Hosties3_StringToLower(cvar, sCvar, sizeof(sCvar));
	Hosties3_RemoveSpaces(sCvar, sCvar, sizeof(sCvar));

	char value[256];
	GetNativeString(3, value, sizeof(value));

	bool bFound = false;

	for (int i = 0; i < GetArraySize(g_hCvarCache); i++)
	{
		new iCache[CvarCache];
		GetArrayArray(g_hCvarCache, i, iCache[0]);

		if (StrEqual(iCache[fFeature], sFeature, false) && StrEqual(iCache[fCvar], sCvar, false))
		{
			bFound = true;
			SetNativeString(4, iCache[fValue], GetNativeCell(5), false);
			return true;
		}
	}

	if(!bFound)
	{
		if (Hosties3_IsSQLValid(g_hDatabase))
		{
			char sQuery[2048];
			Format(sQuery, sizeof(sQuery), "INSERT INTO `hosties3_settings` (`modul`, `name`, `value`, `type`) VALUES ('%s', '%s', '%s', '%s')", sFeature, sCvar, value, "str");
			SQLQuery(sQuery);
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Error: Database handle is invalid!");
		}

		SetNativeString(4, value, GetNativeCell(5), false);
		return true;
	}
	SetNativeString(4, "", GetNativeCell(5), false);
	return false;
}
