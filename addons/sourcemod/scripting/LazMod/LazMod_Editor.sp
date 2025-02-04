

#include <sourcemod>
#include <sdktools>

#include <vphysics>
#include <smlib>

#include <lazmod>




float g_vAlignOrigin[MAXPLAYERS][3]

int g_iCenterIsRunning[MAXPLAYERS]
int g_entCenterMain[MAXPLAYERS]
int g_entCenterFirst[MAXPLAYERS]

int g_entSetParent[MAXPLAYERS] = {-1,...}


public Plugin myinfo = {
	name = "LazMod - Editor",
	author = "LaZycAt, hjkwe654",
	description = "Everything that moves prop or modify prop.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {

	// Player commands
	{
		RegAdminCmd("sm_freezeprop", Command_FreezeProp, 0, "Freeze a prop.")
		RegAdminCmd("sm_unfreezeprop", Command_UnFreezeProp, 0, "Unfreeze a prop.")
		// RegAdminCmd("sm_ffreeze", Command_ForceFreeze, ADMFLAG_CUSTOM1, "ForceFreeze a prop.")
		// RegAdminCmd("sm_unffreeze", Command_UnForceFreeze, ADMFLAG_CUSTOM1, "UnForceFreeze a prop.")

		RegAdminCmd("sm_rotate", Command_Rotate, 0, "Rotate a prop.")
		RegAdminCmd("sm_angles", Command_SetAngles, 0, "Set the angles of a prop directly.")
		RegAdminCmd("sm_stand", Command_Stand, 0, "Reset the angles of a prop.")

		RegAdminCmd("sm_fx", Command_Renderfx, 0, "Change the render effect of a prop.")
		RegAdminCmd("sm_color", Command_RenderColor, 0, "Change the color of a prop.")
		RegAdminCmd("sm_alpha", Command_RenderAlpha, 0, "Change the alpha of a prop.")

		RegAdminCmd("sm_move", Command_Move, 0, "Moves a props by coordinates.")
		RegAdminCmd("sm_align", Command_Align, 0, "Align a prop using the position of another prop as a reference.")
		RegAdminCmd("sm_center", Command_Center, 0, "Moves a prop to the exact middle of the other two props.")

		RegAdminCmd("sm_nobreak", Command_NoBreakProp, 0, "Set a prop wont break.")
		RegAdminCmd("sm_unnobreak", Command_UnNoBreakProp, 0, "Undo nobreak.")

		RegAdminCmd("sm_skin", Command_Skin, 0, "Change skin of a prop (not every prop have multiple skins).")
		RegAdminCmd("sm_light", Command_LightDynamic, 0, "Create a dynamic light.")
		// RegAdminCmd("sm_drop", Command_Drop, 0, "Drop a prop from sky.")


		RegAdminCmd("sm_setmass", Command_SetMass, 0, "Set the mass of a prop.")
		RegAdminCmd("sm_scale", Command_SetModelScale, 0, "Set the model scale of a prop.")
		
		RegAdminCmd("sm_weld", Command_Weld, 0, "Weld a prop.")

		RegAdminCmd("sm_setparent", Command_SetParent, 0, "Set parent.")
		RegAdminCmd("sm_parent", Command_DoParent, 0, "Parent a prop.")
		RegAdminCmd("sm_clearparent", Command_ClearParent, 0, "Clear parent a prop.")
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

public Action Command_FreezeProp(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient))
		return Plugin_Handled
	
	if (!IsPlayerAlive(plyClient)) {
		LM_PrintToChat(plyClient, "You cannot use the command while dead.")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp, true)) {
		if(Phys_IsPhysicsObject(entProp)) {
			Phys_EnableMotion(entProp, false)
		} else
			LM_PrintToChat(plyClient, "This isn't a physics prop!")
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_freeze", szArgs)
	return Plugin_Handled
}

public Action Command_UnFreezeProp(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp, true)) {
		if(Phys_IsPhysicsObject(entProp)) {
			Phys_EnableMotion(entProp, true)
			Phys_Sleep(entProp)
		} else
			LM_PrintToChat(plyClient, "This isn't a physics prop!")
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_unfreeze", szArgs)
	return Plugin_Handled
}

public Action Command_ForceFreeze(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		SetEntityMoveType(entProp, MOVETYPE_NONE)
		if(Phys_IsPhysicsObject(entProp)) {
			Phys_EnableMotion(entProp, false)
			LM_PrintToChat(plyClient, "ForceFreezed Prop")
		} else
			LM_PrintToChat(plyClient, "This isn't a physics prop!")
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_forcefreeze", szArgs)
	return Plugin_Handled
}

public Action Command_UnForceFreeze(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		SetEntityMoveType(entProp, MOVETYPE_VPHYSICS)
		if(Phys_IsPhysicsObject(entProp)) {
			Phys_EnableMotion(entProp, true)
			Phys_Sleep(entProp)
			LM_PrintToChat(plyClient, "UnFreezed Prop")
		} else
			LM_PrintToChat(plyClient, "This isn't a physics prop!")
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_unforcefreeze", szArgs)
	return Plugin_Handled
}




public Action Command_Rotate(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !rotate <x> [y] [z]")
		LM_PrintToChat(plyClient, "Ex: !rotate 0 90 0")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		float vPropAngles[3], vAddAngles[3], vNewAngles[3]
		vAddAngles[0] = GetCmdArgFloat(1)
		vAddAngles[1] = GetCmdArgFloat(2)
		vAddAngles[2] = GetCmdArgFloat(3)
		
		LM_GetEntAngles(entProp, vPropAngles)
		AddVectors(vPropAngles, vAddAngles, vNewAngles)
		
		TeleportEntity(entProp, NULL_VECTOR, vNewAngles, NULL_VECTOR)
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_rotate", szArgs)
	return Plugin_Handled
}

public Action Command_SetAngles(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !angles <x> [y] [z]")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		float vEntityAngle[3]
		vEntityAngle[0] = GetCmdArgFloat(1)
		vEntityAngle[1] = GetCmdArgFloat(2)
		vEntityAngle[2] = GetCmdArgFloat(3)
		
		TeleportEntity(entProp, NULL_VECTOR, vEntityAngle, NULL_VECTOR)
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_angles", szArgs)
	return Plugin_Handled
}

public Action Command_Stand(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		float vEntityAngle[3] = {0.0,...}
		TeleportEntity(entProp, NULL_VECTOR, vEntityAngle, NULL_VECTOR)
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_stand", szArgs)
	return Plugin_Handled
}





public Action Command_Renderfx(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !fx <fx>")
		LM_PrintToChat(plyClient, "Ex. Flashing effect: !fx 4")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		char szRenderFX[20]

		GetCmdArg(1, szRenderFX, sizeof(szRenderFX))
		
		DispatchKeyValue(entProp, "rendermode", "5")
		DispatchKeyValue(entProp, "renderfx", szRenderFX)
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_fx", szArgs)
	return Plugin_Handled
}

public Action Command_RenderColor(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !color <R> [G] [B]")
		LM_PrintToChat(plyClient, "Ex: Green color: !color 0 255 0")
		
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		char szColorRGB[20][3], szColors[33]
		GetCmdArg(1, szColorRGB[0], sizeof(szColorRGB))
		GetCmdArg(2, szColorRGB[1], sizeof(szColorRGB))
		GetCmdArg(3, szColorRGB[2], sizeof(szColorRGB))
		
		Format(szColors, sizeof(szColors), "%s %s %s", szColorRGB[0], szColorRGB[1], szColorRGB[2])
		DispatchKeyValue(entProp, "rendermode", "5")
		DispatchKeyValue(entProp, "rendercolor", szColors)
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_color", szArgs)
	return Plugin_Handled
}

public Action Command_RenderAlpha(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !alpha <amount>")
		LM_PrintToChat(plyClient, "Ex: Translucent: !alpha 150")
		
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		char szAlpha[4]
		GetCmdArg(1, szAlpha, sizeof(szAlpha))
		
		DispatchKeyValue(entProp, "rendermode", "5")
		DispatchKeyValue(entProp, "renderamt", szAlpha)
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_color", szArgs)
	return Plugin_Handled
}





public Action Command_Move(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !move <x> [y] [z]")
		LM_PrintToChat(plyClient, "Ex, move up 50: !move 0 0 50")

		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		float fEntOrigin[3], fArgMove[3]
		fArgMove[0] = GetCmdArgFloat(1)
		fArgMove[1] = GetCmdArgFloat(2)
		fArgMove[2] = GetCmdArgFloat(3)
		
		LM_GetEntOrigin(entProp, fEntOrigin)
		
		AddVectors(fArgMove, fArgMove, fEntOrigin)

		TeleportEntity(entProp, fEntOrigin, NULL_VECTOR, NULL_VECTOR)
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_move", szArgs)
	return Plugin_Handled
}

public Action Command_Align(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !align <mode>")
		LM_PrintToChat(plyClient, "!align set = Select the prop to be alignment refer")
		LM_PrintToChat(plyClient, "!align x  = Align the aimed prop with X coord")
		LM_PrintToChat(plyClient, "!align y  = Align the aimed prop with Y coord")
		LM_PrintToChat(plyClient, "!align z  = Align the aimed prop with Z coord")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsEntOwner(plyClient, entProp))
		return Plugin_Handled
	
	char szMode[5]
	float fEntityAngle[3], fEntityOrigin[3]
	GetCmdArg(1, szMode, sizeof(szMode))
	
	LM_GetEntOrigin(entProp, fEntityOrigin)
	LM_GetEntAngles(entProp, fEntityAngle)

	if (StrEqual(szMode[0], "set") || StrEqual(szMode[0], "s")) {
		LM_GetEntOrigin(entProp, g_vAlignOrigin[plyClient])
		LM_PrintToChat(plyClient, "Align set.")
	} else if (StrEqual(szMode[0], "x")) {
		fEntityOrigin[0] = g_vAlignOrigin[plyClient][0]
		TeleportEntity(entProp, fEntityOrigin, fEntityAngle, NULL_VECTOR)
	} else if (StrEqual(szMode[0], "y")) {
		fEntityOrigin[1] = g_vAlignOrigin[plyClient][1]
		TeleportEntity(entProp, fEntityOrigin, fEntityAngle, NULL_VECTOR)
	} else if (StrEqual(szMode[0], "z")) {
		fEntityOrigin[2] = g_vAlignOrigin[plyClient][2]
		TeleportEntity(entProp, fEntityOrigin, fEntityAngle, NULL_VECTOR)
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_align", szArgs)
	return Plugin_Handled
}

public Action Command_Center(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsEntOwner(plyClient, entProp))
		return Plugin_Handled


	if (g_iCenterIsRunning[plyClient] == 1) {
		g_entCenterFirst[plyClient] = entProp
		g_iCenterIsRunning[plyClient] = 2
		LM_PrintToChat(plyClient, "Now select the third prop to finish.")

	} else if (g_iCenterIsRunning[plyClient] == 2) {
		float fAngleMain[3], fOriginMain[3], fOriginFirst[3], fOriginSecend[3]
		
		LM_GetEntAngles(g_entCenterMain[plyClient], fAngleMain)
		LM_GetEntOrigin(g_entCenterFirst[plyClient], fOriginFirst)
		LM_GetEntOrigin(entProp, fOriginSecend)
		
		for (int i = 0; i < 3; i++)
			fOriginMain[i] = (fOriginFirst[i] + fOriginSecend[i]) / 2
		
		TeleportEntity(g_entCenterMain[plyClient], fOriginMain, fAngleMain, NULL_VECTOR)
		g_iCenterIsRunning[plyClient] = 0

	} else {
		g_entCenterMain[plyClient] = entProp
		g_iCenterIsRunning[plyClient] = 1
		LM_PrintToChat(plyClient, "The prop to be moved have been selected, now select the secend prop.")

	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_center", szArgs)
	return Plugin_Handled
}




public Action Command_NoBreakProp(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		SetVariantString("999999999")
		AcceptEntityInput(entProp, "sethealth", -1)
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_nobreak", szArgs)
	return Plugin_Handled
}

public Action Command_UnNoBreakProp(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		SetVariantString("50")
		AcceptEntityInput(entProp, "sethealth", -1)
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_unnobreak", szArgs)
	return Plugin_Handled
}

public Action Command_Skin(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !skin <number>")
		LM_PrintToChat(plyClient, "Notice: Not every model have multiple skins.")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsEntOwner(plyClient, entProp)) 
		return Plugin_Handled


	char szSkin[33]
	GetCmdArg(1, szSkin, sizeof(szSkin))
	
	SetVariantString(szSkin)
	AcceptEntityInput(entProp, "skin", entProp, plyClient, 0)
	
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_skin", szArgs)
	return Plugin_Handled
}

public Action Command_LightDynamic(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !ld <range> [R] [G] [B] [brightness]")
		return Plugin_Handled
	}
	
	int entLightMelon = CreateEntityByName("prop_physics_multiplayer")
	if (LM_SetEntOwner(entLightMelon, plyClient)) {
		char szColor[12]
		int iRange, iColorR, iColorG, iColorB, iBright 
		char szNameMelon[64]
		float vAimPos[3]
		iRange  = GetCmdArgInt(1)==0 ? 200 : GetCmdArgInt(1)
		iColorR = GetCmdArgInt(2)==0 ? 255 : GetCmdArgInt(2)
		iColorG = GetCmdArgInt(3)==0 ? 255 : GetCmdArgInt(3)
		iColorB = GetCmdArgInt(4)==0 ? 255 : GetCmdArgInt(4)
		iBright = GetCmdArgInt(5)==0 ? 3 : GetCmdArgInt(5)
		
		LM_ClientAimPos(plyClient, vAimPos)
		vAimPos[2] += 50
		
		if(!IsModelPrecached("models/props_junk/watermelon01.mdl"))
			PrecacheModel("models/props_junk/watermelon01.mdl")
		
		if (iRange < 10)	iRange = 10
		if (iRange > 1500)	iRange = 1500
		if (iColorR < 50)	iColorR = 50
		if (iColorR > 255)	iColorR = 255
		if (iColorG < 50)	iColorG = 50
		if (iColorB < 50)	iColorB = 50
		if (iBright < 1)	iBright = 1
		if (iBright > 7)	iBright = 7

		Format(szColor, sizeof(szColor), "%d %d %d", iColorR, iColorG, iColorB)
		
		DispatchKeyValue(entLightMelon, "model", "models/props_junk/watermelon01.mdl")
		DispatchKeyValue(entLightMelon, "rendermode", "5")
		DispatchKeyValue(entLightMelon, "renderamt", "150")
		DispatchKeyValue(entLightMelon, "renderfx", "15")
		DispatchKeyValue(entLightMelon, "rendercolor", szColor)
		
		int entLightDynamic = CreateEntityByName("light_dynamic")
		SetVariantInt(iRange)
		AcceptEntityInput(entLightDynamic, "distance", -1)
		SetVariantInt(iBright)
		AcceptEntityInput(entLightDynamic, "brightness", -1)
		SetVariantString("2")
		AcceptEntityInput(entLightDynamic, "style", -1)
		SetVariantString(szColor)
		AcceptEntityInput(entLightDynamic, "color", -1)
		
		DispatchSpawn(entLightMelon)
		TeleportEntity(entLightMelon, vAimPos, NULL_VECTOR, NULL_VECTOR)
		DispatchSpawn(entLightDynamic)
		TeleportEntity(entLightDynamic, vAimPos, NULL_VECTOR, NULL_VECTOR)
		
		Format(szNameMelon, sizeof(szNameMelon), "entLightDMelon%i", GetRandomInt(1000, 5000))
		DispatchKeyValue(entLightMelon, "targetname", szNameMelon)
		SetVariantString(szNameMelon)
		AcceptEntityInput(entLightDynamic, "setparent", -1)
		AcceptEntityInput(entLightDynamic, "turnon", plyClient, plyClient)
	} else
		RemoveEdict(entLightMelon)
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_light", szArgs)
	return Plugin_Handled
}




public Action Command_SetMass(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !setmass <amount>")
		LM_PrintToChat(plyClient, "Ex: !setmass 100")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled

	if(!Phys_IsPhysicsObject(entProp)) {
		LM_PrintToChat(plyClient, "This isn't a physics prop!")
		return Plugin_Handled
	}
	
	
	if (!LM_IsEntOwner(plyClient, entProp))
		return Plugin_Handled

	float fAmount = GetCmdArgFloat(1)
	
	// I think Source Engine itself already built-in this limit, but just in case
	if (fAmount < 1)
		fAmount = 1.0
	else if (fAmount > 50000)
		fAmount = 50000.0
	
	Phys_SetMass(entProp, fAmount)

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_setmass", szArgs)
	return Plugin_Handled
}


public Action Command_SetModelScale(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !scale <amount>")
		LM_PrintToChat(plyClient, "Ex: !scale 2")
		LM_PrintToChat(plyClient, "warning: Command still wip")
		return Plugin_Handled
	}
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if(!Phys_IsPhysicsObject(entProp)) {
		LM_PrintToChat(plyClient, "This isn't a physics prop!")
		return Plugin_Handled
	}
	
	LM_PrintToChat(plyClient, "1")
	if (!LM_IsEntOwner(plyClient, entProp))
		return Plugin_Handled

	float fAmount = GetCmdArgFloat(1)
	
	
	// I think Source Engine itself already built-in this limit, but just in case
	if (fAmount < 0.1)
		fAmount = 0.1
	if (fAmount > 5.0)
		fAmount = 5.0
	
	// TODO: HOW???
	float vMins[3], vMaxs[3]
	// Entity_GetMinSize(entProp, vMins)
	// Entity_GetMaxSize(entProp, vMaxs)
	GetEntPropVector(entProp, Prop_Send, "m_collisionMins", vMins)
	GetEntPropVector(entProp, Prop_Send, "m_collisionMaxs", vMaxs)
	LM_PrintToChat(plyClient, "%f %f %f - %f %f %f", vMins[0], vMins[1], vMins[2], vMaxs[0], vMaxs[1], vMaxs[2])
	ScaleVector(vMins, fAmount)
	ScaleVector(vMaxs, fAmount)
	LM_PrintToChat(plyClient, "%f %f %f - %f %f %f", vMins[0], vMins[1], vMins[2], vMaxs[0], vMaxs[1], vMaxs[2])
	// Entity_SetMinMaxSize(entProp, vMins, vMaxs)
	DispatchKeyValueFloat(entProp, "modelscale", fAmount)

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_scale", szArgs)
	return Plugin_Handled
}




// SOURCEOP: sm_drop
public Action Command_Drop(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	// if (LM_IsEntOwner(Client, entProp))
		// FakeClientCommand(Client, "e_drop")	// SourceOP Dead
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_drop", szArgs)
	return Plugin_Handled
}

public Action Command_Weld(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		static iTempEnt = 0
		if (!iTempEnt) {
			if (IsValidEntity(entProp) && Phys_IsPhysicsObject(entProp)) {
				iTempEnt = entProp
				LM_PrintToChat(plyClient, "Set reference prop to %d", iTempEnt)
			} else
				LM_PrintToChat(plyClient, "Target prop invalid, try again.")
				
		} else {
			if (IsValidEntity(entProp) && Phys_IsPhysicsObject(entProp) && IsValidEntity(iTempEnt) && Phys_IsPhysicsObject(iTempEnt)) {
				Phys_CreateFixedConstraint(iTempEnt, entProp, INVALID_HANDLE)
				LM_PrintToChat(plyClient, "Welded props %d and %d, reset reference prop.", iTempEnt, entProp)
			} else
				LM_PrintToChat(plyClient, "Target prop invalid, reset reference prop.")
				
			iTempEnt = 0
		}
	}

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_weld", szArgs)
	return Plugin_Handled
}

public Action Command_SetParent(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		g_entSetParent[plyClient] = entProp
	}

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_setparent", szArgs)
	return Plugin_Handled
}

public Action Command_DoParent(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		if (!IsValidEntity(g_entSetParent[plyClient])) {
			LM_PrintToChat(plyClient, "You have to !setparent on a target prop first!")
			return Plugin_Handled
		}
		if (entProp == g_entSetParent[plyClient]) {
			LM_PrintToChat(plyClient, "You cannot parent to same prop itself, !setparent on another prop!")
			return Plugin_Handled
		}

		char szRandName[16]
		Format(szRandName, sizeof(szRandName), "parenttarget%d", GetRandomInt(1000,5000))
		DispatchKeyValue(g_entSetParent[plyClient], "targetname", szRandName)

		SetVariantString(szRandName)
		AcceptEntityInput(entProp, "SetParent")
	}

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_parent", szArgs)
	return Plugin_Handled
}

public Action Command_ClearParent(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntOwner(plyClient, entProp)) {
		SetVariantString("")
		AcceptEntityInput(entProp, "ClearParent")
	}

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_clearparent", szArgs)
	return Plugin_Handled
}








// TODO: Add !activator? !self, !picker
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

		LM_GetEntTargetName(entProp, szTargetName, sizeof(szTargetName))
		LM_GetEntClassname(entProp, szClassName, sizeof(szClassName))

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
	
	if (!LM_IsEntOwner(plyClient, entProp) && !LM_IsClientAdmin(plyClient)) {
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
	
	if (!LM_IsClientAdmin(plyClient)) {
		if (LM_IsEntPlayer(entProp))
			return Plugin_Handled
	}
	
	if (!LM_IsEntOwner(plyClient, entProp) && !LM_IsClientAdmin(plyClient)) {
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
	
	if (!LM_IsEntOwner(plyClient, entProp) && !LM_IsClientAdmin(plyClient)) {
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









