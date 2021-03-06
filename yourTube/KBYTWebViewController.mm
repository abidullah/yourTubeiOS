//
//  ViewController.m
//  yourMusic
//
//  Created by Kevin Bradley on 1/8/16.
//  Copyright © 2016 nito. All rights reserved.
//

#define MessageHandler @"didGetPosts"
#import "KBYTWebViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "APDeviceController.h"
#import "KBYTDownloadsTableViewController.h"
#import "KBYTSearchItemViewController.h"
#import "SVProgressHUD/SVProgressHUD.h"

static NSString * const YTTestActivityType = @"com.nito.activity.TestActivity";

@interface  TestAction : UIActivity

@end

@implementation TestAction

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

- (NSString *)activityType {
    return YTTestActivityType;
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Test Action", nil);
}

- (UIImage *)activityImage {
     return [UIImage imageNamed:@"activityAudio"];
}


@end


@interface KBYTWebViewController ()

@end

@implementation KBYTWebViewController

@synthesize airplayIP;

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view.backgroundColor = [UIColor redColor];
}

- (void)reloadStock
{
    NSURLRequest * request = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:@"http://m.youtube.com"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [[self webView] loadRequest:request];
}

- (void)updateRightButtons
{
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadStock)];
    self.navigationItem.rightBarButtonItem = refreshButton;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self checkAirplay];
    
}

- (void)pauseVideos
{
    NSString *script = @"var videos = document.querySelectorAll(\"video\"); for (var i = videos.length - 1; i >= 0; i--) { videos[i].pause(); };";
    [self.webView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        NSLog(@"Error : %@",error.localizedDescription);
        NSLog(@"Java script result = %@",result);
    }];
}

- (void)videoPlayingDidChange:(NSNotification *)notification
{
    [self updateRightButtons];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateRightButtons];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlayingDidChange:)
                                                 name:@"SomeClientPlayingDidChange"
                                               object:nil];
    
    // Video playing state handler
    
    CGRect mainFrame = [[self view] frame];
    CGFloat height = 64; //self.navigationController.navigationBar.frame.size.height;
    mainFrame.origin.y = height;
    mainFrame.size.height-= height;
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]
                                      init];
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0,height,mainFrame.size.width, 20)];
    [self.progressView.layer setZPosition:2];
    [self.webView.layer setZPosition:1];
    [self.view addSubview:self.progressView];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    //self.progressView.hidden = false;
    
    if ([config respondsToSelector:@selector(requiresUserActionForMediaPlayback)])
    {
        //    config.requiresUserActionForMediaPlayback = true;
    }
    config.mediaPlaybackRequiresUserAction = true;
    config.allowsInlineMediaPlayback = false;
    
    self.webView = [[WKWebView alloc] initWithFrame:mainFrame configuration:config];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [[self view] addSubview:self.webView];
    
    //a script to attempt to pause any videos from autoplaying, used in conjunction with a bunch of other hacks
    //to stop autoplaying from occuring.
    
    NSString *scriptContent = @"var videos = document.querySelectorAll(\"video\"); for (var i = videos.length - 1; i >= 0; i--) { videos[i].pause(); };";
    
    if (scriptContent)
    {
        WKUserScript *script = [[WKUserScript alloc]initWithSource:scriptContent injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        
        [config.userContentController addUserScript:script];
        [config.userContentController addScriptMessageHandler:self name:MessageHandler];
    }
    
    //NSString *lastVisited = [[KBYTPreferences preferences] valueForKey:@"lastVisitedURL"];
    
    NSString *lastVisited = nil;
    
    
    NSLog(@"last visited url: %@", lastVisited);
    
    if (lastVisited == nil || lastVisited.length == 0)
    {
        lastVisited = @"https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fwww.youtube.com%2Fsignin%3Fnext%3D%252F%26hl%3Den%26feature%3Dsign_in_button%26app%3Ddesktop%26action_handle_signin%3Dtrue&hl=en&passive=true&service=youtube&uilel=3";
    }
    
    NSURLRequest * request = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:lastVisited] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    
    //these observers are a hacky way to know a good time to check URL to see if we land on a page that has a video URL
    
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    
    [[self webView] setNavigationDelegate:self];
    [[self webView] loadRequest:request];
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    //  LOG_SELF;
 //   NSLog(@"size: %@", NSStringFromCGSize(size));
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (size.height > size.width) //portrait
    {
        CGRect mainFrame = [[self view] frame];
        CGFloat height = 64; //self.navigationController.navigationBar.frame.size.height;
        mainFrame.origin.y = height;
        mainFrame.size.height-= height;
        self.webView.frame = mainFrame;
        CGRect progressFrame = self.progressView.frame;
        progressFrame.origin.y = height;
        self.progressView.frame = progressFrame;
    } else { //landscape
        
        CGRect mainFrame = [[self view] frame];
        CGFloat height = 32; //self.navigationController.navigationBar.frame.size.height;
        mainFrame.origin.y = height;
        mainFrame.size.height-= height;
        self.webView.frame = mainFrame;
        CGRect progressFrame = self.progressView.frame;
        progressFrame.origin.y = height;
        self.progressView.frame = progressFrame;
    }
    
}


//currently unused
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    LOG_SELF;
    if ([message.name isEqualToString:MessageHandler]) {
        
        id postList = message.body;
        
    }
}

- (void)updateBackButtonState
{
    self.navigationItem.leftBarButtonItem = nil;
    return;
    if ([[self webView] canGoBack])
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"grey_arrow_left.png"] style:UIBarButtonItemStylePlain target:[self webView] action:@selector(goBack)];
    }
    else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}
/*
 
 This observer is where we determine whether or not we are on an actual video / playlist page
 
 If we are, jump through a whole bunch of hoops to stop the page from loading / autoplaying videos / ads. Then fetch
 video details for downloading / playback and show an action sheet.
 
 */

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"loading"]) {
        [self updateBackButtonState];
    }
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        //      NSLog(@"estimated progress: %f", self.webView.estimatedProgress);
        self.progressView.hidden = self.webView.estimatedProgress == 1;
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
    }
    if ([keyPath isEqualToString:@"title"]) {
        self.title = self.webView.title;
        [self updateBackButtonState];
        //among the initial hacks, since title gets changed a lot during a load cycle we dont want to fetch
        //the info twice, if we did then the action sheet would appear twice and we are wasting network calls.
        if (self.gettingDetails == true)
        {
            NSLog(@"already getting details, dont try again...");
            return;
        }
        
        //when we go back a page the video url may show up twice, and the name of page tends to be a generic "youtube"
        //return in this case.
        if ([self.webView.title isEqualToString:@"YouTube"]) {
            return;
        }
        
        //check the parameters of the URL to see if it has an associated video link in "v"
        
        NSDictionary *paramDict = [self.webView.URL parameterDictionary];
        if ( [[paramDict allKeys] containsObject:@"v"])
        {
            NSString *videoID = paramDict[@"v"];
            NSLog(@"videoID: %@", videoID);
            //another hack to prevent us from fetching details for the same video twice in a row.
            if (self.currentMedia != nil)
            {
                if ([self.previousVideoID isEqualToString:videoID])
                {
                    return;
                }
            }
            
            /**
             
             The biggest hack yet, if we just stopLoading and goBack google still finds a way to force
             ads down our throat / autoplay after the page has been left. So we get the URL from the last
             back item, store that, load a completely blank page after stopping and going back, then
             reload this saved URL from the previous link to go back to a page where we are safe from autoplaying
             ads and videos.
             
             */
            
            NSURL *backURL = [[[[self webView] backForwardList] backItem] URL];
            
            [[KBYTPreferences preferences] setObject:[backURL absoluteString] forKey:@"lastVisitedURL"];
            //we have the URL we need stop the loading AND go back
            [[self webView] stopLoading];
            [[self webView] goBack];
            
            //load a blank page, helps prevent ads / videos from autoplaying.
            [[self webView] loadHTMLString:@"<html/>" baseURL:nil];
            
            //now time to reload the previous page requests so we can successfully go "back" without
            //autoplaying garbage.
            
            NSURLRequest * request = [[NSURLRequest alloc]initWithURL:backURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
            [[self webView] loadRequest:request];
            
            //now we can finally fetch the video details so we can show the action sheet for the user to make
            //a decision on their next action.
            [self getVideoIDDetails:videoID];
            self.gettingDetails = true;
        } else {
            
            [[KBYTPreferences preferences] setObject:[self.webView.URL absoluteString] forKey:@"lastVisitedURL"];
        }
        
        
    }
}


- (void)checkAirplay
{
    NSInteger status = [[KBYourTube sharedInstance] airplayStatus];
    
    if (status == 0) {
        [self.navigationController setToolbarHidden:YES animated:YES];
        [self.airplayTimer invalidate];
    } else {
        [self.navigationController setToolbarHidden:NO animated:YES];
        [self populateToolbar:status];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            NSDictionary *playbackInfo = [self getAirplayDetails];
            CGFloat duration = [[playbackInfo valueForKey:@"duration"] floatValue];
            CGFloat position = [[playbackInfo valueForKey:@"position"] floatValue];
            CGFloat percent = position / duration;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.airplayProgressPercent = percent;
                self.airplaySlider.value = percent;
                self.airplayDuration = duration;
            });
        }
    });
}

- (void)fireAirplayTimer
{
    self.airplayTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkAirplay) userInfo:nil repeats:TRUE];
}

#define FLEXY                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]

- (void)sliderMoved:(UISlider *)slider
{
    CGFloat translatedSpot = self.airplayDuration * slider.value;
    [self scrubToPosition:translatedSpot];
}

- (void)populateToolbar:(NSInteger)status
{
    self.sliderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220, 40)];
    self.airplaySlider = [[UISlider alloc]initWithFrame:CGRectMake(0, 0, 220, 40)];
    self.airplaySlider.value = self.airplayProgressPercent;
    [self.airplaySlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
    [self.sliderView addSubview:self.airplaySlider];
    
    UIBarButtonItem *sliderItem = [[UIBarButtonItem alloc] initWithCustomView:self.sliderView];
    
    UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:[KBYourTube sharedInstance] action:@selector(stopAirplay)];
    UIBarButtonItem *playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:[KBYourTube sharedInstance] action:@selector(pauseAirplay)];
    if (status == 1) //playing
        playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:[KBYourTube sharedInstance] action:@selector(pauseAirplay)];
    UIBarButtonItem *fixSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    fixSpace.width = 10.0f;
    self.toolbarItems = @[FLEXY,stopButton, fixSpace,playButton, fixSpace, sliderItem, FLEXY];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSDictionary *)returnFromURLRequest:(NSString *)requestString requestType:(NSString *)type
{
    NSURL *deviceURL = [NSURL URLWithString:requestString];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:deviceURL];
    [request setHTTPMethod:type];
    [request addValue:@"MediaControl/1.0" forHTTPHeaderField:@"User-Agent"];
    NSURLResponse *theResponse = nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
    NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
    //NSLog(@"return details: %@", datString);
    return [datString dictionaryValue];
}

- (NSDictionary *)scrubToPosition:(CGFloat)position
{
    NSString *requestString = [NSString stringWithFormat:@"http://%@/scrub?position=%f", [self airplayIP], position];
    NSDictionary *returnDict = [self returnFromURLRequest:requestString requestType:@"POST"];
    //  NSLog(@"returnDict: %@", returnDict);
    return returnDict;
    
    //   /scrub?position=20.097000
}

- (NSDictionary *)getAirplayDetails
{
    NSString *requestString = [NSString stringWithFormat:@"http://%@/playback-info", [self airplayIP]];
    NSDictionary *returnDict = [self returnFromURLRequest:requestString requestType:@"GET"];
    //    NSLog(@"returnDict: %@", returnDict);
    return returnDict;
}


//actually get the video details for the selected video.

- (void)getVideoIDDetails:(NSString *)details
{
    if (self.currentMedia != nil)
    {
        if ([self.previousVideoID isEqualToString:details])
        {
            NSLog(@"already got this video, dont do anything");
            return;
        }
    }

    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getVideoDetailsForID:details completionBlock:^(KBYTMedia *videoDetails) {
        
       
        [SVProgressHUD dismiss];
        //  NSLog(@"got details successfully: %@", videoDetails);
        self.currentMedia = videoDetails;
        self.previousVideoID = videoDetails.videoId;
        self.gettingDetails = false;
        KBYTSearchItemViewController *searchItem = [[KBYTSearchItemViewController alloc] initWithMedia:videoDetails];
        [[self navigationController] pushViewController:searchItem animated:true];
        self.previousVideoID = nil;
        
        
    } failureBlock:^(NSString *error) {
        [SVProgressHUD dismiss];
        NSLog(@"fail!: %@", error);
        
    }];
}


//another place to try and prevent ads and autoplaying from happening, not sure how successful this is.
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler

{
    NSURL *url = navigationAction.request.URL;
    NSDictionary *paramDict = [self.webView.URL parameterDictionary];
    //    NSLog(@"paramDict: %@", paramDict);
    if ( [[paramDict allKeys] containsObject:@"v"])
    {
        [self pauseVideos];
        decisionHandler(WKNavigationActionPolicyCancel);
        
        
        return;
    }
    
    NSString *absolute = [url absoluteString];
    if([absolute containsString:@"googleads.g.doubleclick.net"])
    {
        
        [self pauseVideos];
        [webView stopLoading];
        
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler

{
    decisionHandler(WKNavigationResponsePolicyAllow);
}
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"error: %@", error);
    if (error.code == -1001) { // TIMED OUT:
        
        // CODE to handle TIMEOUT
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Timed out" message:@"Failed to load youtube.com, please try hitting refresh or try again later" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        
    } else if (error.code == -1003) { // SERVER CANNOT BE FOUND
        
        // CODE to handle SERVER not found
        
    } else if (error.code == -1100) { // URL NOT FOUND ON SERVER
        
        // CODE to handle URL not found
        
    }
    // NSLog(@"error code: %lu", error.code);
    
}
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    //   NSLog(@"url: %@", webView.URL);
}
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    // LOG_SELF;
}


@end

