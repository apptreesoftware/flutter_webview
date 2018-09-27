import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

class FlutterWebView {
  static const MethodChannel _channel =
      const MethodChannel('plugins.apptreesoftware.com/web_view');
  bool _launched = false;
  bool get isLaunched => _launched;

  StreamController<String> _redirectStreamController =
      new StreamController.broadcast();
  StreamController<String> _errorStreamController =
      new StreamController.broadcast();
  StreamController<Map<dynamic, dynamic>> _loadEventStreamController =
      new StreamController.broadcast();
  StreamController<int> _toolbarActionStreamController =
      new StreamController.broadcast();

  void launch(
    String url, {
    Map<String, String> headers,
    bool javaScriptEnabled,
    bool inlineMediaEnabled,
    List<ToolbarAction> toolbarActions,
    Color tintColor,
    Color barColor,
    bool clearCookies = false,
  }) {
    _channel.setMethodCallHandler(_handlePlatformMessages);
    Map<String, dynamic> params = {"url": url};
    _launched = true;
    if (headers != null) {
      params["headers"] = headers;
    }
    List<Map> actions = [];
    if (toolbarActions != null) {
      actions = toolbarActions.map((t) => t.toMap).toList();
    }
    params["actions"] = actions;
    if (tintColor != null) {
      params["tint"] = "${tintColor.red},${tintColor.green},${tintColor.blue}";
    }
    if (barColor != null) {
      params["barTint"] = "${barColor.red},${barColor.green},${barColor.blue}";
    }
    if (javaScriptEnabled != null) {
      params["javaScriptEnabled"] = javaScriptEnabled;
    }
    if (inlineMediaEnabled != null) {
      params["inlineMediaEnabled"] = inlineMediaEnabled;
    }
    if (clearCookies) {
      params["clearCookies"] = clearCookies;
    }
    _channel.invokeMethod('launch', params);
  }

  void dismiss() {
    _launched = false;
    _channel.invokeMethod('dismiss');
  }

  void load(String url, {Map<String, String> headers}) {
    Map<String, dynamic> params = {"url": url};
    if (headers != null) {
      params["headers"] = headers;
    }
    _channel.invokeMethod('load', params);
  }

  void listenForRedirect(String url, bool stopLoadOnRedirect) {
    _channel.invokeMethod(
        'onRedirect', {"url": url, "stopOnRedirect": stopLoadOnRedirect});
  }

  Stream<String> get onRedirect => _redirectStreamController.stream;

  Stream<int> get onToolbarAction => _toolbarActionStreamController.stream;

  Stream<String> get onLoadError => _errorStreamController.stream;

  Stream<String> get onWebViewDidStartLoading =>
      _loadEventStreamController.stream
          .where((map) => map['event'] == "webViewDidStartLoad")
          .map((map) => map['url']);

  Stream<String> get onWebViewDidLoad => _loadEventStreamController.stream
      .where((map) => map['event'] == "webViewDidLoad")
      .map((map) => map['url']);

  //Platform method handling

  Future<Null> _handlePlatformMessages(MethodCall call) async {
    switch (call.method) {
      case "onError":
        _errorStreamController.add(call.arguments);
        break;
      case "onLoadEvent":
        _loadEventStreamController.add(call.arguments);
        break;
      case "onToolbarAction":
        _toolbarActionStreamController.add(call.arguments);
        break;
      case "onRedirect":
        _redirectStreamController.add(call.arguments);
        break;
      default:
        break;
    }
  }
}

class ToolbarAction {
  final String title;
  final int identifier;

  /// Show the button in the toolbar only if there is room.
  /// DEFAULTS to false
  /// Only works on Android
  bool showIfRoom = false;

  ToolbarAction(this.title, this.identifier);

  Map get toMap => {"title": title, "identifier": identifier};
}
