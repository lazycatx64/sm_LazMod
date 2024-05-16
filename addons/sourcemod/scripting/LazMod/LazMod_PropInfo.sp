


#include <sourcemod>
#include <sdktools>

#include <vphysics>

#include <lazmod>



Handle g_hHudTimer = INVALID_HANDLE

ConVar g_hCvarPropInfoEnabled
bool g_bCvarPropInfoEnabled

ConVar g_hCvarUpdateInterval
float g_fCvarUpdateInterval

ConVar g_hCvarMaxDistance
float g_fCvarMaxDistance

ConVar g_hCvarShowClass
int g_iCvarShowClass

ConVar g_hCvarShowOrigin
int g_iCvarShowOrigin

ConVar g_hCvarShowAngles
int g_iCvarShowAngles


public Plugin myinfo = {
	name = "LazMod - PropInfo",
	author = "LaZycAt, hjkwe654",
	description = "Show props infomation on hud.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	
	g_hHudTimer = CreateTimer(g_fCvarUpdateInterval, Display_Msgs, 0, TIMER_REPEAT)
	
	g_hCvarPropInfoEnabled = CreateConVar("lm_propinfo_enable", "1", "Enable display propinfo on hud", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarPropInfoEnabled.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarPropInfoEnabled)

	g_hCvarUpdateInterval = CreateConVar("lm_propinfo_interval", "0.3", "Update interval", FCVAR_NOTIFY, true, 0.0)
	g_hCvarUpdateInterval.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarUpdateInterval)

	g_hCvarMaxDistance = CreateConVar("lm_propinfo_distance", "3000", "Max distance to search of entity, 0 = No limit", FCVAR_NOTIFY, true, 0.0, true, 65535.0)
	g_hCvarMaxDistance.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMaxDistance)

	g_hCvarShowClass = CreateConVar("lm_propinfo_showclass", "1", "Show prop classname, 1=Only common types, 2=All props", FCVAR_NOTIFY, true, 0.0, true, 2.0)
	g_hCvarShowClass.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarShowClass)

	g_hCvarShowOrigin = CreateConVar("lm_propinfo_showorigin", "1", "Show prop origin, 1=Shorten values, 2=Full values", FCVAR_NOTIFY, true, 0.0, true, 2.0)
	g_hCvarShowOrigin.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarShowOrigin)

	g_hCvarShowAngles = CreateConVar("lm_propinfo_showangles", "1", "Show prop angles, 1=Shorten values, 2=Full values", FCVAR_NOTIFY, true, 0.0, true, 2.0)
	g_hCvarShowAngles.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarShowAngles)

	PrintToServer( "LazMod PropInfo loaded!" )
}

Hook_CvarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	CvarChanged(convar)
}
void CvarChanged(Handle convar) {
	if (convar == g_hCvarPropInfoEnabled) {
		g_bCvarPropInfoEnabled = g_hCvarPropInfoEnabled.BoolValue
		ResetPropInfoTimer()

	} else if (convar == g_hCvarUpdateInterval) {
		g_fCvarUpdateInterval = g_hCvarUpdateInterval.FloatValue
		ResetPropInfoTimer()

	} else if (convar == g_hCvarMaxDistance) {
		g_fCvarMaxDistance = g_hCvarMaxDistance.FloatValue
	} else if (convar == g_hCvarShowClass) {
		g_iCvarShowClass = g_hCvarShowClass.IntValue
	} else if (convar == g_hCvarShowOrigin) {
		g_iCvarShowOrigin = g_hCvarShowOrigin.IntValue
	} else if (convar == g_hCvarShowAngles) {
		g_iCvarShowAngles = g_hCvarShowAngles.IntValue
	}

}

void ResetPropInfoTimer() {

	if (g_hHudTimer != INVALID_HANDLE)
		KillTimer(g_hHudTimer)

	g_hHudTimer = CreateTimer(g_fCvarUpdateInterval, Display_Msgs, 0, TIMER_REPEAT)

}

public Action Display_Msgs(Handle timer) {

	for (int plyClient = 1; plyClient <= MaxClients; plyClient++) {		

		if (LM_IsClientValid(plyClient, plyClient, true) && !IsFakeClient(plyClient)) {
			
			int entProp = LM_GetClientAimEntity(plyClient, false, true)

			if (entProp != -1 && IsValidEdict(entProp)) {

				float vPropOrigin[3], vClientOrigin[3]
				LM_GetEntOrigin(entProp, vPropOrigin)
				GetClientAbsOrigin(plyClient, vClientOrigin)
				if (GetVectorDistance(vPropOrigin, vClientOrigin) > g_fCvarMaxDistance)
					return Plugin_Handled

				EntityInfo(plyClient, entProp)
			}
		}
	}
	return Plugin_Handled
}

void EntityInfo(plyClient, entProp) {

	if (!g_bCvarPropInfoEnabled)
		return

	if (LM_IsEntPlayer(entProp)) {
		Display_Player(plyClient, entProp)
		return
	}

	if (LM_IsEntNpc(entProp)) {
		Display_Npc(plyClient, entProp)
		return
	}
	
	Display_Prop(plyClient, entProp)
	
	return
}


stock void Display_Player(int plyClient, int entProp) {

	SetHudTextParams(0.015, 0.08, g_fCvarUpdateInterval, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2)

	int iHealth = GetClientHealth(entProp)
	// I forgor why, maybe prevent something stupid due to game engine
	if (iHealth <= 1) iHealth = 0

	if (LM_IsClientAdmin(plyClient)) {
		char szSteamId[MAX_AUTHID_LENGTH]
		GetClientAuthId(entProp, AuthId_Steam2, szSteamId, sizeof(szSteamId))
		ShowHudText(plyClient, -1, "Player: %N\nHealth: %d\nUserID: %d\nSteamID:%s", entProp, iHealth, GetClientUserId(entProp), szSteamId)
	} else {
		ShowHudText(plyClient, -1, "Player: %N\nHealth: %d", entProp, iHealth)
	}
	return

}

stock void Display_Npc(int plyClient, int entProp) {

	SetHudTextParams(0.015, 0.08, g_fCvarUpdateInterval, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2)

	char szClass[32]
	GetEdictClassname(entProp, szClass, sizeof(szClass))

	int iHealth = GetEntProp(entProp, Prop_Data, "m_iHealth")
	if (iHealth <= 1)
		iHealth = 0
		
	ShowHudText(plyClient, -1, "Classname: %s\nHealth: %d", szClass, iHealth)
	return

}

stock void Display_Prop(int plyClient, int entProp) {

	SetHudTextParams(0.015, 0.08, g_fCvarUpdateInterval, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2)

	char szOwner[32], szBuffer[256]
	int plyOwner = LM_GetEntOwner(entProp)
	if (plyOwner != -1)
		GetClientName(plyOwner, szOwner, sizeof(szOwner))
	else if (plyOwner > MAXPLAYERS){
		szOwner = "*Disconnectd"
	} else {
		szOwner = "*None"
	}

	Format(szBuffer, sizeof(szBuffer), "Index: %d\n", entProp)

	if (g_iCvarShowClass > 0) {
		char szClass[32]
		LM_GetEntClassname(entProp, szClass, sizeof(szClass))
		if (g_iCvarShowClass > 1 || (g_iCvarShowClass == 1 && (StrContains(szClass, "prop_") == 0 || StrContains(szClass, "weapon_") == 0 || StrContains(szClass, "func_physbox") == 0)))
			Format(szBuffer, sizeof(szBuffer), "%sClass: %s\n", szBuffer, szClass)
	}

	char szModel[128] 
	LM_GetEntModel(entProp, szModel, sizeof(szModel))
	Format(szBuffer, sizeof(szBuffer), "%sModel: %s\nOwner: %s\n", szBuffer, szModel, szOwner)

	if (g_iCvarShowOrigin > 0) {
		float vOrigin[3]
		LM_GetEntOrigin(entProp, vOrigin)
		if (g_iCvarShowOrigin == 1)
			Format(szBuffer, sizeof(szBuffer), "%sOrigin: %.2f %.2f %.2f\n", szBuffer, vOrigin[0], vOrigin[1], vOrigin[2])
		else
			Format(szBuffer, sizeof(szBuffer), "%sOrigin: %f %f %f\n", szBuffer, vOrigin[0], vOrigin[1], vOrigin[2])
	}

	if (g_iCvarShowAngles > 0) {
		float vAngles[3]
		LM_GetEntAngles(entProp, vAngles)
		if (g_iCvarShowAngles == 1)
			Format(szBuffer, sizeof(szBuffer), "%sAngles: %.2f %.2f %.2f\n", szBuffer, vAngles[0], vAngles[1], vAngles[2])
		else
			Format(szBuffer, sizeof(szBuffer), "%sAngles: %f %f %f\n", szBuffer, vAngles[0], vAngles[1], vAngles[2])
	}

	if (Phys_IsPhysicsObject(entProp))
		Format(szBuffer, sizeof(szBuffer), "%sMass: %f", szBuffer, Phys_GetMass(entProp))
	
	ShowHudText(plyClient, -1, szBuffer)
	
	return

}
