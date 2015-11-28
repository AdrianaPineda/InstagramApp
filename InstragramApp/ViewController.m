//
//  ViewController.m
//  InstragramApp
//
//  Created by Adriana Pineda on 11/25/15.
//  Copyright © 2015 Adriana Pineda. All rights reserved.
//

#import "ViewController.h"
#import "NXOAuth2.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.loginButton.enabled = true;
    self.logoutButton.enabled = false;
    self.refreshButton.enabled = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonPressed:(id)sender {
    
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"Instagram"];
    
    self.loginButton.enabled = false;
    self.logoutButton.enabled = true;
    self.refreshButton.enabled = true;
}

- (IBAction)logoutButtonPressed:(id)sender {
    
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *accounts = [store accountsWithAccountType:@"Instagram"];
    
    for (id account in accounts) {
        [store removeAccount:account];
    }
    
    self.loginButton.enabled = true;
    self.logoutButton.enabled = false;
    self.refreshButton.enabled = false;
}

- (IBAction)refreshButtonPressed:(id)sender {
    
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *accounts = [store accountsWithAccountType:@"Instagram"];
    
    if ([accounts count] == 0) {
        NSLog(@"Warning: 0 Instagram accounts logged in");
        return;
    }
    
    NXOAuth2Account *account = accounts[0];
    NSString *accessToken = account.accessToken.accessToken;
    NSString *urlString = [@"https://api.instagram.com/v1/users/self/media/recent?access_token=" stringByAppendingString:accessToken];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    [[session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        // Check for error code
        if (error) {
            NSLog(@"Error: couldn't finish request: %@", error);
            return;
        }
        
        // Check HTTP error
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        if (httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
            NSLog(@"Error: status code %ld", httpResp.statusCode);
            return;
        }
        
        // Check JSON parse error
        NSError *parseErr;
        id pkg = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseErr];
        if (!pkg) {
            NSLog(@"Error: couldn't parse response %@", parseErr);
            return;
        }
        
        NSString *imageURLString = pkg[@"data"][0][@"images"][@"standard_resolution"][@"url"];
        NSURL *imageURL = [NSURL URLWithString:imageURLString];
        
        [[session dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (error) {
                NSLog(@"Error: couldn't finish request: %@", error);
                return;
            }
            
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            if (httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
                NSLog(@"Error: status code %ld", httpResp.statusCode);
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // We don't know which thread is running in the block
                // The only thread that can change the UI is the main thread
                self.imageView.image = [UIImage imageWithData:data];
            });
            
            
        }] resume];
        
    }] resume];
}

@end
