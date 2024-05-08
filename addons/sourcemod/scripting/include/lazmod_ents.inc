

/**
 * Get origin of an entity.
 * 
 * @param entProp		Entity index
 * @param vOrigin		Origin[3] to return to
 */
stock void LM_GetEntOrigin(const int entProp, float vOrigin[3]) {

	GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", vOrigin)
}

/**
 * Get angles of an entity.
 * 
 * @param entProp		Entity index
 * @param vAngles		Angles[3] to return to
 */
stock void LM_GetEntAngles(const int entProp, float vAngles[3]) {

	GetEntPropVector(entProp, Prop_Data, "m_angRotation", vAngles)
}

/**
 * Get health of an entity.
 * 
 * @param entProp		Entity index
 * 
 * @return				Health of entity
 */
stock int LM_GetEntHealth(const int entProp) {

	return GetEntProp(entProp, Prop_Data, "m_iHealth")
}

/**
 * Set health of an entity.
 * 
 * @param entProp		Entity index
 * @param iHealth		Health value
 */
stock void LM_SetEntHealth(const int entProp, const int iHealth) {

	SetEntProp(entProp, Prop_Data, "m_iHealth", iHealth)
}

/**
 * Get target name of an entity.
 * 
 * @param entProp		Entity index
 * @param szTName		Targetname to return to
 * @param iMaxlen		Max length of string
 */
stock LM_GetEntTargetName(const int entProp, char[] szTName, const int iMaxlen) {

	GetEntPropString(entProp, Prop_Data, "m_iName", szTName, iMaxlen);
}

/**
 * Get class name of an entity.
 * 
 * @param entProp		Entity index
 * @param szCName		Classname to return to
 * @param iMaxlen		Max length of string
 */
stock LM_GetEntClassname(const int entProp, char[] szCName, const int iMaxlen) {

	GetEntPropString(entProp, Prop_Data, "m_iClassname", szCName, iMaxlen);
}

/**
 * Get model name of an entity.
 * 
 * @param entProp		Entity index
 * @param szModel		Modelname to return to
 * @param iMaxlen		Max length of string
 */
stock LM_GetEntModel(const int entProp, char[] szModel, const int iMaxlen) {

	GetEntPropString(entProp, Prop_Data, "m_ModelName", szModel, iMaxlen)
}

/**
 * Set render mode, fx, color, alpha amount of an entity.
 * RenderMode: https://developer.valvesoftware.com/wiki/Render_Modes
 * RenderFx: https://developer.valvesoftware.com/wiki/Template:KV_Render_FX
 * 
 * @param entProp		Entity index
 * @param szModel		Modelname to return to
 * @param iMaxlen		Max length of string
 */
stock LM_SetEntRenderEffects(const int entProp, RenderMode rmMode = RENDER_NORMAL, const RenderFx rfFX = RENDERFX_NONE, const int iAlpha = 255, int iColors[3] = {255,...}, char[] szColors = "") {

	SetEntityRenderMode(entProp, rmMode)
	SetEntityRenderFx(entProp, rfFX)
	if (!StrEqual(szColors, "")) {
		char szColor[3][4]
		if (StrContains(szColors, " ")) {
			ExplodeString(szColors, " ", szColor, sizeof(szColor), sizeof(szColor[]))
		} else if (StrContains(szColors, ",")) {
			ExplodeString(szColors, ",", szColor, sizeof(szColor), sizeof(szColor[]))
		} else if (StrContains(szColors, ", ")) {
			ExplodeString(szColors, ", ", szColor, sizeof(szColor), sizeof(szColor[]))
		}
		iColors[0] = StringToInt(szColor[0])
		iColors[1] = StringToInt(szColor[1])
		iColors[2] = StringToInt(szColor[2])
	}
	SetEntityRenderColor(entProp, iColors[0], iColors[1], iColors[2], iAlpha)
}




