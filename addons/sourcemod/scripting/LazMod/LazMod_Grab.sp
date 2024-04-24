#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <vphysics>

#define MSGTAG "\x01[\x04LM\x01]"

new g_Beam;
new g_Halo;
new g_PBeam;

// new bool:g_bClientLang[MAXPLAYERS];
// new Handle:g_hCookieClientLang;

new MoveType:g_mtGrabMoveType[MAXPLAYERS];
new g_iGrabTarget[MAXPLAYERS];
new Float:g_vGrabPlayerOrigin[MAXPLAYERS][3];
new bool:g_bGrabIsRunning[MAXPLAYERS];
new bool:g_bGrabFreeze[MAXPLAYERS];

public Plugin:myinfo = {
	name = "LazMod - Grab",
	author = "LaZycAt, hjkwe654",
	description = "Grabent props.",
	version = LAZMOD_VER,
	url = ""
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {

	CreateNative("LM_PrintToChat", Native_PrintToChat);
	CreateNative("LM_ClientAimEntity", Native_ClientAimEntity);
	CreateNative("LM_IsClientValid", Native_IsClientValid);
	
	return APLRes_Success;
}

public OnPluginStart() {
	RegAdminCmd("+grabent", Command_EnableGrab, 0, "Grab props.");
	RegAdminCmd("-grabent", Command_DisableGrab, 0, "Grab props.");
	// g_hCookieClientLang = RegClientCookie("cookie_BuildModClientLang", "BuildMod Client Language.", CookieAccess_Private);
}

public OnMapStart() {
	g_Halo = PrecacheModel("materials/sprites/halo01.vmt");
	g_Beam = PrecacheModel("materials/sprites/laser.vmt");
	g_PBeam = PrecacheModel("materials/sprites/physbeam.vmt");
}

// public Action:OnClientCommand(Client, args) {
// 	if (Client > 0) {
// 		if (LM_IsClientValid(Client, Client)) {
// 			new String:Lang[8];
// 			GetClientCookie(Client, g_hCookieClientLang, Lang, sizeof(Lang));
// 			if (StrEqual(Lang, "1"))
// 				g_bClientLang[Client] = true;
// 			else
// 				g_bClientLang[Client] = false;
// 		}
// 	}
// }

public Action:Command_EnableGrab(Client, args) {
	if (!LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	g_iGrabTarget[Client] = LM_ClientAimEntity(Client, true, true);
	if (g_iGrabTarget[Client] == -1)
		return Plugin_Handled;
	
	if (g_bGrabIsRunning[Client]) {
		// if (g_bClientLang[Client])
		// 	LM_PrintToChat(Client, "你正在移動其他物件!");
		// else
			LM_PrintToChat(Client, "You are already grabbing something!");
		return Plugin_Handled;
	}	
	
	// if (!LM_IsAdmin(Client)) {
		if (GetEntityFlags(g_iGrabTarget[Client]) == (FL_CLIENT | FL_FAKECLIENT))
			return Plugin_Handled;
	// }
	
	// if (LM_IsEntityOwner(Client, g_iGrabTarget[Client])) {		
		decl String:szFreeze[20], String:szColorR[20], String:szColorG[20], String:szColorB[20], String:szColor[128];
		GetCmdArg(1, szFreeze, sizeof(szFreeze));
		GetCmdArg(2, szColorR, sizeof(szColorR));
		GetCmdArg(3, szColorG, sizeof(szColorG));
		GetCmdArg(4, szColorB, sizeof(szColorB));
		
		g_bGrabFreeze[Client] = false;
		if (StrEqual(szFreeze, "1"))
			g_bGrabFreeze[Client] = true;
		
		DispatchKeyValue(g_iGrabTarget[Client], "rendermode", "5");
		DispatchKeyValue(g_iGrabTarget[Client], "renderamt", "150");
		DispatchKeyValue(g_iGrabTarget[Client], "renderfx", "4");
		
		if (StrEqual(szColorR, ""))
			szColorR = "255";
		if (StrEqual(szColorG, ""))
			szColorG = "50";
		if (StrEqual(szColorB, ""))
			szColorB = "50";
		Format(szColor, sizeof(szColor), "%s %s %s", szColorR, szColorG, szColorB);
		DispatchKeyValue(g_iGrabTarget[Client], "rendercolor", szColor);
		
		g_mtGrabMoveType[Client] = GetEntityMoveType(g_iGrabTarget[Client]);
		g_bGrabIsRunning[Client] = true;
		
		CreateTimer(0.01, Timer_GrabBeam, Client);
		// CreateTimer(0.01, Timer_GrabRing, Client);
		CreateTimer(0.05, Timer_GrabMain, Client);
	// }
	return Plugin_Handled;
}

public Action:Command_DisableGrab(Client, args) {
	g_bGrabIsRunning[Client] = false;
	return Plugin_Handled;
}

public Action:Timer_GrabBeam(Handle:Timer, any:Client) {
	if(IsValidEntity(g_iGrabTarget[Client]) && LM_IsClientValid(Client, Client)) {
		new Float:vOriginEntity[3], Float:vOriginPlayer[3];
		
		GetClientAbsOrigin(Client, g_vGrabPlayerOrigin[Client]);
		GetClientAbsOrigin(Client, vOriginPlayer);
		GetEntPropVector(g_iGrabTarget[Client], Prop_Data, "m_vecOrigin", vOriginEntity);
		vOriginPlayer[2] += 50;
		
		new iColor[4];
		iColor[0] = GetRandomInt(50, 255);
		iColor[1] = GetRandomInt(50, 255);
		iColor[2] = GetRandomInt(50, 255);
		iColor[3] = 255;
		
		TE_SetupBeamPoints(vOriginEntity, vOriginPlayer, g_PBeam, g_Halo, 0, 66, 0.1, 2.0, 2.0, 0, 0.0, iColor, 20);
		TE_SendToAll();
		
		if (g_bGrabIsRunning[Client])
			CreateTimer(0.01, Timer_GrabBeam, Client);
	}
}

// public Action:Timer_GrabRing(Handle:Timer, any:Client) {
// 	if(IsValidEntity(g_iGrabTarget[Client]) && LM_IsClientValid(Client, Client)) {
// 		new Float:vOriginEntity[3];
// 		GetEntPropVector(g_iGrabTarget[Client], Prop_Data, "m_vecOrigin", vOriginEntity);
		
// 		new iColor[4];
// 		iColor[0] = GetRandomInt(50, 255);
// 		iColor[1] = GetRandomInt(50, 255);
// 		iColor[2] = GetRandomInt(50, 255);
// 		iColor[3] = 255;
		
// 		TE_SetupBeamRingPoint(vOriginEntity, 10.0, 15.0, g_Beam, g_Halo, 0, 10, 0.6, 3.0, 0.5, iColor, 5, 0);
// 		TE_SetupBeamRingPoint(vOriginEntity, 80.0, 100.0, g_Beam, g_Halo, 0, 10, 0.6, 3.0, 0.5, iColor, 5, 0);
// 		TE_SendToAll();
		
// 		if (g_bGrabIsRunning[Client])
// 			CreateTimer(0.3, Timer_GrabRing, Client);
// 	}
// }

public Action:Timer_GrabMain(Handle:Timer, any:Client) {
	if(IsValidEntity(g_iGrabTarget[Client]) && LM_IsClientValid(Client, Client)) {
		// if (!LM_IsAdmin(Client)) {
			// if (LM_GetEntityOwner(g_iGrabTarget[Client]) != Client) {
				// g_bGrabIsRunning[Client] = false;
				// return;
			// }
		// }
		
		new Float:vOriginEntity[3], Float:vOriginPlayer[3];
		
		GetEntPropVector(g_iGrabTarget[Client], Prop_Data, "m_vecOrigin", vOriginEntity);
		GetClientAbsOrigin(Client, vOriginPlayer);
		
		vOriginEntity[0] += vOriginPlayer[0] - g_vGrabPlayerOrigin[Client][0];
		vOriginEntity[1] += vOriginPlayer[1] - g_vGrabPlayerOrigin[Client][1];
		vOriginEntity[2] += vOriginPlayer[2] - g_vGrabPlayerOrigin[Client][2];
		
		if(Phys_IsPhysicsObject(g_iGrabTarget[Client])) {
			Phys_EnableMotion(g_iGrabTarget[Client], false);
			Phys_Sleep(g_iGrabTarget[Client]);
		}
		SetEntityMoveType(g_iGrabTarget[Client], MOVETYPE_NONE);
		TeleportEntity(g_iGrabTarget[Client], vOriginEntity, NULL_VECTOR, NULL_VECTOR);
		
		if (g_bGrabIsRunning[Client])
			CreateTimer(0.001, Timer_GrabMain, Client);
		else {
			if (GetEntityFlags(g_iGrabTarget[Client]) & (FL_CLIENT | FL_FAKECLIENT))
				SetEntityMoveType(g_iGrabTarget[Client], MOVETYPE_WALK);
			else {
				if (!g_bGrabFreeze[Client] && Phys_IsPhysicsObject(g_iGrabTarget[Client])) {
					Phys_EnableMotion(g_iGrabTarget[Client], true);
					Phys_Sleep(g_iGrabTarget[Client]);
				}
				SetEntityMoveType(g_iGrabTarget[Client], g_mtGrabMoveType[Client]);
			}
			DispatchKeyValue(g_iGrabTarget[Client], "rendermode", "5");
			DispatchKeyValue(g_iGrabTarget[Client], "renderamt", "255");
			DispatchKeyValue(g_iGrabTarget[Client], "renderfx", "0");
			DispatchKeyValue(g_iGrabTarget[Client], "rendercolor", "255 255 255");
		}
	}
	return;
}





public Native_IsClientValid(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);
	new iTarget = GetNativeCell(2);
	new bool:IsAlive, bool:ReplyTarget;
	if (iNumParams == 3)
		IsAlive = GetNativeCell(3);
	if (iNumParams == 4)
		ReplyTarget = GetNativeCell(4);
	
	if (iTarget < 1 || iTarget > 32)
		return false;
	if (!IsClientInGame(iTarget))
		return false;
	else if (IsAlive) {
		if (!IsPlayerAlive(iTarget)) {
			if (ReplyTarget) {
				// if (g_bClientLang[Client])
				// 	LM_PrintToChat(Client, "無法在目標玩家死亡狀態下使用.");
				// else
					LM_PrintToChat(Client, "This command can only be used on alive players.");
			} else {
				// if (g_bClientLang[Client])
				// 	LM_PrintToChat(Client, "你無法在死亡狀態下使用此指令.");
				// else
					LM_PrintToChat(Client, "You cannot use the command if you dead.");
			}
			return false;
		}
	}
	return true;
}





public bool:TraceEntityFilter(entity, mask, any:data) {
    return data != entity;
}

public Native_ClientAimEntity(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);
	new bool:bShowMsg = GetNativeCell(2);
	new bool:bIncClient = false;
	new Float:vOrigin[3], Float:vAngles[3];
	GetClientEyePosition(Client, vOrigin);
	GetClientEyeAngles(Client, vAngles);
	
	if (iNumParams >= 3)
		bIncClient = GetNativeCell(3);
	
	// Command Range Limit
	{
		/*
		new Float:AnglesVec[3], Float:EndPoint[3], Float:Distance;
		if (LM_IsAdmin(Client))
			Distance = 50000.0;
		else
			Distance = 1000.0;
		GetClientEyeAngles(Client,vAngles);
		GetClientEyePosition(Client,vOrigin);
		GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);

		EndPoint[0] = vOrigin[0] + (AnglesVec[0]*Distance);
		EndPoint[1] = vOrigin[1] + (AnglesVec[1]*Distance);
		EndPoint[2] = vOrigin[2] + (AnglesVec[2]*Distance);
		new Handle:trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_SHOT, RayType_EndPoint, TraceEntityFilter, Client);
		*/
	}
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilter, Client);
	
	if (TR_DidHit(trace)) {
		new iEntity = TR_GetEntityIndex(trace);
		
		if (iEntity > 0 && IsValidEntity(iEntity)) {
			if(!bIncClient) {
				if (!(GetEntityFlags(iEntity) & (FL_CLIENT | FL_FAKECLIENT))) {
					CloseHandle(trace);
					return iEntity;
				}
			} else {
				CloseHandle(trace);
				return iEntity;
			}
		}
	}
	
	if (bShowMsg) {
		// if (g_bClientLang[Client])
		// 	LM_PrintToChat(Client, "你未瞄準任何目標或目標無效.");
		// else
			LM_PrintToChat(Client, "You dont have a target or target invalid.");
	}
	CloseHandle(trace);
	return -1;
}





public Native_PrintToChat(Handle:hPlugin, iNumParams) {
	new String:szMsg[192], written;
	FormatNativeString(0, 2, 3, sizeof(szMsg), written, szMsg);
	if (GetNativeCell(1) > 0)
		PrintToChat(GetNativeCell(1), "%s %s", MSGTAG, szMsg);
}
