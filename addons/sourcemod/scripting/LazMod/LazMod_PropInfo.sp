


#include <sourcemod>
#include <sdktools>

#include <vphysics>

#include <lazmod>



Handle g_hHudTimer = INVALID_HANDLE
ConVar g_hCvarPropInfo
bool g_bCvarPropInfo


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
	
	g_hCvarPropInfo	= CreateConVar("lm_propinfo_enable", "1", "Enable the hud to display propinfo", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarPropInfo.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarPropInfo)

	PrintToServer( "LazMod PropInfo loaded!" )
}

Hook_CvarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	CvarChanged(convar)
}
void CvarChanged(Handle convar) {
	if (convar == g_hCvarPropInfo) {
		g_bCvarPropInfo = g_hCvarPropInfo.BoolValue

		if (g_bCvarPropInfo) {
			if (g_hHudTimer == INVALID_HANDLE)
				g_hHudTimer = CreateTimer(0.1, Display_Msgs, 0, TIMER_REPEAT)
				
		} else {
			if (g_hHudTimer != INVALID_HANDLE) {
				KillTimer(g_hHudTimer)
				g_hHudTimer = INVALID_HANDLE
			}
		}
	}


}

public Action Display_Msgs(Handle timer) {	
	for (int plyClient = 1; plyClient <= MaxClients; plyClient++) {		
		if (LM_IsClientValid(plyClient, plyClient, true) && !IsFakeClient(plyClient)) {
			int iAimTarget = LM_GetClientAimEntity(plyClient, false, true)
			// TODO: Max distance? GetVectorDistance()
			if (iAimTarget != -1 && IsValidEdict(iAimTarget))
				EntityInfo(plyClient, iAimTarget)
		}
	}
	return Plugin_Handled
}

void EntityInfo(plyClient, entTarget) {

	if (!g_bCvarPropInfo)
		return

	if (LM_IsEntFunc(entTarget))
		return
	
	if (LM_IsEntPlayer(entTarget)) {
		Display_Player(plyClient, entTarget)
		return
	}

	if (LM_IsEntNpc(entTarget)) {
		Display_Npc(plyClient, entTarget)
		return
	}
	
	Display_Prop(plyClient, entTarget)
	
	return
}


stock void Display_Player(int plyClient, int entTarget) {

	SetHudTextParams(0.015, 0.08, 0.1, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2)

	int iHealth = GetClientHealth(entTarget)
	// I forgor why, maybe prevent something stupid due to game engine
	if (iHealth <= 1) iHealth = 0

	if (LM_IsClientAdmin(plyClient)) {
		char szSteamId[32]
		GetClientAuthId(entTarget, AuthId_Steam2, szSteamId, sizeof(szSteamId))
		ShowHudText(plyClient, -1, "Player: %N\nHealth: %i\nUserID: %i\nSteamID:%s", entTarget, iHealth, GetClientUserId(entTarget), szSteamId)
	} else {
		ShowHudText(plyClient, -1, "Player: %N\nHealth: %i", entTarget, iHealth)
	}
	return

}

stock void Display_Npc(int plyClient, int entTarget) {

	SetHudTextParams(0.015, 0.08, 0.1, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2)

	char szClass[32]
	GetEdictClassname(entTarget, szClass, sizeof(szClass))

	int iHealth = GetEntProp(entTarget, Prop_Data, "m_iHealth")
	if (iHealth <= 1)
		iHealth = 0
		
	ShowHudText(plyClient, -1, "Classname: %s\nHealth: %i", szClass, iHealth)
	return

}

stock void Display_Prop(int plyClient, int entTarget) {

	SetHudTextParams(0.015, 0.08, 0.1, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2)

	char szOwner[32]
	int plyOwner = LM_GetEntOwner(entTarget)
	if (plyOwner != -1)
		GetClientName(plyOwner, szOwner, sizeof(szOwner))
	else if (plyOwner > MAXPLAYERS){
		szOwner = "*Disconnectd"
	} else {
		szOwner = "*None"
	}

	char szClass[32]
	GetEdictClassname(entTarget, szClass, sizeof(szClass))
	char szModel[128] 
	LM_GetEntModel(entTarget, szModel, sizeof(szModel))

	if (Phys_IsPhysicsObject(entTarget)) 
		ShowHudText(plyClient, -1, "Classname: %s\nIndex: %i\nModel: %s\nOwner: %s\nMass:%f", szClass, entTarget, szModel, szOwner, Phys_GetMass(entTarget))
	else 
		ShowHudText(plyClient, -1, "Classname: %s\nIndex: %i\nModel: %s\nOwner: %s", szClass, entTarget, szModel, szOwner)
	
	return

}
