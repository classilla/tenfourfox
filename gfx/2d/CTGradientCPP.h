/* CTGradientCPP object which is a wrapper for CTGradient */

#ifndef __CTGradientCPP_
#define __CTGradientCPP_

typedef float CGFloat; // nasty

#include "Types.h"

namespace mozilla {
namespace gfx {

class CTGradientCPP {
	public:
	CTGradientCPP(CGColorSpaceRef cs, GradientStop *stops, size_t count);
	CTGradientCPP(CGColorSpaceRef cs, CGFloat *colours, CGFloat *offsets,
                             size_t count);
	~CTGradientCPP();

  	void DrawAxial(CGContextRef cg, CGPoint startPoint, CGPoint endPoint);
  	void DrawRadial(CGContextRef cg, CGPoint startCenter,
       		CGFloat startRadius, CGPoint endCenter, CGFloat endRadius);

	void *mGradient; // opaque class
};

}
}

#endif
