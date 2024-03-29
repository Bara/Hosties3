#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <hosties3>
#include <hosties3_rebel>

#undef REQUIRE_PLUGIN
#tryinclude <hosties3_vip>

#define FEATURE_NAME "Rebel"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
bool g_bShowMessage;
bool g_bMessageOnDead;
int g_iLogLevel;
bool g_bSetColor;
bool g_bOnShot;
bool g_bOnHurt;
bool g_bOnDeath;
int g_iRebelColorRed;
int g_iRebelColorGreen;
int g_iRebelColorBlue;
int g_iDefaultColorRed;
int g_iDefaultColorGreen;
int g_iDefaultColorBlue;
int g_iPointsOnRebelKill;

bool g_bRebel[MAXPLAYERS + 1];

Handle g_hOnClientRebel;
Handle g_hOnRebelDeath;

char g_sTag[64];

int g_iSRCommands;
char g_sSRCommandsList[8][32];
char g_sSRCommands[128];

bool g_bVIP = false;

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
	CreateNative("Hosties3_IsClientRebel", Rebel_IsClientRebel);
	CreateNative("Hosties3_SetClientRebel", Rebel_SetClientRebel);

	g_hOnClientRebel = CreateGlobalForward("Hosties3_OnClientRebel", ET_Ignore, Param_Cell, Param_Cell);
	g_hOnRebelDeath = CreateGlobalForward("Hosties3_OnRebelDeath", ET_Ignore, Param_Cell, Param_Cell);

	RegPluginLibrary("hosties3_rebel");

	return APLRes_Success;
}

public Hosties3_OnPluginPreLoaded()
{
	Hosties3_CheckRequirements();
}

public Hosties3_OnConfigsLoaded()
{
	if (!(g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true)))
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}

	if(LibraryExists("hosties3_vip"))
	{
		g_bVIP = true;
	}

	g_bSetColor = Hosties3_AddCvarBool(FEATURE_NAME, "Set Color", true);
	g_bShowMessage = Hosties3_AddCvarBool(FEATURE_NAME, "Show Message", true);
	g_bMessageOnDead = Hosties3_AddCvarBool(FEATURE_NAME, "Message On Dead", true);
	g_bOnShot = Hosties3_AddCvarBool(FEATURE_NAME, "Rebel On Shot", true);
	g_bOnHurt = Hosties3_AddCvarBool(FEATURE_NAME, "Rebel On Hurt", true);
	g_bOnDeath = Hosties3_AddCvarBool(FEATURE_NAME, "Rebel On Death", true);

	if(g_bVIP)
	{
		g_iPointsOnRebelKill = Hosties3_AddCvarInt(FEATURE_NAME, "Points On Rebel Kill", 1);
	}

	g_iRebelColorRed = Hosties3_AddCvarInt(FEATURE_NAME, "Rebel Color Red", 255);
	g_iRebelColorGreen = Hosties3_AddCvarInt(FEATURE_NAME, "Rebel Color Green", 0);
	g_iRebelColorBlue = Hosties3_AddCvarInt(FEATURE_NAME, "Rebel Color Blue", 0);
	g_iDefaultColorRed = Hosties3_AddCvarInt(FEATURE_NAME, "Default Color Red", 255);
	g_iDefaultColorGreen = Hosties3_AddCvarInt(FEATURE_NAME, "Default Color Green", 255);
	g_iDefaultColorBlue = Hosties3_AddCvarInt(FEATURE_NAME, "Default Color Blue", 255);
	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));
	Hosties3_AddCvarString(FEATURE_NAME, "Set Rebel Commands", "setrebel;setr", g_sSRCommands, sizeof(g_sSRCommands));

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Set Color: %d", FEATURE_NAME, g_bSetColor);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] SetRebel Commands: %s", FEATURE_NAME, g_sSRCommands);

		if(g_bVIP)
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Points On Rebel Kill: %s", FEATURE_NAME, g_iPointsOnRebelKill);
		}

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Show Message: %d", FEATURE_NAME, g_bShowMessage);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Message on Dead: %d", FEATURE_NAME, g_bMessageOnDead);

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Rebel Color Red: %d", FEATURE_NAME, g_iRebelColorRed);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Rebel Color Green: %d", FEATURE_NAME, g_iRebelColorGreen);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Rebel Color Blue: %d", FEATURE_NAME, g_iRebelColorBlue);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Default Color Red: %d", FEATURE_NAME, g_iDefaultColorRed);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Default Color Green: %d", FEATURE_NAME, g_iDefaultColorGreen);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Default Color Blue: %d", FEATURE_NAME, g_iDefaultColorBlue);

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Rebel on Shot: %d", FEATURE_NAME, g_bOnShot);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Rebel on Hurt: %d", FEATURE_NAME, g_bOnHurt);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Rebel on Death: %d", FEATURE_NAME, g_bOnDeath);
	}

	g_iSRCommands = ExplodeString(g_sSRCommands, ";", g_sSRCommandsList, sizeof(g_sSRCommandsList), sizeof(g_sSRCommandsList[]));

	for(int i = 0; i < g_iSRCommands; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sSRCommandsList[i]);
		RegAdminCmd(sBuffer, Command_SetRebel, ADMFLAG_GENERIC);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sSRCommandsList[i], sBuffer);
	}

	LoadTranslations("hosties3_rebel.phrases");

	HookEvent("bullet_impact", Event_BulletImpact);
}

public OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "hosties3_vip"))
	{
		g_bVIP = true;
	}
}

public Hosties3_OnPlayerSpawn(int client)
{
	if(Hosties3_IsClientRebel(client))
	{
		Hosties3_SetClientRebel(client, false, false);
	}
}

public Hosties3_OnRoundEnd(int winner)
{
	Hosties3_LoopClients(i)
	{
		if(Hosties3_IsClientValid(i))
		{
			if(Hosties3_IsClientRebel(i))
			{
				Hosties3_SetClientRebel(i, false, false);
			}
		}
	}
}

public Event_BulletImpact(Handle event, const char[] name, bool dontBroadcast)
{
	if (g_bOnShot)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (Hosties3_IsClientValid(client, true) && GetClientTeam(client) == CS_TEAM_T)
		{
			if (!Hosties3_IsClientRebel(client))
			{
				if (g_iLogLevel <= 2)
				{
					Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] \"%L\" has shot and is now a rebel!", FEATURE_NAME, client);
				}

				Hosties3_SetClientRebel(client, true, true);
			}
		}
	}
}

public Action Command_SetRebel(int client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "sm_setrebel <#UserID|Name>");
		return Plugin_Handled;
	}

	char sArg[65];
	GetCmdArg(1, sArg, sizeof(sArg));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(sArg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];

		if (!Hosties3_IsClientValid(target))
		{
			//Todo... add translations
			CReplyToCommand(client, "Invalid target (invalid #2)");
			return Plugin_Handled;
		}

		if(GetClientTeam(target) == CS_TEAM_T)
		{
			if (Hosties3_IsClientRebel(target))
			{
				Hosties3_SetClientRebel(target, false, true);
			}
			else
			{
				Hosties3_SetClientRebel(target, true, true);
			}
		}
	}

	return Plugin_Continue;
}

public Hosties3_OnPlayerHurt(int victim, int attacker, int damage, const char[] weapon)
{
	if (g_bOnHurt)
	{
		if (victim != attacker)
		{
			if (GetClientTeam(attacker) == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_CT)
			{
				if (!Hosties3_IsClientRebel(attacker))
				{
					if (g_iLogLevel <= 2)
					{
						Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] \"%L\" has hurt a ct and is now a rebel!", FEATURE_NAME, attacker);
					}

					Hosties3_SetClientRebel(attacker, true, true);
				}
			}
		}
	}
}

public Hosties3_OnPlayerDeath(int victim, int attacker, int assister, const char[] weapon, bool headshot)
{
	if (g_bOnDeath)
	{
		if (victim != attacker)
		{
			if (GetClientTeam(attacker) == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_CT)
			{
				if (!Hosties3_IsClientRebel(attacker))
				{
					if (g_iLogLevel <= 2)
					{
						Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] \"%L\" has killed \"%L\" and is now a rebel!", FEATURE_NAME, attacker, victim);
					}

					Hosties3_SetClientRebel(attacker, true, true);
				}
			}
		}
	}

	if (Hosties3_IsClientRebel(victim))
	{
		Hosties3_SetClientRebel(victim, false, false);

		Call_StartForward(g_hOnRebelDeath);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_Finish();

		if(g_bVIP)
		{
			if (g_iPointsOnRebelKill > 0)
			{
				Hosties3_AddVIPPoints(attacker, g_iPointsOnRebelKill);
			}
		}

		if (g_bMessageOnDead)
		{
			Hosties3_LoopClients(i)
			{
				if (Hosties3_IsClientValid(i))
				{
					CPrintToChat(i, "%T", "RebelDead", i, g_sTag, victim);
				}
			}
		}
	}
}

public Rebel_IsClientRebel(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsClientValid(client))
	{
		return g_bRebel[client];
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}
	return false;
}

public Rebel_SetClientRebel(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	bool status = GetNativeCell(2);
	bool bMessage = GetNativeCell(3);

	if (Hosties3_IsClientValid(client))
	{
		if (GetClientTeam(client) == CS_TEAM_T)
		{
			if (IsPlayerAlive(client))
			{
				if (g_bRebel[client] != status)
				{
					SetClientRebel(client, status, bMessage);
				}
			}
		}
	}
}

SetClientRebel(int client, bool status, bool bMessage)
{
	if (!status)
	{
		g_bRebel[client] = false;

		if (g_bShowMessage && bMessage)
		{
			Hosties3_LoopClients(i)
			{
				if (Hosties3_IsClientValid(i))
				{
					CPrintToChat(i, "%T", "NoRebel", i, g_sTag, client);
				}
			}
		}

		if (g_bSetColor)
		{
			SetEntityRenderColor(client, g_iDefaultColorRed, g_iDefaultColorGreen, g_iDefaultColorBlue, 255);
		}

		if (g_iLogLevel <= 3)
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, INFO, "[%s] \"%L\" is no longer a rebel!", FEATURE_NAME, client);
		}
	}
	else
	{
		g_bRebel[client] = true;

		if (g_bShowMessage && bMessage)
		{
			Hosties3_LoopClients(i)
			{
				if (Hosties3_IsClientValid(i))
				{
					CPrintToChat(i, "%T", FEATURE_NAME, i, g_sTag, client);
				}
			}
		}

		if (g_bSetColor)
		{
			SetEntityRenderColor(client, g_iRebelColorRed, g_iRebelColorGreen, g_iRebelColorBlue, 255);
		}

		if (g_iLogLevel <= 3)
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, INFO, "[%s] \"%L\" is now a rebel!", FEATURE_NAME, client);
		}
	}

	Call_StartForward(g_hOnClientRebel);
	Call_PushCell(client);
	Call_PushCell(status);
	Call_Finish();
}
