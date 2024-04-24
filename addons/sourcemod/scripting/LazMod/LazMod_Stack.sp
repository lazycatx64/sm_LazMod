#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <vphysics>

new bool:g_bClientLang[MAXPLAYERS];
new Handle:g_hCookieClientLang;

new bool:g_bIsRunning[MAXPLAYERS] = { false,...};
new g_iCurrent[MAXPLAYERS] = { 0,...};

public Plugin:myinfo = {
	name = "BuildMod - Stack",
	author = "LaZycAt, hjkwe654",
	description = "Stack props to larger build.",
	version = LAZMOD_VER,
	url = ""
};

public OnPluginStart() {
	RegAdminCmd("sm_stack", Command_Stack, 0, "Stack a prop.");
	RegAdminCmd("sm_st", Command_Stack, 0, "Stack a prop.");
	g_hCookieClientLang = RegClientCookie("cookie_BuildModClientLang", "BuildMod Client Language.", CookieAccess_Private);
}

public Action:OnClientCommand(Client, args) {
	if (Client > 0) {
		if (LM_IsClientValid(Client, Client)) {
			new String:Lang[8];
			GetClientCookie(Client, g_hCookieClientLang, Lang, sizeof(Lang));
			if (StrEqual(Lang, "1"))
				g_bClientLang[Client] = true;
			else
				g_bClientLang[Client] = false;
		}
	}
}

public Action:Command_Stack(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (g_bIsRunning[Client]) {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "你正在多重複製其他物件!");
		else
			LM_PrintToChat(Client, "You are already stacking something!");
		return Plugin_Handled;
	}	
	
	if (args < 1) {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "用法: !stack <數量> <X> <Y> <Z> <自動固定>");
		else
			LM_PrintToChat(Client, "Usage: !stack <amount> <X> <Y> <Z> <freeze>");
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (!LM_IsEntityOwner(Client, iEntity))
		return Plugin_Handled;
	
	new String:szAmount[5], String:szMoveX[8], String:szMoveY[8], String:szMoveZ[8], String:szFreeze[5], String:szModel[128], String:szClass[33];
	new iFreeze = 0, Float:vMove[3];
	
	GetCmdArg(1, szAmount, sizeof(szAmount));
	GetCmdArg(2, szMoveX, sizeof(szMoveX));
	GetCmdArg(3, szMoveY, sizeof(szMoveY));
	GetCmdArg(4, szMoveZ, sizeof(szMoveZ));
	GetCmdArg(5, szFreeze, sizeof(szFreeze));
	
	vMove[0] = StringToFloat(szMoveX);
	vMove[1] = StringToFloat(szMoveY);
	vMove[2] = StringToFloat(szMoveZ);
	
	if (!StrEqual(szFreeze, ""))
		iFreeze = 1;
	
	new iAmount = StringToInt(szAmount);
	if (!LM_IsAdmin(Client) && iAmount > 5) {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "Stack數量上限是 5");
		else
			LM_PrintToChat(Client, "Max stack amount is 5");
		return Plugin_Handled;
	}
	
	GetEdictClassname(iEntity, szClass, sizeof(szClass));
	if ((StrEqual(szClass, "prop_ragdoll") || StrEqual(szModel, "models/props_c17/oildrum001_explosive.mdl")) && !LM_IsAdmin(Client, true)) {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "你需要 \x04二級建造權限\x01 才能Stack此物件!");
		else
			LM_PrintToChat(Client, "You need \x04L2 Build Access\x01 to stack this prop!");
		return Plugin_Handled;
	}
	
	new Handle:hDataPack;
	CreateDataTimer(0.001, Timer_Stack, hDataPack);
	WritePackCell(hDataPack, Client);
	WritePackCell(hDataPack, iEntity);
	WritePackCell(hDataPack, iAmount);
	WritePackFloat(hDataPack, vMove[0]);
	WritePackFloat(hDataPack, vMove[1]);
	WritePackFloat(hDataPack, vMove[2]);
	WritePackCell(hDataPack, iFreeze);
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_stack", szArgs);
	return Plugin_Handled;
}

public Action:Timer_Stack(Handle:Timer, Handle:hDataPack) {
	new Float:vMove[3], Float:vNext[3];
	ResetPack(hDataPack);
	new Client = ReadPackCell(hDataPack);
	new iEntity = ReadPackCell(hDataPack);
	new iAmount = ReadPackCell(hDataPack);
	vMove[0] = ReadPackFloat(hDataPack);
	vMove[1] = ReadPackFloat(hDataPack);
	vMove[2] = ReadPackFloat(hDataPack);
	new iFreeze = ReadPackCell(hDataPack);
	if (g_iCurrent[Client] != 0) {
		vNext[0] = ReadPackFloat(hDataPack);
		vNext[1] = ReadPackFloat(hDataPack);
		vNext[2] = ReadPackFloat(hDataPack);
	}
	
	g_bIsRunning[Client] = true;
	if (!LM_IsClientValid(Client, Client) || !IsValidEdict(iEntity)) {
		g_bIsRunning[Client] = false;
		g_iCurrent[Client] = 0;
		return;
	}
	
	new String:szClass[32], String:szModel[256], Float:vEntityOrigin[3], Float:vEntityAngle[3];
	GetEdictClassname(iEntity, szClass, sizeof(szClass));
	GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", vEntityOrigin);
	GetEntPropVector(iEntity, Prop_Data, "m_angRotation", vEntityAngle);
	GetEntPropString(iEntity, Prop_Data, "m_ModelName", szModel, sizeof(szModel));
	
	if (g_iCurrent[Client] < iAmount) {
		new bool:IsDoll = false;
		new iStackEntity = CreateEntityByName(szClass);
		
		if (StrEqual(szClass, "prop_ragdoll"))
			IsDoll = true;
			
		if (LM_SetEntityOwner(iStackEntity, Client, IsDoll)) {			
			DispatchKeyValue(iStackEntity, "model", szModel);
			if (StrEqual(szClass, "prop_dynamic"))
				SetEntProp(iStackEntity, Prop_Send, "m_nSolidType", 6);
			DispatchSpawn(iStackEntity);
			
			AddVectors(vMove, vNext, vNext);
			AddVectors(vNext, vEntityOrigin, vEntityOrigin);
			
			TeleportEntity(iStackEntity, vEntityOrigin, vEntityAngle, NULL_VECTOR);
			
			if (iFreeze == 1) {
				if(Phys_IsPhysicsObject(iEntity))
					Phys_EnableMotion(iStackEntity, false);
			}
			g_iCurrent[Client]++;
			new Handle:hNewPack;
			CreateDataTimer(0.005, Timer_Stack, hNewPack);
			WritePackCell(hNewPack, Client);
			WritePackCell(hNewPack, iEntity);
			WritePackCell(hNewPack, iAmount);
			WritePackFloat(hNewPack, vMove[0]);
			WritePackFloat(hNewPack, vMove[1]);
			WritePackFloat(hNewPack, vMove[2]);
			WritePackCell(hNewPack, iFreeze);
			WritePackFloat(hNewPack, vNext[0]);
			WritePackFloat(hNewPack, vNext[1]);
			WritePackFloat(hNewPack, vNext[2]);
			return;
		} else {
			g_bIsRunning[Client] = false;
			g_iCurrent[Client] = 0;
			RemoveEdict(iStackEntity);
			return;
		}
	} else {
		g_bIsRunning[Client] = false;
		g_iCurrent[Client] = 0;
	}
	return;
}


