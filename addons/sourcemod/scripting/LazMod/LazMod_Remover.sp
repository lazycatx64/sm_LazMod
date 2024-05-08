

#include <sourcemod>
#include <sdktools>

#include <vphysics>
#include <smlib>

#include <lazmod>

ConVar g_hCvarDelEffect
bool g_bCvarDelEffect


static int COLOR_WHITE[4]	= {255,255,255,255}
static int COLOR_RED[4]	= {255,50,50,255}
static int COLOR_GREEN[4]	= {50,255,50,255}
static int COLOR_BLUE[4]	= {50,50,255,255}


char g_szConnectedClient[32][MAXPLAYERS]
char g_szDisconnectClient[32][MAXPLAYERS]
int g_iDisconnectTime = 30
int g_iTempOwner[MAX_HOOK_ENTITIES] = {-1,...}

float g_vDelRangePoint1[MAXPLAYERS][3]
float g_vDelRangePoint2[MAXPLAYERS][3]
float g_vDelRangePoint3[MAXPLAYERS][3]
int g_iDelRangeStatus[MAXPLAYERS] = {0,...}
bool g_bDelRangeCancel[MAXPLAYERS] = {false,...}

int g_mdlBeam
int g_mdlHalo
int g_mdlPhysBeam

char g_szEntityType[][] = {
	"player",
	"func_physbox",
	"prop_door_rotating",
	"prop_dynamic",
	"prop_dynamic_ornament",
	"prop_dynamic_override",
	"prop_physics",
	"prop_physics_multiplayer",
	"prop_physics_override",
	"prop_physics_respawnable",
	"prop_ragdoll",
	"item_ammo_357",
	"item_ammo_357_large",
	"item_ammo_ar2",
	"item_ammo_ar2_altfire",
	"item_ammo_ar2_large",
	"item_ammo_crate",
	"item_ammo_crossbow",
	"item_ammo_pistol",
	"item_ammo_pistol_large",
	"item_ammo_smg1",
	"item_ammo_smg1_grenade",
	"item_ammo_smg1_large",
	"item_battery",
	"item_box_buckshot",
	"item_dynamic_resupply",
	"item_healthcharger",
	"item_healthkit",
	"item_healthvial",
	"item_item_crate",
	"item_rpg_round",
	"item_suit",
	"item_suitcharger",
	"weapon_357",
	"weapon_alyxgun",
	"weapon_ar2",
	"weapon_bugbait",
	"weapon_crossbow",
	"weapon_crowbar",
	"weapon_frag",
	"weapon_physcannon",
	"weapon_pistol",
	"weapon_rpg",
	"weapon_shotgun",
	"weapon_smg1",
	"weapon_stunstick",
	"weapon_slam",
	"gib"
}

char g_szDelClass[][] = {
	"npc_",
	"prop_",
	"func_",
	"item_",
	"weapon_",
	"gib"
}

public Plugin myinfo = {
	name = "LazMod - Remover",
	author = "LaZycAt, hjkwe654",
	description = "Remove props.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {	
	RegAdminCmd("sm_delall", Command_DeleteAll, 0, "Delete all of your spawned entitys.")
	RegAdminCmd("sm_del", Command_Delete, 0, "Delete an entity.")

	RegAdminCmd("sm_fdelall", Command_AdminForceDeleteAll, ADMFLAG_BAN, "Delall a player's props.")

	RegAdminCmd("sm_delr", Command_AdminDelRange, ADMFLAG_BAN, "Draw a rectangle and delete props inside, add any arg to cancel in the middle.")
	RegAdminCmd("sm_dels", Command_AdminDelStrider, ADMFLAG_BAN, "Shoots a strider beam and remove props in range. A range can also be specified.")
	RegAdminCmd("sm_dels2", Command_AdminDelStrider2, ADMFLAG_CONVARS, "Shoots a strider beam and remove props in range. Will also kill players in range.")
	
	g_hCvarDelEffect	= CreateConVar("lm_del_effects", "1", "Enable sm_del effects", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarDelEffect.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarDelEffect)

	HookEntityOutput("prop_physics", "OnBreak", OnPropBreak)
	HookEntityOutput("prop_physics_override", "OnBreak", OnPropBreak)
	
	PrintToServer( "LazMod Remover loaded!" )
}

public OnMapStart() {
	g_mdlHalo = PrecacheModel("materials/sprites/halo01.vmt")
	g_mdlBeam = PrecacheModel("materials/sprites/laser.vmt")
	g_mdlPhysBeam = PrecacheModel("materials/sprites/physbeam.vmt")
	PrecacheSound("weapons/airboat/airboat_gun_lastshot1.wav", true)
	PrecacheSound("weapons/airboat/airboat_gun_lastshot2.wav", true)
	PrecacheSound("npc/strider/charging.wav", true)
	PrecacheSound("npc/strider/fire.wav", true)
	for (int i = 1; i < MaxClients; i++) {
		g_szConnectedClient[i] = ""
		if (LM_IsClientValid(i, i))
			GetClientAuthId(i, AuthId_Steam2, g_szConnectedClient[i], sizeof(g_szConnectedClient))
	}
}

Hook_CvarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	CvarChanged(convar)
}
void CvarChanged(Handle convar) {
	if (convar == g_hCvarDelEffect)
		g_bCvarDelEffect = g_hCvarDelEffect.BoolValue
}

public OnClientPutInServer(plyClient) {
	GetClientAuthId(plyClient, AuthId_Steam2, g_szConnectedClient[plyClient], sizeof(g_szConnectedClient))
}

public OnClientDisconnect(plyClient) {
	g_szConnectedClient[plyClient] = ""
	GetClientAuthId(plyClient, AuthId_Steam2, g_szDisconnectClient[plyClient], sizeof(g_szDisconnectClient))
	new iCount
	for (int iCheck = 0; iCheck < MAX_HOOK_ENTITIES; iCheck++) {
		if (IsValidEntity(iCheck)) {
			if (LM_GetEntityOwner(iCheck) == plyClient) {
				g_iTempOwner[iCheck] = plyClient
				LM_SetEntityOwner(iCheck, -1)
				iCount++
			}
		}
	}
	LM_SetSpawnLimit(plyClient, 0)
	LM_SetSpawnLimit(plyClient, 0, true)
	if (iCount > 0) {
		Handle hPack
		CreateDataTimer(0.001, Timer_Disconnect, hPack)
		WritePackCell(hPack, plyClient)
		WritePackCell(hPack, 0)
	}
}

public Action Timer_Disconnect(Handle hTimer, Handle hPack) {
	ResetPack(hPack)
	int plyClient = ReadPackCell(hPack)
	int iTime = ReadPackCell(hPack)
	if (iTime < g_iDisconnectTime) {
		for (int iClient = 1; iClient < sizeof(g_szConnectedClient); iClient++) {
			if (!StrEqual(g_szConnectedClient[iClient], g_szDisconnectClient[plyClient]))
				continue
				
			int iCount = 0
			char szClass[32]
			for (int entProp = 0; entProp < MAX_HOOK_ENTITIES; entProp++) {
				if (!IsValidEdict(entProp))
					continue
				if (g_iTempOwner[entProp] != iClient)
					continue

				GetEdictClassname(entProp, szClass, sizeof(szClass))
				LM_SetEntityOwner(entProp, iClient, StrEqual(szClass, "prop_ragdoll"))
				iCount++
				g_iTempOwner[entProp] = -1
			}

			LM_PrintToChat(plyClient, "You came back in time! you re-owned %i prop(s)!", iCount)
			return Plugin_Handled
		}
		iTime++
		Handle hNewPack
		CreateDataTimer(1.0, Timer_Disconnect, hNewPack)
		WritePackCell(hNewPack, plyClient)
		WritePackCell(hNewPack, iTime)
	} else {
		int iCount
		for (int iCheck = plyClient; iCheck < MAX_HOOK_ENTITIES; iCheck++) {
			if (IsValidEntity(iCheck)) {
				if (g_iTempOwner[iCheck] == plyClient) {
					AcceptEntityInput(iCheck, "Kill", -1)
					iCount++
				}
			}
		}
	}
	return Plugin_Handled
}

public Action Command_Delete(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient, true, true)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(plyClient, entProp)) {
		char szClass[33]
		GetEdictClassname(entProp, szClass, sizeof(szClass))
		DispatchKeyValue(entProp, "targetname", "Del_Drop")
		
		if (!LM_IsAdmin(plyClient)) {
			if (StrEqual(szClass, "prop_vehicle_driveable") || StrEqual(szClass, "prop_vehicle") || StrEqual(szClass, "prop_vehicle_airboat") || StrEqual(szClass, "prop_vehicle_prisoner_pod")) {
				LM_PrintToChat(plyClient, "You cannot delete this prop!")
				return Plugin_Handled
			}
		}
		
		float vOriginPlayer[3], vOriginAim[3]
		int entDissolver = CreateDissolver("3")
		
		LM_ClientAimPos(plyClient, vOriginAim)
		GetClientAbsOrigin(plyClient, vOriginPlayer)
		vOriginPlayer[2] = vOriginPlayer[2] + 50
		
		if (g_bCvarDelEffect) {
			int iPitch = GetRandomInt(50, 255)
			if (GetRandomInt(0,1) == 1) {
				EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginAim, entProp, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, iPitch)
				EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginPlayer, plyClient, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, iPitch)
			} else {
				EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginAim, entProp, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, iPitch)
				EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginPlayer, plyClient, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, iPitch)
			}
			
			DispatchKeyValue(entProp, "targetname", "Del_Target")
			
			TE_SetupBeamRingPoint(vOriginAim, 10.0, 150.0, g_mdlBeam, g_mdlHalo, 0, 10, 0.5, 2.0, 0.5, COLOR_WHITE, 20, 0)
			TE_SendToAll()
			TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_mdlPhysBeam, g_mdlHalo, 0, 66, 0.5, 2.0, 2.0, 0, 0.0, COLOR_RED, 20)
			TE_SendToAll()
		}

		if (LM_IsAdmin(plyClient)) {
			if (StrEqual(szClass, "player") ||
					StrContains(szClass, "prop_") == 0 ||
					StrContains(szClass, "npc_") == 0 ||
					StrContains(szClass, "weapon_") == 0 ||
					StrContains(szClass, "item_") == 0
				) {

				SetVariantString("Del_Target")
				AcceptEntityInput(entDissolver, "dissolve", entProp, entDissolver, 0)
				AcceptEntityInput(entDissolver, "kill", -1)
				DispatchKeyValue(entProp, "targetname", "Del_Drop")
				
				int plyOwner = LM_GetEntityOwner(entProp)
				if (plyOwner != -1) {
					if (StrEqual(szClass, "prop_ragdoll"))
						LM_SetSpawnLimit(plyOwner, -1, true)
					else
						LM_SetSpawnLimit(plyOwner, -1)
					LM_SetEntityOwner(entProp, -1)
				}
				return Plugin_Handled
			}
			if (!LM_IsPlayer(entProp)) {
				AcceptEntityInput(entProp, "kill", -1)
				AcceptEntityInput(entDissolver, "kill", -1)
				return Plugin_Handled
			}
		}

		if (StrEqual(szClass, "func_physbox")) {
			AcceptEntityInput(entProp, "kill", -1)
			AcceptEntityInput(entDissolver, "kill", -1)
		} else {
			SetVariantString("Del_Target")
			AcceptEntityInput(entDissolver, "dissolve", entProp, entDissolver, 0)
			AcceptEntityInput(entDissolver, "kill", -1)
			DispatchKeyValue(entProp, "targetname", "Del_Drop")
		}
		
		if (StrEqual(szClass, "prop_ragdoll"))
			LM_SetSpawnLimit(plyClient, -1, true)
		else
			LM_SetSpawnLimit(plyClient, -1)
		LM_SetEntityOwner(entProp, -1)
	}
	
	char szArgString[256]
	GetCmdArgString(szArgString, sizeof(szArgString))
	LM_LogCmd(plyClient, "sm_del", szArgString)
	return Plugin_Handled
}

public Action Command_DeleteAll(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || !LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	
	int entProp = 0, iCount = 0
	while (entProp < MAX_HOOK_ENTITIES) {
		entProp++
		
		if (!IsValidEntity(entProp))
			continue
		if (LM_GetEntityOwner(entProp) != plyClient)
			continue
			
		for (int i = 0; i < sizeof(g_szDelClass); i++) {
			char szClass[32], szClassLower[32]
			GetEdictClassname(entProp, szClass, sizeof(szClass))
			String_ToLower(szClass, szClassLower, sizeof(szClassLower))
			if (StrContains(szClassLower, g_szDelClass[i]) >= 0) {
				AcceptEntityInput(entProp, "Kill", -1)
				iCount++
			}
			LM_SetEntityOwner(entProp, -1)
		}
	}
	if (iCount > 0)
		LM_PrintToChat(plyClient, "All your props deleted.")
	else
		LM_PrintToChat(plyClient, "You don't have any prop.")

	
	LM_SetSpawnLimit(plyClient, 0)
	LM_SetSpawnLimit(plyClient, 0, true)
	
	char szArgString[256]
	GetCmdArgString(szArgString, sizeof(szArgString))
	LM_LogCmd(plyClient, "sm_delall", szArgString)
	return Plugin_Handled
}

public Action Command_AdminForceDeleteAll(plyClient, args) {
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !fdelall <#userid|name>")
		return Plugin_Handled
	}
	
	char szTarget[33]
	GetCmdArg(1, szTarget, sizeof(szTarget))
	
	char target_name[MAX_TARGET_LENGTH]
	int target_list[MAXPLAYERS], target_count
	bool tn_is_ml
	
	if ((target_count = ProcessTargetString(szTarget, plyClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(plyClient, target_count)
		return Plugin_Handled
	}
	for (int i = 0; i < target_count; i++) {
		FakeClientCommand(target_list[i], "sm_delall")
	}


	char szArgString[256]
	GetCmdArgString(szArgString, sizeof(szArgString))
	LM_LogCmd(plyClient, "sm_fdelall", szArgString)
	return Plugin_Handled
}

public Action Command_AdminDelRange(plyClient, args) {
	if (!LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	
	char szCancel[32]
	GetCmdArg(1, szCancel, sizeof(szCancel))
	if (!StrEqual(szCancel, "") && (g_iDelRangeStatus[plyClient] != 0)) {
		LM_PrintToChat(plyClient, "Canceled DelRange")
		g_bDelRangeCancel[plyClient] = true
		return Plugin_Handled
	}
	
	if (g_iDelRangeStatus[plyClient] == 1) {
		LM_PrintToChat(plyClient, "Selected 2nd pos, now select the 3rd to decide the height.")
		g_iDelRangeStatus[plyClient] = 2
	} else if (g_iDelRangeStatus[plyClient] == 2) {
		LM_PrintToChat(plyClient, "Finished the drawing, use sm_delr again to delete props in range.")
		g_iDelRangeStatus[plyClient] = 3
	} else if (g_iDelRangeStatus[plyClient] == 3) {
		g_iDelRangeStatus[plyClient] = 0
	} else {
		LM_ClientAimPos(plyClient, g_vDelRangePoint1[plyClient])
		LM_PrintToChat(plyClient, "Selected 1st pos, now select the 2nd to decide the wide.")
		LM_PrintToChat(plyClient, "You can add any arg to cancel in the middle.")
		LM_PrintToChat(plyClient, "Ex: !delr 0 = cancel")
		g_iDelRangeStatus[plyClient] = 1
		CreateTimer(0.05, Time_DelRange, plyClient)
	}
	return Plugin_Handled
}

public Action Command_AdminDelStrider(plyClient, args) {
	if (!LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	
	float fRange
	float vOriginAim[3]
	fRange = GetCmdArgFloat(1)
	
	if (fRange < 1)
		fRange = 300.0
	if (fRange > 5000)
		fRange = 5000.0
	
	LM_ClientAimPos(plyClient, vOriginAim)
	
	Handle hDataPack
	CreateDataTimer(0.01, Timer_DScharge, hDataPack)
	WritePackCell(hDataPack, plyClient)
	WritePackFloat(hDataPack, fRange)
	WritePackFloat(hDataPack, vOriginAim[0])
	WritePackFloat(hDataPack, vOriginAim[1])
	WritePackFloat(hDataPack, vOriginAim[2])
	return Plugin_Handled
}

public Action Command_AdminDelStrider2(plyClient, args) {
	if (!LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	
	float fRange
	float vOriginAim[3]
	fRange = GetCmdArgFloat(1)
	
	if (fRange < 1)
		fRange = 300.0
	if (fRange > 5000)
		fRange = 5000.0
	
	LM_ClientAimPos(plyClient, vOriginAim)
	
	Handle hDataPack
	CreateDataTimer(0.01, Timer_DScharge2, hDataPack)
	WritePackCell(hDataPack, plyClient)
	WritePackFloat(hDataPack, fRange)
	WritePackFloat(hDataPack, vOriginAim[0])
	WritePackFloat(hDataPack, vOriginAim[1])
	WritePackFloat(hDataPack, vOriginAim[2])
	return Plugin_Handled
}


public Action Time_DelRange(Handle hTimer, any plyClient) {
	if (!LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	if (g_bDelRangeCancel[plyClient]) {
		g_bDelRangeCancel[plyClient] = false
		g_iDelRangeStatus[plyClient] = 0
		return Plugin_Handled
	}
	
	float vPoint2[3], vPoint3[3], vPoint4[3]
	float vClonePoint1[3], vClonePoint2[3], vClonePoint3[3], vClonePoint4[3]
	float vOriginAim[3], vOriginPlayer[3]
	
	if (g_iDelRangeStatus[plyClient] == 1) {
		LM_ClientAimPos(plyClient, vOriginAim)
		vPoint2[0] = vOriginAim[0]
		vPoint2[1] = vOriginAim[1]
		vPoint2[2] = g_vDelRangePoint1[plyClient][2]
		vClonePoint1[0] = g_vDelRangePoint1[plyClient][0]
		vClonePoint1[1] = vPoint2[1]
		vClonePoint1[2] = ((g_vDelRangePoint1[plyClient][2] + vPoint2[2]) / 2)
		vClonePoint2[0] = vPoint2[0]
		vClonePoint2[1] = g_vDelRangePoint1[plyClient][1]
		vClonePoint2[2] = ((g_vDelRangePoint1[plyClient][2] + vPoint2[2]) / 2)
		
		GetClientAbsOrigin(plyClient, vOriginPlayer)
		vOriginPlayer[2] = (vOriginPlayer[2] + 50)
		
		DrawLine(vClonePoint1, g_vDelRangePoint1[plyClient], COLOR_RED)
		DrawLine(vClonePoint2, g_vDelRangePoint1[plyClient], COLOR_RED)
		DrawLine(vPoint2, vClonePoint1, COLOR_RED)
		DrawLine(vPoint2, vClonePoint2, COLOR_RED)
		DrawLine(vPoint2, vOriginAim, COLOR_BLUE)
		DrawLine(vOriginAim, vOriginPlayer, COLOR_BLUE)
		
		g_vDelRangePoint2[plyClient] = vPoint2
		CreateTimer(0.001, Time_DelRange, plyClient)
	} else if (g_iDelRangeStatus[plyClient] == 2) {
		LM_ClientAimPos(plyClient, vOriginAim)
		vPoint2[0] = g_vDelRangePoint2[plyClient][0]
		vPoint2[1] = g_vDelRangePoint2[plyClient][1]
		vPoint2[2] = g_vDelRangePoint1[plyClient][2]
		vClonePoint1[0] = g_vDelRangePoint1[plyClient][0]
		vClonePoint1[1] = vPoint2[1]
		vClonePoint1[2] = ((g_vDelRangePoint1[plyClient][2] + vPoint2[2]) / 2)
		vClonePoint2[0] = vPoint2[0]
		vClonePoint2[1] = g_vDelRangePoint1[plyClient][1]
		vClonePoint2[2] = ((g_vDelRangePoint1[plyClient][2] + vPoint2[2]) / 2)
		
		vPoint3[0] = g_vDelRangePoint1[plyClient][0]
		vPoint3[1] = g_vDelRangePoint1[plyClient][1]
		vPoint3[2] = vOriginAim[2]
		vPoint4[0] = vPoint2[0]
		vPoint4[1] = vPoint2[1]
		vPoint4[2] = vOriginAim[2]
		vClonePoint3[0] = vClonePoint1[0]
		vClonePoint3[1] = vClonePoint1[1]
		vClonePoint3[2] = vOriginAim[2]
		vClonePoint4[0] = vClonePoint2[0]
		vClonePoint4[1] = vClonePoint2[1]
		vClonePoint4[2] = vOriginAim[2]
		
		GetClientAbsOrigin(plyClient, vOriginPlayer)
		vOriginPlayer[2] = (vOriginPlayer[2] + 50)
		
		DrawLine(vClonePoint1, g_vDelRangePoint1[plyClient], COLOR_RED)
		DrawLine(vClonePoint2, g_vDelRangePoint1[plyClient], COLOR_RED)
		DrawLine(vPoint2, vClonePoint1, COLOR_RED)
		DrawLine(vPoint2, vClonePoint2, COLOR_RED)
		DrawLine(vPoint3, vClonePoint3, COLOR_RED)
		DrawLine(vPoint3, vClonePoint4, COLOR_RED)
		DrawLine(vPoint4, vClonePoint3, COLOR_RED)
		DrawLine(vPoint4, vClonePoint4, COLOR_RED)
		DrawLine(vPoint3, g_vDelRangePoint1[plyClient], COLOR_RED)
		DrawLine(vPoint4, vPoint2, COLOR_RED)
		DrawLine(vClonePoint1, vClonePoint3, COLOR_RED)
		DrawLine(vClonePoint2, vClonePoint4, COLOR_RED)
		DrawLine(vPoint4, vOriginAim, COLOR_BLUE)
		DrawLine(vOriginAim, vOriginPlayer, COLOR_BLUE)
		
		g_vDelRangePoint3[plyClient] = vPoint4
		CreateTimer(0.001, Time_DelRange, plyClient)
	} else if (g_iDelRangeStatus[plyClient] == 3) {
		vPoint2[0] = g_vDelRangePoint2[plyClient][0]
		vPoint2[1] = g_vDelRangePoint2[plyClient][1]
		vPoint2[2] = g_vDelRangePoint1[plyClient][2]
		vClonePoint1[0] = g_vDelRangePoint1[plyClient][0]
		vClonePoint1[1] = vPoint2[1]
		vClonePoint1[2] = ((g_vDelRangePoint1[plyClient][2] + vPoint2[2]) / 2)
		vClonePoint2[0] = vPoint2[0]
		vClonePoint2[1] = g_vDelRangePoint1[plyClient][1]
		vClonePoint2[2] = ((g_vDelRangePoint1[plyClient][2] + vPoint2[2]) / 2)
		
		vPoint3[0] = g_vDelRangePoint1[plyClient][0]
		vPoint3[1] = g_vDelRangePoint1[plyClient][1]
		vPoint3[2] = g_vDelRangePoint3[plyClient][2]
		vClonePoint3[0] = vClonePoint1[0]
		vClonePoint3[1] = vClonePoint1[1]
		vClonePoint3[2] = g_vDelRangePoint3[plyClient][2]
		vClonePoint4[0] = vClonePoint2[0]
		vClonePoint4[1] = vClonePoint2[1]
		vClonePoint4[2] = g_vDelRangePoint3[plyClient][2]
		
		DrawLine(g_vDelRangePoint1[plyClient], vClonePoint1, COLOR_GREEN)
		DrawLine(g_vDelRangePoint1[plyClient], vClonePoint2, COLOR_GREEN)
		DrawLine(vPoint2, vClonePoint1, COLOR_GREEN)
		DrawLine(vPoint2, vClonePoint2, COLOR_GREEN)
		DrawLine(vPoint3, vClonePoint3, COLOR_GREEN)
		DrawLine(vPoint3, vClonePoint4, COLOR_GREEN)
		DrawLine(g_vDelRangePoint3[plyClient], vClonePoint3, COLOR_GREEN)
		DrawLine(g_vDelRangePoint3[plyClient], vClonePoint4, COLOR_GREEN)
		DrawLine(vPoint3, g_vDelRangePoint1[plyClient], COLOR_GREEN)
		DrawLine(vPoint2, g_vDelRangePoint3[plyClient], COLOR_GREEN)
		DrawLine(vPoint2, vClonePoint1, COLOR_GREEN)
		DrawLine(vPoint2, vClonePoint1, COLOR_GREEN)
		TE_SetupBeamPoints(vPoint3, g_vDelRangePoint1[plyClient], g_mdlBeam, g_mdlHalo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, COLOR_GREEN, 20)
		TE_SendToAll()
		TE_SetupBeamPoints(g_vDelRangePoint3[plyClient], vPoint2, g_mdlBeam, g_mdlHalo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, COLOR_GREEN, 20)
		TE_SendToAll()
		TE_SetupBeamPoints(vClonePoint3, vClonePoint1, g_mdlBeam, g_mdlHalo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, COLOR_GREEN, 20)
		TE_SendToAll()
		TE_SetupBeamPoints(vClonePoint4, vClonePoint2, g_mdlBeam, g_mdlHalo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, COLOR_GREEN, 20)
		TE_SendToAll()
		
		CreateTimer(0.001, Time_DelRange, plyClient)
	} else {
		vPoint2[0] = g_vDelRangePoint2[plyClient][0]
		vPoint2[1] = g_vDelRangePoint2[plyClient][1]
		vPoint2[2] = g_vDelRangePoint1[plyClient][2]
		vPoint3[0] = g_vDelRangePoint1[plyClient][0]
		vPoint3[1] = g_vDelRangePoint1[plyClient][1]
		vPoint3[2] = g_vDelRangePoint3[plyClient][2]
		
		vClonePoint1[0] = g_vDelRangePoint1[plyClient][0]
		vClonePoint1[1] = vPoint2[1]
		vClonePoint1[2] = g_vDelRangePoint1[plyClient][2]
		vClonePoint2[0] = vPoint2[0]
		vClonePoint2[1] = g_vDelRangePoint1[plyClient][1]
		vClonePoint2[2] = vPoint2[2]
		vClonePoint3[0] = vClonePoint1[0]
		vClonePoint3[1] = vClonePoint1[1]
		vClonePoint3[2] = g_vDelRangePoint3[plyClient][2]
		vClonePoint4[0] = vClonePoint2[0]
		vClonePoint4[1] = vClonePoint2[1]
		vClonePoint4[2] = g_vDelRangePoint3[plyClient][2]
		
		DrawLine(vClonePoint1, g_vDelRangePoint1[plyClient], COLOR_WHITE, true)
		DrawLine(vClonePoint2, g_vDelRangePoint1[plyClient], COLOR_WHITE, true)
		DrawLine(vClonePoint3, g_vDelRangePoint3[plyClient], COLOR_WHITE, true)
		DrawLine(vClonePoint4, g_vDelRangePoint3[plyClient], COLOR_WHITE, true)
		DrawLine(vPoint2, vClonePoint1, COLOR_WHITE, true)
		DrawLine(vPoint2, vClonePoint2, COLOR_WHITE, true)
		DrawLine(vPoint3, vClonePoint3, COLOR_WHITE, true)
		DrawLine(vPoint3, vClonePoint4, COLOR_WHITE, true)
		DrawLine(vPoint2, g_vDelRangePoint3[plyClient], COLOR_WHITE, true)
		DrawLine(vPoint3, g_vDelRangePoint1[plyClient], COLOR_WHITE, true)
		DrawLine(vClonePoint1, vClonePoint3, COLOR_WHITE, true)
		DrawLine(vClonePoint2, vClonePoint4, COLOR_WHITE, true)
		
		int entDissolver = CreateEntityByName("env_entity_dissolver")
		DispatchKeyValue(entDissolver, "dissolvetype", "3")
		DispatchKeyValue(entDissolver, "targetname", "Del_Dissolver")
		DispatchSpawn(entDissolver)
		ActivateEntity(entDissolver)
		
		float vOriginEntity[3]
		char szClass[32]
		int iCount = 0
		int entProp = -1
		for (int i = 0; i < sizeof(g_szEntityType); i++) {
			while ((entProp = FindEntityByClassname(entProp, g_szEntityType[i])) != -1) {
				LM_GetEntOrigin(entProp, vOriginEntity)
				vOriginEntity[2] += 1
				if (vOriginEntity[0] != 0 && vOriginEntity[1] !=1 && vOriginEntity[2] != 0 && LM_IsInSquare(vOriginEntity, g_vDelRangePoint1[plyClient], g_vDelRangePoint3[plyClient])) {
					GetEdictClassname(entProp, szClass, sizeof(szClass))
					if (StrEqual(szClass, "func_physbox"))
						AcceptEntityInput(entProp, "kill", -1)
					else {
						DispatchKeyValue(entProp, "targetname", "Del_Target")
						SetVariantString("Del_Target")
						AcceptEntityInput(entDissolver, "dissolve", entProp, entDissolver, 0)
						DispatchKeyValue(entProp, "targetname", "Del_Drop")
					}
					
					int plyOwner = LM_GetEntityOwner(entProp)
					if (plyOwner != -1) {
						LM_SetSpawnLimit(plyOwner, -1, StrEqual(szClass, "prop_ragdoll"))
						LM_SetEntityOwner(entProp, -1)
					}
				}
			}
		}
		AcceptEntityInput(entDissolver, "kill", -1)
		
		if (iCount > 0)
			LM_PrintToChat(plyClient, "Deleted %i props.", iCount)
	}
	return Plugin_Handled
}

public Action Timer_DScharge(Handle hTimer, Handle hDataPack) {
	float vOriginAim[3], vOriginPlayer[3]
	ResetPack(hDataPack)
	int plyClient = ReadPackCell(hDataPack)
	float fRange = ReadPackFloat(hDataPack)
	vOriginAim[0] = ReadPackFloat(hDataPack)
	vOriginAim[1] = ReadPackFloat(hDataPack)
	vOriginAim[2] = ReadPackFloat(hDataPack)
	
	GetClientAbsOrigin(plyClient, vOriginPlayer)
	vOriginPlayer[2] = (vOriginPlayer[2] + 50)
	
	EmitAmbientSound("npc/strider/charging.wav", vOriginAim, plyClient, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	EmitAmbientSound("npc/strider/charging.wav", vOriginPlayer, plyClient, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3)
	
	// Flags: 20 = 16 + 4
	// 1 : Test LOS before pushing
	// 2 : Use angles for push direction
	// 4 : No falloff (constant push at any distance)
	// 8 : Push players
	// 16 : Push physics
	int entPush = CreatePush(vOriginAim, -1000.0, fRange, "20")
	AcceptEntityInput(entPush, "enable", -1)
	
	int entCore = CreateCore(vOriginAim, 5.0, "1")
	AcceptEntityInput(entCore, "startdischarge", -1)
	/*
	char szPointTeslaName[128], char szThickMin[64], char szThickMax[64], char szOnUser[128], char szKill[64]
	int entPointTesla = CreateEntityByName("point_tesla")
	TeleportEntity(entPointTesla, vOriginAim, NULL_VECTOR, NULL_VECTOR)
	Format(szPointTeslaName, sizeof(szPointTeslaName), "szTesla%i", GetRandomInt(1000, 5000))
	float fThickMin = StringToFloat(szRange) / 40
	float iThickMax = StringToFloat(szRange) / 30
	Format(szThickMin, sizeof(szThickMin), "%i", RoundToFloor(fThickMin))
	Format(szThickMax, sizeof(szThickMax), "%i", RoundToFloor(iThickMax))
	
	DispatchKeyValue(entPointTesla, "targetname", szPointTeslaName)
	DispatchKeyValue(entPointTesla, "sprite", "sprites/physbeam.vmt")
	DispatchKeyValue(entPointTesla, "m_color", "255 255 255")
	DispatchKeyValue(entPointTesla, "m_flradius", szRange)
	DispatchKeyValue(entPointTesla, "beamcount_min", "100")
	DispatchKeyValue(entPointTesla, "beamcount_max", "500")
	DispatchKeyValue(entPointTesla, "thick_min", szThickMin)
	DispatchKeyValue(entPointTesla, "thick_max", szThickMax)
	DispatchKeyValue(entPointTesla, "lifetime_min", "0.1")
	DispatchKeyValue(entPointTesla, "lifetime_max", "0.1")
	
	float f
	for (f = 0.0; f < 1.3; f=f+0.05) {
		Format(szOnUser, sizeof(szOnUser), "%s,dospark,,%f", szPointTeslaName, f)
		DispatchKeyValue(entPointTesla, "onuser1", szOnUser)
	}
	Format(szKill, sizeof(szKill), "%s,kill,,1.3", szPointTeslaName)
	DispatchSpawn(entPointTesla)
	DispatchKeyValue(entPointTesla, "onuser1", szKill)
	AcceptEntityInput(entPointTesla, "fireuser1", -1)
	*/
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_mdlBeam, g_mdlHalo, 0, 66, 1.3, 15.0, 15.0, 0, 0.0, COLOR_BLUE, 20)
	TE_SendToAll()
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_mdlBeam, g_mdlHalo, 0, 66, 1.3, 20.0, 20.0, 0, 0.0, COLOR_WHITE, 20)
	TE_SendToAll()
	
	Handle hNewPack
	CreateDataTimer(1.3, Timer_DSfire, hNewPack)
	WritePackCell(hNewPack, plyClient)
	WritePackCell(hNewPack, entPush)
	WritePackCell(hNewPack, entCore)
	WritePackFloat(hNewPack, fRange)
	WritePackFloat(hNewPack, vOriginAim[0])
	WritePackFloat(hNewPack, vOriginAim[1])
	WritePackFloat(hNewPack, vOriginAim[2])
	WritePackFloat(hNewPack, vOriginPlayer[0])
	WritePackFloat(hNewPack, vOriginPlayer[1])
	WritePackFloat(hNewPack, vOriginPlayer[2])

	return Plugin_Handled
}

public Action Timer_DSfire(Handle hTimer, Handle hDataPack) {
	float vOriginAim[3], vOriginPlayer[3]
	ResetPack(hDataPack)
	int plyClient = ReadPackCell(hDataPack)
	int entPush = ReadPackCell(hDataPack)
	int entCore = ReadPackCell(hDataPack)
	float fRange = ReadPackFloat(hDataPack)
	vOriginAim[0] = ReadPackFloat(hDataPack)
	vOriginAim[1] = ReadPackFloat(hDataPack)
	vOriginAim[2] = ReadPackFloat(hDataPack)
	vOriginPlayer[0] = ReadPackFloat(hDataPack)
	vOriginPlayer[1] = ReadPackFloat(hDataPack)
	vOriginPlayer[2] = ReadPackFloat(hDataPack)
	
	if (IsValidEntity(entPush))
		AcceptEntityInput(entPush, "kill", -1)
	if (IsValidEntity(entCore))
		AcceptEntityInput(entCore, "kill", -1)
	
	EmitAmbientSound("npc/strider/fire.wav", vOriginAim, plyClient, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	EmitAmbientSound("npc/strider/fire.wav", vOriginPlayer, plyClient, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_mdlBeam, g_mdlHalo, 0, 66, 0.2, 15.0, 15.0, 0, 0.0, COLOR_RED, 20)
	TE_SendToAll()
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_mdlBeam, g_mdlHalo, 0, 66, 0.2, 20.0, 20.0, 0, 0.0, COLOR_WHITE, 20)
	TE_SendToAll()
	
	int entDissolver = CreateDissolver("3")
	float vOriginEntity[3]
	new iCount = 0
	int entProp = -1
	for (int i = 0; i < sizeof(g_szEntityType); i++) {
		while ((entProp = FindEntityByClassname(entProp, g_szEntityType[i])) != -1) {
			LM_GetEntOrigin(entProp, vOriginEntity)
			vOriginEntity[2] += 1
			char szClass[33]
			GetEdictClassname(entProp,szClass,sizeof(szClass))
			if (vOriginEntity[0] != 0 && vOriginEntity[1] !=1 && vOriginEntity[2] != 0 && !StrEqual(szClass, "player") && LM_IsInRange(vOriginEntity, vOriginAim, fRange)) {
				if (StrEqual(szClass, "func_physbox"))
					AcceptEntityInput(entProp, "kill", -1)
				else {
					DispatchKeyValue(entProp, "targetname", "Del_Target")
					SetVariantString("Del_Target")
					AcceptEntityInput(entDissolver, "dissolve", entProp, entDissolver, 0)
					DispatchKeyValue(entProp, "targetname", "Del_Drop")
				}
				
				int plyOwner = LM_GetEntityOwner(entProp)
				if (plyOwner != -1) {
					LM_SetSpawnLimit(plyOwner, -1, StrEqual(szClass, "prop_ragdoll"))
					LM_SetEntityOwner(entProp, -1)
				}
				iCount++
			}
		}
	}
	AcceptEntityInput(entDissolver, "kill", -1)
	if (iCount > 0 && LM_IsClientValid(plyClient, plyClient))
		LM_PrintToChat(plyClient, "Deleted %i props.", iCount)

	return Plugin_Handled
}

public Action Timer_DScharge2(Handle hTimer, Handle hDataPack) {
	float vOriginAim[3], vOriginPlayer[3]
	ResetPack(hDataPack)
	int plyClient = ReadPackCell(hDataPack)
	float fRange = ReadPackFloat(hDataPack)
	vOriginAim[0] = ReadPackFloat(hDataPack)
	vOriginAim[1] = ReadPackFloat(hDataPack)
	vOriginAim[2] = ReadPackFloat(hDataPack)
	
	GetClientAbsOrigin(plyClient, vOriginPlayer)
	vOriginPlayer[2] = (vOriginPlayer[2] + 50)
	
	EmitAmbientSound("npc/strider/charging.wav", vOriginAim, plyClient, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	EmitAmbientSound("npc/strider/charging.wav", vOriginPlayer, plyClient, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3)
	
	// Flags: 28 = 4 + 8 + 16
	// 1 : Test LOS before pushing
	// 2 : Use angles for push direction
	// 4 : No falloff (constant push at any distance)
	// 8 : Push players
	// 16 : Push physics
	int entPush = CreatePush(vOriginAim, -1000.0, fRange, "28")
	AcceptEntityInput(entPush, "enable", -1)
	
	int entCore = CreateCore(vOriginAim, 5.0, "1")
	AcceptEntityInput(entCore, "startdischarge", -1)
	
	float vOriginEntity[3]
	char szClass[32]
	int entProp = -1
	for (int i = 0; i < sizeof(g_szEntityType); i++) {
		while ((entProp = FindEntityByClassname(entProp, g_szEntityType[i])) != -1) {
			LM_GetEntOrigin(entProp, vOriginEntity)
			vOriginEntity[2] = (vOriginEntity[2] + 1)
			if (!Phys_IsPhysicsObject(entProp))
				continue

			if (!LM_IsInRange(vOriginEntity, vOriginAim, fRange))
				continue

			Phys_EnableMotion(entProp, true)
			GetEdictClassname(entProp, szClass, sizeof(szClass))
			if (StrEqual(szClass, "player"))
				SetEntityMoveType(entProp, MOVETYPE_WALK)
			else
				SetEntityMoveType(entProp, MOVETYPE_VPHYSICS)
			
		}
	}
	
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_mdlBeam, g_mdlHalo, 0, 66, 1.3, 15.0, 15.0, 0, 0.0, COLOR_BLUE, 20)
	TE_SendToAll()
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_mdlBeam, g_mdlHalo, 0, 66, 1.3, 20.0, 20.0, 0, 0.0, COLOR_WHITE, 20)
	TE_SendToAll()
	
	Handle hNewPack
	CreateDataTimer(1.3, Timer_DSfire2, hNewPack)
	WritePackCell(hNewPack, plyClient)
	WritePackCell(hNewPack, entPush)
	WritePackCell(hNewPack, entCore)
	WritePackFloat(hNewPack, fRange)
	WritePackFloat(hNewPack, vOriginAim[0])
	WritePackFloat(hNewPack, vOriginAim[1])
	WritePackFloat(hNewPack, vOriginAim[2])
	WritePackFloat(hNewPack, vOriginPlayer[0])
	WritePackFloat(hNewPack, vOriginPlayer[1])
	WritePackFloat(hNewPack, vOriginPlayer[2])

	return Plugin_Handled
}

public Action Timer_DSfire2(Handle hTimer, Handle hDataPack) {
	float vOriginAim[3], vOriginPlayer[3]
	ResetPack(hDataPack)
	int plyClient = ReadPackCell(hDataPack)
	int entPush = ReadPackCell(hDataPack)
	int entCore = ReadPackCell(hDataPack)
	float fRange = ReadPackFloat(hDataPack)
	vOriginAim[0] = ReadPackFloat(hDataPack)
	vOriginAim[1] = ReadPackFloat(hDataPack)
	vOriginAim[2] = ReadPackFloat(hDataPack)
	vOriginPlayer[0] = ReadPackFloat(hDataPack)
	vOriginPlayer[1] = ReadPackFloat(hDataPack)
	vOriginPlayer[2] = ReadPackFloat(hDataPack)
	
	if (IsValidEntity(entPush))
		AcceptEntityInput(entPush, "kill", -1)
	if (IsValidEntity(entCore))
		AcceptEntityInput(entCore, "kill", -1)
	
	EmitAmbientSound("npc/strider/fire.wav", vOriginAim, plyClient, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	EmitAmbientSound("npc/strider/fire.wav", vOriginPlayer, plyClient, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_mdlBeam, g_mdlHalo, 0, 66, 0.2, 15.0, 15.0, 0, 0.0, COLOR_RED, 20)
	TE_SendToAll()
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_mdlBeam, g_mdlHalo, 0, 66, 0.2, 20.0, 20.0, 0, 0.0, COLOR_WHITE, 20)
	TE_SendToAll()
	
	int entDissolver = CreateDissolver("3")
	float vOriginEntity[3]
	new iCount = 0
	int entProp = -1
	for (int i = 0; i < sizeof(g_szEntityType); i++) {
		while ((entProp = FindEntityByClassname(entProp, g_szEntityType[i])) != -1) {
			LM_GetEntOrigin(entProp, vOriginEntity)
			vOriginEntity[2] += 1
			char szClass[33]
			GetEdictClassname(entProp,szClass,sizeof(szClass))
			if (vOriginEntity[0] != 0 && vOriginEntity[1] != 1 && vOriginEntity[2] != 0 && LM_IsInRange(vOriginEntity, vOriginAim, fRange)) {
				if (StrEqual(szClass, "func_physbox"))
					AcceptEntityInput(entProp, "kill", -1)
				else {
					DispatchKeyValue(entProp, "targetname", "Del_Target")
					SetVariantString("Del_Target")
					AcceptEntityInput(entDissolver, "dissolve", entProp, entDissolver, 0)
					DispatchKeyValue(entProp, "targetname", "Del_Drop")
				}
				int plyOwner = LM_GetEntityOwner(entProp)
				if (plyOwner != -1) {
					LM_SetSpawnLimit(plyOwner, -1, StrEqual(szClass, "prop_ragdoll"))
					LM_SetEntityOwner(entProp, -1)
				}
				iCount++
			}
		}
	}
	AcceptEntityInput(entDissolver, "kill", -1)
	if (iCount > 0 && LM_IsClientValid(plyClient, plyClient))
		LM_PrintToChat(plyClient, "Deleted %i props.", iCount)
	
	return Plugin_Handled
}

public OnPropBreak(const char[] output, int entProp, int entActivator, float fDelay) {
	if (IsValidEntity(entProp))
		CreateTimer(0.1, Timer_PropBreak, entProp)
}

public Action Timer_PropBreak(Handle hTimer, any entProp) {
	if (!IsValidEntity(entProp))
		return Plugin_Handled
	int plyOwner = LM_GetEntityOwner(entProp)
	if (plyOwner > 0) {
		LM_SetSpawnLimit(plyOwner, -1)
		LM_SetEntityOwner(entProp, -1)
		AcceptEntityInput(entProp, "kill", -1)
	}
	return Plugin_Handled
}

stock DrawLine(float vStart[3], float vEnd[3], int Color[4], bool bFinale = false) {
	if (bFinale)
		TE_SetupBeamPoints(vStart, vEnd, g_mdlBeam, g_mdlHalo, 0, 66, 0.5, 7.0, 7.0, 0, 0.0, Color, 20)
	else
		TE_SetupBeamPoints(vStart, vEnd, g_mdlBeam, g_mdlHalo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, Color, 20)
	TE_SendToAll()
}

stock CreatePush(float vOrigin[3], float fMagnitude, float fRange, char szSpawnFlags[8]) {
	int entPush = CreateEntityByName("point_push")
	TeleportEntity(entPush, vOrigin, NULL_VECTOR, NULL_VECTOR)
	DispatchKeyValueFloat(entPush, "magnitude", fMagnitude)
	DispatchKeyValueFloat(entPush, "radius", fRange)
	DispatchKeyValueFloat(entPush, "inner_radius", fRange)
	DispatchKeyValue(entPush, "spawnflags", szSpawnFlags)
	DispatchSpawn(entPush)
	return entPush
}

stock CreateCore(float vOrigin[3], float fScale, char szSpawnFlags[8]) {
	int entCore = CreateEntityByName("env_citadel_energy_core")
	TeleportEntity(entCore, vOrigin, NULL_VECTOR, NULL_VECTOR)
	DispatchKeyValueFloat(entCore, "scale", fScale)
	DispatchKeyValue(entCore, "spawnflags", szSpawnFlags)
	DispatchSpawn(entCore)
	return entCore
}

stock int CreateDissolver(char szDissolveType[4]) {
	int entDissolver = CreateEntityByName("env_entity_dissolver")
	DispatchKeyValue(entDissolver, "dissolvetype", szDissolveType)
	DispatchKeyValue(entDissolver, "targetname", "Del_Dissolver")
	DispatchSpawn(entDissolver)
	return entDissolver
}

