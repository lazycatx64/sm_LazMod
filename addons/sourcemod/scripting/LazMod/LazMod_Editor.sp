

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>




Handle g_hWheelNameArray
Handle g_hWheelModelPathArray

public Plugin myinfo = {
	name = "LazMod - Editor",
	author = "LaZycAt, hjkwe654",
	description = "Edit props.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {	
	// RegAdminCmd("sm_drop", Command_Drop, 0, "Drop a prop from sky.") // TODO: SourceOP dead
	RegAdminCmd("sm_freeze", Command_Freeze, 0, "Freeze a prop.")
	RegAdminCmd("sm_unfreeze", Command_UnFreeze, 0, "Unfreeze a prop.")
	// RegAdminCmd("sm_ffreeze", Command_ForceFreeze, ADMFLAG_CUSTOM1, "ForceFreeze a prop.")
	// RegAdminCmd("sm_unffreeze", Command_UnForceFreeze, ADMFLAG_CUSTOM1, "UnForceFreeze a prop.")
	RegAdminCmd("sm_mass", Command_SetMass, 0, "Set the mass of a prop.")
	RegAdminCmd("sm_weld", Command_Weld, 0, "Weld a prop.")
	RegAdminCmd("sm_wheel", Command_Wheel, 0, "Place a wheel on your prop.")
	
	g_hWheelNameArray = CreateArray(32, 32);		// Max Wheel List is 32
	g_hWheelModelPathArray = CreateArray(128, 32);	// Max Wheel List is 32
	ReadWheels()
	
	PrintToServer( "LazMod Editor loaded!" )
}

public Action Command_SetMass(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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


// TODO: SourceOP dead
public Action Command_Drop(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
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

public Action Command_Wheel(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !wheel <type>")
		LM_PrintToChat(Client, "Ex: !wheel 3")
		
		return Plugin_Handled
	}
	
	char szWheelName[33], szModelPath[128]
	GetCmdArg(1, szWheelName, sizeof(szWheelName))
	
	new IndexInArray = FindStringInArray(g_hWheelNameArray, szWheelName)
	if (IndexInArray != -1) {
		float eyePos[3]
		float eyeAng[3]
		
		GetClientEyePosition(Client, eyePos)
		GetClientEyeAngles(Client, eyeAng)
		
		Handle trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SHOT, RayType_Infinite, TraceEntityFilterOnlyVPhysics)
		
		if (TR_DidHit(trace) && TR_GetEntityIndex(trace)) {
			int entIndex = TR_GetEntityIndex(trace)
			if (LM_IsEntityOwner(Client, entIndex)) {	
				int entWheel = CreateEntityByName("prop_physics_override")
				if (LM_SetEntityOwner(entWheel, Client)) {
					float hitPos[3]
					float hitNormal[3]
					TR_GetEndPosition(hitPos, trace)
					TR_GetPlaneNormal(trace, hitNormal)
					
					GetArrayString(g_hWheelModelPathArray, IndexInArray, szModelPath, sizeof(szModelPath))
					
					if (!IsModelPrecached(szModelPath))
						PrecacheModel(szModelPath)
					
					DispatchKeyValue(entWheel, "model", szModelPath)
					DispatchKeyValue(entWheel, "spawnflags", "256")
					DispatchKeyValueFloat(entWheel, "physdamagescale", 0.0)
					DispatchKeyValueFloat(entWheel, "ExplodeDamage", 0.0)
					DispatchKeyValueFloat(entWheel, "ExplodeRadius", 0.0)
					
					DispatchSpawn(entWheel)
					ActivateEntity(entWheel)
					
					float surfaceAng[3];					
					GetVectorAngles(hitNormal, surfaceAng)
					
					float wheelCenter[3]; // Should be calculating the width of the model for this.
					float vecToAdd[3]
					
					vecToAdd[0] = hitNormal[0]
					vecToAdd[1] = hitNormal[1]
					vecToAdd[2] = hitNormal[2]
					
					switch(StringToInt(szWheelName)) {
						case 1:
							ScaleVector(vecToAdd, 5.0)
						case 2:
							ScaleVector(vecToAdd, 10.0)
						case 3:
							ScaleVector(vecToAdd, 7.5)
						case 4:
							ScaleVector(vecToAdd, 12.5)
						case 5:
							ScaleVector(vecToAdd, 11.0)
						case 6:
							ScaleVector(vecToAdd, 40.0)
						case 7:
							ScaleVector(vecToAdd, 40.0)
					}
					
					AddVectors(hitPos, vecToAdd, wheelCenter)
					TeleportEntity(entWheel, wheelCenter, surfaceAng, NULL_VECTOR)
					
					Phys_CreateHingeConstraint(entIndex, entWheel, INVALID_HANDLE, hitPos, hitNormal)
					LM_PrintToChat(Client, "Added wheel to target")
				} else
					RemoveEdict(entWheel)
			}
		} else {
			LM_PrintToChat(Client, "Target not found.")
		}
		
		CloseHandle(trace)
	} else {
		LM_PrintToChat(Client, "Wheel not found.")
	}
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_wheel", szArgs)
	return Plugin_Handled
}

public bool TraceEntityFilterOnlyVPhysics(entity, contentsMask) {
    return ((entity > MaxClients) && Phys_IsPhysicsObject(entity))
}

ReadWheels() {
	char szFile[255]
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/lazmod/wheels.ini")
	
	Handle iFile = OpenFile(szFile, "rt")
	if (iFile == INVALID_HANDLE)
		return
	
	new iCountWheels = 0
	while (!IsEndOfFile(iFile))
	{
		char szLine[255]
		if (!ReadFileLine(iFile, szLine, sizeof(szLine)))
			break
		
		/* 略過註解 */
		new iLen = strlen(szLine)
		bool bIgnore = false
		
		for (int i = 0; i < iLen; i++) {
			if (bIgnore) {
				if (szLine[i] == '"')
					bIgnore = false
			} else {
				if (szLine[i] == '"')
					bIgnore = true
				else if (szLine[i] == ';') {
					szLine[i] = '\0'
					break
				} else if (szLine[i] == '/' && i != iLen - 1 && szLine[i+1] == '/') {
					szLine[i] = '\0'
					break
				}
			}
		}
		
		TrimString(szLine)
		
		if ((szLine[0] == '/' && szLine[1] == '/') || (szLine[0] == ';' || szLine[0] == '\0'))
			continue
	
		ReadPropsLine(szLine, iCountWheels++)
	}
	CloseHandle(iFile)
}

ReadPropsLine(const char[] szLine, iCountWheels) {
	char szWheelName[64], szWheelPath[64]
	new idx, cur_idx
	
	if ((cur_idx = BreakString(szLine, szWheelName, sizeof(szWheelName))) == -1)
		return
	 
	SetArrayString(g_hWheelNameArray, iCountWheels, szWheelName)
	
	idx = cur_idx
	
	/* Get Model File Path */
	if (cur_idx != -1) {
		BreakString(szLine[idx], szWheelPath, sizeof(szWheelPath))
		SetArrayString(g_hWheelModelPathArray, iCountWheels, szWheelPath)
	}
}
