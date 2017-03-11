//
//  fractal.m
//  fenXing
//
//  Created by Coding on 11/03/2017.
//  Copyright © 2017 Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Complex.h"
#import "FGTHSBSupport.h"
#import <mach-o/arch.h>
#import <sys/sysctl.h>

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


void fractalStep(int width, int height, int startY, int endY, int times, Complex const* c, UInt8 *ptr)
{
    UInt8 bgr[3] = {0};
    
    for(int i=startY ; i<endY; i++){
        Complex * z;
        Complex *z0;
        for(int j= 0; j<width; j++){
            int m =0;
            z0 = [[Complex alloc] initWithReal:(CGFloat)j*3/width-1.5 image:(CGFloat)i*3/height-1.5];
            z = z0;
            for(; m <times; m++){
                if([z modelSquare]>=256) break;
                z =  [[z square] addWith:c];
            }
            color(m, bgr,times*1.2);
            ptr[0]= bgr[0];
            ptr[1] = bgr[1];
            ptr[2] = bgr[2];
            ptr += 4;
        }
    }
}
