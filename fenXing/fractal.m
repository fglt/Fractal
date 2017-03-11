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
