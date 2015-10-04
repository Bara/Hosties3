#if defined _hosties3_rebel_included
  #endinput
#endif
#define _hosties3_rebel_included

forward void Hosties3_OnClientRebel(int client, bool status);
forward void Hosties3_OnRebelDeath(int victim, int attacker);

native bool Hosties3_IsClientRebel(int client);
native void Hosties3_SetClientRebel(int client, bool status, bool bMessage);

stock bool Hosties3_IsRebelLoaded()
{
	if (!LibraryExists("hosties3_rebel"))
	{
		SetFailState("'Rebel' Feature not found!");
		return false;
	}
	
	return true;
}

methodmap HRebel < HPlayer
{
	public HRebel(int client)
	{
		return view_as<HRebel>(new HPlayer(client));
	}
}

public SharedPlugin __pl_hosties3_rebel =
{
	file = "rebel.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN

public __pl_hosties3_rebel_SetNTVOptional()
{
	MarkNativeAsOptional("Hosties3_IsClientRebel");
	MarkNativeAsOptional("Hosties3_SetClientRebel");
}
#endif
