

#import "yourTubeApplication.h"

@implementation yourTubeApplication
@synthesize window = _window;

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[KBYTMessagingCenter sharedInstance] stopDownloadListener];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[KBYTMessagingCenter sharedInstance] startDownloadListener];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
    [KBYourTube sharedInstance]; //create it right off the bat to get device discovery going
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _window.backgroundColor = [UIColor whiteColor];
    _searchViewController = [[KBYTDownloadsTableViewController alloc] init];
    self.nav = [[UINavigationController alloc] initWithRootViewController:_searchViewController];

     [[UINavigationBar appearance] setTintColor:[UIColor redColor]];
    [_window setRootViewController:  self.nav];
	[_window makeKeyAndVisible];
  
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *error = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error == nil) {
        [audioSession setActive:YES error:&error];
    }
    
    NSLog(@"app support: %@", [self appSupportFolder]);
    
    [[KBYTMessagingCenter sharedInstance] startDownloadListener];
    [[KBYTMessagingCenter sharedInstance] registerDownloadListener];

    if ([[KBYourTube sharedInstance] isSignedIn] == true)
    {
        [[KBYourTube sharedInstance] getUserDetailsDictionaryWithCompletionBlock:^(NSDictionary *outputResults) {
            //
            [[KBYourTube sharedInstance] setUserDetails:outputResults];
            
        } failureBlock:^(NSString *error) {
            
            NSLog(@"failed fetching user details with error: %@", error);
            
        }];
    } else {
        NSLog(@"is not signed in");
    }
    
   
    
    /*
 
    NSDate *myStart = [NSDate date];
    
    [[KBYourTube sharedInstance] youTubeSearch:@"Drake rick ross" pageNumber:1 completionBlock:^(NSDictionary *searchDetails) {
        
        NSLog(@"time taken: %@ searchDetails: %@", [myStart timeStringFromCurrentDate], searchDetails);
        
    } failureBlock:^(NSString *error) {
        
        
    }];
    
  
    [[KBYourTube sharedInstance]getSearchResults:@"Drake rick ross" pageNumber:1 completionBlock:^(NSDictionary *searchDetails) {
      
        
        NSLog(@"time taken: %@ searchDetails: %@", [myStart timeStringFromCurrentDate], searchDetails);
        
        
    } failureBlock:^(NSString *error) {
        
        //
    }];
    
    */
}


- (void)pushViewController:(id)controller
{
    [[self nav] pushViewController:controller animated:YES];
}

- (void)dealloc {
	
}
@end

// vim:ft=objc
