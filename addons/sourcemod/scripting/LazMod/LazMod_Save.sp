

#include <sourcemod>
#include <regex>

#include <vphysics>
#include <smlib>

#include <lazmod>

Handle g_hFile[MAXPLAYERS]
char g_szFileName[MAXPLAYERS][PLATFORM_MAX_PATH]
char g_szListName[128]
char g_szSavePath[] = "data/lazmodsaves"

bool g_bIsRunning[MAXPLAYERS] = {false, ...}
int g_iCount[MAXPLAYERS]
int g_iError[MAXPLAYERS]
int g_iTryCount[MAXPLAYERS]

char g_szDataTypes[9][16] = {
    "classname",
    "model",
    "origin",
    "angles",
    "rendercolor",
    "alpha",
    "ncself",
    "health",
    "moveable"
}


// [ ]: Save load unbreaks
// [ ]: Save load NCs


public Plugin myinfo = {
	name = "LazMod - SaveSpawn",
	author = "LaZy cAt",
	description = "Saves the building progress.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	RegAdminCmd("sm_ss", Command_SaveSpawn, 0, "Save system ftw.")


	PrintToServer( "LazMod Save loaded!" )
}

public Action Command_SaveSpawn(plyClient, args) {

	if (g_bIsRunning[plyClient]) {
		LM_PrintToChat(plyClient, "Process is already running. Please Wait...")
		return Plugin_Handled
	}
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) && LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	
	char szMode[8], szSaveName[64], szSteamID[MAX_AUTHID_LENGTH]
	GetCmdArg(1, szMode, sizeof(szMode))
	GetCmdArg(2, szSaveName, sizeof(szSaveName))
	GetClientAuthId(plyClient, AuthId_Steam2, szSteamID, sizeof(szSteamID))
	ReplaceString(szSteamID, sizeof(szSteamID), ":", "-")
	
	g_szFileName[plyClient] = ""
	BuildPath(Path_SM, g_szFileName[plyClient], sizeof(g_szFileName[]), "%s/%s#%s.csv", g_szSavePath, szSteamID, szSaveName)
	
	g_hFile[plyClient] = INVALID_HANDLE
	g_iTryCount[plyClient] = 0
	g_iCount[plyClient] = 0
	g_iError[plyClient] = 0
	
	String_ToLower(szMode, szMode, sizeof(szMode))

	if ((StrEqual(szMode, "save") || StrEqual(szMode, "load") || StrEqual(szMode, "delete") || StrEqual(szMode, "info")) && args > 1) {

		if (!Save_CheckSaveName(plyClient, szSaveName))
			return Plugin_Handled
			
		if (StrEqual(szMode, "save")) {
			SaveSpawn_Save(plyClient, szSaveName)
			return Plugin_Handled

		} else if (StrEqual(szMode, "load")) {
			SaveSpawn_Load(plyClient)

		} else if (StrEqual(szMode, "info")) {
			SaveSpawn_Info(plyClient, szSaveName)

		} else if (StrEqual(szMode, "delete")) {
			SaveSpawn_Delete(plyClient)
		}


	} else if (StrEqual(szMode, "list")) {
		SaveSpawn_List(plyClient)

	} else {
		SaveSpawn_Usage(plyClient)

	}

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_ss", szArgs)

	return Plugin_Handled
}

void SaveSpawn_Usage(int plyClient) {
	LM_PrintToChat(plyClient, "SaveSpawn Usage:\n\
								  !ss save <SaveName>\n\
								  !ss load <SaveName>\n\
								  !ss info <SaveName>\n\
								  !ss delete <SaveName>\n\
								  !ss list")
	LM_PrintToChat(plyClient, "Note1: Save names can only be in letters and numbers, and can be up to 32 characters long." )
	LM_PrintToChat(plyClient, "Note2: Deleted saves cannot be undone." )
		

}

void SaveSpawn_Save(const int plyClient, const char[] szSaveName) {
	
	LM_PrintToChat(plyClient, "Gathering data, preparing to save...")
	g_bIsRunning[plyClient] = true
	
	Handle hSavePack
	CreateDataTimer(1.0, Timer_Save, hSavePack)
	WritePackCell(hSavePack, plyClient)
	WritePackString(hSavePack, szSaveName)
}

void SaveSpawn_Load(const int plyClient) {

	if (!FileExists(g_szFileName[plyClient])) {
		LM_PrintToChat(plyClient, "The save does not exist.")
		return
	}

	LM_PrintToChat(plyClient, "Loading the save, please Wait...")
	g_bIsRunning[plyClient] = true

	Handle hLoadPack
	CreateDataTimer(1.0, Timer_Load, hLoadPack)
	WritePackCell(hLoadPack, plyClient)
	WritePackString(hLoadPack, "0")

	return
	
}

void SaveSpawn_Info(const int plyClient, const char[] szSaveName) {

	Handle hFile = OpenFile(g_szFileName[plyClient], "r")
	if (hFile == INVALID_HANDLE) {
		LM_PrintToChat(plyClient, "Failed to read the save or save does not exist!")
		return
	}

	LM_PrintToChat(plyClient, "SaveSpawn '%s' info:", szSaveName)

	Regex reMap = CompileRegex("^# savemap\t(\\w.*)$")
	Regex reDate = CompileRegex("^# savedate\t(\\d+)$")
	Regex reCount = CompileRegex("^# propcount\t(\\d+)$")
	char szData[96], szDateTime[64] = ""
	while (ReadFileLine(hFile, szData, sizeof(szData)) && String_StartsWith(szData, "#")) {

		if (String_StartsWith(szData, "# savemap")) {
			if (MatchRegex(reMap, szData) > 0){
				GetRegexSubString(reMap, 1, szData, sizeof(szData))
				LM_PrintToChat(plyClient, "Saved on maps: %s", szData)
			} else {
				LM_PrintToChat(plyClient, "Saved on maps: n/a")
			}
		} else if (String_StartsWith(szData, "# savedate")) {
			if (MatchRegex(reDate, szData) > 0) {
				GetRegexSubString(reDate, 1, szData, sizeof(szData))
				FormatTime(szDateTime, sizeof(szDateTime), "%F %T (%c)", StringToInt(szData))
				LM_PrintToChat(plyClient, "Saved date: %s", szDateTime)
			} else {
				LM_PrintToChat(plyClient, "Saved date: n/a")
			}
		} else if (String_StartsWith(szData, "# propcount")) {
			if (MatchRegex(reCount, szData) > 0) {
				GetRegexSubString(reCount, 1, szData, sizeof(szData))
				LM_PrintToChat(plyClient, "Saved props: %s", szData)
			} else {
				LM_PrintToChat(plyClient, "Saved props: n/a")
			}
		}
	}
}

void SaveSpawn_Delete(int plyClient) {

	if (FileExists(g_szFileName[plyClient])) {
		if (DeleteFile(g_szFileName[plyClient]))
			LM_PrintToChat(plyClient, "Deleted save successfully.")
		else
			LM_PrintToChat(plyClient, "Delete save failed!")
		
	} else {
		LM_PrintToChat(plyClient, "The save does not exist.")
	}
}

void SaveSpawn_List(int plyClient) {

	// int iCount = 0
	char szSavePath[512]
	char szFileName[64]
	char szAuthSteamID[MAX_AUTHID_LENGTH], szFileSteamID[MAX_AUTHID_LENGTH], szSaveName[36]

	Regex reFile = CompileRegex("(.*)#(.*).csv$")
	Regex reMap = CompileRegex("^# savemap\t(\\w.*)$")
	Regex reDate = CompileRegex("^# savedate\t(\\d+)")
	Regex reCount = CompileRegex("^# propcount\t(\\d+)")

	LM_PrintToChat(plyClient, "Listing saves in console...")
	PrintToConsole(plyClient, "-----------------------------------------------------------------------------")
	PrintToConsole(plyClient, "| SaveName                         | Date       | Props | Maps")
	PrintToConsole(plyClient, "-----------------------------------------------------------------------------")

	GetClientAuthId(plyClient, AuthId_Steam2, szAuthSteamID, sizeof(szAuthSteamID))
	ReplaceString(szAuthSteamID, sizeof(szAuthSteamID), ":", "-")

	BuildPath(Path_SM, szSavePath, sizeof(szSavePath), g_szSavePath)
	if (!DirExists(szSavePath))
		return 

	DirectoryListing arDirList = OpenDirectory(szSavePath)
	while (arDirList.GetNext(szFileName, sizeof(szFileName))) {

		if (StrEqual(szFileName, ".") || StrEqual(szFileName, ".."))
			continue

		MatchRegex(reFile, szFileName)
		GetRegexSubString(reFile, 1, szFileSteamID, sizeof(szFileSteamID))
		if (!StrEqual(szFileSteamID, szAuthSteamID))
			continue

		GetRegexSubString(reFile, 2, szSaveName, sizeof(szSaveName))
		

		char szFilePath[128]
		BuildPath(Path_SM, szFilePath, sizeof(szFilePath), "%s/%s", g_szSavePath, szFileName)
		Handle hFile = OpenFile(szFilePath, "r")
		if (hFile == INVALID_HANDLE)
			continue

		char szData[96], szDateTime[64] = "          ", szMap[128] = ""
		int iPropCount = 0
		while (ReadFileLine(hFile, szData, sizeof(szData)) && String_StartsWith(szData, "#")) {

			if (MatchRegex(reMap, szData) > 0) {
				GetRegexSubString(reMap, 1, szData, sizeof(szData))
				if (strlen(szData) > 1)
					strcopy(szMap, sizeof(szMap), szData)
			} else if (MatchRegex(reDate, szData) > 0) {
				GetRegexSubString(reDate, 1, szData, sizeof(szData))
				FormatTime(szDateTime, sizeof(szDateTime), "%F", StringToInt(szData))
			} else if (MatchRegex(reCount, szData) > 0) {
				GetRegexSubString(reCount, 1, szData, sizeof(szData))
				iPropCount = StringToInt(szData)
			}
		}
		Format(szSaveName, sizeof(szSaveName), "| %s ", szSaveName)
		while (strlen(szSaveName) < sizeof(szSaveName)-2) {
			StrCat(szSaveName, sizeof(szSaveName), " ")
		}
		PrintToConsole(plyClient, "%s | %s | %5d | Maps:%s", szSaveName, szDateTime, iPropCount, szMap)
		CloseHandle(hFile)
	}
	return
}


public Action Timer_Save(Handle hTimer, Handle hDataPack) {
	
	char szSaveName[32]
	ResetPack(hDataPack)
	int plyClient = ReadPackCell(hDataPack)
	ReadPackString(hDataPack, szSaveName, sizeof(szSaveName))
	
	if (!LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	

	// Count if theres anything to save
	char szCls[32]
	int iPreCount = 0
	for (int i = 0; i < GetMaxEntities(); i++) {
		if (!IsValidEdict(i))
			continue
		if (LM_GetEntOwner(i) != plyClient)
			continue
		LM_GetEntClassname(i, szCls, sizeof(szCls))
		if (!String_StartsWith(szCls, "prop_physics") && !String_StartsWith(szCls, "prop_dynamic"))
			continue

		iPreCount++
	}
	
	if (iPreCount == 0) {
		LM_PrintToChat(plyClient, "Found no savable prop, build something first!")
		g_bIsRunning[plyClient] = false
		return Plugin_Handled
	}



	// Extract map list from old save if theres one
	char szDataMap[64]
	if (FileExists(g_szFileName[plyClient])) {
		Handle hFile = OpenFile(g_szFileName[plyClient], "r")
		Regex reMap = CompileRegex("^# savemap\t((\\w+),?(\\w+)?,?(\\w+)?)?")

		char szData[96], szCurrentMap[32], szMaps[64], szMap1[32], szMap2[32], szMap3[32]
		while (ReadFileLine(hFile, szData, sizeof(szData)) && String_StartsWith(szData, "#")) {

			if (MatchRegex(reMap, szData) > 0) {
				GetRegexSubString(reMap, 1, szMaps, sizeof(szMaps))
				GetRegexSubString(reMap, 2, szMap1, sizeof(szMap1))
				GetRegexSubString(reMap, 3, szMap2, sizeof(szMap2))
				GetRegexSubString(reMap, 4, szMap3, sizeof(szMap3))
				GetCurrentMap(szCurrentMap, sizeof(szCurrentMap))
				if (StrContains(szMaps, szCurrentMap)) {
					Format(szDataMap, sizeof(szDataMap), "%s,%s,%s", szCurrentMap, StrEqual(szMap1, szCurrentMap)?szMap2:szMap1, StrEqual(szMap2, szCurrentMap)?szMap3:szMap2)
				} else {
					Format(szDataMap, sizeof(szDataMap), "%s,%s,%s", szCurrentMap, szMap1, szMap2)
				}
			}
		}
		LM_PrintToChat(plyClient, "mapp %s", szCurrentMap)
		LM_PrintToChat(plyClient, "szMaps %s", szMaps)
		LM_PrintToChat(plyClient, "szMap1 %s", szMap1)
		LM_PrintToChat(plyClient, "szMap2 %s", szMap2)
		LM_PrintToChat(plyClient, "szMap3 %s", szMap3)
		CloseHandle(hFile)
	} else {
		GetCurrentMap(szDataMap, sizeof(szDataMap))
	}


	// Try backup old save by renaming it if theres one
	char szBackupFile[PLATFORM_MAX_PATH] = ""
	if (FileExists(g_szFileName[plyClient])) {
		LM_PrintToChat(plyClient, "Found an existing save and started backing up...")

		Format(szBackupFile, sizeof(szBackupFile), "%s.bak", g_szFileName[plyClient])
		
		if (!RenameFile(szBackupFile, g_szFileName[plyClient])) {
			LM_PrintToChat(plyClient, "Unable to back up old save, please try to save with a new savename or contact admins.")
			g_bIsRunning[plyClient] = false
			return Plugin_Handled
		}
		LM_PrintToChat(plyClient, "Backup completed!")

		
	}
	
	// Try create new file
	g_hFile[plyClient] = OpenFile(g_szFileName[plyClient], "w")
	if (g_hFile[plyClient] == INVALID_HANDLE) {
		LM_PrintToChat(plyClient, "Unable to create new save, please try to save with a new savename or contact admins.")

		if (!StrEqual(szBackupFile, "")) {
			if (RenameFile(g_szFileName[plyClient], szBackupFile)){
				LM_PrintToChat(plyClient, "Old save has been restored.")
				szBackupFile = ""
			} else {
				LM_PrintToChat(plyClient, "Failed to restore old save!!")
			}
		}
		g_bIsRunning[plyClient] = false
		return Plugin_Handled
	}
	
	LM_PrintToChat(plyClient, "Found %d savable props, the save will now begin...", iPreCount)
	
	
	// Save begin
	char szSteamID[MAX_AUTHID_LENGTH], szHeaders[256]
	GetClientAuthId(plyClient, AuthId_Steam2, szSteamID, sizeof(szSteamID))
	ImplodeStrings(g_szDataTypes, sizeof(g_szDataTypes), "\t", szHeaders, sizeof(szHeaders))

	WriteFileLine(g_hFile[plyClient], "### Additional data ###")
	WriteFileLine(g_hFile[plyClient], "# steamid\t%s", szSteamID)
	WriteFileLine(g_hFile[plyClient], "# knownname\t%N", plyClient)
	WriteFileLine(g_hFile[plyClient], "# savename\t%s", szSaveName)
	WriteFileLine(g_hFile[plyClient], "# savemap\t%s", szDataMap)
	WriteFileLine(g_hFile[plyClient], "# savedate\t%d", GetTime())
	WriteFileLine(g_hFile[plyClient], "# propcount\t%d", iPreCount)
	WriteFileLine(g_hFile[plyClient], "%s", szHeaders)

	char szClass[32], szModel[128]
	float vOrigin[3], vAngles[3]
	int iColors[3], iAlpha, iCount = 0
	
	
	for (int entProp = 0; entProp < GetMaxEntities(); entProp++) {
		if (!IsValidEdict(entProp))
			continue
		if (LM_GetEntOwner(entProp) != plyClient)
			continue
		LM_GetEntClassname(entProp, szClass, sizeof(szClass))
		if (!String_StartsWith(szClass, "prop_physics") && !String_StartsWith(szClass, "prop_dynamic"))
			continue

		LM_GetEntOrigin(entProp, vOrigin)
		LM_GetEntAngles(entProp, vAngles)
		LM_GetEntModel(entProp, szModel, sizeof(szModel))
		GetEntityRenderColor(entProp, iColors[0], iColors[1], iColors[2], iAlpha)


		WriteFileLine(g_hFile[plyClient], "%s\t%s\t%.3f,%.3f,%.3f\t%.3f,%.3f,%.3f\t%i %i %i\t%i\t0\t0\t0", 
				szClass, szModel, vOrigin[0], vOrigin[1], vOrigin[2], vAngles[0], vAngles[1], vAngles[2], iColors[0], iColors[1], iColors[2], iAlpha)
		iCount++
	}
	
	FlushFile(g_hFile[plyClient])
	CloseHandle(g_hFile[plyClient])
	if (iCount > 0) {
		LM_PrintToChat(plyClient, "Saved %d props with savename '%s'", iCount, szSaveName)
		
		if (!StrEqual(szBackupFile, ""))
			DeleteFile(szBackupFile)

	} else {
		LM_PrintToChat(plyClient, "Nothing to save, removing created data.")
		DeleteFile(g_szFileName[plyClient])
		if (!StrEqual(szBackupFile, "")) {
			if (RenameFile(g_szFileName[plyClient], szBackupFile)){
				LM_PrintToChat(plyClient, "Old save has been restored.")
				szBackupFile = ""
			} else {
				LM_PrintToChat(plyClient, "Failed to restore old save!!")
			}
		}

	}
	g_bIsRunning[plyClient] = false

	return Plugin_Handled
}

public Action Timer_Load(Handle hTimer, Handle hDataPack) {
	ResetPack(hDataPack)
	char szDataHeader[255]
	bool bRegOwnerError = false
	int plyClient = ReadPackCell(hDataPack)
	ReadPackString(hDataPack, szDataHeader, sizeof(szDataHeader))
	
	int entProp = -1

	if (!LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	
	if (g_hFile[plyClient] == INVALID_HANDLE) {
		g_hFile[plyClient] = OpenFile(g_szFileName[plyClient], "r")
		g_iTryCount[plyClient]++
		if (g_iTryCount[plyClient] < 3) {
			Handle hNewPack
			CreateDataTimer(0.2, Timer_Load, hNewPack)
			WritePackCell(hNewPack, plyClient)
			WritePackString(hNewPack, szDataHeader)
		} else {
			LM_PrintToChat(plyClient, "Save found but unable to load! Contact admins!")
			g_hFile[plyClient] = INVALID_HANDLE
			g_iTryCount[plyClient] = 0
			return Plugin_Handled
		}
	} else {
		char szLoadString[255]
		if (ReadFileLine(g_hFile[plyClient], szLoadString, sizeof(szLoadString))) {
			
			if (!LM_CheckMaxEdict()) {
				LM_PrintToChat(plyClient, "Server has no more room for new props, current loading will be terminated!")
				bRegOwnerError = true

			} else if (String_StartsWith(szLoadString, "###")) {
				// pass
				
			} else if (String_StartsWith(szLoadString, "#")) {
				char szBuffer[2][255]
				ReplaceString(szLoadString, sizeof(szLoadString), "# ", "")

				ExplodeString(szLoadString, "\t", szBuffer, sizeof(szBuffer), sizeof(szBuffer[]))
				String_Trim(szBuffer[1], szBuffer[1], sizeof(szBuffer[]))
				if (String_StartsWith(szBuffer[0], "propcount"))
					LM_PrintToChat(plyClient, "Found %s props in save, start loading...", szBuffer[1] )

			} else if (StrContains(szLoadString, "classname") != -1 && StrContains(szLoadString, "origin") != -1) {
				// Makes sure data loaded in correct order
				szDataHeader = szLoadString
				
			} else if (StrContains(szLoadString, "prop_physics") != -1 || StrContains(szLoadString, "prop_dynamic") != -1) {
				
				char szDataBuffer[9][255], szHeaderBuffer[9][255], szClass[32], szModel[128], szColor[16], szAlpha[4]
				char szOrigin[3][16], szAngles[3][16]
				float vOrigin[3], vAngles[3]
				int iNCself, iHealth, iMoveable
				ExplodeString(szDataHeader, "\t", szHeaderBuffer, 9, 255)
				ExplodeString(szLoadString, "\t", szDataBuffer, 9, 255)

				for (int i = 0; i < sizeof(szDataBuffer); i++) {
					if (StrEqual(szHeaderBuffer[i], "classname")) {
						Format(szClass, sizeof(szClass), "%s", szDataBuffer[i])
					} else if (StrEqual(szHeaderBuffer[i], "model")) {
						Format(szModel, sizeof(szModel), "%s", szDataBuffer[i])
					} else if (StrEqual(szHeaderBuffer[i], "origin")) {
						ExplodeString(szDataBuffer[i], ",", szOrigin, sizeof(szOrigin), sizeof(szOrigin[]))
						vOrigin[0] = StringToFloat(szOrigin[0])
						vOrigin[1] = StringToFloat(szOrigin[1])
						vOrigin[2] = StringToFloat(szOrigin[2])
					} else if (StrEqual(szHeaderBuffer[i], "angles")) {
						ExplodeString(szDataBuffer[i], ",", szAngles, sizeof(szAngles), sizeof(szAngles[]))
						vAngles[0] = StringToFloat(szAngles[0])
						vAngles[1] = StringToFloat(szAngles[1])
						vAngles[2] = StringToFloat(szAngles[2])
					} else if (StrEqual(szHeaderBuffer[i], "rendercolor")) {
						if (strlen(szDataBuffer[i]) < 1)
							szDataBuffer[i] = "255 255 255"
						Format(szColor, sizeof(szColor), "%s", szDataBuffer[i])
					} else if (StrEqual(szHeaderBuffer[i], "alpha")) {
						if (strlen(szDataBuffer[i]) < 1)
							szDataBuffer[i] = "255"
						Format(szAlpha, sizeof(szAlpha), "%s", szDataBuffer[i])
					} else if (StrEqual(szHeaderBuffer[i], "ncself")) {
						if (strlen(szDataBuffer[i]) < 1)
							szDataBuffer[i] = "0"
						iNCself = StringToInt(szDataBuffer[i])
					} else if (StrEqual(szHeaderBuffer[i], "health")) {
						if (strlen(szDataBuffer[i]) < 1)
							szDataBuffer[i] = "0"
						iHealth = StringToInt(szDataBuffer[i])
					} else if (StrEqual(szHeaderBuffer[i], "moveable")) {
						if (strlen(szDataBuffer[i]) < 1)
							szDataBuffer[i] = "0"
						iMoveable = StringToInt(szDataBuffer[i])
					}
				}
				
				// if (iHealth == 2)
				// 	iHealth = 999999999
				// if (iHealth == 1)
				// 	iHealth = 50
				if (StrEqual(szClass, "prop_physics"))
					szClass = "prop_physics_override"
				else if (StrEqual(szClass, "prop_dynamic"))
					szClass = "prop_dynamic_override"


				entProp = LM_CreateEntity(plyClient, szClass, szModel, vOrigin, vAngles)
				
				if (entProp < 0) {
					g_iError[plyClient]++

				} else {
					DispatchKeyValue(entProp, "rendermode", "5")
					DispatchKeyValue(entProp, "rendercolor", szColor)
					DispatchKeyValue(entProp, "renderamt", szAlpha)
					DispatchSpawn(entProp)
					AcceptEntityInput(entProp, "disablemotion", -1)
					g_iCount[plyClient]++
					if (g_iCount[plyClient] > 99 && g_iCount[plyClient] % 100 == 0)
						LM_PrintToChat(plyClient, "Loaded %d props, still going...", g_iCount[plyClient])

				}
			}
		}
		if (!IsEndOfFile(g_hFile[plyClient]) && !bRegOwnerError && entProp >= -1) {
			Handle hNewPack
			CreateDataTimer(0.05, Timer_Load, hNewPack)
			WritePackCell(hNewPack, plyClient)
			WritePackString(hNewPack, szDataHeader)
		} else {
			CloseHandle(g_hFile[plyClient])
			g_bIsRunning[plyClient] = false
			LM_PrintToChat(plyClient, "Loaded %i props, failed to load %i props", g_iCount[plyClient], g_iError[plyClient])
			g_iCount[plyClient] = 0
			g_iError[plyClient] = 0
		}
	}
	return Plugin_Handled
}

stock Save_CheckSaveName(const int plyClient, const char[] szSaveName) {

	if (strlen(szSaveName) > 32) {
		LM_PrintToChat(plyClient, "The max SaveName length is 32!")
		return false
	}
	
	Regex hRegex = new Regex("^[A-Za-z0-9]+$")
	if (hRegex.Match(szSaveName) == -1) {
		LM_PrintToChat(plyClient, "The savename can only contain letters and numbers!")
		return false
	}
	
	return true
}

stock CheckFileExist(char[] szFileName) {

}

public CheckSaveList(plyClient, char[] szMode, char[] szSaveName, char[] szSteamID) {
	g_hFile[plyClient] = OpenFile(g_szListName, "a+")
	if (g_hFile[plyClient] == INVALID_HANDLE)
		return -1
	if (StrEqual(szMode, "save")) {
		char szListString[255], szBuffer[3][255]
		while (!IsEndOfFile(g_hFile[plyClient]))	{
			if (ReadFileLine(g_hFile[plyClient], szListString, sizeof(szListString))) {
				ExplodeString(szListString, " ", szBuffer, 3, 255)
				if (StrEqual(szSteamID, szBuffer[0]) && StrEqual(szSaveName, szBuffer[1])) {
					CloseHandle(g_hFile[plyClient])
					return true
				}
			}
		}
		char szTime[64]
		FormatTime(szTime, sizeof(szTime), "%Y/%m/%d")
		WriteFileLine(g_hFile[plyClient], "%s %s %s \t\t//%N", szSteamID, szSaveName, szTime, plyClient)
		PrintToConsole(plyClient, "%s %s %s \t\t//%N", szSteamID, szSaveName, szTime, plyClient)
		FlushFile(g_hFile[plyClient])
		CloseHandle(g_hFile[plyClient])
		return false
	} else if (StrEqual(szMode, "delete")) {
		char szArrayString[64][128], szArrayBuffer[64][3][128]
		for (int i = 0; i < 64; i++) {
			ReadFileLine(g_hFile[plyClient], szArrayString[i], sizeof(szArrayString))
			ExplodeString(szArrayString[i], " ", szArrayBuffer[i], 3, sizeof(szArrayBuffer))
			if (StrEqual(szSteamID, szArrayBuffer[i][0]) && StrEqual(szSaveName, szArrayBuffer[i][1]))
				szArrayString[i] = ""
				
			if (IsEndOfFile(g_hFile[plyClient]))
				break
		}
		CloseHandle(g_hFile[plyClient])
		if (!DeleteFile(g_szListName))
			return -1
		
		SortStrings(szArrayString, sizeof(szArrayString))
		g_hFile[plyClient] = OpenFile(g_szListName, "w+")
		for (int i = 0; i < 64; i++) {
			if (StrContains(szArrayString[i], "0-") == 0)
				WriteFileLine(g_hFile[plyClient], "%s", szArrayString[i])
		}
		FlushFile(g_hFile[plyClient])
		CloseHandle(g_hFile[plyClient])
		return true
	}
	CloseHandle(g_hFile[plyClient])
	return -1
}


