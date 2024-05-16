

#include <sourcemod>
#include <sdktools>

#include <lazmod>

Handle g_hBlackListArray

public Plugin myinfo = {
	name = "LazMod - Blacklist",
	author = "LaZycAt, hjkwe654",
	description = "Add client to blacklist that cant use BuildMod.",
	version = LAZMOD_VER,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max) {

	CreateNative("LM_IsBlacklisted",	Native_IsBlacklisted)
	
	return APLRes_Success
}

public OnPluginStart() {	
	LoadTranslations("common.phrases")
	RegAdminCmd("sm_bl", Command_AddBL, ADMFLAG_BAN, "Add client to LazMod blacklist to prevent them from using LazMod commands.")
	RegAdminCmd("sm_unbl", Command_RemoveBL, ADMFLAG_BAN, "Remove client from blacklist")

	g_hBlackListArray = CreateArray(33, 128);	// 33 arrays, every array size is 128
	ReadBlackList()
	PrintToServer( "LazMod Blacklist loaded!" )
}

public Action Command_AddBL(plyClient, args) {
	if (args < 1) {
		ReplyToCommand(plyClient, "[SM] Usage: sm_bl <#userid|name>")
		return Plugin_Handled
	}
	
	char arg[33]
	GetCmdArg(1, arg, sizeof(arg))
	
	char target_name[MAX_TARGET_LENGTH]
	int target_list[MAXPLAYERS], target_count
	bool tn_is_ml
	
	if ((target_count = ProcessTargetString(arg, plyClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(plyClient, target_count)
		return Plugin_Handled
	}

	for (int i = 0; i < target_count; i++) {
		int target = target_list[i]
		
		if(LM_IsBlacklisted(target)) {
			LM_PrintToChat(plyClient, "%s is already blacklisted!", target_name)
			return Plugin_Handled
		} else 
			AddBlacklist(target)
	}
	
	for (int i = 0; i < MaxClients; i++) {
		if (LM_IsClientValid(i, i)) {
			LM_PrintToChat(i, "%N added %s to LazMod blacklist :(", plyClient, target_name)
		}
	}
	return Plugin_Handled
}

public Action Command_RemoveBL(plyClient, args) {
	if (args < 1) {
		ReplyToCommand(plyClient, "[SM] Usage: sm_unbl <#userid|name>")
		return Plugin_Handled
	}
	
	char arg[33]
	GetCmdArg(1, arg, sizeof(arg))
	
	char target_name[MAX_TARGET_LENGTH]
	int target_list[MAXPLAYERS], target_count
	bool tn_is_ml
	
	if ((target_count = ProcessTargetString(arg, plyClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(plyClient, target_count)
		return Plugin_Handled
	}

	for (int i = 0; i < target_count; i++) {
		int target = target_list[i]
		
		if(!RemoveBlacklist(target)) {
			LM_PrintToChat(plyClient, "%s is not in blacklist!", target_name)
			return Plugin_Handled
		}
	}
	
	if(tn_is_ml) {
		for (int i = 0; i < MaxClients; i++) {
			if (LM_IsClientValid(i, i))
				LM_PrintToChat(i, "%N removed %s from LazMod blacklist :)", plyClient, target_name)
		}
	} else {
		for (int i = 0; i < MaxClients; i++) {
			if (LM_IsClientValid(i, i))
				LM_PrintToChat(i, "%N removed %s from LazMod blacklist :)", plyClient, target_name)
		}
	}
	
	return Plugin_Handled
}

AddBlacklist(int plyClient) {
	char szAuthid[MAX_AUTHID_LENGTH], szName[33], WriteToArray[128], szData[128]
	GetClientAuthId(plyClient, AuthId_Steam2, szAuthid, sizeof(szAuthid))
	GetClientName(plyClient, szName, sizeof(szName))
	
	int i
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

RemoveBlacklist(int plyClient) {
	char szAuthid[MAX_AUTHID_LENGTH], szName[33], szData[128]
	GetClientAuthId(plyClient, AuthId_Steam2, szAuthid, sizeof(szAuthid))
	GetClientName(plyClient, szName, sizeof(szName))
	
	for (int i = 0; i < GetArraySize(g_hBlackListArray); i++) {
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
	char szAuthid[MAX_AUTHID_LENGTH], szData[128]
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

ReadBlackList() {
	char szFile[128]
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/lazmod/blacklist.ini")
	
	Handle hFile = OpenFile(szFile, "r")
	if (hFile == INVALID_HANDLE)
		return
	
	int iClients = 0
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
