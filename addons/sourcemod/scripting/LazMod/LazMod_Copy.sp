

#include <sourcemod>
#include <sdktools>

#include <vphysics>

#include <lazmod>


ConVar g_hCvarStackMax
int g_iCvarStackMax

bool g_bExtendIsRunning[MAXPLAYERS]
int g_entExtendTarget[MAXPLAYERS]

bool g_bStackIsRunning[MAXPLAYERS] = { false,...}
int g_iCurrent[MAXPLAYERS] = { 0,...}

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

	g_hCvarStackMax	= CreateConVar("lm_stack_max", "10", "How many props can a player stack at one time.", FCVAR_NOTIFY, true, 0.0, true, 100.0)
	g_hCvarStackMax.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarStackMax)

	PrintToServer( "LazMod Copy loaded!" )
}

Hook_CvarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	CvarChanged(convar)
}
void CvarChanged(Handle convar) {
	if (convar == g_hCvarStackMax)
		g_iCvarStackMax = g_hCvarStackMax.IntValue
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
	
	if (!LM_IsEntOwner(plyClient, entProp))
		return Plugin_Handled
	
	char szModel[128], szClass[33]
	int iUnFreeze = 0, iAmount
	float vMove[3]
	
	iAmount = GetCmdArgInt(1)
	vMove[0] = GetCmdArgFloat(2)
	vMove[1] = GetCmdArgFloat(3)
	vMove[2] = GetCmdArgFloat(4)
	iUnFreeze = GetCmdArgInt(5)
	
	
	if (!LM_IsClientAdmin(plyClient) && iAmount > g_iCvarStackMax) {
		LM_PrintToChat(plyClient, "Max stack limit is %d", g_iCvarStackMax)
		return Plugin_Handled
	}
	
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	if ((StrEqual(szClass, "prop_ragdoll") || StrEqual(szModel, "models/props_c17/oildrum001_explosive.mdl")) && !LM_IsClientAdmin(plyClient)) {
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
	LM_GetEntOrigin(entProp, vEntityOrigin)
	LM_GetEntAngles(entProp, vEntityAngle)
	LM_GetEntModel(entProp, szModel, sizeof(szModel))
	
	if (g_iCurrent[Client] < iAmount) {
		bool IsDoll = false
		new iStackEntity = CreateEntityByName(szClass)
		
		if (StrEqual(szClass, "prop_ragdoll"))
			IsDoll = true
			
		if (LM_SetEntOwner(iStackEntity, Client, IsDoll)) {			
			DispatchKeyValue(iStackEntity, "model", szModel)
			if (StrEqual(szClass, "prop_dynamic"))
				LM_SetEntSolidType(iStackEntity, SOLID_VPHYSICS)
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
	if (LM_IsEntOwner(plyClient, entProp1)) {
		int entProp3
		if (StrContains(szClass, "prop_dynamic") >= 0) {
			entProp3 = CreateEntityByName("prop_dynamic_override")
			LM_SetEntSolidType(entProp3, SOLID_VPHYSICS)
		} else
			entProp3 = CreateEntityByName(szClass)
			
		if (LM_SetEntOwner(entProp3, plyClient)) {
			if (!g_bExtendIsRunning[plyClient]) {
				g_entExtendTarget[plyClient] = entProp1
				g_bExtendIsRunning[plyClient] = true
				LM_PrintToChat(plyClient, "Extend #1 set, use !ex again on #2 prop.")
			} else {
				char szModel[255]
				float vProp1Origin[3], vProp1Angles[3], vProp2Origin[3], vProp3Origin[3]
				
				LM_GetEntOrigin(g_entExtendTarget[plyClient], vProp1Origin)
				LM_GetEntAngles(g_entExtendTarget[plyClient], vProp1Angles)
				LM_GetEntModel(g_entExtendTarget[plyClient], szModel, sizeof(szModel))
				LM_GetEntOrigin(entProp1, vProp2Origin)
				
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


