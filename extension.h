/**
 * vim: set ts=4 :
 * ======================================================
 * DODHooks - Detours & Natives for Day of Defeat: Source
 * ======================================================
 *
 * GPLv2 License
 */

#ifndef _INCLUDE_SOURCEMOD_EXTENSION_PROPER_H_
#define _INCLUDE_SOURCEMOD_EXTENSION_PROPER_H_

#include <sourcemod_version.h>
#include <ISDKTools.h>
#include <IBinTools.h>
#include <IForwardSys.h>
#include <IPlayerHelpers.h>
#include <IGameHelpers.h>
#include <IEngineTrace.h>
#include <iconvar.h>
#include <IServer.h>
#include <convar.h>
#include <sourcemod.h>
#include <smsdk_ext.h>

/* HL2SDK public headers providing types used by this extension. */
#include <networkstringtabledefs.h>
#include <edict.h>

/**
 * @brief Helper to read/write an entity member at a byte offset.
 * Produces an lvalue so it can be used on both the left and right hand side.
 */
#define OFFSET(type, base, offset) (*(type *)((unsigned char *)(base) + (offset)))

/**
 * Convenience macros - new style uses the global interfaces directly
 * where available, with fallbacks for older SM versions.
 */
#if SM_VERSION_MINOR >= 12
// SourceMod 1.12+ provides these globals directly
#define g_pGameHelpers gamehelpers
#define g_pEngine     engine
#define g_pGameConfs  gameconfs
#else
// Older SM - need to use the interface manager
#define g_pGameHelpers gamehelpers
#define g_pEngine     engine
#define g_pGameConfs  gameconfs
#endif

extern IGameConfig *g_pGameConf;

extern CGlobalVars *g_pGlobals;

extern IBinTools *g_pBinTools;
extern ISDKTools *g_pSDKTools;

extern IServerGameEnts *g_pGameEnts;

extern CSharedEdictChangeInfo *g_pSharedChangeInfo;

extern INetworkStringTableContainer *netstringtables;

extern uint32 g_iOffset_PlayerClass;
extern uint32 g_iOffset_DesiredPlayerClass;

extern uint32 g_iOffset_NumControlPoints;
extern uint32 g_iOffset_AlliesIcons;
extern uint32 g_iOffset_AxisIcons;
extern uint32 g_iOffset_NeutralIcons;
extern uint32 g_iOffset_TimerCapIcons;
extern uint32 g_iOffset_BombedIcons;
extern uint32 g_iOffset_CPIsVisible;

extern uint32 g_iOffset_TimerPaused;
extern uint32 g_iOffset_TimeRemaining;
extern uint32 g_iOffset_TimerEndTime;

extern void *g_pEntList;

extern void **g_pObjectiveResource;

#define DOD_MAXPLAYERS 33

#define MAX_CONTROL_POINTS 8

/**
 * Macro to simplify detour creation with proper error reporting.
 * Compatible with both 32-bit and 64-bit builds.
 */
#define CREATE_DETOUR(detour, name, gamedata) \
	do { \
		detour = DETOUR_CREATE_MEMBER(name, gamedata); \
		if (detour != NULL) \
		{ \
			detour->EnableDetour(); \
		} \
		else \
		{ \
			if (szConfigError[0]) \
			{ \
				snprintf(error, maxlength, "Fatal Error: Unable to load detour - %s (%s)", gamedata, szConfigError); \
			} \
			else \
			{ \
				snprintf(error, maxlength, "Fatal Error: Unable to load detour - %s", gamedata); \
			} \
			return false; \
		} \
	} while (0)

#define REMOVE_DETOUR(detour) \
	do { \
		if (detour != NULL) \
		{ \
			detour->Destroy(); \
			detour = NULL; \
		} \
	} while (0)

/**
 * Player class enum - matches DoD:S internal values
 */
enum DODPlayerClass
{
    PlayerClass_Random = -2,
    PlayerClass_None,
    PlayerClass_Rifleman,
    PlayerClass_Assault,
    PlayerClass_Support,
    PlayerClass_Sniper,
    PlayerClass_Machinegunner,
    PlayerClass_Rocket,

    PlayerClass_Size
};

/**
 * Team enum
 */
enum DODTeam
{
    Team_Unassigned = 0,
    Team_Spectator = 1,
    Team_Allies    = 2,
    Team_Axis      = 3,
};

/**
 * Helper: get send property offset safely
 */
inline uint32 GetSendPropOffset(const char *szNetClass, const char *szPropName)
{
    sm_sendprop_info_t SendPropInfo;

    if (!g_pGameHelpers->FindSendPropInfo(szNetClass, szPropName, &SendPropInfo))
    {
        META_CONPRINTF("Fatal Error: Unable to get offset: %s::%s!\n", szNetClass, szPropName);
        return -1;
    }

    return SendPropInfo.actual_offset;
}

/**
 * @brief Main extension class
 */
class CDODHooks : public SDKExtension
{
public:
    /**
     * @brief Called when the command client is set.
     */
    void OnSetCommandClient(int client);

public:
    /**
     * @brief Called after the initial loading sequence.
     */
    virtual bool SDK_OnLoad(char *error, size_t maxlength, bool late) override;

    /**
     * @brief Called right before the extension is unloaded.
     */
    virtual void SDK_OnUnload() override;

    /**
     * @brief Called once all known extensions have been loaded.
     */
    virtual void SDK_OnAllLoaded() override;

#if defined SMEXT_CONF_METAMOD
    /**
     * @brief Called when Metamod is attached.
     */
    virtual bool SDK_OnMetamodLoad(SourceMM::ISmmAPI *ismm, char *error, size_t maxlength, bool late) override;
#endif

private:
    /**
     * @brief Helper to register all forwards.
     */
    void RegisterForwards();

    /**
     * @brief Helper to unregister all forwards.
     */
    void UnregisterForwards();

    /**
     * @brief Helper to setup all detours.
     */
    bool SetupDetours(char *error, size_t maxlength);

    /**
     * @brief Helper to teardown all detours.
     */
    void TeardownDetours();
};

#endif // _INCLUDE_SOURCEMOD_EXTENSION_PROPER_H_
