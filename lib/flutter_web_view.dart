import 'dart:async';

import 'package:flutter/services.dart';

class FlutterWebView {
  static const MethodChannel _channel =
      const MethodChannel('plugins.apptreesoftware.com/web_view');
  bool _launched = false;
  bool get isLaunched => _launched;

  static const EventChannel _eventChannel =
      const EventChannel('plugins.apptreesoftware.com/web_view_events');

  void launch({List<ToolbarAction> toolbarActions}) {
    List<Map> actions = [];
    if (toolbarActions != null) {
      actions = toolbarActions.map((t) => t.toMap).toList();
    }

    _launched = true;
    _channel.invokeMethod('launch', {"actions": actions});
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

  Stream get eventStream {
    return _eventChannel.receiveBroadcastStream();
  }

  Stream<String> get onRedirect => eventStream
      .where((map) => map["event"] == "redirect")
      .map((map) => map["url"]);

  Stream<int> get onToolbarAction => eventStream
      .where((map) => map['event'] == "toolbar")
      .map((map) => map['identifier']);

  Stream<String> get onLoadError => eventStream
      .where((map) => map['event'] == "webViewDidError")
      .map((map) => map['error']);

  Stream<String> get onWebViewDidStartLoading => eventStream
      .where((map) => map['event'] == "webViewDidStartLoad")
      .map((map) => map['url']);

  Stream<String> get onWebViewDidLoad => eventStream
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
