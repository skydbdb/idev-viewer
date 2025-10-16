package com.idev.viewer

import android.content.Context
import android.webkit.*
import android.view.View
import android.widget.FrameLayout
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformView
import org.json.JSONObject

class IdevViewerPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private var context: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "idev_viewer")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

class IdevViewerView(private val context: Context, private val viewId: Int, private val options: Map<String, Any>) : PlatformView {
    private val webView: WebView
    private val container: FrameLayout

    init {
        container = FrameLayout(context)
        webView = WebView(context).apply {
            settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                allowFileAccess = true
                allowContentAccess = true
                setRenderPriority(WebSettings.RenderPriority.HIGH)
                cacheMode = WebSettings.LOAD_DEFAULT
                mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            }

            addJavascriptInterface(WebAppInterface(), "Android")

            webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    initializeViewer()
                }

                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    return false
                }
            }

            loadUrl("file:///android_asset/idev-app/index.html")
        }

        container.addView(webView)
    }

    private fun initializeViewer() {
        val template = options["template"] as? Map<String, Any>
        val config = options["config"] as? Map<String, Any>

        val initScript = """
            if (typeof IdevViewer !== 'undefined') {
                window.idevViewer = new IdevViewer({
                    width: '100%',
                    height: '100%',
                    idevAppPath: './idev-app/',
                    template: ${template?.let { JSONObject(it).toString() } ?: "null"},
                    config: ${config?.let { JSONObject(it).toString() } ?: "{}"},
                    onReady: function(data) {
                        Android.onViewerReady('$viewId', JSON.stringify(data));
                    },
                    onError: function(error) {
                        Android.onViewerError('$viewId', error);
                    }
                });
                
                window.idevViewer.mount(document.body);
            }
        """.trimIndent()

        webView.evaluateJavascript(initScript, null)
    }

    override fun getView(): View = container

    override fun dispose() {
        webView.destroy()
    }

    inner class WebAppInterface {
        @JavascriptInterface
        fun onViewerReady(viewId: String, data: String) {
            // Flutter로 메시지 전송
        }

        @JavascriptInterface
        fun onViewerError(viewId: String, error: String) {
            // Flutter로 에러 메시지 전송
        }
    }
}
