/**
 * vim: set ts=4 :
 * ======================================================
 * DODHooks - Detours & Natives for Day of Defeat: Source
 * ======================================================
 *
 * GPLv2 License
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 2.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#ifndef _INCLUDE_SOURCEMOD_EXTENSION_CONFIG_H_
#define _INCLUDE_SOURCEMOD_EXTENSION_CONFIG_H_

/**
 * @file smsdk_config.h
 * @brief Contains macros defining various aspects of the extension's build.
 *
 * Each extension must define:
 *   SMEXT_CONF_NAME        - Display name for the extension
 *   SMEXT_CONF_DESCRIPTION - Short description
 *   SMEXT_CONF_VERSION     - Version string (e.g. "1.5.0")
 *   SMEXT_CONF_AUTHOR      - Author name
 *   SMEXT_CONF_URL         - Project URL
 *   SMEXT_CONF_LOGTAG      - Short tag for log messages
 *   SMEXT_CONF_LICENSE     - License name
 *   SMEXT_CONF_DATESTRING  - Build date (auto-filled by build)
 */

#define SMEXT_CONF_NAME            "DODHooks"
#define SMEXT_CONF_DESCRIPTION     "SourceMod extension with Detours & Natives for Day of Defeat: Source"
#define SMEXT_CONF_VERSION         "1.6.0"
#define SMEXT_CONF_AUTHOR          "Andersso, ChesterSmitty, Apfelwurm, DNA-styx, Kittenks"
#define SMEXT_CONF_URL             "https://github.com/kittenks/dodhooks"
#define SMEXT_CONF_LOGTAG          "DODHOOKS"
#define SMEXT_CONF_LICENSE         "GPLv2"
#define SMEXT_CONF_DATESTRING      __DATE__

/**
 * @brief The interface version we expect from SourceMod.
 * SM 1.12+ uses this to ensure compatibility.
 */
#define SMEXT_ENABLE_FORWARDSYS

/**
 * @brief Enables the game config manager (g_pGameConfs / IGameConfig).
 */
#define SMEXT_ENABLE_GAMECONF

/**
 * @brief Enables the game helpers interface (g_pGameHelpers / IGameHelpers).
 */
#define SMEXT_ENABLE_GAMEHELPERS

/**
 * @brief Declares this extension as a Metamod:Source plugin so that the
 * engine (g_pEngine / IVEngineServer) and Metamod interfaces are available.
 * Targets Metamod:Source 1.12 (built against the 1.12-dev branch).
 */
#define SMEXT_CONF_METAMOD

/**
 * @brief Exposes the extension's main interface variable.
 */
#define SMEXT_LINK(name) SDKExtension *g_pExtensionIface = name;

#endif // _INCLUDE_SOURCEMOD_EXTENSION_CONFIG_H_
