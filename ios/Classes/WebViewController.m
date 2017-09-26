//
// Created by Matthew Smith on 9/17/17.
//

#import "WebViewController.h"
#import "FlutterWebViewPlugin.h"
#import "RedirectPolicy.h"

@implementation WebViewController {
    NSMutableSet *redirects;

}

- (id)initWithPlugin:(FlutterWebViewPlugin *)plugin navItems:(NSArray *)navBarItems allowMedia:(BOOL)allowMedia {
    self = [super init];
    if (self) {
        self.plugin = plugin;
        redirects = [NSMutableSet set];
        self.navItems = navBarItems;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItems = self.navItems;
    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    self.webView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.webView.allowsInlineMediaPlayback = YES;
    [self.view addSubview:self.webView];
}

- (void)load:(NSString *)urlString withHeaders:(NSDictionary *)headers {
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    if (!url) {
        return;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    if (headers) {
        NSEnumerator *keyE = headers.keyEnumerator;
        NSString *key = keyE.nextObject;
        while (key) {
            [request addValue:[headers valueForKey:key] forHTTPHeaderField:key];
            key = keyE.nextObject;
        }
    }
    [_webView loadRequest:request];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *url = [request URL].absoluteString;

    for (RedirectPolicy *policy in redirects) {
        if (policy.matchType == PREFIX && [url hasPrefix:policy.url]) {
            [self.plugin handleRedirect: request.URL.absoluteString];
            return !policy.stopOnRedirect;
        } else if (policy.matchType == SUFFIX && [url hasSuffix:policy.url]) {
            [self.plugin handleRedirect:request.URL.absoluteString];
            return !policy.stopOnRedirect;
        } else if (policy.matchType == FULL_URL && [url isEqualToString:policy.url]) {
            [self.plugin handleRedirect:request.URL.absoluteString];
            return !policy.stopOnRedirect;
        }
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.plugin handleWebViewDidStartLoad:webView.request.URL.absoluteString];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.plugin handleWebViewDidFinishLoad:webView.request.URL.absoluteString];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.plugin handleWebViewLoadError:error.localizedDescription];
}

- (void)listenForRedirect:(RedirectPolicy *)redirect {
    [redirects addObject:redirect];
}

@end
