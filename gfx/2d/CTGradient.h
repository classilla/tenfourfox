//
//  CTGradient.h
//
//  Created by Chad Weider on 2/14/07.
//  Written by Chad Weider.
//  Modified for TenFourFox by Cameron Kaiser
//
//  Released into public domain on 4/10/08.
//  
//  Version: 1.8

#import <Cocoa/Cocoa.h>
typedef float CGFloat; // wtf.

typedef struct _CTGradientElement 
	{
	float red, green, blue, alpha;
	float position;
	
	struct _CTGradientElement *nextElement;
	} CTGradientElement;

typedef enum  _CTBlendingMode
	{
	CTLinearBlendingMode,
	CTChromaticBlendingMode,
	CTInverseChromaticBlendingMode
	} CTGradientBlendingMode;


@interface CTGradient : NSObject <NSCopying, NSCoding>
	{
	CTGradientElement* elementList;
	CTGradientBlendingMode blendingMode;
	
	CGFunctionRef gradientFunction;
        CGContextRef cg;
	}

+ (id)gradientWithBeginningColor:(NSColor *)begin endingColor:(NSColor *)end;

+ (id)aquaSelectedGradient;
+ (id)aquaNormalGradient;
+ (id)aquaPressedGradient;

+ (id)unifiedSelectedGradient;
+ (id)unifiedNormalGradient;
+ (id)unifiedPressedGradient;
+ (id)unifiedDarkGradient;

+ (id)sourceListSelectedGradient;
+ (id)sourceListUnselectedGradient;

+ (id)rainbowGradient;
+ (id)hydrogenSpectrumGradient;

- (CTGradient *)gradientWithAlphaComponent:(float)alpha;

- (CTGradient *)addColorStop:(NSColor *)color atPosition:(float)position;	//positions given relative to [0,1]
- (void)addComponentStop:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a position:(float)pos ;
- (CTGradient *)removeColorStopAtIndex:(unsigned)index;
- (CTGradient *)removeColorStopAtPosition:(float)position;

- (CTGradientBlendingMode)blendingMode;
- (NSColor *)colorStopAtIndex:(unsigned)index;
- (NSColor *)colorAtPosition:(float)position;

- (CTGradient *)setCGContext:(CGContextRef)newcg;

- (void)drawSwatchInRect:(NSRect)rect;
- (void)fillRect:(NSRect)rect angle:(float)angle;
	// fills rect with axial gradient
	// angle in degrees
- (void)fillPointToPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint context:(CGContextRef)currentContext;
	// mostly directly maps to CGShading/CGGradient
	// assumes clip is already set, graphics state saved, etc.
- (void)radialFillRect:(NSRect)rect;								//fills rect with radial gradient
																	//  gradient from center outwards
- (void)fillRadiusToRadius:(CGPoint)startPoint endPoint:(CGPoint)endPoint startRadius:(float)startRadius endRadius:(float)endRadius context:(CGContextRef)currentContext;
	// analogue to fPTP
- (void)fillBezierPath:(NSBezierPath *)path angle:(float)angle;
- (void)radialFillBezierPath:(NSBezierPath *)path;

@end
