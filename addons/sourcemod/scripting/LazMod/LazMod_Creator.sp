

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>




Handle g_hPropNameArray
Handle g_hPropModelPathArray
Handle g_hPropTypeArray

Handle g_hWheelNameArray
Handle g_hWheelModelPathArray

Handle g_hCvarSpawnInFront = INVALID_HANDLE
int g_iCvarSpawnInFront

char g_szFile[128]

public Plugin myinfo = {
	name = "LazMod - Creator",
	author = "LaZycAt, hjkwe654",
	description = "Prop spawning.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	RegAdminCmd("sm_spawn", Command_SpawnProp, 0, "Spawn Props.")
	RegAdminCmd("sm_spawnf", Command_SpawnF, 0, "Spawn and freeze the prop instantly so it dosen't go anywhere.")
	
	g_hPropNameArray = CreateArray(33, 2048);		// Max Prop List is 1024-->2048
	g_hPropModelPathArray = CreateArray(128, 2048);	// Max Prop List is 1024-->2048
	g_hPropTypeArray = CreateArray(33, 2048);		// Max Prop List is 1024-->2048
	ReadProps()

	RegAdminCmd("sm_wheel", Command_Wheel, 0, "Place a wheel on your prop.")
	g_hWheelNameArray = CreateArray(32, 32);		// Max Wheel List is 32
	g_hWheelModelPathArray = CreateArray(128, 32);	// Max Wheel List is 32
	ReadWheels()
	


	g_hCvarSpawnInFront	= CreateConVar("lm_spawn_infront", "1", "Spawn props in front of player instead at aimed position.", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_iCvarSpawnInFront = GetConVarBool(g_hCvarSpawnInFront)
	HookConVarChange(g_hCvarSpawnInFront, Hook_CvarSpawnInFront)


	PrintToServer( "LazMod Creator loaded!" )
}

public Hook_CvarSpawnInFront(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarSpawnInFront = GetConVarBool(g_hCvarSpawnInFront)
}

public Action Command_SpawnF(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !spawnf <Prop name> ")
		LM_PrintToChat(plyClient, "Ex: !spawnf goldbar")
		LM_PrintToChat(plyClient, "Ex: !spawnf alyx")
		return Plugin_Handled
	}
	
	char spwansf[33]
	GetCmdArg(1, spwansf, sizeof(spwansf))
	
	FakeClientCommand(plyClient, "sm_spawn %s yes", spwansf)
	return Plugin_Handled
}

public Action Command_SpawnProp(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !spawn <Prop name>")
		LM_PrintToChat(plyClient, "Ex: !spawn goldbar")
		LM_PrintToChat(plyClient, "Ex: !spawn alyx")
		return Plugin_Handled
	}
	
	char szPropName[32], szPropFrozen[32], szModelPath[128]
	GetCmdArg(1, szPropName, sizeof(szPropName))
	GetCmdArg(2, szPropFrozen, sizeof(szPropFrozen))
	
	int iPropIndex = FindStringInArray(g_hPropNameArray, szPropName)
	
	if (iPropIndex != -1) {
		bool bIsDoll = false
		char szEntType[33]
		GetArrayString(g_hPropTypeArray, iPropIndex, szEntType, sizeof(szEntType))
		
		if (StrEqual(szEntType, "prop_ragdoll"))
			bIsDoll = true
		
		int entProp = CreateEntityByName(szEntType)

		if (LM_SetEntityOwner(entProp, plyClient, bIsDoll)) {
			float vClientEyePos[3], vSpawnOrigin[3], vClientEyeAngles[3], fRadiansX, fRadiansY
			
			if (g_iCvarSpawnInFront) {
				GetClientEyePosition(plyClient, vClientEyePos)
				GetClientEyeAngles(plyClient, vClientEyeAngles)
				
				fRadiansX = DegToRad(vClientEyeAngles[0])
				fRadiansY = DegToRad(vClientEyeAngles[1])
				
				vSpawnOrigin[0] = vClientEyePos[0] + (100 * Cosine(fRadiansY) * Cosine(fRadiansX))
				vSpawnOrigin[1] = vClientEyePos[1] + (100 * Sine(fRadiansY) * Cosine(fRadiansX))
				vSpawnOrigin[2] = vClientEyePos[2] - 20
			} else {
				LM_ClientAimPos(plyClient, vSpawnOrigin)
			}
			
			GetArrayString(g_hPropModelPathArray, iPropIndex, szModelPath, sizeof(szModelPath))
			
			if (!IsModelPrecached(szModelPath))
				PrecacheModel(szModelPath)
			
			DispatchKeyValue(entProp, "model", szModelPath)
			
			if (StrEqual(szEntType, "prop_dynamic"))
				SetEntProp(entProp, Prop_Send, "m_nSolidType", 6)
			
			DispatchSpawn(entProp)
			TeleportEntity(entProp, vSpawnOrigin, NULL_VECTOR, NULL_VECTOR)
			
			if (!StrEqual(szPropFrozen, "")) {
				if (Phys_IsPhysicsObject(entProp))
					Phys_EnableMotion(entProp, false)
			}
		} else
			RemoveEdict(entProp)
	} else {
		LM_PrintToChat(plyClient, "Prop not found: %s", szPropName)
	}

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_spawn", szArgs)

	return Plugin_Handled
}

ReadProps() {
	BuildPath(Path_SM, g_szFile, sizeof(g_szFile), "configs/lazmod/props.ini")
	
	Handle iFile = OpenFile(g_szFile, "rt")
	if (iFile == INVALID_HANDLE)
		return
	
	int iCountProps = 0
	while (!IsEndOfFile(iFile))
	{
		char szLine[255]
		if (!ReadFileLine(iFile, szLine, sizeof(szLine)))
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
	
		ReadPropsLine(szLine, iCountProps++)
	}
	PrintToServer( "LazMod Creator - Loaded %i props", iCountProps )
	CloseHandle(iFile)
}

ReadPropsLine(const char[] szLine, iCountProps) {
	char szPropInfo[3][128]
	ExplodeString(szLine, ", ", szPropInfo, sizeof(szPropInfo), sizeof(szPropInfo[]))
	
	StripQuotes(szPropInfo[0])
	SetArrayString(g_hPropNameArray, iCountProps, szPropInfo[0])
	
	StripQuotes(szPropInfo[1])
	SetArrayString(g_hPropModelPathArray, iCountProps, szPropInfo[1])
	
	StripQuotes(szPropInfo[2])
	SetArrayString(g_hPropTypeArray, iCountProps, szPropInfo[2])
}



public Action Command_Wheel(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !wheel <type>")
		LM_PrintToChat(plyClient, "Ex: !wheel 3")
		LM_PrintToChat(plyClient, "Note: Some wheel does not work properly that was broken by game updates, may or may not be fixed in the future")
		
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
						case 5:
							ScaleVector(vVecToAdd, 11.0)
						case 6:
							ScaleVector(vVecToAdd, 40.0)
						case 7:
							ScaleVector(vVecToAdd, 40.0)
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

