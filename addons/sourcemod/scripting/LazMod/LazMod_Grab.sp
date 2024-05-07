

#include <sourcemod>
#include <sdktools>

#include <vphysics>

#include <lazmod>

int g_Beam
int g_Halo
int g_PBeam

// 
// 

new MoveType:g_mtGrabMoveType[MAXPLAYERS]
int g_iGrabTarget[MAXPLAYERS]
float g_vGrabPlayerOrigin[MAXPLAYERS][3]
bool g_bGrabIsRunning[MAXPLAYERS]
bool g_bGrabFreeze[MAXPLAYERS]

public Plugin myinfo = {
	name = "LazMod - Grab",
	author = "LaZycAt, hjkwe654",
	description = "Grabent props.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	RegAdminCmd("+grabent", Command_EnableGrab, 0, "Grab props.")
	RegAdminCmd("-grabent", Command_DisableGrab, 0, "Grab props.")
	
	PrintToServer( "LazMod Grab loaded!" )
}

public OnMapStart() {
	g_Halo = PrecacheModel("materials/sprites/halo01.vmt")
	// g_Beam = PrecacheModel("materials/sprites/laser.vmt")
	g_PBeam = PrecacheModel("materials/sprites/physbeam.vmt")
}


public Action Command_EnableGrab(Client, args) {
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
		char szFreeze[20], szColorR[20], szColorG[20], szColorB[20], szColor[128]
		GetCmdArg(1, szFreeze, sizeof(szFreeze))
		GetCmdArg(2, szColorR, sizeof(szColorR))
		GetCmdArg(3, szColorG, sizeof(szColorG))
		GetCmdArg(4, szColorB, sizeof(szColorB))
		
		g_bGrabFreeze[Client] = false
		if (StrEqual(szFreeze, "1"))
			g_bGrabFreeze[Client] = true
		
		DispatchKeyValue(g_iGrabTarget[Client], "rendermode", "5")
		DispatchKeyValue(g_iGrabTarget[Client], "renderamt", "150")
		DispatchKeyValue(g_iGrabTarget[Client], "renderfx", "4")
		
		if (StrEqual(szColorR, ""))
			szColorR = "255"
		if (StrEqual(szColorG, ""))
			szColorG = "50"
		if (StrEqual(szColorB, ""))
			szColorB = "50"
		Format(szColor, sizeof(szColor), "%s %s %s", szColorR, szColorG, szColorB)
		DispatchKeyValue(g_iGrabTarget[Client], "rendercolor", szColor)
		
		g_mtGrabMoveType[Client] = GetEntityMoveType(g_iGrabTarget[Client])
		g_bGrabIsRunning[Client] = true
		
		CreateTimer(0.01, Timer_GrabBeam, Client)
		// Disabled for being too fancy
		// CreateTimer(0.01, Timer_GrabRing, Client)
		CreateTimer(0.05, Timer_GrabMain, Client)
	}
	return Plugin_Handled
}

public Action Command_DisableGrab(Client, args) {
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
		
		new iColor[4]
		iColor[0] = GetRandomInt(50, 255)
		iColor[1] = GetRandomInt(50, 255)
		iColor[2] = GetRandomInt(50, 255)
		iColor[3] = 255
		
		TE_SetupBeamPoints(vOriginEntity, vOriginPlayer, g_PBeam, g_Halo, 0, 66, 0.1, 2.0, 2.0, 0, 0.0, iColor, 20)
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
		
		new iColor[4]
		iColor[0] = GetRandomInt(50, 255)
		iColor[1] = GetRandomInt(50, 255)
		iColor[2] = GetRandomInt(50, 255)
		iColor[3] = 255
		
		TE_SetupBeamRingPoint(vOriginEntity, 10.0, 15.0, g_Beam, g_Halo, 0, 10, 0.6, 3.0, 0.5, iColor, 5, 0)
		TE_SetupBeamRingPoint(vOriginEntity, 80.0, 100.0, g_Beam, g_Halo, 0, 10, 0.6, 3.0, 0.5, iColor, 5, 0)
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



