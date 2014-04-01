#import <Foundation/Foundation.h>
#import "ConnectionDelegate.h"

@protocol HTTPServiceDelegate

- (void)gotResponse:(NSString *)response;

@end

@interface HTTPService : NSObject <ConnectionDelegateDelegate>

@property  (nonatomic, weak) id<HTTPServiceDelegate> delegate;

-(void)pingMessage:(ConnectionDelegate *) delegate;
@end
