#import "FlutterWebViewPlugin.h"
#import "WebViewController.h"
#import "RedirectPolicy.h"

@implementation FlutterWebViewPlugin {
}
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:@"plugins.apptreesoftware.com/web_view"
                  binaryMessenger:[registrar messenger]];
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    FlutterWebViewPlugin *instance = [[FlutterWebViewPlugin alloc]
            initWithViewController:viewController channel: channel];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (id)initWithViewController:(UIViewController *)viewController channel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        self.hostViewController = viewController;
        self.methodChannel = channel;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"launch"]) {
        NSArray *actions = call.arguments[@"actions"];
        NSString *tint = call.arguments[@"tint"];
        UIColor *tintColor = [self parseNavColor:tint];
        NSString *barTint = call.arguments[@"barTint"];
        NSNumber *javaScriptEnabled = call.arguments[@"javaScriptEnabled"];
        NSNumber *mediaPlaybackEnabled = call.arguments[@"inlineMediaEnabled"];
        NSNumber *clearCookies = call.arguments[@"clearCookies"];
        BOOL mediaPlayback = false;
        if (mediaPlaybackEnabled) {
            mediaPlayback = [mediaPlaybackEnabled boolValue];
        }
        if (clearCookies.boolValue) {
         [[NSURLSession sharedSession] resetWithCompletionHandler:^{}];
        }
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
        self.webViewController = [[WebViewController alloc] initWithPlugin:self navItems:buttons allowMedia:mediaPlayback];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.webViewController];
        [self.hostViewController presentViewController:navigationController animated:true completion:nil];
        if (tintColor) {
            navigationController.navigationBar.tintColor = tintColor;
        }
        if (barTintColor) {
            navigationController.navigationBar.barTintColor = barTintColor;
        }
        [self performSelector:@selector(performLoad:) withObject:call.arguments afterDelay:0.4];
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
    [self.methodChannel invokeMethod:@"onToolbarAction" arguments:@(item.tag)];
}

- (void)handleWebViewLoadError:(NSString *)errorString {
    [self.methodChannel invokeMethod:@"onError" arguments:errorString];
}

- (void)handleRedirect:(NSString *)url {
    [self.methodChannel invokeMethod:@"onRedirect" arguments:url];
}

- (void)handleWebViewDidStartLoad:(NSString *)url {
    [self.methodChannel invokeMethod:@"onLoadEvent" arguments:@{@"event" : @"webViewDidStartLoad", @"url" : url}];
}

- (void)handleWebViewDidFinishLoad:(NSString *)url {
    [self.methodChannel invokeMethod:@"onLoadEvent" arguments:@{@"event" : @"webViewDidLoad", @"url" : url}];
}

@end

