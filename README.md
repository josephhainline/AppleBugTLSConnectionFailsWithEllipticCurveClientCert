## Latest News
* Filed as Apple Rdar: 16482549, which Apple marked as a duplicate (Open) of 10450268, so Apple has known about this for a while.
* Please duplicate!  Details of the bug submission are at: http://openradar.appspot.com/radar?id=5276828226813952

## Instructions for replicating the EC TLS handshake bug in iOS

1. Install XCode and ruby.  We ran with XCode Version 5.1 (5B130a), and Ruby version ruby 1.9.3p362 (2012-12-25 revision 38607) [x86_64-darwin13.0.0]
    
2. Unzip the bugReport.zip file

   ```$ unzip bugReport.zip``` 
        
3. First, we'll connect to an HTTPS server configured to request a client certificate. 
   Running this command will start such a server, set up to respond to TLS connections
   with RSA certs or EC certs.
   
4. Launch the server with this command: (you need sudo because it runs on port 443)

    ```$  sudo openssl s_server -accept 443 -cert im_server.crt -key im_server.key -CAfile ca.crt -debug -verify 1 -no_ssl2 -no_ssl3 -WWW```
  
5. You should see output similar to:

```
verify depth is 1
Using default temp DH parameters
Using default temp ECDH parameters
ACCEPT
```
    
6. If you see an error that includes "bind: Address already in use" then you may need to 
   kill a VPN program or other app currently using port 443.  To see what app that might
   be, run this command on Mavericks:

   ```$ sudo lsof -i -n -P | grep 443```


### Test your TLS connection with a Ruby script (it works)

7. To confirm you are set up correctly, run these ruby scripts, which will make a TLS 
   connection, and do a GET to fetch a small text file.  The first 
   
8. Test your TLS connection with RSA key 

    ```$ ruby test_rsa_connection.rb```

You should see output like the following:

    I, [2014-03-31T14:26:21.139811 #46647]  INFO -- : get https://localhost/ping.txt
    D, [2014-03-31T14:26:21.139918 #46647] DEBUG -- request: User-Agent: "Faraday v0.9.0"
    I, [2014-03-31T14:26:21.173050 #46647]  INFO -- Status: 200
    D, [2014-03-31T14:26:21.173108 #46647] DEBUG -- response: content-type: "text/plain"
    pong
    
9. Test your TLS connection with an EC key

    ```$ ruby test_ec_connection.rb```

You should see output like the following

    I, [2014-03-31T14:26:25.689928 #46651]  INFO -- : get https://localhost/ping.txt
    D, [2014-03-31T14:26:25.690032 #46651] DEBUG -- request: User-Agent: "Faraday v0.9.0"
    I, [2014-03-31T14:26:25.723178 #46651]  INFO -- Status: 200
    D, [2014-03-31T14:26:25.723234 #46651] DEBUG -- response: content-type: "text/plain"
    pong


### Test your TLS connection with an iOS app (EC fails)

10. Open the included XCode project:
   ```$ open AESTest.xcodeproj/```
    
11. Run the AESTest project in XCode, target of iPad or iPhone are both ok.

12. When the simulator is running, click the "send ping request with rsa" button
    If you see the response "pong", the connection worked as expected.
    
13. When the simulator is running, click the "send ping request with ec" button.
    This will attempt the a TLS connection with EC cert, which will fail.  Your 
    reponse will be "error with connection".  

The details:
* How the request is made:
  * In the NSURLConnectionDelegate connection:willSendRequestForAuthenticationChallenge: 
    method, handle NSURLAuthenticationMethodClientCertificate by retrieving an 
    NSURLCredential whose identity certificate which has an elliptic-curve key, and 
    calling [challenge.sender useCredential:forAuthenticationChallenge:] with that 
    credential.
* What fails:
  * TLS handshaking fails due to server sending a FATAL alert "Unexpected Message". 
    Server log indicates "SSL3_GET_CERT_VERIFY:missing verify message". Packet capture 
    shows that client is sending:
    * Certificate
    * Client Key Exchange
    * Change Cipher Spec 
    
    It should be sending:
    * Certificate
    * Client Key Exchange
    * **Certificate Verify**
    * Change Cipher Spec
    
* Wireshark filter used: 
    * ip.src==192.168.0.0/16 && ip.dst==192.168.0.0/16 && tcp.port ==443
