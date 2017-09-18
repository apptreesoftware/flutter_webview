#import <Flutter/Flutter.h>

@class WebViewController;
@class EventStreamHandler;

@interface FlutterWebViewPlugin : NSObject <FlutterPlugin>
@property WebViewController *webViewController;
@property UIViewController *hostViewController;
@property EventStreamHandler *eventStreamHandler;
@end

@interface EventStreamHandler : NSObject <FlutterStreamHandler>

- (void)sendRedirectEvent:(NSString *)url;
- (void)sendToolbarEvent:(NSInteger)identifier;
- (void)sendWebViewDidStartLoad:(NSString *)url;
- (void)sendWebViewDidFinishLoad:(NSString *)url;
- (void)sendDidFailLoadWithError:(NSString *)errorString;
@end
