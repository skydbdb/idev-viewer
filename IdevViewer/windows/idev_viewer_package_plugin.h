#ifndef PLUGIN_NAME_PLUGIN_H_
#define PLUGIN_NAME_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace idev_viewer_package {

class IdevViewerPackagePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  IdevViewerPackagePlugin();

  virtual ~IdevViewerPackagePlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace idev_viewer_package

#endif  // PLUGIN_NAME_PLUGIN_H_
