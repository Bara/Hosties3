#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

#include <hosties3>
#include <lastrequest>

#define FEATURE_NAME "Lastrequet Test"
#define PLUGIN_NAME FEATURE_NAME

bool g_bEnable;
int g_iLogLevel;

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
	if (!(g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true)))
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}

	g_iLogLevel = Hosties3_GetLogLevel();

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
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
}
