#import "HTTPService.h"

@implementation HTTPService

- (void)pingMessage:(ConnectionDelegate *) delegate {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://localhost/ping.txt"]];
    [req setHTTPMethod:@"GET"];
    
    delegate.delegate = self;

    [[NSURLConnection alloc] initWithRequest:req delegate:delegate startImmediately:YES];
}

- (void)connectionFinished:(NSString *)response {
    [self.delegate gotResponse:response];
}

@end
