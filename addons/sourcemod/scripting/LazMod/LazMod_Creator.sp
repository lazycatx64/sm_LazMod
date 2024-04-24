#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <vphysics>

new bool:g_bClientLang[MAXPLAYERS];
new Handle:g_hCookieClientLang;

new Handle:g_hPropNameArray;
new Handle:g_hPropModelPathArray;
new Handle:g_hPropTypeArray;
new String:g_szFile[128];

public Plugin:myinfo = {
	name = "BuildMod - Creator",
	author = "LaZycAt, hjkwe654",
	description = "Create props to build.",
	version = LAZMOD_VER,
	url = ""
};

public OnPluginStart() {
	RegAdminCmd("sm_spawnf", Command_SpawnF, 0, "Spawn frozen prop.");
	RegAdminCmd("sm_sf", Command_SpawnF, 0, "Spawn frozen prop.");
	RegAdminCmd("sm_spawn", Command_SpawnProp, 0, "Spawn Props.");
	RegAdminCmd("sm_s", Command_SpawnProp, 0, "Spawn Props.");
	
	g_hCookieClientLang = RegClientCookie("cookie_BuildModClientLang", "BuildMod Client Language.", CookieAccess_Private);
	g_hPropNameArray = CreateArray(33, 2048);		// Max Prop List is 1024-->2048
	g_hPropModelPathArray = CreateArray(128, 2048);	// Max Prop List is 1024-->2048
	g_hPropTypeArray = CreateArray(33, 2048);		// Max Prop List is 1024-->2048
	ReadProps();
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

public Action:Command_SpawnF(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "用法: !spawnf/!sf <物件名稱> ");
		else
			LM_PrintToChat(Client, "Usage: !spawnf/!sf <Prop name> ");
		return Plugin_Handled;
	}
	
	new String:spwansf[33];
	GetCmdArg(1, spwansf, sizeof(spwansf));
	
	FakeClientCommand(Client, "sm_spawn %s yes", spwansf);
	return Plugin_Handled;
}

public Action:Command_SpawnProp(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: !spawn/!s <物件名稱> ");
			LM_PrintToChat(Client, "例: !spawn goldbar");
			LM_PrintToChat(Client, "例: !spawn alyx");
		} else {
			LM_PrintToChat(Client, "Usage: !spawn/!s <Prop name>");
			LM_PrintToChat(Client, "Ex: !spawn goldbar");
			LM_PrintToChat(Client, "Ex: !spawn alyx");
		}
		return Plugin_Handled;
	}
	
	new String:szPropName[32], String:szPropFrozen[32], String:szModelPath[128];
	GetCmdArg(1, szPropName, sizeof(szPropName));
	GetCmdArg(2, szPropFrozen, sizeof(szPropFrozen));
	
	new IndexInArray = FindStringInArray(g_hPropNameArray, szPropName);
	
	if (StrEqual(szPropName, "explosivecan") && !LM_IsAdmin(Client, true)) {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "你需要 \x04二級建造權限\x01 才能叫出此物件!");
		else
			LM_PrintToChat(Client, "You need \x04L2 Build Access\x01 to spawn this prop!");
		return Plugin_Handled;
	}
	
	if (IndexInArray != -1) {
		new bool:bIsDoll = false;
		new String:szEntType[33];
		GetArrayString(g_hPropTypeArray, IndexInArray, szEntType, sizeof(szEntType));
		
		if (!LM_IsAdmin(Client, true)) {
			if (StrEqual(szPropName, "explosivecan") || StrEqual(szEntType, "prop_ragdoll")) {
				if (g_bClientLang[Client])
					LM_PrintToChat(Client, "你需要 \x04二級建造權限\x01 才能叫出此物件!");
				else
					LM_PrintToChat(Client, "You need \x04L2 Build Access\x01 to spawn this prop!");
				return Plugin_Handled;
			}
		}
		if (StrEqual(szEntType, "prop_ragdoll"))
			bIsDoll = true;
		
		new iEntity = CreateEntityByName(szEntType);

		if (LM_SetEntityOwner(iEntity, Client, bIsDoll)) {
			new Float:fOriginWatching[3], Float:fOriginFront[3], Float:fAngles[3], Float:fRadiansX, Float:fRadiansY;
			
			GetClientEyePosition(Client, fOriginWatching);
			GetClientEyeAngles(Client, fAngles);
			
			fRadiansX = DegToRad(fAngles[0]);
			fRadiansY = DegToRad(fAngles[1]);
			
			fOriginFront[0] = fOriginWatching[0] + (100 * Cosine(fRadiansY) * Cosine(fRadiansX));
			fOriginFront[1] = fOriginWatching[1] + (100 * Sine(fRadiansY) * Cosine(fRadiansX));
			fOriginFront[2] = fOriginWatching[2] - 20;
			
			GetArrayString(g_hPropModelPathArray, IndexInArray, szModelPath, sizeof(szModelPath));
			
			if (!IsModelPrecached(szModelPath))
				PrecacheModel(szModelPath);
			
			DispatchKeyValue(iEntity, "model", szModelPath);
			
			if (StrEqual(szEntType, "prop_dynamic"))
				SetEntProp(iEntity, Prop_Send, "m_nSolidType", 6);
			
			DispatchSpawn(iEntity);
			TeleportEntity(iEntity, fOriginFront, NULL_VECTOR, NULL_VECTOR);
			
			if (!StrEqual(szPropFrozen, "")) {
				if (Phys_IsPhysicsObject(iEntity))
					Phys_EnableMotion(iEntity, false);
			}
		} else
			RemoveEdict(iEntity);
	} else {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "該物件不存在: %s", szPropName);
		else
			LM_PrintToChat(Client, "Prop not found: %s", szPropName);
	}
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_spawn", szArgs);
	return Plugin_Handled;
}

ReadProps() {
	BuildPath(Path_SM, g_szFile, sizeof(g_szFile), "configs/buildmod/props.ini");
	
	new Handle:iFile = OpenFile(g_szFile, "rt");
	if (iFile == INVALID_HANDLE)
		return;
	
	new iCountProps = 0;
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
	
		ReadPropsLine(szLine, iCountProps++);
	}
	CloseHandle(iFile);
}

ReadPropsLine(const String:szLine[], iCountProps) {
	decl String:szPropInfo[3][128];
	ExplodeString(szLine, ", ", szPropInfo, sizeof(szPropInfo), sizeof(szPropInfo[]));
	
	StripQuotes(szPropInfo[0]);
	SetArrayString(g_hPropNameArray, iCountProps, szPropInfo[0]);
	
	StripQuotes(szPropInfo[1]);
	SetArrayString(g_hPropModelPathArray, iCountProps, szPropInfo[1]);
	
	StripQuotes(szPropInfo[2]);
	SetArrayString(g_hPropTypeArray, iCountProps, szPropInfo[2]);
}


