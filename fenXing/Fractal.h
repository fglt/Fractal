//
//  fractal.h
//  fenXing
//
//  Created by Coding on 11/03/2017.
//  Copyright © 2017 Coding. All rights reserved.
//

#import <UIKit/UIKit.h>

Complex * fractal(Complex * z, Complex * c, int k);

void color(CGFloat value, UInt8 *bgr,CGFloat maxValue);

unsigned int countOfCores();
