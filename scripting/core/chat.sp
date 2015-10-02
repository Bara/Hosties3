public Chat_PrintToChat(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	char sBuffer[MAX_MESSAGE_LENGTH];
	FormatNativeString(0, 2, 3, sizeof(sBuffer), _, sBuffer);


	if (!g_bFixColors)
	{
		Hosties3_FixColor();
	}


	if (Hosties3_GetServerGame() == Game_CSGO)
	{
		C_PrintToChat(client, sBuffer);
		C_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
	else
	{
		MC_PrintToChat(client, sBuffer);
		MC_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
}

public Chat_PrintToChatAll(Handle plugin, numParams)
{
	char sBuffer[MAX_MESSAGE_LENGTH];
	FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);


	if (!g_bFixColors)
	{
		Hosties3_FixColor();
	}


	if (Hosties3_GetServerGame() == Game_CSGO)
	{
		C_PrintToChatAll(sBuffer);
		C_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
	else
	{
		MC_PrintToChatAll(sBuffer);
		MC_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
}

public Chat_PrintToChatEx(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	int author = GetNativeCell(2);

	char sBuffer[MAX_MESSAGE_LENGTH];
	FormatNativeString(0, 3, 4, sizeof(sBuffer), _, sBuffer);


	if (!g_bFixColors)
	{
		Hosties3_FixColor();
	}


	if (Hosties3_GetServerGame() == Game_CSGO)
	{
		C_PrintToChatEx(client, author, sBuffer);
		C_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
	else
	{
		MC_PrintToChatEx(client, author, sBuffer);
		MC_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
}

public Chat_PrintToChatAllEx(Handle plugin, numParams)
{
	int author = GetNativeCell(1);

	char sBuffer[MAX_MESSAGE_LENGTH];
	FormatNativeString(0, 2, 3, sizeof(sBuffer), _, sBuffer);


	if (!g_bFixColors)
	{
		Hosties3_FixColor();
	}


	if (Hosties3_GetServerGame() == Game_CSGO)
	{
		C_PrintToChatAllEx(author, sBuffer);
		C_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
	else
	{
		MC_PrintToChatAllEx(author, sBuffer);
		MC_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
}

public Chat_ReplyToCommand(Handle plugin, numParams)
{
	int author = GetNativeCell(1);

	char sBuffer[MAX_MESSAGE_LENGTH];
	FormatNativeString(0, 2, 3, sizeof(sBuffer), _, sBuffer);


	if (!g_bFixColors)
	{
		Hosties3_FixColor();
	}


	if (Hosties3_GetServerGame() == Game_CSGO)
	{
		C_ReplyToCommand(author, sBuffer);
		C_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
	else
	{
		MC_ReplyToCommand(author, sBuffer);
		MC_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
}

public Chat_ReplyToCommandEx(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	int author = GetNativeCell(2);

	char sBuffer[MAX_MESSAGE_LENGTH];
	FormatNativeString(0, 3, 4, sizeof(sBuffer), _, sBuffer);


	if (!g_bFixColors)
	{
		Hosties3_FixColor();
	}


	if (Hosties3_GetServerGame() == Game_CSGO)
	{
		C_ReplyToCommandEx(client, author, sBuffer);
		C_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
	else
	{
		MC_ReplyToCommandEx(client, author, sBuffer);
		MC_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
}

public Chat_ShowActivity(Handle plugin, numParams)
{
	int author = GetNativeCell(1);

	char sBuffer[MAX_MESSAGE_LENGTH];
	FormatNativeString(0, 2, 3, sizeof(sBuffer), _, sBuffer);


	if (!g_bFixColors)
	{
		Hosties3_FixColor();
	}


	if (Hosties3_GetServerGame() == Game_CSGO)
	{
		C_ShowActivity(author, sBuffer);
		C_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
	else
	{
		MC_ShowActivity(author, sBuffer);
		MC_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
}

public Chat_ShowActivityEx(Handle plugin, numParams)
{
	int author = GetNativeCell(1);

	char sTag[32];
	GetNativeString(2, sTag, sizeof(sTag));

	char sBuffer[MAX_MESSAGE_LENGTH];
	FormatNativeString(0, 3, 4, sizeof(sBuffer), _, sBuffer);


	if (!g_bFixColors)
	{
		Hosties3_FixColor();
	}


	if (Hosties3_GetServerGame() == Game_CSGO)
	{
		C_ShowActivityEx(author, sTag, sBuffer);
		C_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
	else
	{
		MC_ShowActivityEx(author, sTag, sBuffer);
		MC_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
}

public Chat_ShowActivity2(Handle plugin, numParams)
{
	int author = GetNativeCell(1);

	char sTag[32];
	GetNativeString(2, sTag, sizeof(sTag));

	char sBuffer[MAX_MESSAGE_LENGTH];
	FormatNativeString(0, 3, 4, sizeof(sBuffer), _, sBuffer);


	if (!g_bFixColors)
	{
		Hosties3_FixColor();
	}


	if (Hosties3_GetServerGame() == Game_CSGO)
	{
		C_ShowActivity2(author, sTag, sBuffer);
		C_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
	else
	{
		MC_ShowActivity2(author, sTag, sBuffer);
		MC_RemoveTags(sBuffer, sizeof(sBuffer));
		PrintToServer(sBuffer);
	}
}

stock CFormatColor(const char[] message, maxlength, author=-1)
{
	if (!g_bFixColors)
	{
		Hosties3_FixColor();
	}


	if (Hosties3_GetServerGame() == Game_CSGO)
	{
		if (author == 0)
		{
			author = -1;
		}

		C_Format(message, maxlength, author);
	}
	else
	{
		if (author == -1)
		{
			author = 0;
		}

		MC_ReplaceColorCodes(message, author, false, maxlength);
	}
}

stock Hosties3_FixColor()
{
	g_bFixColors = true;

	if (!C_ColorAllowed(Color_Lightgreen))
	{
		if (C_ColorAllowed(Color_Lime))
		{
			C_ReplaceColor(Color_Lightgreen, Color_Lime);
		}
		else if (C_ColorAllowed(Color_Olive))
		{
			C_ReplaceColor(Color_Lightgreen, Color_Olive);
		}
	}
}
