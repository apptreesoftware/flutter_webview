import 'dart:async';

import 'package:flutter/services.dart';

class FlutterWebView {
  static const MethodChannel _channel =
      const MethodChannel('plugins.apptreesoftware.com/web_view');
  bool _launched = false;
  bool get isLaunched => _launched;
  Stream _eventStream;

  static const EventChannel _eventChannel =
      const EventChannel('plugins.apptreesoftware.com/web_view_events');

  void launch({List<ToolbarAction> toolbarActions, double yOffset = 0.0}) {
//    List<Map> actions = [];
//    if (toolbarActions != null) {
//      actions = toolbarActions.map((t) => t.toMap).toList();
//    }
    var args = {"yOffset": yOffset};
    _launched = true;
    _channel.invokeMethod('launch', args);
  }

  void dismiss() {
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

  Stream get eventStream {
    if (_eventStream == null) {
      _eventStream = _eventChannel.receiveBroadcastStream();
    }
    return _eventStream;
  }

  Stream<String> get onRedirect => eventStream
      .asBroadcastStream()
      .where((map) => map["event"] == "redirect")
      .map((map) => map["url"]);

  Stream<int> get onToolbarAction => eventStream
      .asBroadcastStream()
      .where((map) => map['event'] == "toolbar")
      .map((map) => map['identifier']);

  Stream<String> get onLoadError => eventStream
      .asBroadcastStream()
      .where((map) => map['event'] == "webViewDidError")
      .map((map) => map['error']);

  Stream<String> get onWebViewDidStartLoading => eventStream
      .asBroadcastStream()
      .where((map) => map['event'] == "webViewDidStartLoad")
      .map((map) => map['url']);

  Stream<String> get onWebViewDidLoad => eventStream
      .asBroadcastStream()
      .where((map) => map['event'] == "webViewDidLoad")
      .map((map) => map['url']);
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
