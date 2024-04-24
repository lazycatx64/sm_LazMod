
#define Unicode_stocks "測試"

bool g_bFirstRun = false

stock LM_FirstRun() {
	if (g_bFirstRun) {
		int g_entDmgFilter = FindEntityByClassname(0, "cat_First_Run")
		if (g_entDmgFilter == -1) {
			g_entDmgFilter = CreateEntityByName("info_target")
			DispatchKeyValue(g_entDmgFilter, "classname", "cat_First_Run")
			DispatchSpawn(g_entDmgFilter)
			g_bFirstRun = true
		} else
			g_bFirstRun = false
	}
}

stock LM_ClientAimPos(Client, float pos[3]) {
	float vOrigin[3], vAngles[3]
	
	GetClientEyePosition(Client, vOrigin)
	GetClientEyeAngles(Client, vAngles)
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer)
	
	if (TR_DidHit(trace)) {
		TR_GetEndPosition(pos, trace)
		CloseHandle(trace)
		return
	}
	CloseHandle(trace)
}

stock bool TraceEntityFilterPlayer(entity, contentsMask) {
	return entity > MaxClients
}

stock bool LM_IsInRange(float vEntityOrigin[3], float vPoint[3], float fRange) {
	if ((vPoint[0] + fRange) > vEntityOrigin[0] > (vPoint[0] - fRange) &&
		(vPoint[1] + fRange) > vEntityOrigin[1] > (vPoint[1] - fRange) &&
		(vPoint[2] + fRange) > vEntityOrigin[2] > (vPoint[2] - fRange))
		return true
		
	return false
}

stock bool LM_IsInSquare(float vEntityOrigin[3], float vPoint1[3], float vPoint2[3]) {
	if ((vPoint1[0] > vEntityOrigin[0] > vPoint2[0] || vPoint2[0] > vEntityOrigin[0] > vPoint1[0]) &&
		(vPoint1[1] > vEntityOrigin[1] > vPoint2[1] || vPoint2[1] > vEntityOrigin[1] > vPoint1[1]) &&
		(vPoint1[2] > vEntityOrigin[2] > vPoint2[2] || vPoint2[2] > vEntityOrigin[2] > vPoint1[2]))
		return true

	return false
}

