import Flutter
import UIKit
import WebKit

public class IdevViewerPackagePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "idev_viewer", binaryMessenger: registrar.messenger())
        let instance = IdevViewerPackagePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let factory = IdevViewerFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "idev_viewer")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

class IdevViewerFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return IdevViewerView(frame: frame, viewId: viewId, args: args, messenger: messenger)
    }
}

class IdevViewerView: NSObject, FlutterPlatformView {
    private var webView: WKWebView
    private var viewId: Int64
    private var messenger: FlutterBinaryMessenger

    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        self.viewId = viewId
        self.messenger = messenger
        
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: frame, configuration: config)
        super.init()
        
        setupWebView()
        loadIDevApp()
    }

    func view() -> UIView {
        return webView
    }

    private func setupWebView() {
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        
        webView.configuration.userContentController.add(self, name: "idevViewer")
    }

    private func loadIDevApp() {
        guard let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "idev-app") else {
            print("❌ idev-app/index.html을 찾을 수 없습니다")
            return
        }
        
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}

extension IdevViewerView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        initializeViewer()
    }
    
    private func initializeViewer() {
        let script = """
            var script = document.createElement('script');
            script.src = './idev-viewer.js';
            script.onload = function() {
                if (typeof IdevViewer !== 'undefined') {
                    window.idevViewer = new IdevViewer({
                        width: '100%',
                        height: '100%',
                        idevAppPath: './idev-app/',
                        template: null,
                        config: {},
                        onReady: function(data) {
                            window.webkit.messageHandlers.idevViewer.postMessage({
                                type: 'ready',
                                viewId: \(viewId),
                                data: data
                            });
                        },
                        onError: function(error) {
                            window.webkit.messageHandlers.idevViewer.postMessage({
                                type: 'error',
                                viewId: \(viewId),
                                error: error
                            });
                        }
                    });
                    
                    window.idevViewer.mount(document.body);
                }
            };
            document.head.appendChild(script);
        """
        
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
}

extension IdevViewerView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? [String: Any],
              let type = messageBody["type"] as? String else {
            return
        }
        
        let channel = FlutterMethodChannel(name: "idev_viewer", binaryMessenger: messenger)
        
        switch type {
        case "ready":
            channel.invokeMethod("onReady", arguments: [
                "viewId": viewId,
                "data": messageBody["data"]
            ])
        case "error":
            channel.invokeMethod("onError", arguments: [
                "viewId": viewId,
                "error": messageBody["error"]
            ])
        default:
            break
        }
    }
}
