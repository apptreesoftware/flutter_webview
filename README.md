# Flutter Web View

A web view plugin for Flutter. Works with iOS and Android

Features

 - [x] Load Web Pages
 - [x] Reload/Load new pages while WebView still active
 - [x] Listen for Redirects
 - [x] Add buttons to a navigation bar
 - [x] Receive call backs for nav buttons pressed
 - [x] WebView loading callbacks
 - [x] Supports custom nav bar & button colors ( ios only for now )
 - [ ] Advanced nav bar support ( position , enable, disable buttons )
 - [ ] Support for nav bar icon buttons
 - [ ] WebView history support
 - [ ] Android back button customization
 - [ ] Built in controls for WebView navigation
 
Feature requests welcome.


### Android Support
To use on Android, make sure to add the the following in your AndroidManifest.xml

```
<activity android:name="com.apptreesoftware.flutterwebview.WebViewActivity">
</activity>
```

### Example Usage

```
flutterWebView.launch(
        "https://apptreesoftware.com",
        headers: {
          "X-SOME-HEADER": "MyCustomHeader",
        },
        javaScriptEnabled: false,
        toolbarActions: [
          new ToolbarAction("Dismiss", 1),
          new ToolbarAction("Reload", 2)
        ],
        barColor: Colors.green,
        tintColor: Colors.white);
    flutterWebView.onToolbarAction.listen((identifier) {
      switch (identifier) {
        case 1:
          flutterWebView.dismiss();
          break;
        case 2:
          reload();
          break;
      }
    });
    flutterWebView.listenForRedirect("mobile://test.com", true);

    flutterWebView.onWebViewDidStartLoading.listen((url) {
      setState(() => _isLoading = true);
    });
    flutterWebView.onWebViewDidLoad.listen((url) {
      setState(() => _isLoading = false);
    });
    flutterWebView.onRedirect.listen((url) {
      flutterWebView.dismiss();
      setState(() => _redirectedToUrl = url);
    });
```
