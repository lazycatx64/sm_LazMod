


#include <sourcemod>
#include <sdktools>
#include <lazmod>


public Plugin myinfo =
{
	name		= "LazMod - PlayerMove",
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
		RegAdminCmd("sm_tp", Command_AdminTeleport, ADMFLAG_GENERIC, "Teleport player.")
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

public Action Command_AdminTeleport(plyClient, args)
{
	if (args < 1)
	{
		LM_PrintToChat(plyClient, "Usage: !tp <player to> [player sent]")
		LM_PrintToChat(plyClient, "Ex: !tp cat dog  = Send dog to cat")
		LM_PrintToChat(plyClient, "Ex: !tp cat  = Send yourself to cat")
		return Plugin_Handled
	}

	char szClientTo[33], szClientSent[33]
	GetCmdArg(1, szClientTo, sizeof(szClientTo))

	if (args == 1) {
		char szClientToName[MAX_TARGET_LENGTH]
		int plyClientToList[1], iClientToCount
		bool bClientToNameML

		if ((iClientToCount = ProcessTargetString(szClientTo, plyClient, plyClientToList, 1, 0, szClientToName, sizeof(szClientToName), bClientToNameML)) <= 0) {
			ReplyToTargetError(plyClient, iClientToCount)
			return Plugin_Handled
		}

		for (int i = 0; i < iClientToCount; i++) {
			int plyClientTo = plyClientToList[i]
			TeleportPlayerToPlayer(plyClientTo, plyClient)
		}

	} else {
		GetCmdArg(2, szClientSent, sizeof(szClientSent))

		char szClientToName[MAX_TARGET_LENGTH], szClientSentName[MAX_TARGET_LENGTH]
		int plyClientToList[1], iClientToCount, plyClientSentList[1], iClientSentCount
		bool bClientToNameML, bClientSentNameML

		if ((iClientToCount = ProcessTargetString(szClientTo, plyClient, plyClientToList, 1, 0, szClientToName, sizeof(szClientToName), bClientToNameML)) <= 0) {
			ReplyToTargetError(plyClient, iClientToCount)
			return Plugin_Handled
		}

		if ((iClientSentCount = ProcessTargetString(szClientSent, plyClient, plyClientSentList, 1, 0, szClientSentName, sizeof(szClientSentName), bClientSentNameML)) <= 0) {
			ReplyToTargetError(plyClient, iClientSentCount)
			return Plugin_Handled
		}

		for (int i = 0; i < iClientToCount; i++) {
			int plyClientTo = plyClientToList[i]
			for (int j = 0; j < iClientSentCount; j++) {
				int plyClientSent = plyClientSentList[j]
				TeleportPlayerToPlayer(plyClientTo, plyClientSent)
			}
		}


	}


	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_tp", szArgs)
	return Plugin_Handled
}
TeleportPlayerToPlayer(int plyTo, int plySent)
{
	float vToPos[3], vToAngles[3]
	GetClientAbsOrigin(plyTo, vToPos)
	GetClientEyeAngles(plyTo, vToAngles)
	vToPos[2] += 75

	TeleportEntity(plySent, vToPos, vToAngles)
}