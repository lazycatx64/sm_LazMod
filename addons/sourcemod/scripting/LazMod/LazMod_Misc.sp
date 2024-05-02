


#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>

// Global definions
int g_mdlLaserBeam
int g_mdlHalo


char g_szMissileModel[MAXPLAYERS][128]
int g_iMissileTarget[MAXPLAYERS]


public Plugin myinfo = {
	name = "LazMod - Misc",
	author = "LaZycAt, hjkwe654",
	description = "Various uncategorized commands.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	
	// Player Commands
	{
	}

	// Level 2 Commands
	{
		// RegAdminCmd("sm_setview", Command_Setview, 0, "Turn your view into a prop.")
		// RegAdminCmd("sm_resetview", Command_Resetview, 0, "Quit the setview.")
		// RegAdminCmd("sm_ginertia", Command_GetInertia, 0, "Get an entity inertia.")
		// RegAdminCmd("sm_push", Command_Push, ADMFLAG_CUSTOM1, "Push an entity.")
		// RegAdminCmd("sm_setent", Command_SetEnt, ADMFLAG_CUSTOM1, "Set an entity as temporary.")
		// RegAdminCmd("sm_rope", Command_Rope, ADMFLAG_CUSTOM1, "Set a rope between two props.");
		// RegAdminCmd("sm_sinertia", Command_SetInertia, ADMFLAG_CUSTOM1, "Set an entity inertia.")
		// RegAdminCmd("sm_airboat", Command_Airboat, ADMFLAG_CUSTOM1, "Spawn an airboat.")
		// RegAdminCmd("sm_thruster", Command_Thruster, ADMFLAG_CUSTOM1, "Set a thruster on prop.")
		// RegAdminCmd("sm_delthruster", Command_DelThruster, ADMFLAG_CUSTOM1, "Delete thrusters.")
		// RegAdminCmd("+thruster", Command_EnableThruster, ADMFLAG_CUSTOM1, "Start thruster.")
		// RegAdminCmd("-thruster", Command_DisableThruster, ADMFLAG_CUSTOM1, "Stop thruster.")
		// RegAdminCmd("+rthruster", Command_rEnableThruster, ADMFLAG_CUSTOM1, "Start reverse thruster.")
		// RegAdminCmd("-rthruster", Command_rDisableThruster, ADMFLAG_CUSTOM1, "Stop reverse thruster.")
		// RegAdminCmd("sm_setgravity", Command_SetGravity, ADMFLAG_CUSTOM1, "Change Target Gravity.")
		// RegAdminCmd("sm_sg", Command_SetGravity, ADMFLAG_CUSTOM1, "Change Target Gravity.")
		// RegAdminCmd("sm_getgravity", Command_GetGravity, ADMFLAG_CUSTOM1, "Get Target Gravity.")
		// RegAdminCmd("sm_gg", Command_GetGravity, ADMFLAG_CUSTOM1, "Get Target Gravity.")
	}
	
	// Admin Commands
	{
		// RegAdminCmd("sm_ball", Command_Ball, ADMFLAG_GENERIC, "Spawn a energy ball.")
		
		RegAdminCmd("sm_setowner", Command_AdminSetOwner, ADMFLAG_BAN, "WTF.")
		RegAdminCmd("sm_team", Command_AdminTeam, ADMFLAG_GENERIC, "Force a player join a team.")
		RegAdminCmd("sm_hurt", Command_AdminHurt, ADMFLAG_BAN, "To hurt you.")
		RegAdminCmd("sm_shoot", Command_AdminShoot, ADMFLAG_BAN, "WTF.")
		RegAdminCmd("sm_mis", Command_AdminMissile, ADMFLAG_CONVARS, "To fire rockets.")
		RegAdminCmd("sm_misset", Command_AdminMissileSet, ADMFLAG_CONVARS, "To set rockets model.")
		RegAdminCmd("sm_misla", Command_AdminMissileLast, ADMFLAG_CONVARS, "Attack last target.")
		RegAdminCmd("sm_gb", Command_AdminBottle, ADMFLAG_CONVARS, "Create bottles.")
		//RegAdminCmd("sm_strider", Command_RActionStrider, ADMFLAG_CONVARS, "Range action strider style.")
		//RegAdminCmd("sm_square", Command_RActionSquare, ADMFLAG_CONVARS, "Range action square style.")
		
		RegAdminCmd("sm_atest", Command_Test, ADMFLAG_ROOT, "test.")
	}
	
	RegConsoleCmd("sm_delay", Command_Delay)
	RegConsoleCmd("kill", Command_kill, "")
	
	PrintToServer( "LazMod Misc loaded!" )
}

public OnMapStart() {
	g_mdlLaserBeam = PrecacheModel("materials/sprites/laserbeam.vmt")
	g_mdlHalo = PrecacheModel("materials/sprites/halo01.vmt")
	PrecacheSound("npc/sniper/echo1.wav", true)
	PrecacheSound("npc/sniper/sniper1.wav", true)
	PrecacheSound("buttons/button15.wav", true)
	PrecacheSound("ion/attack.wav", true)
	
	MapPreset()
}

// TODO: SourceOP Dead
public Action Command_Airboat(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	// FakeClientCommand(Client, "e_spawnboat")	// SourceOP Dead
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_airboat", szArgs)
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_Ball(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	// FakeClientCommand(Client, "e_spawnball")	// SourceOP Dead
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_ball", szArgs)
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_GetInertia(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	// FakeClientCommand(Client, "e_getinertia")	// SourceOP Dead
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_getinertia", szArgs)
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_SetEnt(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		LM_PrintToChat(Client, "First prop selected, use !rp to select second prop to finish.")
		// FakeClientCommand(Client, "e_setent")	// SourceOP Dead
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_setent", szArgs)
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_SetInertia(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !sinertia/!si <x> <y> <z>")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		char szX[16], szY[16], szZ[16]
		GetCmdArg(1, szX, sizeof(szX))
		GetCmdArg(2, szY, sizeof(szY))
		GetCmdArg(3, szZ, sizeof(szZ))
		
		FakeClientCommand(Client, "e_setinertia %s %s %s", szX, szY, szZ)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_setinertia", szArgs)
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_Push(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !push <force>")
		LM_PrintToChat(Client, "Ex: !push 1000")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		char szForce[16]
		GetCmdArg(1, szForce, sizeof(szForce))
		
		FakeClientCommand(Client, "e_push %s", szForce)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_push", szArgs)
	return Plugin_Handled
}


// TODO: SourceOP Dead
public Action Command_Setview(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	// if (LM_IsEntityOwner(Client, entProp))
		// FakeClientCommand(Client, "e_setview")	// SourceOP Dead
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_setview", szArgs)
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_Resetview(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled
	
	// FakeClientCommand(Client, "e_resetview")	// SourceOP Dead
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_resetview", szArgs)
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_Rope(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	// if (LM_IsEntityOwner(Client, entProp))
		// FakeClientCommand(Client, "e_rope")	// SourceOP Dead
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_rope", szArgs)
	return Plugin_Handled
}

// // TODO: SourceOP Dead
// public Action Command_Thruster(Client, args) {
// 	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
// 		return Plugin_Handled
	
// 	if (args < 2) {
// 		LM_PrintToChat(Client, "Usage: !thruster <group> <force>")
// 		LM_PrintToChat(Client, "Ex: !thruster aaa 1000")
		
// 		return Plugin_Handled
// 	}
	
// 	int entProp = LM_GetClientAimEntity(Client)
// 	if (entProp == -1) 
// 		return Plugin_Handled
	
// 	if (LM_IsEntityOwner(Client, entProp)) {
// 		char szGroup[16], szForce[12]
// 		GetCmdArg(1, szGroup, sizeof(szGroup))
// 		GetCmdArg(2, szForce, sizeof(szForce))
// 		LM_PrintToChat(Client, "Placed a thruster, Group: %s, Force: %s", szGroup, szForce)
// 		FakeClientCommand(Client, "e_thruster \"%s\" %s", szGroup, szForce)
// 	}
	
// 	char szTemp[33], szArgs[128]
// 	for (int i = 1; i <= GetCmdArgs(); i++) {
// 		GetCmdArg(i, szTemp, sizeof(szTemp))
// 		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
// 	}
// 	LM_LogCmd(Client, "sm_thruster", szArgs)
// 	return Plugin_Handled
// }

// // TODO: SourceOP Dead
// public Action Command_DelThruster(Client, args) {
// 	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client))
// 		return Plugin_Handled
	
// 	if (args < 1) {
// 		LM_PrintToChat(Client, "Usage: !delthruster/!dth <group>")
// 		LM_PrintToChat(Client, "Ex: !dth aaa")
		
// 		return Plugin_Handled
// 	}
	
// 	char szGroup[16]
// 	GetCmdArg(1, szGroup, sizeof(szGroup))
// 	// FakeClientCommand(Client, "e_delthruster_group \"%s\"", szGroup)
	
// 	char szTemp[33], szArgs[128]
// 	for (int i = 1; i <= GetCmdArgs(); i++) {
// 		GetCmdArg(i, szTemp, sizeof(szTemp))
// 		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
// 	}
// 	LM_LogCmd(Client, "sm_delthruster", szArgs)
// 	return Plugin_Handled
// }

// // TODO: SourceOP Dead
// public Action Command_EnableThruster(Client, args) {
// 	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client))
// 		return Plugin_Handled
	
// 	if (args < 1) {
// 		LM_PrintToChat(Client, "Usage: +th <group>")
// 		LM_PrintToChat(Client, "Ex: +th aaa")
// 		return Plugin_Handled
// 	}
	
// 	char szGroup[4]
// 	GetCmdArg(1, szGroup, sizeof(szGroup))
// 	// FakeClientCommand(Client, "+thruster \"%s\"", szGroup)
	
// 	return Plugin_Handled
// }

// // TODO: SourceOP Dead
// public Action Command_DisableThruster(Client, args) {
// 	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client))
// 		return Plugin_Handled
	
// 	char szGroup[4]
// 	GetCmdArg(1, szGroup, sizeof(szGroup))
// 	// FakeClientCommand(Client, "-thruster \"%s\"", szGroup)
	
// 	return Plugin_Handled
// }

// // TODO: SourceOP Dead
// public Action Command_rEnableThruster(Client, args) {
// 	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client))
// 		return Plugin_Handled
	
// 	if (args < 1) {
// 		LM_PrintToChat(Client, "Usage: +rth <group>")
// 		LM_PrintToChat(Client, "Ex: +rth aaa")
// 		return Plugin_Handled
// 	}
	
// 	char group[4]
// 	GetCmdArg(1, group, sizeof(group))
// 	// FakeClientCommand(Client, "+rthruster \"%s\"", group)
	
// 	return Plugin_Handled
// }

// // TODO: SourceOP Dead
// public Action Command_rDisableThruster(Client, args) {
// 	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client))
// 		return Plugin_Handled
	
// 	char group[4]
// 	GetCmdArg(1, group, sizeof(group))
// 	FakeClientCommand(Client, "-rthruster \"%s\"", group)
	
// 	return Plugin_Handled
// }


public Action Command_AdminSetOwner(Client, args) {
	if (!LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !setowner <Player>")
		return Plugin_Handled
	}
	
	char szClass[32]
	char szTarget[64]
	GetCmdArg(1, szTarget, sizeof(szTarget))
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	
	int plyOwner = LM_GetEntityOwner(entProp)
	if (StrEqual(szTarget, "-1")) {
		LM_SetEntityOwner(entProp, -1)
		if(StrEqual(szClass, "prop_ragdoll"))
			LM_SetSpawnLimit(plyOwner, -1)
		else
			LM_SetSpawnLimit(plyOwner, -1, true)
		LM_PrintToChat(Client, "SetOwner to: none")
	} else {
		char target_name[MAX_TARGET_LENGTH]
		int target_list[MAXPLAYERS], target_count
		bool tn_is_ml
		
		if ((target_count = ProcessTargetString(szTarget, Client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(Client, target_count)
			return Plugin_Handled
		}
		for (int i = 0; i < target_count; i++) {
			new target = target_list[i]
			LM_SetEntityOwner(entProp, target)
			if(plyOwner != -1)
				LM_SetSpawnLimit(plyOwner, -1, StrEqual(szClass, "prop_ragdoll"))
			
			LM_SetSpawnLimit(target, -1, StrEqual(szClass, "prop_ragdoll"))
			
			LM_PrintToChat(Client, "SetOwner to: %N", target)
		}
	}

	
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_setowner", szArgs)
	return Plugin_Handled
}

public Action Command_AdminTeam(Client, args) {
	if (args < 2) {
		LM_PrintToChat(Client, "Usage: !team <UserID> <Team>")
		return Plugin_Handled
	}
	
	char szPlayer[64], szTeam[8]
	GetCmdArg(1, szPlayer, sizeof(szPlayer))
	GetCmdArg(2, szTeam, sizeof(szTeam))
	
	char target_name[MAX_TARGET_LENGTH]
	int target_list[MAXPLAYERS], target_count
	bool tn_is_ml
	
	if ((target_count = ProcessTargetString(szPlayer, Client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(Client, target_count)
		return Plugin_Handled
	}

	for (int i = 0; i < target_count; i++) {
		new target = target_list[i]
		ChangeClientTeam(target, StringToInt(szTeam))
		FakeClientCommand(target, "jointeam %s", szTeam)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_team", szArgs)
	return Plugin_Handled
}

public Action Command_AdminHurt(Client, args) {
	if (args < 3)
		return Plugin_Handled
	
	new iColor[4]
	char szHurtDamage[64], szHurtRange[64], szHrutType[64], szClassName[64], szParent[64]
	float vOriginPlayer[3], fAimPos[3]
	GetCmdArg(1, szHurtDamage, sizeof(szHurtDamage))
	GetCmdArg(2, szHurtRange, sizeof(szHurtRange))
	GetCmdArg(3, szHrutType, sizeof(szHrutType))
	GetCmdArg(4, szClassName, sizeof(szClassName))
	GetCmdArg(5, szParent, sizeof(szParent))
	
	LM_ClientAimPos(Client, fAimPos)
	GetClientAbsOrigin(Client, vOriginPlayer)
	
	int entProp = GetClientAimTarget(Client)
	if (entProp != -1)
		if (LM_IsPlayer(entProp))
			GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", fAimPos)
	
	if (StrEqual(szHurtDamage, ""))
		szHurtDamage = "50"
	if (StrEqual(szHurtRange, ""))
		szHurtRange = "200"
	if (StrEqual(szHrutType, ""))
		szHrutType = "0"
	if (StrEqual(szClassName, ""))
		szClassName = "point_hurt"
	
	int entHurt = CreateEntityByName("point_hurt")
	vOriginPlayer[2] = (vOriginPlayer[2] + 50)
	
	TeleportEntity(entHurt, fAimPos, NULL_VECTOR, NULL_VECTOR)
	DispatchKeyValue(entHurt, "damage", szHurtDamage)
	DispatchKeyValue(entHurt, "DamageRadius", szHurtRange)
	DispatchKeyValue(entHurt, "damagetype", szHrutType)
	DispatchKeyValue(entHurt, "classname", szClassName)
	DispatchSpawn(entHurt)
	
	iColor[0] = GetRandomInt(50, 255)
	iColor[1] = GetRandomInt(50, 255)
	iColor[2] = GetRandomInt(50, 255)
	iColor[3] = GetRandomInt(250, 255)
	
	TE_SetupBeamPoints(fAimPos, vOriginPlayer, g_mdlLaserBeam, g_mdlHalo, 0, 66, 0.1, 3.0, 3.0, 0, 0.0, iColor, 20)
	TE_SendToAll()
	
	
	
	if (StrEqual(szParent, "")) {
		AcceptEntityInput(entHurt, "hurt", Client, Client)
	} else if (StrEqual(szParent, "r")) {
		float fOriginEntity[3]
		DispatchKeyValue(Client, "targetname", "szHurtFrom")
		SetVariantString("szHurtFrom")
		AcceptEntityInput(entHurt, "setparent", Client, Client)
		for(int i = 0; i < 4000; i++) {
			if(IsValidEdict(i)) {
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", fOriginEntity)
				GetEdictClassname(i, szClassName, sizeof(szClassName))
				if((StrContains(szClassName, "npc_") == 0 || StrEqual(szClassName, "player")) && LM_IsInRange(fOriginEntity, fAimPos, StringToFloat(szHurtRange))) {
					DispatchKeyValue(i, "targetname", "HurtTarget")
					DispatchKeyValue(entHurt, "damagetarget", "HurtTarget")
					AcceptEntityInput(entHurt, "hurt", Client, Client)
					DispatchKeyValue(i, "targetname", "HurtTargetDrop")
				}
			}
		}
		DispatchKeyValue(Client, "targetname", "szHurtUserDrop")
	} else if (StrEqual(szParent, "all")) {
		new iPlayer = -1
		DispatchKeyValue(Client, "targetname", "szHurtFrom")
		SetVariantString("szHurtFrom")
		AcceptEntityInput(entHurt, "setparent", Client, Client)
		for (int i = 0; i < MAXPLAYERS; i++) {
			while ((iPlayer = FindEntityByClassname(iPlayer, "player")) != -1) {
				DispatchKeyValue(iPlayer, "targetname", "HurtTarget")
				DispatchKeyValue(entHurt, "damagetarget", "HurtTarget")
				AcceptEntityInput(entHurt, "hurt", Client, Client)
				DispatchKeyValue(iPlayer, "targetname", "HurtTargetDrop")
			}
		}
		DispatchKeyValue(Client, "targetname", "szHurtUserDrop")
	} else {
		new iPlayer = GetClientOfUserId(StringToInt(szParent))
		DispatchKeyValue(iPlayer, "targetname", "HurtTarget")
		DispatchKeyValue(entHurt, "damagetarget", "HurtTarget")
		DispatchKeyValue(Client, "targetname", "szHurtFrom")
		SetVariantString("szHurtFrom")
		AcceptEntityInput(entHurt, "setparent", Client, Client)
		AcceptEntityInput(entHurt, "hurt", Client, Client)
		DispatchKeyValue(Client, "targetname", "szHurtUserDrop")
		DispatchKeyValue(iPlayer, "targetname", "HurtTargetDrop")
	}
	EmitAmbientSound("ion/attack.wav", vOriginPlayer, entHurt, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	EmitAmbientSound("ion/attack.wav", fAimPos, entHurt, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	//new iPitch = GetRandomInt(50, 255)
	//EmitAmbientSound("npc/sniper/sniper1.wav", vOriginPlayer, entHurt, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, iPitch)
	//EmitAmbientSound("npc/sniper/echo1.wav", fAimPos, entHurt, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, iPitch)
	AcceptEntityInput(entHurt, "kill", -1)
	return Plugin_Handled
}

public Action Command_AdminShoot(Client, args) {
	char Prop[128]
	GetCmdArg(1, Prop, sizeof(Prop))
	if (args < 1) {
		Prop = "gascan1"
	}
	FakeClientCommand(Client, "e_spawnprop %s", Prop)
	FakeClientCommand(Client, "e_setmass 50000")
	FakeClientCommand(Client, "e_fire sethealth 15")
	FakeClientCommand(Client, "e_fire ignitelifetime 999")
	FakeClientCommand(Client, "e_push 5000000000")
	return Plugin_Handled;	
}

public Action Command_AdminMissile(Client, args) {
	int entInfoTarget
	g_iMissileTarget[Client] = LM_GetClientAimEntity(Client, _, true)
	if (g_iMissileTarget[Client] == -1) {
		char vTarget[8]
		GetCmdArg(1, vTarget, sizeof(vTarget))
		if (!StrEqual(vTarget, "")) {
			float fAimPos[3]
			LM_ClientAimPos(Client, fAimPos)
			entInfoTarget = CreateEntityByName("info_target")
			TeleportEntity(entInfoTarget, fAimPos, NULL_VECTOR, NULL_VECTOR)
			DispatchKeyValue(entInfoTarget, "targetname", "szMissileTarget")
			DispatchSpawn(entInfoTarget)
		} else
			return Plugin_Handled;	
	}
	
	float vOriginPlayer[3], fAnglePlayer[3]
	GetClientAbsOrigin(Client, vOriginPlayer)
	GetClientAbsAngles(Client, fAnglePlayer)
	vOriginPlayer[2] = (vOriginPlayer[2] + 150)
	
	if (StrEqual(g_szMissileModel[Client], ""))
		return Plugin_Handled
	
	int entMissileLauncher;entMissileLauncher = CreateEntityByName("npc_launcher")
	TeleportEntity(entMissileLauncher, vOriginPlayer, fAnglePlayer, NULL_VECTOR)
	DispatchKeyValue(g_iMissileTarget[Client], "targetname", "szMissileTarget")
	DispatchKeyValue(entMissileLauncher, "MissileModel", g_szMissileModel[Client])
	DispatchKeyValue(entMissileLauncher, "FlySound", "weapons/rpg/rocket1.wav")
	DispatchKeyValue(entMissileLauncher, "SmokeTrail", "2")
	DispatchKeyValue(entMissileLauncher, "LaunchSmoke", "0")
	DispatchKeyValue(entMissileLauncher, "LaunchDelay", "1")
	DispatchKeyValue(entMissileLauncher, "LaunchSpeed", "1500")
	DispatchKeyValue(entMissileLauncher, "HomingSpeed", "1.5")
	DispatchKeyValue(entMissileLauncher, "HomingStrength", "100")
	DispatchKeyValue(entMissileLauncher, "HomingDelay", "0.1")
	DispatchKeyValue(entMissileLauncher, "HomingRampUp", "0")
	DispatchKeyValue(entMissileLauncher, "HomingDuration", "20")
	DispatchKeyValue(entMissileLauncher, "HomingRampDown", "1")
	DispatchKeyValue(entMissileLauncher, "Gravity", "1")
	DispatchKeyValue(entMissileLauncher, "MinRange", "1")
	DispatchKeyValue(entMissileLauncher, "MaxRange", "5000")
	DispatchKeyValue(entMissileLauncher, "SpinMagnitude", "1")
	DispatchKeyValue(entMissileLauncher, "SpinSpeed", "1")
	DispatchKeyValue(entMissileLauncher, "Damage", "50")
	DispatchKeyValue(entMissileLauncher, "DamageRadius", "50")
	
	DispatchSpawn(entMissileLauncher)
	SetVariantString("szMissileTarget d_ht 99")
	AcceptEntityInput(entMissileLauncher, "setrelationship", -1)
	SetVariantString("szMissileTarget")
	AcceptEntityInput(entMissileLauncher, "setenemyentity", -1)
	AcceptEntityInput(entMissileLauncher, "fireonce", -1)
	AcceptEntityInput(entMissileLauncher, "kill", -1)
	AcceptEntityInput(entInfoTarget, "kill", -1)
	
	DispatchKeyValue(g_iMissileTarget[Client], "targetname", "szMissileTargetDrop")
	return Plugin_Handled
}

public Action Command_AdminMissileSet(Client, args) {
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) {
		g_szMissileModel[Client] = "models/props_junk/watermelon01.mdl"
		LM_PrintToChat(Client, "Missile model has been set back to \"%s\".", g_szMissileModel[Client])
	} else {
		GetEntPropString(entProp, Prop_Data, "m_ModelName", g_szMissileModel[Client], sizeof(g_szMissileModel))
		LM_PrintToChat(Client, "Missile model has been set to \"%s\".", g_szMissileModel[Client])
	}
	PrecacheModel(g_szMissileModel[Client])
	return Plugin_Handled
}

public Action Command_AdminMissileLast(Client, args) {
	float vOriginPlayer[3], fAnglePlayer[3]
	GetClientAbsOrigin(Client, vOriginPlayer)
	GetClientAbsAngles(Client, fAnglePlayer)
	vOriginPlayer[2] = (vOriginPlayer[2] + 150)
	
	if (StrEqual(g_szMissileModel[Client], "")) {
		LM_PrintToChat(Client, "[Missile] Set a model with sm_misset first!")
		return Plugin_Handled
	}
	
	int entMissileLauncher;entMissileLauncher = CreateEntityByName("npc_launcher")
	TeleportEntity(entMissileLauncher, vOriginPlayer, fAnglePlayer, NULL_VECTOR)
	DispatchKeyValue(g_iMissileTarget[Client], "targetname", "szMissileTarget")
	DispatchKeyValue(entMissileLauncher, "MissileModel", g_szMissileModel[Client])
	DispatchKeyValue(entMissileLauncher, "FlySound", "weapons/rpg/rocket1.wav")
	DispatchKeyValue(entMissileLauncher, "SmokeTrail", "2")
	DispatchKeyValue(entMissileLauncher, "LaunchSmoke", "0")
	DispatchKeyValue(entMissileLauncher, "LaunchDelay", "1")
	DispatchKeyValue(entMissileLauncher, "LaunchSpeed", "1500")
	DispatchKeyValue(entMissileLauncher, "HomingSpeed", "1.5")
	DispatchKeyValue(entMissileLauncher, "HomingStrength", "100")
	DispatchKeyValue(entMissileLauncher, "HomingDelay", "0.1")
	DispatchKeyValue(entMissileLauncher, "HomingRampUp", "0")
	DispatchKeyValue(entMissileLauncher, "HomingDuration", "20")
	DispatchKeyValue(entMissileLauncher, "HomingRampDown", "1")
	DispatchKeyValue(entMissileLauncher, "Gravity", "1")
	DispatchKeyValue(entMissileLauncher, "MinRange", "1")
	DispatchKeyValue(entMissileLauncher, "MaxRange", "5000")
	DispatchKeyValue(entMissileLauncher, "SpinMagnitude", "1")
	DispatchKeyValue(entMissileLauncher, "SpinSpeed", "1")
	DispatchKeyValue(entMissileLauncher, "Damage", "50")
	DispatchKeyValue(entMissileLauncher, "DamageRadius", "50")
	
	DispatchSpawn(entMissileLauncher)
	
	SetVariantString("szMissileTarget d_ht 99")
	AcceptEntityInput(entMissileLauncher, "setrelationship", -1)
	SetVariantString("szMissileTarget")
	AcceptEntityInput(entMissileLauncher, "setenemyentity", -1)
	
	AcceptEntityInput(entMissileLauncher, "fireonce", -1);	
	AcceptEntityInput(entMissileLauncher, "kill", -1)
	DispatchKeyValue(g_iMissileTarget[Client], "targetname", "szMissileTargetDrop")
	
	return Plugin_Handled
}

public Action Command_AdminBottle(Client, args) {
	char type[16]
	float aim[3]
	new bottle
	LM_ClientAimPos(Client, aim);	
	GetCmdArg(1, type, sizeof(type))
	
	if (StrEqual(type, "1")) {
		bottle = CreateEntityByName("prop_physics")
		TeleportEntity(bottle, aim, NULL_VECTOR, NULL_VECTOR)
		DispatchKeyValue(bottle, "model", "models/props_junk/GlassBottle01a.mdl")
		DispatchKeyValue(bottle, "exploderadius", "100")
		DispatchKeyValue(bottle, "explodedamage", "300")
		DispatchSpawn(bottle)
		return Plugin_Handled
	}
	LM_PrintToChat(Client, "No bottle type selected.")
	
	return Plugin_Handled
}

public Action Command_Test(Client, args) {
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	DispatchKeyValue(entProp, "model", "models/props_junk/watermelon01.mdl")
	DispatchSpawn(entProp)
	return Plugin_Handled
}


// Misc
public Action Command_kill(Client, Args) {
	if (!LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	ForcePlayerSuicide(Client)
	
	return Plugin_Handled
}

public Action Command_Delay(Client, args) {
	if (args != 2) {
		ReplyToCommand(Client, "[SM] Usage: sm_future <Time in minutes> \"Command CmdArgs\"")
		return Plugin_Handled;	
	}
	char szCommand[255], szTime[12]
	GetCmdArg(1, szTime, sizeof(szTime))
	GetCmdArg(2, szCommand, sizeof(szCommand))
	
	float fTime = StringToFloat(szTime)
	
	ShowActivity2(Client, "[SM] ","Executing \"%s\" in %s seconds", szCommand, szTime)
	
	Handle hExcute
	CreateDataTimer(fTime, Timer_Delay, hExcute)
	WritePackString(hExcute,szTime)
	WritePackString(hExcute,szCommand)
	return Plugin_Handled
}

// Timers
public Action Timer_Delay(Handle Timer, Handle hExcute) {
	char szCommand[255], szTime[25]
	
	ResetPack(hExcute)
	ReadPackString(hExcute, szTime, sizeof(szTime))
	ReadPackString(hExcute, szCommand, sizeof(szCommand))
	
	ServerCommand("%s", szCommand)
	
	return Plugin_Stop
}


public MapPreset() {
	char szMapName[64]
	GetCurrentMap(szMapName, sizeof(szMapName))
	
	if (IsAllowBuildMod(szMapName))
		ServerCommand("exec buildmodon")
	else
		ServerCommand("exec buildmodoff")
	
	if (StrEqual(szMapName, "z_umi_hydramag_v4")) {
		float vRebelOri[3], vRebelAng[3], vWepOri[3], vWepAng[3]
		int entRebelStart = -1, entLaser = -1, entWeaponCrate = -1
		vRebelOri[0] = -284.547
		vRebelOri[1] = 4590.370
		vRebelOri[2] = 1065.000
		vRebelAng[0] = 0.0
		vRebelAng[1] = 270.0
		vRebelAng[2] = 0.0

		while ((entRebelStart = FindEntityByClassname(entRebelStart , "info_player_rebel")) != -1)
			TeleportEntity(entRebelStart, vRebelOri, vRebelAng, NULL_VECTOR)
		
		vWepOri[0] = -3009.836
		vWepOri[1] = -3164.536
		vWepOri[2] = 1860.170
		vWepAng[0] = 0.0
		vWepAng[1] = 180.0
		vWepAng[2] = 0.0

		while ((entWeaponCrate = FindEntityByClassname(entWeaponCrate , "item_ammo_crate")) != -1)
			TeleportEntity(entWeaponCrate, vWepOri, vWepAng, NULL_VECTOR)
		
		// Fix the laser
		while ((entLaser  = FindEntityByClassname(entLaser , "env_laser")) != -1) {
			SetVariantString("1")
			AcceptEntityInput(entLaser, "width", -1)
			// DispatchKeyValue(entLaser, "damage", "0")
		}
	} else if (StrEqual(szMapName, "z_umizuri_hydra") || StrEqual(szMapName, "z_umizuri_v4") || StrEqual(szMapName, "js_fishing_umizuri_v3") || StrEqual(szMapName, "z_umizuri_xyz")) {
		float vRebelOri[3], vRebelAng[3]
		int entRebelStart = -1
		vRebelOri[0] = 2939.437500
		vRebelOri[1] = -4545.125000
		vRebelOri[2] = 1920.000000
		vRebelAng[0] = 0.0
		vRebelAng[1] = 270.0
		vRebelAng[2] = 0.0
		while ((entRebelStart = FindEntityByClassname(entRebelStart , "info_player_rebel")) != -1)
			TeleportEntity(entRebelStart, vRebelOri, vRebelAng, NULL_VECTOR)
		
	}
}

char szMapNameHead[][] = {
	"twbz_",
	"rp_",
	"Rp_",
	"RP_",
	"gm_",
	"Gm_",
	"GM_",
	"z_",
	"Z_",
	"freespace",
	"Freespace",
	"FreeSpace"
}

bool IsAllowBuildMod(char szMapName[64]){
	GetCurrentMap(szMapName, sizeof(szMapName))
	for (int i = 0; i < sizeof(szMapNameHead); i++) {
		if(StrContains(szMapName, szMapNameHead[i]) == 0) {
			PrintToServer("Map name start with \"%s\"", szMapNameHead)
			PrintToServer("BuildMod Allowed!!")
			return true
		}
	}
	PrintToServer("BuildMod Disabled!!")
	return false
}

