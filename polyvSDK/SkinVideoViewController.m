//
//  SkinVideoViewController.h
//  polyvSDK
//
//  Created by seanwong on 8/17/15.
//  Copyright (c) 2015 easefun. All rights reserved.
//
#import "SkinVideoViewController.h"
#import "SkinVideoViewControllerView.h"
#import "PolyvSettings.h"
#import "PLVMoviePlayerController.h"

#import "PVDanmuManager.h"
#import "PvDanmuSendView.h"
#import "PvReportManager.h"

static const CGFloat pVideoPlayerControllerAnimationTimeinterval = 0.3f;

@interface SkinVideoViewController ()<PvDanmuSendViewDelegate>

@property (nonatomic, strong) SkinVideoViewControllerView *videoControl;

@property (nonatomic, strong) UIView *movieBackgroundView;
@property (nonatomic, assign) BOOL isFullscreenMode;
@property (nonatomic, assign) BOOL keepNavigationBar;
@property (nonatomic, assign) BOOL isBitRateViewShowing;
@property (nonatomic, assign) CGRect originFrame;
@property (nonatomic, strong) NSTimer *durationTimer;

@property (nonatomic, assign) BOOL danmuEnabled;
@property (nonatomic, strong) PVDanmuManager *danmuManager;
@property (nonatomic, strong) PvDanmuSendView *danmuSendV;

@property (nonatomic, assign) NSString* headtitle;
@property (nonatomic, assign) NSString* param1;


@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGFloat curPosition;
@property (nonatomic, assign) CGFloat curVoice;
@property (nonatomic, assign) CGFloat curBrightness;

@property (nonatomic, assign) PvGestureType gestureType;

@end

@implementation SkinVideoViewController{
    int _position;
    UINavigationController* _navigationController;
    UIViewController *_parentViewController;
    BOOL _isPrepared;
    
    NSTimer *_stallTimer;
    NSDate* _firstLoadStartTime;
    NSDate* _secondLoadStartTime;
    BOOL _firstLoadTimeSent;
    BOOL _secondLoadTimeSent;
    NSTimer *_watchTimer;
    
}

@synthesize watchVideoTimeDuration;
@synthesize watchStartTime;

-(void)play{
    
    [self.videoControl.indicatorView startAnimating];
    [super play];
}
-(void)stop{
    [self.videoControl.indicatorView stopAnimating];
    [super stop];

    
}
- (void)dealloc
{
    [self cancelObserver];
    [_watchTimer invalidate];
    
}


- (void)keepNavigationBar:(BOOL)keep{
    self.keepNavigationBar = keep;
    if (keep) {
        [_navigationController setNavigationBarHidden:NO animated:NO];
        self.videoControl.backButton.hidden = YES;
    }
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        self.view.frame = frame;
        self.view.backgroundColor = [UIColor blackColor];
        self.controlStyle = MPMovieControlStyleNone;
        [self.view addSubview:self.videoControl];
        self.videoControl.frame = self.view.bounds;
        [self configObserver];
        [self configControlAction];
        self.videoControl.closeButton.hidden = YES;
        self.watchVideoTimeDuration = 0;
        

    }
    return self;
}

#pragma mark - Override Method


- (void)setContentURL:(NSURL *)contentURL
{
    [self stop];
    [super setContentURL:contentURL];
    [self play];
}

- (void)setNavigationController:(UINavigationController*)navigationController{
    _navigationController = navigationController;
    if (!self.keepNavigationBar) {
        [_navigationController setNavigationBarHidden:YES animated:NO];
    }
    
    
}
- (void)setParentViewController:(UIViewController*)viewController{
    _parentViewController = viewController;
}



- (void)setLocalMp4:(NSString*)vid level:(int)level {
    NSString *plvPath = [[PolyvSettings sharedInstance] getDownloadDir];
    NSRange range = [vid rangeOfString:@"_"];
    if (range.location==NSNotFound) {
        return;
    }
    NSString*videoPoolId = [vid substringToIndex:range.location];
    
    NSString* localmp4 = [plvPath stringByAppendingString:[NSString stringWithFormat:@"/%@_%d.mp4",videoPoolId,level]];
    NSURL *contentURL = [NSURL fileURLWithPath:localmp4];
    [super setContentURL:contentURL];
    [self play];


}
- (void)setHeadTitle:(NSString*)headtitle{
    [self.videoControl setHeadTitle:headtitle];
}

- (void)setParam1:(NSString*)param1{
    self.param1 = param1;
}

#pragma mark - Public Method

- (void)showInWindow
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (!keyWindow) {
        keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
    }
    [keyWindow addSubview:self.view];
    self.view.alpha = 0.0;
    [UIView animateWithDuration:pVideoPlayerControllerAnimationTimeinterval animations:^{
        self.view.alpha = 1.0;
    } completion:^(BOOL finished) {
        
    }];
    self.videoControl.closeButton.hidden = NO;
    self.videoControl.showInWindowMode = YES;
    //[self enableDanmu:true];
    self.videoControl.backButton.hidden = YES;
    
    
    
    
}

-(void)setLogo:(UIImage*)image location:(int)location size:(CGSize)size{
    /*UIImageView* logoview = [[UIImageView alloc]initWithImage:image];
    //logoview.frame = CGRectMake(0,0,size.width,size.width);

    switch (location) {
        case PvLogoLocationTopLeft:
            logoview.frame = CGRectMake(0, 0, size.width,size.height);
            break;
        case PvLogoLocationTopRight:
            logoview.frame = CGRectMake(self.view.frame.size.width-size.width, 0, size.width,size.height);
            break;
        case PvLogoLocationBottomLeft:
            logoview.frame = CGRectMake(0, self.view.frame.size.height-size.height, size.width,size.height);
            break;
        default:
            logoview.frame = CGRectMake(self.view.frame.size.width-size.width , self.view.frame.size.height-size.height, size.width, size.height);
            break;
    }
    [self.view addSubview:logoview];*/
    [self.videoControl setLogoImage:image];
    [self.videoControl setLogoPosition:location];
    [self.videoControl setLogoSize:size];
    [self.videoControl logoImageView];
}


- (void)enableDanmu:(BOOL)enable{
    self.danmuEnabled  = enable;
    if (!self.danmuManager) {
        CGRect dmFrame;

        dmFrame = self.view.bounds;
        
        self.danmuManager = [[PVDanmuManager alloc] initWithFrame:dmFrame withVid:[super getVid] inView:self.view underView:self.videoControl durationTime:1];
        
    }
    if(self.danmuEnabled){
        [self.videoControl setDanmuButtonColor:[UIColor yellowColor]];
    }else{
        [self.videoControl setDanmuButtonColor:[UIColor whiteColor]];
    }
    
    
}
- (void)dismiss
{
    [self stopDurationTimer];
    [UIView animateWithDuration:pVideoPlayerControllerAnimationTimeinterval animations:^{
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        if (self.dimissCompleteBlock) {
            self.dimissCompleteBlock();
        }
    }];
    [_watchTimer invalidate];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)configObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerPlaybackStateDidChangeNotification) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerLoadStateDidChangeNotification) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerReadyForDisplayDidChangeNotification) name:MPMoviePlayerReadyForDisplayDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMovieDurationAvailableNotification) name:MPMovieDurationAvailableNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerPlaybackDidFinishNotification:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoInfoLoaded) name:@"NotificationVideoInfoLoaded" object:nil];

    
    
    
}
-(void)videoInfoLoaded{
    NSMutableArray*buttons = [self.videoControl createBitRateButton:[super getLevel]];
    for (int i=0; i<buttons.count; i++) {
        UIButton*_button = [buttons objectAtIndex:i];
        [_button addTarget:self action:@selector(bitRateViewButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.videoControl videoInfoLoaded:self.videoInfo];
}
- (void)cancelObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configControlAction
{
    [self.videoControl.playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.pauseButton addTarget:self action:@selector(pauseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.closeButton addTarget:self action:@selector(closeButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.danmuButton addTarget:self action:@selector(danmuButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.sendDanmuButton addTarget:self action:@selector(sendDanmuButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.fullScreenButton addTarget:self action:@selector(fullScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.bitRateButton addTarget:self action:@selector(bitRateButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.shrinkScreenButton addTarget:self action:@selector(shrinkScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    
    //[self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    //[self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpOutside];
    [self setProgressSliderMaxMinValues];
    [self monitorVideoPlayback];
}
-(void)setVid:(NSString *)vid{
    [super setVid:vid];
    [self stopCountWatchTime];
    self.watchVideoTimeDuration = 0;
}
- (void)setVid:(NSString*)vid level:(int)level{
    [super setVid:vid level:level];
    [self stopCountWatchTime];
    self.watchVideoTimeDuration = 0;
}
- (void)onMPMoviePlayerPlaybackStateDidChangeNotification
{
    if (self.playbackState == MPMoviePlaybackStatePlaying) {
        self.videoControl.pauseButton.hidden = NO;
        self.videoControl.playButton.hidden = YES;
        [self.videoControl.indicatorView stopAnimating];
        [self startDurationTimer];
        [self.videoControl autoFadeOutControlBar];
        if (_position>0) {
            [super setCurrentPlaybackTime:_position];
            _position = 0;
        }
        [self startCountWatchTime];
        
    } else{
        self.videoControl.pauseButton.hidden = YES;
        self.videoControl.playButton.hidden = NO;
        [self stopDurationTimer];
        if (self.playbackState == MPMoviePlaybackStateStopped) {
            [self.videoControl animateShow];
            
        }
        [self stopCountWatchTime];
        
        
        //NSLog(@"stop");
        
    }

    
}

- (void)onMPMoviePlayerLoadStateDidChangeNotification
{
    
    if (self.loadState & MPMovieLoadStateStalled) {
        [self stopCountWatchTime];
        [self.videoControl.indicatorView startAnimating];
    }
    if (self.loadState & MPMovieLoadStatePlaythroughOK) {
        [self.videoControl.indicatorView stopAnimating];
        [self startCountWatchTime];
        _isPrepared = YES;
        if (self.watchStartTime>0) {
            [self setCurrentPlaybackTime:self.watchStartTime];
            self.watchStartTime = -1;
        }
    }
    
  
    
}

-(void)startCountWatchTime{
    [_watchTimer invalidate];
    _watchTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                   target:self
                                                 selector:@selector(watchTimer_tick:)
                                                 userInfo:nil
                                                  repeats:YES];
}
-(void)stopCountWatchTime{
    [_watchTimer invalidate];
}
- (void) watchTimer_tick:(NSObject *)sender {
    self.watchVideoTimeDuration++;
}


- (void)onMPMoviePlayerReadyForDisplayDidChangeNotification
{
    
}
-(void)onMPMoviePlayerPlaybackDidFinishNotification:(NSNotification *)notification{
    
    self.videoControl.progressSlider.value = self.duration;
    double totalTime = floor(self.duration);
    [self setTimeLabelValues:totalTime totalTime:totalTime];
    //====error report
    NSDictionary *notificationUserInfo = [notification userInfo];
    NSNumber *resultValue = [notificationUserInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];

    MPMovieFinishReason reason = [resultValue intValue];
    
    //NSLog(@"%f %f",self.duration,self.currentPlaybackTime);
    
    if (fabs(self.duration-self.currentPlaybackTime) <1) {
        NSLog(@"观看完毕");
    }else{
        NSLog(@"没有完成");
    }
    if (reason == MPMovieFinishReasonPlaybackError)
    {
        NSError *mediaPlayerError = [notificationUserInfo objectForKey:@"error"];
        
        NSString*errorstring = @"";
        if (mediaPlayerError)
        {
            errorstring = [NSString stringWithFormat:@"%@",[mediaPlayerError localizedDescription]];
            
        }
        else
        {
            errorstring = @"playback failed without any given reason";
        }
        [PvReportManager reportError:[super getPid] uid:PolyvUserId vid:[super getVid] error:errorstring param1:self.param1 param2:@"" param3:@"" param4:@"" param5:@"polyv-ios-sdk"];

    }
    //NSLog(@"done");
    [self stopCountWatchTime];
    
    
}
- (void)onMPMovieDurationAvailableNotification
{
    [self setProgressSliderMaxMinValues];
}
- (void)bitRateViewButtonClick:(UIButton *)button
{
    _position = [super currentPlaybackTime];
    switch (button.tag) {
        case 0:
            [super switchLevel:0];
            [self.videoControl.bitRateButton setTitle:@"自动" forState:UIControlStateNormal];
            
            break;
        case 1:
            [super switchLevel:1];
            [self.videoControl.bitRateButton setTitle:@"流畅" forState:UIControlStateNormal];
            
            
            break;
        case 2:
            [super switchLevel:2];
            [self.videoControl.bitRateButton setTitle:@"高清" forState:UIControlStateNormal];
            
            
            break;
        case 3:
            [super switchLevel:3];
            [self.videoControl.bitRateButton setTitle:@"超清" forState:UIControlStateNormal];
            
            
            break;
            
        default:
            break;
    }
}



-(void)backButtonClick{
    if (self.isFullscreenMode) {
        [self shrinkScreenButtonClick];
        
        
    }else{
        if (_navigationController) {
            [_navigationController popViewControllerAnimated:YES];
        }else if(_parentViewController){


            [_parentViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
        
        
    }


    
}
- (void)playButtonClick
{
    [self play];
    self.videoControl.playButton.hidden = YES;
    self.videoControl.pauseButton.hidden = NO;
}

- (void)pauseButtonClick
{
    [self pause];
    self.videoControl.playButton.hidden = NO;
    self.videoControl.pauseButton.hidden = YES;
}
- (void)sendDanmuButtonClick{
    if (self.danmuSendV != nil) {
        self.danmuSendV = nil;
    }
    self.danmuSendV = [[PvDanmuSendView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.danmuSendV];
    self.danmuSendV.deleagte = self;
    [self.danmuSendV showAction:self.view];
    [super pause];
    [self.danmuManager pause];
    
}


- (void)danmuButtonClick{
    if (self.danmuEnabled) {
        [self enableDanmu:false];
        self.videoControl.sendDanmuButton.hidden=YES;
    }else{
        [self enableDanmu:true];
        self.videoControl.sendDanmuButton.hidden=NO;
    }
    
    
    
}
- (void)closeButtonClick
{
    [self dismiss];
}
-(void)bitRateButtonClick
{
    if (!self.isBitRateViewShowing) {
        self.videoControl.bitRateView.hidden = NO;
        [self.videoControl animateHide];
        self.isBitRateViewShowing = YES;
        
    }else{
        self.videoControl.bitRateView.hidden = YES;
        self.isBitRateViewShowing = NO;
    }
    
    
}
-(BOOL)isIOS8{
    NSString *ver = [[UIDevice currentDevice] systemVersion];
    float ver_float = [ver floatValue];
    if (ver_float>8 && ver_float<9) {
        return YES;
    }else{
        return NO;
    }
}
- (void)fullScreenButtonClick
{
    if (self.isFullscreenMode) {
        return;
    }
    
    
    if (self.videoControl.showInWindowMode) {
        self.originFrame = self.view.frame;
        CGFloat height = [[UIScreen mainScreen] bounds].size.width;
        CGFloat width = [[UIScreen mainScreen] bounds].size.height;
        CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);;
        [UIView animateWithDuration:0.3f animations:^{
            self.frame = frame;
            [self.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
        } completion:^(BOOL finished) {
            self.isFullscreenMode = YES;
            self.videoControl.fullScreenButton.hidden = YES;
            self.videoControl.shrinkScreenButton.hidden = NO;
        }];
    }else{
        CGFloat duration = [[UIApplication sharedApplication] statusBarOrientationAnimationDuration];
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
        //ios8翻转，弹幕键盘方向有问题，不需要弹幕可以去掉这行
        if ([self isIOS8]) {
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeRight] forKey:@"orientation"];
        }
        
        self.originFrame = self.view.frame;
        
        [UIView animateWithDuration:duration animations:^{
            [_parentViewController.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
        } completion:^(BOOL finished) {
            if (self.keepNavigationBar) {
                [_navigationController setNavigationBarHidden:YES];
                self.videoControl.backButton.hidden = NO;
            }
            _parentViewController.view.frame = _parentViewController.view.superview.bounds;
            self.frame = self.view.superview.bounds;
            self.view.frame =self.view.superview.bounds;
            self.isFullscreenMode = YES;
            [self.videoControl changeToFullsreen];
            self.videoControl.fullScreenButton.hidden = YES;
            self.videoControl.shrinkScreenButton.hidden = NO;
            
            if (self.danmuManager) {
                [self.danmuManager resetDanmuWithFrame:self.view.frame];
                [self.danmuManager initStart];
            }
            
            if (self.danmuEnabled) {
                self.videoControl.sendDanmuButton.hidden = NO;
            }
            if (self.fullscreenBlock) {
                self.fullscreenBlock();
            }
            
            
        }];
    }
    
}
- (void)shrinkScreenButtonClick
{
    if (!self.isFullscreenMode) {
        return;
    }
    
    if (self.videoControl.showInWindowMode) {
        [UIView animateWithDuration:0.3f animations:^{
            [self.view setTransform:CGAffineTransformIdentity];
            self.frame = self.originFrame;
        } completion:^(BOOL finished) {
            self.isFullscreenMode = NO;
            self.videoControl.fullScreenButton.hidden = NO;
            self.videoControl.shrinkScreenButton.hidden = YES;
        }];
    }else{
        CGFloat duration = [[UIApplication sharedApplication] statusBarOrientationAnimationDuration];
        
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
        
        
        [UIView animateWithDuration:duration animations:^{
            [_parentViewController.view setTransform:CGAffineTransformIdentity];
        } completion:^(BOOL finished) {
            if (self.keepNavigationBar) {
                [_navigationController setNavigationBarHidden:NO];
                self.videoControl.backButton.hidden = YES;
            }else{
                _parentViewController.view.frame = _parentViewController.view.superview.bounds;
            }
            
            self.frame = self.originFrame;
            self.view.frame = self.originFrame;
            self.isFullscreenMode = NO;
            [self.videoControl changeToSmallsreen];
            self.videoControl.fullScreenButton.hidden = NO;
            self.videoControl.shrinkScreenButton.hidden = YES;
            if (self.danmuManager) {
                [self.danmuManager resetDanmuWithFrame:self.view.frame];
                [self.danmuManager initStart];
            }
            if (self.danmuEnabled) {
                self.videoControl.sendDanmuButton.hidden = YES;
            }
            if (self.shrinkscreenBlock) {
                self.shrinkscreenBlock();
            }
            
        }];
        
    }

}

- (void)setProgressSliderMaxMinValues {
    CGFloat duration = self.duration;
    self.videoControl.progressSlider.minimumValue = 0.f;
    self.videoControl.progressSlider.maximumValue = duration;
}

- (void)progressSliderTouchBegan:(UISlider *)slider {
    [self pause];
    [self.videoControl cancelAutoFadeOutControlBar];
}

- (void)progressSliderTouchEnded:(UISlider *)slider {
    [self setCurrentPlaybackTime:floor(slider.value)];
    [self play];
    [self.videoControl autoFadeOutControlBar];
}

- (void)progressSliderValueChanged:(UISlider *)slider {
    double currentTime = floor(slider.value);
    double totalTime = floor(self.duration);
    [self setTimeLabelValues:currentTime totalTime:totalTime];
}

- (void)monitorVideoPlayback
{
    double currentTime = floor(self.currentPlaybackTime);
    double totalTime = floor(self.duration);
    [self setTimeLabelValues:currentTime totalTime:totalTime];
    self.videoControl.progressSlider.value = ceil(currentTime);
    if (self.danmuEnabled) {
        [_danmuManager rollDanmu:currentTime];
    }
    //NSLog(@"%d",self.watchVideoTimeDuration);
    
}

- (void)setTimeLabelValues:(double)currentTime totalTime:(double)totalTime {
    double minutesElapsed = floor(currentTime / 60.0);
    double secondsElapsed = fmod(currentTime, 60.0);
    NSString *timeElapsedString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesElapsed, secondsElapsed];
    
    double minutesRemaining = floor(totalTime / 60.0);;
    double secondsRemaining = floor(fmod(totalTime, 60.0));;
    NSString *timeRmainingString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesRemaining, secondsRemaining];
    
    self.videoControl.timeLabel.text = [NSString stringWithFormat:@"%@/%@",timeElapsedString,timeRmainingString];
}

- (void)startDurationTimer
{
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(monitorVideoPlayback) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopDurationTimer
{
    [self.durationTimer invalidate];
}

- (void)fadeDismissControl
{
    [self.videoControl animateHide];
}

#pragma mark - Property

- (SkinVideoViewControllerView *)videoControl
{
    if (!_videoControl) {
        _videoControl = [[SkinVideoViewControllerView alloc] init];
    }
    return _videoControl;
}

- (UIView *)movieBackgroundView
{
    if (!_movieBackgroundView) {
        _movieBackgroundView = [UIView new];
        _movieBackgroundView.alpha = 0.0;
        _movieBackgroundView.backgroundColor = [UIColor blackColor];
    }
    return _movieBackgroundView;
}

- (void)setFrame:(CGRect)frame
{
    [self.view setFrame:frame];
    [self.videoControl setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.videoControl setNeedsLayout];
    [self.videoControl layoutIfNeeded];
}



#pragma mark - QHDanmuSendViewDelegate
- (NSString *)timeFormatted:(int)totalSeconds
{
    
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

- (void)sendDanmu:(PvDanmuSendView *)danmuSendV info:(NSString *)info {
    NSTimeInterval currentTime = [super currentPlaybackTime];
    [self.danmuManager sendDanmu:[super getVid] msg:info time:[self timeFormatted:currentTime] fontSize:@"24" fontMode:@"roll" fontColor:@"0xFFFFFF"];
    [super play];
    
    //[self.danmuManager rollDanmu:0];
    //f=1 画框焦点
    [self.danmuManager insertDanmu:@{@"c":info, @"t":@"1", @"m":@"l",@"color":@"0xFFFFFF",@"f":@"1"}];
    [self.danmuManager resume:currentTime];

    
}

- (void)closeSendDanmu:(PvDanmuSendView *)danmuSendV {
    [super play];
    [self.danmuManager resume:[super currentPlaybackTime]];
}




@end

