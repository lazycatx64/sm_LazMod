

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>

#if LAZMOD_API_VER < 3
	#error "build.inc is outdated. please update before compiling"
#endif





int g_iPropCurrent[MAXPLAYERS]
int g_iDollCurrent[MAXPLAYERS]
int g_iServerCurrent
int g_iEntOwner[MAX_HOOK_ENTITIES] = {-1,...}

Handle g_hBlackListArray
Handle g_hCvarSwitch		= INVALID_HANDLE
Handle g_hCvarNonOwner		= INVALID_HANDLE
Handle g_hCvarFly			= INVALID_HANDLE
Handle g_hCvarClPropLimit	= INVALID_HANDLE
Handle g_hCvarClDollLimit	= INVALID_HANDLE
Handle g_hCvarServerLimit	= INVALID_HANDLE

int g_iCvarEnabled
int g_iCvarNonOwner
int g_iCvarFly
int g_iCvarClPropLimit[MAXPLAYERS]
int g_iCvarClDollLimit
int g_iCvarServerLimit

public Plugin myinfo = {
	name = "LazMod Core",
	author = "LaZycAt, hjkwe654",
	description = "LazMod Core",
	version = LAZMOD_VER,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max) {
	RegPluginLibrary("build_test")
	
	CreateNative("LM_SetEntityOwner",		Native_SetEntityOwner)
	CreateNative("LM_GetEntityOwner",		Native_GetEntityOwner)
	CreateNative("LM_IsEntityOwner",		Native_IsEntityOwner)

	CreateNative("LM_AllowToUse",		Native_AllowToUse)
	CreateNative("LM_AllowFly",			Native_AllowFly)

	CreateNative("LM_IsClientValid",	Native_IsClientValid)
	CreateNative("LM_IsAdmin",			Native_IsAdmin)

	CreateNative("LM_IsFuncProp", 		Native_IsFuncProp)
	CreateNative("LM_IsNpc",			Native_IsNpc)
	CreateNative("LM_IsPlayer",			Native_IsPlayer)

	CreateNative("LM_SetSpawnLimit",	Native_SetSpawnLimit)
	CreateNative("LM_LogCmd",			Native_LogCmd)
	CreateNative("LM_PrintToChat",		Native_PrintToChat)
	CreateNative("LM_PrintToAll",		Native_PrintToAll)
	CreateNative("LM_GetClientAimEntity",	Native_GetClientAimEntity)

	CreateNative("LM_AddBlacklist",		Native_AddBlacklist)
	CreateNative("LM_RemoveBlacklist",	Native_RemoveBlacklist)
	CreateNative("LM_IsBlacklisted",	Native_IsBlacklisted)
	
	return APLRes_Success
}

public OnPluginStart() {	
	g_hCvarSwitch		= CreateConVar("lm_enable", "2", "Enable the LazMod. 2=For All, 1=Admins Only, 0=Disabled.", 0, true, 0.0, true, 2.0)
	g_hCvarNonOwner		= CreateConVar("lm_nonowner", "0", "Switch non-admin player can control non-owner props or not", 0, true, 0.0, true, 1.0)
	g_hCvarFly			= CreateConVar("lm_fly", "1", "Switch non-admin player can use !fly to noclip or not", 0, true, 0.0, true, 1.0)
	g_hCvarClPropLimit	= CreateConVar("lm_prop", "700", "Player prop spawn limit.", 0, true, 0.0)
	g_hCvarClDollLimit	= CreateConVar("lm_doll", "10", "Player doll spawn limit.", 0, true, 0.0)
	g_hCvarServerLimit	= CreateConVar("lm_maxprops", "2000", "Total prop spawn limit.", 0, true, 0.0, true, 3000.0)
	RegAdminCmd("sm_version", Command_Version, 0, "Show Lazmod Core version")
	RegAdminCmd("sm_count", Command_SpawnCount, 0, "Show how many entities are you spawned.")
	
	g_iCvarEnabled = GetConVarInt(g_hCvarSwitch)
	g_iCvarNonOwner = GetConVarBool(g_hCvarNonOwner)
	g_iCvarFly = GetConVarBool(g_hCvarFly)
	for (int i = 0; i < MAXPLAYERS; i++)
		g_iCvarClPropLimit[i] = GetConVarInt(g_hCvarClPropLimit)
	g_iCvarClDollLimit = GetConVarInt(g_hCvarClDollLimit)
	g_iCvarServerLimit = GetConVarInt(g_hCvarServerLimit)

	HookConVarChange(g_hCvarSwitch, Hook_CvarEnabled)
	HookConVarChange(g_hCvarNonOwner, Hook_CvarNonOwner)
	HookConVarChange(g_hCvarFly, Hook_CvarFly)
	HookConVarChange(g_hCvarClPropLimit, Hook_CvarClPropLimit)
	HookConVarChange(g_hCvarClDollLimit, Hook_CvarClDollLimit)
	HookConVarChange(g_hCvarServerLimit, Hook_CvarServerLimit)
	
	ServerCommand("gamedesc_override \"BuildMod %s\"", LAZMOD_VER)
	g_hBlackListArray = CreateArray(33, 128);	// 33 arrays, every array size is 128
	ReadBlackList()
}

public OnMapStart() {
	LM_FirstRun()
}

public Hook_CvarEnabled(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarEnabled = GetConVarInt(g_hCvarSwitch)
}

public Hook_CvarNonOwner(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarNonOwner = GetConVarBool(g_hCvarNonOwner)
}

public Hook_CvarFly(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarFly = GetConVarBool(g_hCvarFly)
}

public Hook_CvarClPropLimit(Handle convar, const char[] oldValue, const char[] newValue) {
	for (int i = 0; i < MAXPLAYERS; i++)
		g_iCvarClPropLimit[i] = GetConVarInt(g_hCvarClPropLimit)
}

public Hook_CvarClDollLimit(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarClDollLimit = GetConVarInt(g_hCvarClDollLimit)
}

public Hook_CvarServerLimit(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarServerLimit = GetConVarInt(g_hCvarServerLimit)
}

public Action Command_Version(Client, args) {
	LM_PrintToChat(Client, "LazMod Core version: %s", LAZMOD_VER)
	return Plugin_Handled
}

public Action Command_SpawnCount(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled
		
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_count", szArgs)
	LM_PrintToChat(Client, "Your Limit: %i/%i [Ragdoll: %i/%i], Server Limit: %i/%i", g_iPropCurrent[Client], g_iCvarClPropLimit[Client], g_iDollCurrent[Client], g_iCvarClDollLimit, g_iServerCurrent, g_iCvarServerLimit)
	if (LM_IsAdmin(Client)) {
		for (int i = 1; i < MaxClients; i++) {
			if (LM_IsClientValid(i, i) && Client != i)
				LM_PrintToChat(Client, "%N: %i/%i [Ragdoll: %i/%i]", i, g_iPropCurrent[i], g_iCvarClPropLimit[i], g_iDollCurrent[i], g_iCvarClDollLimit)
		
		}
	}
	return Plugin_Handled
}

Native_SetEntityOwner(Handle hPlugin, iNumParams) {
	int entProp = GetNativeCell(1)
	int plyClient = GetNativeCell(2)
	bool bIsDoll = false
	
	if (iNumParams >= 3)
		bIsDoll = GetNativeCell(3)
	
	if (plyClient == -1) {
		g_iEntOwner[entProp] = -1
		return true
	}
	if (IsValidEntity(entProp) && LM_IsClientValid(plyClient, plyClient)) {
		if (g_iServerCurrent < g_iCvarServerLimit) {
			if (bIsDoll) {
				if (g_iDollCurrent[plyClient] < g_iCvarClDollLimit) {
					g_iDollCurrent[plyClient] += 1
					g_iPropCurrent[plyClient] += 1
				} else {
					LM_PrintToChat(plyClient, "Your dolls has reached the limit.")
					return false
				}
			} else {
				if (g_iPropCurrent[plyClient] < g_iCvarClPropLimit[plyClient])
					g_iPropCurrent[plyClient] += 1
				else {
					LM_PrintToChat(plyClient, "Your props has reached the limit.")
					return false
				}
			}
			g_iEntOwner[entProp] = plyClient
			g_iServerCurrent += 1
			return true
		} else {
			LM_PrintToChat(plyClient, "The number of prop has reached the server limit.")
			return false
		}
	}
	
	if (!IsValidEntity(entProp))
		ThrowNativeError(SP_ERROR_NATIVE, "Entity id %i is invalid.", entProp)
		
	if (!LM_IsClientValid(plyClient, plyClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not in game.", plyClient)
		
	return -1
}

Native_GetEntityOwner(Handle hPlugin, iNumParams) {
	new iEnt = GetNativeCell(1)
	if (IsValidEntity(iEnt))
		return g_iEntOwner[iEnt]
	else {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity id %i is invalid.", iEnt)
		return -1
	}
}

Native_SetSpawnLimit(Handle hPlugin, iNumParams) {
	int plyTarget = GetNativeCell(1)
	int iAmount = GetNativeCell(2)
	int bIsDoll = false
	
	if (iNumParams >= 3)
		bIsDoll = GetNativeCell(3)
	
	if (iAmount == 0) {
		if (bIsDoll) {
			g_iServerCurrent -= g_iDollCurrent[plyTarget]
			g_iPropCurrent[plyTarget] -= g_iDollCurrent[plyTarget]
			g_iDollCurrent[plyTarget] = 0
		} else {
			g_iServerCurrent -= g_iPropCurrent[plyTarget]
			g_iPropCurrent[plyTarget] = 0
		}
	} else {
		if (bIsDoll) {
			if(g_iDollCurrent[plyTarget] > 0)
				g_iDollCurrent[plyTarget] += iAmount
		}
		if (g_iPropCurrent[plyTarget] > 0)
			g_iPropCurrent[plyTarget] += iAmount
		if (g_iServerCurrent > 0)
			g_iServerCurrent += iAmount
	}
	if (g_iDollCurrent[plyTarget] < 0)
		g_iDollCurrent[plyTarget] = 0
	if (g_iPropCurrent[plyTarget] < 0)
		g_iPropCurrent[plyTarget] = 0
	if (g_iServerCurrent < 0)
		g_iServerCurrent = 0
}

Native_AllowToUse(Handle hPlugin, iNumParams) {
	new Client = GetNativeCell(1)


	if (!IsClientConnected(Client)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not connected.", Client)
		return -1
	}

	switch (g_iCvarEnabled) {
		case 0: {
			LM_PrintToChat(Client, "LazMod is not available or disabled!")
			return false
		}
		case 1: {
			if (!LM_IsAdmin(Client)) {
				LM_PrintToChat(Client, "LazMod is not available or disabled.")
				return false
			} else
				return true
		}
		default: return true
	}
	
}

Native_AllowFly(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)
	if (!IsClientConnected(plyClient)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not connected.", plyClient)
		return -1
	}

	AdminId adminId = GetUserAdmin(plyClient)
	if (!g_iCvarFly && GetAdminFlag(adminId, Admin_Custom1) == false) {
		LM_PrintToChat(plyClient, "Fly is not available or disabled.")
		return false
	} else
		return true
	
	
}

Native_IsAdmin(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)

	if (!IsClientConnected(plyClient)){
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not connected.", plyClient)
		return -1
	}

	new AdminId:Aid = GetUserAdmin(plyClient)
	if (GetAdminFlag(Aid, Admin_Ban))
		return true
	else
		return false
	
	
}

Native_GetClientAimEntity(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)
	bool bShowMsg = GetNativeCell(2)
	bool bIncClient = false
	float vOrigin[3], vAngles[3]
	GetClientEyePosition(plyClient, vOrigin)
	GetClientEyeAngles(plyClient, vAngles)
	
	if (iNumParams >= 3)
		bIncClient = GetNativeCell(3)
	
	// Command Range Limit
	{
		/*
		float AnglesVec[3], float EndPoint[3], float Distance
		if (LM_IsAdmin(Client))
			Distance = 50000.0
		else
			Distance = 1000.0
		GetClientEyeAngles(Client,vAngles)
		GetClientEyePosition(Client,vOrigin)
		GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR)

		EndPoint[0] = vOrigin[0] + (AnglesVec[0]*Distance)
		EndPoint[1] = vOrigin[1] + (AnglesVec[1]*Distance)
		EndPoint[2] = vOrigin[2] + (AnglesVec[2]*Distance)
		Handle trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_SHOT, RayType_EndPoint, TraceEntityFilter, Client)
		*/
	}
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilter, plyClient)
	
	if (TR_DidHit(trace)) {
		int entProp = TR_GetEntityIndex(trace)
		
		if (entProp > 0 && IsValidEntity(entProp)) {
			if(!bIncClient) {
				if (!(LM_IsPlayer(entProp))) {
					CloseHandle(trace)
					return entProp
				}
			} else {
				CloseHandle(trace)
				return entProp
			}
		}
	}
	
	if (bShowMsg)
		LM_PrintToChat(plyClient, "You dont have a target or target invalid.")
	
	CloseHandle(trace)
	return -1
}
bool TraceEntityFilter(entity, mask, any data) {
    return data != entity
}

Native_IsEntityOwner(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)
	int entProp = GetNativeCell(2)
	bool bIngoreCvar = false
	
	if (iNumParams >= 3)
		bIngoreCvar = GetNativeCell(3)
	
	if (LM_GetEntityOwner(entProp) != plyClient) {
		if (!LM_IsAdmin(plyClient)) {
			if (LM_IsPlayer(entProp)) {
				LM_PrintToChat(plyClient, "You are not allowed to do this to players!")
				return false
			}
			if (LM_GetEntityOwner(entProp) == -1) {
				if (!bIngoreCvar) {
					if (!g_iCvarNonOwner) {
						LM_PrintToChat(plyClient, "This prop does not belong to you!")
						return false
					} else
						return true
				} else
					return true
			} else {
				LM_PrintToChat(plyClient, "This prop does not belong to you!")
				return false
			}
		} else
			return true
	} else
		return true
}

Native_LogCmd(Handle hPlugin, iNumParams) {
	new Client = GetNativeCell(1)
	char szCmd[33], szArgs[128]
	GetNativeString(2, szCmd, sizeof(szCmd))
	GetNativeString(3, szArgs, sizeof(szArgs))
	
	static char szLogPath[64]
	char szTime[16], szName[33], szAuthid[33]
	
	FormatTime(szTime, sizeof(szTime), "%Y-%m-%d")
	GetClientName(Client, szName, sizeof(szName))
	GetClientAuthId(Client, AuthId_Steam2, szAuthid, sizeof(szAuthid))
	
	BuildPath(Path_SM, szLogPath, 64, "logs/LazMod-%s.log", szTime)
	
	if (StrEqual(szArgs, "")) {
		LogToFile(szLogPath, "\"%s\" (%s) Cmd: %s", szName, szAuthid, szCmd)
		LogToGame("\"%s\" (%s) Cmd: %s", szName, szAuthid, szCmd)
	} else {
		LogToFile(szLogPath, "\"%s\" (%s) Cmd: %s, Args:%s", szName, szAuthid, szCmd, szArgs)
		LogToGame("\"%s\" (%s) Cmd: %s, Args:%s", szName, szAuthid, szCmd, szArgs)
	}
}

Native_PrintToChat(Handle hPlugin, iNumParams) {
	char szMsg[192]
	int written
	FormatNativeString(0, 2, 3, sizeof(szMsg), written, szMsg)
	if (GetNativeCell(1) > 0)
		PrintToChat(GetNativeCell(1), "%s %s", MSGTAG, szMsg)
}

Native_PrintToAll(Handle hPlugin, iNumParams) {
	char szMsg[192]
	int written
	FormatNativeString(0, 1, 2, sizeof(szMsg), written, szMsg)
	PrintToChatAll("%s%s", MSGTAG, szMsg)
}

Native_IsClientValid(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)
	int plyTarget = GetNativeCell(2)
	bool IsAlive, ReplyTarget
	if (iNumParams == 3)
		IsAlive = GetNativeCell(3)
	if (iNumParams == 4)
		ReplyTarget = GetNativeCell(4)
	
	if (plyTarget < 1 || plyTarget > 32)
		return false
	if (!IsClientInGame(plyTarget))
		return false
	else if (IsAlive) {
		if (!IsPlayerAlive(plyTarget)) {
			if (ReplyTarget) 
				LM_PrintToChat(plyClient, "This command can only be used on alive players.")
			else
				LM_PrintToChat(plyClient, "You cannot use the command while dead.")
			
			return false
		}
	}
	return true
}

Native_AddBlacklist(Handle hPlugin, iNumParams) {
	new Client = GetNativeCell(1)
	char szAuthid[33], szName[33], WriteToArray[128], szData[128]
	GetClientAuthId(Client, AuthId_Steam2, szAuthid, sizeof(szAuthid))
	GetClientName(Client, szName, sizeof(szName))
	
	new i
	for (i = 0; i < GetArraySize(g_hBlackListArray); i++) {
		GetArrayString(g_hBlackListArray , i, szData, sizeof(szData))
		if(StrEqual(szData, ""))
			break
	}
	
	Format(WriteToArray, sizeof(WriteToArray), "\"%s\"\t\t// %s\n", szAuthid, szName)
	if (SetArrayString(g_hBlackListArray, i, WriteToArray)) {
		WriteBlacklist()
		return true
	}

	return false
}

Native_RemoveBlacklist(Handle hPlugin, iNumParams) {
	new Client = GetNativeCell(1)
	char szAuthid[33], szName[33], szData[128]
	GetClientAuthId(Client, AuthId_Steam2, szAuthid, sizeof(szAuthid))
	GetClientName(Client, szName, sizeof(szName))
	
	new i
	for (i = 0; i < GetArraySize(g_hBlackListArray); i++) {
		GetArrayString(g_hBlackListArray , i, szData, sizeof(szData))
		if(StrContains(szData, szAuthid) != -1) {
			RemoveFromArray(g_hBlackListArray, i)
			WriteBlacklist()
			return true
		}
	}
	
	return false
}

Native_IsBlacklisted(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)
	char szAuthid[33], szData[128]
	bool bIsBlacklisted = false
	GetClientAuthId(plyClient, AuthId_Steam2, szAuthid, sizeof(szAuthid))

	for(int i = 0; i < GetArraySize(g_hBlackListArray); i++) {
		GetArrayString(g_hBlackListArray , i, szData, sizeof(szData))
		if(StrContains(szData, szAuthid) != -1) {
			bIsBlacklisted = true
			break
		}
	}
	
	if(bIsBlacklisted) {
		LM_PrintToChat(plyClient, "You have been blacklisted, so you cannot use LazMod :(")
		LM_PrintToChat(plyClient, "Ask admins to unblacklist you :(")
	
		return true
	}
	
	return false
}

Native_IsFuncProp(Handle hPlugin, iNumParams) {
	char szClass[32]
	int entProp = GetNativeCell(1)
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	if (StrContains(szClass, "func_", false) == 0 && !StrEqual(szClass, "func_physbox"))
		return true
	return false
}

Native_IsNpc(Handle hPlugin, iNumParams) {
	char szClass[32]
	int entProp = GetNativeCell(1)
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	if (StrContains(szClass, "npc_", false) == 0)
		return true
	return false
}

Native_IsPlayer(Handle hPlugin, iNumParams) {
	int entProp = GetNativeCell(1)
	if (GetEntityFlags(entProp) & (FL_CLIENT | FL_FAKECLIENT))
		return true
	return false
}

ReadBlackList() {
	char szFile[128]
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/lazmod/blacklist.ini")
	
	Handle hFile = OpenFile(szFile, "r")
	if (hFile == INVALID_HANDLE)
		return
	
	new iClients = 0
	while (!IsEndOfFile(hFile))
	{
		char szLine[255]
		if (!ReadFileLine(hFile, szLine, sizeof(szLine)))
			break
			
		SetArrayString(g_hBlackListArray, iClients++, szLine)
	}
	CloseHandle(hFile)
}

WriteBlacklist() {
	char szFile[128], szData[64]
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/lazmod/blacklist.ini")
	
	Handle hFile = OpenFile(szFile, "w")
	if (hFile == INVALID_HANDLE)
		return false
	
	for (int i = 0; i < GetArraySize(g_hBlackListArray); i++) {
		GetArrayString(g_hBlackListArray , i, szData, sizeof(szData))
		if(StrContains(szData, "STEAM_") != -1)
			WriteFileString(hFile, szData, false)
	}
	
	CloseHandle(hFile)
	return true
}
