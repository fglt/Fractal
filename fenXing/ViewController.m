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
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
//@property (nonatomic) int scale;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _imgView.contentMode = UIViewContentModeCenter;
    NSLog(@"cpu numbers: %d",countOfCores());
//    _scale = [UIScreen mainScreen].scale;
//    _scale = 1;
    // Do any additional setup after loading the view, typically from a nib.
//    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 360, 360)];
//    _imageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
//    
//    _z0RLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(_imageView.frame) + 20, 60, 40)];
//    _z0RLabel.text = @"Z0";
//    _z0RLabel.autoresizingMask =
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}
- (IBAction)runF:(id)sender {
    [self run];
}

- (void)run
{
    NSDate *start;
    start = [NSDate date];

    //CGFloat zr = [_zrText.text doubleValue];
    //CGFloat zi = [_zrText.text doubleValue];
    CGFloat cr = [_crText.text doubleValue];
    CGFloat ci = [_ciText.text doubleValue];
    
    //Complex *z0 = [[Complex alloc] initWithReal:zr image:zi];
    Complex *c = [[Complex alloc] initWithReal:cr image:ci];
    int iwidth=301, iheight=301;
    size_t bytesPerRow = iwidth * 4;
    
    void* data = malloc(iwidth * iheight * 4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGBitmapInfo kBGRxBitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
    
    CGContextRef context = CGBitmapContextCreate(data,iwidth, iheight, 8, bytesPerRow, colorSpace, kBGRxBitmapInfo);
    
    CGColorSpaceRelease(colorSpace);
    
    int halfWidth = iwidth/2;
    int halfHeight = iheight/2;

//    UInt8 bgr[3] = {0};
//    UInt8 *ptr= data;
//    for(int i=0 ; i<iheight; i++){
//        Complex * z;
//        Complex *z0;
//        for(int j= 0; j<iwidth; j++){
//            z0 = [[Complex alloc] initWithReal:(CGFloat)j*4/iwidth-2 image:(CGFloat)i*4/iheight-2];
//            z= fractal(z0, c);
//            colorForFractal(z, bgr);
//            ptr[0]= bgr[0];
//            ptr[1] = bgr[1];
//            ptr[2] = bgr[2];
//            ptr += 4;
//        }
//    }
//    
//    CGImageRef cgimage = CGBitmapContextCreateImage(context);
//    UIImage* image = [UIImage imageWithCGImage:cgimage scale:_scale orientation:UIImageOrientationUp];
//    CGContextRelease(context);
//    CGImageRelease(cgimage);
//    _imgView.image = image;
//    double de = [[NSDate date] timeIntervalSinceDate:start];
//    
//    _timeLabel.text = [NSString stringWithFormat:@"%f", de];



    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, queue, ^{
        UInt8 bgr[3] = {0};
        UInt8 *ptr= data;
        for(int i=0 ; i<halfHeight; i++){
            Complex * z;
            Complex *z0;
            for(int j= 0; j<iwidth; j++){
                z0 = [[Complex alloc] initWithReal:(CGFloat)j*4/iwidth-2 image:(CGFloat)i*4/iheight-2];
                z= fractal(z0, c);
                colorForFractal(z, bgr);
                ptr[0]= bgr[0];
                ptr[1] = bgr[1];
                ptr[2] = bgr[2];
                ptr += 4;
            }
        }
    });
    dispatch_group_async(group, queue, ^{
        UInt8 bgr[3] = {0};
        UInt8 *ptr= data+(halfHeight)*bytesPerRow;
        for(int i=halfHeight ; i<iheight; i++){
            Complex * z;
            Complex *z0;
            for(int j= 0; j<iwidth; j++){
                z0 = [[Complex alloc] initWithReal:(CGFloat)j*4/iwidth-2 image:(CGFloat)i*4/iheight-2];
                z= fractal(z0, c);
                colorForFractal(z, bgr);
                ptr[0]= bgr[0];
                ptr[1] = bgr[1];
                ptr[2] = bgr[2];
                ptr += 4;
            }
        }
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        CGImageRef cgimage = CGBitmapContextCreateImage(context);
        UIImage* image = [UIImage imageWithCGImage:cgimage scale:1 orientation:UIImageOrientationUp];
        CGContextRelease(context);
        CGImageRelease(cgimage);
        _imgView.image = image;
        double de = [[NSDate date] timeIntervalSinceDate:start];
        
        _timeLabel.text = [NSString stringWithFormat:@"%f",de];
    });
}

Complex * fractal(Complex * z, Complex * c)
{
    int i=0;
    for(; i <200; i++){
        if([z modelSquare]>18) break;
        z =  [[z square] addWith:c];
    }
    
    return z;
}


void colorForFractal(Complex *c, UInt8 *bgr)
{
    CGFloat h= [c model];
    int maxM = 20;
    if(h>maxM) h= maxM;
   
    CGFloat hsv[3] = {h/maxM,1,1};
    CGFloat bgrf[3] ={0,0,0};
//    int hi = h;
    //hsv[0] = hi%2 == 0 ? h*0.5/maxM : 0.5 + h*0.5/maxM;
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
