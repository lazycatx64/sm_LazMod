


#include <sourcemod>
#include <sdktools>

#include <lazmod>



ConVar g_hCvarAllowFly
bool g_bCvarAllowFly



public Plugin myinfo = {
	name		= "LazMod - PlayerMove",
	author		= "LaZycAt, hjkwe654",
	description = "Noclip, sprint, teleport, etc.",
	version		= LAZMOD_VER,
	url			= ""
}

public OnPluginStart() {

	// Player commands
	{
		RegAdminCmd("+sprint", Command_EnableSprint, 0, "Sprint with x3 speed!")
		RegAdminCmd("-sprint", Command_DisableSprint, 0, "Stop Sprinting")
		RegAdminCmd("+lightspeed", Command_EnableLightspeed, 0, "Sprint with x10 speed!")
		RegAdminCmd("-lightspeed", Command_DisableSprint, 0, "Stop Lightspeed")
		RegAdminCmd("sm_fly", Command_SwitchFly, 0, "Player noclip.")
	}

	// Admin commands
	{
		RegAdminCmd("sm_tp", Command_AdminTeleport, ADMFLAG_GENERIC, "Teleport player.")
		RegAdminCmd("sm_bring", Command_AdminBring, ADMFLAG_GENERIC, "Bring player.")
	}
	
	g_hCvarAllowFly = CreateConVar("lm_allow_fly", "1", "Players can use !fly to noclip", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarAllowFly.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarAllowFly)
	
	PrintToServer( "LazMod PlayerMove loaded!" )
}



Hook_CvarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	CvarChanged(convar)
}
void CvarChanged(Handle convar) {
	if (convar == g_hCvarAllowFly)
		g_bCvarAllowFly = g_hCvarAllowFly.BoolValue
	
}





//////////////////////////////
// Player Commands
//////////////////////////////
public Action Command_EnableSprint(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled

	float vOriginPlayer[3]

	int entSpeedmod = CreateEntityByName("player_speedmod")
	DispatchSpawn(entSpeedmod)

	SetVariantString("3.0")
	AcceptEntityInput(entSpeedmod, "ModifySpeed", plyClient, plyClient)
	GetClientAbsOrigin(plyClient, vOriginPlayer)
	EmitAmbientSound("buttons/button15.wav", vOriginPlayer, entSpeedmod, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0)
	AcceptEntityInput(entSpeedmod, "kill", -1)
	return Plugin_Handled
}

public Action Command_EnableLightspeed(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled

	float vOriginPlayer[3]

	int entSpeedmod = CreateEntityByName("player_speedmod")
	DispatchSpawn(entSpeedmod)

	SetVariantString("10.0")
	AcceptEntityInput(entSpeedmod, "ModifySpeed", plyClient, plyClient)
	GetClientAbsOrigin(plyClient, vOriginPlayer)
	EmitAmbientSound("buttons/button15.wav", vOriginPlayer, entSpeedmod, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0)
	AcceptEntityInput(entSpeedmod, "kill", -1)
	return Plugin_Handled
}

public Action Command_DisableSprint(plyClient, args) {
	int entSpeedMod = CreateEntityByName("player_speedmod")
	DispatchSpawn(entSpeedMod)
	SetVariantString("1.0")
	AcceptEntityInput(entSpeedMod, "ModifySpeed", plyClient, plyClient)
	AcceptEntityInput(entSpeedMod, "kill", -1)

	return Plugin_Handled
}

public Action Command_SwitchFly(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled

	if (GetEntityMoveType(plyClient) != MOVETYPE_NOCLIP) {
		if (!LM_IsClientAdmin(plyClient) && !g_bCvarAllowFly) {
			LM_PrintToChat(plyClient, "Fly is not available or disabled.")
		} else {
			SetEntityMoveType(plyClient, MOVETYPE_NOCLIP)
		}
	} else {
		SetEntityMoveType(plyClient, MOVETYPE_WALK)
	}

	return Plugin_Handled
}




//////////////////////////////
// Admin Commands
//////////////////////////////

public Action Command_AdminTeleport(plyClient, args) {
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

public Action Command_AdminBring(plyClient, args) {
	if (args < 1)
	{
		LM_PrintToChat(plyClient, "Usage: !bring <player bring>")
		LM_PrintToChat(plyClient, "Ex: !bring cat  = Send cat to you")
		return Plugin_Handled
	}

	char szClientBring[33]
	GetCmdArg(1, szClientBring, sizeof(szClientBring))

	char szClientBringName[MAX_TARGET_LENGTH]
	int plyClientBringList[1], iClientBringCount
	bool bClientBringNameML

	if ((iClientBringCount = ProcessTargetString(szClientBring, plyClient, plyClientBringList, MaxClients, 0, szClientBringName, sizeof(szClientBringName), bClientBringNameML)) <= 0) {
		ReplyToTargetError(plyClient, iClientBringCount)
		return Plugin_Handled
	}

	for (int i = 0; i < iClientBringCount; i++) {
		int plyClientBring = plyClientBringList[i]
		TeleportPlayerToPlayer(plyClient, plyClientBring)
	}


	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_bring", szArgs)
	return Plugin_Handled
}

void TeleportPlayerToPlayer(int plyTo, int plySent) {
	float vToPos[3], vToAngles[3]
	GetClientAbsOrigin(plyTo, vToPos)
	GetClientEyeAngles(plyTo, vToAngles)
	vToPos[2] += 75

	TeleportEntity(plySent, vToPos, vToAngles)
}