

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <vphysics>


Handle g_hCvarStackMax = INVALID_HANDLE
int g_iCvarStackMax

int g_entCopyTarget[MAXPLAYERS]
float g_vCopyPlayerOrigin[MAXPLAYERS][3]
bool g_bCopyIsRunning[MAXPLAYERS] = {false, ...}

bool g_bExtendIsRunning[MAXPLAYERS]
int g_entExtendTarget[MAXPLAYERS]

int g_mdlLaserBeam
int g_mdlHalo
int g_mdlPhysBeam

bool g_bStackIsRunning[MAXPLAYERS] = { false,...}
int g_iCurrent[MAXPLAYERS] = { 0,...}

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
	name = "LazMod - Copy",
	author = "LaZycAt, hjkwe654",
	description = "Everything that duplicates props",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	RegAdminCmd("sm_stack", Command_Stack, 0, "Stack a prop.")
	RegAdminCmd("sm_extend", Command_Extend, 0, "Create a third prop based on the position and angle of first two props.")

	RegAdminCmd("+copyent", Command_CopyentOn, 0, "Copy a prop.")
	RegAdminCmd("-copyent", Command_CopyentOff, 0, "Paste a copied prop.")
	
	g_hCvarStackMax	= CreateConVar("lm_stack_max", "10", "How much prop you can stack in one time", FCVAR_NOTIFY, true, 0.0, true, 50.0)
	HookConVarChange(g_hCvarStackMax, Hook_CvarStackMax)

	PrintToServer( "LazMod Copy loaded!" )
}

public OnMapStart() {
	g_mdlHalo = PrecacheModel("materials/sprites/halo01.vmt")
	g_mdlLaserBeam = PrecacheModel("materials/sprites/laser.vmt")
	g_mdlPhysBeam = PrecacheModel("materials/sprites/physbeam.vmt")
}

public Hook_CvarStackMax(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarStackMax = GetConVarBool(g_hCvarStackMax)
}

public Action Command_Stack(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	if (g_bStackIsRunning[plyClient]) {
		LM_PrintToChat(plyClient, "Already stacking a prop, wait for it to finish!")
		return Plugin_Handled
	}	
	
	if (args < 1) {
		LM_PrintToChat(plyClient, "Usage: !stack <amount> [X] [Y] [Z] [unfreeze]")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsEntityOwner(plyClient, entProp))
		return Plugin_Handled
	
	char szModel[128], szClass[33]
	int iUnFreeze = 0, iAmount
	float vMove[3]
	
	iAmount = GetCmdArgInt(1)
	vMove[0] = GetCmdArgFloat(2)
	vMove[1] = GetCmdArgFloat(3)
	vMove[2] = GetCmdArgFloat(4)
	iUnFreeze = GetCmdArgInt(5)
	
	
	if (!LM_IsAdmin(plyClient) && iAmount > g_iCvarStackMax) {
		LM_PrintToChat(plyClient, "Max stack limit is %d", g_iCvarStackMax)
		return Plugin_Handled
	}
	
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	if ((StrEqual(szClass, "prop_ragdoll") || StrEqual(szModel, "models/props_c17/oildrum001_explosive.mdl")) && !LM_IsAdmin(plyClient)) {
		LM_PrintToChat(plyClient, "Restricted to prevent griefing!")
		return Plugin_Handled
	}
	
	Handle hDataPack
	CreateDataTimer(0.001, Timer_Stack, hDataPack)
	WritePackCell(hDataPack, plyClient)
	WritePackCell(hDataPack, entProp)
	WritePackCell(hDataPack, iAmount)
	WritePackFloat(hDataPack, vMove[0])
	WritePackFloat(hDataPack, vMove[1])
	WritePackFloat(hDataPack, vMove[2])
	WritePackCell(hDataPack, iUnFreeze)
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_stack", szArgs)
	return Plugin_Handled
}

public Action Timer_Stack(Handle Timer, Handle hDataPack) {
	float vMove[3], vNext[3]
	ResetPack(hDataPack)
	int Client = ReadPackCell(hDataPack)
	int entProp = ReadPackCell(hDataPack)
	int iAmount = ReadPackCell(hDataPack)
	vMove[0] = ReadPackFloat(hDataPack)
	vMove[1] = ReadPackFloat(hDataPack)
	vMove[2] = ReadPackFloat(hDataPack)
	int iFreeze = ReadPackCell(hDataPack)
	if (g_iCurrent[Client] != 0) {
		vNext[0] = ReadPackFloat(hDataPack)
		vNext[1] = ReadPackFloat(hDataPack)
		vNext[2] = ReadPackFloat(hDataPack)
	}
	
	g_bStackIsRunning[Client] = true
	if (!LM_IsClientValid(Client, Client) || !IsValidEdict(entProp)) {
		g_bStackIsRunning[Client] = false
		g_iCurrent[Client] = 0
		return Plugin_Handled
	}
	
	char szClass[32], szModel[256]
	float vEntityOrigin[3], vEntityAngle[3]
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", vEntityOrigin)
	GetEntPropVector(entProp, Prop_Data, "m_angRotation", vEntityAngle)
	GetEntPropString(entProp, Prop_Data, "m_ModelName", szModel, sizeof(szModel))
	
	if (g_iCurrent[Client] < iAmount) {
		bool IsDoll = false
		new iStackEntity = CreateEntityByName(szClass)
		
		if (StrEqual(szClass, "prop_ragdoll"))
			IsDoll = true
			
		if (LM_SetEntityOwner(iStackEntity, Client, IsDoll)) {			
			DispatchKeyValue(iStackEntity, "model", szModel)
			if (StrEqual(szClass, "prop_dynamic"))
				SetEntProp(iStackEntity, Prop_Send, "m_nSolidType", 6)
			DispatchSpawn(iStackEntity)
			
			AddVectors(vMove, vNext, vNext)
			AddVectors(vNext, vEntityOrigin, vEntityOrigin)
			
			TeleportEntity(iStackEntity, vEntityOrigin, vEntityAngle, NULL_VECTOR)
			
			if (iFreeze == 1) {
				if(Phys_IsPhysicsObject(entProp))
					Phys_EnableMotion(iStackEntity, false)
			}
			g_iCurrent[Client]++
			Handle hNewPack
			CreateDataTimer(0.005, Timer_Stack, hNewPack)
			WritePackCell(hNewPack, Client)
			WritePackCell(hNewPack, entProp)
			WritePackCell(hNewPack, iAmount)
			WritePackFloat(hNewPack, vMove[0])
			WritePackFloat(hNewPack, vMove[1])
			WritePackFloat(hNewPack, vMove[2])
			WritePackCell(hNewPack, iFreeze)
			WritePackFloat(hNewPack, vNext[0])
			WritePackFloat(hNewPack, vNext[1])
			WritePackFloat(hNewPack, vNext[2])
			return Plugin_Handled
		} else {
			g_bStackIsRunning[Client] = false
			g_iCurrent[Client] = 0
			RemoveEdict(iStackEntity)
			return Plugin_Handled
		}
	} else {
		g_bStackIsRunning[Client] = false
		g_iCurrent[Client] = 0
	}
	return Plugin_Handled
}

public Action Command_Extend(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient) || !LM_IsClientValid(plyClient, plyClient, true))
		return Plugin_Handled
	
	int entProp1 = LM_GetClientAimEntity(plyClient)
	if (entProp1 == -1) 
		return Plugin_Handled
	
	char szClass[33]
	GetEdictClassname(entProp1, szClass, sizeof(szClass))
	if (LM_IsEntityOwner(plyClient, entProp1)) {
		int entProp3
		if (StrContains(szClass, "prop_dynamic") >= 0) {
			entProp3 = CreateEntityByName("prop_dynamic_override")
			SetEntProp(entProp3, Prop_Send, "m_nSolidType", 6)
			SetEntProp(entProp3, Prop_Data, "m_nSolidType", 6)
		} else
			entProp3 = CreateEntityByName(szClass)
			
		if (LM_SetEntityOwner(entProp3, plyClient)) {
			if (!g_bExtendIsRunning[plyClient]) {
				g_entExtendTarget[plyClient] = entProp1
				g_bExtendIsRunning[plyClient] = true
				LM_PrintToChat(plyClient, "Extend #1 set, use !ex again on #2 prop.")
			} else {
				char szModel[255]
				float vProp1Origin[3], vProp1Angles[3], vProp2Origin[3], vProp3Origin[3]
				
				GetEntPropVector(g_entExtendTarget[plyClient], Prop_Data, "m_vecOrigin", vProp1Origin)
				GetEntPropVector(g_entExtendTarget[plyClient], Prop_Data, "m_angRotation", vProp1Angles)
				GetEntPropString(g_entExtendTarget[plyClient], Prop_Data, "m_ModelName", szModel, sizeof(szModel))
				GetEntPropVector(entProp1, Prop_Data, "m_vecOrigin", vProp2Origin)
				
				for (int i = 0; i < 3; i++)
					vProp3Origin[i] = (vProp2Origin[i] + vProp2Origin[i] - vProp1Origin[i])
				
				DispatchKeyValue(entProp3, "model", szModel)
				DispatchSpawn(entProp3)
				TeleportEntity(entProp3, vProp3Origin, vProp1Angles, NULL_VECTOR)
				
				if(Phys_IsPhysicsObject(entProp3))
					Phys_EnableMotion(entProp3, false)
				
				g_bExtendIsRunning[plyClient] = false
				LM_PrintToChat(plyClient, "Extended a prop.")
			}
		} else
			RemoveEdict(entProp3)
	}
	
	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_extend", szArgs)
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
		
		new iColor[4]
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
		
		new iColor[4]
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
