#include "desktop_session.h"

#include <dwmapi.h>

#include <string>
#include <vector>

namespace {
constexpr wchar_t kInstance[] = L"Local\\com.growthrecord.shiyu";
constexpr wchar_t kWindowProperty[] = L"com.growthrecord.shiyu.primary";
constexpr wchar_t kRunKey[] = L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
constexpr wchar_t kStartupEntry[] = L"Shiyu";

BOOL CALLBACK FindInstance(HWND window, LPARAM result) {
  if (GetPropW(window, kWindowProperty) == nullptr) return TRUE;
  *reinterpret_cast<HWND*>(result) = window;
  return FALSE;
}
}  // namespace

DesktopSession::DesktopSession() {
  mutex_ = CreateMutexW(nullptr, FALSE, kInstance);
  primary_ = mutex_ != nullptr && GetLastError() != ERROR_ALREADY_EXISTS;
}

DesktopSession::~DesktopSession() {
  if (mutex_ != nullptr) CloseHandle(mutex_);
}

void DesktopSession::Attach(HWND window) const {
  SetPropW(window, kWindowProperty, reinterpret_cast<HANDLE>(static_cast<INT_PTR>(1)));
}

void DesktopSession::NotifyExisting(const std::string& pack_path) const {
  for (int attempt = 0; attempt < 60; ++attempt) {
    HWND window = nullptr;
    EnumWindows(FindInstance, reinterpret_cast<LPARAM>(&window));
    if (window != nullptr) {
      if (pack_path.empty() || pack_path.size() > kShiyuPackPathLimit) {
        PostMessageW(window, kShiyuReopen, 0, 0);
      } else {
        COPYDATASTRUCT payload{
            kShiyuPackMessage, static_cast<DWORD>(pack_path.size()),
            const_cast<char*>(pack_path.data())};
        SendMessageTimeoutW(window, WM_COPYDATA, 0,
                            reinterpret_cast<LPARAM>(&payload),
                            SMTO_ABORTIFHUNG, 2000, nullptr);
      }
      return;
    }
    Sleep(30);
  }
}

bool IsExternalFullscreen() {
  const HWND foreground = GetForegroundWindow();
  if (foreground == nullptr || !IsWindowVisible(foreground) || IsIconic(foreground)) return false;
  DWORD owner = 0;
  GetWindowThreadProcessId(foreground, &owner);
  if (owner == GetCurrentProcessId() || foreground == GetShellWindow()) return false;
  if (IsZoomed(foreground) && (GetWindowLongPtrW(foreground, GWL_STYLE) & WS_CAPTION)) {
    return false;
  }
  RECT frame{};
  if (FAILED(DwmGetWindowAttribute(foreground, DWMWA_EXTENDED_FRAME_BOUNDS,
                                   &frame, sizeof(frame))) &&
      !GetWindowRect(foreground, &frame)) return false;
  MONITORINFO monitor{};
  monitor.cbSize = sizeof(monitor);
  if (!GetMonitorInfoW(MonitorFromWindow(foreground, MONITOR_DEFAULTTONEAREST), &monitor)) {
    return false;
  }
  const RECT& screen = monitor.rcMonitor;
  return frame.left <= screen.left && frame.top <= screen.top &&
         frame.right >= screen.right && frame.bottom >= screen.bottom;
}

bool StartupEnabled() {
  DWORD bytes = 0;
  return RegGetValueW(HKEY_CURRENT_USER, kRunKey, kStartupEntry, RRF_RT_REG_SZ,
                      nullptr, nullptr, &bytes) == ERROR_SUCCESS;
}

bool SetStartupEnabled(bool enabled) {
  if (!enabled) {
    const LSTATUS status = RegDeleteKeyValueW(HKEY_CURRENT_USER, kRunKey, kStartupEntry);
    return status == ERROR_SUCCESS || status == ERROR_FILE_NOT_FOUND;
  }
  std::vector<wchar_t> executable(32768);
  const DWORD count = GetModuleFileNameW(nullptr, executable.data(),
                                         static_cast<DWORD>(executable.size()));
  if (count == 0 || count == executable.size()) return false;
  const std::wstring command = L"\"" + std::wstring(executable.data(), count) + L"\"";
  return RegSetKeyValueW(HKEY_CURRENT_USER, kRunKey, kStartupEntry, REG_SZ,
                         command.c_str(),
                         static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t))) == ERROR_SUCCESS;
}
