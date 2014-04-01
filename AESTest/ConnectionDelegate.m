#import "ConnectionDelegate.h"

@interface ConnectionDelegate ()

@property(nonatomic) NSOutputStream *fileStream;
@property (nonatomic) NSString *p12filename;
@end

@implementation ConnectionDelegate

- (instancetype)initWithP12FileName:(NSString*)filename {
    if (self = [super init]) {
        self.fileStream = [NSOutputStream outputStreamToMemory];
        self.p12filename = filename;
        [self.fileStream open];
    }
    return self;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {

    NSLog(@"Authmethod is %@", challenge.protectionSpace.authenticationMethod);
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        // TODO: validate against trusted root for application in "ca.der"
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    } else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        // ipad.p12 works, and has an RSA key. ipad_ec.p12 fails, and
        NSData *p12Data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:self.p12filename ofType:@"p12"]];

        const void *keys[] = {kSecImportExportPassphrase};
        CFStringRef password = CFSTR(""); // Use blank password even if p12 has 'no password'
        const void *values[] = {password};
        CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
        OSStatus securityError = SecPKCS12Import((__bridge CFDataRef) p12Data, options, &items);

        if (securityError) {
            NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:securityError userInfo:nil];
            NSLog(@"%@", error.localizedDescription);
            [challenge.sender cancelAuthenticationChallenge:challenge];
        }

        CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
        SecIdentityRef identity = (SecIdentityRef) CFDictionaryGetValue(identityDict, CFSTR("identity"));

        SecCertificateRef certificateForIdentity = NULL;
        SecIdentityCopyCertificate(identity, &certificateForIdentity);
        if (securityError == errSecSuccess) {
            NSLog(@"Success opening p12 certificate. Items: %ld", CFArrayGetCount(items));
            CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
            identity = (SecIdentityRef) CFDictionaryGetValue(identityDict, kSecImportItemIdentity);
        } else {
            NSLog(@"Error opening Certificate.");
        }

        NSURLCredential *successCredential = [NSURLCredential credentialWithIdentity:identity
                                                                        certificates:@[(__bridge_transfer id)
                                                                                certificateForIdentity]
                                                                         persistence:NSURLCredentialPersistenceNone];
        [challenge.sender useCredential:successCredential forAuthenticationChallenge:challenge];
    } else {
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    return NO;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"FAILED %@", error);
    [self.delegate connectionFinished:@"error with connection"];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"Connection finished loading");
    NSData *retData = [self.fileStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    NSString *returnString = [[NSString alloc] initWithData:retData encoding:NSUTF8StringEncoding];
    [self.delegate connectionFinished:returnString];
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
    NSLog(@"Received data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

    NSInteger dataLength;
    const uint8_t *dataBytes;
    NSInteger bytesWritten;
    NSInteger bytesWrittenSoFar;

    dataLength = [data length];
    dataBytes = [data bytes];

    bytesWrittenSoFar = 0;
    do {
        bytesWritten = [self.fileStream write:&dataBytes[bytesWrittenSoFar] maxLength:dataLength - bytesWrittenSoFar];
        assert(bytesWritten != 0);
        if (bytesWritten == -1) {
            NSLog(@"ERROR");
            break;
        } else {
            bytesWrittenSoFar += bytesWritten;
        }
    } while (bytesWrittenSoFar != dataLength);
}

@end
