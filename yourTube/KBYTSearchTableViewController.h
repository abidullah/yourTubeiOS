//
//  KBYTSearchTableViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/1/16.
//
//

#import <UIKit/UIKit.h>
#import "MarqueeLabel/MarqueeLabel.h"
#import "KBYTDownloadCell.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "KBYTPreferences.h"
#import "KBYourTube.h"



@interface KBYTSearchTableViewController : UITableViewController <UISearchBarDelegate>

@property (nonatomic, strong) NSTimer *airplayTimer;
@property (nonatomic, strong) NSString *airplayIP;
#if TARGET_OS_IOS
@property (nonatomic, strong) UISlider *airplaySlider;
#endif
@property (nonatomic, strong) UIView *sliderView;
@property (readwrite, assign) CGFloat airplayProgressPercent;
@property (readwrite, assign) CGFloat airplayDuration;
@property (readwrite, assign) NSInteger currentPage;
@property (nonatomic, strong) NSString *lastSearch;
@property (readwrite, assign) BOOL showingSuggestedVideos;

- (void)getNextPage;
@end
