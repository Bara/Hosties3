public Client_IsValidClient(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	bool alive = GetNativeCell(2);
	bool bots = GetNativeCell(3);
	bool admin = GetNativeCell(4);

	if (client > 0 && client <= MaxClients && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)) && (bots == false && !IsFakeClient(client)) && (admin == false || Hosties3_IsClientAdmin(client))
	)
	{
		return true;
	}
	return false;
}

public Client_StripClientAll(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsClientValid(client))
	{
		bool ammo = GetNativeCell(2);

		Client_RemoveAllWeapons(client, "", ammo);
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}
}

public Client_StripClient(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsClientValid(client))
	{
		bool ammo = GetNativeCell(3);

		char weapon[32];
		GetNativeString(2, weapon, sizeof(weapon));

		Client_RemoveWeapon(client, weapon, ammo);
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}
}

public Client_SendOverlayToClient(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsClientValid(client))
	{
		char overlay[PLATFORM_MAX_PATH + 1];

		GetNativeString(2, overlay, sizeof(overlay));

		ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}
}

public Client_SendOverlayToAll(Handle plugin, numParams)
{
	char overlay[PLATFORM_MAX_PATH + 1];
	GetNativeString(1, overlay, sizeof(overlay));

	Hosties3_LoopClients(i)
	{
		if (Hosties3_IsClientValid(i) && !IsFakeClient(i))
		{
			ClientCommand(i, "r_screenoverlay \"%s\"", overlay);
		}
	}
}

// https://forums.alliedmods.net/showpost.php?p=1204522&postcount=12
public Client_GetRandomClient(Handle plugin, numParams)
{
	int team = GetNativeCell(1);
	new clients[MaxClients + 1];
	int clientCount;

	Hosties3_LoopClients(i)
	{
		if (IsClientInGame(i) && (GetClientTeam(i) == team))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

public Client_GetClientID(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	char sBuffer[128];
	Format(sBuffer, sizeof(sBuffer), "%s", g_sClientID[client]);

	SetNativeString(2, sBuffer, GetNativeCell(3), false);
}

public Client_SwitchClient(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	int team = GetNativeCell(2);

	ChangeClientTeam(client, team);

	int clients[1];
	Handle bf;
	clients[0] = client;
	bf = StartMessage("VGUIMenu", clients, 1);

	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetString(bf, "name", "team");
		PbSetBool(bf, "show", true);
	}
	else
	{
		BfWriteString(bf, "team");
		BfWriteByte(bf, 1);
		BfWriteByte(bf, 0);
	}

	EndMessage();
}

public Client_SteamIDToCommunityID(Handle plugin, numParams)
{
	char steamid[24];
	char communityid[64];
	GetNativeString(1, steamid, sizeof(steamid));
	int length = GetNativeCell(3);

	if (strlen(steamid) < 11 || steamid[0] != 'S' || steamid[6] == 'I')
	{
		communityid[0] = 0;
		return;
	}

	int iUpper = 765611979;
	int iFriendID = StringToInt(steamid[10]) * 2 + 60265728 + steamid[8] - 48;
	int iDiv = iFriendID / 100000000;
	int iIdx = 9-(iDiv ? iDiv / 10 + 1 : 0);
	iUpper += iDiv;
	IntToString(iFriendID, communityid[iIdx], length-iIdx);
	iIdx = communityid[9];
	IntToString(iUpper, communityid, length);
	communityid[9] = iIdx;

	SetNativeString(2, communityid, GetNativeCell(3), false);
}

public Client_GetClientColors(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	bool gotconfig = false;
	char prop[32];

	if (!gotconfig)
	{
		Handle gc = LoadGameConfigFile("core.games");
		bool exists = GameConfGetKeyValue(gc, "m_clrRender", prop, sizeof(prop));
		CloseHandle(gc);

		if (!exists)
		{
			strcopy(prop, sizeof(prop), "m_clrRender");
		}

		gotconfig = true;
	}

	int offset = GetEntSendPropOffs(client, prop);

	if (offset <= 0)
	{
		ThrowError("GetEntityRenderColor not supported by this mod");
	}

	SetNativeCellRef(2, GetEntData(client, offset, 1));
	SetNativeCellRef(3, GetEntData(client, offset + 1, 1));
	SetNativeCellRef(4, GetEntData(client, offset + 2, 1));
	SetNativeCellRef(5, GetEntData(client, offset + 3, 1));
}
