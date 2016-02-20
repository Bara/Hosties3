#if defined _hosties3_lr_included
  #endinput
#endif
#define _hosties3_lr_included

native bool Hosties3_RegisterLRGame(const char[] name, const char[] translations);
native bool Hosties3_IsClientInLastRequest(int client);

stock bool Hosties3_IsLRLoaded()
{
	if (!LibraryExists("hosties3_lr"))
	{
		return SetFailState("'Last Request'-Plugin not found!");
	}
}

public SharedPlugin __pl_hosties3_lr = 
{
	file = "lr.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN

public __pl_hosties3_lr_SetNTVOptional()
{
	MarkNativeAsOptional("Hosties3_RegisterLRGame");
}
#endif
