#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#include <hosties3>
#include <lastrequest>

#define FEATURE_NAME "Knife Fight"
#define PLUGIN_NAME FEATURE_NAME

#define KNORMAL  FEATURE_NAME ... " - Normal"
#define BACKSTAB FEATURE_NAME ... " - Backstab"

bool g_bKnife = false;
bool g_bNormal = false;
bool g_bBackstab = false;

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

	bool bNormal    = Hosties3_RegisterLRGame(KNORMAL, "KnifeNormal");
	bool bBackstab  = Hosties3_RegisterLRGame(BACKSTAB, "KnifeAntiBackstab");
	
	Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Register Knife Normal: %d", FEATURE_NAME, bNormal);
	Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Register Knife Backstab: %d", FEATURE_NAME, bBackstab);
}

public void Hosties3_OnLastRequestChoosen(int client, int target, const char[] name)
{
	if(StrEqual(name, KNORMAL, false))
	{
		PrintToChatAll("%s", name);
		g_bKnife = true;
		g_bNormal = true;
	}
	else if(StrEqual(name, BACKSTAB, false))
	{
		PrintToChatAll("%s", name);
		g_bKnife = true;
		g_bBackstab = true;
	}
	
	if(g_bKnife)
	{
		SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
		SDKHook(target, SDKHook_TraceAttack, OnTraceAttack);
	}
	
	Hosties3_StripClientAll(client);
	Hosties3_StripClientAll(target);
	
	int iKnife1 = GivePlayerItem(client, "weapon_knife");
	int iKnife2 = GivePlayerItem(target, "weapon_knife");
	
	EquipPlayerWeapon(client, iKnife1);
	EquipPlayerWeapon(target, iKnife2);
}

public void Hosties3_OnLastRequestEnd(int client, int target)
{
	SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKUnhook(target, SDKHook_TraceAttack, OnTraceAttack);
	
	g_bKnife = false;
	g_bNormal = false;
	g_bBackstab = false;
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(!g_bKnife)
	{
		return Plugin_Continue;
	}
	
	if(damagetype == DMG_FALL || damagetype == DMG_GENERIC || attacker == 0)
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
		if(g_bNormal)
		{
			return Plugin_Continue;
		}
		else if(g_bBackstab)
		{
			float fAAngle[3], fVAngle[3], fBAngle[3];
			
			GetClientAbsAngles(victim, fVAngle);
			GetClientAbsAngles(attacker, fAAngle);
			MakeVectorFromPoints(fVAngle, fAAngle, fBAngle);
			
			if(fBAngle[1] > -90.0 && fBAngle[1] < 90.0)
			{
				return Plugin_Continue;
			}
			else
			{
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Handled;
}
