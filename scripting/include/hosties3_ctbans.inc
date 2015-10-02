#if defined _hosties3_ctbans_included
  #endinput
#endif
#define _hosties3_ctbans_included

forward void Hosties3_OnClientCTBan(int admin, int client, int length, int timeleft, const char[] reason);
forward void Hosties3_OnClientCTBanExpired(int admin, int client, int length, const char[] reason);

native bool Hosties3_HasClientCTBan(int client);
native bool Hosties3_SetClientCTBan(int admin, int client, int length, int timeleft, const char[] reason);
native bool Hosties3_DelClientCTBan(int admin, int client);

stock Hosties3_IsCTBansLoaded()
{
	if (!LibraryExists("hosties3_ctbans"))
	{
		SetFailState("'CTBans'-Feature not found!");
	}
}

public SharedPlugin __pl_hosties3_ctbans =
{
	file = "ctbans.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN

public __pl_hosties3_ctbans_SetNTVOptional()
{
	MarkNativeAsOptiomal("Hosties3_HasClientCTBan");
	MarkNativeAsOptiomal("Hosties3_SetClientCTBan");
	MarkNativeAsOptiomal("Hosties3_DelClientCTBan");
}
#endif
