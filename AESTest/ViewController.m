#import "ViewController.h"

@interface ViewController ()

@property (nonatomic) UILabel *datareceived;

@property (nonatomic) HTTPService *httpService;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor whiteColor];

    self.httpService = [[HTTPService alloc] init];
    self.httpService.delegate = self;
    
    UIButton *sendDataWithRsa = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sendDataWithRsa addTarget:self action:@selector(sendRequestWithRsaCertificate) forControlEvents:UIControlEventTouchUpInside];
    [sendDataWithRsa setTitle:@"Send ping request with rsa" forState:UIControlStateNormal];
    sendDataWithRsa.frame = CGRectMake(10, 80, 200, 50);
    [self.view addSubview:sendDataWithRsa];

    UIButton *sendDataWithEc = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sendDataWithEc addTarget:self action:@selector(sendRequestWithEcCertificate) forControlEvents:UIControlEventTouchUpInside];
    [sendDataWithEc setTitle:@"Send ping request with ec" forState:UIControlStateNormal];
    sendDataWithEc.frame = CGRectMake(CGRectGetMinX(sendDataWithRsa.frame) + 220, 80, 200, 50);
    [self.view addSubview:sendDataWithEc];

    self.datareceived = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(sendDataWithRsa.frame), CGRectGetMinY(sendDataWithRsa.frame) + 20, 600, 200)];
    [self.view addSubview:self.datareceived];
    self.datareceived.text = @"";
}

-(void)sendRequestWithRsaCertificate {
    ConnectionDelegate *delegate = [[ConnectionDelegate alloc] initWithP12FileName:@"ipad"];


    [self.httpService pingMessage:delegate];
}

-(void)sendRequestWithEcCertificate {
    ConnectionDelegate *delegate = [[ConnectionDelegate alloc] initWithP12FileName:@"ipad_ec"];


    [self.httpService pingMessage:delegate];
}

- (void)gotResponse:(NSString *)response {
    self.datareceived.text = [NSString stringWithFormat:@"Service responded: %@", response];
}

@end
