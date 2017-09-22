#import "FlutterWebViewPlugin.h"
#import "WebViewController.h"
#import "RedirectPolicy.h"

@implementation FlutterWebViewPlugin {
}
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:@"plugins.apptreesoftware.com/web_view"
                  binaryMessenger:[registrar messenger]];
    FlutterWebViewPlugin *instance = [[FlutterWebViewPlugin alloc]
            initWithViewController:(UIViewController *)
                    registrar.messenger];
    [registrar addMethodCallDelegate:instance channel:channel];

    FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:@"plugins.apptreesoftware.com/web_view_events" binaryMessenger:registrar.messenger];
    [eventChannel setStreamHandler: instance.eventStreamHandler];
}

- (id)initWithViewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        self.hostViewController = viewController;
        self.eventStreamHandler = [[EventStreamHandler alloc] init];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"launch"]) {
        NSArray *actions = call.arguments[@"actions"];
        NSString *tint = call.arguments[@"tint"];
        UIColor *tintColor = [self parseNavColor:tint];
        NSString *barTint = call.arguments[@"barTint"];
        UIColor *barTintColor = [self parseNavColor:barTint];
        
        NSMutableArray *buttons = [NSMutableArray array];
        if (actions) {
            for (NSDictionary *action in actions) {
                UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:[action valueForKey:@"title"]
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(handleToolbar:)];
                button.tag = [[action valueForKey:@"identifier"] intValue];
                [buttons addObject:button];
            }
        }
        self.webViewController = [[WebViewController alloc] initWithPlugin:self navItems:buttons];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.webViewController];
        [self.hostViewController presentViewController:navigationController animated:true completion:nil];
        if (tintColor) {
            navigationController.navigationBar.tintColor = tintColor;
        }
        if (barTintColor) {
            navigationController.navigationBar.barTintColor = barTintColor;
        }
        result(@"");
        return;
    } else if ([call.method isEqualToString:@"dismiss"]) {
        [self.webViewController dismissViewControllerAnimated:true completion:nil];
        result(@"");
    } else if ([call.method isEqualToString:@"load"]) {
        [self performLoad:call.arguments];
        result(@"");
        return;
    } else if ([call.method isEqualToString:@"back"]) {
        [self.webViewController.webView goBack];
        result(@"");
    } else if ([call.method isEqualToString:@"forward"]) {
        [self.webViewController.webView goForward];
        result(@"");
    } else if ([call.method isEqualToString:@"onRedirect"]) {
        NSString *url = call.arguments[@"url"];
        NSNumber *stopOnRedirect = call.arguments[@"stopOnRedirect"];
        RedirectPolicy *policy = [[RedirectPolicy alloc] initWithUrl:url matchType:PREFIX stopOnRedirect:stopOnRedirect.boolValue];
        [self.webViewController listenForRedirect:policy];
        result(@"");
    }
    result(FlutterMethodNotImplemented);
}


- (UIColor *)parseNavColor: (NSString *)colorString {
    if (!colorString) {
        return nil;
    }
    NSArray *components = [colorString componentsSeparatedByString:@","];
    NSString *r = components[0];
    NSString *g = components[1];
    NSString *b = components[2];
    
    return [UIColor colorWithRed:[r floatValue]/255.0 green:[g floatValue]/255.0 blue:[b floatValue]/255.0 alpha:1.0];
}

- (void)performLoad:(NSDictionary *)params {
    NSString *urlString = params[@"url"];
    NSDictionary *headers = params[@"headers"];
    [self.webViewController load:urlString withHeaders:headers];
}

- (void)handleToolbar:(UIBarButtonItem *)item {
    [self.eventStreamHandler sendToolbarEvent:item.tag];
}

@end

@implementation EventStreamHandler {
    FlutterEventSink _eventSink;
}

- (void)sendRedirectEvent:(NSString *)url {
    if(_eventSink) {
        _eventSink(@{@"event" : @"redirect", @"url" : url});
    }
}

- (void)sendWebViewDidStartLoad:(NSString *)url {
    if(_eventSink) {
        _eventSink(@{@"event" : @"webViewDidStartLoad", @"url" : url});
    }
}

- (void)sendWebViewDidFinishLoad:(NSString *)url {
    if(_eventSink) {
        _eventSink(@{@"event" : @"webViewDidLoad", @"url" : url});
    }
}

- (void)sendDidFailLoadWithError:(NSString *)errorString {
    if(_eventSink) {
        _eventSink(@{@"event" : @"webViewDidError", @"error" : errorString});
    }
}

- (void)sendToolbarEvent:(NSInteger)identifier {
    _eventSink(@{@"event" : @"toolbar", @"identifier" : @(identifier)});
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}


@end
