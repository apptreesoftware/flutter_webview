import 'package:flutter/material.dart';
import 'package:flutter_web_view/flutter_web_view.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _redirectedToUrl;
  FlutterWebView flutterWebView = new FlutterWebView();
  bool _isLoading = false;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget leading;
    if (_isLoading) {
      leading = new CircularProgressIndicator();
    }
    var app = new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          leading: leading,
          actions: [
            new IconButton(icon: new Icon(Icons.refresh), onPressed: _refreshPage),
            new FlatButton(onPressed: _changeDomain, child: new Text("Switch App")),

          ],
        ),
        body: new Text("Redirected to $_redirectedToUrl"),
      ),
    );
    if (_redirectedToUrl == null) {
      launchWebViewExample(context);
    }
    return app;
  }

  void _refreshPage() {
    reload();
  }

  void _changeDomain() {
    print("Change domain hit");
  }

  void launchWebViewExample(BuildContext context) {
    if (flutterWebView.isLaunched) {
      return;
    }

    flutterWebView.launch(yOffset: 72.0);
    reload();
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
  }

  void reload() {
    flutterWebView.load(
        "https://authenticate.apptreesoftware.com/login?redirect=mobile://test.com",
        headers: {
          "X-APPTREE-APPLICATION-ID": "johns.app",
          "X-APPTREE-VERSION": "1",
          "X-APPTREE-DEVICE-ID": "12345"
        });
  }
}
