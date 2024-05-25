

#include <sourcemod>
#include <sdktools>

#include <smlib>
#include <vphysics>

#include <lazmod>



int g_iMaxWheelArray = 32
Handle g_hWheelNameArray
Handle g_hWheelModelPathArray

ConVar g_hCvarSpawnInFront
bool g_bCvarSpawnInFront

Handle hPropList		= INVALID_HANDLE
Handle hRagdollList		= INVALID_HANDLE
char g_szPathProps[PLATFORM_MAX_PATH]		= "configs/lazmod/props.ini"
char g_szPathRagdolls[PLATFORM_MAX_PATH]	= "configs/lazmod/ragdolls.ini"



ConVar g_hCvarStackMax
int g_iCvarStackMax

bool g_bExtendIsRunning[MAXPLAYERS]
int g_entExtendTarget[MAXPLAYERS]

bool g_bStackIsRunning[MAXPLAYERS] = { false,...}
int g_iCurrent[MAXPLAYERS] = { 0,...}



public Plugin myinfo = {
	name = "LazMod - Creator",
	author = "LaZycAt, hjkwe654",
	description = "Prop spawning.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	RegAdminCmd("sm_spawn", Command_SpawnProp, 0, "Spawn physics props.")
	RegAdminCmd("sm_spawnf", Command_SpawnFrozen, 0, "Spawn and freeze the prop and frozen.")
	RegAdminCmd("sm_spawnd", Command_SpawnDynamic, 0, "Spawn dynamic props.")

	RegAdminCmd("sm_spawnmodel", Command_SpawnModel, ADMFLAG_GENERIC, "Spawn physics props by model.")
	RegAdminCmd("sm_spawnmodelf", Command_SpawnModelFrozen, ADMFLAG_GENERIC, "Spawn physics props by model and frozen.")
	RegAdminCmd("sm_spawnmodeld", Command_SpawnModelDynamic, ADMFLAG_GENERIC, "Spawn dynamic props by model.")

	RegAdminCmd("sm_spawnragdoll", Command_SpawnRagdoll, 0, "Spawn ragdoll props.")




	RegAdminCmd("sm_stack", Command_Stack, 0, "Stack a prop.")
	RegAdminCmd("sm_extend", Command_Extend, 0, "Create a third prop based on the position and angle of first two props.")

	g_hCvarStackMax	= CreateConVar("lm_stack_max", "10", "How many props can a player stack at one time.", FCVAR_NOTIFY, true, 0.0, true, 100.0)
	g_hCvarStackMax.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarStackMax)




	RegAdminCmd("sm_spawnwheel", Command_SpawnWheel, 0, "Place a wheel on your prop.")
	g_hWheelNameArray      = CreateArray(32, g_iMaxWheelArray);
	g_hWheelModelPathArray = CreateArray(128, g_iMaxWheelArray);
	ReadWheels()
	

	g_hCvarSpawnInFront	= CreateConVar("lm_spawn_infront", "0", "Spawn props in front of player instead at aimed position.", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarSpawnInFront.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarSpawnInFront)

	char szGameName[32]
	GetGameFolderName(szGameName, sizeof(szGameName))

	BuildPath(Path_SM, g_szPathProps,    sizeof(g_szPathProps),    g_szPathProps)
	hPropList = CreateKeyValues("PropList")
	FileToKeyValues(hPropList,  g_szPathProps)
	if (!KvJumpToKey(hPropList, szGameName))
		ThrowError("Game not supported because props.ini has no list for this game: %s", szGameName)
	
	BuildPath(Path_SM, g_szPathRagdolls, sizeof(g_szPathRagdolls), g_szPathRagdolls)
	hRagdollList = CreateKeyValues("RagdollList")
	FileToKeyValues(hRagdollList,  g_szPathRagdolls)
	if (!KvJumpToKey(hRagdollList, szGameName))
		ThrowError("Game not supported because ragdolls.ini has no list for this game: %s", szGameName)

	PrintToServer( "LazMod Creator loaded!" )
}

Hook_CvarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	CvarChanged(convar)
}
void CvarChanged(Handle convar) {
	if (convar == g_hCvarSpawnInFront)
		g_bCvarSpawnInFront = g_hCvarSpawnInFront.BoolValue
	else if (convar == g_hCvarStackMax)
		g_iCvarStackMax = g_hCvarStackMax.IntValue
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

public Action Command_SpawnFrozen(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !spawnf <Prop name> ")
		LM_PrintToChat(plyClient, "Ex: !spawnf melon")
		return Plugin_Handled
	}
	
	char szPropName[33]
	GetCmdArg(1, szPropName, sizeof(szPropName))
	
	FakeClientCommand(plyClient, "sm_spawn %s 1", szPropName)
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
	
	char szPropName[33]
	GetCmdArg(1, szPropName, sizeof(szPropName))
	
	FakeClientCommand(plyClient, "sm_spawn %s 2", szPropName)
	return Plugin_Handled
}




public Action Command_SpawnModel(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !spawnmodel <model path>\n\
									Ex: !spawnmodel props_lab/blastdoor001c\n\
									Ex: !spawnmodel models/props_c17/support01.mdl")
		LM_PrintToChat(plyClient, "Note: 'models/' and '.mdl' are acceptable")
		LM_PrintToChat(plyClient, "Warning: Do not try spawn models thats like '*60', it might crash server")
		return Plugin_Handled
	}
	
	char szModel[128]
	int iPropType
	GetCmdArg(1, szModel, sizeof(szModel))
	iPropType = GetCmdArgInt(2)
	
	if (!String_StartsWith(szModel, "models/"))
		Format(szModel, sizeof(szModel), "models/%s", szModel)
	if (!String_EndsWith(szModel, ".mdl"))
		Format(szModel, sizeof(szModel), "%s.mdl", szModel)
	
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
	LM_LogCmd(plyClient, "sm_spawnmodel", szArgs)

	return Plugin_Handled
}

public Action Command_SpawnModelFrozen(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !spawnmodelf <model path>\n\
									Ex: !spawnmodelf props_lab/blastdoor001c\n\
									Ex: !spawnmodelf models/props_c17/support01.mdl")
		LM_PrintToChat(plyClient, "Note: 'models/' and '.mdl' are acceptable")
		LM_PrintToChat(plyClient, "Warning: Do not try spawn models thats like '*60', it might crash server")
		return Plugin_Handled
	}
	
	char szModel[33]
	GetCmdArg(1, szModel, sizeof(szModel))
	
	FakeClientCommand(plyClient, "sm_spawnmodel %s 1", szModel)
	return Plugin_Handled
}

public Action Command_SpawnModelDynamic(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !spawnmodeld <model path>\n\
									Ex: !spawnmodeld props_lab/blastdoor001c\n\
									Ex: !spawnmodeld models/props_c17/support01.mdl")
		LM_PrintToChat(plyClient, "Note: 'models/' and '.mdl' are acceptable")
		LM_PrintToChat(plyClient, "Warning: Do not try spawn models thats like '*60', it might crash server")
		return Plugin_Handled
	}
	
	char szModel[33]
	GetCmdArg(1, szModel, sizeof(szModel))
	
	FakeClientCommand(plyClient, "sm_spawnmodel %s 2", szModel)
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
	
	char szRagdollName[32], szModel[128]
	GetCmdArg(1, szRagdollName, sizeof(szRagdollName))
	
	KvGetString(hRagdollList, szRagdollName, szModel, sizeof(szModel))
	if (StrEqual(szModel, "")) {
		LM_PrintToChat(plyClient, "Ragdoll not found: %s", szRagdollName)
		return Plugin_Handled
	}

	float vSpawnOrigin[3]
	LM_GetFrontSpawnPos(plyClient, vSpawnOrigin)

	int entProp = -1
	entProp = LM_CreateEntity(plyClient, "prop_ragdoll", szModel, vSpawnOrigin, NULL_VECTOR, true)

	if (entProp == -1) {
		LM_PrintToChat(plyClient, "Failed to spawn ragdoll: %s", szRagdollName)
		return Plugin_Handled
	}

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_ragdoll", szArgs)

	return Plugin_Handled
}




public Action Command_Stack(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (g_bStackIsRunning[plyClient]) {
		LM_PrintToChat(plyClient, "Already stacking a prop, wait for it to finish!")
		return Plugin_Handled
	}	
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !stack <amount> [X] [Y] [Z] [unfreeze]")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsEntOwner(plyClient, entProp))
		return Plugin_Handled
	
	char szModel[128], szClass[33]
	int iUnFreeze = 0, iAmount
	float vMove[3]
	
	iAmount = GetCmdArgInt(1)
	vMove[0] = GetCmdArgFloat(2)
	vMove[1] = GetCmdArgFloat(3)
	vMove[2] = GetCmdArgFloat(4)
	iUnFreeze = GetCmdArgInt(5)
	
	
	if (!LM_IsClientAdmin(plyClient) && iAmount > g_iCvarStackMax) {
		LM_PrintToChat(plyClient, "Max stack limit is %d", g_iCvarStackMax)
		return Plugin_Handled
	}
	
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	if ((StrEqual(szClass, "prop_ragdoll") || StrEqual(szModel, "models/props_c17/oildrum001_explosive.mdl")) && !LM_IsClientAdmin(plyClient)) {
		LM_PrintToChat(plyClient, "Restricted to prevent griefing!")
		return Plugin_Handled
	}
	
	Handle hDataPack
	CreateDataTimer(0.001, Timer_Stack, hDataPack)
	WritePackCell(hDataPack, plyClient)
	WritePackCell(hDataPack, entProp)
	WritePackCell(hDataPack, iAmount)
	WritePackFloat(hDataPack, vMove[0])
	WritePackFloat(hDataPack, vMove[1])
	WritePackFloat(hDataPack, vMove[2])
	WritePackCell(hDataPack, iUnFreeze)
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_stack", szArgs)
	return Plugin_Handled
}
public Action Timer_Stack(Handle Timer, Handle hDataPack) {
	float vMove[3], vNext[3]
	ResetPack(hDataPack)
	int Client = ReadPackCell(hDataPack)
	int entProp = ReadPackCell(hDataPack)
	int iAmount = ReadPackCell(hDataPack)
	vMove[0] = ReadPackFloat(hDataPack)
	vMove[1] = ReadPackFloat(hDataPack)
	vMove[2] = ReadPackFloat(hDataPack)
	int iFreeze = ReadPackCell(hDataPack)
	if (g_iCurrent[Client] != 0) {
		vNext[0] = ReadPackFloat(hDataPack)
		vNext[1] = ReadPackFloat(hDataPack)
		vNext[2] = ReadPackFloat(hDataPack)
	}
	
	g_bStackIsRunning[Client] = true
	if (!LM_IsClientValid(Client, Client) || !IsValidEdict(entProp)) {
		g_bStackIsRunning[Client] = false
		g_iCurrent[Client] = 0
		return Plugin_Handled
	}
	
	char szClass[32], szModel[256]
	float vEntityOrigin[3], vEntityAngle[3]
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	LM_GetEntOrigin(entProp, vEntityOrigin)
	LM_GetEntAngles(entProp, vEntityAngle)
	LM_GetEntModel(entProp, szModel, sizeof(szModel))
	
	if (g_iCurrent[Client] < iAmount) {
		bool IsDoll = false
		int entStackEntity = CreateEntityByName(szClass)
		
		if (StrEqual(szClass, "prop_ragdoll"))
			IsDoll = true
			
		if (LM_SetEntOwner(entStackEntity, Client, IsDoll)) {			
			DispatchKeyValue(entStackEntity, "model", szModel)
			if (StrEqual(szClass, "prop_dynamic"))
				LM_SetEntSolidType(entStackEntity, SOLID_VPHYSICS)
			DispatchSpawn(entStackEntity)
			
			AddVectors(vMove, vNext, vNext)
			AddVectors(vNext, vEntityOrigin, vEntityOrigin)
			
			TeleportEntity(entStackEntity, vEntityOrigin, vEntityAngle, NULL_VECTOR)
			
			if (iFreeze == 1) {
				if(Phys_IsPhysicsObject(entProp))
					Phys_EnableMotion(entStackEntity, false)
			}
			g_iCurrent[Client]++
			Handle hNewPack
			CreateDataTimer(0.005, Timer_Stack, hNewPack)
			WritePackCell(hNewPack, Client)
			WritePackCell(hNewPack, entProp)
			WritePackCell(hNewPack, iAmount)
			WritePackFloat(hNewPack, vMove[0])
			WritePackFloat(hNewPack, vMove[1])
			WritePackFloat(hNewPack, vMove[2])
			WritePackCell(hNewPack, iFreeze)
			WritePackFloat(hNewPack, vNext[0])
			WritePackFloat(hNewPack, vNext[1])
			WritePackFloat(hNewPack, vNext[2])
			return Plugin_Handled
		} else {
			g_bStackIsRunning[Client] = false
			g_iCurrent[Client] = 0
			RemoveEdict(entStackEntity)
			return Plugin_Handled
		}
	} else {
		g_bStackIsRunning[Client] = false
		g_iCurrent[Client] = 0
	}
	return Plugin_Handled
}

public Action Command_Extend(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp1 = LM_GetClientAimEntity(plyClient)
	if (entProp1 == -1) 
		return Plugin_Handled
	
	char szClass[33]
	GetEdictClassname(entProp1, szClass, sizeof(szClass))
	if (LM_IsEntOwner(plyClient, entProp1)) {
		int entProp3
		if (StrContains(szClass, "prop_dynamic") >= 0) {
			entProp3 = CreateEntityByName("prop_dynamic_override")
			LM_SetEntSolidType(entProp3, SOLID_VPHYSICS)
		} else
			entProp3 = CreateEntityByName(szClass)
			
		if (LM_SetEntOwner(entProp3, plyClient)) {
			if (!g_bExtendIsRunning[plyClient]) {
				g_entExtendTarget[plyClient] = entProp1
				g_bExtendIsRunning[plyClient] = true
				LM_PrintToChat(plyClient, "Extend #1 set, use !ex again on #2 prop.")
			} else {
				char szModel[255]
				float vProp1Origin[3], vProp1Angles[3], vProp2Origin[3], vProp3Origin[3]
				
				LM_GetEntOrigin(g_entExtendTarget[plyClient], vProp1Origin)
				LM_GetEntAngles(g_entExtendTarget[plyClient], vProp1Angles)
				LM_GetEntModel(g_entExtendTarget[plyClient], szModel, sizeof(szModel))
				LM_GetEntOrigin(entProp1, vProp2Origin)
				
				for (int i = 0; i < 3; i++)
					vProp3Origin[i] = (vProp2Origin[i] + vProp2Origin[i] - vProp1Origin[i])
				
				DispatchKeyValue(entProp3, "model", szModel)
				DispatchSpawn(entProp3)
				TeleportEntity(entProp3, vProp3Origin, vProp1Angles, NULL_VECTOR)
				
				if(Phys_IsPhysicsObject(entProp3))
					Phys_EnableMotion(entProp3, false)
				
				g_bExtendIsRunning[plyClient] = false
				LM_PrintToChat(plyClient, "Extended a prop.")
			}
		} else
			RemoveEdict(entProp3)
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_extend", szArgs)
	return Plugin_Handled
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
			if (LM_IsEntOwner(plyClient, entIndex)) {	
				int entWheel = CreateEntityByName("prop_physics_override")
				if (LM_SetEntOwner(entWheel, plyClient)) {
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
	
	int iCountWheels = 0
	while (!IsEndOfFile(iFile))
	{
		char szLine[255]
		if (!ReadFileLine(iFile, szLine, sizeof(szLine)))
			break
		
		/* 略過註解 */
		int iLineLen = strlen(szLine)
		bool bIgnore = false
		
		for (int i = 0; i < iLineLen; i++) {
			if (bIgnore) {
				if (szLine[i] == '"')
					bIgnore = false
			} else {
				if (szLine[i] == '"')
					bIgnore = true
				else if (szLine[i] == ';') {
					szLine[i] = '\0'
					break
				} else if (szLine[i] == '/' && i != iLineLen - 1 && szLine[i+1] == '/') {
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
	int iIndex, iCurIndex
	
	if ((iCurIndex = BreakString(szLine, szWheelName, sizeof(szWheelName))) == -1)
		return
	 
	SetArrayString(g_hWheelNameArray, iCountWheels, szWheelName)
	
	iIndex = iCurIndex
	
	/* Get Model File Path */
	if (iCurIndex != -1) {
		BreakString(szLine[iIndex], szWheelPath, sizeof(szWheelPath))
		SetArrayString(g_hWheelModelPathArray, iCountWheels, szWheelPath)
	}
}

