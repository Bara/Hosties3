#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#pragma newdecls required

#include <hosties3>
#include <lastrequest>

#define FEATURE_NAME "Knives"
#define PLUGIN_NAME FEATURE_NAME

bool g_bKnife = false;

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

	bool success = Hosties3_RegisterLRGame(FEATURE_NAME, "knives");
	
	Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Register status: %d", FEATURE_NAME, success);
}

public void Hosties3_OnLastRequestChoosen(int client, int target, const char[] name)
{
	if(StrEqual(name, FEATURE_NAME, false))
	{
		PrintToChatAll("KNIVE!!!");
		g_bKnife = true;
		
		SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
		SDKHook(target, SDKHook_TraceAttack, OnTraceAttack);
	}
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(!g_bKnife)
	{
		return Plugin_Continue;
	}
	
	if(damagetype == DMG_FALL
	|| damagetype == DMG_GENERIC
	|| damagetype == DMG_CRUSH
	|| damagetype == DMG_SLASH
	|| damagetype == DMG_BURN
	|| damagetype == DMG_VEHICLE
	|| damagetype == DMG_FALL
	|| damagetype == DMG_BLAST
	|| damagetype == DMG_SHOCK
	|| damagetype == DMG_SONIC
	|| damagetype == DMG_ENERGYBEAM
	|| damagetype == DMG_DROWN
	|| damagetype == DMG_PARALYZE
	|| damagetype == DMG_NERVEGAS
	|| damagetype == DMG_POISON
	|| damagetype == DMG_ACID
	|| damagetype == DMG_AIRBOAT
	|| damagetype == DMG_PLASMA
	|| damagetype == DMG_RADIATION
	|| damagetype == DMG_SLOWBURN
	|| attacker == 0)
	{
		return Plugin_Continue;
	}
	
	if(Hosties3_IsClientValid(attacker) && Hosties3_IsClientValid(victim) && !Hosties3_IsClientInLastRequest(attacker) || !Hosties3_IsClientInLastRequest(victim))
	{
		return Plugin_Handled;
	}
	
	char sWeapon[32];
	GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
	
	if ((StrContains(sWeapon, "knife", false) != -1) || (StrContains(sWeapon, "bayonet", false) != -1))
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}
