//
// Created by Matthew Smith on 9/17/17.
//

#import <Foundation/Foundation.h>

typedef enum matchType
{
    PREFIX,
    SUFFIX,
    FULL_URL
} MatchType;

@interface RedirectPolicy : NSObject
@property (nonatomic, retain) NSString *url;
@property (nonatomic, assign) BOOL stopOnRedirect;
@property (nonatomic, assign) MatchType matchType;

- (id)initWithUrl:(NSString *)url matchType:(MatchType)matchType stopOnRedirect:(BOOL)stop;

@end