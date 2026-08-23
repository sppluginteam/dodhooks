#include <sourcemod>
#include <sdktools>
#include "dodhooks.inc"

public void OnPluginStart()
{
    PrintToServer("[dodhooks-test] 插件启动，开始检测 dodhooks 扩展与 natives");

    bool extLoaded = false;

    if (IsExtensionLoaded("dodhooks.ext") || IsExtensionLoaded("dodhooks") || IsExtensionLoaded("DoD Hooks"))
    {
        PrintToServer("[dodhooks-test] 扩展被标记为已加载 (IsExtensionLoaded)");
        extLoaded = true;
    }
    else
    {
        PrintToServer("[dodhooks-test] IsExtensionLoaded 没有报告已加载状态，继续检查 native 绑定");
    }

    // 尝试使用 FindNative 检查是否有 PrecacheCPIcon
    Handle h = INVALID_HANDLE;
    if (FindNative("PrecacheCPIcon", h))
    {
        PrintToServer("[dodhooks-test] 找到 native PrecacheCPIcon，尝试调用进行测试");
        int idx = PrecacheCPIcon("sprites/obj_icons/icon_obj_allies.vmt");
        PrintToServer("[dodhooks-test] PrecacheCPIcon 返回 %d", idx);
        CloseHandle(h);
    }
    else
    {
        PrintToServer("[dodhooks-test] 未找到 native PrecacheCPIcon (插件可能无法调用扩展原生函数)");
    }

    if (!extLoaded)
    {
        PrintToServer("[dodhooks-test] 如果扩展应当随服务器自动加载但未检测到，请确认扩展文件 dodhooks.ext 已放在 extensions/ 下，并检查服务器日志。");
    }
}
