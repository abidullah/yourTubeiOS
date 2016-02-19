//
//  ViewController.h
//  yourMusic
//
//  Created by Kevin Bradley on 1/8/16.
//  Copyright © 2016 nito. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>
#import "KBYourTube.h"
#import "KBYTPreferences.h"

@interface YTPlayerViewController : AVPlayerViewController

@end

@protocol OurViewControllerDelegate <NSObject>

- (void)pushViewController:(id)controller;

@end

@interface OurViewController : UIViewController <WKNavigationDelegate, UIActionSheetDelegate, WKScriptMessageHandler>
{
    id <OurViewControllerDelegate> __weak delegate;
}
@property (nonatomic, weak) id<OurViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet WKWebView *webView;
@property (nonatomic, strong) KBYTMedia *currentMedia;
@property (nonatomic, strong) NSString *previousVideoID;
@property (readwrite, assign) BOOL gettingDetails;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) NSTimer *airplayTimer;
@property (nonatomic, strong) NSString *airplayIP;
@property (nonatomic, strong) UISlider *airplaySlider;
@property (nonatomic, strong) UIView *sliderView;
@property (readwrite, assign) CGFloat airplayProgressPercent;
@property (readwrite, assign) CGFloat airplayDuration;


@end

