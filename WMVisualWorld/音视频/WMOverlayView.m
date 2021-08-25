
#import "WMOverlayView.h"

@interface WMOverlayView ()
@property (nonatomic, strong) UIButton * actionButton;
@property (nonatomic, strong) UIView * videoPoint;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) UIButton *flashButton;//闪光灯
@property (strong, nonatomic) UIButton *torchButton;//电灯
@end

@implementation WMOverlayView

- (void)awakeFromNib {
    [super awakeFromNib];
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        CGSize screenRect = [[UIScreen mainScreen] bounds].size;
        
        self.actionButton = [[UIButton alloc] initWithFrame:CGRectMake(screenRect.width/2.0 - 25, screenRect.height-50-20, 50, 50)];
        self.actionButton.backgroundColor = [UIColor whiteColor];
        self.actionButton.layer.cornerRadius = 25.0;
        [self.actionButton addTarget:self action:@selector(onActionButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.actionButton];
        
        self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(30, screenRect.height-50-20, 40, 40)];
        self.backButton.backgroundColor = [UIColor redColor];
        self.backButton.layer.cornerRadius = 20.0;
        [self.backButton addTarget:self action:@selector(onBackButton) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.backButton];
        
        self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(30, screenRect.height-50-20, 40, 40)];
        self.backButton.backgroundColor = [UIColor redColor];
        self.backButton.layer.cornerRadius = 20.0;
        [self.backButton addTarget:self action:@selector(onBackButton) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.backButton];

        self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(30, screenRect.height-50-20, 40, 40)];
        self.backButton.backgroundColor = [UIColor redColor];
        self.backButton.layer.cornerRadius = 20.0;
        [self.backButton addTarget:self action:@selector(onBackButton) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.backButton];
        
        self.flashButton = [[UIButton alloc] initWithFrame:CGRectMake(screenRect.width-60, screenRect.height/2.0, 60, 40)];
        [self.flashButton setTitle:@"无闪光" forState:UIControlStateNormal];
        [self.flashButton setTitle:@"⚡️" forState:UIControlStateSelected];
        [self.flashButton setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
        self.flashButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [self.flashButton addTarget:self action:@selector(onFlashButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.flashButton];

        self.torchButton = [[UIButton alloc] initWithFrame:CGRectMake(screenRect.width-60, screenRect.height/2.0+50, 60, 40)];
        [self.torchButton setTitle:@"手电筒" forState:UIControlStateNormal];
        [self.torchButton setTitle:@"🔦" forState:UIControlStateSelected];
        [self.torchButton setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
        self.torchButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [self.torchButton addTarget:self action:@selector(onTorchButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.torchButton];

    }
    return self;
}

-(void)setType:(WMOverlayViewType)type
{
    _type = type;
    if (type != stillImage) {
        [self.flashButton removeFromSuperview];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self.actionButton pointInside:[self convertPoint:point toView:self.actionButton] withEvent:event] ||
        [self.backButton pointInside:[self convertPoint:point toView:self.backButton] withEvent:event] ||
        [self.flashButton pointInside:[self convertPoint:point toView:self.flashButton] withEvent:event] ||
        [self.torchButton pointInside:[self convertPoint:point toView:self.torchButton] withEvent:event]) {
        return YES;
    }
    return NO;
}

-(void)onFlashButton:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if ([self.delegate respondsToSelector:@selector(WMOverlayViewDelegateFlash:)]) {
        [self.delegate WMOverlayViewDelegateFlash:sender.selected];
    }
}

-(void)onTorchButton:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if ([self.delegate respondsToSelector:@selector(WMOverlayViewDelegateTorch:)]) {
        [self.delegate WMOverlayViewDelegateTorch:sender.selected];
    }
}


-(void)onBackButton
{
    if ([self.delegate respondsToSelector:@selector(WMOverlayViewDelegateStopAction)]) {
        [self.delegate WMOverlayViewDelegateStopAction];
    }
}

-(void)onActionButton:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (self.type == stillImage) {
        if ([self.delegate respondsToSelector:@selector(WMOverlayViewDelegateStillImage)]) {
            [self.delegate WMOverlayViewDelegateStillImage];
        }
    }
    if (self.type == video) {
        if ([self.delegate respondsToSelector:@selector(WMOverlayViewDelegateVideo)]) {
            if (sender.selected) {
                [self startVideo];
            }else {
                [self stopVideo];
            }
            [self.delegate WMOverlayViewDelegateVideo];
        }
    }
//    if (self.type == face) {
//        if ([self.delegate respondsToSelector:@selector(WMOverlayViewDelegateFace)]) {
//            [self.delegate WMOverlayViewDelegateFace];
//        }
//    }
//    if (self.type == scanCode) {
//        if ([self.delegate respondsToSelector:@selector(WMOverlayViewDelegateScanCode)]) {
//            [self.delegate WMOverlayViewDelegateScanCode];
//        }
//    }
}


#pragma mark - 录制视频时候的闪点,标识正在录制视频中
-(void)updateTimeDisplay
{
    [UIView animateWithDuration:0.4 animations:^{
        if (self.videoPoint.tag==0) {
            self.videoPoint.backgroundColor = [UIColor greenColor];
            self.videoPoint.tag = 1;
        }else {
            self.videoPoint.backgroundColor = [UIColor clearColor];
            self.videoPoint.tag = 0;
        }
    }];
}

- (void)startTimer {
    [self.timer invalidate];
    self.timer = [NSTimer timerWithTimeInterval:0.5
                                         target:self
                                       selector:@selector(updateTimeDisplay)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
    [self.videoPoint removeFromSuperview];
}

-(void)startVideo
{
    [self addSubview:self.videoPoint];
    [self startTimer];
}

-(void)stopVideo
{
    [self stopTimer];
}

-(UIView *)videoPoint
{
    if (!_videoPoint) {
        _videoPoint = [[UIView alloc] initWithFrame:CGRectMake(10, 20, 10, 10)];
        _videoPoint.layer.cornerRadius = 5.0;
        _videoPoint.backgroundColor = [UIColor clearColor];
    }
    return _videoPoint;
}
@end
