//
//  FGTHSBSupport.m
//  BrushTest
//
//  Created by Coding on 8/7/16.
//  Copyright © 2016 Coding. All rights reserved.
//

#import "FGTHSBSupport.h"

//------------------------------------------------------------------------------

CGFloat pin(CGFloat minValue, CGFloat value, CGFloat maxValue)
{
	if (minValue > value)
		return minValue;
	else if (maxValue < value)
		return maxValue;
	else
		return value;
}

//------------------------------------------------------------------------------
#pragma mark	Floating point conversion
//------------------------------------------------------------------------------

static void hueToComponentFactors(CGFloat h, CGFloat*bgr)
{
    if(h == 1)
        h=0;
    CGFloat h_prime = h * 6;
    int  i = h_prime;
    CGFloat x = 1.0f - fabs(fmod(h_prime, 2.0f) - 1.0f);
    CGFloat bgr0[] = {0,x,1,0,1,x,x,1,0,1,x,0,1,0,x,x,0,1};
    memcpy(bgr, bgr0 + i*3, 3*sizeof(CGFloat));
}

void HSVtoRGB(const CGFloat*hsv, CGFloat* bgr)
{
    hueToComponentFactors(hsv[0], bgr);
    
    CGFloat c = hsv[2] * hsv[1];
    CGFloat m = hsv[2] - c;
    
    bgr[2] = bgr[2] * c + m;
    bgr[1] = bgr[1] * c + m;
    bgr[0] = bgr[0] * c + m;
}
//------------------------------------------------------------------------------

void RGBToHSV(const CGFloat * bgr, CGFloat*hsv, BOOL preserveHS)
{
    CGFloat max = bgr[2];
    CGFloat min = bgr[2];
    
    if (max <  bgr[1])
        max =  bgr[1];
    else{
        min = bgr[1];
    }
    if (max <  bgr[0])
        max =  bgr[0];
    else{
        if (min >  bgr[0])
            min =  bgr[0];
    }
    
    // Brightness (aka Value)
    
    hsv[2] = max;
    
    // Saturation
    
    CGFloat sat;
    
    if (max != 0.0f) {
        sat = (max - min) / max;
        hsv[1] = sat;
    }
    else {
        sat = 0.0f;
        
        if (!preserveHS)
            hsv[1] = 0.0f;             // Black, so sat is undefined, use 0
    }
    
    // Hue
    
    CGFloat delta;
    
    if (sat == 0.0f) {
        if (!preserveHS)
            hsv[0] = 0.0f;           // No color, so hue is undefined, use 0
    }
    else {
        delta = max - min;
        
        CGFloat hue;
        
        if (bgr[2] == max)
            hue = (bgr[1] - bgr[0]) / delta;
        else if (bgr[1] == max)
            hue = 2 + (bgr[0] - bgr[2]) / delta;
        else
            hue = 4 + (bgr[2] - bgr[1]) / delta;
        
        hue /= 6.0f;
        
        if (hue < 0.0f)
            hue += 1.0f;
        
        if (!preserveHS || fabs(hue - hsv[0]) != 1.0f)
            hsv[0] = hue;                               // 0.0 and 1.0 hues are actually both the same (red)
    }
}
//------------------------------------------------------------------------------
#pragma mark	Square/Bar image creation
//------------------------------------------------------------------------------

static UInt8 blend(UInt8 value, UInt8 percentIn255)
{
	return (UInt8) ((int) value * percentIn255 / 255);
}

//------------------------------------------------------------------------------

static CGContextRef createBGRxImageContext(int w, int h, void* data)
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	CGBitmapInfo kBGRxBitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
	// BGRA is the most efficient on the iPhone.
	
	CGContextRef context = CGBitmapContextCreate(data, w, h, 8, w * 4, colorSpace, kBGRxBitmapInfo);
	
	CGColorSpaceRelease(colorSpace);
	
	return context;
}


//------------------------------------------------------------------------------


UIImage* HSVBarContentImage(FGTColorHSVIndex colorHSVIndex, CGFloat hsv[3])
{
	UInt8 data[256 * 4];
	
	// Set up the bitmap context for filling with color:
	
	CGContextRef context = createBGRxImageContext(256, 1, data);
	
	if (context == nil)
		return nil;
	
	// Draw into context here:
	
	UInt8* ptr = CGBitmapContextGetData(context);
	if (ptr == nil) {
		CGContextRelease(context);
		return nil;
	}
	
	CGFloat bgr[3];
	for (int x = 0; x < 256; ++x) {
		hsv[colorHSVIndex] = (CGFloat) x / 255.0f;
		
		HSVtoRGB(hsv, bgr);
		ptr[0] = (UInt8) (bgr[0] * 255.0f);
		ptr[1] = (UInt8) (bgr[1] * 255.0f);
		ptr[2] = (UInt8) (bgr[2] * 255.0f);
		
		ptr += 4;
	}
	
	// Return an image of the context's content:
	
	CGImageRef cgimage = CGBitmapContextCreateImage(context);
	UIImage* image = [UIImage imageWithCGImage:cgimage];
	CGContextRelease(context);
    CGImageRelease(cgimage);
	return image;
}

void HSVFromUIColor(UIColor* color, CGFloat hsv[3])
{
    CGColorRef colorRef = [color CGColor];
    
    const CGFloat* components = CGColorGetComponents(colorRef);
    size_t numComponents = CGColorGetNumberOfComponents(colorRef);
    
    CGFloat bgr[3];
    
    if (numComponents < 3) {
        bgr[0] = bgr[1] = bgr[2] = components[0];
    }
    else {
        bgr[2] = components[0];
        bgr[1] = components[1];
        bgr[0] = components[2];
    }
    
    RGBToHSV(bgr, hsv, YES);
    //NSLog(@"%f: %f: %f",*h, *s,*v);
}

