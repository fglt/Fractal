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
#import <mach-o/arch.h>
#import <sys/sysctl.h>

@interface ViewController ()
//@property (nonatomic, strong) UIImageView *imageView;
//@property (nonatomic, strong) UILabel *z0RLabel;
//@property (nonatomic, strong) UILabel *z0ILabel;
//@property (nonatomic, strong) UILabel *c0RLabel;
//@property (nonatomic, strong) UILabel *c0ILabel;
//@property (nonatomic, strong) UITextField *z0RText;
//@property (nonatomic, strong) UITextField *z0IText;
//@property (nonatomic, strong) UITextField *c0RText;
//@property (nonatomic, strong) UITextField *c0IText;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UITextField *crText;
@property (weak, nonatomic) IBOutlet UITextField *ciText;
@property (weak, nonatomic) IBOutlet UITextField *timeText;
//@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UITextField *timesText;
@property (weak, nonatomic) IBOutlet UISwitch *typeSwitch;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (nonatomic, strong) CADisplayLink *timer;
@property (nonatomic, strong) NSMutableArray *complexArray;
@property (nonatomic, strong) NSMutableArray *timesArray;
@property (nonatomic) int iwidth;
@property (nonatomic) int iheight;
@property (nonatomic) int loops;
@property (nonatomic, strong) Complex *c;
@property (nonatomic) int ktimes;

//@property (nonatomic) int scale;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _imgView.contentMode = UIViewContentModeCenter;
    _iwidth = 602;
    _iheight = 602;
    self.complexArray= [NSMutableArray arrayWithCapacity:_iwidth*_iheight];
    self.timesArray= [NSMutableArray arrayWithCapacity:_iwidth*_iheight];
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
            _progressView.progress = 0;
            self.timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(run2)];
            [self.timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        }
    }
}

- (void)fractal:(int) times
{
    NSDate *start;
    start = [NSDate date];

    size_t bytesPerRow = _iwidth * 4;
    
    void* data = malloc(_iwidth * _iheight * 4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGBitmapInfo kBGRxBitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
    
    CGContextRef context = CGBitmapContextCreate(data,_iwidth, _iheight, 8, bytesPerRow, colorSpace, kBGRxBitmapInfo);
    
    CGColorSpaceRelease(colorSpace);
    
    int threadCount = countOfCores();
    int heightPerThread = _iheight/threadCount;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    for(int count=0; count<threadCount; count++){
        dispatch_group_async(group, queue, ^{
            UInt8 bgr[3] = {0};
            UInt8 *ptr= data+count*bytesPerRow*heightPerThread;
            int max =(count+1)*heightPerThread+(_iheight%threadCount)*((count+1)/threadCount);
            for(int i=heightPerThread*count ; i<max; i++){
                Complex * z;
                Complex *z0;
                for(int j= 0; j<_iwidth; j++){
                    int m =0;
                    z0 = [[Complex alloc] initWithReal:(CGFloat)j*3/_iwidth-1.5 image:(CGFloat)i*3/_iheight-1.5];
                    z = z0;
                    for(; m <_ktimes; m++){
                        if([z modelSquare]>=256) break;
                        z =  [[z square] addWith:_c];
                    }
                    color(m, bgr,_ktimes*1.2);
                    ptr[0]= bgr[0];
                    ptr[1] = bgr[1];
                    ptr[2] = bgr[2];
                    ptr += 4;
                }
            }
        });
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        CGImageRef cgimage = CGBitmapContextCreateImage(context);
        UIImage* image = [UIImage imageWithCGImage:cgimage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        CGContextRelease(context);
        CGImageRelease(cgimage);
        _imgView.image = image;
        double de = [[NSDate date] timeIntervalSinceDate:start];
        
        _timeText.text = [NSString stringWithFormat:@"%f",de];
    });
}

- (void)run2
{
    int loopsStep = 15;
     _progressView.progress = (CGFloat)_loops/loopsStep/_ktimes;
    if(_loops>=_ktimes*loopsStep) {
        [_timer invalidate];
        _loops = 0;
        return;
    }
    
    if(_loops%loopsStep !=0) {
        _loops++;
        return;
    }
    
   
    size_t bytesPerRow = _iwidth * 4;
    
    void* data = malloc(_iwidth * _iheight * 4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGBitmapInfo kBGRxBitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
    
    CGContextRef context = CGBitmapContextCreate(data,_iwidth, _iheight, 8, bytesPerRow, colorSpace, kBGRxBitmapInfo);
    
    CGColorSpaceRelease(colorSpace);
    
    
    UInt8 *ptr= data;
    for(int i=0 ; i<_iheight; i++){
        for(int j= 0; j<_iwidth; j++){
            UInt8 bgr[3] = {0};
            int index = j+i*_iwidth;
            Complex *tmpc;
            if(_loops==0){
                _complexArray[index] = [[Complex alloc] initWithReal:(CGFloat)j*3/_iwidth-1.5 image:(CGFloat)i*3/_iheight-1.5];
                _timesArray[index] = [NSNumber numberWithInt:0];
            }else{
                tmpc = _complexArray[index];
                if([tmpc modelSquare]<256){
                    _complexArray[index] = [[tmpc square] addWith:_c];
                    _timesArray[index] = [NSNumber numberWithInt:[_timesArray[index] intValue] +1] ;
                }
            }

            CGFloat colorValue= [_timesArray[index] intValue];

            color(colorValue, bgr, _ktimes*1.2);

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
    CGContextRelease(context);
    
    _loops++;
}

Complex * fractal(Complex * z, Complex * c, int k)
{
    int i=0;
    for(; i <k; i++){
        if([z modelSquare]>40) break;
        z =  [[z square] addWith:c];
    }
    
    return z;
}

void color(CGFloat value, UInt8 *bgr,CGFloat maxValue)
{
    CGFloat hsv[3] = {0,1,1};
    hsv[0] =  value/maxValue;
//    hsv[0] = value<=5?  value/maxValue : value/maxValue+exp(value-maxValue)/2;
//    hsv[0] = hsv[0]<=1? hsv[0]:1;
    CGFloat bgrf[3] ={0,0,0};
    HSVtoRGB(hsv, bgrf);
    bgr[0] = bgrf[0]*255;
    bgr[1] = bgrf[1]*255;
    bgr[2] = bgrf[2]*255;
    
}

unsigned int countOfCores()
{
    unsigned int ncpu;
    size_t len = sizeof(ncpu);
    sysctlbyname("hw.ncpu", &ncpu, &len, NULL, 0);
    
    return ncpu;
}
@end
