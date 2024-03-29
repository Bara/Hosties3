/*

	ToDo:
		- Add "3..2..1..GO!"-sounds
			- <GAME> started in 3/1 second/s

*/

#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

#include <emitsoundany>

#pragma newdecls required

#include <hosties3>
#include <lastrequest>

#define FEATURE_NAME "Last Request"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bLastRequest = false;
bool g_bLastRequestRound = false;
bool g_bInLR[MAXPLAYERS + 1] =  { false, ... };

bool g_bEnable;
int g_iLogLevel;

bool g_bPlaySound;
bool g_bAutoOpenMenu;
char g_sLRSoundsFile[PLATFORM_MAX_PATH + 1];
int g_iLRSoundsCount;

int g_iLRMenuTime;

Handle g_hOnLRChoosen;
Handle g_hOnLRAvailable;
Handle g_hOnLREnd;

char g_sLRGame[MAXPLAYERS + 1][128];
int g_iLRTarget[MAXPLAYERS + 1] =  { 0, ... };

char g_sSoundsPath[PLATFORM_MAX_PATH + 1];

enum lrCache
{
	lrId,
	String:lrName[HOSTIES3_MAX_FEATURE_NAME],
	String:lrTranslation[HOSTIES3_MAX_FEATURE_NAME]
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
	CreateNative("Hosties3_IsLastRequestAvailable", Native_IsLastRequestAvailable);
	CreateNative("Hosties3_IsClientInLastRequest", Native_IsClientInLastRequest);
	CreateNative("Hosties3_SetLastRequestStatus", Native_SetLastRequestStatus);
	CreateNative("Hosties3_StopLastRequest", Native_StopLastRequest);
	
	g_hOnLRChoosen = CreateGlobalForward("Hosties3_OnLastRequestChoosen", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	g_hOnLRAvailable = CreateGlobalForward("Hosties3_OnLastRequestAvailable", ET_Ignore, Param_Cell);
	g_hOnLREnd = CreateGlobalForward("Hosties3_OnLastRequestEnd", ET_Ignore, Param_Cell, Param_Cell);
	
	RegPluginLibrary("hosties3-lr");
	
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	Hosties3_CheckRequirements();
	
	if(g_aLRGames != null)
	{
		g_aLRGames.Clear();
	}
	
	g_aLRGames = new ArrayList(sizeof(g_iLRGames));
	
	HookEvent("round_prestart", Event_RoundPreStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public void Hosties3_OnConfigsLoaded()
{
	if (!(g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true)))
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}
	
	g_iLogLevel = Hosties3_GetLogLevel();
	g_iLRMenuTime = Hosties3_AddCvarInt(FEATURE_NAME, "Last Request Menu Time", 30);
	
	g_bPlaySound = Hosties3_AddCvarBool(FEATURE_NAME, "Play sound on lr available", true);
	g_bAutoOpenMenu = Hosties3_AddCvarBool(FEATURE_NAME, "Auto open menu on lr available", true);
	g_iLRSoundsCount = Hosties3_AddCvarInt(FEATURE_NAME, "Count of last request sounds", 1);
	Hosties3_AddCvarString(FEATURE_NAME, "Base path+filename (x is replaced with count)", "server/hosties3/lastrequest/lastrequestX.mp3", g_sLRSoundsFile, sizeof(g_sLRSoundsFile));
	Hosties3_AddCvarString(FEATURE_NAME, "Sounds for 3...2...1...Go ( Go = 0 )", "server/hosties3/lastrequest/X.mp3", g_sSoundsPath, sizeof(g_sSoundsPath));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
	}
	
	char sLRCommands[128];
	Hosties3_AddCvarString(FEATURE_NAME, "Lastrequest Commands", "lr;lastrequest", sLRCommands, sizeof(sLRCommands));
	int iLRCommands;
	char sLRCommandsList[8][32];
	iLRCommands = ExplodeString(sLRCommands, ";", sLRCommandsList, sizeof(sLRCommandsList), sizeof(sLRCommandsList[]));
	
	
	for(int i = 0; i < iLRCommands; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", sLRCommandsList[i]);
		RegConsoleCmd(sBuffer, Command_LastRequest);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, sLRCommandsList[i], sBuffer);
	}
	
	char sLRSCommands[128];
	Hosties3_AddCvarString(FEATURE_NAME, "Lastrequest List Commands", "lrs;lastrequests", sLRSCommands, sizeof(sLRSCommands));
	int iLRSCommands;
	char sLRSCommandsList[8][32];
	iLRSCommands = ExplodeString(sLRSCommands, ";", sLRSCommandsList, sizeof(sLRSCommandsList), sizeof(sLRSCommandsList[]));
	
	for(int i = 0; i < iLRSCommands; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", sLRSCommandsList[i]);
		RegConsoleCmd(sBuffer, Command_LastRequestList);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, sLRSCommandsList[i], sBuffer);
	}
	
	RegAdminCmd("sm_lrdebug", LRDebug, ADMFLAG_ROOT);
	
	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
	
	CreateTimer(3.0, Timer_CheckTeams, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}


public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(Hosties3_IsClientValid(client) && Hosties3_IsClientInLastRequest(client))
	{
		Hosties3_StopLastRequest();
		return;
	}
	
	CheckTeams();
	return;
}

public Action Timer_CheckTeams(Handle timer)
{
	if(!Hosties3_IsLastRequestAvailable())
	{
		CheckTeams();
	}
	else
	{
		int T = 0;
		int CT = 0;
		Hosties3_LoopClients(i)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(GetClientTeam(i) == CS_TEAM_T)
				{
					T++;
				}
				else if(GetClientTeam(i) == CS_TEAM_CT)
				{
					CT++;
				}
			}
		}
		
		if(T == 0 || CT == 0)
		{
			Hosties3_StopLastRequest();
		}
	}
}

void CheckTeams()
{
	int iCount = 0;
	int lastT[65];
	
	Hosties3_LoopClients(i)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
		{
			iCount++;
			lastT[iCount] = i;
		}
	}
	
	if(iCount == 1)
	{
		int client = lastT[1];
		g_bLastRequest = true;
		
		if(g_bPlaySound)
		{
			PlayLastRequestSound();
		}
		
		if(g_bAutoOpenMenu)
		{
			ShowLastRequestMenu(client);
		}
		
		Call_StartForward(g_hOnLRAvailable);
		Call_PushCell(client);
		Call_Finish();
	}
}

void PlayLastRequestSound()
{
	char sFile[PLATFORM_MAX_PATH + 1], sid[2];
	strcopy(sFile, sizeof(sFile), g_sLRSoundsFile);
	
	int id;
	if(g_iLRSoundsCount > 1)
	{
		id = GetRandomInt(1, g_iLRSoundsCount);
	}
	else
	{
		id = 1;
	}
	
	IntToString(id, sid, sizeof(sid));
	ReplaceString(sFile, sizeof(sFile), "X", sid, true);
	EmitSoundToAllAny(sFile);
}

public Action Event_RoundPreStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bLastRequest = false;
	g_bLastRequestRound = true;
}

public Action LRDebug(int client, int args)
{
	for (int i = 0; i < g_aLRGames.Length; i++)
	{
		int iGang[lrCache];
		g_aLRGames.GetArray(i, iGang[0]);

		PrintToServer("[LastRequest]: %s", iGang[lrName]);
	}
	
	CreateCountdown(3, client);
	
	if(Hosties3_IsClientInLastRequest(client))
	{
		PrintToChat(client, "You're in a last request!");
	}
}


public Action Command_LastRequestList(int client, int args)
{
	if(!Hosties3_IsClientValid(client)) // TODO: Add message
	{
		return Plugin_Handled;
	}
	
	ShowLastRequestList(client);
	
	return Plugin_Continue;
}


public Action Command_LastRequest(int client, int args)
{
	if(!Hosties3_IsClientValid(client))
	{
		return Plugin_Handled;
	}
	
	if(GetClientTeam(client) != CS_TEAM_T) // TODO: Add message
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client, "Hosties3_IsLastRequestAvailable: %d, Hosties3_IsClientInLastRequest: %d", Hosties3_IsLastRequestAvailable(), Hosties3_IsClientInLastRequest(client));
	
	if(Hosties3_IsLastRequestAvailable()) // TODO: Add message
	{
		return Plugin_Handled;
	}
	
	if(Hosties3_IsClientInLastRequest(client)) // TODO: Add message
	{
		return Plugin_Handled;
	}
		
	ShowLastRequestMenu(client);
	
	return Plugin_Continue;
}

void ShowLastRequestList(int client)
{
	Menu menu = new Menu(Menu_Empty); // TODO: As panel
	menu.SetTitle("Last requests:"); // TODO: Add translation
	
	for (int i = 0; i < g_aLRGames.Length; i++)
	{
		int iGang[lrCache];
		g_aLRGames.GetArray(i, iGang[0]);

		menu.AddItem(iGang[lrTranslation], iGang[lrTranslation], ITEMDRAW_DISABLED); // TODO: Add translation
	}
	
	menu.ExitButton = true;
	menu.Display(client, g_iLRMenuTime);
}

void ShowLastRequestMenu(int client)
{
	Menu menu = new Menu(Menu_LastRequest);
	menu.SetTitle("Choose a last request:"); // TODO: Add translation
	
	for (int i = 0; i < g_aLRGames.Length; i++)
	{
		int iGang[lrCache];
		g_aLRGames.GetArray(i, iGang[0]);

		menu.AddItem(iGang[lrTranslation], iGang[lrTranslation]); // TODO: Add translation
	}
	
	menu.ExitButton = true;
	menu.Display(client, g_iLRMenuTime);
}


public int Menu_LastRequest(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char sParam[32];
		GetMenuItem(menu, param, sParam, sizeof(sParam));
		
		PrintToChat(client, "LR: %s", sParam);
		strcopy(g_sLRGame[client], sizeof(g_sLRGame[]), sParam);
		
		Menu tMenu = new Menu(Menu_TMenu);
		tMenu.SetTitle("Choose your opponent:");
		
		Hosties3_LoopClients(i)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && IsPlayerAlive(i) && !Hosties3_IsClientInLastRequest(i))
			{
				char sIndex[12], sName[MAX_NAME_LENGTH];
				IntToString(i, sIndex, sizeof(sIndex));
				GetClientName(i, sName, sizeof(sName));
				tMenu.AddItem(sIndex, sName);
			}
		}
		
		tMenu.ExitButton = true;
		tMenu.Display(client, g_iLRMenuTime);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Timeout)
		{
			PrintToChatAll("MenuCancel_Timeout %N", client); // TODO: Add translation & function (Nothing or slay?)
		}
	}		
	else if (action == MenuAction_End)
	{
		if(menu != null)
		{
			delete menu;
		}
	}
	return 0;
}

public int Menu_TMenu(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char sParam[32];
		GetMenuItem(menu, param, sParam, sizeof(sParam));
		
		int target = StringToInt(sParam);
		g_iLRTarget[client] = target;
		
		PrintToChat(client, "LR: %s - Opponent: %N", g_sLRGame[client], target);
		
		CreateCountdown(3, client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Timeout)
		{
			PrintToChatAll("MenuCancel_Timeout %N", client); // TODO: Add translation & function (Nothing or slay?)
		}
	}		
	else if (action == MenuAction_End)
	{
		if(menu != null)
		{
			delete menu;
		}
	}
	return 0;
}

public int Menu_Empty(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		if(menu != null)
		{
			delete menu;
		}
	}
	return 0;
}

public int Native_RegisterLRGame(Handle plugin, int numParams)
{
	char name[HOSTIES3_MAX_FEATURE_NAME];
	char translations[HOSTIES3_MAX_FEATURE_NAME];
	
	GetNativeString(1, name, sizeof(name));
	GetNativeString(2, translations, sizeof(translations));
	
	CheckExistsLRGames(name);
	
	int iCache[lrCache];
	
	iCache[lrId] = g_aLRGames.Length + 1;
	strcopy(iCache[lrName], sizeof(name), name);
	strcopy(iCache[lrTranslation], sizeof(translations), translations);

	Hosties3_LogToFile(HOSTIES3_PATH, "LRGames", DEBUG, "[LRGames] ID: %d - Name: %s - Translations: %s", iCache[lrId], iCache[lrName], iCache[lrTranslation]);

	g_aLRGames.PushArray(iCache[0]);
	
	CheckExistsLRGames(name);
	
	return false;
}

public int Native_IsClientInLastRequest(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return g_bInLR[client];
}

public int Native_SetLastRequestStatus(Handle plugin, int numParams)
{
	g_bLastRequestRound = GetNativeCell(1);
	return g_bLastRequestRound;
}

public int Native_StopLastRequest(Handle plugin, int numParams)
{
	Hosties3_LoopClients(i)
	{
		if(Hosties3_IsClientValid(i))
		{
			if(GetClientTeam(i) == CS_TEAM_T && g_iLRTarget[i] > 0)
			{
				Call_StartForward(g_hOnLREnd);
				Call_PushCell(i);
				Call_PushCell(g_iLRTarget[i]);
				Call_Finish();
			}
		}
	}
	
	Hosties3_LoopClients(i)
	{
		if(Hosties3_IsClientValid(i))
		{
			if(g_bInLR[i])
			{
				g_bInLR[i] = false;
			}
			
			if(GetClientTeam(i) == CS_TEAM_T && g_iLRTarget[i] > 0)
			{
				Hosties3_LoopClients(j)
				{
					if(Hosties3_IsClientValid(j))
					{
						PrintToChat(j, "Last request was ended ( Game: %s, Player: %N, Opponent: %N )", g_sLRGame[i], i, g_iLRTarget[i]); // TODO: Add translation
					}
				}
				g_iLRTarget[i] = 0;
				g_sLRGame[i] = "";
			}
		}
	}
	
	g_bLastRequest = true;
}

public int Native_IsLastRequestAvailable(Handle plugin, int numParams)
{
	return g_bLastRequest;
}

bool CheckExistsLRGames(const char[] name)
{
	for (int i = 0; i < g_aLRGames.Length; i++)
	{
		int iGang[lrCache];
		g_aLRGames.GetArray(i, iGang[0]);

		if(StrEqual(iGang[lrName], name, false))
		{
			return true;
		}
	}
	return false;
}


stock void CreateCountdown(int seconds, int client)
{
	Handle pack = CreateDataPack();
	WritePackCell(pack, seconds);
	WritePackCell(pack, GetClientUserId(client));
	CreateTimer(0.0, Timer_Countdown, pack);
}

public Action Timer_Countdown(Handle timer, any pack)
{
	ResetPack(pack, false);
	int seconds = ReadPackCell(pack);
	int client = GetClientOfUserId(ReadPackCell(pack));
	CloseHandle(pack);
	
	if(Hosties3_IsClientValid(client) && Hosties3_IsClientValid(g_iLRTarget[client]))
	{
		Hosties3_LoopClients(i)
		{
			if(Hosties3_IsClientValid(i))
			{
				if(seconds == 1)
				{
					PrintToChat(i, "Last request started in %d second ( Game: %s, Player: %N, Opponent: %N)", seconds, g_sLRGame[client], i, g_iLRTarget[client]); // TODO: Add translation
				}
				else if(seconds == 0)
				{
					PrintToChat(i, "Go! ( Game: %s, Player: %N, Opponent: %N)", g_sLRGame[client], i, g_iLRTarget[client]); // TODO: Add translation
					StartLastRequest(client);
				}
				else
				{
					PrintToChat(i, "Last request started in %d seconds ( Game: %s, Player: %N, Opponent: %N)", seconds, g_sLRGame[client], i, g_iLRTarget[client]); // TODO: Add translation
				}
				
				PlaySound(seconds);
			}
		}
	}
	
	seconds--;

	if(seconds >= 0)
	{
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, seconds);
		WritePackCell(hPack, GetClientUserId(client));
		CreateTimer(1.0, Timer_Countdown, hPack);
	}

	return Plugin_Stop;
}

void PlaySound(int seconds)
{
	if(seconds >= 0 && seconds <= 3)
	{
		char sFile[PLATFORM_MAX_PATH + 1], sid[2];
		strcopy(sFile, sizeof(sFile), g_sLRSoundsFile);
		IntToString(seconds, sid, sizeof(sid));
		ReplaceString(sFile, sizeof(sFile), "X", sid, true);
		EmitSoundToAllAny(sFile);
	}
}

void StartLastRequest(int client)
{
	if(!Hosties3_IsClientValid(client) || !Hosties3_IsClientValid(g_iLRTarget[client]))
	{
		Hosties3_LoopClients(i)
		{
			if(Hosties3_IsClientValid(i))
			{
				PrintToChat(i, "Last request aborted! Client invalid"); // TODO: Add translation
			}
		}
	}
	
	g_bLastRequest = false;
	g_bInLR[g_iLRTarget[client]] = true;
	
	Call_StartForward(g_hOnLRChoosen);
	Call_PushCell(client);
	Call_PushCell(g_iLRTarget[client]);
	for (int i = 0; i < g_aLRGames.Length; i++)
	{
		int iGang[lrCache];
		g_aLRGames.GetArray(i, iGang[0]);

		if(StrEqual(iGang[lrTranslation], g_sLRGame[client], false))
		{
			Call_PushString(iGang[lrName]);
		}
	}
	Call_Finish();
}
