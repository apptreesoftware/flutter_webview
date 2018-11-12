package com.apptreesoftware.flutterwebview

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.os.Build
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.webkit.*
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar


class FlutterWebViewPlugin(val activity: Activity) : MethodCallHandler {
    companion object {

        lateinit var channel: MethodChannel
        var currentActivity : WebViewActivity? = null

        var redirects = ArrayList<RedirectPolicy>()

        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {
            channel = MethodChannel(registrar.messenger(), "plugins.apptreesoftware.com/web_view")
            val plugin = FlutterWebViewPlugin(registrar.activity())
            channel.setMethodCallHandler(plugin)
            redirects.clear()
        }

        fun onLoadStarted(url: String) {
            channel.invokeMethod("onLoadEvent",
                                 mapOf("event" to "webViewDidStartLoad", "url" to url))
        }

        fun onLoadCompleted(url: String) {
            channel.invokeMethod("onLoadEvent",
                                 mapOf("event" to "webViewDidLoad", "url" to url))
        }

        fun onError(error: String) {
            channel.invokeMethod("onError", error)
        }

        fun onRedirect(url: String) {
            channel.invokeMethod("onRedirect", url)
        }

        fun onToolbarAction(actionId: Int) {
            channel.invokeMethod("onToolbarAction", actionId)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result): Unit {

        when (call.method) {
            "launch" -> {
                val actions: List<Map<String, Any>>? = call.argument("actions")
                val actionsArray = ArrayList<Map<String, Any>>()
                if (actions != null) {
                    actionsArray.addAll(actions)
                }
                //val tintColor = call.argument<String?>("tint")
                //val barColor = call.argument<String?>("barTint")

                val url = call.argument<String>("url")
                val javaScriptEnabled = call.argument("javaScriptEnabled") ?: false
                val inlineMediaEnabled = call.argument("inlineMediaEnabled") ?: false
                val clearCookies = call.argument("clearCookies") ?: false
                val headers = call.argument<Map<String, String>?>("headers")
                val hashMapHeaders = HashMap<String, String>()
                if (headers != null) {
                    hashMapHeaders.putAll(headers)
                }
                val intent = Intent(activity, WebViewActivity::class.java)
                intent.putExtra(WebViewActivity.EXTRA_URL, url)
                intent.putExtra(WebViewActivity.HEADERS, hashMapHeaders)
                intent.putExtra(WebViewActivity.ACTIONS, actionsArray)
                intent.putExtra(WebViewActivity.JAVASCRIPT_ENABLED, javaScriptEnabled)
                intent.putExtra(WebViewActivity.INLINE_MEDIA_ENABLED, inlineMediaEnabled)
                intent.putExtra(WebViewActivity.CLEAR_COOKIES, clearCookies)
                this.activity.startActivity(intent)
                result.success("")
            }
            "onRedirect" -> {
                val url = call.argument<String>("url") ?: throw RuntimeException("url must be provided")
                val stopOnRedirect = call.argument<Boolean>("stopOnRedirect") ?: true
                val policy = RedirectPolicy(url, stopOnRedirect, MatchType.PREFIX)
                redirects.add(policy)
                result.success("")
            }
            "dismiss" -> {
                currentActivity?.finish()
                currentActivity = null
            }
            "load" -> {
                val url = call.argument<String>("url") ?: throw RuntimeException("url must be provided")
                val headers = call.argument<Map<String, String>?>("headers")
                val hashMapHeaders = HashMap<String, String>()
                if (headers != null) {
                    hashMapHeaders.putAll(headers)
                }
                currentActivity?.load(url, hashMapHeaders)
            }
            else -> result.notImplemented()
        }
    }
}

class WebViewActivity : Activity() {

    companion object {
        val EXTRA_URL = "url"
        val ACTIONS = "actions"
        val HEADERS = "headers"
        val BAR_COLOR = "barColor"
        val INLINE_MEDIA_ENABLED = "inlineMediaEnabled"
        val JAVASCRIPT_ENABLED = "javaScriptEnabled"
        val CLEAR_COOKIES = "clearCookies"
    }

    lateinit var webView : WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        webView = WebView(this)
        title = ""
        setContentView(webView)
        webView.settings.javaScriptEnabled = intent.getBooleanExtra(JAVASCRIPT_ENABLED, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            webView.settings.mediaPlaybackRequiresUserGesture = intent.getBooleanExtra(
                INLINE_MEDIA_ENABLED, false)
        }
        webView.webViewClient = WebClient()
        if (clearCookies) {
            clearCookies()
        }
        webView.loadUrl(url, headers)
    }

    override fun onResume() {
        FlutterWebViewPlugin.currentActivity = this
        super.onResume()
    }

    fun load(url : String, headers : HashMap<String, String>) {
        intent.putExtra(WebViewActivity.EXTRA_URL, url)
        intent.putExtra(WebViewActivity.HEADERS, headers)
        webView.loadUrl(url, headers)
    }

    private fun clearCookies() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            CookieManager.getInstance().removeAllCookies { }
        } else {
            CookieManager.getInstance().removeAllCookie()
        }
    }

    val url: String get() = intent.extras.getString(WebViewActivity.EXTRA_URL)
    val headers: HashMap<String, String>
        get() = intent.getSerializableExtra(WebViewActivity.HEADERS) as HashMap<String, String>
    val actions: ArrayList<Map<String, Any>>
        get() = intent.getSerializableExtra(WebViewActivity.ACTIONS) as ArrayList<Map<String, Any>>
    val clearCookies : Boolean get() = intent.getBooleanExtra(WebViewActivity.CLEAR_COOKIES, false)

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        for ((index, action) in actions.withIndex()) {
            menu.add(0, action["identifier"] as Int, index, action["title"] as String)
        }
        return super.onCreateOptionsMenu(menu)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        FlutterWebViewPlugin.onToolbarAction(item.itemId)
        return super.onOptionsItemSelected(item)
    }

    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}

class WebClient : WebViewClient() {
    override fun onPageFinished(view: WebView?, url: String) {
        super.onPageFinished(view, url)
        FlutterWebViewPlugin.onLoadCompleted(url)
    }

    override fun onReceivedError(view: WebView?, request: WebResourceRequest?,
                                 error: WebResourceError?) {
        super.onReceivedError(view, request, error)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            FlutterWebViewPlugin.onError(
                error?.description?.toString() ?: "An error occurred loading this page")
        }
    }

    override fun onReceivedError(view: WebView?, errorCode: Int, description: String?,
                                 failingUrl: String?) {
        super.onReceivedError(view, errorCode, description, failingUrl)
        FlutterWebViewPlugin.onError(description ?: "An error occurred loading this page")
    }

    override fun onPageStarted(view: WebView?, url: String, favicon: Bitmap?) {
        super.onPageStarted(view, url, favicon)
        FlutterWebViewPlugin.onLoadStarted(url)
    }

    override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val url = request.url.toString()
            for (policy in FlutterWebViewPlugin.redirects) {
                if (policy.matchType == MatchType.PREFIX && url.startsWith(policy.url,
                                                                           ignoreCase = true)) {
                    FlutterWebViewPlugin.onRedirect(url)
                    return policy.stopOnRedirect
                } else if (policy.matchType == MatchType.SUFFIX && url.endsWith(policy.url,
                                                                                ignoreCase = true)) {
                    FlutterWebViewPlugin.onRedirect(url)
                    return policy.stopOnRedirect
                } else if (policy.matchType == MatchType.FULL_URL && url.equals(policy.url,
                                                                                ignoreCase = true)) {
                    FlutterWebViewPlugin.onRedirect(url)
                    return policy.stopOnRedirect
                }
            }
        }
        return false
    }

    override fun shouldOverrideUrlLoading(view: WebView?, url: String): Boolean {
        for (policy in FlutterWebViewPlugin.redirects) {
            if (policy.matchType == MatchType.PREFIX && url.startsWith(policy.url,
                                                                       ignoreCase = true)) {
                FlutterWebViewPlugin.onRedirect(url)
                return policy.stopOnRedirect
            } else if (policy.matchType == MatchType.SUFFIX && url.endsWith(policy.url,
                                                                            ignoreCase = true)) {
                FlutterWebViewPlugin.onRedirect(url)
                return policy.stopOnRedirect
            } else if (policy.matchType == MatchType.FULL_URL && url.equals(policy.url,
                                                                            ignoreCase = true)) {
                FlutterWebViewPlugin.onRedirect(url)
                return policy.stopOnRedirect
            }
        }
        return super.shouldOverrideUrlLoading(view, url)
    }
}
