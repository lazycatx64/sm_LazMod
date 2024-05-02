


#include <sourcemod>
#include <sdktools>
#include <lazmod>


public Plugin myinfo =
{
	name		= "LazMod - Movement",
	author		= "LaZycAt, hjkwe654",
	description = "Noclip, sprint, teleport, etc.",
	version		= LAZMOD_VER,
	url			= ""
}

public OnPluginStart()
{
	// Player commands
	{
		RegAdminCmd("+sprint", Command_EnableSprint, 0, "Sprint with x3 speed!")
		RegAdminCmd("-sprint", Command_DisableSprint, 0, "Stop Sprinting")
	}

	// Admin commands
	{
		RegAdminCmd("sm_fly", Command_AdminFly, ADMFLAG_CUSTOM2, "WTF.")
		RegAdminCmd("sm_tele", Command_AdminTeleport, ADMFLAG_GENERIC, "Teleport player.")
	}
	
	PrintToServer( "LazMod PlayerMove loaded!" )
}

//////////////////////////////
// Player Commands
//////////////////////////////
public Action Command_EnableSprint(Client, args) 
{
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled

	float vOriginPlayer[3]

	int entSpeedmod = CreateEntityByName("player_speedmod")
	DispatchSpawn(entSpeedmod)

	SetVariantString("3.0")
	AcceptEntityInput(entSpeedmod, "ModifySpeed", Client, Client)
	GetClientAbsOrigin(Client, vOriginPlayer)
	EmitAmbientSound("buttons/button15.wav", vOriginPlayer, entSpeedmod, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0)
	AcceptEntityInput(entSpeedmod, "kill", -1)
	return Plugin_Handled
}

public Action Command_DisableSprint(Client, args)
{
	new entSpeedMod = CreateEntityByName("player_speedmod")
	DispatchSpawn(entSpeedMod)
	SetVariantString("1.0")
	AcceptEntityInput(entSpeedMod, "ModifySpeed", Client, Client)
	AcceptEntityInput(entSpeedMod, "kill", -1)

	return Plugin_Handled
}

//////////////////////////////
// Admin Commands
//////////////////////////////
public Action Command_AdminFly(Client, args)
{
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled

	if (GetEntityMoveType(Client) != MOVETYPE_NOCLIP)
	{
		if (LM_AllowFly(Client))
			SetEntityMoveType(Client, MOVETYPE_NOCLIP)
	}
	else {
		SetEntityMoveType(Client, MOVETYPE_WALK)
	}

	return Plugin_Handled
}

public Action Command_AdminTeleport(Client, args)
{
	if (args < 1)
	{
		LM_PrintToChat(Client, "Usage: !tele <player to> [player sent]")
		LM_PrintToChat(Client, "Ex: !tele cat dog  = Send dog to cat")
		LM_PrintToChat(Client, "Ex: !tele cat  = Send yourself to cat")
		return Plugin_Handled
	}

	char szClientTo[33], szClientSent[33]
	char target_name[MAX_TARGET_LENGTH]
	int target_list[1], target_count
	bool tn_is_ml

	GetCmdArg(1, szClientTo, sizeof(szClientTo))
	if ((target_count = ProcessTargetString(szClientTo, Client, target_list, 1, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(Client, target_count)
		return Plugin_Handled
	}

	for (int i = 0; i < target_count; i++)
	{
		new target = target_list[i]

		if (LM_IsBlacklisted(target))
		{
			LM_PrintToChat(Client, "%s is already blacklisted!", target_name)
			return Plugin_Handled
		}
		else
			LM_AddBlacklist(target)
	}

	if (args == 1)
	{
	}
	else {
	}

	GetCmdArg(2, szClientSent, sizeof(szClientSent))

	FakeClientCommand(Client, "admin_send \"%s\" \"%s\"", szClientTo, szClientSent)

	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++)
	{
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_tele", szArgs)
	return Plugin_Handled
}
TeleportPlayer(int plyTo, int plySent)
{
	float fOriginTo[3], fAimTo[3]
	GetClientAbsOrigin(plyTo, fOriginTo)
	GetClientEyeAngles(plyTo, fAimTo)
	fOriginTo[2] += 75

	TeleportEntity(plySent, fOriginTo, fAimTo)
}