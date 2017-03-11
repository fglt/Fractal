//
//  ViewController.m
//  FactalMacOS
//
//  Created by Coding on 11/03/2017.
//  Copyright © 2017 Coding. All rights reserved.
//

#import "ViewController.h"
#import "Complex.h"
#import "FGTHSBSupport.h"
#import "fractal.h"

@interface ViewController()
@property (weak) IBOutlet NSImageView *imgView;

@property (weak) IBOutlet NSTextField *crText;
@property (weak) IBOutlet NSTextField *ciText;
@property (weak) IBOutlet NSTextField *timesText;
@property (weak) IBOutlet NSTextField *timeText;
@property (weak) IBOutlet NSButton *checkButton;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@property (strong) NSTimer *timers;
@property (strong) NSMutableArray *complexArray;
@property  int iwidth;
@property  int iheight;
@property  int loops;
@property (strong) Complex *c;
@property  int ktimes;
@end

@implementation ViewController{
    void *imgData;
    UInt16 *kdata;
    CGContextRef context;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _imgView.imageAlignment = NSImageAlignCenter;
    _iwidth = 602;
    _iheight = 602;
    _loops = 0;
    NSLog(@"cpu numbers: %d",countOfCores());
    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)FactalButtonAction:(NSButton *)sender {
    NSString *crs,*cis, *timestring;

    crs = [_crText.stringValue isEqual:@""] ? _crText.placeholderString:_crText.stringValue;
    cis = [_ciText.stringValue isEqual:@""] ? _ciText.placeholderString:_ciText.stringValue;
    timestring = [_timesText.stringValue isEqual:@""] ? _timesText.placeholderString:_timesText.stringValue;
   
    _c = [[Complex alloc] initWithReal:[crs doubleValue] image:[cis doubleValue]];
    _ktimes = [timestring intValue];
    
    if(_checkButton.state){
        if(imgData) return;
        [self fractal:_ktimes];
        
    }else{
        
        if(_loops==0){
            self.complexArray= [NSMutableArray arrayWithCapacity:_iwidth*_iheight];

            _progressIndicator.doubleValue = 0;
            self.timers = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(run2) userInfo:nil repeats:YES];
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
        
        NSImage* image = [self imageFromCGImageRef:cgimage];
        
        free(imgData);
        imgData = nil;
        CGContextRelease(context);
        CGImageRelease(cgimage);
        _imgView.image = image;
        double de = [[NSDate date] timeIntervalSinceDate:start];
        
        _timeText.stringValue = [NSString stringWithFormat:@"%.2f",de];
    });
}

- (void)run2
{
    _progressIndicator.doubleValue= (CGFloat)_loops*100.0/_ktimes;
    if(_loops>=_ktimes) {
        [_timers invalidate];
        free(imgData);
        imgData = nil;
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
    NSImage* image = [self imageFromCGImageRef:cgimage];
    _imgView.image = image;
    CGImageRelease(cgimage);
    _loops++;
}


- (NSImage*) imageFromCGImageRef:(CGImageRef)image

{
    
    NSRect imageRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
    
    CGContextRef imageContext = nil;
    
    NSImage* newImage = nil;
    
    
    
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
    
    return newImage;
    
}

@end
