

#include <sourcemod>
#include <sdktools>

#include <smlib>
#include <vphysics>

#include <lazmod>


int g_iMaxRagdollArray = 512
Handle g_hRagdollNameArray
Handle g_hRagdollModelPathArray

int g_iMaxWheelArray = 32
Handle g_hWheelNameArray
Handle g_hWheelModelPathArray

ConVar g_hCvarSpawnInFront
bool g_bCvarSpawnInFront

Handle hPropList		= INVALID_HANDLE
Handle hRagdollList		= INVALID_HANDLE
Handle hWheelList		= INVALID_HANDLE
char g_szPathProps[PLATFORM_MAX_PATH]	= "configs/lazmod/props.ini"
char g_szPathRagdolls[PLATFORM_MAX_PATH]	= "configs/lazmod/ragdolls.ini"
char g_szPathWheels[PLATFORM_MAX_PATH]	= "configs/lazmod/wheels.ini"

public Plugin myinfo = {
	name = "LazMod - Creator",
	author = "LaZycAt, hjkwe654",
	description = "Prop spawning.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	RegAdminCmd("sm_spawn", Command_SpawnProp, 0, "Spawn physics props.")
	RegAdminCmd("sm_spawnf", Command_SpawnFrozen, 0, "Spawn and freeze the prop instantly so it dosen't go anywhere.")
	RegAdminCmd("sm_spawnd", Command_SpawnDynamic, 0, "Spawn dynamic props.")

	RegAdminCmd("sm_ragdoll", Command_SpawnRagdoll, 0, "Spawn ragdoll props.")
	g_hRagdollNameArray = CreateArray(32, g_iMaxRagdollArray);
	g_hRagdollModelPathArray = CreateArray(128, g_iMaxRagdollArray);
	ReadRagdolls()

	RegAdminCmd("sm_spawnwheel", Command_SpawnWheel, 0, "Place a wheel on your prop.")
	g_hWheelNameArray = CreateArray(32, g_iMaxWheelArray);
	g_hWheelModelPathArray = CreateArray(128, g_iMaxWheelArray);
	ReadWheels()
	

	g_hCvarSpawnInFront	= CreateConVar("lm_spawn_infront", "0", "Spawn props in front of player instead at aimed position.", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarSpawnInFront.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarSpawnInFront)

	char szGameName[32]
	GetGameFolderName(szGameName, sizeof(szGameName))
	BuildPath(Path_SM, g_szPathProps, sizeof(g_szPathProps), g_szPathProps)
	hPropList = CreateKeyValues("PropList")
	FileToKeyValues(hPropList, g_szPathProps)
	if (!KvJumpToKey(hPropList, szGameName)) {
		ThrowError("Game not supported because props.ini has no list for this game: %s", szGameName)
	}

	PrintToServer( "LazMod Creator loaded!" )
}

Hook_CvarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	CvarChanged(convar)
}
void CvarChanged(Handle convar) {
	if (convar == g_hCvarSpawnInFront)
		g_bCvarSpawnInFront = g_hCvarSpawnInFront.BoolValue
}


public Action Command_SpawnFrozen(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !spawnf <Prop name> ")
		LM_PrintToChat(plyClient, "Ex: !spawnf melon")
		return Plugin_Handled
	}
	
	char spwansf[33]
	GetCmdArg(1, spwansf, sizeof(spwansf))
	
	FakeClientCommand(plyClient, "sm_spawn %s 1", spwansf)
	return Plugin_Handled
}

public Action Command_SpawnDynamic(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !spawnd <Prop name> ")
		LM_PrintToChat(plyClient, "Ex: !spawnd blastdoor")
		LM_PrintToChat(plyClient, "Ex: !spawnd support")
		return Plugin_Handled
	}
	
	char spwansf[33]
	GetCmdArg(1, spwansf, sizeof(spwansf))
	
	FakeClientCommand(plyClient, "sm_spawn %s 2", spwansf)
	return Plugin_Handled
}

public Action Command_SpawnProp(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !spawn <Prop name>")
		LM_PrintToChat(plyClient, "Ex: !spawn melon")
		return Plugin_Handled
	}
	
	char szPropName[32], szModel[128]
	int iPropType
	GetCmdArg(1, szPropName, sizeof(szPropName))
	iPropType = GetCmdArgInt(2)
	
	KvGetString(hPropList, szPropName, szModel, sizeof(szModel))

	if (StrEqual(szModel, "")) {
		LM_PrintToChat(plyClient, "Prop not found: %s", szPropName)
		return Plugin_Handled
	}

	float vSpawnOrigin[3], vSurfaceAngles[3]

	if (g_bCvarSpawnInFront) {
		LM_GetFrontSpawnPos(plyClient, vSpawnOrigin)

	} else if (iPropType == 2) {
		LM_GetClientAimPosNormal(plyClient, vSpawnOrigin, vSurfaceAngles)
	
	} else {
		LM_ClientAimPos(plyClient, vSpawnOrigin)
	}
			

	char szClass[32]
	if (iPropType == 2)
		szClass = "prop_dynamic_override"
	else
		szClass = "prop_physics_override"

	int entProp = -1
	if (iPropType == 2)
		entProp = LM_CreateEntity(plyClient, szClass, szModel, vSpawnOrigin, vSurfaceAngles)
	else
		entProp = LM_CreateEntity(plyClient, szClass, szModel, vSpawnOrigin)

	if (entProp == -1) {
		LM_PrintToChat(plyClient, "Failed to spawn prop!")
		return Plugin_Handled
	}

	DispatchSpawn(entProp)
	
	if (iPropType == 1 && Phys_IsPhysicsObject(entProp))
		Phys_EnableMotion(entProp, false)


	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_spawn", szArgs)

	return Plugin_Handled
}





public Action Command_SpawnRagdoll(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !ragdoll <ragdoll name>")
		LM_PrintToChat(plyClient, "Ex: !ragdoll alyx")
		return Plugin_Handled
	}
	
	char szRagdollName[32], szModelPath[128]
	GetCmdArg(1, szRagdollName, sizeof(szRagdollName))
	
	int iRagdollIndex = FindStringInArray(g_hRagdollNameArray, szRagdollName)
	
	if (iRagdollIndex != -1) {
		
		int entProp = -1
		entProp = CreateEntityByName("prop_ragdoll")
		if (LM_SetEntityOwner(entProp, plyClient, true)) {
			float vClientEyePos[3], vSpawnOrigin[3], vClientEyeAngles[3], fRadiansX, fRadiansY
			
			GetClientEyePosition(plyClient, vClientEyePos)
			GetClientEyeAngles(plyClient, vClientEyeAngles)
			
			fRadiansX = DegToRad(vClientEyeAngles[0])
			fRadiansY = DegToRad(vClientEyeAngles[1])
			
			vSpawnOrigin[0] = vClientEyePos[0] + (100 * Cosine(fRadiansY) * Cosine(fRadiansX))
			vSpawnOrigin[1] = vClientEyePos[1] + (100 * Sine(fRadiansY) * Cosine(fRadiansX))
			vSpawnOrigin[2] = vClientEyePos[2] - 10
			
			GetArrayString(g_hRagdollModelPathArray, iRagdollIndex, szModelPath, sizeof(szModelPath))
			
			if (!IsModelPrecached(szModelPath))
				PrecacheModel(szModelPath)
			PrintToServer(szModelPath)
			DispatchKeyValue(entProp, "model", szModelPath)
			
			DispatchSpawn(entProp)
			TeleportEntity(entProp, vSpawnOrigin, NULL_VECTOR, NULL_VECTOR)
			
		} else
			RemoveEdict(entProp)
	} else {
		LM_PrintToChat(plyClient, "Prop not found: %s", szRagdollName)
	}

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_spawn", szArgs)

	return Plugin_Handled
}

ReadRagdolls() {
	char szFile[128]
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/lazmod/ragdolls.ini")
	
	Handle hFile = OpenFile(szFile, "rt")
	if (hFile == INVALID_HANDLE)
		return
	
	int iCountRagdolls = 0
	while (!IsEndOfFile(hFile))
	{
		
		char szLine[255]
		if (!ReadFileLine(hFile, szLine, sizeof(szLine)))
			break
		
		/* 略過註解 */
		int iLen = strlen(szLine)
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
	
		ReadRagdollsLine(szLine, iCountRagdolls++)
	}
	PrintToServer( "LazMod Creator - Loaded %i ragdolls", iCountRagdolls )
	CloseHandle(hFile)
}

ReadRagdollsLine(const char[] szLine, iCountRagdolls) {
	
	char szRagdollInfo[2][128]
	ExplodeString(szLine, ", ", szRagdollInfo, sizeof(szRagdollInfo), sizeof(szRagdollInfo[]))
	
	StripQuotes(szRagdollInfo[0])
	SetArrayString(g_hRagdollNameArray, iCountRagdolls, szRagdollInfo[0])
	
	StripQuotes(szRagdollInfo[1])
	SetArrayString(g_hRagdollModelPathArray, iCountRagdolls, szRagdollInfo[1])
	
}








public Action Command_SpawnWheel(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !wheel <type>")
		LM_PrintToChat(plyClient, "Ex: !wheel 3")
		
		return Plugin_Handled
	}
	
	char szWheelName[33], szModelPath[128]
	GetCmdArg(1, szWheelName, sizeof(szWheelName))
	
	int iPropIndex = FindStringInArray(g_hWheelNameArray, szWheelName)
	if (iPropIndex != -1) {
		float vClientEyePos[3]
		float vClientEyeAngles[3]
		
		GetClientEyePosition(plyClient, vClientEyePos)
		GetClientEyeAngles(plyClient, vClientEyeAngles)
		
		Handle trace = TR_TraceRayFilterEx(vClientEyePos, vClientEyeAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterOnlyVPhysics)
		
		if (TR_DidHit(trace) && TR_GetEntityIndex(trace)) {
			int entIndex = TR_GetEntityIndex(trace)
			if (LM_IsEntityOwner(plyClient, entIndex)) {	
				int entWheel = CreateEntityByName("prop_physics_override")
				if (LM_SetEntityOwner(entWheel, plyClient)) {
					float vHitPos[3]
					float vHitNormal[3]
					TR_GetEndPosition(vHitPos, trace)
					TR_GetPlaneNormal(trace, vHitNormal)
					
					GetArrayString(g_hWheelModelPathArray, iPropIndex, szModelPath, sizeof(szModelPath))
					
					if (!IsModelPrecached(szModelPath))
						PrecacheModel(szModelPath)
					
					DispatchKeyValue(entWheel, "model", szModelPath)
					DispatchKeyValue(entWheel, "spawnflags", "256")
					DispatchKeyValueFloat(entWheel, "physdamagescale", 0.0)
					DispatchKeyValueFloat(entWheel, "ExplodeDamage", 0.0)
					DispatchKeyValueFloat(entWheel, "ExplodeRadius", 0.0)
					
					DispatchSpawn(entWheel)
					ActivateEntity(entWheel)
					
					float vSurfaceAngles[3];					
					GetVectorAngles(vHitNormal, vSurfaceAngles)
					
					float vWheelPos[3]; // Should be calculating the width of the model for this.
					float vVecToAdd[3]
					
					vVecToAdd[0] = vHitNormal[0]
					vVecToAdd[1] = vHitNormal[1]
					vVecToAdd[2] = vHitNormal[2]
					
					switch(StringToInt(szWheelName)) {
						case 1:
							ScaleVector(vVecToAdd, 5.0)
						case 2:
							ScaleVector(vVecToAdd, 10.0)
						case 3:
							ScaleVector(vVecToAdd, 7.5)
						case 4:
							ScaleVector(vVecToAdd, 12.5)
						case 5: {
							ScaleVector(vVecToAdd, 11.0)
							vSurfaceAngles[0] += 90
							vSurfaceAngles[2] += 90
						}
						case 6: {
							ScaleVector(vVecToAdd, 30.0)
							vSurfaceAngles[0] += 90
							vSurfaceAngles[2] += 90
						}
						case 7: {
							ScaleVector(vVecToAdd, 30.0)
							vSurfaceAngles[0] += 90
							vSurfaceAngles[2] += 90
						}
					}
					
					AddVectors(vHitPos, vVecToAdd, vWheelPos)
					TeleportEntity(entWheel, vWheelPos, vSurfaceAngles, NULL_VECTOR)
					
					Phys_CreateHingeConstraint(entIndex, entWheel, INVALID_HANDLE, vHitPos, vHitNormal)
					LM_PrintToChat(plyClient, "Added wheel to target")
				} else
					RemoveEdict(entWheel)
			}
		} else {
			LM_PrintToChat(plyClient, "Target not found.")
		}
		
		CloseHandle(trace)
	} else {
		LM_PrintToChat(plyClient, "Wheel not found.")
	}


	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_wheel", szArgs)
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
	
		ReadWheelLine(szLine, iCountWheels++)
	}
	CloseHandle(iFile)
}

ReadWheelLine(const char[] szLine, iCountWheels) {
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

