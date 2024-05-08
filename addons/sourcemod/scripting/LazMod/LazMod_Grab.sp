

#include <sourcemod>
#include <sdktools>

#include <vphysics>
#include <smlib>

#include <lazmod>

int g_mdlLaserBeam
int g_mdlHalo

MoveType g_mtGrabMoveType[MAXPLAYERS]
int g_entGrabTarget[MAXPLAYERS]
float g_vGrabPlayerOrigin[MAXPLAYERS][3]
bool g_bGrabIsRunning[MAXPLAYERS] = {false,...}
bool g_bGrabUnfreeze[MAXPLAYERS] = {false,...}
int g_iGrabColor[4] = {255, 50, 50, 255}

int g_entCopyOld[MAXPLAYERS]
int g_entCopyTarget[MAXPLAYERS]
float g_vCopyPlayerOrigin[MAXPLAYERS][3]
bool g_bCopyIsRunning[MAXPLAYERS] = {false,...}
bool g_bCopyUnfreeze[MAXPLAYERS] = {false,...}
int g_iCopyColor[4] = {255, 50, 200, 255}
char CopyableProps[][] = {
	"prop_dynamic",
	"prop_dynamic_override",
	"prop_physics",
	"prop_physics_multiplayer",
	"prop_physics_override",
	"prop_physics_respawnable",
	"prop_ragdoll",
	"func_physbox",
	"player"
}



public Plugin myinfo = {
	name = "LazMod - Grab",
	author = "LaZycAt, hjkwe654",
	description = "Grabent props.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	RegAdminCmd("+grabent", Command_GrabentOn, 0, "Grabent a prop, use '+grabent 1' can freeze prop after grab.")
	RegAdminCmd("-grabent", Command_GrabentOff, 0, "Stop grabent.")
	
	RegAdminCmd("+copyent", Command_CopyentOn, 0, "Copyent a prop.")
	RegAdminCmd("-copyent", Command_CopyentOff, 0, "Stop copyent.")
	
	PrintToServer( "LazMod Grab loaded!" )
}

public OnMapStart() {
	g_mdlHalo = PrecacheModel("materials/sprites/halo01.vmt")
	g_mdlLaserBeam = PrecacheModel("materials/sprites/laser.vmt")
}


public Action Command_GrabentOn(plyClient, args) {
	if (!LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	g_entGrabTarget[plyClient] = LM_GetClientAimEntity(plyClient, true, true)
	if (g_entGrabTarget[plyClient] == -1)
		return Plugin_Handled
	
	if (g_bGrabIsRunning[plyClient]) {
		LM_PrintToChat(plyClient, "You are already grabbing something!")
		return Plugin_Handled
	}	
	
	if (!LM_IsAdmin(plyClient)) {
		if (GetEntityFlags(g_entGrabTarget[plyClient]) == (FL_CLIENT | FL_FAKECLIENT))
			return Plugin_Handled
	}
	
	if (!LM_IsEntityOwner(plyClient, g_entGrabTarget[plyClient]))
		return Plugin_Handled

	char szFreeze[20]
	GetCmdArg(1, szFreeze, sizeof(szFreeze))
	
	g_bGrabUnfreeze[plyClient] = true
	if (!StrEqual(szFreeze, ""))
		g_bGrabUnfreeze[plyClient] = false
	
	SetEntityRenderColor(g_entGrabTarget[plyClient], g_iGrabColor[0], g_iGrabColor[1], g_iGrabColor[2], g_iGrabColor[3])
	SetEntityRenderFx(g_entGrabTarget[plyClient], RENDERFX_PULSE_FAST_WIDE)
	SetEntityRenderMode(g_entGrabTarget[plyClient], RENDER_NORMAL)

	g_mtGrabMoveType[plyClient] = GetEntityMoveType(g_entGrabTarget[plyClient])
	g_bGrabIsRunning[plyClient] = true
	
	CreateTimer(0.01, Timer_GrabBeam, plyClient)
	CreateTimer(0.01, Timer_GrabRing, plyClient)
	CreateTimer(0.05, Timer_GrabMain, plyClient)
	
	return Plugin_Handled
}

public Action Command_GrabentOff(plyClient, args) {
	g_bGrabIsRunning[plyClient] = false
	return Plugin_Handled
}

public Action Timer_GrabBeam(Handle Timer, any plyClient) {
	if(!IsValidEntity(g_entGrabTarget[plyClient]) || !LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
		
	float vOriginEntity[3], vOriginPlayer[3]
	
	GetClientAbsOrigin(plyClient, g_vGrabPlayerOrigin[plyClient])
	GetClientAbsOrigin(plyClient, vOriginPlayer)
	LM_GetEntOrigin(g_entGrabTarget[plyClient], vOriginEntity)
	vOriginPlayer[2] += 50
	
	TE_SetupBeamPoints(vOriginEntity, vOriginPlayer, g_mdlLaserBeam, g_mdlHalo, 0, 66, 0.1, 2.0, 2.0, 0, 0.0, g_iGrabColor, 20)
	TE_SendToAll()
	
	if (g_bGrabIsRunning[plyClient])
		CreateTimer(0.01, Timer_GrabBeam, plyClient)
	
	return Plugin_Handled
}

public Action Timer_GrabRing(Handle Timer, any plyClient) {
	if(!IsValidEntity(g_entGrabTarget[plyClient]) || !LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
		
	float vOriginEntity[3]
	LM_GetEntOrigin(g_entGrabTarget[plyClient], vOriginEntity)
	
	TE_SetupBeamRingPoint(vOriginEntity, 10.0, 15.0, g_mdlLaserBeam, g_mdlHalo, 0, 10, 0.6, 3.0, 0.5, g_iGrabColor, 5, 0)
	TE_SendToAll()
	TE_SetupBeamRingPoint(vOriginEntity, 80.0, 100.0, g_mdlLaserBeam, g_mdlHalo, 0, 10, 0.6, 3.0, 0.5, g_iGrabColor, 5, 0)
	TE_SendToAll()
	
	if (g_bGrabIsRunning[plyClient])
		CreateTimer(0.5, Timer_GrabRing, plyClient)
	
	return Plugin_Handled
}

public Action Timer_GrabMain(Handle Timer, any plyClient) {
	if(!IsValidEntity(g_entGrabTarget[plyClient]) || !LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
		
	float vOriginEntity[3], vOriginPlayer[3]
	
	LM_GetEntOrigin(g_entGrabTarget[plyClient], vOriginEntity)
	GetClientAbsOrigin(plyClient, vOriginPlayer)
	
	vOriginEntity[0] += vOriginPlayer[0] - g_vGrabPlayerOrigin[plyClient][0]
	vOriginEntity[1] += vOriginPlayer[1] - g_vGrabPlayerOrigin[plyClient][1]
	vOriginEntity[2] += vOriginPlayer[2] - g_vGrabPlayerOrigin[plyClient][2]
	
	if(Phys_IsPhysicsObject(g_entGrabTarget[plyClient])) {
		Phys_EnableMotion(g_entGrabTarget[plyClient], false)
		Phys_Sleep(g_entGrabTarget[plyClient])
	}
	SetEntityMoveType(g_entGrabTarget[plyClient], MOVETYPE_NONE)
	TeleportEntity(g_entGrabTarget[plyClient], vOriginEntity)
	
	if (!g_bGrabIsRunning[plyClient]) {
		if (GetEntityFlags(g_entGrabTarget[plyClient]) & (FL_CLIENT | FL_FAKECLIENT)) {
			SetEntityMoveType(g_entGrabTarget[plyClient], MOVETYPE_WALK)
			
		} else {
			if (Phys_IsPhysicsObject(g_entGrabTarget[plyClient])) {
				Phys_EnableMotion(g_entGrabTarget[plyClient], g_bGrabUnfreeze[plyClient])
				Phys_Sleep(g_entGrabTarget[plyClient])
			}
			SetEntityMoveType(g_entGrabTarget[plyClient], g_mtGrabMoveType[plyClient])
		}
		
		SetEntityRenderColor(g_entGrabTarget[plyClient], 255, 255, 255, 255)
		SetEntityRenderFx(g_entGrabTarget[plyClient], RENDERFX_NONE)
		SetEntityRenderMode(g_entGrabTarget[plyClient], RENDER_NORMAL)

	} else {
		CreateTimer(0.001, Timer_GrabMain, plyClient)

	}
	return Plugin_Handled
}



public Action Command_CopyentOn(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp = LM_GetClientAimEntity(plyClient, true, true)
	if (entProp == -1)
		return Plugin_Handled
	
	if(!LM_IsAdmin(plyClient) && (LM_IsFuncProp(entProp) || LM_IsPlayer(entProp))) {
		LM_PrintToChat(plyClient, "You cannot copy this prop!")
		return Plugin_Handled
	}
	
	if (!LM_IsEntityOwner(plyClient, entProp, true))
		return Plugin_Handled
	
	if (g_bCopyIsRunning[plyClient]) {
		LM_PrintToChat(plyClient, "You are already copying something!")
		return Plugin_Handled
	}
	
	char szFreeze[2] = ""
	GetCmdArg(1, szFreeze, sizeof(szFreeze))
		
	g_bCopyUnfreeze[plyClient] = true
	if (StrEqual(szFreeze, "1"))
		g_bCopyUnfreeze[plyClient] = false

	char szClass[32]
	bool bCanCopy = false
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	for (int i = 0; i < sizeof(CopyableProps); i++) {
		if(StrEqual(szClass, CopyableProps[i], false))
			bCanCopy = true
	}
	if (!bCanCopy) {
		LM_PrintToChat(plyClient, "This prop cannot be copied.")
		return Plugin_Handled
	}

	// Note:If a model was designed to be prop_dynamic, spawning as prop_physics will fail to spawn
	//		same as prop_physics to prop_dynamic, using _override can fix this
	if (StrEqual(szClass, "prop_physics") || StrEqual(szClass, "prop_dynamic")) {
		StrCat(szClass, sizeof(szClass), "_override")
	}
	
	char szModelName[128]
	float vOrigin[3], vAngles[3]
	LM_GetEntModel(entProp, szModelName, sizeof(szModelName))
	LM_GetEntOrigin(entProp, vOrigin)
	LM_GetEntAngles(entProp, vAngles)
	g_entCopyTarget[plyClient] = LM_CreateEntity(plyClient, szClass, szModelName, vOrigin, vAngles)
	g_entCopyOld[plyClient] = entProp
	
	if (g_entCopyTarget[plyClient] == -1)
		return Plugin_Handled

	DispatchSpawn(g_entCopyTarget[plyClient])
	
	if (Phys_IsPhysicsObject(g_entCopyTarget[plyClient]))
		Phys_EnableMotion(g_entCopyTarget[plyClient], false)
	
	SetEntityRenderColor(g_entCopyTarget[plyClient], g_iCopyColor[0], g_iCopyColor[1], g_iCopyColor[2], g_iCopyColor[3])
	SetEntityRenderFx(g_entCopyTarget[plyClient], RENDERFX_PULSE_FAST_WIDE)
	SetEntityRenderMode(g_entCopyTarget[plyClient], RENDER_NORMAL)
	
	g_bCopyIsRunning[plyClient] = true
	
	CreateTimer(0.01, Timer_CopyRing, plyClient)
	CreateTimer(0.01, Timer_CopyBeam, plyClient)
	CreateTimer(0.02, Timer_CopyMain, plyClient)

	return Plugin_Handled

}

public Action Command_CopyentOff(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient))
		return Plugin_Handled
	
	g_bCopyIsRunning[plyClient] = false
	return Plugin_Handled
}

public Action Timer_CopyBeam(Handle Timer, any plyClient) {
	if(IsValidEntity(g_entCopyTarget[plyClient]) && LM_IsClientValid(plyClient, plyClient)) {
		float fOriginPlayer[3], vOriginEntity[3]
		
		GetClientAbsOrigin(plyClient, g_vCopyPlayerOrigin[plyClient])
		GetClientAbsOrigin(plyClient, fOriginPlayer)
		
		LM_GetEntOrigin(g_entCopyTarget[plyClient], vOriginEntity)
		fOriginPlayer[2] += 50
		
		TE_SetupBeamPoints(vOriginEntity, fOriginPlayer, g_mdlLaserBeam, g_mdlHalo, 0, 66, 0.1, 2.0, 2.0, 0, 0.0, g_iCopyColor, 20)
		TE_SendToAll()
		
		if (g_bCopyIsRunning[plyClient])
			CreateTimer(0.01, Timer_CopyBeam, plyClient);	
	}
	return Plugin_Handled
}

public Action Timer_CopyRing(Handle Timer, any plyClient) {
	if(IsValidEntity(g_entCopyTarget[plyClient]) && LM_IsClientValid(plyClient, plyClient)) {
		float vOriginEntity[3]
		
		LM_GetEntOrigin(g_entCopyTarget[plyClient], vOriginEntity)
		
		TE_SetupBeamRingPoint(vOriginEntity, 10.0, 15.0, g_mdlLaserBeam, g_mdlHalo, 0, 10, 0.6, 3.0, 0.5, g_iCopyColor, 5, 0)
		TE_SendToAll()
		TE_SetupBeamRingPoint(vOriginEntity, 80.0, 100.0, g_mdlLaserBeam, g_mdlHalo, 0, 10, 0.6, 3.0, 0.5, g_iCopyColor, 5, 0)
		TE_SendToAll()
		
		if (g_bCopyIsRunning[plyClient])
			CreateTimer(0.5, Timer_CopyRing, plyClient)
	}
	return Plugin_Handled
}

public Action Timer_CopyMain(Handle Timer, any plyClient) {
	if(IsValidEntity(g_entCopyTarget[plyClient]) && LM_IsClientValid(plyClient, plyClient)) {

		float vPropOrigin[3], vPlayerOrigin[3]
		
		LM_GetEntOrigin(g_entCopyTarget[plyClient], vPropOrigin)
		GetClientAbsOrigin(plyClient, vPlayerOrigin)
		
		vPropOrigin[0] += vPlayerOrigin[0] - g_vCopyPlayerOrigin[plyClient][0]
		vPropOrigin[1] += vPlayerOrigin[1] - g_vCopyPlayerOrigin[plyClient][1]
		vPropOrigin[2] += vPlayerOrigin[2] - g_vCopyPlayerOrigin[plyClient][2]
		
		if(Phys_IsPhysicsObject(g_entCopyTarget[plyClient])) {
			Phys_EnableMotion(g_entCopyTarget[plyClient], false)
			Phys_Sleep(g_entCopyTarget[plyClient])
		}
		SetEntityMoveType(g_entCopyTarget[plyClient], MOVETYPE_NONE)
		TeleportEntity(g_entCopyTarget[plyClient], vPropOrigin)

		if (g_bCopyIsRunning[plyClient])
			CreateTimer(0.001, Timer_CopyMain, plyClient)
		else {
			if(Phys_IsPhysicsObject(g_entCopyTarget[plyClient])) {
				Phys_EnableMotion(g_entCopyTarget[plyClient], g_bCopyUnfreeze[plyClient])
				Phys_Sleep(g_entCopyTarget[plyClient])
			}

			if (IsValidEdict(g_entCopyOld[plyClient])) {
				SetEntityMoveType(g_entCopyTarget[plyClient], GetEntityMoveType(g_entCopyOld[plyClient]))
				int clr[3], a
				GetEntityRenderColor(g_entCopyOld[plyClient], clr[0], clr[1], clr[2], a)
				LM_SetEntRenderEffects(g_entCopyTarget[plyClient], GetEntityRenderMode(g_entCopyOld[plyClient]), GetEntityRenderFx(g_entCopyOld[plyClient]), a, clr)
			} else {
				DispatchKeyValue(g_entCopyTarget[plyClient], "rendermode", "5")
				DispatchKeyValue(g_entCopyTarget[plyClient], "renderamt", "255")
				DispatchKeyValue(g_entCopyTarget[plyClient], "renderfx", "0")
				DispatchKeyValue(g_entCopyTarget[plyClient], "rendercolor", "255 255 255")
			}
			
			g_entCopyTarget[plyClient] = -1
			g_entCopyOld[plyClient] = -1
		}
	}
	return Plugin_Handled
}

