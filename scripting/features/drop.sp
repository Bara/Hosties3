#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <hosties3>

#define FEATURE_NAME "Drop"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;

bool g_bTaser;
bool g_bHEGrenade;
bool g_bFlash;
bool g_bSmoke;
bool g_bIncGrenade;
bool g_bMolotov;
bool g_bDecoy;
bool g_bKnife;

int g_iLogLevel;

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

public Hosties3_OnConfigsLoaded()
{
	if (!(g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true)))
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}

	g_bTaser = Hosties3_AddCvarBool(FEATURE_NAME, "Taser", true);
	g_bHEGrenade = Hosties3_AddCvarBool(FEATURE_NAME, "HE Grenade", true);
	g_bFlash = Hosties3_AddCvarBool(FEATURE_NAME, "Flash", true);
	g_bSmoke = Hosties3_AddCvarBool(FEATURE_NAME, "Smoke", true);
	g_bIncGrenade = Hosties3_AddCvarBool(FEATURE_NAME, "Inc Grenade", true);
	g_bMolotov = Hosties3_AddCvarBool(FEATURE_NAME, "Molotov", true);
	g_bDecoy = Hosties3_AddCvarBool(FEATURE_NAME, "Decoy", true);
	g_bKnife = Hosties3_AddCvarBool(FEATURE_NAME, "Knife", true);

	g_iLogLevel = Hosties3_GetLogLevel();

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Taser: %d", FEATURE_NAME, g_bTaser);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] HEGrenade: %d", FEATURE_NAME, g_bHEGrenade);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Flash: %d", FEATURE_NAME, g_bFlash);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Smoke: %d", FEATURE_NAME, g_bSmoke);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] IncGrenade: %d", FEATURE_NAME, g_bIncGrenade);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Molotov: %d", FEATURE_NAME, g_bMolotov);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Decoy: %d", FEATURE_NAME, g_bDecoy);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Knife: %d", FEATURE_NAME, g_bKnife);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	AddCommandListener(Command_Drop, "drop");
}

public Action Command_Drop(int client, const char[] command, int args)
{
	if (IsClientInGame(client))
	{
		char sName[32];
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEdict(weapon))
		{
			return Plugin_Stop;
		}

		GetEdictClassname(weapon, sName, sizeof(sName));

		if (StrEqual("weapon_taser", sName, false) && g_bTaser)
		{
			if (GetEntProp(weapon, Prop_Data, "m_iClip1") > 0)
			{
				int nSequence = GetEntProp(weapon, Prop_Data, "m_nSequence");
				if((Hosties3_GetServerGame() == Game_CSS && nSequence != 5) || (Hosties3_GetServerGame() == Game_CSGO && nSequence != 2))
				{
					SDKHooks_DropWeapon(client, weapon);
					return Plugin_Handled;
				}
			}
		}
		else if (StrEqual("weapon_hegrenade", sName, false) && g_bHEGrenade ||
				StrEqual("weapon_flashbang", sName, false) && g_bFlash ||
				StrEqual("weapon_smokegrenade", sName, false) && g_bSmoke ||
				StrEqual("weapon_incgrenade", sName, false) && g_bIncGrenade ||
				StrEqual("weapon_molotov", sName, false) && g_bMolotov ||
				StrEqual("weapon_decoy", sName, false) && g_bDecoy)
		{
			int nSequence = GetEntProp(weapon, Prop_Data, "m_nSequence");
			if((Hosties3_GetServerGame() == Game_CSS && nSequence != 5) || (Hosties3_GetServerGame() == Game_CSGO && nSequence != 2))
			{
				SDKHooks_DropWeapon(client, weapon);
				return Plugin_Handled;
			}
		}
		else if (StrEqual("weapon_knife", sName, false) && g_bKnife)
		{
			SDKHooks_DropWeapon(client, weapon);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
