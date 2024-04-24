#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>

new bool:g_bClientLang[MAXPLAYERS];
new Handle:g_hCookieClientLang;

new Handle:g_hWheelNameArray;
new Handle:g_hWheelModelPathArray;

public Plugin:myinfo = {
	name = "BuildMod - Editor",
	author = "LaZycAt, hjkwe654",
	description = "Edit props.",
	version = LAZMOD_VER,
	url = ""
};

public OnPluginStart() {	
	RegAdminCmd("sm_drop", Command_Drop, 0, "Drop a prop from sky.");
	RegAdminCmd("sm_dr", Command_Drop, 0, "Drop a prop from sky.");
	RegAdminCmd("sm_freeze", Command_Freeze, 0, "Freeze a prop.");
	RegAdminCmd("sm_f", Command_Freeze, 0, "Freeze a prop.");
	RegAdminCmd("sm_unfreeze", Command_UnFreeze, 0, "Unfreeze an entity.");
	RegAdminCmd("sm_uf", Command_UnFreeze, 0, "Unfreeze an entity.");
	RegAdminCmd("sm_ffreeze", Command_ForceFreeze, ADMFLAG_CUSTOM1, "ForceFreeze a prop.");
	RegAdminCmd("sm_unffreeze", Command_UnForceFreeze, ADMFLAG_CUSTOM1, "UnForceFreeze a prop.");
	RegAdminCmd("sm_mass", Command_SetMass, ADMFLAG_CUSTOM1, "Set a prop mass.");
	RegAdminCmd("sm_weld", Command_Weld, 0, "Weld your prop.");
	RegAdminCmd("sm_w", Command_Weld, 0, "Weld your prop.");
	RegAdminCmd("sm_wheel", Command_Wheel, 0, "Place a wheel on your entity.");
	RegAdminCmd("sm_wh", Command_Wheel, 0, "Place a wheel on your entity.");
	
	g_hCookieClientLang = RegClientCookie("cookie_BuildModClientLang", "BuildMod Client Language.", CookieAccess_Private);
	g_hWheelNameArray = CreateArray(32, 32);		// Max Wheel List is 32
	g_hWheelModelPathArray = CreateArray(128, 32);	// Max Wheel List is 32
	ReadWheels();
}

public Action:OnClientCommand(Client, args) {
	if (Client > 0) {
		if (LM_IsClientValid(Client, Client)) {
			new String:Lang[8];
			GetClientCookie(Client, g_hCookieClientLang, Lang, sizeof(Lang));
			if (StrEqual(Lang, "1"))
				g_bClientLang[Client] = true;
			else
				g_bClientLang[Client] = false;
		}
	}
}

public Action:Command_SetMass(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: !mass <重量>");
			LM_PrintToChat(Client, "例: !mass 100");
		} else {
			LM_PrintToChat(Client, "Usage: !mass <amount>");
			LM_PrintToChat(Client, "Ex: !mass 100");
		}
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {		
		decl String:szAmount[16];
		GetCmdArg(1, szAmount, sizeof(szAmount));
		
		if (StringToInt(szAmount) < 1){
			if (g_bClientLang[Client])
				LM_PrintToChat(Client, "重量不能低於 0");
			else
				LM_PrintToChat(Client, "The mass amount must be higher than 0");
			return Plugin_Handled;
		}
		
		if(Phys_IsPhysicsObject(iEntity)) {
			new Float:fMass = StringToFloat(szAmount);
			Phys_SetMass(iEntity, fMass);
		} else
			LM_PrintToChat(Client, "This isn't a physics prop!");
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_del", szArgs);
	return Plugin_Handled;
}

public Action:Command_Drop(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity))
		FakeClientCommand(Client, "e_drop");
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_del", szArgs);
	return Plugin_Handled;
}

public Action:Command_Freeze(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled;
	
	if (!IsPlayerAlive(Client)) {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "死亡狀態下無法使用此指令.");
		else
			LM_PrintToChat(Client, "You cannot use the command if you dead.");
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity, true)) {
		if(Phys_IsPhysicsObject(iEntity)) {
			Phys_EnableMotion(iEntity, false);
			if (g_bClientLang[Client])
				LM_PrintToChat(Client, "固定物件");
			else
				LM_PrintToChat(Client, "Freezed Prop");
		} else
			LM_PrintToChat(Client, "This isn't a physics prop!");
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_del", szArgs);
	return Plugin_Handled;
}

public Action:Command_UnFreeze(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity, true)) {
		if(Phys_IsPhysicsObject(iEntity)) {
			Phys_EnableMotion(iEntity, true);
			Phys_Sleep(iEntity);
			if (g_bClientLang[Client])
				LM_PrintToChat(Client, "解除固定物件");
			else
				LM_PrintToChat(Client, "UnFreezed Prop");
		} else
			LM_PrintToChat(Client, "This isn't a physics prop!");
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_del", szArgs);
	return Plugin_Handled;
}

public Action:Command_ForceFreeze(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		SetEntityMoveType(iEntity, MOVETYPE_NONE);
		if(Phys_IsPhysicsObject(iEntity)) {
			Phys_EnableMotion(iEntity, false);
			if (g_bClientLang[Client])
				LM_PrintToChat(Client, "強制固定物件");
			else
				LM_PrintToChat(Client, "ForceFreezed Prop");
		} else
			LM_PrintToChat(Client, "This isn't a physics prop!");
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_forcefreeze", szArgs);
	return Plugin_Handled;
}

public Action:Command_UnForceFreeze(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		SetEntityMoveType(iEntity, MOVETYPE_VPHYSICS);
		if(Phys_IsPhysicsObject(iEntity)) {
			Phys_EnableMotion(iEntity, true);
			Phys_Sleep(iEntity);
			if (g_bClientLang[Client])
				LM_PrintToChat(Client, "解除強制固定物件");
			else
				LM_PrintToChat(Client, "UnFreezed Prop");
		} else
			LM_PrintToChat(Client, "This isn't a physics prop!");
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_unforcefreeze", szArgs);
	return Plugin_Handled;
}

public Action:Command_Weld(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity, true)) {
		static iTempEnt = 0;
		if (!iTempEnt) {
			if (IsValidEntity(iEntity) && Phys_IsPhysicsObject(iEntity)) {
				iTempEnt = iEntity;
				if (g_bClientLang[Client])
					LM_PrintToChat(Client, "選擇了第一個物件 %d", iTempEnt);
				else
					LM_PrintToChat(Client, "Set reference prop to %d", iTempEnt);
			} else
				LM_PrintToChat(Client, "Target prop invalid, try again.");
				
		} else {
			if (IsValidEntity(iEntity) && Phys_IsPhysicsObject(iEntity) && IsValidEntity(iTempEnt) && Phys_IsPhysicsObject(iTempEnt)) {
				Phys_CreateFixedConstraint(iTempEnt, iEntity, INVALID_HANDLE);
				if (g_bClientLang[Client])
					LM_PrintToChat(Client, "接合了物件: %d 和 %d.", iTempEnt, iEntity);
				else
					LM_PrintToChat(Client, "Welded props %d and %d, reset reference prop.", iTempEnt, iEntity);
			} else
				LM_PrintToChat(Client, "Target prop invalid, reset reference prop.");
				
			iTempEnt = 0;
		}
	}
	return Plugin_Handled;
}

public Action:Command_Wheel(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: !wheel/!wh <輪子編號>");
			LM_PrintToChat(Client, "例: !wheel 3");
		} else {
			LM_PrintToChat(Client, "Usage: !wheel/!wh <Wheel Index>");
			LM_PrintToChat(Client, "Ex: !wheel 3");
		}
		return Plugin_Handled;
	}
	
	decl String:szWheelName[33], String:szModelPath[128];
	GetCmdArg(1, szWheelName, sizeof(szWheelName));
	
	new IndexInArray = FindStringInArray(g_hWheelNameArray, szWheelName);
	if (IndexInArray != -1) {
		new Float:eyePos[3];
		new Float:eyeAng[3];
		
		GetClientEyePosition(Client, eyePos);
		GetClientEyeAngles(Client, eyeAng);
		
		new Handle:trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SHOT, RayType_Infinite, TraceEntityFilterOnlyVPhysics);
		
		if (TR_DidHit(trace) && TR_GetEntityIndex(trace)) {
			new entIndex = TR_GetEntityIndex(trace);
			if (LM_IsEntityOwner(Client, entIndex)) {	
				new Obj_Wheel = CreateEntityByName("prop_physics_override");
				if (LM_SetEntityOwner(Obj_Wheel, Client)) {
					new Float:hitPos[3];
					new Float:hitNormal[3];
					TR_GetEndPosition(hitPos, trace);
					TR_GetPlaneNormal(trace, hitNormal);
					
					GetArrayString(g_hWheelModelPathArray, IndexInArray, szModelPath, sizeof(szModelPath));
					
					if (!IsModelPrecached(szModelPath))
						PrecacheModel(szModelPath);
					
					DispatchKeyValue(Obj_Wheel, "model", szModelPath);
					DispatchKeyValue(Obj_Wheel, "spawnflags", "256");
					DispatchKeyValueFloat(Obj_Wheel, "physdamagescale", 0.0);
					DispatchKeyValueFloat(Obj_Wheel, "ExplodeDamage", 0.0);
					DispatchKeyValueFloat(Obj_Wheel, "ExplodeRadius", 0.0);
					
					DispatchSpawn(Obj_Wheel);
					ActivateEntity(Obj_Wheel);
					
					new Float:surfaceAng[3];					
					GetVectorAngles(hitNormal, surfaceAng);
					
					new Float:wheelCenter[3]; // Should be calculating the width of the model for this.
					new Float:vecToAdd[3];
					
					vecToAdd[0] = hitNormal[0];
					vecToAdd[1] = hitNormal[1];
					vecToAdd[2] = hitNormal[2];
					
					switch(StringToInt(szWheelName)) {
						case 1:
							ScaleVector(vecToAdd, 5.0);
						case 2:
							ScaleVector(vecToAdd, 10.0);
						case 3:
							ScaleVector(vecToAdd, 7.5);
						case 4:
							ScaleVector(vecToAdd, 12.5);
						case 5:
							ScaleVector(vecToAdd, 11.0);
						case 6:
							ScaleVector(vecToAdd, 40.0);
						case 7:
							ScaleVector(vecToAdd, 40.0);
					}
					
					AddVectors(hitPos, vecToAdd, wheelCenter);
					TeleportEntity(Obj_Wheel, wheelCenter, surfaceAng, NULL_VECTOR);
					
					Phys_CreateHingeConstraint(entIndex, Obj_Wheel, INVALID_HANDLE, hitPos, hitNormal);
					if (g_bClientLang[Client])
						LM_PrintToChat(Client, "在目標上新增了輪子");
					else
						LM_PrintToChat(Client, "Added wheel to target");
				} else
					RemoveEdict(Obj_Wheel);
			}
		} else {
			if (g_bClientLang[Client])
				LM_PrintToChat(Client, "請瞄準一個物件.");
			else
				LM_PrintToChat(Client, "Target not found.");
		}
		
		CloseHandle(trace);
	} else {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "輪子編號不存在.");
		else
			LM_PrintToChat(Client, "Wheel not found.");
	}
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_wheel", szArgs);
	return Plugin_Handled;
}

public bool:TraceEntityFilterOnlyVPhysics(entity, contentsMask) {
    return ((entity > MaxClients) && Phys_IsPhysicsObject(entity));
}

ReadWheels() {
	new String:szFile[255];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/buildmod/wheels.ini");
	
	new Handle:iFile = OpenFile(szFile, "rt");
	if (iFile == INVALID_HANDLE)
		return;
	
	new iCountWheels = 0;
	while (!IsEndOfFile(iFile))
	{
		decl String:szLine[255];
		if (!ReadFileLine(iFile, szLine, sizeof(szLine)))
			break;
		
		/* 略過註解 */
		new iLen = strlen(szLine);
		new bool:bIgnore = false;
		
		for (new i = 0; i < iLen; i++) {
			if (bIgnore) {
				if (szLine[i] == '"')
					bIgnore = false;
			} else {
				if (szLine[i] == '"')
					bIgnore = true;
				else if (szLine[i] == ';') {
					szLine[i] = '\0';
					break;
				} else if (szLine[i] == '/' && i != iLen - 1 && szLine[i+1] == '/') {
					szLine[i] = '\0';
					break;
				}
			}
		}
		
		TrimString(szLine);
		
		if ((szLine[0] == '/' && szLine[1] == '/') || (szLine[0] == ';' || szLine[0] == '\0'))
			continue;
	
		ReadPropsLine(szLine, iCountWheels++);
	}
	CloseHandle(iFile);
}

ReadPropsLine(const String:szLine[], iCountWheels) {
	new String:szWheelName[64],String:szWheelPath[64];
	new idx, cur_idx;
	
	if ((cur_idx = BreakString(szLine, szWheelName, sizeof(szWheelName))) == -1)
		return;
	 
	SetArrayString(g_hWheelNameArray, iCountWheels, szWheelName);
	
	idx = cur_idx;
	
	/* Get Model File Path */
	if (cur_idx != -1) {
		BreakString(szLine[idx], szWheelPath, sizeof(szWheelPath));
		SetArrayString(g_hWheelModelPathArray, iCountWheels, szWheelPath);
	}
}
