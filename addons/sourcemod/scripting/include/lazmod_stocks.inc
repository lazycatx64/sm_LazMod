
bool g_bFirstRun = false


/**
 * Check if plugin already ran before (plugin reload?)
 * Currently just a placeholder, no further use.
 */
stock LM_FirstRun() {
	if (g_bFirstRun) {
		int g_entFirstRun = FindEntityByClassname(0, "cat_First_Run")
		if (g_entFirstRun == -1) {
			g_entFirstRun = CreateEntityByName("info_target")
			DispatchKeyValue(g_entFirstRun, "classname", "cat_First_Run")
			DispatchSpawn(g_entFirstRun)
			g_bFirstRun = true
		} else
			g_bFirstRun = false
	}
}

/**
 * Get the coordinates of the client's aiming position
 *
 * @param plyClient			Client id
 * @param vAimPos			Aim pos to return
 */
stock LM_ClientAimPos(int plyClient, float vAimPos[3]) {
	float vOrigin[3], vAngles[3]
	
	GetClientEyePosition(plyClient, vOrigin)
	GetClientEyeAngles(plyClient, vAngles)
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer)
	
	if (TR_DidHit(trace)) {
		TR_GetEndPosition(vAimPos, trace)
	}
	CloseHandle(trace)
}
stock bool TraceEntityFilterPlayer(entity, contentsMask) {
	return entity > MaxClients
}

/**
 * Check if a coord was in range.
 *
 * @param vCheck		Origin to check
 * @param vPoint		Center of this range
 * @param fRange		Search range
 * @return True if was in range; false otherwise.
 */
stock bool LM_IsInRange(float vCheck[3], float vPoint[3], float fRange) {
	if ((vPoint[0] + fRange) > vCheck[0] > (vPoint[0] - fRange) &&
		(vPoint[1] + fRange) > vCheck[1] > (vPoint[1] - fRange) &&
		(vPoint[2] + fRange) > vCheck[2] > (vPoint[2] - fRange))
		return true
		
	return false
}

/**
 * Check if a coord is in a specific cube range
 *
 * @param vCheck			Origin to check
 * @param vPoint1			Point1
 * @param vPoint2			Point2
 * @return					True if vCheck was in cube; false otherwise
 */
stock bool LM_IsInCube(float vCheck[3], float vPoint1[3], float vPoint2[3]) {
	if ((vPoint1[0] > vCheck[0] > vPoint2[0] || vPoint2[0] > vCheck[0] > vPoint1[0]) &&
		(vPoint1[1] > vCheck[1] > vPoint2[1] || vPoint2[1] > vCheck[1] > vPoint1[1]) &&
		(vPoint1[2] > vCheck[2] > vPoint2[2] || vPoint2[2] > vCheck[2] > vPoint1[2]))
		return true

	return false
}


/**
 * Max edicts allowed for LazMod
 * HL2DM currently is 2048.
 * 5% (103) is reserved, so we have 1945 avaliable.
 * https://developer.valvesoftware.com/wiki/Entity_limit
 * 
 * @return 		Max edicts allowed for LazMod
 */
stock int LM_GetMaxEdict() {
	
	return RoundToFloor(GetMaxEntities()*0.95)
}

/**
 * Check if current edict count is about to break SourceEngine.
 * HL2DM currently is 2048.
 * 5% (103) is reserved, so we have 1945 avaliable.
 * https://developer.valvesoftware.com/wiki/Entity_limit
 * 
 * @return 		True if about to hit the reserved limit, false otherwise
 */
stock bool LM_CheckMaxEdict() {
	
	return GetEntityCount() <= LM_GetMaxEdict()
}