#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <geoip>
#include <hosties3>

#define FEATURE_NAME "Advert"
#define FEATURE_FILE FEATURE_NAME ... ".cfg"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME
#define PLUGIN_CONFIG HOSTIES3_CONFIG ... FEATURE_FILE

bool g_bEnable;
int g_iLogLevel;

char g_sTime12[32];
char g_sTime24[32];

char g_sDate[32];
char g_sDateTime12[32];
char g_sDateTime24[32];

char g_sTag[64];
char g_sServerTags[128];

Handle g_hMessages;

float g_fMessageDelay;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = HOSTIES3_AUTHOR,
	version = HOSTIES3_VERSION,
	description = HOSTIES3_DESCRIPTION,
	url = HOSTIES3_URL
};

public Hosties3_OnPluginPreLoaded()
{
	Hosties3_IsLoaded();
	Hosties3_CheckServerGame();
}

public OnMapStart()
{
	if (!StrEqual(g_sServerTags, ""))
	{
		char g_sBuffer[64];
		Handle cvar = FindConVar("sv_tags");
		GetConVarString(cvar, g_sBuffer, sizeof(g_sBuffer));
		StrCat(g_sServerTags, sizeof(g_sServerTags), g_sBuffer);
		SetConVarString(cvar, g_sServerTags, true);
		CloseHandle(cvar);
	}
}


public Hosties3_OnConfigsLoaded()
{
	if (!(g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true)))
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}

	g_fMessageDelay = Hosties3_AddCvarFloat(FEATURE_NAME, "Delay Between Messages", 25.0);
	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_AddCvarString(FEATURE_NAME, "Server Tags", ",hosties3,jailbreak,jail,cs:go,", g_sServerTags, sizeof(g_sServerTags));
	Hosties3_AddCvarString(FEATURE_NAME, "Time 12", "%I:%M:%S%p", g_sTime12, sizeof(g_sTime12));
	Hosties3_AddCvarString(FEATURE_NAME, "Time 24", "%H:%M:%S", g_sTime24, sizeof(g_sTime24));
	Hosties3_AddCvarString(FEATURE_NAME, "Date", "%D", g_sDate, sizeof(g_sDate));
	Hosties3_AddCvarString(FEATURE_NAME, "Datetime 12", "%I:%M:%S%p - %D", g_sDateTime12, sizeof(g_sDateTime12));
	Hosties3_AddCvarString(FEATURE_NAME, "Datetime 24", "%H:%M:%S - %D", g_sDateTime24, sizeof(g_sDateTime24));

	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable - %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Tag - %s", FEATURE_NAME, g_sTag);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Server tags - %s", FEATURE_NAME, g_sServerTags);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Delay - %.1f", FEATURE_NAME, g_fMessageDelay);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Time12 Format - %s", FEATURE_NAME, g_sTime12);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Time24 Format - %s", FEATURE_NAME, g_sTime24);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Date Format - %s", FEATURE_NAME, g_sDate);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] DateTime12 Format - %s", FEATURE_NAME, g_sDateTime12);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] DateTime24 Format - %s", FEATURE_NAME, g_sDateTime24);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
	LoadMessages();

	RegAdminCmd("sm_reloadadverts", Command_ReloadAdverts, ADMFLAG_ROOT);
}

public Action Command_ReloadAdverts(client, args)
{
	if (g_hMessages)
	{
		CloseHandle(g_hMessages);
	}

	LoadMessages();
	Hosties3_PrintToChat(client, "%s Messages are successfully reloaded", g_sTag);
}

public Action Timer_PostAdvert(Handle timer)
{
	if (!KvGotoNextKey(g_hMessages))
	{
		KvGoBack(g_hMessages);
		KvGotoFirstSubKey(g_hMessages);
	}

	Hosties3_LoopClients(i)
	{
		if (IsClientInGame(i))
		{
			char sType[12];
			char sText[256];
			char sBuffer[256];
			char sCountryTag[3];
			char sIP[26];

			GetClientIP(i, sIP, sizeof(sIP));
			GeoipCode2(sIP, sCountryTag);
			KvGetString(g_hMessages, sCountryTag, sText, sizeof(sText), "LANGMISSING");

			if (StrEqual(sText, "LANGMISSING"))
			{
				KvGetString(g_hMessages, "default", sText, sizeof(sText));
			}

			if (StrContains(sText , "{NEXTMAP}") != -1)
			{
				GetNextMap(sBuffer, sizeof(sBuffer));
				ReplaceString(sText, sizeof(sText), "{NEXTMAP}", sBuffer);
			}

			if (StrContains(sText , "{TIMELEFT}") != -1)
			{
				int iMins, iSecs, iTimeLeft;

				if (GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0)
				{
					iMins = iTimeLeft / 60;
					iSecs = iTimeLeft % 60;
				}

				Format(sBuffer, sizeof(sBuffer), "%d:%02d", iMins, iSecs);
				ReplaceString(sText, sizeof(sText), "{TIMELEFT}", sBuffer);
			}

			if (StrContains(sText, "{CURRENTMAP}") != -1)
			{
				GetCurrentMap(sBuffer, sizeof(sBuffer));
				ReplaceString(sText, sizeof(sText), "{CURRENTMAP}", sBuffer);
			}

			if (StrContains(sText, "{TIME12}") != -1)
			{
				FormatTime(sBuffer, sizeof(sBuffer), g_sTime12);
				ReplaceString(sText, sizeof(sText), "{TIME12}", sBuffer);
			}

			if (StrContains(sText, "{TIME24}") != -1)
			{
				FormatTime(sBuffer, sizeof(sBuffer), g_sTime24);
				ReplaceString(sText, sizeof(sText), "{TIME24}", sBuffer);
			}

			if (StrContains(sText, "{DATE}") != -1)
			{
				FormatTime(sBuffer, sizeof(sBuffer), g_sDate);
				ReplaceString(sText, sizeof(sText), "{DATE}", sBuffer);
			}

			if (StrContains(sText, "{DATETIME12}") != -1)
			{
				FormatTime(sBuffer, sizeof(sBuffer), g_sDateTime12);
				ReplaceString(sText, sizeof(sText), "{DATETIME12}", sBuffer);
			}

			if (StrContains(sText, "{DATETIME24}") != -1)
			{
				FormatTime(sBuffer, sizeof(sBuffer), g_sDateTime24);
				ReplaceString(sText, sizeof(sText), "{DATETIME24}", sBuffer);
			}

			KvGetString(g_hMessages, "type", sType, sizeof(sType));

			if (StrContains(sType, "T", false) != -1)
			{
				Hosties3_PrintToChat(i, "%s %s", g_sTag, sText);
			}

			if (StrContains(sType, "C", false) != -1)
			{
				PrintCenterText(i, "%s %s", g_sTag, sText);
			}
	 	}
	}
}

LoadMessages()
{
	g_hMessages = CreateKeyValues("Hosties3");

	if (!FileExists(PLUGIN_CONFIG))
	{
		SetFailState("[%s] '%s' not found!", FEATURE_NAME, PLUGIN_CONFIG);
		return;
	}

	FileToKeyValues(g_hMessages, PLUGIN_CONFIG);
	if (KvJumpToKey(g_hMessages, FEATURE_NAME))
	{
		if (KvJumpToKey(g_hMessages, "Messages"))
		{
			KvGotoFirstSubKey(g_hMessages);
		}
	}

	CreateTimer(g_fMessageDelay, Timer_PostAdvert, _, TIMER_REPEAT);
}
