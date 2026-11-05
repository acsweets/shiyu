#include "desktop_geometry.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <cmath>

namespace {
using Value = flutter::EncodableValue;
using List = flutter::EncodableList;

bool Coordinate(const Value& value, int& out) {
  const double* number = std::get_if<double>(&value);
  if (number == nullptr || !std::isfinite(*number) || std::abs(*number) > 1000000) {
    return false;
  }
  out = static_cast<int>(std::lround(*number));
  return true;
}
}  // namespace

void RegisterDesktopGeometry(flutter::BinaryMessenger* messenger, HWND window) {
  flutter::MethodChannel<Value> channel(messenger, "shiyu/placement",
                                         &flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler([window](const auto& call, auto result) {
    const auto& method = call.method_name();
    if (method == "show") {
      const bool* inactive = std::get_if<bool>(call.arguments());
      if (inactive != nullptr) {
        const int command = *inactive ? SW_SHOWNOACTIVATE : (IsIconic(window) ? SW_RESTORE : SW_SHOW);
        ShowWindow(window, command);
        if (!*inactive) SetForegroundWindow(window);
        result->Success();
        return;
      }
    } else if (method == "read") {
      RECT rect{};
      if (GetWindowRect(window, &rect)) {
        result->Success(Value(List{Value(double(rect.left)), Value(double(rect.top)),
                                    Value(double(rect.right - rect.left)),
                                    Value(double(rect.bottom - rect.top))}));
        return;
      }
    } else if (method == "cursor") {
      POINT point{};
      if (GetCursorPos(&point)) {
        result->Success(Value(List{Value(double(point.x)), Value(double(point.y))}));
        return;
      }
    } else if (method == "move" || method == "write") {
      const auto* list = std::get_if<List>(call.arguments());
      const bool move = method == "move";
      const size_t expected = move ? 2 : 4;
      int x = 0, y = 0, width = 0, height = 0;
      if (list != nullptr && list->size() == expected &&
          Coordinate((*list)[0], x) && Coordinate((*list)[1], y) &&
          (move || (Coordinate((*list)[2], width) && Coordinate((*list)[3], height) &&
                    width > 0 && height > 0))) {
        const UINT flags = SWP_NOACTIVATE | SWP_NOZORDER | (move ? SWP_NOSIZE : 0);
        if (SetWindowPos(window, nullptr, x, y, width, height, flags)) {
          result->Success();
          return;
        }
      }
    } else {
      result->NotImplemented();
      return;
    }
    result->Error("desktop_geometry");
  });
}
