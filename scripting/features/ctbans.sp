#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <hosties3>
#include <hosties3_ctbans>

#define FEATURE_NAME "CT Bans"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
bool g_bReady;

bool g_bIsClientReady[MAXPLAYERS + 1] = {false, ...};
bool g_bBan[MAXPLAYERS + 1] = {false, ...};

float g_fStartPluginTime;
float g_fBanCheck;

int g_iLogLevel;

int g_iLength[MAXPLAYERS + 1] = {0, ...};
int g_iTimeleft[MAXPLAYERS + 1] = {0, ...};
char g_sReason[MAXPLAYERS + 1][256];

char g_sTag[64];

char g_sClientID[MAXPLAYERS + 1][128];

Handle g_hDatabase;

Handle g_hCheckTimer[MAXPLAYERS + 1] = {null, ...};
Handle g_hBanCheck[MAXPLAYERS + 1] = {null, ...};

int g_iBansCom;
char g_sBansComList[8][32];
char g_sBansCom[128];

int g_iSetBansCom;
char g_sSetBansComList[8][32];
char g_sSetBansCom[128];

int g_iDelBansCom;
char g_sDelBansComList[8][32];
char g_sDelBansCom[128];

int g_iDefaulLength;

Handle g_hOnCTBan;
Handle g_hOnCTBanExpired;

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
	CreateNative("Hosties3_HasClientCTBan", CTBans_HasClientCTBan);
	CreateNative("Hosties3_SetClientCTBan", CTBans_SetClientCTBan);
	CreateNative("Hosties3_DelClientCTBan", CTBans_DelClientCTBan);

	g_hOnCTBan = CreateGlobalForward("Hosties3_OnClientCTBan", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
	g_hOnCTBanExpired = CreateGlobalForward("Hosties3_OnClientCTBanExpired", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_String);

	RegPluginLibrary("hosties3_ctbans");

	return APLRes_Success;
}

public CTBans_HasClientCTBan(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsClientValid(client))
	{
		if (g_bBan[client])
		{
			return true;
		}
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}

	return false;
}

public CTBans_SetClientCTBan(Handle plugin, numParams)
{
	char reason[256];

	int admin = GetNativeCell(1);
	int client = GetNativeCell(2);
	int length = GetNativeCell(3);
	int timeleft = GetNativeCell(4);
	GetNativeString(5, reason, sizeof(reason));

	if(StrEqual(reason, "", false))
	{
		Format(reason, sizeof(reason), "%T", "NoReason", admin);
	}

	if (Hosties3_IsClientValid(client))
	{
		if (!Hosties3_HasClientCTBan(client))
		{
			return SetCTBan(admin, client, length, timeleft, reason);
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "%T", "IsAlreadyBanned", admin);
		}
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%T", "Invalid", admin);
	}

	return false;
}

public CTBans_DelClientCTBan(Handle plugin, numParams)
{
	int admin = GetNativeCell(1);
	int client = GetNativeCell(2);

	if (Hosties3_IsClientValid(client))
	{
		if (Hosties3_HasClientCTBan(client))
		{
			return DelCTBan(admin, client);
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "%T", "IsntBanned", admin);
		}
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "%T", "Invalid", admin);
	}

	return false;
}

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

	g_iDefaulLength = Hosties3_AddCvarInt(FEATURE_NAME, "Default Ban Time", 30);

	g_fStartPluginTime = Hosties3_AddCvarFloat(FEATURE_NAME, "Start Plugin Time", 20.0);
	g_fBanCheck = Hosties3_AddCvarFloat(FEATURE_NAME, "CT Ban Check", 60.0);

	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	Hosties3_AddCvarString(FEATURE_NAME, "Commands", "ctbans", g_sBansCom, sizeof(g_sBansCom));
	Hosties3_AddCvarString(FEATURE_NAME, "Set Commands", "ctban", g_sSetBansCom, sizeof(g_sSetBansCom));
	Hosties3_AddCvarString(FEATURE_NAME, "Del Commands", "ctunban", g_sDelBansCom, sizeof(g_sDelBansCom));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] DefaultBanLength : %d", FEATURE_NAME, g_iDefaulLength);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] BanCheck : %.0f", FEATURE_NAME, g_fBanCheck);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] StartPluginTime: %.0f", FEATURE_NAME, g_fStartPluginTime);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] CTBansCommands: %s", FEATURE_NAME, g_sBansCom);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] CTBanCommands: %s", FEATURE_NAME, g_sSetBansCom);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] CTUnbanCommands: %s", FEATURE_NAME, g_sDelBansCom);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	g_iBansCom = ExplodeString(g_sBansCom, ";", g_sBansComList, sizeof(g_sBansComList), sizeof(g_sBansComList[]));
	for(int i = 0; i < g_iBansCom; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sBansComList[i]);
		RegConsoleCmd(sBuffer, Command_Bans);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sBansComList[i], sBuffer);
	}

	g_iSetBansCom = ExplodeString(g_sSetBansCom, ";", g_sSetBansComList, sizeof(g_sSetBansComList), sizeof(g_sSetBansComList[]));
	for(int i = 0; i < g_iSetBansCom; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sSetBansComList[i]);
		RegAdminCmd(sBuffer, Command_SetBans, ADMFLAG_GENERIC);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sSetBansComList[i], sBuffer);
	}

	g_iDelBansCom = ExplodeString(g_sDelBansCom, ";", g_sDelBansComList, sizeof(g_sDelBansComList), sizeof(g_sDelBansComList[]));
	for(int i = 0; i < g_iDelBansCom; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sDelBansComList[i]);
		RegAdminCmd(sBuffer, Command_DelBans, ADMFLAG_GENERIC);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sDelBansComList[i], sBuffer);
	}

	if (g_fStartPluginTime > 0.0)
	{
		CreateTimer(g_fStartPluginTime, Timer_StartPlugin);
	}

	AddCommandListener(Command_JoinTeam, "jointeam");

	LoadTranslations("common.phrases");
	LoadTranslations("hosties3_ctbans.phrases");
}

public Action Timer_StartPlugin(Handle timer)
{
	g_bReady = true;

	Hosties3_LoopClients(i)
	{
		if (Hosties3_IsClientValid(i))
		{
			g_hCheckTimer[i] = CreateTimer(1.0, Timer_CheckClients, GetClientUserId(i), TIMER_REPEAT);
		}
	}
}

public Action Timer_CheckClients(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if (g_bReady && Hosties3_IsClientValid(client) && g_bIsClientReady[client])
	{
		if (GetClientTeam(client) == CS_TEAM_CT)
		{
			if (Hosties3_HasClientCTBan(client))
			{
				Hosties3_PrintToChat(client, "%T", "CTBanned", client, g_sTag, g_iTimeleft[client]);
				Hosties3_SwitchClient(client, CS_TEAM_T);
			}
		}
	}
	else
	{
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Hosties3_OnSQLConnected(Handle database)
{
	if (Hosties3_IsSQLValid(database))
	{
		g_hDatabase = CloneHandle(database);

		CheckTables();
	}
}

public Hosties3_OnPlayerReady(int client)
{
	char sQuery[2048];
	Hosties3_GetClientID(client, g_sClientID[client], sizeof(g_sClientID[]));
	Format(sQuery, sizeof(sQuery), "SELECT length, timeleft, reason FROM hosties3_ctbans WHERE id = '%s'", g_sClientID[client]);
	SQL_TQuery(g_hDatabase, SQL_ClientConnect, sQuery, GetClientUserId(client));
}

public SQL_ClientConnect(Handle owner, Handle hndl, const char[] error, any userid)
{
	if (hndl != null)
	{
		int client = GetClientOfUserId(userid);

		if (Hosties3_IsClientValid(client) && !IsFakeClient(client))
		{
			if (SQL_FetchRow(hndl))
			{
				g_iLength[client] = SQL_FetchInt(hndl, 0);
				g_iTimeleft[client] = SQL_FetchInt(hndl, 1);
				SQL_FetchString(hndl, 2, g_sReason[client], sizeof(g_sReason[]));

				if (g_iLength[client] == 0)
				{
					g_bBan[client] = true;
					g_iLength[client] = 0;
					g_iTimeleft[client] = -1;
					g_bIsClientReady[client] = true;
					return;
				}
				else if (g_iTimeleft[client] > 0)
				{
					Hosties3_SafeCloseHandle(g_hBanCheck[client]);

					if (g_hBanCheck[client] == null)
					{
						CreateTimer(g_fBanCheck, Timer_BanCheck, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}

					g_bBan[client] = true;
					g_bIsClientReady[client] = true;
					return;
				}

				if (GetClientTeam(client) == CS_TEAM_CT && Hosties3_HasClientCTBan(client))
				{
					Hosties3_SwitchClient(client, CS_TEAM_T);
				}
			}
			g_bIsClientReady[client] = true;
		}
	}
}

public Hosties3_OnPlayerSpawn(int client)
{
	if (!g_bReady || !g_bIsClientReady[client])
	{
		return;
	}

	if (GetClientTeam(client) == CS_TEAM_CT)
	{
		if (Hosties3_HasClientCTBan(client))
		{
			Hosties3_PrintToChat(client, "%T", "CTBanned", client, g_sTag, g_iTimeleft[client]);
			Hosties3_SwitchClient(client, CS_TEAM_T);
		}
	}
}

public Hosties3_OnPlayerDisconnect(int client)
{
	Hosties3_SafeCloseHandle(g_hCheckTimer[client]);
}

public Action Command_JoinTeam(int client, const char[] command, args)
{
	if (!g_bReady || !Hosties3_IsClientValid(client) || !g_bIsClientReady[client])
	{
		return Plugin_Continue;
	}

	char sTeam[3];
	GetCmdArg(1, sTeam, sizeof(sTeam));
	int iTeam = StringToInt(sTeam);

	if (iTeam == CS_TEAM_CT)
	{
		if (Hosties3_HasClientCTBan(client))
		{
			Hosties3_PrintToChat(client, "%T", "CTBanned", client, g_sTag, g_iTimeleft[client]);
			Hosties3_SwitchClient(client, CS_TEAM_T);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action Command_Bans(client, args)
{
	if (Hosties3_IsClientValid(client))
	{
		Menu menu = CreateMenu(Menu_Block);
		char sTitle[256];
		Format(sTitle, sizeof(sTitle), "%T", "CTBansList", client);
		menu.SetTitle(sTitle);

		int count = 0;

		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				if (Hosties3_HasClientCTBan(i))
				{
					char sUserID[64];
					IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));

					char sName[MAX_NAME_LENGTH];
					Format(sName, sizeof(sName), "%N (%d/%d)", i, g_iTimeleft[i], g_iLength[i]);
					menu.AddItem(sUserID, sName);

					count++;
				}
			}
		}

		if(count == 0)
		{
			char sBuffer[64];
			Format(sBuffer, sizeof(sBuffer), "%T", "NoPlayers", client);
			menu.AddItem("", sBuffer, ITEMDRAW_DISABLED);
		}

		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public Menu_Block(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		if (Hosties3_IsClientValid(client))
		{
			char sUserID[64];
			menu.GetItem(param, sUserID, sizeof(sUserID));
			int userid = StringToInt(sUserID);
			int target = GetClientOfUserId(userid);

			if (Hosties3_IsClientValid(target))
			{
				Hosties3_PrintToChat(client, "%T", "CTBansInfo", client, g_sTag, target, g_iLength[target], g_iTimeleft[target], g_sReason[target]);
			}
		}

		Command_Bans(client, 0);
		delete menu;
	}
}

public Action Command_SetBans(int client, int args)
{
	if (args != 3)
	{
		Hosties3_ReplyToCommand(client, "%T", "CTBanSyntax", client, g_sTag);
		return Plugin_Handled;
	}

	char sArg1[MAX_NAME_LENGTH];
	char sArg2[12];
	char sArg3[256];

	GetCmdArg(1, sArg1, sizeof(sArg1));
	GetCmdArg(2, sArg2, sizeof(sArg2));
	GetCmdArg(3, sArg3, sizeof(sArg3));

	int iLength = StringToInt(sArg2);

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(sArg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];

		if (!Hosties3_IsClientValid(target))
		{
			Hosties3_ReplyToCommand(client, "%T", "Invalid", client);
			return Plugin_Handled;
		}

		if (!Hosties3_HasClientCTBan(client))
		{
			Hosties3_SetClientCTBan(client, target, iLength, iLength, sArg3);
		}
		else
		{
			Hosties3_ReplyToCommand(client, "%T", "IsAlreadyBanned", client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Command_DelBans(client, args)
{
	if (args != 1)
	{
		Hosties3_ReplyToCommand(client, "%T", "CTUnBanSyntax", client, g_sTag);
		return Plugin_Handled;
	}

	char sArg1[MAX_NAME_LENGTH];
	GetCmdArg(1, sArg1, sizeof(sArg1));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(sArg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];

		if (!Hosties3_IsClientValid(target))
		{
			Hosties3_ReplyToCommand(client, "%T", "Invalid", client);
			return Plugin_Handled;
		}

		if (Hosties3_HasClientCTBan(client))
		{
			Hosties3_DelClientCTBan(client, target);
		}
		else
		{
			Hosties3_ReplyToCommand(client, "%T", "IsntBanned", client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

SetCTBan(int admin, int client, int length, int timeleft, const char[] reason)
{
	g_iLength[client] = length;
	g_iTimeleft[client] = timeleft;
	g_bBan[client] = true;
	strcopy(g_sReason[client], sizeof(g_sReason[]), reason);

	char sQuery[1024];
	Format(sQuery, sizeof(sQuery), "INSERT INTO `hosties3_ctbans` (`id`, `date`, `length`, `timeleft`, `reason`, `adminid`) VALUES ('%s', UNIX_TIMESTAMP(), '%d', '%d', '%s', '%s')", g_sClientID[client], length, timeleft, reason, g_sClientID[admin]);
	SQLQuery(sQuery);

	char sAdmin[MAX_NAME_LENGTH];
	if (admin < 1)
	{
		Format(sAdmin, sizeof(sAdmin), "Console");
	}
	else
	{
		GetClientName(admin, sAdmin, sizeof(sAdmin));
	}

	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		Hosties3_SwitchClient(client, CS_TEAM_T);
	}

	Hosties3_LoopClients(i)
	{
		if (Hosties3_IsClientValid(i))
		{
			Hosties3_PrintToChat(i, "%T", "OnCTBan", i, g_sTag, client, sAdmin, length, reason);
		}
	}

	Hosties3_SafeCloseHandle(g_hBanCheck[client]);

	if (g_hBanCheck[client] == null)
	{
		CreateTimer(g_fBanCheck, Timer_BanCheck, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	Call_StartForward(g_hOnCTBan);
	Call_PushCell(admin);
	Call_PushCell(client);
	Call_PushCell(length);
	Call_PushCell(timeleft);
	Call_PushString(reason);
	Call_Finish();

	return true;
}

DelCTBan(int admin, int client)
{
	char reason[256];
	strcopy(reason, sizeof(reason), g_sReason[client]);

	int length = g_iLength[client];

	g_iLength[client] = 0;
	g_iTimeleft[client] = 0;
	g_bBan[client] = false;
	Format(g_sReason[client], sizeof(g_sReason[]), "");

	char sAdmin[MAX_NAME_LENGTH];
	if (admin < 1)
	{
		Format(sAdmin, sizeof(sAdmin), "Console");
		Format(g_sClientID[admin], sizeof(g_sClientID[]), "0");
	}
	else
	{
		GetClientName(admin, sAdmin, sizeof(sAdmin));
	}

	char sQuery[1024];
	Format(sQuery, sizeof(sQuery), "UPDATE `hosties3_ctbans` SET `timeleft` = '0', `uadminid` = '%s' WHERE `id`='%s'", g_sClientID[admin], g_sClientID[client]);
	SQLQuery(sQuery);

	Hosties3_LoopClients(i)
	{
		if (Hosties3_IsClientValid(i))
		{
			Hosties3_PrintToChat(i, "%T", "OnCTUnBan", i, g_sTag, client, sAdmin, length, reason);
		}
	}

	Hosties3_SafeCloseHandle(g_hBanCheck[client]);

	Call_StartForward(g_hOnCTBanExpired);
	Call_PushCell(admin);
	Call_PushCell(client);
	Call_PushCell(length);
	Call_PushString(reason);
	Call_Finish();

	return true;
}

public Action Timer_BanCheck(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if (Hosties3_IsClientValid(client) && GetClientTeam(client) == CS_TEAM_T)
	{
		if (g_iTimeleft[client] == 0)
		{
			Hosties3_DelClientCTBan(0, client);
		}
		else if (g_iTimeleft[client] > 0)
		{
			g_iTimeleft[client]--;

			char sQuery[1024];
			Format(sQuery, sizeof(sQuery), "UPDATE `hosties3_ctbans` SET `timeleft` = '%d' WHERE `id`='%s'",g_iTimeleft[client], g_sClientID[client]);
			SQLQuery(sQuery);

			return Plugin_Continue;
		}
	}
	g_hBanCheck[client] = null;
	return Plugin_Stop;
}

CheckTables()
{
	char sQuery[] = "\
		CREATE TABLE IF NOT EXISTS `hosties3_ctbans` ( \
		  `id` varchar(128) NOT NULL, \
		  `date` int(10) NOT NULL, \
		  `length` int(32) NOT NULL, \
		  `timeleft` int(32) NOT NULL, \
		  `reason` varchar(128) NOT NULL, \
		  `adminid` varchar(128) NOT NULL , \
		  `uadminid` varchar(128) NOT NULL, \
		  PRIMARY KEY (`id`) \
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;";

	SQLQuery(sQuery);
}

SQLQuery(char[] sQuery)
{
	Handle hPack = CreateDataPack();
	WritePackString(hPack, sQuery);
	SQL_TQuery(g_hDatabase, SQL_Callback, sQuery, hPack);
}

public SQL_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (error[0])
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, ERROR, "Query failed: %s", error);
		return false;
	}
	return true;
}
