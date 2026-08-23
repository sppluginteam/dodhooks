/**
 * vim: set ts=4 :
 * ======================================================
 * DODHooks - Native implementations
 * ======================================================
 *
 * GPLv2 License
 */

#include "extension.h"
#include "natives.h"

/* CBaseEdict::GetChangeAccessor implementation */
IChangeInfoAccessor *CBaseEdict::GetChangeAccessor()
{
    return g_pEngine->GetChangeAccessor((const edict_t *)this);
}

/* ============================================================================
 * Player Class Natives
 * ========================================================================== */

cell_t Native_GetPlayerClass(IPluginContext *pContext, const cell_t *Params)
{
    edict_t *pEdict = g_pEngine->PEntityOfEntIndex(Params[1]);
    if (!pEdict)
    {
        return pContext->ThrowNativeError("Client index %d is invalid", Params[1]);
    }

    CBaseEntity *pEntity = g_pGameEnts->EdictToBaseEntity(pEdict);
    if (!pEntity || strcmp(pEdict->GetClassName(), "player") != 0)
    {
        return pContext->ThrowNativeError("Client index %d is not a valid player", Params[1]);
    }

    return OFFSET(int, pEntity, g_iOffset_PlayerClass);
}

cell_t Native_SetPlayerClass(IPluginContext *pContext, const cell_t *Params)
{
    edict_t *pEdict = g_pEngine->PEntityOfEntIndex(Params[1]);
    if (!pEdict)
    {
        return pContext->ThrowNativeError("Client index %d is invalid", Params[1]);
    }

    CBaseEntity *pEntity = g_pGameEnts->EdictToBaseEntity(pEdict);
    if (!pEntity || strcmp(pEdict->GetClassName(), "player") != 0)
    {
        return pContext->ThrowNativeError("Client index %d is not a valid player", Params[1]);
    }

    if (Params[2] < PlayerClass_Random || Params[2] >= PlayerClass_Size)
    {
        return pContext->ThrowNativeError("Player class %d is not valid", Params[2]);
    }

    OFFSET(int, pEntity, g_iOffset_PlayerClass) = Params[2];

    return true;
}

cell_t Native_GetDesiredPlayerClass(IPluginContext *pContext, const cell_t *Params)
{
    edict_t *pEdict = g_pEngine->PEntityOfEntIndex(Params[1]);
    if (!pEdict)
    {
        return pContext->ThrowNativeError("Client index %d is invalid", Params[1]);
    }

    CBaseEntity *pEntity = g_pGameEnts->EdictToBaseEntity(pEdict);
    if (!pEntity || strcmp(pEdict->GetClassName(), "player") != 0)
    {
        return pContext->ThrowNativeError("Client index %d is not a valid player", Params[1]);
    }

    return OFFSET(int, pEntity, g_iOffset_DesiredPlayerClass);
}

cell_t Native_SetDesiredPlayerClass(IPluginContext *pContext, const cell_t *Params)
{
    edict_t *pEdict = g_pEngine->PEntityOfEntIndex(Params[1]);
    if (!pEdict)
    {
        return pContext->ThrowNativeError("Client index %d is invalid", Params[1]);
    }

    CBaseEntity *pEntity = g_pGameEnts->EdictToBaseEntity(pEdict);
    if (!pEntity || strcmp(pEdict->GetClassName(), "player") != 0)
    {
        return pContext->ThrowNativeError("Client index %d is not a valid player", Params[1]);
    }

    if (Params[2] < PlayerClass_Random || Params[2] >= PlayerClass_Size)
    {
        return pContext->ThrowNativeError("Player class %d is not valid", Params[2]);
    }

    OFFSET(int, pEntity, g_iOffset_DesiredPlayerClass) = Params[2];

    return true;
}

/* ============================================================================
 * PopHelmet Native
 * ========================================================================== */

cell_t Native_PopHelmet(IPluginContext *pContext, const cell_t *Params)
{
    edict_t *pEdict = g_pEngine->PEntityOfEntIndex(Params[1]);
    if (!pEdict)
    {
        return pContext->ThrowNativeError("Client index %d is invalid", Params[1]);
    }

    CBaseEntity *pEntity = g_pGameEnts->EdictToBaseEntity(pEdict);
    if (!pEntity || strcmp(pEdict->GetClassName(), "player") != 0)
    {
        return pContext->ThrowNativeError("Client index %d is not a valid player", Params[1]);
    }

    /* Resolve the detour address once and cache the call wrapper */
    static ICallWrapper *pWrapper = NULL;

    if (!pWrapper)
    {
        void *pAddress = NULL;
        if (!g_pGameConf->GetMemSig("PopHelmet", &pAddress) || !pAddress)
        {
            return pContext->ThrowNativeError("Failed to resolve PopHelmet signature");
        }

        SourceMod::PassInfo Pass[2];
        Pass[0].flags = PASSFLAG_BYVAL;
        Pass[0].size = sizeof(Vector);
        Pass[0].type = PassType_Basic;

        Pass[1].flags = PASSFLAG_BYVAL;
        Pass[1].size = sizeof(Vector);
        Pass[1].type = PassType_Basic;

        pWrapper = g_pBinTools->CreateCall(pAddress, CallConv_ThisCall, NULL, Pass, 2);
        if (!pWrapper)
        {
            return pContext->ThrowNativeError("Failed to create PopHelmet call wrapper");
        }
    }

    cell_t *pAddr1, *pAddr2;

    pContext->LocalToPhysAddr(Params[2], &pAddr1);
    pContext->LocalToPhysAddr(Params[3], &pAddr2);

    /* On 64-bit Linux, ensure proper stack alignment for Vector arguments */
    unsigned char vstk[sizeof(CBaseEntity *) + (sizeof(Vector) * 2) + 16];
    memset(vstk, 0, sizeof(vstk));
    unsigned char *vptr = vstk;

    /* Align to 16-byte boundary for 64-bit ABI compliance */
#if defined(PLATFORM_X64) || defined(_WIN64)
    uintptr_t addr = (uintptr_t)vptr;
    addr = (addr + 15) & ~15;
    vptr = (unsigned char *)addr;
#endif

    *(CBaseEntity **)vptr = pEntity;
    vptr += sizeof(CBaseEntity *);

    *(Vector *)vptr = Vector(sp_ctof(pAddr1[0]), sp_ctof(pAddr1[1]), sp_ctof(pAddr1[2]));
    vptr += sizeof(Vector);

    *(Vector *)vptr = Vector(sp_ctof(pAddr2[0]), sp_ctof(pAddr2[1]), sp_ctof(pAddr2[2]));

    pWrapper->Execute(vstk, NULL);

    return true;
}

/* ============================================================================
 * Control Point / Objective Natives
 * ========================================================================== */

cell_t Native_SetNumControlPoints(IPluginContext *pContext, const cell_t *Params)
{
    if (!g_pObjectiveResource)
    {
        return pContext->ThrowNativeError("g_pObjectiveResource is NULL");
    }

    CBaseEntity *pObjectiveResource = (CBaseEntity *)*g_pObjectiveResource;

    if (!pObjectiveResource)
    {
        return pContext->ThrowNativeError("ObjectiveResource not available before map is loaded");
    }

    OFFSET(int, pObjectiveResource, g_iOffset_NumControlPoints) = Params[1];

    g_pGameEnts->BaseEntityToEdict(pObjectiveResource)->StateChanged(g_iOffset_NumControlPoints);

    return true;
}

void PrecacheMaterial(const char *szMaterialName)
{
    if (!netstringtables)
    {
        return;
    }

    INetworkStringTable *pTable = netstringtables->FindTable("Materials");
    if (pTable)
    {
        pTable->AddString(true, szMaterialName);
    }
}

int GetMaterialIndex(const char *pMaterialName)
{
    if (!netstringtables)
    {
        return 0;
    }

    INetworkStringTable *pTable = netstringtables->FindTable("Materials");
    if (!pTable)
    {
        return 0;
    }

    int idx = pTable->FindStringIndex(pMaterialName);
    if (idx == INVALID_STRING_INDEX)
    {
        return 0;
    }

    return idx;
}

cell_t Native_PrecacheCPIcon(IPluginContext *pContext, const cell_t *Params)
{
    char *szMaterialName;
    pContext->LocalToString(Params[1], &szMaterialName);

    PrecacheMaterial(szMaterialName);

    return GetMaterialIndex(szMaterialName);
}

cell_t Native_SetCPIcons(IPluginContext *pContext, const cell_t *Params)
{
    if (!g_pObjectiveResource)
    {
        return pContext->ThrowNativeError("g_pObjectiveResource is NULL");
    }

    CBaseEntity *pObjectiveResource = (CBaseEntity *)*g_pObjectiveResource;

    if (!pObjectiveResource)
    {
        return pContext->ThrowNativeError("ObjectiveResource not available before map is loaded");
    }

    if (Params[1] < 0 || Params[1] >= MAX_CONTROL_POINTS)
    {
        return pContext->ThrowNativeError("Control point index %d is not valid", Params[1]);
    }

    edict_t *pEdict = g_pGameEnts->BaseEntityToEdict(pObjectiveResource);

    int arrayElement = static_cast<int>(Params[1]) * static_cast<int>(sizeof(int));

    if (Params[2])
    {
        OFFSET(int, pObjectiveResource, g_iOffset_AlliesIcons + arrayElement) = Params[2];
        pEdict->StateChanged(g_iOffset_AlliesIcons + arrayElement);
    }

    if (Params[3])
    {
        OFFSET(int, pObjectiveResource, g_iOffset_AxisIcons + arrayElement) = Params[3];
        pEdict->StateChanged(g_iOffset_AxisIcons + arrayElement);
    }

    if (Params[4])
    {
        OFFSET(int, pObjectiveResource, g_iOffset_NeutralIcons + arrayElement) = Params[4];
        pEdict->StateChanged(g_iOffset_NeutralIcons + arrayElement);
    }

    if (Params[5])
    {
        OFFSET(int, pObjectiveResource, g_iOffset_TimerCapIcons + arrayElement) = Params[5];
        pEdict->StateChanged(g_iOffset_TimerCapIcons + arrayElement);
    }

    if (Params[6])
    {
        OFFSET(int, pObjectiveResource, g_iOffset_BombedIcons + arrayElement) = Params[6];
        pEdict->StateChanged(g_iOffset_BombedIcons + arrayElement);
    }

    return true;
}

cell_t Native_SetCPVisible(IPluginContext *pContext, const cell_t *Params)
{
    if (!g_pObjectiveResource)
    {
        return pContext->ThrowNativeError("g_pObjectiveResource is NULL");
    }

    CBaseEntity *pObjectiveResource = (CBaseEntity *)*g_pObjectiveResource;

    if (!pObjectiveResource)
    {
        return pContext->ThrowNativeError("ObjectiveResource not available before map is loaded");
    }

    if (Params[1] < 0 || Params[1] >= MAX_CONTROL_POINTS)
    {
        return pContext->ThrowNativeError("Control point index %d is not valid", Params[1]);
    }

    int arrayElement = static_cast<int>(Params[1]) * static_cast<int>(sizeof(int));

    OFFSET(int, pObjectiveResource, g_iOffset_CPIsVisible + arrayElement) = Params[2];

    g_pGameEnts->BaseEntityToEdict(pObjectiveResource)->StateChanged(g_iOffset_CPIsVisible + arrayElement);

    return true;
}

/* ============================================================================
 * Timer Natives
 * ========================================================================== */

cell_t Native_PauseTimer(IPluginContext *pContext, const cell_t *Params)
{
    edict_t *pEdict = g_pEngine->PEntityOfEntIndex(Params[1]);
    if (!pEdict)
    {
        return pContext->ThrowNativeError("Entity index %d is invalid", Params[1]);
    }

    CBaseEntity *pEntity = g_pGameEnts->EdictToBaseEntity(pEdict);
    if (!pEntity || strcmp(pEdict->GetClassName(), "dod_round_timer") != 0)
    {
        return pContext->ThrowNativeError("Entity index %d is not a dod_round_timer", Params[1]);
    }

    if (!OFFSET(bool, pEntity, g_iOffset_TimerPaused))
    {
        OFFSET(float, pEntity, g_iOffset_TimeRemaining) = OFFSET(float, pEntity, g_iOffset_TimerEndTime) - g_pGlobals->curtime;
        OFFSET(bool, pEntity, g_iOffset_TimerPaused) = true;

        pEdict->StateChanged(g_iOffset_TimeRemaining);
        pEdict->StateChanged(g_iOffset_TimerPaused);
    }

    return true;
}

cell_t Native_ResumeTimer(IPluginContext *pContext, const cell_t *Params)
{
    edict_t *pEdict = g_pEngine->PEntityOfEntIndex(Params[1]);
    if (!pEdict)
    {
        return pContext->ThrowNativeError("Entity index %d is invalid", Params[1]);
    }

    CBaseEntity *pEntity = g_pGameEnts->EdictToBaseEntity(pEdict);
    if (!pEntity || strcmp(pEdict->GetClassName(), "dod_round_timer") != 0)
    {
        return pContext->ThrowNativeError("Entity index %d is not a dod_round_timer", Params[1]);
    }

    if (OFFSET(bool, pEntity, g_iOffset_TimerPaused))
    {
        OFFSET(float, pEntity, g_iOffset_TimerEndTime) = OFFSET(float, pEntity, g_iOffset_TimeRemaining) + g_pGlobals->curtime;
        OFFSET(bool, pEntity, g_iOffset_TimerPaused) = false;

        pEdict->StateChanged(g_iOffset_TimerEndTime);
        pEdict->StateChanged(g_iOffset_TimerPaused);
    }

    return true;
}

cell_t Native_SetTimeRemaining(IPluginContext *pContext, const cell_t *Params)
{
    edict_t *pEdict = g_pEngine->PEntityOfEntIndex(Params[1]);
    if (!pEdict)
    {
        return pContext->ThrowNativeError("Entity index %d is invalid", Params[1]);
    }

    CBaseEntity *pEntity = g_pGameEnts->EdictToBaseEntity(pEdict);
    if (!pEntity || strcmp(pEdict->GetClassName(), "dod_round_timer") != 0)
    {
        return pContext->ThrowNativeError("Entity index %d is not a dod_round_timer", Params[1]);
    }

    OFFSET(float, pEntity, g_iOffset_TimeRemaining) = sp_ctof(Params[2]);
    OFFSET(float, pEntity, g_iOffset_TimerEndTime) = g_pGlobals->curtime + sp_ctof(Params[2]);

    pEdict->StateChanged(g_iOffset_TimeRemaining);
    pEdict->StateChanged(g_iOffset_TimerEndTime);

    return true;
}

cell_t Native_GetTimeRemaining(IPluginContext *pContext, const cell_t *Params)
{
    edict_t *pEdict = g_pEngine->PEntityOfEntIndex(Params[1]);
    if (!pEdict)
    {
        return pContext->ThrowNativeError("Entity index %d is invalid", Params[1]);
    }

    CBaseEntity *pEntity = g_pGameEnts->EdictToBaseEntity(pEdict);
    if (!pEntity || strcmp(pEdict->GetClassName(), "dod_round_timer") != 0)
    {
        return pContext->ThrowNativeError("Entity index %d is not a dod_round_timer", Params[1]);
    }

    float fTimeRemaining;

    if (OFFSET(bool, pEntity, g_iOffset_TimerPaused))
    {
        fTimeRemaining = OFFSET(float, pEntity, g_iOffset_TimeRemaining);
    }
    else
    {
        fTimeRemaining = OFFSET(float, pEntity, g_iOffset_TimerEndTime) - g_pGlobals->curtime;
    }

    if (fTimeRemaining < 0.0f)
    {
        fTimeRemaining = 0.0f;
    }

    return sp_ftoc(fTimeRemaining);
}

/* ============================================================================
 * Game Rules Natives
 * ========================================================================== */

cell_t Native_RespawnPlayer(IPluginContext *pContext, const cell_t *Params)
{
    edict_t *pEdict = g_pEngine->PEntityOfEntIndex(Params[1]);
    if (!pEdict)
    {
        return pContext->ThrowNativeError("Client index %d is invalid", Params[1]);
    }

    CBaseEntity *pEntity = g_pGameEnts->EdictToBaseEntity(pEdict);
    if (!pEntity || strcmp(pEdict->GetClassName(), "player") != 0)
    {
        return pContext->ThrowNativeError("Client index %d is not a valid player", Params[1]);
    }

    if (Params[2])
    {
        int iPlayerClass = OFFSET(int, pEntity, g_iOffset_DesiredPlayerClass);

        if (iPlayerClass == PlayerClass_None)
        {
            return pContext->ThrowNativeError("Player class is not valid (PlayerClass_None)");
        }
    }

    static ICallWrapper *pWrapper = NULL;

    if (!pWrapper)
    {
        void *pAddress = NULL;
        if (!g_pGameConf->GetMemSig("DODRespawn", &pAddress) || !pAddress)
        {
            return pContext->ThrowNativeError("Failed to resolve DODRespawn signature");
        }

        pWrapper = g_pBinTools->CreateCall(pAddress, CallConv_ThisCall, NULL, NULL, 0);
        if (!pWrapper)
        {
            return pContext->ThrowNativeError("Failed to create DODRespawn call wrapper");
        }
    }

    pWrapper->Execute(&pEntity, NULL);

    return true;
}

cell_t Native_AddWaveTime(IPluginContext *pContext, const cell_t *Params)
{
    if (Params[1] != Team_Allies && Params[1] != Team_Axis)
    {
        return pContext->ThrowNativeError("Team index %i is not valid", Params[1]);
    }

    static ICallWrapper *pWrapper = NULL;

    if (!pWrapper)
    {
        void *pAddress = NULL;
        if (!g_pGameConf->GetMemSig("AddWaveTime", &pAddress) || !pAddress)
        {
            return pContext->ThrowNativeError("Failed to resolve AddWaveTime signature");
        }

        SourceMod::PassInfo Pass[2];
        Pass[0].flags = PASSFLAG_BYVAL;
        Pass[0].size = sizeof(int);
        Pass[0].type = PassType_Basic;

        Pass[1].flags = PASSFLAG_BYVAL;
        Pass[1].size = sizeof(float);
        Pass[1].type = PassType_Basic;

        pWrapper = g_pBinTools->CreateCall(pAddress, CallConv_ThisCall, NULL, Pass, 2);
        if (!pWrapper)
        {
            return pContext->ThrowNativeError("Failed to create AddWaveTime call wrapper");
        }
    }

    void *pGameRules = g_pSDKTools->GetGameRules();
    if (!pGameRules)
    {
        return pContext->ThrowNativeError("GameRules not available before map is loaded");
    }

    unsigned char vstk[sizeof(void *) + sizeof(int) + sizeof(float) + 16];
    memset(vstk, 0, sizeof(vstk));
    unsigned char *vptr = vstk;

#if defined(PLATFORM_X64) || defined(_WIN64)
    uintptr_t addr = (uintptr_t)vptr;
    addr = (addr + 15) & ~15;
    vptr = (unsigned char *)addr;
#endif

    *(void **)vptr = pGameRules;
    vptr += sizeof(void *);

    *(int *)vptr = Params[1];
    vptr += sizeof(int);

    float fDelay = sp_ctof(Params[2]);
    *(float *)vptr = fDelay;

    pWrapper->Execute(vstk, NULL);

    return true;
}

cell_t Native_SetWinningTeam(IPluginContext *pContext, const cell_t *Params)
{
    if (Params[1] != Team_Allies && Params[1] != Team_Axis)
    {
        return pContext->ThrowNativeError("Team index %d is not valid", Params[1]);
    }

    static ICallWrapper *pWrapper = NULL;

    if (!pWrapper)
    {
        void *pAddress = NULL;
        if (!g_pGameConf->GetMemSig("SetWinningTeam", &pAddress) || !pAddress)
        {
            return pContext->ThrowNativeError("Failed to resolve SetWinningTeam signature");
        }

        SourceMod::PassInfo Pass[1];
        Pass[0].flags = PASSFLAG_BYVAL;
        Pass[0].size = sizeof(int);
        Pass[0].type = PassType_Basic;

        pWrapper = g_pBinTools->CreateCall(pAddress, CallConv_ThisCall, NULL, Pass, 1);
        if (!pWrapper)
        {
            return pContext->ThrowNativeError("Failed to create SetWinningTeam call wrapper");
        }
    }

    void *pGameRules = g_pSDKTools->GetGameRules();
    if (!pGameRules)
    {
        return pContext->ThrowNativeError("GameRules not available before map is loaded");
    }

    unsigned char vstk[sizeof(void *) + sizeof(int) + 16];
    memset(vstk, 0, sizeof(vstk));
    unsigned char *vptr = vstk;

#if defined(PLATFORM_X64) || defined(_WIN64)
    uintptr_t addr = (uintptr_t)vptr;
    addr = (addr + 15) & ~15;
    vptr = (unsigned char *)addr;
#endif

    *(void **)vptr = pGameRules;
    vptr += sizeof(void *);

    *(int *)vptr = Params[1];

    pWrapper->Execute(vstk, NULL);

    return true;
}

cell_t Native_SetRoundState(IPluginContext *pContext, const cell_t *Params)
{
    static ICallWrapper *pWrapper = NULL;

    if (!pWrapper)
    {
        void *pAddress = NULL;
        if (!g_pGameConf->GetMemSig("RoundState", &pAddress) || !pAddress)
        {
            return pContext->ThrowNativeError("Failed to resolve RoundState signature");
        }

        SourceMod::PassInfo Pass[1];
        Pass[0].flags = PASSFLAG_BYVAL;
        Pass[0].size = sizeof(int);
        Pass[0].type = PassType_Basic;

        pWrapper = g_pBinTools->CreateCall(pAddress, CallConv_ThisCall, NULL, Pass, 1);
        if (!pWrapper)
        {
            return pContext->ThrowNativeError("Failed to create RoundState call wrapper");
        }
    }

    void *pGameRules = g_pSDKTools->GetGameRules();
    if (!pGameRules)
    {
        return pContext->ThrowNativeError("GameRules not available before map is loaded");
    }

    unsigned char vstk[sizeof(void *) + sizeof(int) + 16];
    memset(vstk, 0, sizeof(vstk));
    unsigned char *vptr = vstk;

#if defined(PLATFORM_X64) || defined(_WIN64)
    uintptr_t addr = (uintptr_t)vptr;
    addr = (addr + 15) & ~15;
    vptr = (unsigned char *)addr;
#endif

    *(void **)vptr = pGameRules;
    vptr += sizeof(void *);

    *(int *)vptr = Params[1];

    pWrapper->Execute(vstk, NULL);

    return true;
}

cell_t Native_SetPlayerState(IPluginContext *pContext, const cell_t *Params)
{
    edict_t *pEdict = g_pEngine->PEntityOfEntIndex(Params[1]);
    if (!pEdict)
    {
        return pContext->ThrowNativeError("Client index %d is invalid", Params[1]);
    }

    CBaseEntity *pEntity = g_pGameEnts->EdictToBaseEntity(pEdict);
    if (!pEntity || strcmp(pEdict->GetClassName(), "player") != 0)
    {
        return pContext->ThrowNativeError("Client index %d is not a valid player", Params[1]);
    }

    static ICallWrapper *pWrapper = NULL;

    if (!pWrapper)
    {
        void *pAddress = NULL;
        if (!g_pGameConf->GetMemSig("PlayerState", &pAddress) || !pAddress)
        {
            return pContext->ThrowNativeError("Failed to resolve PlayerState signature");
        }

        SourceMod::PassInfo Pass[1];
        Pass[0].flags = PASSFLAG_BYVAL;
        Pass[0].size = sizeof(int);
        Pass[0].type = PassType_Basic;

        pWrapper = g_pBinTools->CreateCall(pAddress, CallConv_ThisCall, NULL, Pass, 1);
        if (!pWrapper)
        {
            return pContext->ThrowNativeError("Failed to create PlayerState call wrapper");
        }
    }

    unsigned char vstk[sizeof(CBaseEntity *) + sizeof(int) + 16];
    memset(vstk, 0, sizeof(vstk));
    unsigned char *vptr = vstk;

#if defined(PLATFORM_X64) || defined(_WIN64)
    uintptr_t addr = (uintptr_t)vptr;
    addr = (addr + 15) & ~15;
    vptr = (unsigned char *)addr;
#endif

    *(CBaseEntity **)vptr = pEntity;
    vptr += sizeof(CBaseEntity *);

    *(int *)vptr = Params[2];

    pWrapper->Execute(vstk, NULL);

    return true;
}

cell_t Native_SetBombTargetState(IPluginContext *pContext, const cell_t *Params)
{
    edict_t *pEdict = g_pEngine->PEntityOfEntIndex(Params[1]);
    if (!pEdict)
    {
        return pContext->ThrowNativeError("Entity index %d is invalid", Params[1]);
    }

    CBaseEntity *pEntity = g_pGameEnts->EdictToBaseEntity(pEdict);
    if (!pEntity || strcmp(pEdict->GetClassName(), "dod_bomb_target") != 0)
    {
        return pContext->ThrowNativeError("Entity index %d is not a dod_bomb_target", Params[1]);
    }

    static ICallWrapper *pWrapper = NULL;

    if (!pWrapper)
    {
        void *pAddress = NULL;
        if (!g_pGameConf->GetMemSig("BombTargetState", &pAddress) || !pAddress)
        {
            return pContext->ThrowNativeError("Failed to resolve BombTargetState signature");
        }

        SourceMod::PassInfo Pass[1];
        Pass[0].flags = PASSFLAG_BYVAL;
        Pass[0].size = sizeof(int);
        Pass[0].type = PassType_Basic;

        pWrapper = g_pBinTools->CreateCall(pAddress, CallConv_ThisCall, NULL, Pass, 1);
        if (!pWrapper)
        {
            return pContext->ThrowNativeError("Failed to create BombTargetState call wrapper");
        }
    }

    unsigned char vstk[sizeof(CBaseEntity *) + sizeof(int) + 16];
    memset(vstk, 0, sizeof(vstk));
    unsigned char *vptr = vstk;

#if defined(PLATFORM_X64) || defined(_WIN64)
    uintptr_t addr = (uintptr_t)vptr;
    addr = (addr + 15) & ~15;
    vptr = (unsigned char *)addr;
#endif

    *(CBaseEntity **)vptr = pEntity;
    vptr += sizeof(CBaseEntity *);

    *(int *)vptr = Params[2];

    pWrapper->Execute(vstk, NULL);

    return true;
}

/* ============================================================================
 * Native dispatch table
 * ========================================================================== */

const sp_nativeinfo_t g_Natives[] =
{
    {"DOD_GetPlayerClass",         Native_GetPlayerClass},
    {"DOD_SetPlayerClass",         Native_SetPlayerClass},
    {"DOD_GetDesiredPlayerClass",  Native_GetDesiredPlayerClass},
    {"DOD_SetDesiredPlayerClass",  Native_SetDesiredPlayerClass},
    {"DOD_PopHelmet",              Native_PopHelmet},
    {"DOD_SetNumControlPoints",    Native_SetNumControlPoints},
    {"DOD_PrecacheCPIcon",         Native_PrecacheCPIcon},
    {"DOD_SetCPIcons",             Native_SetCPIcons},
    {"DOD_SetCPVisible",           Native_SetCPVisible},
    {"DOD_PauseTimer",             Native_PauseTimer},
    {"DOD_ResumeTimer",            Native_ResumeTimer},
    {"DOD_SetTimeRemaining",       Native_SetTimeRemaining},
    {"DOD_GetTimeRemaining",       Native_GetTimeRemaining},
    {"DOD_RespawnPlayer",          Native_RespawnPlayer},
    {"DOD_AddWaveTime",            Native_AddWaveTime},
    {"DOD_SetWinningTeam",         Native_SetWinningTeam},
    {"DOD_SetRoundState",          Native_SetRoundState},
    {"DOD_SetPlayerState",         Native_SetPlayerState},
    {"DOD_SetBombTargetState",     Native_SetBombTargetState},
    {NULL, NULL},
};
