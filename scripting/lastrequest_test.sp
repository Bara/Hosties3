#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

#include <hosties3>
#include <lastrequest>

#define FEATURE_NAME "Lastrequet Test"
#define PLUGIN_NAME FEATURE_NAME

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = HOSTIES3_AUTHOR,
	version = HOSTIES3_VERSION,
	description = HOSTIES3_DESCRIPTION,
	url = HOSTIES3_URL
};

public void OnAllPluginsLoaded()
{
	Hosties3_CheckRequirements();
}

public void Hosties3_OnConfigsLoaded()
{
	if (!Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true))
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}

	bool success = Hosties3_RegisterLRGame(FEATURE_NAME, "example");
	
	Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Register status: %d", FEATURE_NAME, success);
}

public void Hosties3_OnLastRequestChoosen(int client, int target, const char[] name)
{
	PrintToChat(client, "%s", name);
}

public bool Hosties_OnLastRequestAvailable(int client)
{
	if(Hosties3_IsLastRequestAvailable())
	{
		PrintToChatAll("Last request is now available!");
		PrintToChatAll("Last T is: %N", client);
	}
	PrintToChatAll("(Hosties_OnLastRequestAvailable) called!");
}
