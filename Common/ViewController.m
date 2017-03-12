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

@property (weak, nonatomic) IBOutlet NameView(ImageView) *imgView;
@property (weak, nonatomic) IBOutlet NameView(TextField) *crText;
@property (weak, nonatomic) IBOutlet NameView(TextField) *ciText;
@property (weak, nonatomic) IBOutlet NameView(TextField) *timesText;
@property (weak, nonatomic) IBOutlet CheckButton *typeSwitch;
@property (weak, nonatomic) IBOutlet ProgressView *progressIndicator;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableArray *complexArray;
@property (nonatomic) int iwidth;
@property (nonatomic) int iheight;
@property (nonatomic) int loops;
@property (nonatomic, strong) Complex *c;
@property (nonatomic) int ktimes;

@end

@implementation ViewController
{
    void *imgData;
    UInt16 *kdata;
    CGContextRef context;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _iwidth = 602;
    _iheight = 602;
    _loops = 0;
    NSLog(@"cpu numbers: %d",countOfCores());
    
}

- (IBAction)fractalButtonAction:(id)sender {
#if TARGET_OS_IPHONE
    _c = [[Complex alloc] initWithReal:[_crText.text doubleValue] image:[_ciText.text doubleValue]];
    _ktimes = [_timesText.text intValue];
    
    if(_typeSwitch.isOn){
        
        [self fractal:_ktimes];
        
    }else{
        
        if(_loops==0){
            self.complexArray= [NSMutableArray arrayWithCapacity:_iwidth*_iheight];
            //self.timesArray= [NSMutableArray arrayWithCapacity:_iwidth*_iheight];
            _progressIndicator.progress = 0;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(fractalGradient) userInfo:nil repeats:YES];
        }
    }
#else
    NSString *crs,*cis, *timestring;
    
    crs = [_crText.stringValue isEqual:@""] ? _crText.placeholderString:_crText.stringValue;
    cis = [_ciText.stringValue isEqual:@""] ? _ciText.placeholderString:_ciText.stringValue;
    timestring = [_timesText.stringValue isEqual:@""] ? _timesText.placeholderString:_timesText.stringValue;
    
    _c = [[Complex alloc] initWithReal:[crs doubleValue] image:[cis doubleValue]];
    _ktimes = [timestring intValue];
    
    if(_typeSwitch.state){
        if(imgData) return;
        [self fractal:_ktimes];
        
    }else{
        
        if(_loops==0){
            self.complexArray= [NSMutableArray arrayWithCapacity:_iwidth*_iheight];
            
            _progressIndicator.doubleValue = 0;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(fractalGradient) userInfo:nil repeats:YES];
        }
    }
#endif
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
        IMAGE_CLASS *image = [self imageFromCGImageRef:cgimage];
        
        free(imgData);
        imgData = nil;
        CGContextRelease(context);
        CGImageRelease(cgimage);
        _imgView.image = image;
    });
}

- (void)fractalGradient
{
    
#if TARGET_OS_IPHONE
    _progressIndicator.progress = (CGFloat)_loops/_ktimes;
#else
    _progressIndicator.doubleValue = (CGFloat)_loops*100/_ktimes;
#endif
    if(_loops>=_ktimes) {
        [_timer invalidate];
        free(imgData);
        imgData = nil;
        CGContextRelease(context);
        free(kdata);
        kdata = nil;
        [self.complexArray removeAllObjects];
        self.complexArray = nil;
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
    IMAGE_CLASS *image = [self imageFromCGImageRef:cgimage];
    _imgView.image = image;
    CGImageRelease(cgimage);
    _loops++;
}

- (IMAGE_CLASS *)imageFromCGImageRef:(CGImageRef)image

{
    IMAGE_CLASS *newImage;
#if TARGET_OS_IPHONE
    newImage = [UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
#else

    NSRect imageRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
    
    CGContextRef imageContext = nil;
    
    
    // Get the image dimensions.
    
    imageRect.size.height = CGImageGetHeight(image);
    
    imageRect.size.width = CGImageGetWidth(image);
    
    
    
    // Create a new image to receive the Quartz image data.
    
    newImage = [[NSImage alloc] initWithSize:imageRect.size];
    
    [newImage lockFocus];
    
    
    // Get the Quartz context and draw.
    
    imageContext = (CGContextRef)[[NSGraphicsContext currentContext]
                                  
                                  graphicsPort];
    
    CGContextDrawImage(imageContext, *(CGRect*)&imageRect, image);
    
    [newImage unlockFocus];
#endif
    return newImage;
}

@end
