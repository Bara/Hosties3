#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

#include <hosties3>
#include <hosties3_lr>

#define FEATURE_NAME "Last Request"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;

int g_iLogLevel;

enum lrCache
{
	lrId,
	String:lrName[HOSTIES3_MAX_FEATURE_NAME],
	String:lrTranslations[HOSTIES3_MAX_FEATURE_NAME]
};
int g_iLRGames[lrCache];
ArrayList g_aLRGames = null;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = HOSTIES3_AUTHOR,
	version = HOSTIES3_VERSION,
	description = HOSTIES3_DESCRIPTION,
	url = HOSTIES3_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Hosties3_RegisterLRGame", Native_RegisterLRGame);
	
	RegPluginLibrary("hosties3-lr");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	Hosties3_CheckRequirements();
	
	if(g_aLRGames != null)
		g_aLRGames.Clear();
	
	g_aLRGames = new ArrayList(sizeof(g_iLRGames));
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
}

public int Native_RegisterLRGame(Handle plugin, int numParams)
{
	char name[HOSTIES3_MAX_FEATURE_NAME];
	char translations[HOSTIES3_MAX_FEATURE_NAME];
	
	GetNativeString(1, name, sizeof(name));
	GetNativeString(2, translations, sizeof(translations));
	
	int iCache[lrCache];
	
	iCache[lrId] = g_aLRGames.Length + 1;
	strcopy(iCache[lrName], sizeof(name), name);
	strcopy(iCache[lrTranslations], sizeof(translations), translations);

	Hosties3_LogToFile(HOSTIES3_PATH, "LRGames", DEBUG, "[LRGames] ID: %d - Name: %s - Translations: %s", iCache[lrId], iCache[lrName], iCache[lrTranslations]);

	g_aLRGames.PushArray(iCache[0]);
	
	for (int i = 0; i < g_aLRGames.Length; i++)
	{
		int iGang[lrCache];
		g_aLRGames.GetArray(i, iGang[0]);

		if(StrEqual(iGang[lrName], name, false))
			return true;
	}
	
	return false;
}
