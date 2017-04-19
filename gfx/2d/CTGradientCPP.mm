/* CTGradient to C++ bridge for TenFourFox CoreGraphics Azure backend

   This uses the CTGradient class (tweaked appropriately) to simulate
   CGGradient on 10.4. This wrapper object provides similar methods and
   hides the ObjC from C++.

   Cameron Kaiser */

#import "CTGradient.h"
#include "CTGradientCPP.h"

#include "DrawTargetCG.h"
#include "SourceSurfaceCG.h"
#include "Rect.h"
#include "ScaledFontMac.h"
#include "Tools.h"
#include <vector>

namespace mozilla {
namespace gfx {

// ctor
CTGradientCPP::CTGradientCPP(CGColorSpaceRef cs, // unused, see below
                             GradientStop *stops,
                             size_t count) {
	// We create a CTGradient manually, and add the components and
	// locations to it manually.
	mGradient = (void *)[[[CTGradient alloc] init] retain];

	// XXX: Currently, <canvas> uses RGBA color, and that's what we do
	// here. Apple documents that toll-free bridging from NSColorSpace to
	// CGColorSpaceRef was not implemented until 10.5, and there appears
	// to be no private interface for it either. So we just use the stock
	// NSColorSpace for sRGB and hope that's what the caller is using too.
	// If we ever figure out a way to interconvert, put that code in here.
	//
	// The components are RGBA CGFloats, representing the components from 
	// [NSColor getRed] et al.
	for (size_t i = 0; i < count; i++) {
		[(CTGradient *)mGradient addComponentStop:stops[i].color.r
			green:stops[i].color.g
			blue:stops[i].color.b
			alpha:stops[i].color.a
			position:stops[i].offset ];
	}

	// Ready to rock.
}

// Alternate form
// Simulates CGGradientCreateWithColorComponents
CTGradientCPP::CTGradientCPP(CGColorSpaceRef cs, // unused, see above
                             CGFloat *colours,
                             CGFloat *offsets,
                             size_t count) {
	mGradient = (void *)[[[CTGradient alloc] init] retain];
	size_t c_offs = 0;
	for (size_t i = 0; i < count; i++) {
		[(CTGradient *)mGradient addComponentStop:colours[c_offs]
			green:colours[c_offs+1]
			blue:colours[c_offs+2]
			alpha:colours[c_offs+3]
			position:offsets[i] ];
			c_offs += 4; // avoid Werror=sequence-point
	}
}

// dtor
CTGradientCPP::~CTGradientCPP() {
	[(CTGradient *)mGradient release];
	mGradient = NULL;
}

// Draw an axial (CGGradient now calls this a "linear") gradient defined by
// a rectangle stretching from startPoint to endPoint.
void
CTGradientCPP::DrawAxial(CGContextRef cg, CGPoint startPoint, CGPoint endPoint)
{
	[(CTGradient *)mGradient fillPointToPoint:startPoint
		endPoint:endPoint
		context:cg];
}

// Draw a radial gradient defined from an inner diametre to an outer one.
void
CTGradientCPP::DrawRadial(CGContextRef cg, CGPoint startCenter,
                CGFloat startRadius, CGPoint endCenter, CGFloat endRadius) {
	[(CTGradient *)mGradient fillRadiusToRadius:startCenter
		endPoint:endCenter
		startRadius:startRadius
		endRadius:endRadius
		context:cg];
}

}
}
