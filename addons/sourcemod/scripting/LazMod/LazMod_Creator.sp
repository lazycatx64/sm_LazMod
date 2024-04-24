

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <vphysics>




Handle g_hPropNameArray
Handle g_hPropModelPathArray
Handle g_hPropTypeArray
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
	
	PrintToServer( "LazMod Creator loaded!" )
}

public Action Command_SpawnF(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !spawnf <Prop name> ")
		return Plugin_Handled
	}
	
	char spwansf[33]
	GetCmdArg(1, spwansf, sizeof(spwansf))
	
	FakeClientCommand(Client, "sm_spawn %s yes", spwansf)
	return Plugin_Handled
}

public Action Command_SpawnProp(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !spawn <Prop name>")
		LM_PrintToChat(Client, "Ex: !spawn goldbar")
		LM_PrintToChat(Client, "Ex: !spawn alyx")
		return Plugin_Handled
	}
	
	char szPropName[32], szPropFrozen[32], szModelPath[128]
	GetCmdArg(1, szPropName, sizeof(szPropName))
	GetCmdArg(2, szPropFrozen, sizeof(szPropFrozen))
	
	new IndexInArray = FindStringInArray(g_hPropNameArray, szPropName)
	
	if (IndexInArray != -1) {
		bool bIsDoll = false
		char szEntType[33]
		GetArrayString(g_hPropTypeArray, IndexInArray, szEntType, sizeof(szEntType))
		
		if (StrEqual(szEntType, "prop_ragdoll"))
			bIsDoll = true
		
		int entProp = CreateEntityByName(szEntType)

		if (LM_SetEntityOwner(entProp, Client, bIsDoll)) {
			float fOriginWatching[3], fOriginFront[3], fAngles[3], fRadiansX, fRadiansY
			
			GetClientEyePosition(Client, fOriginWatching)
			GetClientEyeAngles(Client, fAngles)
			
			fRadiansX = DegToRad(fAngles[0])
			fRadiansY = DegToRad(fAngles[1])
			
			fOriginFront[0] = fOriginWatching[0] + (100 * Cosine(fRadiansY) * Cosine(fRadiansX))
			fOriginFront[1] = fOriginWatching[1] + (100 * Sine(fRadiansY) * Cosine(fRadiansX))
			fOriginFront[2] = fOriginWatching[2] - 20
			
			GetArrayString(g_hPropModelPathArray, IndexInArray, szModelPath, sizeof(szModelPath))
			
			if (!IsModelPrecached(szModelPath))
				PrecacheModel(szModelPath)
			
			DispatchKeyValue(entProp, "model", szModelPath)
			
			if (StrEqual(szEntType, "prop_dynamic"))
				SetEntProp(entProp, Prop_Send, "m_nSolidType", 6)
			
			DispatchSpawn(entProp)
			TeleportEntity(entProp, fOriginFront, NULL_VECTOR, NULL_VECTOR)
			
			if (!StrEqual(szPropFrozen, "")) {
				if (Phys_IsPhysicsObject(entProp))
					Phys_EnableMotion(entProp, false)
			}
		} else
			RemoveEdict(entProp)
	} else {
		LM_PrintToChat(Client, "Prop not found: %s", szPropName)
	}

	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_spawn", szArgs)

	return Plugin_Handled
}

ReadProps() {
	BuildPath(Path_SM, g_szFile, sizeof(g_szFile), "configs/lazmod/props.ini")
	
	Handle iFile = OpenFile(g_szFile, "rt")
	if (iFile == INVALID_HANDLE)
		return
	
	new iCountProps = 0
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


