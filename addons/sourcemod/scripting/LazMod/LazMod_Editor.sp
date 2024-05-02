

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>

#include <smlib>




float g_vAlignOrigin[MAXPLAYERS][3]

bool g_bExtendIsRunning[MAXPLAYERS]
int g_entExtendTarget[MAXPLAYERS]

int g_iCenterIsRunning[MAXPLAYERS]
int g_entCenterMain[MAXPLAYERS]
int g_entCenterFirst[MAXPLAYERS]


public Plugin myinfo = {
	name = "LazMod - Editor",
	author = "LaZycAt, hjkwe654",
	description = "Edit props.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {

	// Player commands
	{
		RegAdminCmd("sm_freeze", Command_Freeze, 0, "Freeze a prop.")
		RegAdminCmd("sm_unfreeze", Command_UnFreeze, 0, "Unfreeze a prop.")
		// RegAdminCmd("sm_ffreeze", Command_ForceFreeze, ADMFLAG_CUSTOM1, "ForceFreeze a prop.")
		// RegAdminCmd("sm_unffreeze", Command_UnForceFreeze, ADMFLAG_CUSTOM1, "UnForceFreeze a prop.")

		RegAdminCmd("sm_rotate", Command_Rotate, 0, "Rotate an entity.")
		RegAdminCmd("sm_angles", Command_SetAngles, 0, "Set the angles of a prop directly.")

		RegAdminCmd("sm_render", Command_Render, 0, "Render an entity.")
		RegAdminCmd("sm_color", Command_Color, 0, "Color a prop.")

		RegAdminCmd("sm_move", Command_Move, 0, "Move props.")
		RegAdminCmd("sm_align", Command_Align, 0, "Aligning props.")
		RegAdminCmd("sm_extend", Command_Extend, 0, "Create a third prop based on the position and angle of first two props.")
		RegAdminCmd("sm_center", Command_Center, 0, "Moves a prop to the exact middle of the other two props.")

		RegAdminCmd("sm_nobreak", Command_NoBreakProp, 0, "Set a prop wont break.")
		RegAdminCmd("sm_unnobreak", Command_UnNoBreakProp, 0, "Undo nobreak.")

		RegAdminCmd("sm_skin", Command_Skin, 0, "Change skin of a prop.")
		RegAdminCmd("sm_light", Command_LightDynamic, 0, "Create a dynamic light.")
		// RegAdminCmd("sm_drop", Command_Drop, 0, "Drop a prop from sky.") // TODO: SourceOP dead

		// RegAdminCmd("sm_stand", Command_Stand, 0, "Set the mass of a prop.")

		RegAdminCmd("sm_setmass", Command_SetMass, 0, "Set the mass of a prop.")
		// RegAdminCmd("sm_mass", Command_GetMass, 0, "Get the mass of a prop.")
		RegAdminCmd("sm_weld", Command_Weld, 0, "Weld a prop.")
	}

	// Admin commands
	{
		RegAdminCmd("sm_ent_fire", Command_EntFire, ADMFLAG_CHEATS, "Replicate the ent_fire.")
		RegAdminCmd("sm_getname", Command_EntGetName, ADMFLAG_CHEATS, "Aim on an entity to get its targetname and classname.")
		RegAdminCmd("sm_input", Command_EntInput, ADMFLAG_CHEATS, "Aim on an entity and call an input.")
		RegAdminCmd("sm_output", Command_EntOutput, ADMFLAG_CHEATS, "Aim on an entity and call an output or set a keyvalue.")
	}
	
	PrintToServer( "LazMod Editor loaded!" )
}

public Action Command_Render(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 3) {
		LM_PrintToChat(Client, "Usage: !color <R> <G> <B>")
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
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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

public Action Command_SetMass(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !mass <amount>")
		LM_PrintToChat(Client, "Ex: !mass 100")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp))
		return Plugin_Handled

	char szAmount[16]
	GetCmdArg(1, szAmount, sizeof(szAmount))
	
	// I think Source Engine itself already built-in this limit, but just in case
	if (StringToInt(szAmount) < 1)
		szAmount = "1"
	if (StringToInt(szAmount) > 50000)
		szAmount = "50000"
	
	if(Phys_IsPhysicsObject(entProp)) {
		float fMass = StringToFloat(szAmount)
		Phys_SetMass(entProp, fMass)
	} else
		LM_PrintToChat(Client, "This isn't a physics prop!")
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_mass", szArgs)
	return Plugin_Handled
}


public Action Command_NoBreakProp(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !angles <x> [y] [z]")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		float vEntityOrigin[3], vEntityAngle[3]
		vEntityAngle[0] = GetCmdArgFloat(1)
		vEntityAngle[1] = GetCmdArgFloat(2)
		vEntityAngle[2] = GetCmdArgFloat(3)
		
		GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", vEntityOrigin)
		
		TeleportEntity(entProp, vEntityOrigin, vEntityAngle, NULL_VECTOR)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_angles", szArgs)
	return Plugin_Handled
}

public Action Command_Align(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
		GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", g_vAlignOrigin[Client])
		LM_PrintToChat(Client, "Align set.")
	} else if (StrEqual(szMode[0], "x")) {
		fEntityOrigin[0] = g_vAlignOrigin[Client][0]
		TeleportEntity(entProp, fEntityOrigin, fEntityAngle, NULL_VECTOR)
	} else if (StrEqual(szMode[0], "y")) {
		fEntityOrigin[1] = g_vAlignOrigin[Client][1]
		TeleportEntity(entProp, fEntityOrigin, fEntityAngle, NULL_VECTOR)
	} else if (StrEqual(szMode[0], "z")) {
		fEntityOrigin[2] = g_vAlignOrigin[Client][2]
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
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
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
				g_entExtendTarget[plyClient] = entProp
				g_bExtendIsRunning[plyClient] = true
				LM_PrintToChat(plyClient, "Extend #1 set, use !ex again on #2 prop.")
			} else {
				char szModel[255]
				float fOriginProp1[3], fAngle[3], fOriginProp2[3], fOriginProp3[3]
				
				GetEntPropVector(g_entExtendTarget[plyClient], Prop_Data, "m_vecOrigin", fOriginProp1)
				GetEntPropVector(g_entExtendTarget[plyClient], Prop_Data, "m_angRotation", fAngle)
				GetEntPropString(g_entExtendTarget[plyClient], Prop_Data, "m_ModelName", szModel, sizeof(szModel))
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
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsEntityOwner(Client, entProp))
		return Plugin_Handled


	if (g_iCenterIsRunning[Client] == 1) {
		g_entCenterFirst[Client] = entProp
		g_iCenterIsRunning[Client] = 2
		LM_PrintToChat(Client, "Now select the third prop to finish.")

	} else if (g_iCenterIsRunning[Client] == 2) {
		float fAngleMain[3], fOriginMain[3], fOriginFirst[3], fOriginSecend[3]
		
		GetEntPropVector(g_entCenterMain[Client], Prop_Data, "m_angRotation", fAngleMain)
		GetEntPropVector(g_entCenterFirst[Client], Prop_Data, "m_vecOrigin", fOriginFirst)
		GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", fOriginSecend)
		
		for (int i = 0; i < 3; i++)
			fOriginMain[i] = (fOriginFirst[i] + fOriginSecend[i]) / 2
		
		TeleportEntity(g_entCenterMain[Client], fOriginMain, fAngleMain, NULL_VECTOR)
		g_iCenterIsRunning[Client] = 0

	} else {
		g_entCenterMain[Client] = entProp
		g_iCenterIsRunning[Client] = 1
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
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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

// TODO: SourceOP dead
public Action Command_Drop(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	// if (LM_IsEntityOwner(Client, entProp))
		// FakeClientCommand(Client, "e_drop")	// SourceOP Dead
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_drop", szArgs)
	return Plugin_Handled
}

public Action Command_Freeze(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled
	
	if (!IsPlayerAlive(Client)) {
		LM_PrintToChat(Client, "You cannot use the command while dead.")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp, true)) {
		if(Phys_IsPhysicsObject(entProp)) {
			Phys_EnableMotion(entProp, false)
		} else
			LM_PrintToChat(Client, "This isn't a physics prop!")
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_freeze", szArgs)
	return Plugin_Handled
}

public Action Command_UnFreeze(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp, true)) {
		if(Phys_IsPhysicsObject(entProp)) {
			Phys_EnableMotion(entProp, true)
			Phys_Sleep(entProp)
		} else
			LM_PrintToChat(Client, "This isn't a physics prop!")
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_unfreeze", szArgs)
	return Plugin_Handled
}

public Action Command_ForceFreeze(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		SetEntityMoveType(entProp, MOVETYPE_NONE)
		if(Phys_IsPhysicsObject(entProp)) {
			Phys_EnableMotion(entProp, false)
			LM_PrintToChat(Client, "ForceFreezed Prop")
		} else
			LM_PrintToChat(Client, "This isn't a physics prop!")
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_forcefreeze", szArgs)
	return Plugin_Handled
}

public Action Command_UnForceFreeze(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		SetEntityMoveType(entProp, MOVETYPE_VPHYSICS)
		if(Phys_IsPhysicsObject(entProp)) {
			Phys_EnableMotion(entProp, true)
			Phys_Sleep(entProp)
			LM_PrintToChat(Client, "UnFreezed Prop")
		} else
			LM_PrintToChat(Client, "This isn't a physics prop!")
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_unforcefreeze", szArgs)
	return Plugin_Handled
}

public Action Command_Weld(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp, true)) {
		static iTempEnt = 0
		if (!iTempEnt) {
			if (IsValidEntity(entProp) && Phys_IsPhysicsObject(entProp)) {
				iTempEnt = entProp
				LM_PrintToChat(Client, "Set reference prop to %d", iTempEnt)
			} else
				LM_PrintToChat(Client, "Target prop invalid, try again.")
				
		} else {
			if (IsValidEntity(entProp) && Phys_IsPhysicsObject(entProp) && IsValidEntity(iTempEnt) && Phys_IsPhysicsObject(iTempEnt)) {
				Phys_CreateFixedConstraint(iTempEnt, entProp, INVALID_HANDLE)
				LM_PrintToChat(Client, "Welded props %d and %d, reset reference prop.", iTempEnt, entProp)
			} else
				LM_PrintToChat(Client, "Target prop invalid, reset reference prop.")
				
			iTempEnt = 0
		}
	}
	return Plugin_Handled
}









public Action Command_EntFire(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 2) {
		LM_PrintToChat(plyClient, "Usage: !ent_fire <name> <input> [value] [delay]")
		return Plugin_Handled
	}
	
	char szName[32], szInput[32], szValue[64]
	float fDelay
	Handle hExcute

	GetCmdArg(1, szName, sizeof(szName))
	GetCmdArg(2, szInput, sizeof(szInput))
	GetCmdArg(3, szValue, sizeof(szValue))
	fDelay = GetCmdArgFloat(4)

	int iMaxEntities = GetMaxEntities()*2
	char szTargetName[32], szClassName[32]
	for (int entProp=0; entProp < iMaxEntities; entProp++) {

		if (!IsValidEntity(entProp))
			continue

		GetEntPropString(entProp, Prop_Data, "m_iName", szTargetName, sizeof(szTargetName));
		GetEntPropString(entProp, Prop_Data, "m_iClassname", szClassName, sizeof(szClassName));

		if (StrEqual(szTargetName, szName) || StrEqual(szClassName, szName)) {
			if (fDelay > 0) {
				CreateDataTimer(fDelay, Timer_EntFireDelay, hExcute)
				WritePackCell(hExcute, entProp)
				WritePackString(hExcute, szInput)
				WritePackCell(hExcute, plyClient)
				WritePackString(hExcute, szValue)
			} else {
				SetVariantString(szValue)
				AcceptEntityInput(entProp, szInput, entProp, plyClient, 0)
			}
			continue
		}
	}

	char szArgString[256]
	GetCmdArgString(szArgString, sizeof(szArgString))
	LM_LogCmd(plyClient, "sm_ent_fire", szArgString)
	return Plugin_Handled
}
public Action Timer_EntFireDelay(Handle Timer, Handle hExcute) {
	char szInput[255], szValue[25]
	int entProp, plyClient
	
	ResetPack(hExcute)
	entProp = ReadPackCell(hExcute)
	ReadPackString(hExcute, szInput, sizeof(szInput))
	plyClient = ReadPackCell(hExcute)
	ReadPackString(hExcute, szValue, sizeof(szValue))
	
	if (!IsValidEntity(entProp))
		return Plugin_Stop

	SetVariantString(szValue)
	AcceptEntityInput(entProp, szInput, entProp, plyClient, 0)
	
	return Plugin_Stop
}

public Action Command_EntGetName(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsEntityOwner(plyClient, entProp) && !LM_IsAdmin(plyClient)) {
		LM_PrintToChat(plyClient, "You can only use this command to your own props!")
		return Plugin_Handled
	}

	char szName[64]
	Entity_GetName(entProp, szName, sizeof(szName))
	LM_PrintToChat(plyClient, "Name/m_iName: %s", szName)
	Entity_GetClassName(entProp, szName, sizeof(szName))
	LM_PrintToChat(plyClient, "ClassName/m_iClassname: %s", szName)
	Entity_GetTargetName(entProp, szName, sizeof(szName))
	LM_PrintToChat(plyClient, "TargetName/m_target: %s", szName)

	char szArgString[256]
	GetCmdArgString(szArgString, sizeof(szArgString))
	LM_LogCmd(plyClient, "sm_getname", szArgString)
	return Plugin_Handled
}

public Action Command_EntInput(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !input <input> [value]")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsAdmin(plyClient)) {
		if (LM_IsPlayer(entProp))
			return Plugin_Handled
	}
	
	if (!LM_IsEntityOwner(plyClient, entProp) && !LM_IsAdmin(plyClient)) {
		LM_PrintToChat(plyClient, "You can only use this command to your own props!")
		return Plugin_Handled
	}

	char szInput[33], szValues[33]
	GetCmdArg(1, szInput, sizeof(szInput))
	GetCmdArg(2, szValues, sizeof(szValues))
	
	SetVariantString(szValues)
	AcceptEntityInput(entProp, szInput, entProp, plyClient, 0)
	

	char szArgString[256]
	GetCmdArgString(szArgString, sizeof(szArgString))
	LM_LogCmd(plyClient, "sm_input", szArgString)
	return Plugin_Handled
}

public Action Command_EntOutput(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 2) {
		LM_PrintToChat(plyClient, "Usage: !output <output> <value>")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsEntityOwner(plyClient, entProp) && !LM_IsAdmin(plyClient)) {
		LM_PrintToChat(plyClient, "You can only use this command to your own props!")
		return Plugin_Handled
	}

	char szKeys[33], szValues[33]
	GetCmdArg(1, szKeys, sizeof(szKeys))
	GetCmdArg(2, szValues, sizeof(szValues))
	
	DispatchKeyValue(entProp, szKeys, szValues)
	
	char szArgString[256]
	GetCmdArgString(szArgString, sizeof(szArgString))
	LM_LogCmd(plyClient, "sm_output", szArgString)
	return Plugin_Handled
}









