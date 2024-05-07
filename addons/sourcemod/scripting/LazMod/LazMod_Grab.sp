

#include <sourcemod>
#include <sdktools>

#include <vphysics>

#include <lazmod>

int g_mdlLaserBeam
int g_mdlHalo
int g_mdlPhysBeam

MoveType g_mtGrabMoveType[MAXPLAYERS]
int g_iGrabTarget[MAXPLAYERS]
float g_vGrabPlayerOrigin[MAXPLAYERS][3]
bool g_bGrabIsRunning[MAXPLAYERS]
bool g_bGrabFreeze[MAXPLAYERS]

int g_entCopyTarget[MAXPLAYERS]
float g_vCopyPlayerOrigin[MAXPLAYERS][3]
bool g_bCopyIsRunning[MAXPLAYERS] = {false, ...}
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
	RegAdminCmd("+grabent", Command_GrabentOn, 0, "Grabent a prop.")
	RegAdminCmd("-grabent", Command_GrabentOff, 0, "Stop grabent.")
	
	RegAdminCmd("+copyent", Command_CopyentOn, 0, "Copyent a prop.")
	RegAdminCmd("-copyent", Command_CopyentOff, 0, "Stop copyent.")
	
	PrintToServer( "LazMod Grab loaded!" )
}

public OnMapStart() {
	g_mdlHalo = PrecacheModel("materials/sprites/halo01.vmt")
	g_mdlLaserBeam = PrecacheModel("materials/sprites/laser.vmt")
	g_mdlPhysBeam = PrecacheModel("materials/sprites/physbeam.vmt")
}


public Action Command_GrabentOn(Client, args) {
	if (!LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	g_iGrabTarget[Client] = LM_GetClientAimEntity(Client, true, true)
	if (g_iGrabTarget[Client] == -1)
		return Plugin_Handled
	
	if (g_bGrabIsRunning[Client]) {
		LM_PrintToChat(Client, "You are already grabbing something!")
		return Plugin_Handled
	}	
	
	if (!LM_IsAdmin(Client)) {
		if (GetEntityFlags(g_iGrabTarget[Client]) == (FL_CLIENT | FL_FAKECLIENT))
			return Plugin_Handled
	}
	
	if (LM_IsEntityOwner(Client, g_iGrabTarget[Client])) {		
		char szFreeze[20]
		GetCmdArg(1, szFreeze, sizeof(szFreeze))
		
		g_bGrabFreeze[Client] = false
		if (StrEqual(szFreeze, "1"))
			g_bGrabFreeze[Client] = true
		
		DispatchKeyValue(g_iGrabTarget[Client], "rendermode", "5")
		DispatchKeyValue(g_iGrabTarget[Client], "renderamt", "150")
		DispatchKeyValue(g_iGrabTarget[Client], "renderfx", "4")
		
		DispatchKeyValue(g_iGrabTarget[Client], "rendercolor", "255 50 50")
		
		g_mtGrabMoveType[Client] = GetEntityMoveType(g_iGrabTarget[Client])
		g_bGrabIsRunning[Client] = true
		
		CreateTimer(0.01, Timer_GrabBeam, Client)
		// Disabled for being too fancy
		// CreateTimer(0.01, Timer_GrabRing, Client)
		CreateTimer(0.05, Timer_GrabMain, Client)
	}
	return Plugin_Handled
}

public Action Command_GrabentOff(Client, args) {
	g_bGrabIsRunning[Client] = false
	return Plugin_Handled
}

public Action Timer_GrabBeam(Handle Timer, any Client) {
	if(IsValidEntity(g_iGrabTarget[Client]) && LM_IsClientValid(Client, Client)) {
		float vOriginEntity[3], vOriginPlayer[3]
		
		GetClientAbsOrigin(Client, g_vGrabPlayerOrigin[Client])
		GetClientAbsOrigin(Client, vOriginPlayer)
		GetEntPropVector(g_iGrabTarget[Client], Prop_Data, "m_vecOrigin", vOriginEntity)
		vOriginPlayer[2] += 50
		
		int iColor[4]
		iColor[0] = GetRandomInt(50, 255)
		iColor[1] = GetRandomInt(50, 255)
		iColor[2] = GetRandomInt(50, 255)
		iColor[3] = 255
		
		TE_SetupBeamPoints(vOriginEntity, vOriginPlayer, g_mdlPhysBeam, g_mdlHalo, 0, 66, 0.1, 2.0, 2.0, 0, 0.0, iColor, 20)
		TE_SendToAll()
		
		if (g_bGrabIsRunning[Client])
			CreateTimer(0.01, Timer_GrabBeam, Client)
	}
	return Plugin_Handled
}

public Action Timer_GrabRing(Handle Timer, any Client) {
	if(IsValidEntity(g_iGrabTarget[Client]) && LM_IsClientValid(Client, Client)) {
		float vOriginEntity[3]
		GetEntPropVector(g_iGrabTarget[Client], Prop_Data, "m_vecOrigin", vOriginEntity)
		
		int iColor[4]
		iColor[0] = GetRandomInt(50, 255)
		iColor[1] = GetRandomInt(50, 255)
		iColor[2] = GetRandomInt(50, 255)
		iColor[3] = 255
		
		TE_SetupBeamRingPoint(vOriginEntity, 10.0, 15.0, g_mdlLaserBeam, g_mdlHalo, 0, 10, 0.6, 3.0, 0.5, iColor, 5, 0)
		TE_SetupBeamRingPoint(vOriginEntity, 80.0, 100.0, g_mdlLaserBeam, g_mdlHalo, 0, 10, 0.6, 3.0, 0.5, iColor, 5, 0)
		TE_SendToAll()
		
		if (g_bGrabIsRunning[Client])
			CreateTimer(0.3, Timer_GrabRing, Client)
	}
	return Plugin_Handled
}

public Action Timer_GrabMain(Handle Timer, any Client) {
	if(IsValidEntity(g_iGrabTarget[Client]) && LM_IsClientValid(Client, Client)) {
		// if (!LM_IsAdmin(Client)) {
			// if (LM_GetEntityOwner(g_iGrabTarget[Client]) != Client) {
				// g_bGrabIsRunning[Client] = false
				// return
			// }
		// }
		
		float vOriginEntity[3], vOriginPlayer[3]
		
		GetEntPropVector(g_iGrabTarget[Client], Prop_Data, "m_vecOrigin", vOriginEntity)
		GetClientAbsOrigin(Client, vOriginPlayer)
		
		vOriginEntity[0] += vOriginPlayer[0] - g_vGrabPlayerOrigin[Client][0]
		vOriginEntity[1] += vOriginPlayer[1] - g_vGrabPlayerOrigin[Client][1]
		vOriginEntity[2] += vOriginPlayer[2] - g_vGrabPlayerOrigin[Client][2]
		
		if(Phys_IsPhysicsObject(g_iGrabTarget[Client])) {
			Phys_EnableMotion(g_iGrabTarget[Client], false)
			Phys_Sleep(g_iGrabTarget[Client])
		}
		SetEntityMoveType(g_iGrabTarget[Client], MOVETYPE_NONE)
		TeleportEntity(g_iGrabTarget[Client], vOriginEntity, NULL_VECTOR, NULL_VECTOR)
		
		if (g_bGrabIsRunning[Client])
			CreateTimer(0.001, Timer_GrabMain, Client)
		else {
			if (GetEntityFlags(g_iGrabTarget[Client]) & (FL_CLIENT | FL_FAKECLIENT))
				SetEntityMoveType(g_iGrabTarget[Client], MOVETYPE_WALK)
			else {
				if (!g_bGrabFreeze[Client] && Phys_IsPhysicsObject(g_iGrabTarget[Client])) {
					Phys_EnableMotion(g_iGrabTarget[Client], true)
					Phys_Sleep(g_iGrabTarget[Client])
				}
				SetEntityMoveType(g_iGrabTarget[Client], g_mtGrabMoveType[Client])
			}
			DispatchKeyValue(g_iGrabTarget[Client], "rendermode", "5")
			DispatchKeyValue(g_iGrabTarget[Client], "renderamt", "255")
			DispatchKeyValue(g_iGrabTarget[Client], "renderfx", "0")
			DispatchKeyValue(g_iGrabTarget[Client], "rendercolor", "255 255 255")
		}
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
	
	char szClass[33]
	bool bCanCopy = false
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	for (int i = 0; i < sizeof(CopyableProps); i++) {
		if(StrEqual(szClass, CopyableProps[i], false))
			bCanCopy = true
	}
	
	bool IsDoll = false
	if (StrEqual(szClass, "prop_ragdoll") || StrEqual(szClass, "player")) {
		g_entCopyTarget[plyClient] = CreateEntityByName("prop_ragdoll")
		IsDoll = true
		
	} else {
		g_entCopyTarget[plyClient] = CreateEntityByName(szClass)
	}
	
	if (LM_SetEntityOwner(g_entCopyTarget[plyClient], plyClient, IsDoll)) {
		if (bCanCopy) {
			float fEntityOrigin[3], fEntityAngle[3]
			char szModelName[128]
			char szColorR[20], szColorG[20], szColorB[20], szColor[3][128], szColor2[255]
			
			GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", fEntityOrigin)
			GetEntPropVector(entProp, Prop_Data, "m_angRotation", fEntityAngle)
			GetEntPropString(entProp, Prop_Data, "m_ModelName", szModelName, sizeof(szModelName))
			DispatchKeyValue(g_entCopyTarget[plyClient], "model", szModelName)
			
			
			GetEdictClassname(g_entCopyTarget[plyClient], szClass, sizeof(szClass))
			if (StrEqual(szClass, "prop_dynamic")) {
				SetEntProp(g_entCopyTarget[plyClient], Prop_Send, "m_nSolidType", 6)
				SetEntProp(g_entCopyTarget[plyClient], Prop_Data, "m_nSolidType", 6)
			}
			
			DispatchSpawn(g_entCopyTarget[plyClient])
			TeleportEntity(g_entCopyTarget[plyClient], fEntityOrigin, fEntityAngle, NULL_VECTOR)
			
			if (Phys_IsPhysicsObject(g_entCopyTarget[plyClient]))
				Phys_EnableMotion(g_entCopyTarget[plyClient], false)
			
			GetCmdArg(1, szColorR, sizeof(szColorR))
			GetCmdArg(2, szColorG, sizeof(szColorG))
			GetCmdArg(3, szColorB, sizeof(szColorB))
			
			DispatchKeyValue(g_entCopyTarget[plyClient], "rendermode", "5")
			DispatchKeyValue(g_entCopyTarget[plyClient], "renderamt", "150")
			DispatchKeyValue(g_entCopyTarget[plyClient], "renderfx", "4")
			
			if (args > 1) {
				szColor[0] = szColorR
				szColor[1] = szColorG
				szColor[2] = szColorB
				ImplodeStrings(szColor, 3, " ", szColor2, 255)
				DispatchKeyValue(g_entCopyTarget[plyClient], "rendercolor", szColor2)
			} else {
				DispatchKeyValue(g_entCopyTarget[plyClient], "rendercolor", "50 255 255")
			}
			g_bCopyIsRunning[plyClient] = true
			
			CreateTimer(0.01, Timer_CopyRing, plyClient)
			CreateTimer(0.01, Timer_CopyBeam, plyClient)
			CreateTimer(0.02, Timer_CopyMain, plyClient)
			return Plugin_Handled
		} else {
			LM_PrintToChat(plyClient, "This prop was not copy able.")
			return Plugin_Handled
		}
	} else {
		RemoveEdict(g_entCopyTarget[plyClient])
		return Plugin_Handled
	}
	// return Plugin_Handled
}

public Action Command_CopyentOff(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled
		
	g_bCopyIsRunning[Client] = false
	return Plugin_Handled
}

public Action Timer_CopyBeam(Handle Timer, any Client) {
	if(IsValidEntity(g_entCopyTarget[Client]) && LM_IsClientValid(Client, Client)) {
		float fOriginPlayer[3], fOriginEntity[3]
		
		GetClientAbsOrigin(Client, g_vCopyPlayerOrigin[Client])
		GetClientAbsOrigin(Client, fOriginPlayer)
		
		GetEntPropVector(g_entCopyTarget[Client], Prop_Data, "m_vecOrigin", fOriginEntity)
		fOriginPlayer[2] += 50
		
		int iColor[4]
		iColor[0] = GetRandomInt(50, 255)
		iColor[1] = GetRandomInt(50, 255)
		iColor[2] = GetRandomInt(50, 255)
		iColor[3] = GetRandomInt(255, 255)
		
		TE_SetupBeamPoints(fOriginEntity, fOriginPlayer, g_mdlPhysBeam, g_mdlHalo, 0, 66, 0.1, 2.0, 2.0, 0, 0.0, iColor, 20)
		TE_SendToAll()
		
		if (g_bCopyIsRunning[Client])
			CreateTimer(0.01, Timer_CopyBeam, Client);	
	}
	return Plugin_Handled
}

public Action Timer_CopyRing(Handle Timer, any Client) {
	if(IsValidEntity(g_entCopyTarget[Client]) && LM_IsClientValid(Client, Client)) {
		float fOriginEntity[3]
		
		GetEntPropVector(g_entCopyTarget[Client], Prop_Data, "m_vecOrigin", fOriginEntity)
		
		int iColor[4]
		iColor[0] = GetRandomInt(50, 255)
		iColor[1] = GetRandomInt(254, 255)
		iColor[2] = GetRandomInt(254, 255)
		iColor[3] = GetRandomInt(250, 255)
		
		TE_SetupBeamRingPoint(fOriginEntity, 10.0, 15.0, g_mdlLaserBeam, g_mdlHalo, 0, 10, 0.6, 3.0, 0.5, iColor, 5, 0)
		TE_SendToAll()
		TE_SetupBeamRingPoint(fOriginEntity, 80.0, 100.0, g_mdlLaserBeam, g_mdlHalo, 0, 10, 0.6, 3.0, 0.5, iColor, 5, 0)
		TE_SendToAll()
		
		if (g_bCopyIsRunning[Client])
			CreateTimer(0.3, Timer_CopyRing, Client)
	}
	return Plugin_Handled
}

public Action Timer_CopyMain(Handle Timer, any plyClient) {
	if(IsValidEntity(g_entCopyTarget[plyClient]) && LM_IsClientValid(plyClient, plyClient)) {
		float vPropOrigin[3], vPlayerOrigin[3]
		
		GetEntPropVector(g_entCopyTarget[plyClient], Prop_Data, "m_vecOrigin", vPropOrigin)
		GetClientAbsOrigin(plyClient, vPlayerOrigin)
		
		vPropOrigin[0] += vPlayerOrigin[0] - g_vCopyPlayerOrigin[plyClient][0]
		vPropOrigin[1] += vPlayerOrigin[1] - g_vCopyPlayerOrigin[plyClient][1]
		vPropOrigin[2] += vPlayerOrigin[2] - g_vCopyPlayerOrigin[plyClient][2]
		
		if(Phys_IsPhysicsObject(g_entCopyTarget[plyClient])) {
			Phys_EnableMotion(g_entCopyTarget[plyClient], false)
			Phys_Sleep(g_entCopyTarget[plyClient])
		}
		SetEntityMoveType(g_entCopyTarget[plyClient], MOVETYPE_NONE)
		TeleportEntity(g_entCopyTarget[plyClient], vPropOrigin, NULL_VECTOR, NULL_VECTOR)

		if (g_bCopyIsRunning[plyClient])
			CreateTimer(0.001, Timer_CopyMain, plyClient)
		else {
			if(Phys_IsPhysicsObject(g_entCopyTarget[plyClient])) {
				Phys_EnableMotion(g_entCopyTarget[plyClient], true)
				Phys_Sleep(g_entCopyTarget[plyClient])
			}
			SetEntityMoveType(g_entCopyTarget[plyClient], MOVETYPE_VPHYSICS)
			
			DispatchKeyValue(g_entCopyTarget[plyClient], "rendermode", "5")
			DispatchKeyValue(g_entCopyTarget[plyClient], "renderamt", "255")
			DispatchKeyValue(g_entCopyTarget[plyClient], "renderfx", "0")
			DispatchKeyValue(g_entCopyTarget[plyClient], "rendercolor", "255 255 255")
		}
	}
	return Plugin_Handled
}

