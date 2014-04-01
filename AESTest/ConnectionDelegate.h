#import <UIKit/UIKit.h>

@protocol ConnectionDelegateDelegate

- (void)connectionFinished:(NSString *)response;

@end

@interface ConnectionDelegate : NSObject  <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, weak) id<ConnectionDelegateDelegate> delegate;

- (instancetype)initWithP12FileName:(NSString *)filename;
@end
