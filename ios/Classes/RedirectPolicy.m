//
// Created by Matthew Smith on 9/17/17.
//

#import "RedirectPolicy.h"


@implementation RedirectPolicy {
}

- (id)initWithUrl:(NSString *)url matchType:(MatchType)matchType stopOnRedirect:(BOOL)stop {
    self = [super init];
    if (self) {
        self.url = url;
        self.matchType = matchType;
        self.stopOnRedirect = stop;
    }
    return self;
}
@end