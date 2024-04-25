

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>


static int COLOR_WHITE[4]	= {255,255,255,255}
static int COLOR_RED[4]	= {255,50,50,255}
static int COLOR_GREEN[4]	= {50,255,50,255}
static int COLOR_BLUE[4]	= {50,50,255,255}


char g_szConnectedClient[32][MAXPLAYERS]
char g_szDisconnectClient[32][MAXPLAYERS]
int g_iDisconnectTime = 30
int g_iTempOwner[MAX_HOOK_ENTITIES] = {-1,...}

float g_fDelRangePoint1[MAXPLAYERS][3]
float g_fDelRangePoint2[MAXPLAYERS][3]
float g_fDelRangePoint3[MAXPLAYERS][3]
char g_szDelRangeStatus[MAXPLAYERS][8]
bool g_szDelRangeCancel[MAXPLAYERS] = { false,...}

int g_mdlBeam
int g_mdlHalo
int g_mdlPhysBeam

char EntityType[][] = {
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

char DelClass[][] = {
	"npc_",
	"Npc_",
	"NPC_",
	"prop_",
	"Prop_",
	"PROP_",
	"func_",
	"Func_",
	"FUNC_",
	"item_",
	"Item_",
	"ITEM_",
	"weapon_",
	"Weapon_",
	"WEAPON_",
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
	RegAdminCmd("sm_delr", Command_DelRange, ADMFLAG_BAN, "WTF.")
	RegAdminCmd("sm_dels", Command_DelStrider, ADMFLAG_BAN, "WTF.")
	RegAdminCmd("sm_dels2", Command_DelStrider2, ADMFLAG_CONVARS, "WTF.")
	
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

public OnClientPutInServer(Client) {
	GetClientAuthId(Client, AuthId_Steam2, g_szConnectedClient[Client], sizeof(g_szConnectedClient))
}

public OnClientDisconnect(Client) {
	g_szConnectedClient[Client] = ""
	GetClientAuthId(Client, AuthId_Steam2, g_szDisconnectClient[Client], sizeof(g_szDisconnectClient))
	new iCount
	for (int iCheck = 0; iCheck < MAX_HOOK_ENTITIES; iCheck++) {
		if (IsValidEntity(iCheck)) {
			if (LM_GetEntityOwner(iCheck) == Client) {
				g_iTempOwner[iCheck] = Client
				LM_SetEntityOwner(iCheck, -1)
				iCount++
			}
		}
	}
	LM_SetSpawnLimit(Client, 0)
	LM_SetSpawnLimit(Client, 0, true)
	if (iCount > 0) {
		Handle hPack
		CreateDataTimer(0.001, Timer_Disconnect, hPack)
		WritePackCell(hPack, Client)
		WritePackCell(hPack, 0)
	}
}

public Action Timer_Disconnect(Handle Timer, Handle hPack) {
	ResetPack(hPack)
	int plyClient = ReadPackCell(hPack)
	int iTime = ReadPackCell(hPack)
	if (iTime < g_iDisconnectTime) {
		for (int iClient = 1; iClient < sizeof(g_szConnectedClient); iClient++) {
			if (StrEqual(g_szConnectedClient[iClient], g_szDisconnectClient[plyClient])) {
				int iCount = 0
				char szClass[32]
				for (int entProp = 0; entProp < MAX_HOOK_ENTITIES; entProp++) {
					if (IsValidEdict(entProp)) {
						if (g_iTempOwner[entProp] == iClient) {
							GetEdictClassname(entProp, szClass, sizeof(szClass))
							LM_SetEntityOwner(entProp, iClient, StrEqual(szClass, "prop_ragdoll"))
							iCount++
							g_iTempOwner[entProp] = -1
						}
					}
				}

				LM_PrintToChat(plyClient, "You came back in time! you re-owned %i prop(s)!", iCount)
				return Plugin_Handled
			}
		}
		iTime++
		Handle hNewPack
		CreateDataTimer(1.0, Timer_Disconnect, hNewPack)
		WritePackCell(hNewPack, plyClient)
		WritePackCell(hNewPack, iTime)
	} else {
		new iCount
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

public Action Command_DeleteAll(Client, args) {
	if (!LM_AllowToUse(Client) || !LM_IsClientValid(Client, Client))
		return Plugin_Handled
	
	new iCheck = 0, iCount = 0
	while (iCheck < MAX_HOOK_ENTITIES) {
		if (IsValidEntity(iCheck)) {
			if (LM_GetEntityOwner(iCheck) == Client) {
				for (int i = 0; i < sizeof(DelClass); i++) {
					char szClass[32]
					GetEdictClassname(iCheck, szClass, sizeof(szClass))
					if (StrContains(szClass, DelClass[i]) >= 0) {
						AcceptEntityInput(iCheck, "Kill", -1)
						iCount++
					}
					LM_SetEntityOwner(iCheck, -1)
				}
			}
		}
		iCheck += 1
	}
	if (iCount > 0)
		LM_PrintToChat(Client, "All your props deleted.")
	else
		LM_PrintToChat(Client, "You don't have any prop.")

	
	LM_SetSpawnLimit(Client, 0)
	LM_SetSpawnLimit(Client, 0, true)
	// FakeClientCommand(Client, "e_removespawned")	// SourceOP Dead
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_delall", szArgs)
	return Plugin_Handled
}

public Action Command_Delete(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(Client, true, true)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (LM_IsEntityOwner(Client, entProp)) {
		char szClass[33]
		GetEdictClassname(entProp, szClass, sizeof(szClass))
		DispatchKeyValue(entProp, "targetname", "Del_Drop")
		
		if (!LM_IsAdmin(Client)) {
			if (StrEqual(szClass, "prop_vehicle_driveable") || StrEqual(szClass, "prop_vehicle") || StrEqual(szClass, "prop_vehicle_airboat") || StrEqual(szClass, "prop_vehicle_prisoner_pod")) {
				LM_PrintToChat(Client, "You cannot delete this prop!")
				return Plugin_Handled
			}
		}
		
		float vOriginPlayer[3], vOriginAim[3]
		int entDissolver = CreateDissolver("3")
		
		LM_ClientAimPos(Client, vOriginAim)
		GetClientAbsOrigin(Client, vOriginPlayer)
		vOriginPlayer[2] = vOriginPlayer[2] + 50
		
		new random = GetRandomInt(0,1)
		new iPitch = GetRandomInt(50, 255)
		if (random == 1) {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginAim, entProp, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, iPitch)
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, iPitch)
		} else {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginAim, entProp, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, iPitch)
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, iPitch)
		}
		
		DispatchKeyValue(entProp, "targetname", "Del_Target")
		
		TE_SetupBeamRingPoint(vOriginAim, 10.0, 150.0, g_mdlBeam, g_mdlHalo, 0, 10, 0.5, 2.0, 0.5, COLOR_WHITE, 20, 0)
		TE_SendToAll()
		TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_mdlPhysBeam, g_mdlHalo, 0, 66, 0.5, 2.0, 2.0, 0, 0.0, COLOR_RED, 20)
		TE_SendToAll()

		if (LM_IsAdmin(Client)) {
			if (StrEqual(szClass, "player") || StrContains(szClass, "prop_") == 0 || StrContains(szClass, "npc_") == 0 || StrContains(szClass, "weapon_") == 0 || StrContains(szClass, "item_") == 0) {
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
			if (!(LM_IsPlayer(entProp))) {
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
			LM_SetSpawnLimit(Client, -1, true)
		else
			LM_SetSpawnLimit(Client, -1)
		LM_SetEntityOwner(entProp, -1)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_del", szArgs)
	return Plugin_Handled
}

public Action Command_DelRange(Client, args) {
	if (!LM_IsClientValid(Client, Client))
		return Plugin_Handled
	
	char szCancel[32]
	GetCmdArg(1, szCancel, sizeof(szCancel))
	if (!StrEqual(szCancel, "") && (!StrEqual(g_szDelRangeStatus[Client], "off") || !StrEqual(g_szDelRangeStatus[Client], ""))) {
		LM_PrintToChat(Client, "Canceled DelRange")
		g_szDelRangeCancel[Client] = true
		return Plugin_Handled
	}
	
	if (StrEqual(g_szDelRangeStatus[Client], "x"))
		g_szDelRangeStatus[Client] = "y"
	else if (StrEqual(g_szDelRangeStatus[Client], "y"))
		g_szDelRangeStatus[Client] = "z"
	else if (StrEqual(g_szDelRangeStatus[Client], "z"))
		g_szDelRangeStatus[Client] = "off"
	else {
		LM_ClientAimPos(Client, g_fDelRangePoint1[Client])
		g_szDelRangeStatus[Client] = "x"
		CreateTimer(0.05, Timer_DR, Client)
	}
	return Plugin_Handled
}

public Action Command_DelStrider(Client, args) {
	if (!LM_IsClientValid(Client, Client))
		return Plugin_Handled
	
	float fRange
	char szRange[5]
	float vOriginAim[3]
	GetCmdArg(1, szRange, sizeof(szRange))
	
	fRange = StringToFloat(szRange)
	if (fRange < 1)
		fRange = 300.0
	if (fRange > 5000)
		fRange = 5000.0
	
	LM_ClientAimPos(Client, vOriginAim)
	
	Handle hDataPack
	CreateDataTimer(0.01, Timer_DScharge, hDataPack)
	WritePackCell(hDataPack, Client)
	WritePackFloat(hDataPack, fRange)
	WritePackFloat(hDataPack, vOriginAim[0])
	WritePackFloat(hDataPack, vOriginAim[1])
	WritePackFloat(hDataPack, vOriginAim[2])
	return Plugin_Handled
}

public Action Command_DelStrider2(Client, args) {
	if (!LM_IsClientValid(Client, Client))
		return Plugin_Handled
	
	float fRange
	char szRange[5]
	float vOriginAim[3]
	GetCmdArg(1, szRange, sizeof(szRange))
	
	fRange = StringToFloat(szRange)
	if (fRange < 1)
		fRange = 300.0
	if (fRange > 5000)
		fRange = 5000.0
	
	LM_ClientAimPos(Client, vOriginAim)
	
	Handle hDataPack
	CreateDataTimer(0.01, Timer_DScharge2, hDataPack)
	WritePackCell(hDataPack, Client)
	WritePackFloat(hDataPack, fRange)
	WritePackFloat(hDataPack, vOriginAim[0])
	WritePackFloat(hDataPack, vOriginAim[1])
	WritePackFloat(hDataPack, vOriginAim[2])
	return Plugin_Handled
}


public Action Timer_DR(Handle Timer, any Client) {
	if (!LM_IsClientValid(Client, Client))
		return Plugin_Handled
	if (g_szDelRangeCancel[Client]) {
		g_szDelRangeCancel[Client] = false
		g_szDelRangeStatus[Client] = "off"
		return Plugin_Handled
	}
	
	float vPoint2[3], vPoint3[3], vPoint4[3]
	float vClonePoint1[3], vClonePoint2[3], vClonePoint3[3], vClonePoint4[3]
	float vOriginAim[3], vOriginPlayer[3]
	
	if (StrEqual(g_szDelRangeStatus[Client], "x")) {
		LM_ClientAimPos(Client, vOriginAim)
		vPoint2[0] = vOriginAim[0]
		vPoint2[1] = vOriginAim[1]
		vPoint2[2] = g_fDelRangePoint1[Client][2]
		vClonePoint1[0] = g_fDelRangePoint1[Client][0]
		vClonePoint1[1] = vPoint2[1]
		vClonePoint1[2] = ((g_fDelRangePoint1[Client][2] + vPoint2[2]) / 2)
		vClonePoint2[0] = vPoint2[0]
		vClonePoint2[1] = g_fDelRangePoint1[Client][1]
		vClonePoint2[2] = ((g_fDelRangePoint1[Client][2] + vPoint2[2]) / 2)
		
		GetClientAbsOrigin(Client, vOriginPlayer)
		vOriginPlayer[2] = (vOriginPlayer[2] + 50)
		
		DrowLine(vClonePoint1, g_fDelRangePoint1[Client], COLOR_RED)
		DrowLine(vClonePoint2, g_fDelRangePoint1[Client], COLOR_RED)
		DrowLine(vPoint2, vClonePoint1, COLOR_RED)
		DrowLine(vPoint2, vClonePoint2, COLOR_RED)
		DrowLine(vPoint2, vOriginAim, COLOR_BLUE)
		DrowLine(vOriginAim, vOriginPlayer, COLOR_BLUE)
		
		g_fDelRangePoint2[Client] = vPoint2
		CreateTimer(0.001, Timer_DR, Client)
	} else if (StrEqual(g_szDelRangeStatus[Client], "y")) {
		LM_ClientAimPos(Client, vOriginAim)
		vPoint2[0] = g_fDelRangePoint2[Client][0]
		vPoint2[1] = g_fDelRangePoint2[Client][1]
		vPoint2[2] = g_fDelRangePoint1[Client][2]
		vClonePoint1[0] = g_fDelRangePoint1[Client][0]
		vClonePoint1[1] = vPoint2[1]
		vClonePoint1[2] = ((g_fDelRangePoint1[Client][2] + vPoint2[2]) / 2)
		vClonePoint2[0] = vPoint2[0]
		vClonePoint2[1] = g_fDelRangePoint1[Client][1]
		vClonePoint2[2] = ((g_fDelRangePoint1[Client][2] + vPoint2[2]) / 2)
		
		vPoint3[0] = g_fDelRangePoint1[Client][0]
		vPoint3[1] = g_fDelRangePoint1[Client][1]
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
		
		GetClientAbsOrigin(Client, vOriginPlayer)
		vOriginPlayer[2] = (vOriginPlayer[2] + 50)
		
		DrowLine(vClonePoint1, g_fDelRangePoint1[Client], COLOR_RED)
		DrowLine(vClonePoint2, g_fDelRangePoint1[Client], COLOR_RED)
		DrowLine(vPoint2, vClonePoint1, COLOR_RED)
		DrowLine(vPoint2, vClonePoint2, COLOR_RED)
		DrowLine(vPoint3, vClonePoint3, COLOR_RED)
		DrowLine(vPoint3, vClonePoint4, COLOR_RED)
		DrowLine(vPoint4, vClonePoint3, COLOR_RED)
		DrowLine(vPoint4, vClonePoint4, COLOR_RED)
		DrowLine(vPoint3, g_fDelRangePoint1[Client], COLOR_RED)
		DrowLine(vPoint4, vPoint2, COLOR_RED)
		DrowLine(vClonePoint1, vClonePoint3, COLOR_RED)
		DrowLine(vClonePoint2, vClonePoint4, COLOR_RED)
		DrowLine(vPoint4, vOriginAim, COLOR_BLUE)
		DrowLine(vOriginAim, vOriginPlayer, COLOR_BLUE)
		
		g_fDelRangePoint3[Client] = vPoint4
		CreateTimer(0.001, Timer_DR, Client)
	} else if (StrEqual(g_szDelRangeStatus[Client], "z")) {
		vPoint2[0] = g_fDelRangePoint2[Client][0]
		vPoint2[1] = g_fDelRangePoint2[Client][1]
		vPoint2[2] = g_fDelRangePoint1[Client][2]
		vClonePoint1[0] = g_fDelRangePoint1[Client][0]
		vClonePoint1[1] = vPoint2[1]
		vClonePoint1[2] = ((g_fDelRangePoint1[Client][2] + vPoint2[2]) / 2)
		vClonePoint2[0] = vPoint2[0]
		vClonePoint2[1] = g_fDelRangePoint1[Client][1]
		vClonePoint2[2] = ((g_fDelRangePoint1[Client][2] + vPoint2[2]) / 2)
		
		vPoint3[0] = g_fDelRangePoint1[Client][0]
		vPoint3[1] = g_fDelRangePoint1[Client][1]
		vPoint3[2] = g_fDelRangePoint3[Client][2]
		vClonePoint3[0] = vClonePoint1[0]
		vClonePoint3[1] = vClonePoint1[1]
		vClonePoint3[2] = g_fDelRangePoint3[Client][2]
		vClonePoint4[0] = vClonePoint2[0]
		vClonePoint4[1] = vClonePoint2[1]
		vClonePoint4[2] = g_fDelRangePoint3[Client][2]
		
		DrowLine(g_fDelRangePoint1[Client], vClonePoint1, COLOR_GREEN)
		DrowLine(g_fDelRangePoint1[Client], vClonePoint2, COLOR_GREEN)
		DrowLine(vPoint2, vClonePoint1, COLOR_GREEN)
		DrowLine(vPoint2, vClonePoint2, COLOR_GREEN)
		DrowLine(vPoint3, vClonePoint3, COLOR_GREEN)
		DrowLine(vPoint3, vClonePoint4, COLOR_GREEN)
		DrowLine(g_fDelRangePoint3[Client], vClonePoint3, COLOR_GREEN)
		DrowLine(g_fDelRangePoint3[Client], vClonePoint4, COLOR_GREEN)
		DrowLine(vPoint3, g_fDelRangePoint1[Client], COLOR_GREEN)
		DrowLine(vPoint2, g_fDelRangePoint3[Client], COLOR_GREEN)
		DrowLine(vPoint2, vClonePoint1, COLOR_GREEN)
		DrowLine(vPoint2, vClonePoint1, COLOR_GREEN)
		TE_SetupBeamPoints(vPoint3, g_fDelRangePoint1[Client], g_mdlBeam, g_mdlHalo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, COLOR_GREEN, 20)
		TE_SendToAll()
		TE_SetupBeamPoints(g_fDelRangePoint3[Client], vPoint2, g_mdlBeam, g_mdlHalo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, COLOR_GREEN, 20)
		TE_SendToAll()
		TE_SetupBeamPoints(vClonePoint3, vClonePoint1, g_mdlBeam, g_mdlHalo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, COLOR_GREEN, 20)
		TE_SendToAll()
		TE_SetupBeamPoints(vClonePoint4, vClonePoint2, g_mdlBeam, g_mdlHalo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, COLOR_GREEN, 20)
		TE_SendToAll()
		
		CreateTimer(0.001, Timer_DR, Client)
	} else {
		vPoint2[0] = g_fDelRangePoint2[Client][0]
		vPoint2[1] = g_fDelRangePoint2[Client][1]
		vPoint2[2] = g_fDelRangePoint1[Client][2]
		vPoint3[0] = g_fDelRangePoint1[Client][0]
		vPoint3[1] = g_fDelRangePoint1[Client][1]
		vPoint3[2] = g_fDelRangePoint3[Client][2]
		
		vClonePoint1[0] = g_fDelRangePoint1[Client][0]
		vClonePoint1[1] = vPoint2[1]
		vClonePoint1[2] = g_fDelRangePoint1[Client][2]
		vClonePoint2[0] = vPoint2[0]
		vClonePoint2[1] = g_fDelRangePoint1[Client][1]
		vClonePoint2[2] = vPoint2[2]
		vClonePoint3[0] = vClonePoint1[0]
		vClonePoint3[1] = vClonePoint1[1]
		vClonePoint3[2] = g_fDelRangePoint3[Client][2]
		vClonePoint4[0] = vClonePoint2[0]
		vClonePoint4[1] = vClonePoint2[1]
		vClonePoint4[2] = g_fDelRangePoint3[Client][2]
		
		DrowLine(vClonePoint1, g_fDelRangePoint1[Client], COLOR_WHITE, true)
		DrowLine(vClonePoint2, g_fDelRangePoint1[Client], COLOR_WHITE, true)
		DrowLine(vClonePoint3, g_fDelRangePoint3[Client], COLOR_WHITE, true)
		DrowLine(vClonePoint4, g_fDelRangePoint3[Client], COLOR_WHITE, true)
		DrowLine(vPoint2, vClonePoint1, COLOR_WHITE, true)
		DrowLine(vPoint2, vClonePoint2, COLOR_WHITE, true)
		DrowLine(vPoint3, vClonePoint3, COLOR_WHITE, true)
		DrowLine(vPoint3, vClonePoint4, COLOR_WHITE, true)
		DrowLine(vPoint2, g_fDelRangePoint3[Client], COLOR_WHITE, true)
		DrowLine(vPoint3, g_fDelRangePoint1[Client], COLOR_WHITE, true)
		DrowLine(vClonePoint1, vClonePoint3, COLOR_WHITE, true)
		DrowLine(vClonePoint2, vClonePoint4, COLOR_WHITE, true)
		
		int entDissolver = CreateEntityByName("env_entity_dissolver")
		DispatchKeyValue(entDissolver, "dissolvetype", "3")
		DispatchKeyValue(entDissolver, "targetname", "Del_Dissolver")
		DispatchSpawn(entDissolver)
		ActivateEntity(entDissolver)
		
		float vOriginEntity[3]
		char szClass[32]
		int iCount = 0
		int entProp = -1
		for (int i = 0; i < sizeof(EntityType); i++) {
			while ((entProp = FindEntityByClassname(entProp, EntityType[i])) != -1) {
				GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", vOriginEntity)
				vOriginEntity[2] += 1
				if (vOriginEntity[0] != 0 && vOriginEntity[1] !=1 && vOriginEntity[2] != 0 && LM_IsInSquare(vOriginEntity, g_fDelRangePoint1[Client], g_fDelRangePoint3[Client])) {
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
			LM_PrintToChat(Client, "Deleted %i props.", iCount)
	}
	return Plugin_Handled
}

public Action Timer_DScharge(Handle Timer, Handle hDataPack) {
	float vOriginAim[3], vOriginPlayer[3]
	ResetPack(hDataPack)
	int Client = ReadPackCell(hDataPack)
	float fRange = ReadPackFloat(hDataPack)
	vOriginAim[0] = ReadPackFloat(hDataPack)
	vOriginAim[1] = ReadPackFloat(hDataPack)
	vOriginAim[2] = ReadPackFloat(hDataPack)
	
	GetClientAbsOrigin(Client, vOriginPlayer)
	vOriginPlayer[2] = (vOriginPlayer[2] + 50)
	
	EmitAmbientSound("npc/strider/charging.wav", vOriginAim, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	EmitAmbientSound("npc/strider/charging.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3)
	
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
	WritePackCell(hNewPack, Client)
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

public Action Timer_DSfire(Handle Timer, Handle hDataPack) {
	float vOriginAim[3], vOriginPlayer[3]
	ResetPack(hDataPack)
	new Client = ReadPackCell(hDataPack)
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
	
	EmitAmbientSound("npc/strider/fire.wav", vOriginAim, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	EmitAmbientSound("npc/strider/fire.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_mdlBeam, g_mdlHalo, 0, 66, 0.2, 15.0, 15.0, 0, 0.0, COLOR_RED, 20)
	TE_SendToAll()
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_mdlBeam, g_mdlHalo, 0, 66, 0.2, 20.0, 20.0, 0, 0.0, COLOR_WHITE, 20)
	TE_SendToAll()
	
	int entDissolver = CreateDissolver("3")
	float vOriginEntity[3]
	new iCount = 0
	int entProp = -1
	for (int i = 0; i < sizeof(EntityType); i++) {
		while ((entProp = FindEntityByClassname(entProp, EntityType[i])) != -1) {
			GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", vOriginEntity)
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
	if (iCount > 0 && LM_IsClientValid(Client, Client))
		LM_PrintToChat(Client, "Deleted %i props.", iCount)

	return Plugin_Handled
}

public Action Timer_DScharge2(Handle Timer, Handle hDataPack) {
	float vOriginAim[3], vOriginPlayer[3]
	ResetPack(hDataPack)
	new Client = ReadPackCell(hDataPack)
	float fRange = ReadPackFloat(hDataPack)
	vOriginAim[0] = ReadPackFloat(hDataPack)
	vOriginAim[1] = ReadPackFloat(hDataPack)
	vOriginAim[2] = ReadPackFloat(hDataPack)
	
	GetClientAbsOrigin(Client, vOriginPlayer)
	vOriginPlayer[2] = (vOriginPlayer[2] + 50)
	
	EmitAmbientSound("npc/strider/charging.wav", vOriginAim, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	EmitAmbientSound("npc/strider/charging.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3)
	
	int entPush = CreatePush(vOriginAim, -1000.0, fRange, "28")
	AcceptEntityInput(entPush, "enable", -1)
	
	int entCore = CreateCore(vOriginAim, 5.0, "1")
	AcceptEntityInput(entCore, "startdischarge", -1)
	
	float vOriginEntity[3]
	char szClass[32]
	int entProp = -1
	for (int i = 0; i < sizeof(EntityType); i++) {
		while ((entProp = FindEntityByClassname(entProp, EntityType[i])) != -1) {
			GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", vOriginEntity)
			vOriginEntity[2] = (vOriginEntity[2] + 1)
			if (Phys_IsPhysicsObject(entProp)) {
				GetEdictClassname(entProp, szClass, sizeof(szClass))
				if (LM_IsInRange(vOriginEntity, vOriginAim, fRange)) {
					Phys_EnableMotion(entProp, true)
					if (StrEqual(szClass, "player"))
						SetEntityMoveType(entProp, MOVETYPE_WALK)
					else
						SetEntityMoveType(entProp, MOVETYPE_VPHYSICS)
				}
			}
		}
	}
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
	CreateDataTimer(1.3, Timer_DSfire2, hNewPack)
	WritePackCell(hNewPack, Client)
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

public Action Timer_DSfire2(Handle Timer, Handle hDataPack) {
	float vOriginAim[3], vOriginPlayer[3]
	ResetPack(hDataPack)
	new plyClient = ReadPackCell(hDataPack)
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
	for (int i = 0; i < sizeof(EntityType); i++) {
		while ((entProp = FindEntityByClassname(entProp, EntityType[i])) != -1) {
			GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", vOriginEntity)
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

public OnPropBreak(const char[] output, entProp, iActivator, float delay) {
	if (IsValidEntity(entProp))
		CreateTimer(0.1, Timer_PropBreak, entProp)
}

public Action Timer_PropBreak(Handle Timer, any entProp) {
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

stock DrowLine(float vPoint1[3], float vPoint2[3], Color[4], bool bFinale = false) {
	if (bFinale)
		TE_SetupBeamPoints(vPoint1, vPoint2, g_mdlBeam, g_mdlHalo, 0, 66, 0.5, 7.0, 7.0, 0, 0.0, Color, 20)
	else
		TE_SetupBeamPoints(vPoint1, vPoint2, g_mdlBeam, g_mdlHalo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, Color, 20)
	TE_SendToAll()
}

stock CreatePush(float vOrigin[3], float fMagnitude, float fRange, char szSpawnFlags[8]) {
	new Push_Index = CreateEntityByName("point_push")
	TeleportEntity(Push_Index, vOrigin, NULL_VECTOR, NULL_VECTOR)
	DispatchKeyValueFloat(Push_Index, "magnitude", fMagnitude)
	DispatchKeyValueFloat(Push_Index, "radius", fRange)
	DispatchKeyValueFloat(Push_Index, "inner_radius", fRange)
	DispatchKeyValue(Push_Index, "spawnflags", szSpawnFlags)
	DispatchSpawn(Push_Index)
	return Push_Index
}

stock CreateCore(float vOrigin[3], float fScale, char szSpawnFlags[8]) {
	new Core_Index = CreateEntityByName("env_citadel_energy_core")
	TeleportEntity(Core_Index, vOrigin, NULL_VECTOR, NULL_VECTOR)
	DispatchKeyValueFloat(Core_Index, "scale", fScale)
	DispatchKeyValue(Core_Index, "spawnflags", szSpawnFlags)
	DispatchSpawn(Core_Index)
	return Core_Index
}

stock CreateDissolver(char szDissolveType[4]) {
	new Dissolver_Index = CreateEntityByName("env_entity_dissolver")
	DispatchKeyValue(Dissolver_Index, "dissolvetype", szDissolveType)
	DispatchKeyValue(Dissolver_Index, "targetname", "Del_Dissolver")
	DispatchSpawn(Dissolver_Index)
	return Dissolver_Index
}

