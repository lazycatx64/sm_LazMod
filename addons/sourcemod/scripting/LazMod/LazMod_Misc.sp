
#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>

// Global definions
new g_LBeam;
new g_Halo;
new g_Beam;

new bool:g_bClientLang[MAXPLAYERS];
new Handle:g_hCookieClientLang;

new Handle:g_hHostName = INVALID_HANDLE;
new String:g_szHostName[128];

new String:g_szMissileModel[MAXPLAYERS][128];
new g_iMissileTarget[MAXPLAYERS];
new Float:g_fAlignOrigin[MAXPLAYERS][3];
new bool:g_bExtendIsRunning[MAXPLAYERS];
new g_iExtendTarget[MAXPLAYERS];
new String:g_szCenterIsRunning[MAXPLAYERS][32];
new g_iCenterMain[MAXPLAYERS];
new g_iCenterFirst[MAXPLAYERS];

new ColorWhite[4] = { 255,255,255,255};
new ColorRed[4] = { 255,50,50,255};
new ColorBlue[4] = { 50,50,255,255};

public Plugin:myinfo = {
	name = "BuildMod - Misc",
	author = "LaZycAt, hjkwe654",
	description = "Various uncategorized commands.",
	version = LAZMOD_VER,
	url = ""
};

public OnPluginStart() {
	
	// Player Commands
	{
		RegAdminCmd("sm_ginertia", Command_GetInertia, 0, "Get an entity inertia.");
		RegAdminCmd("sm_gi", Command_GetInertia, 0, "Get an entity inertia.");
		RegAdminCmd("sm_render", Command_Render, 0, "Render an entity.");
		RegAdminCmd("sm_rd", Command_Render, 0, "Render an entity.");
		RegAdminCmd("sm_rotate", Command_Rotate, 0, "Rotate an entity.");
		RegAdminCmd("sm_r", Command_Rotate, 0, "Rotate an entity.");
		RegAdminCmd("sm_setview", Command_Setview, 0, "Turn your view into a prop.");
		RegAdminCmd("sm_sv", Command_Setview, 0, "Turn your view into a prop.");
		RegAdminCmd("sm_resetview", Command_Resetview, 0, "Quit the setview.");
		RegAdminCmd("sm_rsv", Command_Resetview, 0, "Quit the setview.");
		RegAdminCmd("sm_color", Command_Color, 0, "Color a prop.");
		RegAdminCmd("sm_cl", Command_Color, 0, "Color a prop.");
		RegAdminCmd("sm_lang", Command_ClientLang, 0, "Change Language");
	}

	// Level 2 Commands
	{
		RegAdminCmd("sm_push", Command_Push, ADMFLAG_CUSTOM1, "Push an entity.");
		RegAdminCmd("sm_setent", Command_SetEnt, ADMFLAG_CUSTOM1, "Set an entity as temporary.");
		RegAdminCmd("sm_se", Command_SetEnt, ADMFLAG_CUSTOM1, "Set an entity as temporary.");
		RegAdminCmd("sm_rope", Command_Rope, ADMFLAG_CUSTOM1, "Set a rope between two props.");	
		RegAdminCmd("sm_rp", Command_Rope, ADMFLAG_CUSTOM1, "Set a rope between two props.");
		RegAdminCmd("sm_sinertia", Command_SetInertia, ADMFLAG_CUSTOM1, "Set an entity inertia.");
		RegAdminCmd("sm_si", Command_SetInertia, ADMFLAG_CUSTOM1, "Set an entity inertia.");
		RegAdminCmd("sm_airboat", Command_Airboat, ADMFLAG_CUSTOM1, "Spawn an airboat.");
		RegAdminCmd("sm_ab", Command_Airboat, ADMFLAG_CUSTOM1, "Spawn an airboat.");
		RegAdminCmd("sm_nobreak", Command_NoBreakProp, ADMFLAG_CUSTOM1, "Set a prop wont break.");
		RegAdminCmd("sm_nb", Command_NoBreakProp, ADMFLAG_CUSTOM1, "Set a prop wont break.");
		RegAdminCmd("sm_unnobreak", Command_UnNoBreakProp, ADMFLAG_CUSTOM1, "Undo nobreak.");
		RegAdminCmd("sm_unb", Command_UnNoBreakProp, ADMFLAG_CUSTOM1, "Undo nobreak.");
		RegAdminCmd("sm_accuraterotate", Command_AccurateRotate, ADMFLAG_CUSTOM1, "Accurate rotate a prop.");
		RegAdminCmd("sm_ar", Command_AccurateRotate, ADMFLAG_CUSTOM1, "Accurate rotate a prop.");
		RegAdminCmd("sm_thruster", Command_Thruster, ADMFLAG_CUSTOM1, "Set a thruster on prop.");
		RegAdminCmd("sm_th", Command_Thruster, ADMFLAG_CUSTOM1, "Set a thruster on prop.");
		RegAdminCmd("sm_delthruster", Command_DelThruster, ADMFLAG_CUSTOM1, "Delete thrusters.");
		RegAdminCmd("sm_dth", Command_DelThruster, ADMFLAG_CUSTOM1, "Delete thrusters.");
		RegAdminCmd("+th", Command_EnableThruster, ADMFLAG_CUSTOM1, "Enable thruster.");
		RegAdminCmd("-th", Command_DisableThruster, ADMFLAG_CUSTOM1, "Disable thruster.");
		RegAdminCmd("+rth", Command_rEnableThruster, ADMFLAG_CUSTOM1, "Enable rThruster.");
		RegAdminCmd("-rth", Command_rDisableThruster, ADMFLAG_CUSTOM1, "Disable rThruster.");
		RegAdminCmd("sm_align", Command_Align, ADMFLAG_CUSTOM1, "Aligning props.");
		RegAdminCmd("sm_al", Command_Align, ADMFLAG_CUSTOM1, "Aligning props.");
		RegAdminCmd("sm_move", Command_Move, ADMFLAG_CUSTOM1, "Move props.");
		RegAdminCmd("sm_m", Command_Move, ADMFLAG_CUSTOM1, "Move props.");
		RegAdminCmd("sm_extend", Command_Extend, ADMFLAG_CUSTOM1, "Extend prop.");
		RegAdminCmd("sm_ex", Command_Extend, ADMFLAG_CUSTOM1, "Extend prop.");
		RegAdminCmd("sm_center", Command_Center, ADMFLAG_CUSTOM1, "Moves a prop to the exact middle of the other two, .");
		RegAdminCmd("sm_skin", Command_Skin, ADMFLAG_CUSTOM1, "Color a prop.");
		RegAdminCmd("sm_ld", Command_LightDynamic, ADMFLAG_CUSTOM1, "Dynamic Light.");
		RegAdminCmd("sm_lightd", Command_LightDynamic, ADMFLAG_CUSTOM1, "Dynamic Light.");
		//RegAdminCmd("sm_setgravity", Command_SetGravity, ADMFLAG_CUSTOM1, "Change Target Gravity.");
		//RegAdminCmd("sm_sg", Command_SetGravity, ADMFLAG_CUSTOM1, "Change Target Gravity.");
		//RegAdminCmd("sm_getgravity", Command_GetGravity, ADMFLAG_CUSTOM1, "Get Target Gravity.");
		//RegAdminCmd("sm_gg", Command_GetGravity, ADMFLAG_CUSTOM1, "Get Target Gravity.");
	}
	
	// Admin Commands
	{
		RegAdminCmd("sm_ball", Command_Ball, ADMFLAG_GENERIC, "Spawn a energy ball.");
		RegAdminCmd("sm_output", Command_OutPut, ADMFLAG_GENERIC, "Add output on entity.");
		RegAdminCmd("sm_keyvalue", Command_KeyValue, ADMFLAG_GENERIC, "Set an entity keyvalues.");
		RegAdminCmd("sm_input", Command_InPut, ADMFLAG_GENERIC, "Fires an input on the entity.");
		
		RegAdminCmd("sm_fda", Command_AdminForceDeleteAll, ADMFLAG_BAN, "Delall a player's props.");
		RegAdminCmd("sm_setowner", Command_AdminSetOwner, ADMFLAG_BAN, "WTF.");
		RegAdminCmd("sm_team", Command_AdminTeam, ADMFLAG_GENERIC, "Force a player join a team.");
		RegAdminCmd("sm_expray", Command_AdminExplosionBeam, ADMFLAG_BAN, "To blow you up.");
		RegAdminCmd("sm_hurt", Command_AdminHurt, ADMFLAG_BAN, "To hurt you.");
		RegAdminCmd("sm_droct", Command_AdminDrOct, ADMFLAG_BAN, "To hurt you.");
		RegAdminCmd("sm_shoot", Command_AdminShoot, ADMFLAG_BAN, "WTF.");
		RegAdminCmd("sm_mis", Command_AdminMissile, ADMFLAG_CONVARS, "To fire rockets.");
		RegAdminCmd("sm_misset", Command_AdminMissileSet, ADMFLAG_CONVARS, "To set rockets model.");
		RegAdminCmd("sm_misla", Command_AdminMissileLast, ADMFLAG_CONVARS, "Attack last target.");
		RegAdminCmd("sm_gb", Command_AdminBottle, ADMFLAG_CONVARS, "Create bottles.");
		//RegAdminCmd("sm_strider", Command_RActionStrider, ADMFLAG_CONVARS, "Range action strider style.");
		//RegAdminCmd("sm_square", Command_RActionSquare, ADMFLAG_CONVARS, "Range action square style.");
		
		RegAdminCmd("sm_atest", Command_Test, ADMFLAG_ROOT, "test.");
	}
	g_hHostName = FindConVar("hostname");
	GetConVarString(g_hHostName, g_szHostName, sizeof(g_szHostName));
	RegConsoleCmd("sm_delay", Command_Delay);
	RegConsoleCmd("kill", Command_kill, "");
	g_hCookieClientLang = RegClientCookie("cookie_BuildModClientLang", "BuildMod Client Language.", CookieAccess_Private);
}

public OnMapStart() {
	g_LBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_Halo = PrecacheModel("materials/sprites/halo01.vmt");
	PrecacheSound("npc/sniper/echo1.wav", true);
	PrecacheSound("npc/sniper/sniper1.wav", true);
	PrecacheSound("buttons/button15.wav", true);
	PrecacheSound("ion/attack.wav", true);
	
	g_Beam = PrecacheModel("materials/sprites/laser.vmt");
	PrecacheSound("dr_oct.wav", true);
	PrecacheSound("npc/strider/charging.wav", true);
	PrecacheSound("npc/strider/fire.wav", true);
	MapPreset();
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

public Action:Command_ClientLang(Client, args) {
	new String:Lang[8];
	GetCmdArg(1, Lang, sizeof(Lang));
	if (StrEqual(Lang, "accept"))
		return Plugin_Handled;
	if (StrEqual(Lang, "1")) {
		g_bClientLang[Client] = true;
		SetClientCookie(Client, g_hCookieClientLang, "1");
		LM_PrintToChat(Client, "Language set to 繁體中文");
		LM_PrintToChat(Client, "註: 有的東西沒辦法翻譯成中文所以維持英文");
		FakeClientCommand(Client, "sm_lang accept");
		return Plugin_Handled;
	}
	if (StrEqual(Lang, "0")) {
		g_bClientLang[Client] = false;
		SetClientCookie(Client, g_hCookieClientLang, "");
		LM_PrintToChat(Client, "Language set to English");
		FakeClientCommand(Client, "sm_lang accept");
		return Plugin_Handled;
	}
	LM_PrintToChat(Client, "Usage: !lang <choose>");
	LM_PrintToChat(Client, "!lang 0  = English (Default)");
	LM_PrintToChat(Client, "!lang 1  = 繁體中文");
	return Plugin_Handled;
}

public Action:Command_Airboat(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	FakeClientCommand(Client, "e_spawnboat");
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_airboat", szArgs);
	return Plugin_Handled;
}

public Action:Command_Ball(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	FakeClientCommand(Client, "e_spawnball");
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_ball", szArgs);
	return Plugin_Handled;
}

public Action:Command_InPut(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !input <input> <value>");
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (!LM_IsAdmin(Client)) {
		if (GetEntityFlags(iEntity) & (FL_CLIENT | FL_FAKECLIENT))
			return Plugin_Handled;
	}
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		new String:szInput[33], String:szValues[33];
		GetCmdArg(1, szInput, sizeof(szInput));
		GetCmdArg(2, szValues, sizeof(szValues));
		
		SetVariantString(szValues);
		AcceptEntityInput(iEntity, szInput, iEntity, Client, 0);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_input", szArgs);
	return Plugin_Handled;
}

public Action:Command_GetInertia(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	FakeClientCommand(Client, "e_getinertia");
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_getinertia", szArgs);
	return Plugin_Handled;
}

public Action:Command_KeyValue(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 2) {
		LM_PrintToChat(Client, "Usage: !keyvalue <keyvalue> <value>");
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		
		new String:szKeys[33], String:szValues[33];
		GetCmdArg(1, szKeys, sizeof(szKeys));
		GetCmdArg(2, szValues, sizeof(szValues));
		
		DispatchKeyValue(iEntity, szKeys, szValues);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_keyvalue", szArgs);
	return Plugin_Handled;
}

public Action:Command_SetEnt(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "選擇了第一個物件, 使用!rp選擇第二個物件完成Rope.");
		else
			LM_PrintToChat(Client, "First prop selected, use !rp to select second prop to finish.");
		FakeClientCommand(Client, "e_setent");
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_setent", szArgs);
	return Plugin_Handled;
}

public Action:Command_SetInertia(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "用法: !sinertia/!si <x> <y> <z>");
		else
			LM_PrintToChat(Client, "Usage: !sinertia/!si <x> <y> <z>");
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		new String:szX[16], String:szY[16], String:szZ[16];
		GetCmdArg(1, szX, sizeof(szX));
		GetCmdArg(2, szY, sizeof(szY));
		GetCmdArg(3, szZ, sizeof(szZ));
		
		FakeClientCommand(Client, "e_setinertia %s %s %s", szX, szY, szZ);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_setinertia", szArgs);
	return Plugin_Handled;
}

public Action:Command_OutPut(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 2) {
		LM_PrintToChat(Client, "Usage: !output <output> <value>");
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		new String:szKeys[33], String:szValues[33];
		GetCmdArg(1, szKeys, sizeof(szKeys));
		GetCmdArg(2, szValues, sizeof(szValues));
		
		DispatchKeyValue(iEntity, szKeys, szValues);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_output", szArgs);
	return Plugin_Handled;
}

public Action:Command_Push(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: !push <推力>");
			LM_PrintToChat(Client, "例: !push 1000");
		} else {
			LM_PrintToChat(Client, "Usage: !push <force>");
			LM_PrintToChat(Client, "Ex: !push 1000");
		}
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		new String:szForce[16];
		GetCmdArg(1, szForce, sizeof(szForce));
		
		FakeClientCommand(Client, "e_push %s", szForce);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_push", szArgs);
	return Plugin_Handled;
}

public Action:Command_Render(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 5) {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: !render/!rd <透明度> <特效> <紅> <綠> <藍>");
			LM_PrintToChat(Client, "例. 閃爍綠: !render 150 4 15 255 0");
		} else {
			LM_PrintToChat(Client, "Usage: !render/!rd <fx amount> <fx> <R> <G> <B>");
			LM_PrintToChat(Client, "Ex. Flashing Green: !render 150 4 15 255 0");
		}
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		new String:szRenderAlpha[20], String:szRenderFX[20], String:szColorRGB[20][3], String:szColors[128];
		GetCmdArg(1, szRenderAlpha, sizeof(szRenderAlpha));
		GetCmdArg(2, szRenderFX, sizeof(szRenderFX));
		GetCmdArg(3, szColorRGB[0], sizeof(szColorRGB));
		GetCmdArg(4, szColorRGB[1], sizeof(szColorRGB));
		GetCmdArg(5, szColorRGB[2], sizeof(szColorRGB));
		
		Format(szColors, sizeof(szColors), "%s %s %s", szColorRGB[0], szColorRGB[1], szColorRGB[2]);
		if (StringToInt(szRenderAlpha) < 1)
			szRenderAlpha = "1";
		DispatchKeyValue(iEntity, "rendermode", "5");
		DispatchKeyValue(iEntity, "renderamt", szRenderAlpha);
		DispatchKeyValue(iEntity, "renderfx", szRenderFX);
		DispatchKeyValue(iEntity, "rendercolor", szColors);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_render", szArgs);
	return Plugin_Handled;
}

public Action:Command_Color(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 3) {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: !color/!cl <紅> <綠> <藍>");
			LM_PrintToChat(Client, "例: 綠色: !color 0 255 0");
		} else {
			LM_PrintToChat(Client, "Usage: !color/!cl <R> <G> <B>");
			LM_PrintToChat(Client, "Ex: Green: !color 0 255 0");
		}
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		new String:szColorRGB[20][3], String:szColors[33];
		GetCmdArg(1, szColorRGB[0], sizeof(szColorRGB));
		GetCmdArg(2, szColorRGB[1], sizeof(szColorRGB));
		GetCmdArg(3, szColorRGB[2], sizeof(szColorRGB));
		
		Format(szColors, sizeof(szColors), "%s %s %s", szColorRGB[0], szColorRGB[1], szColorRGB[2]);
		DispatchKeyValue(iEntity, "rendermode", "5");
		DispatchKeyValue(iEntity, "renderamt", "255");
		DispatchKeyValue(iEntity, "renderfx", "0");
		DispatchKeyValue(iEntity, "rendercolor", szColors);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_color", szArgs);
	return Plugin_Handled;
}

public Action:Command_Rotate(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: !rotate/!r <x> <y> <z>");
			LM_PrintToChat(Client, "例: !rotate 0 90 0");
		} else {
			LM_PrintToChat(Client, "Usage: !rotate/!r <x> <y> <z>");
			LM_PrintToChat(Client, "Ex: !rotate 0 90 0");
		}
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		new String:szAngleX[8], String:szAngleY[8], String:szAngleZ[8];
		new Float:fEntityOrigin[3], Float:fEntityAngle[3];
		GetCmdArg(1, szAngleX, sizeof(szAngleX));
		GetCmdArg(2, szAngleY, sizeof(szAngleY));
		GetCmdArg(3, szAngleZ, sizeof(szAngleZ));
		
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEntityOrigin);
		GetEntPropVector(iEntity, Prop_Data, "m_angRotation", fEntityAngle);
		fEntityAngle[0] += StringToFloat(szAngleX);
		fEntityAngle[1] += StringToFloat(szAngleY);
		fEntityAngle[2] += StringToFloat(szAngleZ);
		
		TeleportEntity(iEntity, fEntityOrigin, fEntityAngle, NULL_VECTOR);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_rotate", szArgs);
	return Plugin_Handled;
}

public Action:Command_Setview(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity))
		FakeClientCommand(Client, "e_setview");
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_setview", szArgs);
	return Plugin_Handled;
}

public Action:Command_Resetview(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled;
	
	FakeClientCommand(Client, "e_resetview");
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_resetview", szArgs);
	return Plugin_Handled;
}

public Action:Command_Rope(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity))
		FakeClientCommand(Client, "e_rope");
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_rope", szArgs);
	return Plugin_Handled;
}

public Action:Command_NoBreakProp(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		SetVariantString("999999999");
		AcceptEntityInput(iEntity, "sethealth", -1);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_nobreak", szArgs);
	return Plugin_Handled;
}

public Action:Command_UnNoBreakProp(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		SetVariantString("50");
		AcceptEntityInput(iEntity, "sethealth", -1);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_unnobreak", szArgs);
	return Plugin_Handled;
}

public Action:Command_AccurateRotate(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "用法: !ar <x> <y> <z>");
		else
			LM_PrintToChat(Client, "Usage: !ar <x> <y> <z>");
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		new String:szRotateX[33], String:szRotateY[33], String:szRotateZ[33];
		new Float:fEntityOrigin[3], Float:fEntityAngle[3];
		GetCmdArg(1, szRotateX, sizeof(szRotateX));
		GetCmdArg(2, szRotateY, sizeof(szRotateY));
		GetCmdArg(3, szRotateZ, sizeof(szRotateZ));
		
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEntityOrigin);
		fEntityAngle[0] = StringToFloat(szRotateX);
		fEntityAngle[1] = StringToFloat(szRotateY);
		fEntityAngle[2] = StringToFloat(szRotateZ);
		
		TeleportEntity(iEntity, fEntityOrigin, fEntityAngle, NULL_VECTOR);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_accuraterotate", szArgs);
	return Plugin_Handled;
}

public Action:Command_Thruster(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 2) {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: !thruster/!th <群組> <推力>");
			LM_PrintToChat(Client, "例: !thruster aaa 1000");
		} else {
			LM_PrintToChat(Client, "Usage: !thruster/!th <group> <force>");
			LM_PrintToChat(Client, "Ex: !thruster aaa 1000");
		}
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		new String:szGroup[16], String:szForce[12];
		GetCmdArg(1, szGroup, sizeof(szGroup));
		GetCmdArg(2, szForce, sizeof(szForce));
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "設置了一個推進器, 群組: %s, 推力: %s", szGroup, szForce);
		else
			LM_PrintToChat(Client, "Placed a thruster, Group: %s, Force: %s", szGroup, szForce);
		FakeClientCommand(Client, "e_thruster \"%s\" %s", szGroup, szForce);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_thruster", szArgs);
	return Plugin_Handled;
}

public Action:Command_DelThruster(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: !delthruster/!dth <群組>");
			LM_PrintToChat(Client, "例: !dth aaa");
		} else {
			LM_PrintToChat(Client, "Usage: !delthruster/!dth <group>");
			LM_PrintToChat(Client, "Ex: !dth aaa");
		}
		return Plugin_Handled;
	}
	
	new String:szGroup[16];
	GetCmdArg(1, szGroup, sizeof(szGroup));
	FakeClientCommand(Client, "e_delthruster_group \"%s\"", szGroup);
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_delthruster", szArgs);
	return Plugin_Handled;
}

public Action:Command_EnableThruster(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: +th <群組>");
			LM_PrintToChat(Client, "例: +th aaa");
		} else {
			LM_PrintToChat(Client, "Usage: +th <group>");
			LM_PrintToChat(Client, "Ex: +th aaa");
		}
		return Plugin_Handled;
	}
	
	new String:szGroup[4];
	GetCmdArg(1, szGroup, sizeof(szGroup));
	FakeClientCommand(Client, "+thruster \"%s\"", szGroup);
	
	return Plugin_Handled;
}

public Action:Command_DisableThruster(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled;
	
	new String:szGroup[4];
	GetCmdArg(1, szGroup, sizeof(szGroup));
	FakeClientCommand(Client, "-thruster \"%s\"", szGroup);
	
	return Plugin_Handled;
}

public Action:Command_rEnableThruster(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled;
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: +rth <group>");
		LM_PrintToChat(Client, "Ex: +rth aaa");
		return Plugin_Handled;
	}
	
	new String:group[4];
	GetCmdArg(1, group, sizeof(group));
	FakeClientCommand(Client, "+rthruster \"%s\"", group);
	
	return Plugin_Handled;
}

public Action:Command_rDisableThruster(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled;
	
	new String:group[4];
	GetCmdArg(1, group, sizeof(group));
	FakeClientCommand(Client, "-rthruster \"%s\"", group);
	
	return Plugin_Handled;
}

public Action:Command_Align(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: !align <模式>");
			LM_PrintToChat(Client, "!align set  = 選擇要當對齊基準的物件");
			LM_PrintToChat(Client, "!align x  = 將瞄準的物件與基準的X對齊");
			LM_PrintToChat(Client, "!align y  = 將瞄準的物件與基準的Y對齊");
			LM_PrintToChat(Client, "!align z  = 將瞄準的物件與基準的Z對齊");
		} else {
			LM_PrintToChat(Client, "Usage: !align <mode>");
			LM_PrintToChat(Client, "!align set = Select the prop to be alignment refer");
			LM_PrintToChat(Client, "!align x  = Align the aimed prop with X coord");
			LM_PrintToChat(Client, "!align y  = Align the aimed prop with Y coord");
			LM_PrintToChat(Client, "!align z  = Align the aimed prop with Z coord");
		}
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (!LM_IsEntityOwner(Client, iEntity))
		return Plugin_Handled;
	
	new String:szMode[5];
	new Float:fEntityAngle[3], Float:fEntityOrigin[3];
	GetCmdArg(1, szMode, sizeof(szMode));
	
	GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEntityOrigin);
	GetEntPropVector(iEntity, Prop_Data, "m_angRotation", fEntityAngle);

	if (StrEqual(szMode[0], "set") || StrEqual(szMode[0], "s")) {
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", g_fAlignOrigin[Client]);
		LM_PrintToChat(Client, "Align set.");
	} else if (StrEqual(szMode[0], "x")) {
		fEntityOrigin[0] = g_fAlignOrigin[Client][0];
		TeleportEntity(iEntity, fEntityOrigin, fEntityAngle, NULL_VECTOR);
	} else if (StrEqual(szMode[0], "y")) {
		fEntityOrigin[1] = g_fAlignOrigin[Client][1];
		TeleportEntity(iEntity, fEntityOrigin, fEntityAngle, NULL_VECTOR);
	} else if (StrEqual(szMode[0], "z")) {
		fEntityOrigin[2] = g_fAlignOrigin[Client][2];
		TeleportEntity(iEntity, fEntityOrigin, fEntityAngle, NULL_VECTOR);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_align", szArgs);
	return Plugin_Handled;
}

public Action:Command_Move(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: !move <x> <y> <z>");
			LM_PrintToChat(Client, "例 往上移50: !move 0 0 50");
		} else {
			LM_PrintToChat(Client, "Usage: !move <x> <y> <z>");
			LM_PrintToChat(Client, "Ex, move up 50: !move 0 0 50");
		}
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (LM_IsEntityOwner(Client, iEntity)) {
		new Float:fEntityOrigin[3], Float:fEntityAngle[3];	
		new String:szArgX[33], String:szArgY[33], String:szArgZ[33];
		GetCmdArg(1, szArgX, sizeof(szArgX));
		GetCmdArg(2, szArgY, sizeof(szArgY));
		GetCmdArg(3, szArgZ, sizeof(szArgZ));
		
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEntityOrigin);
		GetEntPropVector(iEntity, Prop_Data, "m_angRotation", fEntityAngle);
		
		fEntityOrigin[0] += StringToFloat(szArgX);
		fEntityOrigin[1] += StringToFloat(szArgY);
		fEntityOrigin[2] += StringToFloat(szArgZ);
		
		TeleportEntity(iEntity, fEntityOrigin, fEntityAngle, NULL_VECTOR);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_move", szArgs);
	return Plugin_Handled;
}

public Action:Command_Extend(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	new String:szClass[33];
	GetEdictClassname(iEntity, szClass, sizeof(szClass));
	if (LM_IsEntityOwner(Client, iEntity)) {
		new Obj_ThirdProp;
		if (StrContains(szClass, "prop_dynamic") >= 0) {
			Obj_ThirdProp = CreateEntityByName("prop_dynamic_override");
			SetEntProp(Obj_ThirdProp, Prop_Send, "m_nSolidType", 6);
			SetEntProp(Obj_ThirdProp, Prop_Data, "m_nSolidType", 6);
		} else
			Obj_ThirdProp = CreateEntityByName(szClass);
			
		if (LM_SetEntityOwner(Obj_ThirdProp, Client)) {
			if (!g_bExtendIsRunning[Client]) {
				g_iExtendTarget[Client] = iEntity;
				g_bExtendIsRunning[Client] = true;
				if (g_bClientLang[Client])
					LM_PrintToChat(Client, "選擇了第一個物件, 請繼續選下個物件.");
				else
					LM_PrintToChat(Client, "Extend #1 set, use !ex again on #2 prop.");
			} else {
				new String:szModel[255];
				new Float:fOriginProp1[3], Float:fAngle[3], Float:fOriginProp2[3], Float:fOriginProp3[3];
				
				GetEntPropVector(g_iExtendTarget[Client], Prop_Data, "m_vecOrigin", fOriginProp1);
				GetEntPropVector(g_iExtendTarget[Client], Prop_Data, "m_angRotation", fAngle);
				GetEntPropString(g_iExtendTarget[Client], Prop_Data, "m_ModelName", szModel, sizeof(szModel));
				GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOriginProp2);
				
				for (new i = 0; i < 3; i++)
					fOriginProp3[i] = (fOriginProp2[i] + fOriginProp2[i] - fOriginProp1[i]);
				
				DispatchKeyValue(Obj_ThirdProp, "model", szModel);
				DispatchSpawn(Obj_ThirdProp);
				TeleportEntity(Obj_ThirdProp, fOriginProp3, fAngle, NULL_VECTOR);
				
				if(Phys_IsPhysicsObject(Obj_ThirdProp))
					Phys_EnableMotion(Obj_ThirdProp, false);
				
				g_bExtendIsRunning[Client] = false;
				if (g_bClientLang[Client])
					LM_PrintToChat(Client, "延伸了一個物件.");
				else
					LM_PrintToChat(Client, "Extended a prop.");
			}
		} else
			RemoveEdict(Obj_ThirdProp);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_extend", szArgs);
	return Plugin_Handled;
}

public Action:Command_Center(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (!LM_IsEntityOwner(Client, iEntity))
		return Plugin_Handled;


	if (StrEqual(g_szCenterIsRunning[Client], "first")) {
		g_iCenterFirst[Client] = iEntity;
		g_szCenterIsRunning[Client] = "secend";
		// if (g_bClientLang[Client])
		// 	LM_PrintToChat(Client, "請選擇第三個物件.");
		// else
			LM_PrintToChat(Client, "Now select the third prop to finish.");
	} else if (StrEqual(g_szCenterIsRunning[Client], "secend")) {
		new Float:fAngleMain[3], Float:fOriginMain[3], Float:fOriginFirst[3], Float:fOriginSecend[3];
		
		GetEntPropVector(g_iCenterMain[Client], Prop_Data, "m_angRotation", fAngleMain);
		GetEntPropVector(g_iCenterFirst[Client], Prop_Data, "m_vecOrigin", fOriginFirst);
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOriginSecend);
		
		for (new i = 0; i < 3; i++)
			fOriginMain[i] = (fOriginFirst[i] + fOriginSecend[i]) / 2;
		
		TeleportEntity(g_iCenterMain[Client], fOriginMain, fAngleMain, NULL_VECTOR);
		g_szCenterIsRunning[Client] = "off";
	} else {
		g_iCenterMain[Client] = iEntity;
		g_szCenterIsRunning[Client] = "first";
		// if (g_bClientLang[Client])
		// 	LM_PrintToChat(Client, "請選擇第二個物件.");
		// else
			LM_PrintToChat(Client, "The prop to be moved have been selected, now select the secend prop.");
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_center", szArgs);
	return Plugin_Handled;
}

public Action:Command_Skin(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		// if (g_bClientLang[Client]) {
		// 	LM_PrintToChat(Client, "用法: !skin <編號>");
		// 	LM_PrintToChat(Client, "註: 不是每個物件都有多個 skin");
		// } else {
			LM_PrintToChat(Client, "Usage: !skin <number>");
			LM_PrintToChat(Client, "Notice: Not every model have multiple skins.");
		// }
		return Plugin_Handled;
	}
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (!LM_IsEntityOwner(Client, iEntity)) 
		return Plugin_Handled;


	new String:szSkin[33];
	GetCmdArg(1, szSkin, sizeof(szSkin));
	
	SetVariantString(szSkin);
	AcceptEntityInput(iEntity, "skin", iEntity, Client, 0);
	
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_skin", szArgs);
	return Plugin_Handled;
}

public Action:Command_LightDynamic(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "用法: !ld <範圍> <亮度> <紅> <綠> <藍>");
		else
			LM_PrintToChat(Client, "Usage: !ld <range> <brightness> <R> <G> <B>");
		return Plugin_Handled;
	}
	
	new entLightMelon = CreateEntityByName("prop_physics_multiplayer");
	if (LM_SetEntityOwner(entLightMelon, Client)) {
		new String:szRange[33], String:szBrightness[33], String:szColorR[33], String:szColorG[33], String:szColorB[33], String:szColor[33];
		new String:szNameMelon[64];
		new Float:fAimPos[3];
		GetCmdArg(1, szRange, sizeof(szRange));
		GetCmdArg(2, szBrightness, sizeof(szBrightness));
		GetCmdArg(3, szColorR, sizeof(szColorR));
		GetCmdArg(4, szColorG, sizeof(szColorG));
		GetCmdArg(5, szColorB, sizeof(szColorB));
		
		LM_ClientAimPos(Client, fAimPos);
		fAimPos[2] += 50;
		
		if(!IsModelPrecached("models/props_junk/watermelon01.mdl"))
			PrecacheModel("models/props_junk/watermelon01.mdl");
		
		if (StrEqual(szBrightness, ""))
			szBrightness = "3";
		if (StringToInt(szColorR) < 100 || StrEqual(szColorR, ""))
			szColorR = "100";
		if (StringToInt(szColorG) < 100 || StrEqual(szColorG, ""))
			szColorG = "100";
		if (StringToInt(szColorB) < 100 || StrEqual(szColorB, ""))
			szColorB = "100";
		Format(szColor, sizeof(szColor), "%s %s %s", szColorR, szColorG, szColorB);
		
		DispatchKeyValue(entLightMelon, "model", "models/props_junk/watermelon01.mdl");
		DispatchKeyValue(entLightMelon, "rendermode", "5");
		DispatchKeyValue(entLightMelon, "renderamt", "150");
		DispatchKeyValue(entLightMelon, "renderfx", "15");
		DispatchKeyValue(entLightMelon, "rendercolor", szColor);
		
		new Obj_LightDynamic = CreateEntityByName("light_dynamic");
		if (StringToInt(szRange) > 1500) {
			if (g_bClientLang[Client])
				LM_PrintToChat(Client, "範圍上限是 1500!");
			else
				LM_PrintToChat(Client, "Max range is 1500!");
			return Plugin_Handled;
		}
		if (StringToInt(szBrightness) > 7) {
			if (g_bClientLang[Client])
				LM_PrintToChat(Client, "亮度上限是 7!");
			else
				LM_PrintToChat(Client, "Max brightness is 7!");
			return Plugin_Handled;
		}
		SetVariantString(szRange);
		AcceptEntityInput(Obj_LightDynamic, "distance", -1);
		SetVariantString(szBrightness);
		AcceptEntityInput(Obj_LightDynamic, "brightness", -1);
		SetVariantString("2");
		AcceptEntityInput(Obj_LightDynamic, "style", -1);
		SetVariantString(szColor);
		AcceptEntityInput(Obj_LightDynamic, "color", -1);
		
		DispatchSpawn(entLightMelon);
		TeleportEntity(entLightMelon, fAimPos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(Obj_LightDynamic);
		TeleportEntity(Obj_LightDynamic, fAimPos, NULL_VECTOR, NULL_VECTOR);
		
		Format(szNameMelon, sizeof(szNameMelon), "Obj_LightDMelon%i", GetRandomInt(1000, 5000));
		DispatchKeyValue(entLightMelon, "targetname", szNameMelon);
		SetVariantString(szNameMelon);
		AcceptEntityInput(Obj_LightDynamic, "setparent", -1);
		AcceptEntityInput(Obj_LightDynamic, "turnon", Client, Client);
	} else
		RemoveEdict(entLightMelon);
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_ld", szArgs);
	return Plugin_Handled;
}


public Action:Command_AdminTeleport(Client, args) {
	if (args < 2) {
		LM_PrintToChat(Client, "Usage: !tele <player to> <player sent>");
		LM_PrintToChat(Client, "Ex: !tele cat dog");
		return Plugin_Handled;
	}
	
	new String:to[33], String:sent[33];
	GetCmdArg(1, to, sizeof(to));
	GetCmdArg(2, sent, sizeof(sent));
	
	FakeClientCommand(Client, "admin_send \"%s\" \"%s\"", to, sent);
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_tele", szArgs);
	return Plugin_Handled;
}

public Action:Command_AdminForceDeleteAll(Client, args) {
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !fda <userid>");
		return Plugin_Handled;
	}
	
	new String:pla[33];
	GetCmdArg(1, pla, sizeof(pla));
	if (StrEqual(pla, "@all")) {
		for (new player = 1; player <= MaxClients; player++) {
			if (LM_IsClientValid(Client, player))
				FakeClientCommand(player, "sm_da");
		}
		return Plugin_Handled;
	}
	
	FakeClientCommand(Client, "sm_cexec %s sm_da", pla);
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_fda", szArgs);
	return Plugin_Handled;
}

public Action:Command_AdminSetOwner(Client, args) {
	if (!LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	if (args < 1) {
		LM_PrintToChat(Client, "Usage: !setowner <Player>");
		return Plugin_Handled;
	}
	
	new String:szClass[32];
	new String:szTarget[64];
	GetCmdArg(1, szTarget, sizeof(szTarget));
	GetEdictClassname(iEntity, szClass, sizeof(szClass));
	
	new iOwner = LM_GetEntityOwner(iEntity);
	if (StrEqual(szTarget, "-1")) {
		LM_SetEntityOwner(iEntity, -1);
		if(StrEqual(szClass, "prop_ragdoll"))
			LM_SetLimit(iOwner, -1);
		else
			LM_SetLimit(iOwner, -1, true);
		LM_PrintToChat(Client, "SetOwner to: none");
	} else {
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
		if ((target_count = ProcessTargetString(szTarget, Client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(Client, target_count);
			return Plugin_Handled;
		}
		for (new i = 0; i < target_count; i++) {
			new target = target_list[i];
			LM_SetEntityOwner(iEntity, target);
			if(StrEqual(szClass, "prop_ragdoll")) {
				if(iOwner != -1)
					LM_SetLimit(iOwner, -1, true);
				
				LM_SetLimit(target, -1, true);
			} else {
				if(iOwner != -1)
					LM_SetLimit(iOwner, -1);
				
				LM_SetLimit(target, -1);
			}
			LM_PrintToChat(Client, "SetOwner to: %N", target);
		}
	}

	
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_setowner", szArgs);
	return Plugin_Handled;
}

public Action:Command_AdminTeam(Client, args) {
	if (args < 2) {
		LM_PrintToChat(Client, "Usage: !team <UserID> <Team>");
		return Plugin_Handled;
	}
	
	new String:szPlayer[64], String:szTeam[8];
	GetCmdArg(1, szPlayer, sizeof(szPlayer));
	GetCmdArg(2, szTeam, sizeof(szTeam));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(szPlayer, Client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(Client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++) {
		new target = target_list[i];
		ChangeClientTeam(target, StringToInt(szTeam));
		FakeClientCommand(target, "jointeam %s", szTeam);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_team", szArgs);
	return Plugin_Handled;
}

public Action:Command_AdminExplosionBeam(Client, args) {
	new Float:fClientPos[3], Float:fAimPos[3];
	new iColor[4];
	
	LM_ClientAimPos(Client, fAimPos);
	
	new iEntity = GetClientAimTarget(Client);
	if (iEntity != -1) {
		static EntFlag; EntFlag = GetEntityFlags(iEntity);
		if (EntFlag & (FL_CLIENT | FL_FAKECLIENT))
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fAimPos);
	}
	
	GetClientAbsOrigin(Client, fClientPos);
	new Obj_Explosion = CreateEntityByName("env_explosion");
	fClientPos[2] = (fClientPos[2] + 50);
	
	TeleportEntity(Obj_Explosion, fAimPos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Obj_Explosion, "iMagnitude", "200");
	DispatchKeyValue(Obj_Explosion, "iRadiusOverride", "200");
	DispatchSpawn(Obj_Explosion);
	
	iColor[0] = GetRandomInt(50, 255);
	iColor[1] = GetRandomInt(50, 255);
	iColor[2] = GetRandomInt(50, 255);
	iColor[3] = GetRandomInt(250, 255);
	
	TE_SetupBeamPoints(fAimPos, fClientPos, g_LBeam, g_Halo, 0, 66, 0.1, 3.0, 3.0, 0, 0.0, iColor, 20);
	TE_SendToAll();
	
	AcceptEntityInput(Obj_Explosion, "explode", Client, Client);
	AcceptEntityInput(Obj_Explosion, "kill", -1);
	return Plugin_Handled;
}

public Action:Command_AdminHurt(Client, args) {
	if (args < 3)
		return Plugin_Handled;
	
	new iColor[4];
	new String:szHurtDamage[64], String:szHurtRange[64], String:szHrutType[64], String:szClassName[64], String:szParent[64];
	new Float:vOriginPlayer[3], Float:fAimPos[3];
	GetCmdArg(1, szHurtDamage, sizeof(szHurtDamage));
	GetCmdArg(2, szHurtRange, sizeof(szHurtRange));
	GetCmdArg(3, szHrutType, sizeof(szHrutType));
	GetCmdArg(4, szClassName, sizeof(szClassName));
	GetCmdArg(5, szParent, sizeof(szParent));
	
	LM_ClientAimPos(Client, fAimPos);
	GetClientAbsOrigin(Client, vOriginPlayer);
	
	new iEntity = GetClientAimTarget(Client);
	if (iEntity != -1)
		if (GetEntityFlags(iEntity) & (FL_CLIENT | FL_FAKECLIENT))
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fAimPos);
	
	if (StrEqual(szHurtDamage, ""))
		szHurtDamage = "50";
	if (StrEqual(szHurtRange, ""))
		szHurtRange = "200";
	if (StrEqual(szHrutType, ""))
		szHrutType = "0";
	if (StrEqual(szClassName, ""))
		szClassName = "point_hurt";
	
	new Obj_Hurt;Obj_Hurt = CreateEntityByName("point_hurt");
	vOriginPlayer[2] = (vOriginPlayer[2] + 50);
	
	TeleportEntity(Obj_Hurt, fAimPos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Obj_Hurt, "damage", szHurtDamage);
	DispatchKeyValue(Obj_Hurt, "DamageRadius", szHurtRange);
	DispatchKeyValue(Obj_Hurt, "damagetype", szHrutType);
	DispatchKeyValue(Obj_Hurt, "classname", szClassName);
	DispatchSpawn(Obj_Hurt);
	
	iColor[0] = GetRandomInt(50, 255);
	iColor[1] = GetRandomInt(50, 255);
	iColor[2] = GetRandomInt(50, 255);
	iColor[3] = GetRandomInt(250, 255);
	
	TE_SetupBeamPoints(fAimPos, vOriginPlayer, g_LBeam, g_Halo, 0, 66, 0.1, 3.0, 3.0, 0, 0.0, iColor, 20);
	TE_SendToAll();
	
	
	
	if (StrEqual(szParent, "")) {
		AcceptEntityInput(Obj_Hurt, "hurt", Client, Client);
	} else if (StrEqual(szParent, "r")) {
		new Float:fOriginEntity[3];
		DispatchKeyValue(Client, "targetname", "szHurtFrom");
		SetVariantString("szHurtFrom");
		AcceptEntityInput(Obj_Hurt, "setparent", Client, Client);
		for(new i = 0; i < 4000; i++) {
			if(IsValidEdict(i)) {
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", fOriginEntity);
				GetEdictClassname(i, szClassName, sizeof(szClassName));
				if((StrContains(szClassName, "npc_") == 0 || StrEqual(szClassName, "player")) && Build_IsInRange(fOriginEntity, fAimPos, StringToFloat(szHurtRange))) {
					DispatchKeyValue(i, "targetname", "HurtTarget");
					DispatchKeyValue(Obj_Hurt, "damagetarget", "HurtTarget");
					AcceptEntityInput(Obj_Hurt, "hurt", Client, Client);
					DispatchKeyValue(i, "targetname", "HurtTargetDrop");
				}
			}
		}
		DispatchKeyValue(Client, "targetname", "szHurtUserDrop");
	} else if (StrEqual(szParent, "all")) {
		new iPlayer = -1;
		DispatchKeyValue(Client, "targetname", "szHurtFrom");
		SetVariantString("szHurtFrom");
		AcceptEntityInput(Obj_Hurt, "setparent", Client, Client);
		for (new i = 0; i < MAXPLAYERS; i++) {
			while ((iPlayer = FindEntityByClassname(iPlayer, "player")) != -1) {
				DispatchKeyValue(iPlayer, "targetname", "HurtTarget");
				DispatchKeyValue(Obj_Hurt, "damagetarget", "HurtTarget");
				AcceptEntityInput(Obj_Hurt, "hurt", Client, Client);
				DispatchKeyValue(iPlayer, "targetname", "HurtTargetDrop");
			}
		}
		DispatchKeyValue(Client, "targetname", "szHurtUserDrop");
	} else {
		new iPlayer = GetClientOfUserId(StringToInt(szParent));
		DispatchKeyValue(iPlayer, "targetname", "HurtTarget");
		DispatchKeyValue(Obj_Hurt, "damagetarget", "HurtTarget");
		DispatchKeyValue(Client, "targetname", "szHurtFrom");
		SetVariantString("szHurtFrom");
		AcceptEntityInput(Obj_Hurt, "setparent", Client, Client);
		AcceptEntityInput(Obj_Hurt, "hurt", Client, Client);
		DispatchKeyValue(Client, "targetname", "szHurtUserDrop");
		DispatchKeyValue(iPlayer, "targetname", "HurtTargetDrop");
	}
	EmitAmbientSound("ion/attack.wav", vOriginPlayer, Obj_Hurt, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	EmitAmbientSound("ion/attack.wav", fAimPos, Obj_Hurt, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	//new iPitch = GetRandomInt(50, 255);
	//EmitAmbientSound("npc/sniper/sniper1.wav", vOriginPlayer, Obj_Hurt, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, iPitch);
	//EmitAmbientSound("npc/sniper/echo1.wav", fAimPos, Obj_Hurt, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, iPitch);
	AcceptEntityInput(Obj_Hurt, "kill", -1);
	return Plugin_Handled;
}

public Action:Command_AdminDrOct(Client, args) {
	new String:szRange[8];
	GetCmdArg(1, szRange, sizeof(szRange));
	
	if (StringToInt(szRange) < 1)
		szRange = "300";
	
	new Float:vDrOctOrigin[3];
	LM_ClientAimPos(Client, vDrOctOrigin);
	DrOctCharge(Client, vDrOctOrigin, szRange);
	return Plugin_Handled;
}

public Action:Command_AdminShoot(Client, args) {
	new String:Prop[128];
	GetCmdArg(1, Prop, sizeof(Prop));
	if (args < 1) {
		Prop = "gascan1";
	}
	FakeClientCommand(Client, "e_spawnprop %s", Prop);
	FakeClientCommand(Client, "e_setmass 50000");
	FakeClientCommand(Client, "e_fire sethealth 15");
	FakeClientCommand(Client, "e_fire ignitelifetime 999");
	FakeClientCommand(Client, "e_push 5000000000");
	return Plugin_Handled;	
}

public Action:Command_AdminMissile(Client, args) {
	new Obj_InfoTarget;
	g_iMissileTarget[Client] = LM_ClientAimEntity(Client, _, true);
	if (g_iMissileTarget[Client] == -1) {
		new String:vTarget[8];
		GetCmdArg(1, vTarget, sizeof(vTarget));
		if (!StrEqual(vTarget, "")) {
			new Float:fAimPos[3];
			LM_ClientAimPos(Client, fAimPos);
			Obj_InfoTarget = CreateEntityByName("info_target");
			TeleportEntity(Obj_InfoTarget, fAimPos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(Obj_InfoTarget, "targetname", "szMissileTarget");
			DispatchSpawn(Obj_InfoTarget);
		} else
			return Plugin_Handled;	
	}
	
	new Float:vOriginPlayer[3], Float:fAnglePlayer[3];
	GetClientAbsOrigin(Client, vOriginPlayer);
	GetClientAbsAngles(Client, fAnglePlayer);
	vOriginPlayer[2] = (vOriginPlayer[2] + 150);
	
	if (StrEqual(g_szMissileModel[Client], ""))
		return Plugin_Handled;
	
	new Obj_MissileLauncher;Obj_MissileLauncher = CreateEntityByName("npc_launcher");
	TeleportEntity(Obj_MissileLauncher, vOriginPlayer, fAnglePlayer, NULL_VECTOR);
	DispatchKeyValue(g_iMissileTarget[Client], "targetname", "szMissileTarget");
	DispatchKeyValue(Obj_MissileLauncher, "MissileModel", g_szMissileModel[Client]);
	DispatchKeyValue(Obj_MissileLauncher, "FlySound", "weapons/rpg/rocket1.wav");
	DispatchKeyValue(Obj_MissileLauncher, "SmokeTrail", "2");
	DispatchKeyValue(Obj_MissileLauncher, "LaunchSmoke", "0");
	DispatchKeyValue(Obj_MissileLauncher, "LaunchDelay", "1");
	DispatchKeyValue(Obj_MissileLauncher, "LaunchSpeed", "1500");
	DispatchKeyValue(Obj_MissileLauncher, "HomingSpeed", "1.5");
	DispatchKeyValue(Obj_MissileLauncher, "HomingStrength", "100");
	DispatchKeyValue(Obj_MissileLauncher, "HomingDelay", "0.1");
	DispatchKeyValue(Obj_MissileLauncher, "HomingRampUp", "0");
	DispatchKeyValue(Obj_MissileLauncher, "HomingDuration", "20");
	DispatchKeyValue(Obj_MissileLauncher, "HomingRampDown", "1");
	DispatchKeyValue(Obj_MissileLauncher, "Gravity", "1");
	DispatchKeyValue(Obj_MissileLauncher, "MinRange", "1");
	DispatchKeyValue(Obj_MissileLauncher, "MaxRange", "5000");
	DispatchKeyValue(Obj_MissileLauncher, "SpinMagnitude", "1");
	DispatchKeyValue(Obj_MissileLauncher, "SpinSpeed", "1");
	DispatchKeyValue(Obj_MissileLauncher, "Damage", "50");
	DispatchKeyValue(Obj_MissileLauncher, "DamageRadius", "50");
	
	DispatchSpawn(Obj_MissileLauncher);
	SetVariantString("szMissileTarget d_ht 99");
	AcceptEntityInput(Obj_MissileLauncher, "setrelationship", -1);
	SetVariantString("szMissileTarget");
	AcceptEntityInput(Obj_MissileLauncher, "setenemyentity", -1);
	AcceptEntityInput(Obj_MissileLauncher, "fireonce", -1);
	AcceptEntityInput(Obj_MissileLauncher, "kill", -1);
	AcceptEntityInput(Obj_InfoTarget, "kill", -1);
	
	DispatchKeyValue(g_iMissileTarget[Client], "targetname", "szMissileTargetDrop");
	return Plugin_Handled;
}

public Action:Command_AdminMissileSet(Client, args) {
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) {
		g_szMissileModel[Client] = "models/props_junk/watermelon01.mdl";
		LM_PrintToChat(Client, "Missile model has been set back to \"%s\".", g_szMissileModel[Client]);
	} else {
		GetEntPropString(iEntity, Prop_Data, "m_ModelName", g_szMissileModel[Client], sizeof(g_szMissileModel));
		LM_PrintToChat(Client, "Missile model has been set to \"%s\".", g_szMissileModel[Client]);
	}
	PrecacheModel(g_szMissileModel[Client]);
	return Plugin_Handled;
}

public Action:Command_AdminMissileLast(Client, args) {
	new Float:vOriginPlayer[3], Float:fAnglePlayer[3];
	GetClientAbsOrigin(Client, vOriginPlayer);
	GetClientAbsAngles(Client, fAnglePlayer);
	vOriginPlayer[2] = (vOriginPlayer[2] + 150);
	
	if (StrEqual(g_szMissileModel[Client], "")) {
		LM_PrintToChat(Client, "[Missile] Set a model with sm_misset first!");
		return Plugin_Handled;
	}
	
	new Obj_MissileLauncher;Obj_MissileLauncher = CreateEntityByName("npc_launcher");
	TeleportEntity(Obj_MissileLauncher, vOriginPlayer, fAnglePlayer, NULL_VECTOR);
	DispatchKeyValue(g_iMissileTarget[Client], "targetname", "szMissileTarget");
	DispatchKeyValue(Obj_MissileLauncher, "MissileModel", g_szMissileModel[Client]);
	DispatchKeyValue(Obj_MissileLauncher, "FlySound", "weapons/rpg/rocket1.wav");
	DispatchKeyValue(Obj_MissileLauncher, "SmokeTrail", "2");
	DispatchKeyValue(Obj_MissileLauncher, "LaunchSmoke", "0");
	DispatchKeyValue(Obj_MissileLauncher, "LaunchDelay", "1");
	DispatchKeyValue(Obj_MissileLauncher, "LaunchSpeed", "1500");
	DispatchKeyValue(Obj_MissileLauncher, "HomingSpeed", "1.5");
	DispatchKeyValue(Obj_MissileLauncher, "HomingStrength", "100");
	DispatchKeyValue(Obj_MissileLauncher, "HomingDelay", "0.1");
	DispatchKeyValue(Obj_MissileLauncher, "HomingRampUp", "0");
	DispatchKeyValue(Obj_MissileLauncher, "HomingDuration", "20");
	DispatchKeyValue(Obj_MissileLauncher, "HomingRampDown", "1");
	DispatchKeyValue(Obj_MissileLauncher, "Gravity", "1");
	DispatchKeyValue(Obj_MissileLauncher, "MinRange", "1");
	DispatchKeyValue(Obj_MissileLauncher, "MaxRange", "5000");
	DispatchKeyValue(Obj_MissileLauncher, "SpinMagnitude", "1");
	DispatchKeyValue(Obj_MissileLauncher, "SpinSpeed", "1");
	DispatchKeyValue(Obj_MissileLauncher, "Damage", "50");
	DispatchKeyValue(Obj_MissileLauncher, "DamageRadius", "50");
	
	DispatchSpawn(Obj_MissileLauncher);
	
	SetVariantString("szMissileTarget d_ht 99");
	AcceptEntityInput(Obj_MissileLauncher, "setrelationship", -1);
	SetVariantString("szMissileTarget");
	AcceptEntityInput(Obj_MissileLauncher, "setenemyentity", -1);
	
	AcceptEntityInput(Obj_MissileLauncher, "fireonce", -1);	
	AcceptEntityInput(Obj_MissileLauncher, "kill", -1);
	DispatchKeyValue(g_iMissileTarget[Client], "targetname", "szMissileTargetDrop");
	
	return Plugin_Handled;
}

public Action:Command_AdminBottle(Client, args) {
	new String:type[16];
	new Float:aim[3];
	new bottle;
	LM_ClientAimPos(Client, aim);	
	GetCmdArg(1, type, sizeof(type));
	
	if (StrEqual(type, "1")) {
		bottle = CreateEntityByName("prop_physics");
		TeleportEntity(bottle, aim, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(bottle, "model", "models/props_junk/GlassBottle01a.mdl");
		DispatchKeyValue(bottle, "exploderadius", "100");
		DispatchKeyValue(bottle, "explodedamage", "300");
		DispatchSpawn(bottle);
		return Plugin_Handled;
	}
	LM_PrintToChat(Client, "No bottle type selected.");
	
	return Plugin_Handled;
}

public Action:Command_RActionStrider(Client, args) {
	/*
	GetCmdArg(1, g_szRActionRange[Client], sizeof(g_szRActionRange));
	GetCmdArg(2, g_szRActionCommand[Client], sizeof(g_szRActionCommand));
	for (new i = 3; i < 11; i++)
		GetCmdArg(i, g_szRActionArgs[Client][i-3], sizeof(g_szRActionArgs));
	
	
	
	if (StringToFloat(g_szDelStriderRange[Client]) < 1)
		g_szDelStriderRange[Client] = "300";
	
	LM_ClientAimPos(Client, g_fDelStriderOrigin[Client]);
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity != -1) {
		static EntFlag; EntFlag = GetEntityFlags(iEntity);
		if (EntFlag & (FL_CLIENT | FL_FAKECLIENT))
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", g_fDelStriderOrigin[Client]);
	}
	CreateTimer(0.01, DScharge2, Client);
	return Plugin_Handled;
	*/
}

public Action:Command_RActionSquare(Client, args) {
	/*
	GetCmdArg(1, g_szDelStriderRange[Client], sizeof(g_szDelStriderRange));
	if (StringToFloat(g_szDelStriderRange[Client]) < 1)
		g_szDelStriderRange[Client] = "300";
	
	LM_ClientAimPos(Client, g_fDelStriderOrigin[Client]);
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity != -1) {
		static EntFlag; EntFlag = GetEntityFlags(iEntity);
		if (EntFlag & (FL_CLIENT | FL_FAKECLIENT))
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", g_fDelStriderOrigin[Client]);
	}
	CreateTimer(0.01, DScharge2, Client);
	return Plugin_Handled;
	*/
}

public Action:Command_Test(Client, args) {
	
	new iEntity = LM_ClientAimEntity(Client);
	if (iEntity == -1) 
		return Plugin_Handled;
	
	DispatchKeyValue(iEntity, "model", "models/props_junk/watermelon01.mdl");
	DispatchSpawn(iEntity);
	return Plugin_Handled;
}


// Misc
public Action:Command_kill(Client, Args) {
	if (!LM_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	ForcePlayerSuicide(Client);
	
	//if (GetCmdArgs() > 0)
	//	LM_PrintToChat(Client, "Don't use unneeded args in kill");
	
	return Plugin_Handled;
}

public Action:Command_Delay(Client, args) {
	if (args != 2) {
		ReplyToCommand(Client, "[SM] Usage: sm_future <Time in minutes> \"Command CmdArgs\"");
		return Plugin_Handled;	
	}
	new String:szCommand[255], String:szTime[12];
	GetCmdArg(1, szTime, sizeof(szTime));
	GetCmdArg(2, szCommand, sizeof(szCommand));
	
	new Float:fTime = StringToFloat(szTime);
	
	ShowActivity2(Client, "[SM] ","Executing \"%s\" in %s seconds", szCommand, szTime);
	
	new Handle:hExcute;
	CreateDataTimer(fTime, Timer_Delay, hExcute);
	WritePackString(hExcute,szTime);
	WritePackString(hExcute,szCommand);
	return Plugin_Handled;
}

// Timers
public DrOctCharge(Client, Float:vDrOctOrigin[3], String:szRange[]) {
	new Float:vOriginPlayer[3], Float:vOriginPlayerBeam[3];
	
	GetClientAbsOrigin(Client, vOriginPlayer);
	GetClientAbsOrigin(Client, vOriginPlayerBeam);
	vOriginPlayerBeam[2] += 50;
	EmitAmbientSound("dr_oct.wav", vDrOctOrigin, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);
	EmitAmbientSound("dr_oct.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);
	EmitAmbientSound("npc/strider/charging.wav", vDrOctOrigin, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);
	EmitAmbientSound("npc/strider/charging.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);
	
	new Obj_Push = CreateEntityByName("point_push");
	TeleportEntity(Obj_Push, vDrOctOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Obj_Push, "magnitude", "-1000");
	DispatchKeyValue(Obj_Push, "radius", szRange);
	DispatchKeyValue(Obj_Push, "inner_radius", szRange);
	DispatchKeyValue(Obj_Push, "spawnflags", "28");
	DispatchSpawn(Obj_Push);
	AcceptEntityInput(Obj_Push, "enable", -1);
	
	new Obj_Core = CreateEntityByName("env_citadel_energy_core");
	TeleportEntity(Obj_Core, vDrOctOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Obj_Core, "scale", "5");
	DispatchKeyValue(Obj_Core, "spawnflags", "1");
	DispatchSpawn(Obj_Core);
	AcceptEntityInput(Obj_Core, "startdischarge", -1);
	
	TE_SetupBeamPoints(vDrOctOrigin, vOriginPlayerBeam, g_Beam, g_Halo, 0, 66, 1.3, 15.0, 15.0, 0, 0.0, ColorBlue, 20);
	TE_SendToAll();
	TE_SetupBeamPoints(vDrOctOrigin, vOriginPlayerBeam, g_Beam, g_Halo, 0, 66, 1.3, 20.0, 20.0, 0, 0.0, ColorWhite, 20);
	TE_SendToAll();
	
	new Handle:hDataPack;
	CreateDataTimer(1.2, Timer_DrOctFire, hDataPack);
	WritePackCell(hDataPack, Client);
	WritePackCell(hDataPack, Obj_Push);
	WritePackCell(hDataPack, Obj_Core);
	WritePackFloat(hDataPack, vDrOctOrigin[0]);
	WritePackFloat(hDataPack, vDrOctOrigin[1]);
	WritePackFloat(hDataPack, vDrOctOrigin[2]);
	WritePackFloat(hDataPack, vOriginPlayerBeam[0]);
	WritePackFloat(hDataPack, vOriginPlayerBeam[1]);
	WritePackFloat(hDataPack, vOriginPlayerBeam[2]);
	return;
}

public Action:Timer_DrOctFire(Handle:Timer, Handle:hDataPack) {
	
	ResetPack(hDataPack);
	new Client = ReadPackCell(hDataPack);
	new Obj_Push = ReadPackCell(hDataPack);
	new Obj_Core = ReadPackCell(hDataPack);
	new Float:vDrOctOrigin[3];
	vDrOctOrigin[0] = ReadPackFloat(hDataPack);
	vDrOctOrigin[1] = ReadPackFloat(hDataPack);
	vDrOctOrigin[2] = ReadPackFloat(hDataPack);
	new Float:vOriginPlayerBeam[3];
	vOriginPlayerBeam[0] = ReadPackFloat(hDataPack);
	vOriginPlayerBeam[1] = ReadPackFloat(hDataPack);
	vOriginPlayerBeam[2] = ReadPackFloat(hDataPack);
	
	EmitAmbientSound("npc/strider/fire.wav", vDrOctOrigin, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	EmitAmbientSound("npc/strider/fire.wav", vOriginPlayerBeam, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	TE_SetupBeamPoints(vDrOctOrigin, vOriginPlayerBeam, g_Beam, g_Halo, 0, 66, 0.2, 15.0, 15.0, 0, 0.0, ColorRed, 20);
	TE_SendToAll();
	TE_SetupBeamPoints(vDrOctOrigin, vOriginPlayerBeam, g_Beam, g_Halo, 0, 66, 0.2, 20.0, 20.0, 0, 0.0, ColorWhite, 20);
	TE_SendToAll();
	DispatchKeyValue(Obj_Push, "magnitude", "1000");
	
	new Handle:hNewPack;
	CreateDataTimer(0.01, Timer_DrOctRemove, hNewPack);
	WritePackCell(hNewPack, Obj_Push);
	WritePackCell(hNewPack, Obj_Core);
}

public Action:Timer_DrOctRemove(Handle:Timer, Handle:hDataPack) {
	ResetPack(hDataPack);
	new Obj_Push = ReadPackCell(hDataPack);
	new Obj_Core = ReadPackCell(hDataPack);
	if (IsValidEntity(Obj_Push))
		AcceptEntityInput(Obj_Push, "kill", -1);
	if (IsValidEntity(Obj_Core))
		AcceptEntityInput(Obj_Core, "kill", -1);
}

public Action:Timer_Delay(Handle:Timer, Handle:hExcute) {
	new String:szCommand[255], String:szTime[25];
	
	ResetPack(hExcute);
	ReadPackString(hExcute, szTime, sizeof(szTime));
	ReadPackString(hExcute, szCommand, sizeof(szCommand));
	
	ServerCommand("%s", szCommand);
	
	return Plugin_Stop;
}

public Action:RActionStriderCharge(Handle:Timer, any:Client) {
	/*
	new Float:vOriginPlayer[3];
	
	if (g_bDelStriderIsRunning[Client]) {
		AcceptEntityInput(g_iDelStriderPushIndex[Client], "kill", -1);
		AcceptEntityInput(g_iDelStriderCoreIndex[Client], "kill", -1);
	}
	g_bDelStriderIsRunning = true;
	GetClientAbsOrigin(Client, vOriginPlayer);
	vOriginPlayer[2] = (vOriginPlayer[2] + 50);
	
	EmitAmbientSound("npc/strider/charging.wav", g_fDelStriderOrigin[Client], Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	EmitAmbientSound("npc/strider/charging.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	g_iDelStriderPushIndex[Client] = CreateEntityByName("point_push");
	TeleportEntity(g_iDelStriderPushIndex[Client], g_fDelStriderOrigin[Client], NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(g_iDelStriderPushIndex[Client], "magnitude", "-1000");
	DispatchKeyValue(g_iDelStriderPushIndex[Client], "radius", g_szDelStriderRange[Client]);
	DispatchKeyValue(g_iDelStriderPushIndex[Client], "inner_radius", g_szDelStriderRange[Client]);
	DispatchKeyValue(g_iDelStriderPushIndex[Client], "spawnflags", "28");
	DispatchSpawn(g_iDelStriderPushIndex[Client]);
	AcceptEntityInput(g_iDelStriderPushIndex[Client], "enable", -1);
	
	g_iDelStriderCoreIndex[Client] = CreateEntityByName("env_citadel_energy_core");
	TeleportEntity(g_iDelStriderCoreIndex[Client], g_fDelStriderOrigin[Client], NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(g_iDelStriderCoreIndex[Client], "scale", "5");
	DispatchKeyValue(g_iDelStriderCoreIndex[Client], "spawnflags", "1");
	DispatchSpawn(g_iDelStriderCoreIndex[Client]);
	AcceptEntityInput(g_iDelStriderCoreIndex[Client], "startdischarge", -1);
	
	new Float:fOriginEntity[3];
	new iEntity = -1;
	for (new i = 0; i < sizeof(EntityType); i++) {
		while ((iEntity = FindEntityByClassname(iEntity, EntityType[i])) != -1) {
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOriginEntity);
			fOriginEntity[2] = (fOriginEntity[2] + 1);
			if(Phys_IsPhysicsObject(iEntity)) {
				if (Build_IsInRange(fOriginEntity, g_fDelStriderOrigin[Client], StringToFloat(g_szDelStriderRange[Client]))) {
					Phys_EnableMotion(iEntity, true);
					SetEntityMoveType(iEntity, MOVETYPE_VPHYSICS);
				}
			}
		}
	}

	TE_SetupBeamPoints(g_fDelStriderOrigin[Client], vOriginPlayer, g_Beam, g_Halo, 0, 66, 1.3, 15.0, 15.0, 0, 0.0, ColorBlue, 20);
	TE_SendToAll();
	TE_SetupBeamPoints(g_fDelStriderOrigin[Client], vOriginPlayer, g_Beam, g_Halo, 0, 66, 1.3, 20.0, 20.0, 0, 0.0, ColorWhite, 20);
	TE_SendToAll();
	
	CreateTimer(1.3, DSfire2, Client);
	return Plugin_Handled;
	*/
}

public Action:RActionStriderFire(Handle:Timer, any:Client) {
	/*
	new Float:vOriginPlayer[3];
	GetClientAbsOrigin(Client, vOriginPlayer);
	vOriginPlayer[2] = (vOriginPlayer[2] + 50);
	
	AcceptEntityInput(g_iDelStriderPushIndex[Client], "kill", -1);
	AcceptEntityInput(g_iDelStriderCoreIndex[Client], "kill", -1);
	
	EmitAmbientSound("npc/strider/fire.wav", g_fDelStriderOrigin[Client], Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	EmitAmbientSound("npc/strider/fire.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	TE_SetupBeamPoints(g_fDelStriderOrigin[Client], vOriginPlayer, g_Beam, g_Halo, 0, 66, 0.2, 15.0, 15.0, 0, 0.0, ColorRed, 20);
	TE_SendToAll();
	TE_SetupBeamPoints(g_fDelStriderOrigin[Client], vOriginPlayer, g_Beam, g_Halo, 0, 66, 0.2, 20.0, 20.0, 0, 0.0, ColorWhite, 20);
	TE_SendToAll();

	new Obj_Dissolver;Obj_Dissolver = CreateEntityByName("env_entity_dissolver");
	DispatchKeyValue(Obj_Dissolver, "dissolvetype", "3");
	DispatchKeyValue(Obj_Dissolver, "targetname", "disser");
	DispatchSpawn(Obj_Dissolver);
	
	new Float:fOriginEntity[3];
	new iCount = 0;
	new iEntity = -1;
	for (new i = 0; i < sizeof(EntityType); i++) {
		while ((iEntity = FindEntityByClassname(iEntity, EntityType[i])) != -1) {
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fOriginEntity);
			fOriginEntity[2] = (fOriginEntity[2] + 1);
			if (Build_IsInRange(fOriginEntity, g_fDelStriderOrigin[Client], StringToFloat(g_szDelStriderRange[Client]))) {
				DispatchKeyValue(iEntity, "targetname", "disstar");
				SetVariantString("disstar");
				AcceptEntityInput(Obj_Dissolver, "dissolve", -1);
				AcceptEntityInput(Obj_Dissolver, "kill", -1);
				DispatchKeyValue(iEntity, "targetname", "dissdrop");
				iCount++;
			}
		}
	}
	if (iCount > 0)
		LM_PrintToChat(Client, "Deleted %i props.", iCount);
	
	g_bDelStriderIsRunning[Client] = false;
	return Plugin_Handled;
	*/
}


public MapPreset() {
	new String:szMapName[64];
	GetCurrentMap(szMapName, sizeof(szMapName));
	
	if (IsAllowBuildMod(szMapName))
		ServerCommand("exec buildmodon");
	else
		ServerCommand("exec buildmodoff");
	
	if (StrEqual(szMapName, "z_umi_hydramag_v4")) {
		new Float:vRebelOri[3], Float:vRebelAng[3], Float:vWepOri[3], Float:vWepAng[3], Obj_RebelStart = -1, Obj_Laser = -1, Obj_WeaponCrate = -1;
		vRebelOri[0] = -284.547;
		vRebelOri[1] = 4590.370;
		vRebelOri[2] = 1065.000;
		vRebelAng[0] = 0.0;
		vRebelAng[1] = 270.0;
		vRebelAng[2] = 0.0;
		while ((Obj_RebelStart = FindEntityByClassname(Obj_RebelStart , "info_player_rebel")) != -1)
			TeleportEntity(Obj_RebelStart, vRebelOri, vRebelAng, NULL_VECTOR);
		
		vWepOri[0] = -3009.836;
		vWepOri[1] = -3164.536;
		vWepOri[2] = 1860.170;
		vWepAng[0] = 0.0;
		vWepAng[1] = 180.0;
		vWepAng[2] = 0.0;
		while ((Obj_WeaponCrate = FindEntityByClassname(Obj_WeaponCrate , "item_ammo_crate")) != -1)
			TeleportEntity(Obj_WeaponCrate, vWepOri, vWepAng, NULL_VECTOR);
		
		while ((Obj_Laser  = FindEntityByClassname(Obj_Laser , "env_laser")) != -1) {
			SetVariantString("1");
			AcceptEntityInput(Obj_Laser, "width", -1);
			DispatchKeyValue(Obj_Laser, "damage", "0");
		}
	} else if (StrEqual(szMapName, "z_umizuri_hydra") || StrEqual(szMapName, "z_umizuri_v4") || StrEqual(szMapName, "js_fishing_umizuri_v3") || StrEqual(szMapName, "z_umizuri_xyz")) {
		new Float:vRebelOri[3], Float:vRebelAng[3], Obj_RebelStart = -1;
		vRebelOri[0] = 2939.437500;
		vRebelOri[1] = -4545.125000;
		vRebelOri[2] = 1920.000000;
		vRebelAng[0] = 0.0;
		vRebelAng[1] = 270.0;
		vRebelAng[2] = 0.0;
		while ((Obj_RebelStart = FindEntityByClassname(Obj_RebelStart , "info_player_rebel")) != -1)
			TeleportEntity(Obj_RebelStart, vRebelOri, vRebelAng, NULL_VECTOR);
		
	} else if (StrEqual(szMapName, "rp_cityx_007")) {
		new Obj_Timer = -1;
		while ((Obj_Timer = FindEntityByClassname(Obj_Timer , "logic_timer")) != -1)
			AcceptEntityInput(Obj_Timer, "kill", -1);
		ServerCommand("hostname %s", g_szHostName);
		ServerCommand("sm_future 1 \"exec server\"");
	}
}

new String:szMapNameHead[][] = {
	"twbz_",
	"rp_",
	"Rp_",
	"RP_",
	"gm_",
	"Gm_",
	"GM_",
	"z_",
	"Z_",
	"freespace",
	"Freespace",
	"FreeSpace"
};

bool:IsAllowBuildMod(String:szMapName[64]){
	GetCurrentMap(szMapName, sizeof(szMapName));
	for (new i = 0; i < sizeof(szMapNameHead); i++) {
		if(StrContains(szMapName, szMapNameHead[i]) == 0) {
			PrintToServer("Map name start with \"%s\"", szMapNameHead);
			PrintToServer("BuildMod Allowed!!");
			return true;
		}
	}
	PrintToServer("BuildMod Disabled!!");
	return false;
}

