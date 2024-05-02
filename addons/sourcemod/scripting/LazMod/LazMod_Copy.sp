

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <vphysics>


int g_iCopyTarget[MAXPLAYERS]
float g_fCopyPlayerOrigin[MAXPLAYERS][3]
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

	RegAdminCmd("+copyent", Command_Copyent, 0, "Copy a prop.")
	RegAdminCmd("-copyent", Command_Paste, 0, "Paste a copied prop.")
	
	PrintToServer( "LazMod Copy loaded!" )
}

public OnMapStart() {
	g_mdlHalo = PrecacheModel("materials/sprites/halo01.vmt")
	g_mdlLaserBeam = PrecacheModel("materials/sprites/laser.vmt")
	g_mdlPhysBeam = PrecacheModel("materials/sprites/physbeam.vmt")
}

public Action Command_Stack(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled
	
	if (g_bStackIsRunning[Client]) {
		LM_PrintToChat(Client, "Already stacking a prop, wait for it to finish!")
		return Plugin_Handled
	}	
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !stack <amount> [X] [Y] [Z] [unfreeze]")
		return Plugin_Handled
	}
	
	int entProp = LM_GetClientAimEntity(Client)
	if (entProp == -1) 
		return Plugin_Handled
	
	if (!LM_IsEntityOwner(Client, entProp))
		return Plugin_Handled
	
	char szAmount[5], szMoveX[8], szMoveY[8], szMoveZ[8], szFreeze[5], szModel[128], szClass[33]
	int iFreeze = 0
	float vMove[3]
	
	GetCmdArg(1, szAmount, sizeof(szAmount))
	GetCmdArg(2, szMoveX, sizeof(szMoveX))
	GetCmdArg(3, szMoveY, sizeof(szMoveY))
	GetCmdArg(4, szMoveZ, sizeof(szMoveZ))
	GetCmdArg(5, szFreeze, sizeof(szFreeze))
	
	vMove[0] = StringToFloat(szMoveX)
	vMove[1] = StringToFloat(szMoveY)
	vMove[2] = StringToFloat(szMoveZ)
	
	if (!StrEqual(szFreeze, ""))
		iFreeze = 1
	
	int iAmount = StringToInt(szAmount)
	if (!LM_IsAdmin(Client) && iAmount > 10) {
		LM_PrintToChat(Client, "Max stack limit is 10")
		return Plugin_Handled
	}
	
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	if ((StrEqual(szClass, "prop_ragdoll") || StrEqual(szModel, "models/props_c17/oildrum001_explosive.mdl")) && !LM_IsAdmin(Client)) {
		LM_PrintToChat(Client, "Restricted to prevent griefing!")
		return Plugin_Handled
	}
	
	Handle hDataPack
	CreateDataTimer(0.001, Timer_Stack, hDataPack)
	WritePackCell(hDataPack, Client)
	WritePackCell(hDataPack, entProp)
	WritePackCell(hDataPack, iAmount)
	WritePackFloat(hDataPack, vMove[0])
	WritePackFloat(hDataPack, vMove[1])
	WritePackFloat(hDataPack, vMove[2])
	WritePackCell(hDataPack, iFreeze)
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_stack", szArgs)
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
	
	int entProp = LM_GetClientAimEntity(plyClient)
	if (entProp == -1) 
		return Plugin_Handled
	
	char szClass[33]
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	if (LM_IsEntityOwner(plyClient, entProp)) {
		int entThirdProp
		if (StrContains(szClass, "prop_dynamic") >= 0) {
			entThirdProp = CreateEntityByName("prop_dynamic_override")
			SetEntProp(entThirdProp, Prop_Send, "m_nSolidType", 6)
			SetEntProp(entThirdProp, Prop_Data, "m_nSolidType", 6)
		} else
			entThirdProp = CreateEntityByName(szClass)
			
		if (LM_SetEntityOwner(entThirdProp, plyClient)) {
			if (!g_bExtendIsRunning[plyClient]) {
				g_entExtendTarget[plyClient] = entProp
				g_bExtendIsRunning[plyClient] = true
				LM_PrintToChat(plyClient, "Extend #1 set, use !ex again on #2 prop.")
			} else {
				char szModel[255]
				float fOriginProp1[3], fAngle[3], fOriginProp2[3], fOriginProp3[3]
				
				GetEntPropVector(g_entExtendTarget[plyClient], Prop_Data, "m_vecOrigin", fOriginProp1)
				GetEntPropVector(g_entExtendTarget[plyClient], Prop_Data, "m_angRotation", fAngle)
				GetEntPropString(g_entExtendTarget[plyClient], Prop_Data, "m_ModelName", szModel, sizeof(szModel))
				GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", fOriginProp2)
				
				for (int i = 0; i < 3; i++)
					fOriginProp3[i] = (fOriginProp2[i] + fOriginProp2[i] - fOriginProp1[i])
				
				DispatchKeyValue(entThirdProp, "model", szModel)
				DispatchSpawn(entThirdProp)
				TeleportEntity(entThirdProp, fOriginProp3, fAngle, NULL_VECTOR)
				
				if(Phys_IsPhysicsObject(entThirdProp))
					Phys_EnableMotion(entThirdProp, false)
				
				g_bExtendIsRunning[plyClient] = false
				LM_PrintToChat(plyClient, "Extended a prop.")
			}
		} else
			RemoveEdict(entThirdProp)
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(plyClient, "sm_extend", szArgs)
	return Plugin_Handled
}



public Action Command_Copyent(plyClient, args) {
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
		g_iCopyTarget[plyClient] = CreateEntityByName("prop_ragdoll")
		IsDoll = true
		
	} else {
		g_iCopyTarget[plyClient] = CreateEntityByName(szClass)
	}
	
	if (LM_SetEntityOwner(g_iCopyTarget[plyClient], plyClient, IsDoll)) {
		if (bCanCopy) {
			float fEntityOrigin[3], fEntityAngle[3]
			char szModelName[128]
			char szColorR[20], szColorG[20], szColorB[20], szColor[3][128], szColor2[255]
			
			GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", fEntityOrigin)
			GetEntPropVector(entProp, Prop_Data, "m_angRotation", fEntityAngle)
			GetEntPropString(entProp, Prop_Data, "m_ModelName", szModelName, sizeof(szModelName))
			DispatchKeyValue(g_iCopyTarget[plyClient], "model", szModelName)
			
			
			GetEdictClassname(g_iCopyTarget[plyClient], szClass, sizeof(szClass))
			if (StrEqual(szClass, "prop_dynamic")) {
				SetEntProp(g_iCopyTarget[plyClient], Prop_Send, "m_nSolidType", 6)
				SetEntProp(g_iCopyTarget[plyClient], Prop_Data, "m_nSolidType", 6)
			}
			
			DispatchSpawn(g_iCopyTarget[plyClient])
			TeleportEntity(g_iCopyTarget[plyClient], fEntityOrigin, fEntityAngle, NULL_VECTOR)
			
			if (Phys_IsPhysicsObject(g_iCopyTarget[plyClient]))
				Phys_EnableMotion(g_iCopyTarget[plyClient], false)
			
			GetCmdArg(1, szColorR, sizeof(szColorR))
			GetCmdArg(2, szColorG, sizeof(szColorG))
			GetCmdArg(3, szColorB, sizeof(szColorB))
			
			DispatchKeyValue(g_iCopyTarget[plyClient], "rendermode", "5")
			DispatchKeyValue(g_iCopyTarget[plyClient], "renderamt", "150")
			DispatchKeyValue(g_iCopyTarget[plyClient], "renderfx", "4")
			
			if (args > 1) {
				szColor[0] = szColorR
				szColor[1] = szColorG
				szColor[2] = szColorB
				ImplodeStrings(szColor, 3, " ", szColor2, 255)
				DispatchKeyValue(g_iCopyTarget[plyClient], "rendercolor", szColor2)
			} else {
				DispatchKeyValue(g_iCopyTarget[plyClient], "rendercolor", "50 255 255")
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
		RemoveEdict(g_iCopyTarget[plyClient])
		return Plugin_Handled
	}
	// return Plugin_Handled
}

public Action Command_Paste(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled
		
	g_bCopyIsRunning[Client] = false
	return Plugin_Handled
}

public Action Timer_CopyBeam(Handle Timer, any Client) {
	if(IsValidEntity(g_iCopyTarget[Client]) && LM_IsClientValid(Client, Client)) {
		float fOriginPlayer[3], fOriginEntity[3]
		
		GetClientAbsOrigin(Client, g_fCopyPlayerOrigin[Client])
		GetClientAbsOrigin(Client, fOriginPlayer)
		
		GetEntPropVector(g_iCopyTarget[Client], Prop_Data, "m_vecOrigin", fOriginEntity)
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
	if(IsValidEntity(g_iCopyTarget[Client]) && LM_IsClientValid(Client, Client)) {
		float fOriginEntity[3]
		
		GetEntPropVector(g_iCopyTarget[Client], Prop_Data, "m_vecOrigin", fOriginEntity)
		
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

public Action Timer_CopyMain(Handle Timer, any Client) {
	if(IsValidEntity(g_iCopyTarget[Client]) && LM_IsClientValid(Client, Client)) {
		float fOriginEntity[3], fOriginPlayer[3]
		
		GetEntPropVector(g_iCopyTarget[Client], Prop_Data, "m_vecOrigin", fOriginEntity)
		GetClientAbsOrigin(Client, fOriginPlayer)
		
		fOriginEntity[0] += fOriginPlayer[0] - g_fCopyPlayerOrigin[Client][0]
		fOriginEntity[1] += fOriginPlayer[1] - g_fCopyPlayerOrigin[Client][1]
		fOriginEntity[2] += fOriginPlayer[2] - g_fCopyPlayerOrigin[Client][2]
		
		if(Phys_IsPhysicsObject(g_iCopyTarget[Client])) {
			Phys_EnableMotion(g_iCopyTarget[Client], false)
			Phys_Sleep(g_iCopyTarget[Client])
		}
		SetEntityMoveType(g_iCopyTarget[Client], MOVETYPE_NONE)
		TeleportEntity(g_iCopyTarget[Client], fOriginEntity, NULL_VECTOR, NULL_VECTOR)

		if (g_bCopyIsRunning[Client])
			CreateTimer(0.001, Timer_CopyMain, Client)
		else {
			if(Phys_IsPhysicsObject(g_iCopyTarget[Client])) {
				Phys_EnableMotion(g_iCopyTarget[Client], true)
				Phys_Sleep(g_iCopyTarget[Client])
			}
			SetEntityMoveType(g_iCopyTarget[Client], MOVETYPE_VPHYSICS)
			
			DispatchKeyValue(g_iCopyTarget[Client], "rendermode", "5")
			DispatchKeyValue(g_iCopyTarget[Client], "renderamt", "255")
			DispatchKeyValue(g_iCopyTarget[Client], "renderfx", "0")
			DispatchKeyValue(g_iCopyTarget[Client], "rendercolor", "255 255 255")
		}
	}
	return Plugin_Handled
}
