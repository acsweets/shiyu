#ifndef RUNNER_DESKTOP_SESSION_H_
#define RUNNER_DESKTOP_SESSION_H_

#include <windows.h>
#include <string>

constexpr UINT kShiyuReopen = WM_APP + 38;
constexpr UINT_PTR kShiyuFullscreenTimer = 539;
constexpr ULONG_PTR kShiyuPackMessage = 0x53485950;
constexpr size_t kShiyuPackPathLimit = 128 * 1024;

// Windows 会话内只保留一个主引擎，子浮窗仍由该进程创建。
class DesktopSession {
 public:
  DesktopSession();
  ~DesktopSession();

  bool IsPrimary() const { return primary_; }
  void Attach(HWND window) const;
  void NotifyExisting(const std::string& pack_path) const;

 private:
  HANDLE mutex_ = nullptr;
  bool primary_ = false;
};

bool IsExternalFullscreen();
bool StartupEnabled();
bool SetStartupEnabled(bool enabled);

#endif
