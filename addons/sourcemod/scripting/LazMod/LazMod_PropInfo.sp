


#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>



Handle g_hHudTimer = INVALID_HANDLE
Handle g_hCvarPropInfo = INVALID_HANDLE
int g_iCvarPropInfo


public Plugin myinfo = {
	name = "LazMod - PropInfo",
	author = "LaZycAt, hjkwe654",
	description = "Show props infomation on hud.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	LoadTranslations("common.phrases")
	g_hHudTimer = CreateTimer(0.1, Display_Msgs, 0, TIMER_REPEAT)
	
	g_hCvarPropInfo	= CreateConVar("lm_propinfo", "1", "Enable the hud to display propinfo", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_iCvarPropInfo = GetConVarBool(g_hCvarPropInfo)
	HookConVarChange(g_hCvarPropInfo, Hook_CvarPropInfo)

	PrintToServer( "LazMod PropInfo loaded!" )
}

public Hook_CvarPropInfo(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarPropInfo = GetConVarBool(g_hCvarPropInfo)

	if (StrEqual(newValue, "0")) {
		if (g_hHudTimer != INVALID_HANDLE) {
			KillTimer(g_hHudTimer)
			g_hHudTimer = INVALID_HANDLE
		}
			
	} else {
		if (g_hHudTimer == INVALID_HANDLE)
			g_hHudTimer = CreateTimer(0.1, Display_Msgs, 0, TIMER_REPEAT)
	}

}

public Action Display_Msgs(Handle timer) {	
	for (int plyClient = 1; plyClient <= MaxClients; plyClient++) {		
		if (LM_IsClientValid(plyClient, plyClient, true) && !IsFakeClient(plyClient)) {
			int iAimTarget = LM_GetClientAimEntity(plyClient, false, true)
			if (iAimTarget != -1 && IsValidEdict(iAimTarget))
				EntityInfo(plyClient, iAimTarget)
		}
	}
	return Plugin_Handled
}

void EntityInfo(plyClient, entTarget) {

	if (!g_iCvarPropInfo)
		return

	if (LM_IsFuncProp(entTarget))
		return
	
	SetHudTextParams(0.015, 0.08, 0.1, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2)
	if (LM_IsPlayer(entTarget)) {
		int iHealth = GetClientHealth(entTarget)
		if (iHealth <= 1)
			iHealth = 0

		if (LM_IsAdmin(plyClient)) {
			char szSteamId[32]
			GetClientAuthId(entTarget, AuthId_Steam2, szSteamId, sizeof(szSteamId))
			ShowHudText(plyClient, -1, "Player: %N\nHealth: %i\nUserID: %i\nSteamID:%s", entTarget, iHealth, GetClientUserId(entTarget), szSteamId)
		} else {
			ShowHudText(plyClient, -1, "Player: %N\nHealth: %i", entTarget, iHealth)
		}
		return
	}

	char szClass[32]
	GetEdictClassname(entTarget, szClass, sizeof(szClass))
	if (LM_IsNpc(entTarget)) {
		int iHealth = GetEntProp(entTarget, Prop_Data, "m_iHealth")
		if (iHealth <= 1)
			iHealth = 0
		ShowHudText(plyClient, -1, "Classname: %s\nHealth: %i", szClass, iHealth)
		return
	}
	
	char szOwner[32]
	int plyOwner = LM_GetEntityOwner(entTarget)
	if (plyOwner != -1)
		GetClientName(plyOwner, szOwner, sizeof(szOwner))
	else if (plyOwner > MAXPLAYERS){
		szOwner = "*Disconnectd"
	} else {
		szOwner = "*None"
	}

	char szModel[128] 
	GetEntPropString(entTarget, Prop_Data, "m_ModelName", szModel, sizeof(szModel))
	
	if (Phys_IsPhysicsObject(entTarget)) 
		ShowHudText(plyClient, -1, "Classname: %s\nIndex: %i\nModel: %s\nOwner: %s\nMass:%f", szClass, entTarget, szModel, szOwner, Phys_GetMass(entTarget))
	else 
		ShowHudText(plyClient, -1, "Classname: %s\nIndex: %i\nModel: %s\nOwner: %s", szClass, entTarget, szModel, szOwner)
	
	return
}



