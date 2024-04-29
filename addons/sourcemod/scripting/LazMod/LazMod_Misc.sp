


#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>

// Global definions
int g_mdlLaserBeam
int g_mdlHalo


Handle g_hHostName = INVALID_HANDLE
char g_szHostName[128]

char g_szMissileModel[MAXPLAYERS][128]
int g_iMissileTarget[MAXPLAYERS]
float g_fAlignOrigin[MAXPLAYERS][3]
bool g_bExtendIsRunning[MAXPLAYERS]
int g_iExtendTarget[MAXPLAYERS]
char g_szCenterIsRunning[MAXPLAYERS][32]
int g_iCenterMain[MAXPLAYERS]
int g_iCenterFirst[MAXPLAYERS]


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
		RegAdminCmd("sm_render", Command_Render, 0, "Render an entity.")
		RegAdminCmd("sm_rotate", Command_Rotate, 0, "Rotate an entity.")
		RegAdminCmd("sm_color", Command_Color, 0, "Color a prop.")
	}

	// Level 2 Commands
	{
		RegAdminCmd("sm_nobreak", Command_NoBreakProp, ADMFLAG_CUSTOM1, "Set a prop wont break.")
		RegAdminCmd("sm_unnobreak", Command_UnNoBreakProp, ADMFLAG_CUSTOM1, "Undo nobreak.")
		RegAdminCmd("sm_angles", Command_SetAngles, ADMFLAG_CUSTOM1, "Set the angles of a prop directly.")
		RegAdminCmd("sm_align", Command_Align, ADMFLAG_CUSTOM1, "Aligning props.")
		RegAdminCmd("sm_move", Command_Move, ADMFLAG_CUSTOM1, "Move props.")
		RegAdminCmd("sm_extend", Command_Extend, ADMFLAG_CUSTOM1, "Create a third prop based on the position and angle of first two props.")
		RegAdminCmd("sm_center", Command_Center, ADMFLAG_CUSTOM1, "Moves a prop to the exact middle of the other two props.")
		RegAdminCmd("sm_skin", Command_Skin, ADMFLAG_CUSTOM1, "Change skin of a prop.")
		RegAdminCmd("sm_light", Command_LightDynamic, ADMFLAG_CUSTOM1, "Create a dynamic light.")
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
		RegAdminCmd("sm_ball", Command_Ball, ADMFLAG_GENERIC, "Spawn a energy ball.")
		
		RegAdminCmd("sm_fda", Command_AdminForceDeleteAll, ADMFLAG_BAN, "Delall a player's props.")
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
	g_hHostName = FindConVar("hostname")
	GetConVarString(g_hHostName, g_szHostName, sizeof(g_szHostName))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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


public Action Command_Render(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 5) {
		LM_PrintToChat(Client, "Usage: !render/!rd <fx amount> <fx> <R> <G> <B>")
		LM_PrintToChat(Client, "Ex. Flashing Green: !render 150 4 15 255 0")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		char szRenderAlpha[20], szRenderFX[20], szColorRGB[20][3], szColors[128]
		GetCmdArg(1, szRenderAlpha, sizeof(szRenderAlpha))
		GetCmdArg(2, szRenderFX, sizeof(szRenderFX))
		GetCmdArg(3, szColorRGB[0], sizeof(szColorRGB))
		GetCmdArg(4, szColorRGB[1], sizeof(szColorRGB))
		GetCmdArg(5, szColorRGB[2], sizeof(szColorRGB))
		
		Format(szColors, sizeof(szColors), "%s %s %s", szColorRGB[0], szColorRGB[1], szColorRGB[2])
		if (StringToInt(szRenderAlpha) < 1)
			szRenderAlpha = "1"
		DispatchKeyValue(entProp, "rendermode", "5")
		DispatchKeyValue(entProp, "renderamt", szRenderAlpha)
		DispatchKeyValue(entProp, "renderfx", szRenderFX)
		DispatchKeyValue(entProp, "rendercolor", szColors)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_render", szArgs)
	return Plugin_Handled
}

public Action Command_Color(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 3) {
		LM_PrintToChat(Client, "Usage: !color/!cl <R> <G> <B>")
		LM_PrintToChat(Client, "Ex: Green: !color 0 255 0")
		
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		char szColorRGB[20][3], szColors[33]
		GetCmdArg(1, szColorRGB[0], sizeof(szColorRGB))
		GetCmdArg(2, szColorRGB[1], sizeof(szColorRGB))
		GetCmdArg(3, szColorRGB[2], sizeof(szColorRGB))
		
		Format(szColors, sizeof(szColors), "%s %s %s", szColorRGB[0], szColorRGB[1], szColorRGB[2])
		DispatchKeyValue(entProp, "rendermode", "5")
		DispatchKeyValue(entProp, "renderamt", "255")
		DispatchKeyValue(entProp, "renderfx", "0")
		DispatchKeyValue(entProp, "rendercolor", szColors)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_color", szArgs)
	return Plugin_Handled
}

public Action Command_Rotate(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !rotate/!r <x> <y> <z>")
		LM_PrintToChat(Client, "Ex: !rotate 0 90 0")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		char szAngleX[8], szAngleY[8], szAngleZ[8]
		float fEntityOrigin[3], fEntityAngle[3]
		GetCmdArg(1, szAngleX, sizeof(szAngleX))
		GetCmdArg(2, szAngleY, sizeof(szAngleY))
		GetCmdArg(3, szAngleZ, sizeof(szAngleZ))
		
		GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", fEntityOrigin)
		GetEntPropVector(entProp, Prop_Data, "m_angRotation", fEntityAngle)
		fEntityAngle[0] += StringToFloat(szAngleX)
		fEntityAngle[1] += StringToFloat(szAngleY)
		fEntityAngle[2] += StringToFloat(szAngleZ)
		
		TeleportEntity(entProp, fEntityOrigin, fEntityAngle, NULL_VECTOR)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_rotate", szArgs)
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_Setview(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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

public Action Command_NoBreakProp(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		SetVariantString("999999999")
		AcceptEntityInput(entProp, "sethealth", -1)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_nobreak", szArgs)
	return Plugin_Handled
}

public Action Command_UnNoBreakProp(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		SetVariantString("50")
		AcceptEntityInput(entProp, "sethealth", -1)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_unnobreak", szArgs)
	return Plugin_Handled
}

public Action Command_SetAngles(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !angles <x> <y> <z>")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		char szRotateX[33], szRotateY[33], szRotateZ[33]
		float fEntityOrigin[3], fEntityAngle[3]
		GetCmdArg(1, szRotateX, sizeof(szRotateX))
		GetCmdArg(2, szRotateY, sizeof(szRotateY))
		GetCmdArg(3, szRotateZ, sizeof(szRotateZ))
		
		GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", fEntityOrigin)
		fEntityAngle[0] = StringToFloat(szRotateX)
		fEntityAngle[1] = StringToFloat(szRotateY)
		fEntityAngle[2] = StringToFloat(szRotateZ)
		
		TeleportEntity(entProp, fEntityOrigin, fEntityAngle, NULL_VECTOR)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_accuraterotate", szArgs)
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_Thruster(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 2) {
		LM_PrintToChat(Client, "Usage: !thruster <group> <force>")
		LM_PrintToChat(Client, "Ex: !thruster aaa 1000")
		
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		char szGroup[16], szForce[12]
		GetCmdArg(1, szGroup, sizeof(szGroup))
		GetCmdArg(2, szForce, sizeof(szForce))
		LM_PrintToChat(Client, "Placed a thruster, Group: %s, Force: %s", szGroup, szForce)
		FakeClientCommand(Client, "e_thruster \"%s\" %s", szGroup, szForce)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_thruster", szArgs)
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_DelThruster(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !delthruster/!dth <group>")
		LM_PrintToChat(Client, "Ex: !dth aaa")
		
		return Plugin_Handled
	}
	
	char szGroup[16]
	GetCmdArg(1, szGroup, sizeof(szGroup))
	// FakeClientCommand(Client, "e_delthruster_group \"%s\"", szGroup)
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_delthruster", szArgs)
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_EnableThruster(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: +th <group>")
		LM_PrintToChat(Client, "Ex: +th aaa")
		return Plugin_Handled
	}
	
	char szGroup[4]
	GetCmdArg(1, szGroup, sizeof(szGroup))
	// FakeClientCommand(Client, "+thruster \"%s\"", szGroup)
	
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_DisableThruster(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled
	
	char szGroup[4]
	GetCmdArg(1, szGroup, sizeof(szGroup))
	// FakeClientCommand(Client, "-thruster \"%s\"", szGroup)
	
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_rEnableThruster(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: +rth <group>")
		LM_PrintToChat(Client, "Ex: +rth aaa")
		return Plugin_Handled
	}
	
	char group[4]
	GetCmdArg(1, group, sizeof(group))
	// FakeClientCommand(Client, "+rthruster \"%s\"", group)
	
	return Plugin_Handled
}

// TODO: SourceOP Dead
public Action Command_rDisableThruster(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled
	
	char group[4]
	GetCmdArg(1, group, sizeof(group))
	FakeClientCommand(Client, "-rthruster \"%s\"", group)
	
	return Plugin_Handled
}

public Action Command_Align(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !align <mode>")
		LM_PrintToChat(Client, "!align set = Select the prop to be alignment refer")
		LM_PrintToChat(Client, "!align x  = Align the aimed prop with X coord")
		LM_PrintToChat(Client, "!align y  = Align the aimed prop with Y coord")
		LM_PrintToChat(Client, "!align z  = Align the aimed prop with Z coord")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsEntityOwner(Client, entProp))
		return Plugin_Handled
	
	char szMode[5]
	float fEntityAngle[3], fEntityOrigin[3]
	GetCmdArg(1, szMode, sizeof(szMode))
	
	GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", fEntityOrigin)
	GetEntPropVector(entProp, Prop_Data, "m_angRotation", fEntityAngle)

	if (StrEqual(szMode[0], "set") || StrEqual(szMode[0], "s")) {
		GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", g_fAlignOrigin[Client])
		LM_PrintToChat(Client, "Align set.")
	} else if (StrEqual(szMode[0], "x")) {
		fEntityOrigin[0] = g_fAlignOrigin[Client][0]
		TeleportEntity(entProp, fEntityOrigin, fEntityAngle, NULL_VECTOR)
	} else if (StrEqual(szMode[0], "y")) {
		fEntityOrigin[1] = g_fAlignOrigin[Client][1]
		TeleportEntity(entProp, fEntityOrigin, fEntityAngle, NULL_VECTOR)
	} else if (StrEqual(szMode[0], "z")) {
		fEntityOrigin[2] = g_fAlignOrigin[Client][2]
		TeleportEntity(entProp, fEntityOrigin, fEntityAngle, NULL_VECTOR)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_align", szArgs)
	return Plugin_Handled
}

public Action Command_Move(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !move <x> [y] [z]")
		LM_PrintToChat(Client, "Ex, move up 50: !move 0 0 50")

		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		float fEntityOrigin[3], fEntityAngle[3];	
		char szArgX[33], szArgY[33], szArgZ[33]
		GetCmdArg(1, szArgX, sizeof(szArgX))
		GetCmdArg(2, szArgY, sizeof(szArgY))
		GetCmdArg(3, szArgZ, sizeof(szArgZ))
		
		GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", fEntityOrigin)
		GetEntPropVector(entProp, Prop_Data, "m_angRotation", fEntityAngle)
		
		fEntityOrigin[0] += StringToFloat(szArgX)
		fEntityOrigin[1] += StringToFloat(szArgY)
		fEntityOrigin[2] += StringToFloat(szArgZ)
		
		TeleportEntity(entProp, fEntityOrigin, fEntityAngle, NULL_VECTOR)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_move", szArgs)
	return Plugin_Handled
}

public Action Command_Extend(plyClient, args) {
	if (!LM_AllowToUse(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	char szClass[33]
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	if (LM_IsEntityOwner(plyClient, entProp)) {
		int entThirdProp
		if (StrContains(szClass, "prop_dynamic") >= 0) {
			entThirdProp = CreateEntityByName("prop_dynamic_override")
			SetEntProp(entThirdProp, Prop_Send, "m_nSolidType", 6)
			SetEntProp(entThirdProp, Prop_Data, "m_nSolidType", 6)
		} else
			entThirdProp = CreateEntityByName(szClass)
			
		if (LM_SetEntityOwner(entThirdProp, plyClient)) {
			if (!g_bExtendIsRunning[plyClient]) {
				g_iExtendTarget[plyClient] = entProp
				g_bExtendIsRunning[plyClient] = true
				LM_PrintToChat(plyClient, "Extend #1 set, use !ex again on #2 prop.")
			} else {
				char szModel[255]
				float fOriginProp1[3], fAngle[3], fOriginProp2[3], fOriginProp3[3]
				
				GetEntPropVector(g_iExtendTarget[plyClient], Prop_Data, "m_vecOrigin", fOriginProp1)
				GetEntPropVector(g_iExtendTarget[plyClient], Prop_Data, "m_angRotation", fAngle)
				GetEntPropString(g_iExtendTarget[plyClient], Prop_Data, "m_ModelName", szModel, sizeof(szModel))
				GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", fOriginProp2)
				
				for (int i = 0; i < 3; i++)
					fOriginProp3[i] = (fOriginProp2[i] + fOriginProp2[i] - fOriginProp1[i])
				
				DispatchKeyValue(entThirdProp, "model", szModel)
				DispatchSpawn(entThirdProp)
				TeleportEntity(entThirdProp, fOriginProp3, fAngle, NULL_VECTOR)
				
				if(Phys_IsPhysicsObject(entThirdProp))
					Phys_EnableMotion(entThirdProp, false)
				
				g_bExtendIsRunning[plyClient] = false
				LM_PrintToChat(plyClient, "Extended a prop.")
			}
		} else
			RemoveEdict(entThirdProp)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(plyClient, "sm_extend", szArgs)
	return Plugin_Handled
}

public Action Command_Center(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsEntityOwner(Client, entProp))
		return Plugin_Handled


	if (StrEqual(g_szCenterIsRunning[Client], "first")) {
		g_iCenterFirst[Client] = entProp
		g_szCenterIsRunning[Client] = "secend"
		LM_PrintToChat(Client, "Now select the third prop to finish.")
	} else if (StrEqual(g_szCenterIsRunning[Client], "secend")) {
		float fAngleMain[3], fOriginMain[3], fOriginFirst[3], fOriginSecend[3]
		
		GetEntPropVector(g_iCenterMain[Client], Prop_Data, "m_angRotation", fAngleMain)
		GetEntPropVector(g_iCenterFirst[Client], Prop_Data, "m_vecOrigin", fOriginFirst)
		GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", fOriginSecend)
		
		for (int i = 0; i < 3; i++)
			fOriginMain[i] = (fOriginFirst[i] + fOriginSecend[i]) / 2
		
		TeleportEntity(g_iCenterMain[Client], fOriginMain, fAngleMain, NULL_VECTOR)
		g_szCenterIsRunning[Client] = "off"
	} else {
		g_iCenterMain[Client] = entProp
		g_szCenterIsRunning[Client] = "first"
		LM_PrintToChat(Client, "The prop to be moved have been selected, now select the secend prop.")
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_center", szArgs)
	return Plugin_Handled
}

public Action Command_Skin(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !skin <number>")
		LM_PrintToChat(Client, "Notice: Not every model have multiple skins.")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsEntityOwner(Client, entProp)) 
		return Plugin_Handled


	char szSkin[33]
	GetCmdArg(1, szSkin, sizeof(szSkin))
	
	SetVariantString(szSkin)
	AcceptEntityInput(entProp, "skin", entProp, Client, 0)
	
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_skin", szArgs)
	return Plugin_Handled
}

public Action Command_LightDynamic(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !ld <range> <brightness> <R> <G> <B>")
		return Plugin_Handled
	}
	
	new entLightMelon = CreateEntityByName("prop_physics_multiplayer")
	if (LM_SetEntityOwner(entLightMelon, Client)) {
		char szRange[33], szBrightness[33], szColorR[33], szColorG[33], szColorB[33], szColor[33]
		char szNameMelon[64]
		float fAimPos[3]
		GetCmdArg(1, szRange, sizeof(szRange))
		GetCmdArg(2, szBrightness, sizeof(szBrightness))
		GetCmdArg(3, szColorR, sizeof(szColorR))
		GetCmdArg(4, szColorG, sizeof(szColorG))
		GetCmdArg(5, szColorB, sizeof(szColorB))
		
		LM_ClientAimPos(Client, fAimPos)
		fAimPos[2] += 50
		
		if(!IsModelPrecached("models/props_junk/watermelon01.mdl"))
			PrecacheModel("models/props_junk/watermelon01.mdl")
		
		if (StrEqual(szBrightness, ""))
			szBrightness = "3"
		if (StringToInt(szColorR) < 100 || StrEqual(szColorR, ""))
			szColorR = "100"
		if (StringToInt(szColorG) < 100 || StrEqual(szColorG, ""))
			szColorG = "100"
		if (StringToInt(szColorB) < 100 || StrEqual(szColorB, ""))
			szColorB = "100"
		Format(szColor, sizeof(szColor), "%s %s %s", szColorR, szColorG, szColorB)
		
		DispatchKeyValue(entLightMelon, "model", "models/props_junk/watermelon01.mdl")
		DispatchKeyValue(entLightMelon, "rendermode", "5")
		DispatchKeyValue(entLightMelon, "renderamt", "150")
		DispatchKeyValue(entLightMelon, "renderfx", "15")
		DispatchKeyValue(entLightMelon, "rendercolor", szColor)
		
		int entLightDynamic = CreateEntityByName("light_dynamic")
		if (StringToInt(szRange) > 1500) {
			LM_PrintToChat(Client, "Max range is 1500!")
			return Plugin_Handled
		}
		if (StringToInt(szBrightness) > 7) {
			LM_PrintToChat(Client, "Max brightness is 7!")
			return Plugin_Handled
		}
		SetVariantString(szRange)
		AcceptEntityInput(entLightDynamic, "distance", -1)
		SetVariantString(szBrightness)
		AcceptEntityInput(entLightDynamic, "brightness", -1)
		SetVariantString("2")
		AcceptEntityInput(entLightDynamic, "style", -1)
		SetVariantString(szColor)
		AcceptEntityInput(entLightDynamic, "color", -1)
		
		DispatchSpawn(entLightMelon)
		TeleportEntity(entLightMelon, fAimPos, NULL_VECTOR, NULL_VECTOR)
		DispatchSpawn(entLightDynamic)
		TeleportEntity(entLightDynamic, fAimPos, NULL_VECTOR, NULL_VECTOR)
		
		Format(szNameMelon, sizeof(szNameMelon), "entLightDMelon%i", GetRandomInt(1000, 5000))
		DispatchKeyValue(entLightMelon, "targetname", szNameMelon)
		SetVariantString(szNameMelon)
		AcceptEntityInput(entLightDynamic, "setparent", -1)
		AcceptEntityInput(entLightDynamic, "turnon", Client, Client)
	} else
		RemoveEdict(entLightMelon)
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_ld", szArgs)
	return Plugin_Handled
}


public Action Command_AdminForceDeleteAll(Client, args) {
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !fda <userid>")
		return Plugin_Handled
	}
	
	char pla[33]
	GetCmdArg(1, pla, sizeof(pla))
	if (StrEqual(pla, "@all")) {
		for (int player = 1; player <= MaxClients; player++) {
			if (LM_IsClientValid(Client, player))
				FakeClientCommand(player, "sm_da")
		}
		return Plugin_Handled
	}
	
	FakeClientCommand(Client, "sm_cexec %s sm_da", pla)
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_fda", szArgs)
	return Plugin_Handled
}

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
	
	//if (GetCmdArgs() > 0)
	//	LM_PrintToChat(Client, "Don't use unneeded args in kill")
	
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
		
	} else if (StrEqual(szMapName, "rp_cityx_007")) {
		// To remove the fking timer that auto changes server name
		int entLogicTimer = -1
		while ((entLogicTimer = FindEntityByClassname(entLogicTimer , "logic_timer")) != -1)
			AcceptEntityInput(entLogicTimer, "kill", -1)
		ServerCommand("hostname %s", g_szHostName)
		ServerCommand("sm_future 1 \"exec server\"")
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

