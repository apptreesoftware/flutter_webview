//
// Created by Matthew Smith on 9/17/17.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FlutterWebViewPlugin;
@class RedirectPolicy;

@interface WebViewController : UIViewController<UIWebViewDelegate>

- (id)initWithPlugin:(FlutterWebViewPlugin *)plugin navItems:(NSArray *)navItems;
@property(nonatomic, weak) FlutterWebViewPlugin *plugin;
@property(nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSArray *navItems;

- (void)load:(NSString *)urlString withHeaders:(NSDictionary *)headers;
- (void)listenForRedirect:(RedirectPolicy *)redirect;

@end