//
//  ViewController.m
//  fenXing
//
//  Created by Coding on 06/03/2017.
//  Copyright © 2017 Coding. All rights reserved.
//

#import "ViewController.h"
#import "Complex.h"
#import "FGTHSBSupport.h"
#import "fractal.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UITextField *crText;
@property (weak, nonatomic) IBOutlet UITextField *ciText;
@property (weak, nonatomic) IBOutlet UITextField *timeText;
//@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UITextField *timesText;
@property (weak, nonatomic) IBOutlet UISwitch *typeSwitch;
@property (weak, nonatomic) IBOutlet UIProgressView *progressIndicator;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableArray *complexArray;
//@property (nonatomic, strong) NSMutableArray *timesArray;
@property (nonatomic) int iwidth;
@property (nonatomic) int iheight;
@property (nonatomic) int loops;
@property (nonatomic, strong) Complex *c;
@property (nonatomic) int ktimes;

//@property (nonatomic) int scale;
@end

@implementation ViewController
{
    void *imgData;
    UInt16 *kdata;
    CGContextRef context;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _imgView.contentMode = UIViewContentModeCenter;
    _iwidth = 602;
    _iheight = 602;
    _loops = 0;
    NSLog(@"cpu numbers: %d",countOfCores());
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}
- (IBAction)runF:(id)sender {
    _c = [[Complex alloc] initWithReal:[_crText.text doubleValue] image:[_ciText.text doubleValue]];
    _ktimes = [_timesText.text intValue];
    
    if(_typeSwitch.isOn){
        
        [self fractal:_ktimes];
        
    }else{
        
        if(_loops==0){
            self.complexArray= [NSMutableArray arrayWithCapacity:_iwidth*_iheight];
            //self.timesArray= [NSMutableArray arrayWithCapacity:_iwidth*_iheight];
            _progressIndicator.progress = 0;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(run2) userInfo:nil repeats:YES];
        }
    }
}

- (void)imgContextWithWidth:(int) width height:(int) height{
    if(!imgData)
        imgData = malloc(_iwidth * _iheight * 4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGBitmapInfo kBGRxBitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
    
    context = CGBitmapContextCreate(imgData,width, height, 8, width * 4, colorSpace, kBGRxBitmapInfo);
    
    CGColorSpaceRelease(colorSpace);
}

- (void)fractal:(int) times
{
    NSDate *start;
    start = [NSDate date];
    
    [self imgContextWithWidth:_iwidth height:_iheight];
    
    int bytesPerRow = 4*_iwidth;
    int threadCount = countOfCores();
    int heightPerThread = _iheight/threadCount;
    int mod = _iheight%threadCount;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    for(int count=0; count<threadCount; count++){
        dispatch_group_async(group, queue, ^{
            UInt8 *ptr= imgData+count*bytesPerRow*heightPerThread;
            int startY = heightPerThread*count;
            int endY = startY + heightPerThread + mod*((count+1)/threadCount);
            fractalStep(_iwidth, _iheight,startY,endY, times, _c, ptr);
        });
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        CGImageRef cgimage = CGBitmapContextCreateImage(context);
        UIImage* image = [UIImage imageWithCGImage:cgimage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        
        free(imgData);
        imgData = nil;
        CGContextRelease(context);
        CGImageRelease(cgimage);
        _imgView.image = image;
        double de = [[NSDate date] timeIntervalSinceDate:start];
        
        _timeText.text = [NSString stringWithFormat:@"%.2f",de];
    });
}

- (void)run2
{
    _progressIndicator.progress = (CGFloat)_loops/_ktimes;
    if(_loops>=_ktimes) {
        [_timer invalidate];
        free(imgData);
        imgData = nil;
        free(kdata);
        kdata = nil;
        [self.complexArray removeAllObjects];
        //[self.timesArray removeAllObjects];
        self.complexArray = nil;
        //self.timesArray = nil;
        _loops = 0;
        return;
    }
    
    if(!kdata){
        kdata = malloc(_iwidth*_iheight*sizeof(UInt16));
    }
    [self imgContextWithWidth:_iwidth height:_iheight];
    
    UInt8 *ptr= imgData;
    for(int i=0 ; i<_iheight; i++){
        for(int j= 0; j<_iwidth; j++){
            UInt8 bgr[3] = {0};
            int index = j+i*_iwidth;
            Complex *tmpc;
            if(_loops==0){
                _complexArray[index] = [[Complex alloc] initWithReal:(CGFloat)j*3/_iwidth-1.5 image:(CGFloat)i*3/_iheight-1.5];
                kdata[index] = 0;
            }else{
                tmpc = _complexArray[index];
                if([tmpc modelSquare]<256){
                    _complexArray[index] = [[tmpc square] addWith:_c];
                    kdata[index]++ ;
                }
            }
            
            color( kdata[index], bgr, _ktimes*1.2);
            
            ptr[0] = bgr[0];
            ptr[1] = bgr[1];
            ptr[2] = bgr[2];
            ptr += 4;
        }
    }
    
    CGImageRef cgimage = CGBitmapContextCreateImage(context);
    UIImage* image = [UIImage imageWithCGImage:cgimage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    _imgView.image = image;
    CGImageRelease(cgimage);
    _loops++;
}

@end