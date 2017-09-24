#import <Flutter/Flutter.h>

@class WebViewController;
//@class EventStreamHandler;

@interface FlutterWebViewPlugin : NSObject <FlutterPlugin>
@property WebViewController *webViewController;
@property UIViewController *hostViewController;
@property FlutterMethodChannel *methodChannel;

- (void)handleToolbar:(UIBarButtonItem *)item;

- (void)handleWebViewLoadError:(NSString *)errorString;
- (void)handleRedirect:(NSString *)url;
- (void)handleWebViewDidStartLoad:(NSString *)url;
- (void)handleWebViewDidFinishLoad:(NSString *)url;
@end
