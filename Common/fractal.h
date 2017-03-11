//
//  fractal.h
//  fenXing
//
//  Created by Coding on 11/03/2017.
//  Copyright © 2017 Coding. All rights reserved.
//

@import Foundation;
@import CoreGraphics;
#import "Complex.h"

Complex * FGFractal(Complex * z, Complex * c, int k);

void color(CGFloat value, UInt8 *bgr,CGFloat maxValue);

unsigned int countOfCores();

void fractalStep(int width, int height,int startY, int endY, int times, Complex *const c, UInt8 *ptr);
