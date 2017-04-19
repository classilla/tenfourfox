/* -*- Mode: objc; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "mozilla/ArrayUtils.h"

#include "mozilla/Logging.h"

#include <unistd.h>
#include <math.h>

#include "nsChildView.h"
#include "nsCocoaWindow.h"

#include "mozilla/MiscEvents.h"
#include "mozilla/MouseEvents.h"
#include "mozilla/TextEvents.h"
#include "mozilla/TouchEvents.h"

#include "nsObjCExceptions.h"
#include "nsCOMPtr.h"
#include "nsToolkit.h"
#include "nsCRT.h"

#include "nsFontMetrics.h"
#include "nsIRollupListener.h"
#include "nsViewManager.h"
#include "nsIInterfaceRequestor.h"
#include "nsIFile.h"
#include "nsILocalFileMac.h"
#include "nsGfxCIID.h"
#include "nsIDOMSimpleGestureEvent.h"
#include "nsThemeConstants.h"
#include "nsIWidgetListener.h"
#include "nsIPresShell.h"

#include "nsDragService.h"
#include "nsClipboard.h"
#include "nsCursorManager.h"
#include "nsWindowMap.h"
#include "nsCocoaFeatures.h"
#include "nsCocoaUtils.h"
#include "nsMenuUtilsX.h"
#include "nsMenuBarX.h"
#include "NativeKeyBindings.h"
#include "ComplexTextInputPanel.h"

#include "gfxContext.h"
#include "gfxQuartzSurface.h"
#include "gfxUtils.h"
#include "nsRegion.h"
#include "Layers.h"
#include "ClientLayerManager.h"
#include "mozilla/layers/LayerManagerComposite.h"
#include "GLTextureImage.h"
#include "GLContextProvider.h"
#include "GLContextCGL.h"
#include "GLUploadHelpers.h"
#include "ScopedGLHelpers.h"
#include "HeapCopyOfStackArray.h"
#include "mozilla/layers/APZCTreeManager.h"
#include "mozilla/layers/APZThreadUtils.h"
#include "mozilla/layers/GLManager.h"
#include "mozilla/layers/CompositorOGL.h"
#include "mozilla/layers/CompositorParent.h"
#include "mozilla/layers/BasicCompositor.h"
#include "mozilla/layers/InputAPZContext.h"
#include "gfxUtils.h"
#include "gfxPrefs.h"
#include "mozilla/gfx/2D.h"
#include "mozilla/gfx/BorrowedContext.h"
#ifdef ACCESSIBILITY
#include "nsAccessibilityService.h"
#include "mozilla/a11y/Platform.h"
#endif
#ifdef MOZ_CRASHREPORTER
#include "nsExceptionHandler.h"
#endif

#include "mozilla/Preferences.h"

#include <dlfcn.h>

#include <ApplicationServices/ApplicationServices.h>

#include "GeckoProfiler.h"

#include "nsIDOMWheelEvent.h"
#include "mozilla/layers/ChromeProcessController.h"
#include "nsLayoutUtils.h"
#include "InputData.h"
#include "SwipeTracker.h"
#include "VibrancyManager.h"
#include "nsNativeThemeCocoa.h"
#include "nsIDOMWindowUtils.h"
#include "Units.h"
#include "UnitTransforms.h"

using namespace mozilla;
using namespace mozilla::layers;
using namespace mozilla::gl;
using namespace mozilla::widget;

using mozilla::gfx::Matrix4x4;

#undef DEBUG_UPDATE
#undef INVALIDATE_DEBUGGING  // flash areas as they are invalidated

// Don't put more than this many rects in the dirty region, just fluff
// out to the bounding-box if there are more
#define MAX_RECTS_IN_REGION 100

PRLogModuleInfo* sCocoaLog = nullptr;

extern "C" {
  CG_EXTERN void CGContextResetCTM(CGContextRef);
  CG_EXTERN void CGContextSetCTM(CGContextRef, CGAffineTransform);
  CG_EXTERN void CGContextResetClip(CGContextRef);

  typedef CFTypeRef CGSRegionObj;
  CGError CGSNewRegionWithRect(const CGRect *rect, CGSRegionObj *outRegion);
  CGError CGSNewRegionWithRectList(const CGRect *rects, int rectCount, CGSRegionObj *outRegion);

  // CGSPrivate.h
  typedef NSInteger CGSConnection;
  typedef NSInteger CGSWindow;
  extern CGSConnection _CGSDefaultConnection();
  extern CGError CGSGetScreenRectForWindow(const CGSConnection cid, CGSWindow wid, CGRect *outRect);
  extern CGError CGSGetWindowLevel(const CGSConnection cid, CGSWindow wid, CGWindowLevel *level);
  extern CGError CGSGetWindowAlpha(const CGSConnection cid, const CGSWindow wid, float* alpha);
}

#ifndef NS_LEOPARD_AND_LATER
struct __TISInputSource;
typedef __TISInputSource* TISInputSourceRef;
TISInputSourceRef (*Leopard_TISCopyCurrentKeyboardInputSource)() = NULL;
TISInputSourceRef (*Leopard_TISCopyCurrentKeyboardLayoutInputSource)() = NULL;
void* (*Leopard_TISGetInputSourceProperty)(TISInputSourceRef inputSource, CFStringRef propertyKey) = NULL;
CFArrayRef (*Leopard_TISCreateInputSourceList)(CFDictionaryRef properties, Boolean includeAllInstalled) = NULL;
CFStringRef kOurTISPropertyUnicodeKeyLayoutData = NULL;
CFStringRef kOurTISPropertyInputSourceID = NULL;
CFStringRef kOurTISPropertyInputSourceLanguages = NULL;

bool nsTSMManager::sIsIMEEnabled = true;
bool nsTSMManager::sIsRomanKeyboardsOnly = false;
bool nsTSMManager::sIgnoreCommit = false;
NSView<mozView>* nsTSMManager::sComposingView = nullptr;
TSMDocumentID nsTSMManager::sDocumentID = nullptr;
NSString* nsTSMManager::sComposingString = nullptr;
nsITimer* nsTSMManager::sSyncKeyScriptTimer = nullptr;
uint32_t nsTSMManager::sIMEEnabledStatus = IMEState::ENABLED;
#endif // NS_LEOPARD_AND_LATER
uint32_t nsChildView::sSecureEventInputCount = 0;

// defined in nsMenuBarX.mm
extern NSMenu* sApplicationMenu; // Application menu shared by all menubars

static bool gChildViewMethodsSwizzled = false;

extern nsISupportsArray *gDraggedTransferables;

ChildView* ChildViewMouseTracker::sLastMouseEventView = nil;
NSEvent* ChildViewMouseTracker::sLastMouseMoveEvent = nil;
NSWindow* ChildViewMouseTracker::sWindowUnderMouse = nil;
NSPoint ChildViewMouseTracker::sLastScrollEventScreenLocation = NSZeroPoint;

#ifdef INVALIDATE_DEBUGGING
static void blinkRect(Rect* r);
static void blinkRgn(RgnHandle rgn);
#endif

#ifndef NS_LEOPARD_AND_LATER
// used by nsAppShell.mm
uint32_t gLastModifierState = 0;
#endif

nsString mLastDispatchedCompositionString; // bug 543789. NOT NSString *!

bool gUserCancelledDrag = false;

uint32_t nsChildView::sLastInputEventCount = 0;

static uint32_t gNumberOfWidgetsNeedingEventThread = 0;

@interface ChildView(Private)

// sets up our view, attaching it to its owning gecko view
- (id)initWithFrame:(NSRect)inFrame geckoChild:(nsChildView*)inChild;
- (void)forceRefreshOpenGL;

// set up a gecko mouse event based on a cocoa mouse event
- (void) convertCocoaMouseWheelEvent:(NSEvent*)aMouseEvent
                        toGeckoEvent:(WidgetWheelEvent*)outWheelEvent;
- (void) convertCocoaMouseEvent:(NSEvent*)aMouseEvent
                   toGeckoEvent:(WidgetInputEvent*)outGeckoEvent;

- (NSMenu*)contextMenu;

- (BOOL)isRectObscuredBySubview:(NSRect)inRect;

- (void)processPendingRedraws;

- (void)drawRect:(NSRect)aRect inContext:(CGContextRef)aContext;
- (LayoutDeviceIntRegion)nativeDirtyRegionWithBoundingRect:(NSRect)aRect;
- (BOOL)isUsingMainThreadOpenGL;
- (BOOL)isUsingOpenGL;
- (void)drawUsingOpenGL;
- (void)drawUsingOpenGLCallback;

- (BOOL)hasRoundedBottomCorners;
- (CGFloat)cornerRadius;
- (void)clearCorners;

// Overlay drawing functions for traditional CGContext drawing
- (void)drawTitleString;
- (void)drawTitlebarHighlight;
- (void)maskTopCornersInContext:(CGContextRef)aContext;

// Called using performSelector:withObject:afterDelay:0 to release
// aWidgetArray (and its contents) the next time through the run loop.
- (void)releaseWidgets:(NSArray*)aWidgetArray;

#if USE_CLICK_HOLD_CONTEXTMENU
 // called on a timer two seconds after a mouse down to see if we should display
 // a context menu (click-hold)
- (void)clickHoldCallback:(id)inEvent;
#endif

#ifdef ACCESSIBILITY
- (id<mozAccessible>)accessible;
#endif

- (LayoutDeviceIntPoint)convertWindowCoordinates:(NSPoint)aPoint;
- (APZCTreeManager*)apzctm;

- (BOOL)inactiveWindowAcceptsMouseEvent:(NSEvent*)aEvent;
- (void)updateWindowDraggableState;

- (bool)shouldConsiderStartingSwipeFromEvent:(NSEvent*)aEvent;

@end

@interface EventThreadRunner : NSObject
{
  NSThread* mThread;
}
- (id)init;

+ (void)start;
+ (void)stop;

@end

@interface NSView(NSThemeFrameCornerRadius)
- (float)roundedCornerRadius;
@end

@interface NSView(DraggableRegion)
- (CGSRegionObj)_regionForOpaqueDescendants:(NSRect)aRect forMove:(BOOL)aForMove;
- (CGSRegionObj)_regionForOpaqueDescendants:(NSRect)aRect forMove:(BOOL)aForMove forUnderTitlebar:(BOOL)aForUnderTitlebar;
@end

@interface NSWindow(NSWindowShouldZoomOnDoubleClick)
+ (BOOL)_shouldZoomOnDoubleClick; // present on 10.7 and above
@end

// Starting with 10.7 the bottom corners of all windows are rounded.
// Unfortunately, the standard rounding that OS X applies to OpenGL views
// does not use anti-aliasing and looks very crude. Since we want a smooth,
// anti-aliased curve, we'll draw it ourselves.
// Additionally, we need to turn off the OS-supplied rounding because it
// eats into our corner's curve. We do that by overriding an NSSurface method.
@interface NSSurface @end

@implementation NSSurface(DontCutOffCorners)
- (CGSRegionObj)_createRoundedBottomRegionForRect:(CGRect)rect
{
  // Create a normal rect region without rounded bottom corners.
  CGSRegionObj region;
  CGSNewRegionWithRect(&rect, &region);
  return region;
}
@end

#pragma mark -

// Key code constants
enum
{
  kEscapeKeyCode      = 0x35,
  kRCommandKeyCode    = 0x36, // right command key
  kCommandKeyCode     = 0x37,
  kShiftKeyCode       = 0x38,
  kCapsLockKeyCode    = 0x39,
  kOptionkeyCode      = 0x3A,
  kControlKeyCode     = 0x3B,
  kRShiftKeyCode      = 0x3C, // right shift key
  kROptionKeyCode     = 0x3D, // right option key
  kRControlKeyCode    = 0x3E, // right control key
  kClearKeyCode       = 0x47,

  // function keys
  kF1KeyCode          = 0x7A,
  kF2KeyCode          = 0x78,
  kF3KeyCode          = 0x63,
  kF4KeyCode          = 0x76,
  kF5KeyCode          = 0x60,
  kF6KeyCode          = 0x61,
  kF7KeyCode          = 0x62,
  kF8KeyCode          = 0x64,
  kF9KeyCode          = 0x65,
  kF10KeyCode         = 0x6D,
  kF11KeyCode         = 0x67,
  kF12KeyCode         = 0x6F,
  kF13KeyCode         = 0x69,
  kF14KeyCode         = 0x6B,
  kF15KeyCode         = 0x71,
  
  kPrintScreenKeyCode = kF13KeyCode,
  kScrollLockKeyCode  = kF14KeyCode,
  kPauseKeyCode       = kF15KeyCode,
  
  // keypad
  kKeypad0KeyCode     = 0x52,
  kKeypad1KeyCode     = 0x53,
  kKeypad2KeyCode     = 0x54,
  kKeypad3KeyCode     = 0x55,
  kKeypad4KeyCode     = 0x56,
  kKeypad5KeyCode     = 0x57,
  kKeypad6KeyCode     = 0x58,
  kKeypad7KeyCode     = 0x59,
  kKeypad8KeyCode     = 0x5B,
  kKeypad9KeyCode     = 0x5C,

// The following key codes are not defined until Mac OS X 10.5
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
  kVK_ANSI_1          = 0x12,
  kVK_ANSI_2          = 0x13,
  kVK_ANSI_3          = 0x14,
  kVK_ANSI_4          = 0x15,
  kVK_ANSI_5          = 0x17,
  kVK_ANSI_6          = 0x16,
  kVK_ANSI_7          = 0x1A,
  kVK_ANSI_8          = 0x1C,
  kVK_ANSI_9          = 0x19,
  kVK_ANSI_0          = 0x1D,
#endif

  kKeypadMultiplyKeyCode  = 0x43,
  kKeypadAddKeyCode       = 0x45,
  kKeypadSubtractKeyCode  = 0x4E,
  kKeypadDecimalKeyCode   = 0x41,
  kKeypadDivideKeyCode    = 0x4B,
  kKeypadEqualsKeyCode    = 0x51, // no correpsonding gecko key code
  kEnterKeyCode           = 0x4C,
  kReturnKeyCode          = 0x24,
  kPowerbookEnterKeyCode  = 0x34, // Enter on Powerbook's keyboard is different
  
  kInsertKeyCode          = 0x72, // also help key
  kDeleteKeyCode          = 0x75, // also forward delete key
  kTabKeyCode             = 0x30,
  kTildeKeyCode           = 0x32,
  kBackspaceKeyCode       = 0x33,
  kHomeKeyCode            = 0x73, 
  kEndKeyCode             = 0x77,
  kPageUpKeyCode          = 0x74,
  kPageDownKeyCode        = 0x79,
  kLeftArrowKeyCode       = 0x7B,
  kRightArrowKeyCode      = 0x7C,
  kUpArrowKeyCode         = 0x7E,
  kDownArrowKeyCode       = 0x7D
};
#define unsignedIntegerValue unsignedIntValue
#define numberWithUnsignedInteger numberWithUnsignedInt

#pragma mark -

/* Convenience routine to go from a Gecko rect to Cocoa NSRect.
 * (Restored for TenFourFox 43.)
 *
 * Gecko rects (nsRect) contain an origin (x,y) in a coordinate
 * system with (0,0) in the top-left of the screen. Cocoa rects
 * (NSRect) contain an origin (x,y) in a coordinate system with
 * (0,0) in the bottom-left of the screen. Both nsRect and NSRect
 * contain width/height info, with no difference in their use.
 * If a Cocoa rect is from a flipped view, there is no need to
 * convert coordinate systems.
 */
#ifndef __LP64__
static inline void
ConvertGeckoRectToMacRect(const nsIntRect& aRect, Rect& outMacRect)
{
  outMacRect.left = aRect.x;
  outMacRect.top = aRect.y;
  outMacRect.right = aRect.x + aRect.width;
  outMacRect.bottom = aRect.y + aRect.height;
}
#endif

// Flips a screen coordinate from a point in the cocoa coordinate system (bottom-left rect) to a point
// that is a "flipped" cocoa coordinate system (starts in the top-left).
static inline void
FlipCocoaScreenCoordinate(NSPoint &inPoint)
{
  inPoint.y = nsCocoaUtils::FlippedScreenY(inPoint.y);
}

#ifndef NS_LEOPARD_AND_LATER
// Functions that we had to restore for 10.4. Damn you, Mozilla!
// Maybe move these to nsCocoaUtils at some point ...
static inline void
GeckoRectToNSRect(const nsIntRect & inGeckoRect, NSRect & outCocoaRect)
{
  outCocoaRect.origin.x = inGeckoRect.x;
  outCocoaRect.origin.y = inGeckoRect.y;
  outCocoaRect.size.width = inGeckoRect.width;
  outCocoaRect.size.height = inGeckoRect.height;
}

/*
static inline void
InitPluginEvent(nsPluginEvent &aEvent, NPCocoaEvent &aCocoaEvent)
{
  aEvent.time = PR_IntervalNow();
  aEvent.pluginEvent = (void*)&aCocoaEvent;
  aEvent.retargetToFocusedDocument = false;
}
*/

static uint32_t
UnderlineAttributeToTextRangeType(PRUint32 aUnderlineStyle, NSRange selRange)
{
#ifdef DEBUG_IME
  NSLog(@"****in underlineAttributeToTextRangeType = %d", aUnderlineStyle);
#endif

  // For more info on the underline attribute, please see: 
  // http://developer.apple.com/techpubs/macosx/Cocoa/TasksAndConcepts/ProgrammingTopics/AttributedStrings/Tasks/AccessingAttrs.html
  // We are not clear where the define for value 2 is right now. 
  // To see this value in japanese ime, type 'aaaaaaaaa' and hit space to make the
  // ime send you some part of text in 1 (NSSingleUnderlineStyle) and some part in 2. 
  // ftang will ask apple for more details
  //
  // It probably means show 1-pixel thickness underline vs 2-pixel thickness.
  
  uint32_t attr;
  if (selRange.length == 0) {
    switch (aUnderlineStyle) {
      case 1:
        attr = NS_TEXTRANGE_RAWINPUT;
        break;
      case 2:
      default:
        attr = NS_TEXTRANGE_SELECTEDRAWTEXT;
        break;
    }
  }
  else {
    switch (aUnderlineStyle) {
      case 1:
        attr = NS_TEXTRANGE_CONVERTEDTEXT;
        break;
      case 2:
      default:
        attr = NS_TEXTRANGE_SELECTEDCONVERTEDTEXT;
        break;
    }
  }
  return attr;
}

static uint32_t
CountRanges(NSAttributedString *aString)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  // Iterate through aString for the NSUnderlineStyleAttributeName and count the
  // different segments adjusting limitRange as we go.
  uint32_t count = 0;
  NSRange effectiveRange;
  NSRange limitRange = NSMakeRange(0, [aString length]);
  while (limitRange.length > 0) {
    [aString attribute:NSUnderlineStyleAttributeName 
               atIndex:limitRange.location 
 longestEffectiveRange:&effectiveRange
               inRange:limitRange];
    limitRange = NSMakeRange(NSMaxRange(effectiveRange), 
                             NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
    count++;
  }
  return count;
  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(0);
}

static already_AddRefed<mozilla::TextRangeArray>
ConvertAttributeToGeckoRange(NSAttributedString *aString, NSRange markRange, NSRange selRange, uint32_t inCount)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSNULL;

  // Convert the Cocoa range into the TextRange Array used in Gecko.
  // Iterate through the attributed string and map the underline attribute to Gecko IME textrange attributes.
  // We may need to change the code here if we change the implementation of validAttributesForMarkedText.
  uint32_t i = 0;
  NSRange effectiveRange;
  NSRange limitRange = NSMakeRange(0, [aString length]);
  RefPtr<mozilla::TextRangeArray> textRangeArray =
                                      new mozilla::TextRangeArray();
  while ((limitRange.length > 0) && (i < inCount)) {
    id attributeValue = [aString attribute:NSUnderlineStyleAttributeName 
                              atIndex:limitRange.location 
                              longestEffectiveRange:&effectiveRange
                              inRange:limitRange];
    mozilla::TextRange range;
    range.mStartOffset = effectiveRange.location;
    range.mEndOffset = NSMaxRange(effectiveRange);
    range.mRangeType = UnderlineAttributeToTextRangeType([attributeValue intValue], selRange); 
    textRangeArray->AppendElement(range);

    limitRange = NSMakeRange(NSMaxRange(effectiveRange), 
                             NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
    i++;
  }
  // Get current caret position.
  mozilla::TextRange range;
  range.mStartOffset = selRange.location + selRange.length;
  range.mEndOffset = range.mStartOffset;
  range.mRangeType = NS_TEXTRANGE_CARETPOSITION;
  textRangeArray->AppendElement(range);

  return textRangeArray.forget();

  NS_OBJC_END_TRY_ABORT_BLOCK_NSNULL;
}

#endif

void EnsureLogInitialized()
{
  if (!sCocoaLog) {
    sCocoaLog = PR_NewLogModule("nsCocoaWidgets");
  }
}

namespace {

// Manages a texture which can resize dynamically, binds to the
// LOCAL_GL_TEXTURE_RECTANGLE_ARB texture target and is automatically backed
// by a power-of-two size GL texture. The latter two features are used for
// compatibility with older Mac hardware which we block GL layers on.
// RectTextureImages are used both for accelerated GL layers drawing and for
// OMTC BasicLayers drawing.
class RectTextureImage {
public:
  explicit RectTextureImage(GLContext* aGLContext)
   : mGLContext(aGLContext)
   , mTexture(0)
   , mInUpdate(false)
  {}

  virtual ~RectTextureImage();

  already_AddRefed<gfx::DrawTarget>
    BeginUpdate(const LayoutDeviceIntSize& aNewSize,
                const LayoutDeviceIntRegion& aDirtyRegion =
                  LayoutDeviceIntRegion());
  void EndUpdate(bool aKeepSurface = false);

  void UpdateIfNeeded(const LayoutDeviceIntSize& aNewSize,
                      const LayoutDeviceIntRegion& aDirtyRegion,
                      void (*aCallback)(gfx::DrawTarget*,
                                        const LayoutDeviceIntRegion&))
  {
    RefPtr<gfx::DrawTarget> drawTarget = BeginUpdate(aNewSize, aDirtyRegion);
    if (drawTarget) {
      aCallback(drawTarget, GetUpdateRegion());
      EndUpdate();
    }
  }

  void UpdateFromCGContext(const LayoutDeviceIntSize& aNewSize,
                           const LayoutDeviceIntRegion& aDirtyRegion,
                           CGContextRef aCGContext);

  LayoutDeviceIntRegion GetUpdateRegion() {
    MOZ_ASSERT(mInUpdate, "update region only valid during update");
    return mUpdateRegion;
  }

  void Draw(mozilla::layers::GLManager* aManager,
            const LayoutDeviceIntPoint& aLocation,
            const Matrix4x4& aTransform = Matrix4x4());

  static LayoutDeviceIntSize TextureSizeForSize(
    const LayoutDeviceIntSize& aSize);

protected:

  RefPtr<gfx::DrawTarget> mUpdateDrawTarget;
  GLContext* mGLContext;
  LayoutDeviceIntRegion mUpdateRegion;
  LayoutDeviceIntSize mUsedSize;
  LayoutDeviceIntSize mBufferSize;
  LayoutDeviceIntSize mTextureSize;
  GLuint mTexture;
  bool mInUpdate;
};

// Used for OpenGL drawing from the compositor thread for OMTC BasicLayers.
// We need to use OpenGL for this because there seems to be no other robust
// way of drawing from a secondary thread without locking, which would cause
// deadlocks in our setup. See bug 882523.
class GLPresenter : public GLManager
{
public:
  static GLPresenter* CreateForWindow(nsIWidget* aWindow)
  {
    // Contrary to CompositorOGL, we allow unaccelerated OpenGL contexts to be
    // used. BasicCompositor only requires very basic GL functionality.
    RefPtr<GLContext> context = gl::GLContextProvider::CreateForWindow(aWindow, false);
    return context ? new GLPresenter(context) : nullptr;
  }

  explicit GLPresenter(GLContext* aContext);
  virtual ~GLPresenter();

  virtual GLContext* gl() const override { return mGLContext; }
  virtual ShaderProgramOGL* GetProgram(GLenum aTarget, gfx::SurfaceFormat aFormat) override
  {
    MOZ_ASSERT(aTarget == LOCAL_GL_TEXTURE_RECTANGLE_ARB);
    MOZ_ASSERT(aFormat == gfx::SurfaceFormat::R8G8B8A8);
    return mRGBARectProgram;
  }
  virtual const gfx::Matrix4x4& GetProjMatrix() const override
  {
    return mProjMatrix;
  }
  virtual void ActivateProgram(ShaderProgramOGL *aProg) override
  {
    mGLContext->fUseProgram(aProg->GetProgram());
  }
  virtual void BindAndDrawQuad(ShaderProgramOGL *aProg,
                               const gfx::Rect& aLayerRect,
                               const gfx::Rect& aTextureRect) override;

  void BeginFrame(LayoutDeviceIntSize aRenderSize);
  void EndFrame();

  NSOpenGLContext* GetNSOpenGLContext()
  {
    return GLContextCGL::Cast(mGLContext)->GetNSOpenGLContext();
  }

protected:
  RefPtr<mozilla::gl::GLContext> mGLContext;
  nsAutoPtr<mozilla::layers::ShaderProgramOGL> mRGBARectProgram;
  gfx::Matrix4x4 mProjMatrix;
  GLuint mQuadVBO;
};

} // unnamed namespace

namespace mozilla {

struct SwipeEventQueue {
  SwipeEventQueue(uint32_t aAllowedDirections, uint64_t aInputBlockId)
    : allowedDirections(aAllowedDirections)
    , inputBlockId(aInputBlockId)
  {}

  nsTArray<PanGestureInput> queuedEvents;
  uint32_t allowedDirections;
  uint64_t inputBlockId;
};

} // namespace mozilla

#pragma mark -

nsChildView::nsChildView() : nsBaseWidget()
, mView(nullptr)
, mParentView(nullptr)
, mParentWidget(nullptr)
, mViewTearDownLock("ChildViewTearDown")
, mEffectsLock("WidgetEffects")
, mShowsResizeIndicator(false)
, mHasRoundedBottomCorners(false)
, mIsCoveringTitlebar(false)
, mIsFullscreen(false)
, mTitlebarCGContext(nullptr)
, mBackingScaleFactor(0.0)
, mVisible(false)
, mDrawing(false)
, mIsDispatchPaint(false)
{
  EnsureLogInitialized();

  if (nsCocoaFeatures::OnLeopardOrLater() && !Leopard_TISCopyCurrentKeyboardLayoutInputSource) {
    // This library would already be open for LMGetKbdType (and probably other
    // symbols), so merely using RTLD_DEFAULT in dlsym would be sufficient,
    // but man dlsym says: "all mach-o images in the process (except ...) are
    // searched in the order they were loaded.  This can be a costly search
    // and should be avoided."
    void* hitoolboxHandle = dlopen("/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/A/HIToolbox", RTLD_LAZY);
    if (hitoolboxHandle) {
      *(void **)(&Leopard_TISCopyCurrentKeyboardInputSource) = dlsym(hitoolboxHandle, "TISCopyCurrentKeyboardInputSource");
      *(void **)(&Leopard_TISCopyCurrentKeyboardLayoutInputSource) = dlsym(hitoolboxHandle, "TISCopyCurrentKeyboardLayoutInputSource");
      *(void **)(&Leopard_TISGetInputSourceProperty) = dlsym(hitoolboxHandle, "TISGetInputSourceProperty");
      *(void **)(&Leopard_TISCreateInputSourceList) = dlsym(hitoolboxHandle, "TISCreateInputSourceList");
      kOurTISPropertyUnicodeKeyLayoutData = *static_cast<CFStringRef*>(dlsym(hitoolboxHandle, "kTISPropertyUnicodeKeyLayoutData"));
      kOurTISPropertyInputSourceID = *static_cast<CFStringRef*>(dlsym(hitoolboxHandle, "kTISPropertyInputSourceID"));
      kOurTISPropertyInputSourceLanguages = *static_cast<CFStringRef*>(dlsym(hitoolboxHandle, "kTISPropertyInputSourceLanguages"));
    }
  }
}

nsChildView::~nsChildView()
{
  ReleaseTitlebarCGContext();

  if (mSwipeTracker) {
    mSwipeTracker->Destroy();
    mSwipeTracker = nullptr;
  }

  // Notify the children that we're gone.  childView->ResetParent() can change
  // our list of children while it's being iterated, so the way we iterate the
  // list must allow for this.
  for (nsIWidget* kid = mLastChild; kid;) {
    nsChildView* childView = static_cast<nsChildView*>(kid);
    kid = kid->GetPrevSibling();
    childView->ResetParent();
  }

  NS_WARN_IF_FALSE(mOnDestroyCalled, "nsChildView object destroyed without calling Destroy()");

  DestroyCompositor();

  if (mAPZC && gfxPrefs::AsyncPanZoomSeparateEventThread()) {
    gNumberOfWidgetsNeedingEventThread--;
    if (gNumberOfWidgetsNeedingEventThread == 0) {
      [EventThreadRunner stop];
    }
  }

  // An nsChildView object that was in use can be destroyed without Destroy()
  // ever being called on it.  So we also need to do a quick, safe cleanup
  // here (it's too late to just call Destroy(), which can cause crashes).
  // It's particularly important to make sure widgetDestroyed is called on our
  // mView -- this method NULLs mView's mGeckoChild, and NULL checks on
  // mGeckoChild are used throughout the ChildView class to tell if it's safe
  // to use a ChildView object.
  [mView widgetDestroyed]; // Safe if mView is nil.
  mParentWidget = nil;
  TearDownView(); // Safe if called twice.
}

void
nsChildView::ReleaseTitlebarCGContext()
{
  if (mTitlebarCGContext) {
    CGContextRelease(mTitlebarCGContext);
    mTitlebarCGContext = nullptr;
  }
}

nsresult nsChildView::Create(nsIWidget* aParent,
                             nsNativeWidget aNativeParent,
                             const LayoutDeviceIntRect& aRect,
                             nsWidgetInitData* aInitData)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  // Because the hidden window is created outside of an event loop,
  // we need to provide an autorelease pool to avoid leaking cocoa objects
  // (see bug 559075).
  nsAutoreleasePool localPool;

  // See NSView (MethodSwizzling) below.
  if (nsCocoaFeatures::OnLeopardOrLater() && !gChildViewMethodsSwizzled) {
    nsToolkit::SwizzleMethods([NSView class], @selector(mouseDownCanMoveWindow),
                              @selector(nsChildView_NSView_mouseDownCanMoveWindow));
#ifdef __LP64__
    if (nsCocoaFeatures::OnLionOrLater()) {
      nsToolkit::SwizzleMethods([NSEvent class], @selector(addLocalMonitorForEventsMatchingMask:handler:),
                                @selector(nsChildView_NSEvent_addLocalMonitorForEventsMatchingMask:handler:),
                                true);
      nsToolkit::SwizzleMethods([NSEvent class], @selector(removeMonitor:),
                                @selector(nsChildView_NSEvent_removeMonitor:), true);
    }
#endif
    gChildViewMethodsSwizzled = true;
  }

  mBounds = aRect.ToUnknownRect();

  // Ensure that the toolkit is created.
  nsToolkit::GetToolkit();

  BaseCreate(aParent, aRect, aInitData);

  // inherit things from the parent view and create our parallel
  // NSView in the Cocoa display system
  mParentView = nil;
  if (aParent) {
    // inherit the top-level window. NS_NATIVE_WIDGET is always a NSView
    // regardless of if we're asking a window or a view (for compatibility
    // with windows).
    mParentView = (NSView<mozView>*)aParent->GetNativeData(NS_NATIVE_WIDGET);
    mParentWidget = aParent;
  } else {
    // This is the normal case. When we're the root widget of the view hiararchy,
    // aNativeParent will be the contentView of our window, since that's what
    // nsCocoaWindow returns when asked for an NS_NATIVE_VIEW.
    mParentView = reinterpret_cast<NSView<mozView>*>(aNativeParent);
  }

  // create our parallel NSView and hook it up to our parent. Recall
  // that NS_NATIVE_WIDGET is the NSView.
  CGFloat scaleFactor = 1.0f; //nsCocoaUtils::GetBackingScaleFactor(mParentView);
  NSRect r = nsCocoaUtils::DevPixelsToCocoaPoints(
    LayoutDeviceIntRect::FromUnknownRect(mBounds));
  mView = [(NSView<mozView>*)CreateCocoaView(r) retain];
  if (!mView) {
    return NS_ERROR_FAILURE;
  }

  // If this view was created in a Gecko view hierarchy, the initial state
  // is hidden.  If the view is attached only to a native NSView but has
  // no Gecko parent (as in embedding), the initial state is visible.
  if (mParentWidget)
    [mView setHidden:YES];
  else
    mVisible = true;

  // Hook it up in the NSView hierarchy.
  if (mParentView) {
    [mParentView addSubview:mView];
  }

  // if this is a ChildView, make sure that our per-window data
  // is set up
  if ([mView isKindOfClass:[ChildView class]])
    [[WindowDataMap sharedWindowDataMap] ensureDataForWindow:[mView window]];

#if(0)
  NS_ASSERTION(!mTextInputHandler, "mTextInputHandler has already existed");
  mTextInputHandler = new TextInputHandler(this, mView);
#endif

  mPluginFocused = false;

  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

// Creates the appropriate child view. Override to create something other than
// our |ChildView| object. Autoreleases, so caller must retain.
NSView*
nsChildView::CreateCocoaView(NSRect inFrame)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  return [[[ChildView alloc] initWithFrame:inFrame geckoChild:this] autorelease];

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}

void nsChildView::TearDownView()
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!mView)
    return;

  NSWindow* win = [mView window];
  NSResponder* responder = [win firstResponder];

  // We're being unhooked from the view hierarchy, don't leave our view
  // or a child view as the window first responder.
  if (responder && [responder isKindOfClass:[NSView class]] &&
      [(NSView*)responder isDescendantOf:mView]) {
    [win makeFirstResponder:[mView superview]];
  }

  // If mView is win's contentView, win (mView's NSWindow) "owns" mView --
  // win has retained mView, and will detach it from the view hierarchy and
  // release it when necessary (when win is itself destroyed (in a call to
  // [win dealloc])).  So all we need to do here is call [mView release] (to
  // match the call to [mView retain] in nsChildView::StandardCreate()).
  // Also calling [mView removeFromSuperviewWithoutNeedingDisplay] causes
  // mView to be released again and dealloced, while remaining win's
  // contentView.  So if we do that here, win will (for a short while) have
  // an invalid contentView (for the consequences see bmo bugs 381087 and
  // 374260).
  if ([mView isEqual:[win contentView]]) {
    [mView release];
  } else {
    // Stop NSView hierarchy being changed during [ChildView drawRect:]
    [mView performSelectorOnMainThread:@selector(delayedTearDown) withObject:nil waitUntilDone:false];
  }
  mView = nil;

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

nsCocoaWindow*
nsChildView::GetXULWindowWidget()
{
  id windowDelegate = [[mView window] delegate];
  if (windowDelegate && [windowDelegate isKindOfClass:[WindowDelegate class]]) {
    return [(WindowDelegate *)windowDelegate geckoWidget];
  }
  return nullptr;
}

NS_IMETHODIMP nsChildView::Destroy()
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  // Make sure that no composition is in progress while disconnecting
  // ourselves from the view.
  MutexAutoLock lock(mViewTearDownLock);

  if (mOnDestroyCalled)
    return NS_OK;
  mOnDestroyCalled = true;

  [mView widgetDestroyed];

  nsBaseWidget::Destroy();

  NotifyWindowDestroyed();
  mParentWidget = nil;

  TearDownView();

  nsBaseWidget::OnDestroy();

  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

#pragma mark -

#if 0
static void PrintViewHierarchy(NSView *view)
{
  while (view) {
    NSLog(@"  view is %x, frame %@", view, NSStringFromRect([view frame]));
    view = [view superview];
  }
}
#endif

// Return native data according to aDataType
void* nsChildView::GetNativeData(uint32_t aDataType)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSNULL;

  void* retVal = nullptr;

  switch (aDataType)
  {
    case NS_NATIVE_WIDGET:
    case NS_NATIVE_DISPLAY:
      retVal = (void*)mView;
      break;

    case NS_NATIVE_WINDOW:
      retVal = [mView window];
      break;

    case NS_NATIVE_GRAPHIC:
      NS_ERROR("Requesting NS_NATIVE_GRAPHIC on a Mac OS X child view!");
      retVal = nullptr;
      break;

    case NS_NATIVE_OFFSETX:
      retVal = 0;
      break;

    case NS_NATIVE_OFFSETY:
      retVal = 0;
      break;

    case NS_RAW_NATIVE_IME_CONTEXT:
      retVal = [mView inputContext];
      // If input context isn't available on this widget, we should set |this|
      // instead of nullptr since if this returns nullptr, IMEStateManager
      // cannot manage composition with TextComposition instance.  Although,
      // this case shouldn't occur.
      if (NS_WARN_IF(!retVal)) {
        retVal = this;
      }
      break;
  }

  return retVal;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSNULL;
}

#pragma mark -

nsTransparencyMode nsChildView::GetTransparencyMode()
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  nsCocoaWindow* windowWidget = GetXULWindowWidget();
  return windowWidget ? windowWidget->GetTransparencyMode() : eTransparencyOpaque;

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(eTransparencyOpaque);
}

// This is called by nsContainerFrame on the root widget for all window types
// except popup windows (when nsCocoaWindow::SetTransparencyMode is used instead).
void nsChildView::SetTransparencyMode(nsTransparencyMode aMode)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  nsCocoaWindow* windowWidget = GetXULWindowWidget();
  if (windowWidget) {
    windowWidget->SetTransparencyMode(aMode);
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

bool nsChildView::IsVisible() const
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  if (!mVisible) {
    return mVisible;
  }

  // mVisible does not accurately reflect the state of a hidden tabbed view
  // so verify that the view has a window as well
  // then check native widget hierarchy visibility
  return ([mView window] != nil) && !NSIsEmptyRect([mView visibleRect]);

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(false);
}

// Some NSView methods (e.g. setFrame and setHidden) invalidate the view's
// bounds in our window. However, we don't want these invalidations because
// they are unnecessary and because they actually slow us down since we
// block on the compositor inside drawRect.
// When we actually need something invalidated, there will be an explicit call
// to Invalidate from Gecko, so turning these automatic invalidations off
// won't hurt us in the non-OMTC case.
// The invalidations inside these NSView methods happen via a call to the
// private method -[NSWindow _setNeedsDisplayInRect:]. Our BaseWindow
// implementation of that method is augmented to let us ignore those calls
// using -[BaseWindow disable/enableSetNeedsDisplay].
// For 10.4, we just wrap calls to this together.
#if(0)
static void
ManipulateViewWithoutNeedingDisplay(NSView* aView, void (^aCallback)())
{
  BaseWindow* win = nil;
  if ([[aView window] isKindOfClass:[BaseWindow class]]) {
    win = (BaseWindow*)[aView window];
  }
  [win disableSetNeedsDisplay];
  aCallback();
  [win enableSetNeedsDisplay];
}
#else
#define MVWND(x,y) { BaseWindow* win = nil; if ([[x window] isKindOfClass:[BaseWindow class]]) { win = (BaseWindow*)[x window]; } [win disableSetNeedsDisplay]; y; [win enableSetNeedsDisplay]; }
#endif

// Hide or show this component
NS_IMETHODIMP nsChildView::Show(bool aState)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  if (aState != mVisible) {
    // Provide an autorelease pool because this gets called during startup
    // on the "hidden window", resulting in cocoa object leakage if there's
    // no pool in place.
    nsAutoreleasePool localPool;

#if(0)
    ManipulateViewWithoutNeedingDisplay(mView, ^{
      [mView setHidden:!aState];
    });
#else
    MVWND(mView, [mView setHidden:!aState]);
#endif

    mVisible = aState;
  }
  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

// Change the parent of this widget
NS_IMETHODIMP
nsChildView::SetParent(nsIWidget* aNewParent)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  if (mOnDestroyCalled)
    return NS_OK;

  nsCOMPtr<nsIWidget> kungFuDeathGrip(this);

  if (mParentWidget) {
    mParentWidget->RemoveChild(this);
  }

  if (aNewParent) {
    ReparentNativeWidget(aNewParent);
  } else {
    [mView removeFromSuperview];
    mParentView = nil;
  }

  mParentWidget = aNewParent;

  if (mParentWidget) {
    mParentWidget->AddChild(this);
  }

  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

NS_IMETHODIMP
nsChildView::ReparentNativeWidget(nsIWidget* aNewParent)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  NS_PRECONDITION(aNewParent, "");

  if (mOnDestroyCalled)
    return NS_OK;

  NSView<mozView>* newParentView =
   (NSView<mozView>*)aNewParent->GetNativeData(NS_NATIVE_WIDGET);
  NS_ENSURE_TRUE(newParentView, NS_ERROR_FAILURE);

  // we hold a ref to mView, so this is safe
  [mView removeFromSuperview];
  mParentView = newParentView;
  [mParentView addSubview:mView];
  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

void nsChildView::ResetParent()
{
  if (!mOnDestroyCalled) {
    if (mParentWidget)
      mParentWidget->RemoveChild(this);
    if (mView)
      [mView removeFromSuperview];
  }
  mParentWidget = nullptr;
}

nsIWidget*
nsChildView::GetParent()
{
  return mParentWidget;
}

float
nsChildView::GetDPI()
{
  NSWindow* window = [mView window];
  if (window && [window isKindOfClass:[BaseWindow class]]) {
    return [(BaseWindow*)window getDPI];
  }

  return 96.0;
}

NS_IMETHODIMP nsChildView::Enable(bool aState)
{
  return NS_OK;
}

bool nsChildView::IsEnabled() const
{
  return true;
}

NS_IMETHODIMP nsChildView::SetFocus(bool aRaise)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  NSWindow* window = [mView window];
  if (window)
    [window makeFirstResponder:mView];
  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

// Override to set the cursor on the mac
NS_IMETHODIMP nsChildView::SetCursor(nsCursor aCursor)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

// this should nop out (Cameron)
  if ([mView isDragInProgress])
    return NS_OK; // Don't change the cursor during dragging.

  nsBaseWidget::SetCursor(aCursor);
  return [[nsCursorManager sharedInstance] setCursor:aCursor];

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

// implement to fix "hidden virtual function" warning
NS_IMETHODIMP nsChildView::SetCursor(imgIContainer* aCursor,
                                      uint32_t aHotspotX, uint32_t aHotspotY)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  nsBaseWidget::SetCursor(aCursor, aHotspotX, aHotspotY);
  return [[nsCursorManager sharedInstance] setCursorWithImage:aCursor hotSpotX:aHotspotX hotSpotY:aHotspotY];

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

#pragma mark -

// Get this component dimension
NS_IMETHODIMP nsChildView::GetBounds(LayoutDeviceIntRect& aRect)
{
  aRect = !mView
        ? LayoutDeviceIntRect::FromUnknownRect(mBounds)
        : CocoaPointsToDevPixels([mView frame]);
  return NS_OK;
}

NS_IMETHODIMP nsChildView::GetClientBounds(mozilla::LayoutDeviceIntRect& aRect)
{
  GetBounds(aRect);
  if (!mParentWidget) {
    // For top level widgets we want the position on screen, not the position
    // of this view inside the window.
    aRect.MoveTo(WidgetToScreenOffset());
  }
  return NS_OK;
}

NS_IMETHODIMP nsChildView::GetScreenBounds(LayoutDeviceIntRect& aRect)
{
  GetBounds(aRect);
  aRect.MoveTo(WidgetToScreenOffset());
  return NS_OK;
}

#if(0)
double
nsChildView::GetDefaultScaleInternal()
{
  return BackingScaleFactor();
}

CGFloat
nsChildView::BackingScaleFactor() const
{
  if (mBackingScaleFactor > 0.0) {
    return mBackingScaleFactor;
  }
  if (!mView) {
    return 1.0;
  }
  mBackingScaleFactor = nsCocoaUtils::GetBackingScaleFactor(mView);
  return mBackingScaleFactor;
}

void
nsChildView::BackingScaleFactorChanged()
{
  CGFloat newScale = nsCocoaUtils::GetBackingScaleFactor(mView);

  // ignore notification if it hasn't really changed (or maybe we have
  // disabled HiDPI mode via prefs)
  if (mBackingScaleFactor == newScale) {
    return;
  }

  mBackingScaleFactor = newScale;

  if (mWidgetListener && !mWidgetListener->GetXULWindow()) {
    nsIPresShell* presShell = mWidgetListener->GetPresShell();
    if (presShell) {
      presShell->BackingScaleFactorChanged();
    }
  }
}

int32_t
nsChildView::RoundsWidgetCoordinatesTo()
{
  if (BackingScaleFactor() == 2.0) {
    return 2;
  }
  return 1;
}
#endif

NS_IMETHODIMP nsChildView::ConstrainPosition(bool aAllowSlop,
                                             int32_t *aX, int32_t *aY)
{
  return NS_OK;
}

// Move this component, aX and aY are in the parent widget coordinate system
NS_IMETHODIMP nsChildView::Move(double aX, double aY)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  int32_t x = NSToIntRound(aX);
  int32_t y = NSToIntRound(aY);

  if (!mView || (mBounds.x == x && mBounds.y == y))
    return NS_OK;

  mBounds.x = x;
  mBounds.y = y;

#if(0)
  ManipulateViewWithoutNeedingDisplay(mView, ^{
    [mView setFrame:UntypedDevPixelsToCocoaPoints(mBounds)];
  });
#else
  MVWND(mView, [mView setFrame:UntypedDevPixelsToCocoaPoints(mBounds)]);
#endif

  NotifyRollupGeometryChange();
  ReportMoveEvent();

  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

NS_IMETHODIMP nsChildView::Resize(double aWidth, double aHeight, bool aRepaint)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  int32_t width = NSToIntRound(aWidth);
  int32_t height = NSToIntRound(aHeight);

  if (!mView || (mBounds.width == width && mBounds.height == height))
    return NS_OK;

  mBounds.width  = width;
  mBounds.height = height;

#if(0)
  ManipulateViewWithoutNeedingDisplay(mView, ^{
    [mView setFrame:UntypedDevPixelsToCocoaPoints(mBounds)];
  });
#else
  MVWND(mView, [mView setFrame:UntypedDevPixelsToCocoaPoints(mBounds)]);
#endif

  if (mVisible && aRepaint)
    [mView setNeedsDisplay:YES];

  NotifyRollupGeometryChange();
  ReportSizeEvent();

  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

NS_IMETHODIMP nsChildView::Resize(double aX, double aY,
                                  double aWidth, double aHeight, bool aRepaint)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  int32_t x = NSToIntRound(aX);
  int32_t y = NSToIntRound(aY);
  int32_t width = NSToIntRound(aWidth);
  int32_t height = NSToIntRound(aHeight);

  BOOL isMoving = (mBounds.x != x || mBounds.y != y);
  BOOL isResizing = (mBounds.width != width || mBounds.height != height);
  if (!mView || (!isMoving && !isResizing))
    return NS_OK;

  if (isMoving) {
    mBounds.x = x;
    mBounds.y = y;
  }
  if (isResizing) {
    mBounds.width  = width;
    mBounds.height = height;
  }

#if(0)
  ManipulateViewWithoutNeedingDisplay(mView, ^{
    [mView setFrame:UntypedDevPixelsToCocoaPoints(mBounds)];
  });
#else
  MVWND(mView, [mView setFrame:UntypedDevPixelsToCocoaPoints(mBounds)]);
#endif

  if (mVisible && aRepaint)
    [mView setNeedsDisplay:YES];

  NotifyRollupGeometryChange();
  if (isMoving) {
    ReportMoveEvent();
    if (mOnDestroyCalled)
      return NS_OK;
  }
  if (isResizing)
    ReportSizeEvent();

  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

static const int32_t resizeIndicatorWidth = 15;
static const int32_t resizeIndicatorHeight = 15;
bool nsChildView::ShowsResizeIndicator(LayoutDeviceIntRect* aResizerRect)
{
  NSView *topLevelView = mView, *superView = nil;
  while ((superView = [topLevelView superview]))
    topLevelView = superView;

  if (![[topLevelView window] showsResizeIndicator] ||
      !([[topLevelView window] styleMask] & NSResizableWindowMask))
    return false;

  if (aResizerRect) {
    NSSize bounds = [topLevelView bounds].size;
    NSPoint corner = NSMakePoint(bounds.width, [topLevelView isFlipped] ? bounds.height : 0);
    corner = [topLevelView convertPoint:corner toView:mView];
    aResizerRect->SetRect(NSToIntRound(corner.x) - resizeIndicatorWidth,
                          NSToIntRound(corner.y) - resizeIndicatorHeight,
                          resizeIndicatorWidth, resizeIndicatorHeight);
  }
  return true;
}

// This is needed for 10.4's SynthesizeNativeKeyEvent.
static NSString* ToNSString(const nsAString& aString)
{
  return [NSString stringWithCharacters:aString.BeginReading()
                                 length:aString.Length()];
}

struct KeyboardLayoutOverride {
  int32_t mKeyboardLayout;
  bool mOverrideEnabled;
};

static KeyboardLayoutOverride gOverrideKeyboardLayout;

static const uint32_t sModifierFlagMap[][2] = {
  { nsIWidget::CAPS_LOCK, NSAlphaShiftKeyMask },
  { nsIWidget::SHIFT_L, NSShiftKeyMask },
  { nsIWidget::SHIFT_R, NSShiftKeyMask },
  { nsIWidget::CTRL_L, NSControlKeyMask },
  { nsIWidget::CTRL_R, NSControlKeyMask },
  { nsIWidget::ALT_L, NSAlternateKeyMask },
  { nsIWidget::ALT_R, NSAlternateKeyMask },
  { nsIWidget::COMMAND_L, NSCommandKeyMask },
  { nsIWidget::COMMAND_R, NSCommandKeyMask },
  { nsIWidget::NUMERIC_KEY_PAD, NSNumericPadKeyMask },
  { nsIWidget::HELP, NSHelpKeyMask },
  { nsIWidget::FUNCTION, NSFunctionKeyMask }
};

nsresult nsChildView::SynthesizeNativeKeyEvent(int32_t aNativeKeyboardLayout,
                                               int32_t aNativeKeyCode,
                                               uint32_t aModifierFlags,
                                               const nsAString& aCharacters,
                                               const nsAString& aUnmodifiedCharacters,
                                               nsIObserver* aObserver)
{
  AutoObserverNotifier notifier(aObserver, "keyevent");
#if(0)
  return mTextInputHandler->SynthesizeNativeKeyEvent(aNativeKeyboardLayout,
                                                     aNativeKeyCode,
                                                     aModifierFlags,
                                                     aCharacters,
                                                     aUnmodifiedCharacters);
#else
// Use the Mozilla 7 code.
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;
  
  uint32_t modifierFlags = 0;
  for (uint32_t i = 0; i < 12; ++i) { // NS_ARRAY_LENGTH(sModifierFlagMap); ++i) {
    if (aModifierFlags & sModifierFlagMap[i][0]) {
      modifierFlags |= sModifierFlagMap[i][1];
    }
  }
  int windowNumber = [[mView window] windowNumber];
  BOOL sendFlagsChangedEvent = NO;
  switch (aNativeKeyCode) {
    case kCapsLockKeyCode:
    case kRCommandKeyCode:
    case kCommandKeyCode:
    case kShiftKeyCode:
    case kOptionkeyCode:
    case kControlKeyCode:
    case kRShiftKeyCode:
    case kROptionKeyCode:
    case kRControlKeyCode:
      sendFlagsChangedEvent = YES;
  }
  NSEventType eventType = sendFlagsChangedEvent ? NSFlagsChanged : NSKeyDown;
  NSEvent* downEvent = [NSEvent keyEventWithType:eventType
                                        location:NSMakePoint(0,0)
                                   modifierFlags:modifierFlags
                                       timestamp:0
                                    windowNumber:windowNumber
                                         context:[NSGraphicsContext currentContext]
                                      characters:ToNSString(aCharacters)
                     charactersIgnoringModifiers:ToNSString(aUnmodifiedCharacters)
                                       isARepeat:NO
                                         keyCode:aNativeKeyCode];

  NSEvent* upEvent = sendFlagsChangedEvent ? nil :
                       [ChildView makeNewCocoaEventWithType:NSKeyUp
                                                  fromEvent:downEvent];

  if (downEvent && (sendFlagsChangedEvent || upEvent)) {
    KeyboardLayoutOverride currentLayout = gOverrideKeyboardLayout;
    gOverrideKeyboardLayout.mKeyboardLayout = aNativeKeyboardLayout;
    gOverrideKeyboardLayout.mOverrideEnabled = true;
    [NSApp sendEvent:downEvent];
    if (upEvent)
      [NSApp sendEvent:upEvent];
    // processKeyDownEvent and keyUp block exceptions so we're sure to
    // reach here to restore gOverrideKeyboardLayout
    gOverrideKeyboardLayout = currentLayout;
  }

  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
#endif
}

nsresult nsChildView::SynthesizeNativeMouseEvent(LayoutDeviceIntPoint aPoint,
                                                 uint32_t aNativeMessage,
                                                 uint32_t aModifierFlags,
                                                 nsIObserver* aObserver)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  AutoObserverNotifier notifier(aObserver, "mouseevent");

#if(0)
  NSPoint pt =
    nsCocoaUtils::DevPixelsToCocoaPoints(aPoint, BackingScaleFactor());

  // Move the mouse cursor to the requested position and reconnect it to the mouse.
  CGWarpMouseCursorPosition(NSPointToCGPoint(pt));
  CGAssociateMouseAndMouseCursorPosition(true);

  // aPoint is given with the origin on the top left, but convertScreenToBase
  // expects a point in a coordinate system that has its origin on the bottom left.
  NSPoint screenPoint = NSMakePoint(pt.x, nsCocoaUtils::FlippedScreenY(pt.y));
#else

  // Use the simpler code from before; it's slightly faster.

#ifdef DEBUG
   fprintf(stderr, "Sending Mouse event %i to %i\n", aNativeMessage,
       [[mView window] windowNumber]);
#endif
  // Move the mouse cursor to the requested position and reconnect it to
  // the mouse.
  CGWarpMouseCursorPosition(CGPointMake(aPoint.x, aPoint.y));
  CGAssociateMouseAndMouseCursorPosition(true);

  // aPoint is given with the origin on the top left, but convertScreenToBase
  // expects a point in a coordinate system that has its origin on the bottom
  // left.
  NSPoint screenPoint = NSMakePoint(aPoint.x,
	[[NSScreen mainScreen] frame].size.height - aPoint.y);

#endif
  NSPoint windowPoint = [[mView window] convertScreenToBase:screenPoint];

  NSEvent* event = [NSEvent mouseEventWithType:(NSEventType)aNativeMessage
                                      location:windowPoint
                                 modifierFlags:aModifierFlags
#if(0)
                                     timestamp:[[NSProcessInfo processInfo] systemUptime]
#else
                                     timestamp:[NSDate timeIntervalSinceReferenceDate]
#endif
                                  windowNumber:[[mView window] windowNumber]
                                       context:nil
                                   eventNumber:0
                                    clickCount:1
                                      pressure:0.0];

  if (!event)
    return NS_ERROR_FAILURE;

// We don't have NSTrackingArea in 10.4.
#if(0)
  if ([[mView window] isKindOfClass:[BaseWindow class]]) {
    // Tracking area events don't end up in their tracking areas when sent
    // through [NSApp sendEvent:], so pass them directly to the right methods.
    BaseWindow* window = (BaseWindow*)[mView window];
    if (aNativeMessage == NSMouseEntered) {
      [window mouseEntered:event];
      return NS_OK;
    }
    if (aNativeMessage == NSMouseExited) {
      [window mouseExited:event];
      return NS_OK;
    }
    if (aNativeMessage == NSMouseMoved) {
      [window mouseMoved:event];
      return NS_OK;
    }
  }
#endif

  [NSApp sendEvent:event];
  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

nsresult nsChildView::SynthesizeNativeMouseScrollEvent(mozilla::LayoutDeviceIntPoint aPoint,
                                                       uint32_t aNativeMessage,
                                                       double aDeltaX,
                                                       double aDeltaY,
                                                       double aDeltaZ,
                                                       uint32_t aModifierFlags,
                                                       uint32_t aAdditionalFlags,
                                                       nsIObserver* aObserver)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  AutoObserverNotifier notifier(aObserver, "mousescrollevent");

  NSPoint pt =
    nsCocoaUtils::DevPixelsToCocoaPoints(aPoint);

  // Move the mouse cursor to the requested position and reconnect it to the mouse.
#if(0)
  CGWarpMouseCursorPosition(NSPointToCGPoint(pt));
  CGAssociateMouseAndMouseCursorPosition(true);

  // Mostly copied from http://stackoverflow.com/a/6130349
  CGScrollEventUnit units =
    (aAdditionalFlags & nsIDOMWindowUtils::MOUSESCROLL_SCROLL_LINES)
    ? kCGScrollEventUnitLine : kCGScrollEventUnitPixel;
  CGEventRef cgEvent = CGEventCreateScrollWheelEvent(NULL, units, 3, aDeltaY, aDeltaX, aDeltaZ);
  if (!cgEvent) {
    return NS_ERROR_FAILURE;
  }

  CGEventPost(kCGHIDEventTap, cgEvent);
  CFRelease(cgEvent);
#else
  CGWarpMouseCursorPosition(CGPointMake(aPoint.x, aPoint.y));
  CGAssociateMouseAndMouseCursorPosition(true);

  // Use the deprecated 10.4 CGPostScrollWheelEvent.
  // Note that this can't cope with pixel scrolling, but we shouldn't
  // generate such events with the 10.4 SDK either.
  if (aAdditionalFlags & nsIDOMWindowUtils::MOUSESCROLL_SCROLL_LINES) {
    // We don't support deltaZ, so report only two axes. (It might work?)
    NS_ASSERTION((aDeltaZ == 0.0), "Generated a Z-delta scroll event");
    if (CGPostScrollWheelEvent(2, aDeltaY, aDeltaX) != kCGErrorSuccess)
      return NS_ERROR_FAILURE;
  } else {
    NS_WARNING("Received/ignored a pixel scrolling event to SynthesizeNativeMouseScrollEvent");
  }
#endif
  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

// First argument has to be an NSMenu representing the application's top-level
// menu bar. The returned item is *not* retained.
static NSMenuItem* NativeMenuItemWithLocation(NSMenu* menubar, NSString* locationString)
{
  NSArray* indexes = [locationString componentsSeparatedByString:@"|"];
  unsigned int indexCount = [indexes count];
  if (indexCount == 0)
    return nil;

  NSMenu* currentSubmenu = [NSApp mainMenu];
  for (unsigned int i = 0; i < indexCount; i++) {
    int targetIndex;
    // We remove the application menu from consideration for the top-level menu
    if (i == 0)
      targetIndex = [[indexes objectAtIndex:i] intValue] + 1;
    else
      targetIndex = [[indexes objectAtIndex:i] intValue];
    int itemCount = [currentSubmenu numberOfItems];
    if (targetIndex < itemCount) {
      NSMenuItem* menuItem = [currentSubmenu itemAtIndex:targetIndex];
      // if this is the last index just return the menu item
      if (i == (indexCount - 1))
        return menuItem;
      // if this is not the last index find the submenu and keep going
      if ([menuItem hasSubmenu])
        currentSubmenu = [menuItem submenu];
      else
        return nil;
    }
  }

  return nil;
}

// Used for testing native menu system structure and event handling.
NS_IMETHODIMP nsChildView::ActivateNativeMenuItemAt(const nsAString& indexString)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  NSString* locationString = [NSString stringWithCharacters:reinterpret_cast<const unichar*>(indexString.BeginReading())
                                                     length:indexString.Length()];
  NSMenuItem* item = NativeMenuItemWithLocation([NSApp mainMenu], locationString);
  // We can't perform an action on an item with a submenu, that will raise
  // an obj-c exception.
  if (item && ![item hasSubmenu]) {
    NSMenu* parent = [item menu];
    if (parent) {
      // NSLog(@"Performing action for native menu item titled: %@\n",
      //       [[currentSubmenu itemAtIndex:targetIndex] title]);
      [parent performActionForItemAtIndex:[parent indexOfItem:item]];
      return NS_OK;
    }
  }
  return NS_ERROR_FAILURE;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

// Used for testing native menu system structure and event handling.
NS_IMETHODIMP nsChildView::ForceUpdateNativeMenuAt(const nsAString& indexString)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  nsCocoaWindow *widget = GetXULWindowWidget();
  if (widget) {
    nsMenuBarX* mb = widget->GetMenuBar();
    if (mb) {
      if (indexString.IsEmpty())
        mb->ForceNativeMenuReload();
      else
        mb->ForceUpdateNativeMenuAt(indexString);
    }
  }
  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

#pragma mark -

#ifdef INVALIDATE_DEBUGGING

static Boolean KeyDown(const UInt8 theKey)
{
  KeyMap map;
  GetKeys(map);
  return ((*((UInt8 *)map + (theKey >> 3)) >> (theKey & 7)) & 1) != 0;
}

static Boolean caps_lock()
{
  return KeyDown(0x39);
}

static void blinkRect(Rect* r)
{
  StRegionFromPool oldClip;
  if (oldClip != NULL)
    ::GetClip(oldClip);

  ::ClipRect(r);
  ::InvertRect(r);
  UInt32 end = ::TickCount() + 5;
  while (::TickCount() < end) ;
  ::InvertRect(r);

  if (oldClip != NULL)
    ::SetClip(oldClip);
}

static void blinkRgn(RgnHandle rgn)
{
  StRegionFromPool oldClip;
  if (oldClip != NULL)
    ::GetClip(oldClip);

  ::SetClip(rgn);
  ::InvertRgn(rgn);
  UInt32 end = ::TickCount() + 5;
  while (::TickCount() < end) ;
  ::InvertRgn(rgn);

  if (oldClip != NULL)
    ::SetClip(oldClip);
}

#endif

// Invalidate this component's visible area
NS_IMETHODIMP nsChildView::Invalidate(const LayoutDeviceIntRect& aRect)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  if (!mView || !mVisible)
    return NS_OK;

  NS_ASSERTION(GetLayerManager()->GetBackendType() != LayersBackend::LAYERS_CLIENT,
               "Shouldn't need to invalidate with accelerated OMTC layers!");

  if ([NSView focusView]) {
    // if a view is focussed (i.e. being drawn), then postpone the invalidate so that we
    // don't lose it.
    [mView setNeedsPendingDisplayInRect:DevPixelsToCocoaPoints(aRect)];
  }
  else {
    [mView setNeedsDisplayInRect:DevPixelsToCocoaPoints(aRect)];
  }

  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

bool
nsChildView::ComputeShouldAccelerate()
{
  // Don't use OpenGL for transparent windows or for popup windows.
  if (!mView || ![[mView window] isOpaque] ||
      [[mView window] isKindOfClass:[PopupWindow class]])
    return false;

  return nsBaseWidget::ComputeShouldAccelerate();
}

bool
nsChildView::ShouldUseOffMainThreadCompositing()
{
  // Don't use OMTC for transparent windows or for popup windows.
  if (!mView || ![[mView window] isOpaque] ||
      [[mView window] isKindOfClass:[PopupWindow class]])
    return false;

  return nsBaseWidget::ShouldUseOffMainThreadCompositing();
}

inline uint16_t COLOR8TOCOLOR16(uint8_t color8)
{
  // return (color8 == 0xFF ? 0xFFFF : (color8 << 8));
  return (color8 << 8) | color8;  /* (color8 * 257) == (color8 * 0x0101) */
}

#pragma mark -

nsresult nsChildView::ConfigureChildren(const nsTArray<Configuration>& aConfigurations)
{
  return NS_OK;
}

// Invokes callback and ProcessEvent methods on Event Listener object
NS_IMETHODIMP nsChildView::DispatchEvent(WidgetGUIEvent* event,
                                         nsEventStatus& aStatus)
{
#ifdef DEBUG
  debug_DumpEvent(stdout, event->widget, event, nsAutoCString("something"), 0);
#endif

#if(0)
  NS_ASSERTION(!(mTextInputHandler && mTextInputHandler->IsIMEComposing() &&
                 event->HasKeyEventMessage()),
    "Any key events should not be fired during IME composing");

  if (event->mFlags.mIsSynthesizedForTests) {
    WidgetKeyboardEvent* keyEvent = event->AsKeyboardEvent();
    if (keyEvent) {
      nsresult rv = mTextInputHandler->AttachNativeKeyEvent(*keyEvent);
      NS_ENSURE_SUCCESS(rv, rv);
    }
  }
#else
  NS_ASSERTION(!(nsTSMManager::IsComposing() && event->HasKeyEventMessage()),
    "Any key events should not be fired during IME composing");

  if (event->mFlags.mIsSynthesizedForTests && event->HasKeyEventMessage()) {
    NS_WARNING("XXX Need TextInputHandlerBase::AttachNativeKeyEvent\n");
    return NS_ERROR_FAILURE;
  }
#endif

  aStatus = nsEventStatus_eIgnore;

  nsIWidgetListener* listener = mWidgetListener;

  // If the listener is NULL, check if the parent is a popup. If it is, then
  // this child is the popup content view attached to a popup. Get the
  // listener from the parent popup instead.
  nsCOMPtr<nsIWidget> kungFuDeathGrip = do_QueryInterface(mParentWidget ? mParentWidget : this);
  if (!listener && mParentWidget) {
    if (mParentWidget->WindowType() == eWindowType_popup) {
      // Check just in case event->widget isn't this widget
      if (event->widget)
        listener = event->widget->GetWidgetListener();
      if (!listener) {
        event->widget = mParentWidget;
        listener = mParentWidget->GetWidgetListener();
      }
    }
  }

  if (listener)
    aStatus = listener->HandleEvent(event, mUseAttachedEvents);

  return NS_OK;
}

bool nsChildView::DispatchWindowEvent(WidgetGUIEvent& event)
{
  nsEventStatus status;
  DispatchEvent(&event, status);
  return ConvertStatus(status);
}

nsIWidget*
nsChildView::GetWidgetForListenerEvents()
{
  // If there is no listener, use the parent popup's listener if that exists.
  if (!mWidgetListener && mParentWidget &&
      mParentWidget->WindowType() == eWindowType_popup) {
    return mParentWidget;
  }

  return this;
}

void nsChildView::WillPaintWindow()
{
  nsCOMPtr<nsIWidget> widget = GetWidgetForListenerEvents();

  nsIWidgetListener* listener = widget->GetWidgetListener();
  if (listener) {
    listener->WillPaintWindow(widget);
  }
}

bool nsChildView::PaintWindow(LayoutDeviceIntRegion aRegion)
{
  nsCOMPtr<nsIWidget> widget = GetWidgetForListenerEvents();

  nsIWidgetListener* listener = widget->GetWidgetListener();
  if (!listener)
    return false;

  bool returnValue = false;
  bool oldDispatchPaint = mIsDispatchPaint;
  mIsDispatchPaint = true;
  returnValue = listener->PaintWindow(widget, aRegion);

  listener = widget->GetWidgetListener();
  if (listener) {
    listener->DidPaintWindow();
  }

  mIsDispatchPaint = oldDispatchPaint;
  return returnValue;
}

#pragma mark -

void nsChildView::ReportMoveEvent()
{
   NotifyWindowMoved(mBounds.x, mBounds.y);
}

void nsChildView::ReportSizeEvent()
{
  if (mWidgetListener)
    mWidgetListener->WindowResized(this, mBounds.width, mBounds.height);
}

#pragma mark -

LayoutDeviceIntPoint nsChildView::GetClientOffset()
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  NSPoint origin = [mView convertPoint:NSMakePoint(0, 0) toView:nil];
  origin.y = [[mView window] frame].size.height - origin.y;
  return CocoaPointsToDevPixels(origin);

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(LayoutDeviceIntPoint(0, 0));
}

//    Return the offset between this child view and the screen.
//    @return       -- widget origin in device-pixel coords
LayoutDeviceIntPoint nsChildView::WidgetToScreenOffset()
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  NSPoint origin = NSMakePoint(0, 0);

  // 1. First translate view origin point into window coords.
  // The returned point is in bottom-left coordinates.
  origin = [mView convertPoint:origin toView:nil];

  // 2. We turn the window-coord rect's origin into screen (still bottom-left) coords.
  origin = [[mView window] convertBaseToScreen:origin];

  // 3. Since we're dealing in bottom-left coords, we need to make it top-left coords
  //    before we pass it back to Gecko.
  FlipCocoaScreenCoordinate(origin);

  // convert to device pixels
  return CocoaPointsToDevPixels(origin);

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(LayoutDeviceIntPoint(0,0));
}

NS_IMETHODIMP nsChildView::CaptureRollupEvents(nsIRollupListener * aListener,
                                               bool aDoCapture)
{
  // this never gets called, only top-level windows can be rollup widgets
  return NS_OK;
}

NS_IMETHODIMP nsChildView::SetTitle(const nsAString& title)
{
  // child views don't have titles
  return NS_OK;
}

NS_IMETHODIMP nsChildView::GetAttention(int32_t aCycleCount)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  [NSApp requestUserAttention:NSInformationalRequest];
  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
}

/* static */
bool nsChildView::DoHasPendingInputEvent()
{
  return sLastInputEventCount != GetCurrentInputEventCount();
}

/* static */
uint32_t nsChildView::GetCurrentInputEventCount()
{
  // Can't use kCGAnyInputEventType because that updates too rarely for us (and
  // always in increments of 30+!) and because apparently it's sort of broken
  // on Tiger.  So just go ahead and query the counters we care about.
  static const CGEventType eventTypes[] = {
    kCGEventLeftMouseDown,
    kCGEventLeftMouseUp,
    kCGEventRightMouseDown,
    kCGEventRightMouseUp,
    kCGEventMouseMoved,
    kCGEventLeftMouseDragged,
    kCGEventRightMouseDragged,
    kCGEventKeyDown,
    kCGEventKeyUp,
    kCGEventScrollWheel,
    kCGEventTabletPointer,
    kCGEventOtherMouseDown,
    kCGEventOtherMouseUp,
    kCGEventOtherMouseDragged
  };

  uint32_t eventCount = 0;
  for (uint32_t i = 0; i < ArrayLength(eventTypes); ++i) {
    eventCount +=
      CGEventSourceCounterForEventType(kCGEventSourceStateCombinedSessionState,
                                       eventTypes[i]);
  }
  return eventCount;
}

/* static */
void nsChildView::UpdateCurrentInputEventCount()
{
  sLastInputEventCount = GetCurrentInputEventCount();
}

bool nsChildView::HasPendingInputEvent()
{
  return DoHasPendingInputEvent();
}

#pragma mark -

// Added for bug 807893
static int32_t sSecureEventInputCount = 0;

static void ChildViewEnableSecureEventInput()
{
  sSecureEventInputCount++;
  ::EnableSecureEventInput();
}

static void ChildViewDisableSecureEventInput()
{
  if (!sSecureEventInputCount) return;
  sSecureEventInputCount--;
  ::DisableSecureEventInput();
}

static bool ChildViewIsSecureEventInputEnabled()
{
  return !!sSecureEventInputCount;
}

static void ChildViewEnsureSecureEventInputDisabled()
{
  while (sSecureEventInputCount)
    ChildViewDisableSecureEventInput();
}

nsresult
nsChildView::NotifyIMEInternal(const IMENotification& aIMENotification)
{
#if(0)
  switch (aIMENotification.mMessage) {
    case REQUEST_TO_COMMIT_COMPOSITION:
      NS_ENSURE_TRUE(mTextInputHandler, NS_ERROR_NOT_AVAILABLE);
      mTextInputHandler->CommitIMEComposition();
      return NS_OK;
    case REQUEST_TO_CANCEL_COMPOSITION:
      NS_ENSURE_TRUE(mTextInputHandler, NS_ERROR_NOT_AVAILABLE);
      mTextInputHandler->CancelIMEComposition();
      return NS_OK;
    case NOTIFY_IME_OF_FOCUS:
      if (mTextInputHandler->IsFocused()) {
        if (mInputContext.IsPasswordEditor()) {
          TextInputHandler::EnableSecureEventInput();
        } else {
          TextInputHandler::EnsureSecureEventInputDisabled();
        }
      }

      NS_ENSURE_TRUE(mTextInputHandler, NS_ERROR_NOT_AVAILABLE);
      mTextInputHandler->OnFocusChangeInGecko(true);
      return NS_OK;
    case NOTIFY_IME_OF_BLUR:
      NS_ENSURE_TRUE(mTextInputHandler, NS_ERROR_NOT_AVAILABLE);
      mTextInputHandler->OnFocusChangeInGecko(false);
      return NS_OK;
    case NOTIFY_IME_OF_SELECTION_CHANGE:
      NS_ENSURE_TRUE(mTextInputHandler, NS_ERROR_NOT_AVAILABLE);
      mTextInputHandler->OnSelectionChange(aIMENotification);
      return NS_OK;
    default:
      return NS_ERROR_NOT_IMPLEMENTED;
  }
#else
  switch (aIMENotification.mMessage) {
    case REQUEST_TO_COMMIT_COMPOSITION:
      nsTSMManager::CommitIME();
      return NS_OK;
    case REQUEST_TO_CANCEL_COMPOSITION:
      nsTSMManager::CancelIME();
      return NS_OK;
    case NOTIFY_IME_OF_FOCUS:
      if (mInputContext.IsPasswordEditor())
        ChildViewEnableSecureEventInput();
      else
      	ChildViewEnsureSecureEventInputDisabled();
      // XXX mTextInputHandler->OnFocusChangeInGecko(true);
      return NS_OK;
    case NOTIFY_IME_OF_BLUR:
      // When we're going to be deactivated, we must disable the secure
      // event input mode; see the Carbon Event Manager Reference.
      ChildViewEnsureSecureEventInputDisabled();
      // XXX mTextInputHandler->OnFocusChangeInGecko(false);
      return NS_OK;
    case NOTIFY_IME_OF_SELECTION_CHANGE:
      // XXX mTextInputHandler->OnSelectionChange(aIMENotification);
      return NS_OK;
    default:
      return NS_ERROR_NOT_IMPLEMENTED;
  }
#endif
}

NS_IMETHODIMP
nsChildView::StartPluginIME(const mozilla::WidgetKeyboardEvent& aKeyboardEvent,
                            int32_t aPanelX, int32_t aPanelY,
                            nsString& aCommitted)
{
  NS_ENSURE_TRUE(mView, NS_ERROR_NOT_AVAILABLE);

  ComplexTextInputPanel* ctiPanel =
    ComplexTextInputPanel::GetSharedComplexTextInputPanel();

  ctiPanel->PlacePanel(aPanelX, aPanelY);
  // We deliberately don't use TextInputHandler::GetCurrentKeyEvent() to
  // obtain the NSEvent* we pass to InterpretKeyEvent().  This works fine in
  // non-e10s mode.  But in e10s mode TextInputHandler::HandleKeyDownEvent()
  // has already returned, so the relevant KeyEventState* (and its NSEvent*)
  // is already out of scope.  Furthermore we don't *need* to use it.
  // StartPluginIME() is only ever called to start a new IME session when none
  // currently exists.  So nested IME should never reach here, and so it should
  // be fine to use the last key-down event received by -[ChildView keyDown:]
  // (as we currently do).
  ctiPanel->InterpretKeyEvent([(ChildView*)mView lastKeyDownEvent], aCommitted);

  return NS_OK;
}

NS_IMETHODIMP
nsChildView::SetPluginFocused(bool& aFocused)
{
  if (aFocused == mPluginFocused) {
    return NS_OK;
  }
  if (!aFocused) {
    ComplexTextInputPanel* ctiPanel =
      ComplexTextInputPanel::GetSharedComplexTextInputPanel();
    if (ctiPanel) {
      ctiPanel->CancelComposition();
    }
  }
  mPluginFocused = aFocused;
  return NS_OK;
}

NS_IMETHODIMP_(void)
nsChildView::SetInputContext(const InputContext& aContext,
                             const InputContextAction& aAction)
{
#ifdef DEBUG_IME
  //NSLog(@"**** SetInputMode mStatus = %d", aContext.mStatus);
#endif

#if(0)
  NS_ENSURE_TRUE_VOID(mTextInputHandler);

  if (mTextInputHandler->IsFocused()) {
    if (aContext.IsPasswordEditor()) {
      TextInputHandler::EnableSecureEventInput();
    } else {
      TextInputHandler::EnsureSecureEventInputDisabled();
    }
  }

  mInputContext = aContext;
  switch (aContext.mIMEState.mEnabled) {
    case IMEState::ENABLED:
    case IMEState::PLUGIN:
      mTextInputHandler->SetASCIICapableOnly(false);
      mTextInputHandler->EnableIME(true);
      if (mInputContext.mIMEState.mOpen != IMEState::DONT_CHANGE_OPEN_STATE) {
        mTextInputHandler->SetIMEOpenState(
          mInputContext.mIMEState.mOpen == IMEState::OPEN);
      }
      break;
    case IMEState::DISABLED:
      mTextInputHandler->SetASCIICapableOnly(false);
      mTextInputHandler->EnableIME(false);
      break;
    case IMEState::PASSWORD:
      mTextInputHandler->SetASCIICapableOnly(true);
      mTextInputHandler->EnableIME(false);
      break;
    default:
      NS_ERROR("not implemented!");
  }
#else
  // Bug 807893 requires that we juggle the secure status ourselves.
  // Bug 893973 needs focus checking, but our 10.4-compatible code does not.
  if (aContext.IsPasswordEditor())
	ChildViewEnableSecureEventInput();
  else
	ChildViewDisableSecureEventInput();

  mInputContext = aContext;
  switch (aContext.mIMEState.mEnabled) {
    case IMEState::ENABLED:
    case IMEState::PLUGIN:
        if (mInputContext.mIMEState.mOpen != IMEState::DONT_CHANGE_OPEN_STATE) {
                nsTSMManager::SetIMEOpenState(
                        mInputContext.mIMEState.mOpen == IMEState::OPEN);
        }
        break;
    case IMEState::DISABLED:
    case IMEState::PASSWORD:
        // handled by nsTSMManager::SetIMEEnabled
        break;
    default:
        NS_ERROR("not implemented!");
        return;
  }
  (void)nsTSMManager::SetIMEEnabled(aContext.mIMEState.mEnabled);
#endif
}

NS_IMETHODIMP_(InputContext)
nsChildView::GetInputContext()
{
#if(0)
  switch (mInputContext.mIMEState.mEnabled) {
    case IMEState::ENABLED:
    case IMEState::PLUGIN:
      if (mTextInputHandler) {
        mInputContext.mIMEState.mOpen =
          mTextInputHandler->IsIMEOpened() ? IMEState::OPEN : IMEState::CLOSED;
        break;
      }
      // If mTextInputHandler is null, set CLOSED instead...
      MOZ_FALLTHROUGH;
    default:
      mInputContext.mIMEState.mOpen = IMEState::CLOSED;
      break;
  }
#else
  switch (mInputContext.mIMEState.mEnabled) {
    case IMEState::ENABLED:
    case IMEState::PLUGIN:
      // The nsTSMManager is always available in 10.4.
      mInputContext.mIMEState.mOpen =
        nsTSMManager::GetIMEOpenState() ? IMEState::OPEN : IMEState::CLOSED;
      break;
    default:
      mInputContext.mIMEState.mOpen = IMEState::CLOSED;
      break;
  }
#endif
  return mInputContext;
}

NS_IMETHODIMP
nsChildView::AttachNativeKeyEvent(mozilla::WidgetKeyboardEvent& aEvent)
{
#if(0)
  NS_ENSURE_TRUE(mTextInputHandler, NS_ERROR_NOT_AVAILABLE);
  return mTextInputHandler->AttachNativeKeyEvent(aEvent);
#else
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NSRESULT;

  // Don't try to replace a native event if one already exists.
  // OS X doesn't have an OS modifier, so we can't make a native event.
  if (aEvent.mNativeKeyEvent || aEvent.modifiers & MODIFIER_OS) {
    return NS_OK;
  }

#if(0)
  PR_LOG(sCocoaLog, PR_LOG_ALWAYS,
    ("%p nsChildView::AttachNativeKeyEvent, key=0x%X, char=0x%X, "
     "mod=0x%X", this, aEvent.keyCode, aEvent.charCode,
     aEvent.modifiers));
#endif

  NSEventType eventType;
  if (aEvent.mMessage == eKeyUp) {
    eventType = NSKeyUp;
  } else {
    eventType = NSKeyDown;
  }

  static const uint32_t sModifierFlagMap[][2] = {
    { MODIFIER_SHIFT,    NSShiftKeyMask },
    { MODIFIER_CONTROL,  NSControlKeyMask },
    { MODIFIER_ALT,      NSAlternateKeyMask },
    { MODIFIER_ALTGRAPH, NSAlternateKeyMask },
    { MODIFIER_META,     NSCommandKeyMask },
    { MODIFIER_CAPSLOCK, NSAlphaShiftKeyMask },
    { MODIFIER_NUMLOCK,  NSNumericPadKeyMask }
  };

  uint32_t modifierFlags = 0;
  for (uint32_t i = 0; i < ArrayLength(sModifierFlagMap); ++i) {
    if (aEvent.modifiers & sModifierFlagMap[i][0]) {
      modifierFlags |= sModifierFlagMap[i][1];
    }
  }
  // We probably don't need nsCocoaUtils to adjust the modifier flags. ???

  int32_t windowNumber = [[mView window] windowNumber];

  NSString* characters;
  if (aEvent.charCode) {
    characters = [NSString stringWithCharacters:
      reinterpret_cast<const unichar*>(&(aEvent.charCode)) length:1];
  } else {
    uint32_t cocoaCharCode =
      nsCocoaUtils::ConvertGeckoKeyCodeToMacCharCode(aEvent.keyCode);
    characters = [NSString stringWithCharacters:
      reinterpret_cast<const unichar*>(&cocoaCharCode) length:1];
  }

  aEvent.mNativeKeyEvent =
    [NSEvent     keyEventWithType:eventType
                         location:NSMakePoint(0,0)
                    modifierFlags:modifierFlags
                        timestamp:0
                     windowNumber:windowNumber
                          context:[NSGraphicsContext currentContext]
                       characters:characters
      charactersIgnoringModifiers:characters
                        isARepeat:NO
                          keyCode:0]; // Native key code not currently needed

  return NS_OK;

  NS_OBJC_END_TRY_ABORT_BLOCK_NSRESULT;
#endif
}

bool
nsChildView::ExecuteNativeKeyBindingRemapped(NativeKeyBindingsType aType,
                                             const WidgetKeyboardEvent& aEvent,
                                             DoCommandCallback aCallback,
                                             void* aCallbackData,
                                             uint32_t aGeckoKeyCode,
                                             uint32_t aCocoaKeyCode)
{
  NSEvent *originalEvent = reinterpret_cast<NSEvent*>(aEvent.mNativeKeyEvent);

  WidgetKeyboardEvent modifiedEvent(aEvent);
  modifiedEvent.keyCode = aGeckoKeyCode;

  unichar ch = nsCocoaUtils::ConvertGeckoKeyCodeToMacCharCode(aGeckoKeyCode);
  NSString *chars =
    [[[NSString alloc] initWithCharacters:&ch length:1] autorelease];

  modifiedEvent.mNativeKeyEvent =
    [NSEvent keyEventWithType:[originalEvent type]
                     location:[originalEvent locationInWindow]
                modifierFlags:[originalEvent modifierFlags]
                    timestamp:[originalEvent timestamp]
                 windowNumber:[originalEvent windowNumber]
                      context:[originalEvent context]
                   characters:chars
  charactersIgnoringModifiers:chars
                    isARepeat:[originalEvent isARepeat]
                      keyCode:aCocoaKeyCode];

  NativeKeyBindings* keyBindings = NativeKeyBindings::GetInstance(aType);
  return keyBindings->Execute(modifiedEvent, aCallback, aCallbackData);
}

NS_IMETHODIMP_(bool)
nsChildView::ExecuteNativeKeyBinding(NativeKeyBindingsType aType,
                                     const WidgetKeyboardEvent& aEvent,
                                     DoCommandCallback aCallback,
                                     void* aCallbackData)
{
  // If the key is a cursor-movement arrow, and the current selection has
  // vertical writing-mode, we'll remap so that the movement command
  // generated (in terms of characters/lines) will be appropriate for
  // the physical direction of the arrow.
  if (aEvent.keyCode >= nsIDOMKeyEvent::DOM_VK_LEFT &&
      aEvent.keyCode <= nsIDOMKeyEvent::DOM_VK_DOWN) {
    WidgetQueryContentEvent query(true, eQuerySelectedText, this);
    DispatchWindowEvent(query);

    if (query.mSucceeded && query.mReply.mWritingMode.IsVertical()) {
      uint32_t geckoKey = 0;
      uint32_t cocoaKey = 0;

      switch (aEvent.keyCode) {
      case nsIDOMKeyEvent::DOM_VK_LEFT:
        if (query.mReply.mWritingMode.IsVerticalLR()) {
          geckoKey = nsIDOMKeyEvent::DOM_VK_UP;
          cocoaKey = kVK_UpArrow;
        } else {
          geckoKey = nsIDOMKeyEvent::DOM_VK_DOWN;
          cocoaKey = kVK_DownArrow;
        }
        break;

      case nsIDOMKeyEvent::DOM_VK_RIGHT:
        if (query.mReply.mWritingMode.IsVerticalLR()) {
          geckoKey = nsIDOMKeyEvent::DOM_VK_DOWN;
          cocoaKey = kVK_DownArrow;
        } else {
          geckoKey = nsIDOMKeyEvent::DOM_VK_UP;
          cocoaKey = kVK_UpArrow;
        }
        break;

      case nsIDOMKeyEvent::DOM_VK_UP:
        geckoKey = nsIDOMKeyEvent::DOM_VK_LEFT;
        cocoaKey = kVK_LeftArrow;
        break;

      case nsIDOMKeyEvent::DOM_VK_DOWN:
        geckoKey = nsIDOMKeyEvent::DOM_VK_RIGHT;
        cocoaKey = kVK_RightArrow;
        break;
      }

      return ExecuteNativeKeyBindingRemapped(aType, aEvent, aCallback,
                                             aCallbackData,
                                             geckoKey, cocoaKey);
    }
  }

  NativeKeyBindings* keyBindings = NativeKeyBindings::GetInstance(aType);
  return keyBindings->Execute(aEvent, aCallback, aCallbackData);
}

nsIMEUpdatePreference
nsChildView::GetIMEUpdatePreference()
{
  // While a plugin has focus, IMEInputHandler doesn't need any notifications.
  if (mInputContext.mIMEState.mEnabled == IMEState::PLUGIN) {
    return nsIMEUpdatePreference();
  }
  return nsIMEUpdatePreference(nsIMEUpdatePreference::NOTIFY_SELECTION_CHANGE);
}

#if(0)
NSView<mozView>* nsChildView::GetEditorView()
{
  NSView<mozView>* editorView = mView;
  // We need to get editor's view. E.g., when the focus is in the bookmark
  // dialog, the view is <panel> element of the dialog.  At this time, the key
  // events are processed the parent window's view that has native focus.
  WidgetQueryContentEvent textContent(true, eQueryTextContent, this);
  textContent.InitForQueryTextContent(0, 0);
  DispatchWindowEvent(textContent);
  if (textContent.mSucceeded && textContent.mReply.mFocusedWidget) {
    NSView<mozView>* view = static_cast<NSView<mozView>*>(
      textContent.mReply.mFocusedWidget->GetNativeData(NS_NATIVE_WIDGET));
    if (view)
      editorView = view;
  }
  return editorView;
}
#endif // no Tiger equivalent.

#pragma mark -

void
nsChildView::CreateCompositor()
{
  nsBaseWidget::CreateCompositor();
  if (mCompositorChild) {
    [(ChildView *)mView setUsingOMTCompositor:true];
  }
}

void
nsChildView::ConfigureAPZCTreeManager()
{
  nsBaseWidget::ConfigureAPZCTreeManager();

  if (gfxPrefs::AsyncPanZoomSeparateEventThread()) {
    if (gNumberOfWidgetsNeedingEventThread == 0) {
      [EventThreadRunner start];
    }
    gNumberOfWidgetsNeedingEventThread++;
  }
}

void
nsChildView::ConfigureAPZControllerThread()
{
  if (gfxPrefs::AsyncPanZoomSeparateEventThread()) {
    // The EventThreadRunner is the controller thread, but it doesn't
    // have a MessageLoop.
    APZThreadUtils::SetControllerThread(nullptr);
  } else {
    nsBaseWidget::ConfigureAPZControllerThread();
  }
}

LayoutDeviceIntRect
nsChildView::RectContainingTitlebarControls()
{
#if(0)
  // Start with a thin strip at the top of the window for the highlight line.
  NSRect rect = NSMakeRect(0, 0, [mView bounds].size.width,
                           [(ChildView*)mView cornerRadius]);

  // Add the rects of the titlebar controls.
  for (id view in [(BaseWindow*)[mView window] titlebarControls]) {
    rect = NSUnionRect(rect, [mView convertRect:[view bounds] fromView:view]);
  }
  return CocoaPointsToDevPixels(rect);
#else
  // Actually, stuff all that. We've gotta get on with these.
  // Gotta compete with a whiny Mozilla that broke 10.4 compatibilit-ee.
  // Use the manual gradient patch in 880620 for perf and no NSGradient.
  NSRect rect = NSMakeRect(0, 0, [mView bounds].size.width,
                           [(ChildView*)mView cornerRadius]);

  // Now we can add the rects of the titlebar controls. Oi! Where's the bar!
  // XXX: NSEnumerator *e = [a objectEnumerator]; while(id = [e nextObject])
  int i;
  NSArray *a = [(BaseWindow*)[mView window] titlebarControls];
  for (i=0; i < [a count]; i++) {
    id view = [a objectAtIndex:i];
    rect = NSUnionRect(rect, [mView convertRect:[view bounds] fromView:view]);
  }
  return CocoaPointsToDevPixels(rect);
#endif
}

void
nsChildView::PrepareWindowEffects()
{
  MutexAutoLock lock(mEffectsLock);
  mShowsResizeIndicator = ShowsResizeIndicator(&mResizeIndicatorRect);
  mHasRoundedBottomCorners = [(ChildView*)mView hasRoundedBottomCorners];
  CGFloat cornerRadius = [(ChildView*)mView cornerRadius];
  mDevPixelCornerRadius = cornerRadius; // * BackingScaleFactor();
  mIsCoveringTitlebar = [(ChildView*)mView isCoveringTitlebar];
  NSInteger styleMask = [[mView window] styleMask];
  mIsFullscreen = (styleMask & NSFullScreenWindowMask) || !(styleMask & NSTitledWindowMask);
  if (mIsCoveringTitlebar) {
    mTitlebarRect = RectContainingTitlebarControls();
    UpdateTitlebarCGContext();
  }
}

void
nsChildView::CleanupWindowEffects()
{
  mResizerImage = nullptr;
  mCornerMaskImage = nullptr;
  mTitlebarImage = nullptr;
}

bool
nsChildView::PreRender(LayerManagerComposite* aManager)
{
  nsAutoPtr<GLManager> manager(GLManager::CreateGLManager(aManager));
  if (!manager) {
    return true;
  }

  // The lock makes sure that we don't attempt to tear down the view while
  // compositing. That would make us unable to call postRender on it when the
  // composition is done, thus keeping the GL context locked forever.
  mViewTearDownLock.Lock();

  NSOpenGLContext *glContext = GLContextCGL::Cast(manager->gl())->GetNSOpenGLContext();

  if (![(ChildView*)mView preRender:glContext]) {
    mViewTearDownLock.Unlock();
    return false;
  }
  return true;
}

void
nsChildView::PostRender(LayerManagerComposite* aManager)
{
  nsAutoPtr<GLManager> manager(GLManager::CreateGLManager(aManager));
  if (!manager) {
    return;
  }
  NSOpenGLContext *glContext = GLContextCGL::Cast(manager->gl())->GetNSOpenGLContext();
  [(ChildView*)mView postRender:glContext];
  mViewTearDownLock.Unlock();
}

void
nsChildView::DrawWindowOverlay(LayerManagerComposite* aManager,
                               LayoutDeviceIntRect aRect)
{
  nsAutoPtr<GLManager> manager(GLManager::CreateGLManager(aManager));
  if (manager) {
    DrawWindowOverlay(manager, aRect);
  }
}

void
nsChildView::DrawWindowOverlay(GLManager* aManager, LayoutDeviceIntRect aRect)
{
  GLContext* gl = aManager->gl();
  ScopedGLState scopedScissorTestState(gl, LOCAL_GL_SCISSOR_TEST, false);

  MaybeDrawTitlebar(aManager);
  MaybeDrawResizeIndicator(aManager);
  MaybeDrawRoundedCorners(aManager, aRect);
}

static void
ClearRegion(gfx::DrawTarget *aDT, LayoutDeviceIntRegion aRegion)
{
  gfxUtils::ClipToRegion(aDT, aRegion.ToUnknownRegion());
  aDT->ClearRect(gfx::Rect(0, 0, aDT->GetSize().width, aDT->GetSize().height));
  aDT->PopClip();
}

static void
DrawResizer(CGContextRef aCtx)
{
  CGContextSetShouldAntialias(aCtx, false);
  CGPoint points[6];
  points[0] = CGPointMake(13.0f, 4.0f);
  points[1] = CGPointMake(3.0f, 14.0f);
  points[2] = CGPointMake(13.0f, 8.0f);
  points[3] = CGPointMake(7.0f, 14.0f);
  points[4] = CGPointMake(13.0f, 12.0f);
  points[5] = CGPointMake(11.0f, 14.0f);
  CGContextSetRGBStrokeColor(aCtx, 0.00f, 0.00f, 0.00f, 0.15f);
  CGContextStrokeLineSegments(aCtx, points, 6);

  points[0] = CGPointMake(13.0f, 5.0f);
  points[1] = CGPointMake(4.0f, 14.0f);
  points[2] = CGPointMake(13.0f, 9.0f);
  points[3] = CGPointMake(8.0f, 14.0f);
  points[4] = CGPointMake(13.0f, 13.0f);
  points[5] = CGPointMake(12.0f, 14.0f);
  CGContextSetRGBStrokeColor(aCtx, 0.13f, 0.13f, 0.13f, 0.54f);
  CGContextStrokeLineSegments(aCtx, points, 6);

  points[0] = CGPointMake(13.0f, 6.0f);
  points[1] = CGPointMake(5.0f, 14.0f);
  points[2] = CGPointMake(13.0f, 10.0f);
  points[3] = CGPointMake(9.0f, 14.0f);
  points[5] = CGPointMake(13.0f, 13.9f);
  points[4] = CGPointMake(13.0f, 14.0f);
  CGContextSetRGBStrokeColor(aCtx, 0.84f, 0.84f, 0.84f, 0.55f);
  CGContextStrokeLineSegments(aCtx, points, 6);
}

static void MaybeDrawResizeIndicatorCallback(gfx::DrawTarget* drawTarget,
	const LayoutDeviceIntRegion& updateRegion) {
    ClearRegion(drawTarget, updateRegion);
    gfx::BorrowedCGContext borrow(drawTarget);
    DrawResizer(borrow.cg);
    borrow.Finish();
}

void
nsChildView::MaybeDrawResizeIndicator(GLManager* aManager)
{
  MutexAutoLock lock(mEffectsLock);
  if (!mShowsResizeIndicator) {
    return;
  }

  if (!mResizerImage) {
    mResizerImage = new RectTextureImage(aManager->gl());
  }

  LayoutDeviceIntSize size = mResizeIndicatorRect.Size();
#if(0)
  mResizerImage->UpdateIfNeeded(size, LayoutDeviceIntRegion(), ^(gfx::DrawTarget* drawTarget, const LayoutDeviceIntRegion& updateRegion) {
    ClearRegion(drawTarget, updateRegion);
    gfx::BorrowedCGContext borrow(drawTarget);
    DrawResizer(borrow.cg);
    borrow.Finish();
  });
#else
  mResizerImage->UpdateIfNeeded(size, LayoutDeviceIntRegion(),
	&MaybeDrawResizeIndicatorCallback);
#endif

  mResizerImage->Draw(aManager, mResizeIndicatorRect.TopLeft());
}

// Draw the highlight line at the top of the titlebar.
// This function draws into the current NSGraphicsContext and assumes flippedness.
static void
DrawTitlebarHighlight(NSSize aWindowSize, CGFloat aRadius, CGFloat aDevicePixelWidth)
{
  [NSGraphicsContext saveGraphicsState];

  // Set up the clip path. We start with the outer rectangle and cut out a
  // slightly smaller inner rectangle with rounded corners.
  // The outer corners of the resulting path will be square, but they will be
  // masked away in a later step.
  NSBezierPath* path = [NSBezierPath bezierPath];
  [path setWindingRule:NSEvenOddWindingRule];
  NSRect pathRect = NSMakeRect(0, 0, aWindowSize.width, aRadius + 2);
  [path appendBezierPathWithRect:pathRect];
  pathRect = NSInsetRect(pathRect, aDevicePixelWidth, aDevicePixelWidth);
  CGFloat innerRadius = aRadius - aDevicePixelWidth;
#if(0)
  [path appendBezierPathWithRoundedRect:pathRect xRadius:innerRadius yRadius:innerRadius];
#else
  // Only 10.5 has this; 10.4 needs an approximation.
  // http://lists.apple.com/archives/cocoa-dev/2008/Dec/msg00263.html
  /* [path appendBezierPathWithRoundedRect:pathRect xRadius:innerRadius
	yRadius:innerRadius]; */
  float clampedRadius = MIN(innerRadius, 0.5 * MIN(pathRect.size.width,
	pathRect.size.height));
  NSPoint topLeft = NSMakePoint(NSMinX(pathRect), NSMaxY(pathRect));
  NSPoint topRight = NSMakePoint(NSMaxX(pathRect), NSMaxY(pathRect));
  NSPoint bottomRight = NSMakePoint(NSMaxX(pathRect), NSMinY(pathRect));
  [path moveToPoint:NSMakePoint(NSMidX(pathRect), NSMaxY(pathRect))];
  [path appendBezierPathWithArcFromPoint:topLeft
	toPoint:pathRect.origin radius:clampedRadius];
  [path appendBezierPathWithArcFromPoint:pathRect.origin
	toPoint:bottomRight radius:clampedRadius];
  [path appendBezierPathWithArcFromPoint:bottomRight
	toPoint:topRight radius:clampedRadius];
  [path appendBezierPathWithArcFromPoint:topRight toPoint:topLeft
	radius:clampedRadius];
#endif

  [path addClip];

  // Now we fill the path with a subtle highlight gradient.
  // We don't use NSGradient because it's 5x to 15x slower than the manual fill,
  // as indicated by the performance test in bug 880620.
  for (CGFloat y = 0; y < aRadius; y += aDevicePixelWidth) {
    CGFloat t = y / aRadius;
    [[NSColor colorWithDeviceWhite:1.0 alpha:0.4 * (1.0 - t)] set];
    NSRectFillUsingOperation(NSMakeRect(0, y, aWindowSize.width, aDevicePixelWidth), NSCompositeSourceOver);
  }

  [NSGraphicsContext restoreGraphicsState];
}

static CGContextRef
CreateCGContext(const LayoutDeviceIntSize& aSize)
{
  CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
  CGContextRef ctx =
    CGBitmapContextCreate(NULL,
                          aSize.width,
                          aSize.height,
                          8 /* bitsPerComponent */,
                          aSize.width * 4,
                          cs,
                          kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
  CGColorSpaceRelease(cs);

  CGContextTranslateCTM(ctx, 0, aSize.height);
  CGContextScaleCTM(ctx, 1, -1);
  CGContextSetInterpolationQuality(ctx, kCGInterpolationLow);

  return ctx;
}

// When this method is entered, mEffectsLock is already being held.
void
nsChildView::UpdateTitlebarCGContext()
{
  if (mTitlebarRect.IsEmpty()) {
    ReleaseTitlebarCGContext();
    return;
  }

  NSRect titlebarRect = DevPixelsToCocoaPoints(mTitlebarRect);
  NSRect dirtyRect = [mView convertRect:[(BaseWindow*)[mView window] getAndResetNativeDirtyRect] fromView:nil];
  NSRect dirtyTitlebarRect = NSIntersectionRect(titlebarRect, dirtyRect);

  LayoutDeviceIntSize texSize =
    RectTextureImage::TextureSizeForSize(mTitlebarRect.Size());
  if (!mTitlebarCGContext ||
      CGBitmapContextGetWidth(mTitlebarCGContext) != size_t(texSize.width) ||
      CGBitmapContextGetHeight(mTitlebarCGContext) != size_t(texSize.height)) {
    dirtyTitlebarRect = titlebarRect;

    ReleaseTitlebarCGContext();

    mTitlebarCGContext = CreateCGContext(texSize);
  }

  if (NSIsEmptyRect(dirtyTitlebarRect)) {
    return;
  }

  CGContextRef ctx = mTitlebarCGContext;

  CGContextSaveGState(ctx);

#if(0)
  double scale = BackingScaleFactor();
  CGContextScaleCTM(ctx, scale, scale);
#else
  CGContextScaleCTM(ctx, 1.0, 1.0);
#endif

  //CGContextClipToRect(ctx, NSRectToCGRect(dirtyTitlebarRect));
CGRect dgr = *(CGRect*)&dirtyTitlebarRect; CGContextClipToRect(ctx, dgr);
  //CGContextClearRect(ctx, NSRectToCGRect(dirtyTitlebarRect));
  CGContextClearRect(ctx, dgr);

  NSGraphicsContext* oldContext = [NSGraphicsContext currentContext];

  CGContextSaveGState(ctx);

  BaseWindow* window = (BaseWindow*)[mView window];
  NSView* frameView = [[window contentView] superview];
  if (![frameView isFlipped]) {
    CGContextTranslateCTM(ctx, 0, [frameView bounds].size.height);
    CGContextScaleCTM(ctx, 1, -1);
  }
  NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:[frameView isFlipped]];
  [NSGraphicsContext setCurrentContext:context];

  // Draw the title string.
  if ([window wantsTitleDrawn] && [frameView respondsToSelector:@selector(_drawTitleBar:)]) {
    [frameView _drawTitleBar:[frameView bounds]];
  }

  // Draw the titlebar controls into the titlebar image.
  //for (id view in [window titlebarControls]) {
  int i;
  NSArray *a = [window titlebarControls];
  for(i=0; i<[a count]; i++) {
    id view = [a objectAtIndex:i];
    NSRect viewFrame = [view frame];
    NSRect viewRect = [mView convertRect:viewFrame fromView:frameView];
    if (!NSIntersectsRect(dirtyTitlebarRect, viewRect)) {
      continue;
    }
    // All of the titlebar controls we're interested in are subclasses of
    // NSButton.
    if (![view isKindOfClass:[NSButton class]]) {
      continue;
    }
    NSButton *button = (NSButton *) view;
    id cellObject = [button cell];
    if (![cellObject isKindOfClass:[NSCell class]]) {
      continue;
    }
    NSCell *cell = (NSCell *) cellObject;

    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, viewFrame.origin.x, viewFrame.origin.y);

    if ([context isFlipped] != [view isFlipped]) {
      CGContextTranslateCTM(ctx, 0, viewFrame.size.height);
      CGContextScaleCTM(ctx, 1, -1);
    }

    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:[view isFlipped]]];

#if(0)
    if ([window useBrightTitlebarForeground] && !nsCocoaFeatures::OnYosemiteOrLater() &&
        view == [window standardWindowButton:NSWindowFullScreenButton]) {
      // Make the fullscreen button visible on dark titlebar backgrounds by
      // drawing it into a new transparency layer and turning it white.
      CGRect r = NSRectToCGRect([view bounds]);
      CGContextBeginTransparencyLayerWithRect(ctx, r, nullptr);

      // Draw twice for double opacity.
      [cell drawWithFrame:[button bounds] inView:button];
      [cell drawWithFrame:[button bounds] inView:button];

      // Make it white.
      CGContextSetBlendMode(ctx, kCGBlendModeSourceIn);
      CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
      CGContextFillRect(ctx, r);
      CGContextSetBlendMode(ctx, kCGBlendModeNormal);

      CGContextEndTransparencyLayer(ctx);
    } else {
      [cell drawWithFrame:[button bounds] inView:button];
    }
#else
    [cell drawWithFrame:[button bounds] inView:button];
#endif

    [NSGraphicsContext setCurrentContext:context];
    CGContextRestoreGState(ctx);
  }

  CGContextRestoreGState(ctx);

  DrawTitlebarHighlight([frameView bounds].size, [(ChildView*)mView cornerRadius],
                        DevPixelsToCocoaPoints(1));

  [NSGraphicsContext setCurrentContext:oldContext];

  CGContextRestoreGState(ctx);

  mUpdatedTitlebarRegion.OrWith(CocoaPointsToDevPixels(dirtyTitlebarRect));
}

// This method draws an overlay in the top of the window which contains the
// titlebar controls (e.g. close, min, zoom, fullscreen) and the titlebar
// highlight effect.
// This is necessary because the real titlebar controls are covered by our
// OpenGL context. Note that in terms of the NSView hierarchy, our ChildView
// is actually below the titlebar controls - that's why hovering and clicking
// them works as expected - but their visual representation is only drawn into
// the normal window buffer, and the window buffer surface lies below the
// GLContext surface. In order to make the titlebar controls visible, we have
// to redraw them inside the OpenGL context surface.
void
nsChildView::MaybeDrawTitlebar(GLManager* aManager)
{
  MutexAutoLock lock(mEffectsLock);
  if (!mIsCoveringTitlebar || mIsFullscreen) {
    return;
  }

  LayoutDeviceIntRegion updatedTitlebarRegion;
  updatedTitlebarRegion.And(mUpdatedTitlebarRegion, mTitlebarRect);
  mUpdatedTitlebarRegion.SetEmpty();

  if (!mTitlebarImage) {
    mTitlebarImage = new RectTextureImage(aManager->gl());
  }

  mTitlebarImage->UpdateFromCGContext(mTitlebarRect.Size(),
                                      updatedTitlebarRegion,
                                      mTitlebarCGContext);

  mTitlebarImage->Draw(aManager, mTitlebarRect.TopLeft());
}

static void
DrawTopLeftCornerMask(CGContextRef aCtx, int aRadius)
{
  CGContextSetRGBFillColor(aCtx, 1.0, 1.0, 1.0, 1.0);
  CGContextFillEllipseInRect(aCtx, CGRectMake(0, 0, aRadius * 2, aRadius * 2));
}

static void MaybeDrawRoundedCornersCallback(gfx::DrawTarget* drawTarget,
	const LayoutDeviceIntRegion& updateRegion) {
    ClearRegion(drawTarget, updateRegion);
    gfx::BorrowedCGContext borrow(drawTarget);
    /*
    DrawTopLeftCornerMask(borrow.cg, mDevPixelCornerRadius);
    */
    borrow.Finish();
}

void
nsChildView::MaybeDrawRoundedCorners(GLManager* aManager,
                                     const LayoutDeviceIntRect& aRect)
{
  MutexAutoLock lock(mEffectsLock);

  if (!mCornerMaskImage) {
    mCornerMaskImage = new RectTextureImage(aManager->gl());
  }

  LayoutDeviceIntSize size(mDevPixelCornerRadius, mDevPixelCornerRadius);
#if(0)
  mCornerMaskImage->UpdateIfNeeded(size, LayoutDeviceIntRegion(), ^(gfx::DrawTarget* drawTarget, const LayoutDeviceIntRegion& updateRegion) {
    ClearRegion(drawTarget, updateRegion);
    RefPtr<gfx::PathBuilder> builder = drawTarget->CreatePathBuilder();
    builder->Arc(gfx::Point(mDevPixelCornerRadius, mDevPixelCornerRadius), mDevPixelCornerRadius, 0, 2.0f * M_PI);
    RefPtr<gfx::Path> path = builder->Finish();
    drawTarget->Fill(path,
                     gfx::ColorPattern(gfx::Color(1.0, 1.0, 1.0, 1.0)),
                     gfx::DrawOptions(1.0f, gfx::CompositionOp::OP_SOURCE));
  });
#else
  mCornerMaskImage->UpdateIfNeeded(size, LayoutDeviceIntRegion(),
	&MaybeDrawRoundedCornersCallback);
#endif

  // Use operator destination in: multiply all 4 channels with source alpha.
  aManager->gl()->fBlendFuncSeparate(LOCAL_GL_ZERO, LOCAL_GL_SRC_ALPHA,
                                     LOCAL_GL_ZERO, LOCAL_GL_SRC_ALPHA);

  Matrix4x4 flipX = Matrix4x4::Scaling(-1, 1, 1);
  Matrix4x4 flipY = Matrix4x4::Scaling(1, -1, 1);

  if (mIsCoveringTitlebar && !mIsFullscreen) {
    // Mask the top corners.
    mCornerMaskImage->Draw(aManager, aRect.TopLeft());
    mCornerMaskImage->Draw(aManager, aRect.TopRight(), flipX);
  }

  if (mHasRoundedBottomCorners && !mIsFullscreen) {
    // Mask the bottom corners.
    mCornerMaskImage->Draw(aManager, aRect.BottomLeft(), flipY);
    mCornerMaskImage->Draw(aManager, aRect.BottomRight(), flipY * flipX);
  }

  // Reset blend mode.
  aManager->gl()->fBlendFuncSeparate(LOCAL_GL_ONE, LOCAL_GL_ONE_MINUS_SRC_ALPHA,
                                     LOCAL_GL_ONE, LOCAL_GL_ONE);
}

static int32_t
FindTitlebarBottom(const nsTArray<nsIWidget::ThemeGeometry>& aThemeGeometries,
                   int32_t aWindowWidth)
{
  int32_t titlebarBottom = 0;
  for (uint32_t i = 0; i < aThemeGeometries.Length(); ++i) {
    const nsIWidget::ThemeGeometry& g = aThemeGeometries[i];
    if ((g.mType == nsNativeThemeCocoa::eThemeGeometryTypeTitlebar) &&
        g.mRect.X() <= 0 &&
        g.mRect.XMost() >= aWindowWidth &&
        g.mRect.Y() <= 0) {
      titlebarBottom = std::max(titlebarBottom, g.mRect.YMost());
    }
  }
  return titlebarBottom;
}

static int32_t
FindUnifiedToolbarBottom(const nsTArray<nsIWidget::ThemeGeometry>& aThemeGeometries,
                         int32_t aWindowWidth, int32_t aTitlebarBottom)
{
  int32_t unifiedToolbarBottom = aTitlebarBottom;
  for (uint32_t i = 0; i < aThemeGeometries.Length(); ++i) {
    const nsIWidget::ThemeGeometry& g = aThemeGeometries[i];
    if ((g.mType == nsNativeThemeCocoa::eThemeGeometryTypeToolbar) &&
        g.mRect.X() <= 0 &&
        g.mRect.XMost() >= aWindowWidth &&
        g.mRect.Y() <= aTitlebarBottom) {
      unifiedToolbarBottom = std::max(unifiedToolbarBottom, g.mRect.YMost());
    }
  }
  return unifiedToolbarBottom;
}

static LayoutDeviceIntRect
FindFirstRectOfType(const nsTArray<nsIWidget::ThemeGeometry>& aThemeGeometries,
                    nsITheme::ThemeGeometryType aThemeGeometryType)
{
  for (uint32_t i = 0; i < aThemeGeometries.Length(); ++i) {
    const nsIWidget::ThemeGeometry& g = aThemeGeometries[i];
    if (g.mType == aThemeGeometryType) {
      return g.mRect;
    }
  }
  return LayoutDeviceIntRect();
}

void
nsChildView::UpdateThemeGeometries(const nsTArray<ThemeGeometry>& aThemeGeometries)
{
  if (![mView window])
    return;

  UpdateVibrancy(aThemeGeometries);

  if (![[mView window] isKindOfClass:[ToolbarWindow class]])
    return;

  // Update unified toolbar height and sheet attachment position.
  int32_t windowWidth = mBounds.width;
  int32_t titlebarBottom = FindTitlebarBottom(aThemeGeometries, windowWidth);
  int32_t unifiedToolbarBottom =
    FindUnifiedToolbarBottom(aThemeGeometries, windowWidth, titlebarBottom);
  int32_t toolboxBottom =
    FindFirstRectOfType(aThemeGeometries, nsNativeThemeCocoa::eThemeGeometryTypeToolbox).YMost();

  ToolbarWindow* win = (ToolbarWindow*)[mView window];
  bool drawsContentsIntoWindowFrame = [win drawsContentsIntoWindowFrame];
  int32_t titlebarHeight = CocoaPointsToDevPixels([win titlebarHeight]);
  int32_t contentOffset = drawsContentsIntoWindowFrame ? titlebarHeight : 0;
  int32_t devUnifiedHeight = titlebarHeight + unifiedToolbarBottom - contentOffset;
  [win setUnifiedToolbarHeight:DevPixelsToCocoaPoints(devUnifiedHeight)];
#if(0)
  // This gets called a lot, and is useless spinning on 10.4.
  int32_t devSheetPosition = titlebarHeight + std::max(toolboxBottom, unifiedToolbarBottom) - contentOffset;
  [win setSheetAttachmentPosition:DevPixelsToCocoaPoints(devSheetPosition)];
#endif

  // Update titlebar control offsets.
  LayoutDeviceIntRect windowButtonRect = FindFirstRectOfType(aThemeGeometries, nsNativeThemeCocoa::eThemeGeometryTypeWindowButtons);
  [win placeWindowButtons:[mView convertRect:DevPixelsToCocoaPoints(windowButtonRect) toView:nil]];
  LayoutDeviceIntRect fullScreenButtonRect = FindFirstRectOfType(aThemeGeometries, nsNativeThemeCocoa::eThemeGeometryTypeFullscreenButton);
  [win placeFullScreenButton:[mView convertRect:DevPixelsToCocoaPoints(fullScreenButtonRect) toView:nil]];
}

static LayoutDeviceIntRegion
GatherThemeGeometryRegion(const nsTArray<nsIWidget::ThemeGeometry>& aThemeGeometries,
                          nsITheme::ThemeGeometryType aThemeGeometryType)
{
  LayoutDeviceIntRegion region;
  for (size_t i = 0; i < aThemeGeometries.Length(); ++i) {
    const nsIWidget::ThemeGeometry& g = aThemeGeometries[i];
    if (g.mType == aThemeGeometryType) {
      region.OrWith(g.mRect);
    }
  }
  return region;
}

template<typename Region>
static void MakeRegionsNonOverlappingImpl(Region& aOutUnion) { }

template<typename Region, typename ... Regions>
static void MakeRegionsNonOverlappingImpl(Region& aOutUnion, Region& aFirst, Regions& ... aRest)
{
  MakeRegionsNonOverlappingImpl(aOutUnion, aRest...);
  aFirst.SubOut(aOutUnion);
  aOutUnion.OrWith(aFirst);
}

// Subtracts parts from regions in such a way that they don't have any overlap.
// Each region in the argument list will have the union of all the regions
// *following* it subtracted from itself. In other words, the arguments are
// sorted low priority to high priority.
template<typename Region, typename ... Regions>
static void MakeRegionsNonOverlapping(Region& aFirst, Regions& ... aRest)
{
  Region unionOfAll;
  MakeRegionsNonOverlappingImpl(unionOfAll, aFirst, aRest...);
}

void
nsChildView::UpdateVibrancy(const nsTArray<ThemeGeometry>& aThemeGeometries)
{
  if (!VibrancyManager::SystemSupportsVibrancy()) {
    return;
  }

  LayoutDeviceIntRegion sheetRegion =
    GatherThemeGeometryRegion(aThemeGeometries, nsNativeThemeCocoa::eThemeGeometryTypeSheet);
  LayoutDeviceIntRegion vibrantLightRegion =
    GatherThemeGeometryRegion(aThemeGeometries, nsNativeThemeCocoa::eThemeGeometryTypeVibrancyLight);
  LayoutDeviceIntRegion vibrantDarkRegion =
    GatherThemeGeometryRegion(aThemeGeometries, nsNativeThemeCocoa::eThemeGeometryTypeVibrancyDark);
  LayoutDeviceIntRegion menuRegion =
    GatherThemeGeometryRegion(aThemeGeometries, nsNativeThemeCocoa::eThemeGeometryTypeMenu);
  LayoutDeviceIntRegion tooltipRegion =
    GatherThemeGeometryRegion(aThemeGeometries, nsNativeThemeCocoa::eThemeGeometryTypeTooltip);
  LayoutDeviceIntRegion highlightedMenuItemRegion =
    GatherThemeGeometryRegion(aThemeGeometries, nsNativeThemeCocoa::eThemeGeometryTypeHighlightedMenuItem);

  MakeRegionsNonOverlapping(sheetRegion, vibrantLightRegion, vibrantDarkRegion,
                            menuRegion, tooltipRegion, highlightedMenuItemRegion);

  auto& vm = EnsureVibrancyManager();
  vm.UpdateVibrantRegion(VibrancyType::LIGHT, vibrantLightRegion);
  vm.UpdateVibrantRegion(VibrancyType::TOOLTIP, tooltipRegion);
  vm.UpdateVibrantRegion(VibrancyType::MENU, menuRegion);
  vm.UpdateVibrantRegion(VibrancyType::HIGHLIGHTED_MENUITEM, highlightedMenuItemRegion);
  vm.UpdateVibrantRegion(VibrancyType::SHEET, sheetRegion);
  vm.UpdateVibrantRegion(VibrancyType::DARK, vibrantDarkRegion);
}

void
nsChildView::ClearVibrantAreas()
{
  if (VibrancyManager::SystemSupportsVibrancy()) {
    EnsureVibrancyManager().ClearVibrantAreas();
  }
}

static VibrancyType
ThemeGeometryTypeToVibrancyType(nsITheme::ThemeGeometryType aThemeGeometryType)
{
  switch (aThemeGeometryType) {
    case nsNativeThemeCocoa::eThemeGeometryTypeVibrancyLight:
      return VibrancyType::LIGHT;
    case nsNativeThemeCocoa::eThemeGeometryTypeVibrancyDark:
      return VibrancyType::DARK;
    case nsNativeThemeCocoa::eThemeGeometryTypeTooltip:
      return VibrancyType::TOOLTIP;
    case nsNativeThemeCocoa::eThemeGeometryTypeMenu:
      return VibrancyType::MENU;
    case nsNativeThemeCocoa::eThemeGeometryTypeHighlightedMenuItem:
      return VibrancyType::HIGHLIGHTED_MENUITEM;
    case nsNativeThemeCocoa::eThemeGeometryTypeSheet:
      return VibrancyType::SHEET;
    default:
      MOZ_CRASH();
  }
}

NSColor*
nsChildView::VibrancyFillColorForThemeGeometryType(nsITheme::ThemeGeometryType aThemeGeometryType)
{
  if (VibrancyManager::SystemSupportsVibrancy()) {
    return EnsureVibrancyManager().VibrancyFillColorForType(
      ThemeGeometryTypeToVibrancyType(aThemeGeometryType));
  }
  return [NSColor whiteColor];
}

NSColor*
nsChildView::VibrancyFontSmoothingBackgroundColorForThemeGeometryType(nsITheme::ThemeGeometryType aThemeGeometryType)
{
  if (VibrancyManager::SystemSupportsVibrancy()) {
    return EnsureVibrancyManager().VibrancyFontSmoothingBackgroundColorForType(
      ThemeGeometryTypeToVibrancyType(aThemeGeometryType));
  }
  return [NSColor clearColor];
}

mozilla::VibrancyManager&
nsChildView::EnsureVibrancyManager()
{
  MOZ_ASSERT(mView, "Only call this once we have a view!");
  if (!mVibrancyManager) {
    mVibrancyManager = MakeUnique<VibrancyManager>(*this, mView);
  }
  return *mVibrancyManager;
}

nsChildView::SwipeInfo
nsChildView::SendMayStartSwipe(const mozilla::PanGestureInput& aSwipeStartEvent)
{
  nsCOMPtr<nsIWidget> kungFuDeathGrip(this);

  uint32_t direction = (aSwipeStartEvent.mPanDisplacement.x > 0.0)
    ? (uint32_t)nsIDOMSimpleGestureEvent::DIRECTION_RIGHT
    : (uint32_t)nsIDOMSimpleGestureEvent::DIRECTION_LEFT;

  // We're ready to start the animation. Tell Gecko about it, and at the same
  // time ask it if it really wants to start an animation for this event.
  // This event also reports back the directions that we can swipe in.
  LayoutDeviceIntPoint position =
    RoundedToInt(aSwipeStartEvent.mPanStartPoint * ScreenToLayoutDeviceScale(1));
  WidgetSimpleGestureEvent geckoEvent =
    SwipeTracker::CreateSwipeGestureEvent(eSwipeGestureMayStart, this,
                                          position);
  geckoEvent.direction = direction;
  geckoEvent.delta = 0.0;
  geckoEvent.allowedDirections = 0;
  bool shouldStartSwipe = DispatchWindowEvent(geckoEvent); // event cancelled == swipe should start

  SwipeInfo result = { shouldStartSwipe, geckoEvent.allowedDirections };
  return result;
}

void
nsChildView::TrackScrollEventAsSwipe(const mozilla::PanGestureInput& aSwipeStartEvent,
                                     uint32_t aAllowedDirections)
{
  // If a swipe is currently being tracked kill it -- it's been interrupted
  // by another gesture event.
  if (mSwipeTracker) {
    mSwipeTracker->CancelSwipe();
    mSwipeTracker->Destroy();
    mSwipeTracker = nullptr;
  }

  uint32_t direction = (aSwipeStartEvent.mPanDisplacement.x > 0.0)
    ? (uint32_t)nsIDOMSimpleGestureEvent::DIRECTION_RIGHT
    : (uint32_t)nsIDOMSimpleGestureEvent::DIRECTION_LEFT;

  mSwipeTracker = new SwipeTracker(*this, aSwipeStartEvent,
                                   aAllowedDirections, direction);

  if (!mAPZC) {
    mCurrentPanGestureBelongsToSwipe = true;
  }
}

void
nsChildView::SwipeFinished()
{
  mSwipeTracker = nullptr;
}

already_AddRefed<gfx::DrawTarget>
nsChildView::StartRemoteDrawingInRegion(nsIntRegion& aInvalidRegion)
{
  // should have created the GLPresenter in InitCompositor.
  MOZ_ASSERT(mGLPresenter);
  if (!mGLPresenter) {
    mGLPresenter = GLPresenter::CreateForWindow(this);

    if (!mGLPresenter) {
      return nullptr;
    }
  }

  LayoutDeviceIntRegion dirtyRegion(LayoutDeviceIntRegion::FromUnknownRegion(aInvalidRegion));
  LayoutDeviceIntSize renderSize =
    LayoutDeviceIntSize::FromUnknownSize(mBounds.Size());

  if (!mBasicCompositorImage) {
    mBasicCompositorImage = new RectTextureImage(mGLPresenter->gl());
  }

  RefPtr<gfx::DrawTarget> drawTarget =
    mBasicCompositorImage->BeginUpdate(renderSize, dirtyRegion);

  if (!drawTarget) {
    // Composite unchanged textures.
    DoRemoteComposition(LayoutDeviceIntRect::FromUnknownRect(mBounds));
    return nullptr;
  }

  aInvalidRegion = mBasicCompositorImage->GetUpdateRegion().ToUnknownRegion();

  return drawTarget.forget();
}

void
nsChildView::EndRemoteDrawing()
{
  mBasicCompositorImage->EndUpdate(true);
  DoRemoteComposition(LayoutDeviceIntRect::FromUnknownRect(mBounds));
}

void
nsChildView::CleanupRemoteDrawing()
{
  mBasicCompositorImage = nullptr;
  mCornerMaskImage = nullptr;
  mResizerImage = nullptr;
  mTitlebarImage = nullptr;
  mGLPresenter = nullptr;
}

bool
nsChildView::InitCompositor(Compositor* aCompositor)
{
  if (aCompositor->GetBackendType() == LayersBackend::LAYERS_BASIC) {
    if (!mGLPresenter) {
      mGLPresenter = GLPresenter::CreateForWindow(this);
    }

    return !!mGLPresenter;
  }
  return true;
}

void
nsChildView::DoRemoteComposition(const LayoutDeviceIntRect& aRenderRect)
{
  if (![(ChildView*)mView preRender:mGLPresenter->GetNSOpenGLContext()]) {
    return;
  }
  mGLPresenter->BeginFrame(aRenderRect.Size());

  // Draw the result from the basic compositor.
  mBasicCompositorImage->Draw(mGLPresenter, LayoutDeviceIntPoint(0, 0));

  // DrawWindowOverlay doesn't do anything for non-GL, so it didn't paint
  // anything during the basic compositor transaction. Draw the overlay now.
  DrawWindowOverlay(mGLPresenter, aRenderRect);

  mGLPresenter->EndFrame();

  [(ChildView*)mView postRender:mGLPresenter->GetNSOpenGLContext()];
}

void
nsChildView::UpdateWindowDraggingRegion(const LayoutDeviceIntRegion& aRegion)
{
  if (mDraggableRegion != aRegion) {
    mDraggableRegion = aRegion;
    [(ChildView*)mView updateWindowDraggableState];
  }
}

void
nsChildView::ReportSwipeStarted(uint64_t aInputBlockId,
                                bool aStartSwipe)
{
  if (mSwipeEventQueue && mSwipeEventQueue->inputBlockId == aInputBlockId) {
    if (aStartSwipe) {
      PanGestureInput& startEvent = mSwipeEventQueue->queuedEvents[0];
      TrackScrollEventAsSwipe(startEvent, mSwipeEventQueue->allowedDirections);
      for (size_t i = 1; i < mSwipeEventQueue->queuedEvents.Length(); i++) {
        mSwipeTracker->ProcessEvent(mSwipeEventQueue->queuedEvents[i]);
      }
    }
    mSwipeEventQueue = nullptr;
  }
}

void
nsChildView::DispatchAPZWheelInputEvent(InputData& aEvent, bool aCanTriggerSwipe)
{
  if (mSwipeTracker && aEvent.mInputType == PANGESTURE_INPUT) {
    // Give the swipe tracker a first pass at the event. If a new pan gesture
    // has been started since the beginning of the swipe, the swipe tracker
    // will know to ignore the event.
    nsEventStatus status = mSwipeTracker->ProcessEvent(aEvent.AsPanGestureInput());
    if (status == nsEventStatus_eConsumeNoDefault) {
      return;
    }
  }

  WidgetWheelEvent event(true, eWheel, this);

  if (mAPZC) {
    uint64_t inputBlockId = 0;
    ScrollableLayerGuid guid;

    nsEventStatus result = mAPZC->ReceiveInputEvent(aEvent, &guid, &inputBlockId);
    if (result == nsEventStatus_eConsumeNoDefault) {
      return;
    }

    switch(aEvent.mInputType) {
      case PANGESTURE_INPUT: {
        PanGestureInput& panInput = aEvent.AsPanGestureInput();

        event = panInput.ToWidgetWheelEvent(this);
        if (aCanTriggerSwipe) {
          SwipeInfo swipeInfo = SendMayStartSwipe(panInput);
          event.mCanTriggerSwipe = swipeInfo.wantsSwipe;
          if (swipeInfo.wantsSwipe) {
            if (result == nsEventStatus_eIgnore) {
              // APZ has determined and that scrolling horizontally in the
              // requested direction is impossible, so it didn't do any
              // scrolling for the event.
              // We know now that MayStartSwipe wants a swipe, so we can start
              // the swipe now.
              TrackScrollEventAsSwipe(panInput, swipeInfo.allowedDirections);
            } else {
              // We don't know whether this event can start a swipe, so we need
              // to queue up events and wait for a call to ReportSwipeStarted.
              // APZ might already have started scrolling in response to the
              // event if it knew that it's the right thing to do. In that case
              // we'll still get a call to ReportSwipeStarted, and we will
              // discard the queued events at that point.
              mSwipeEventQueue = MakeUnique<SwipeEventQueue>(swipeInfo.allowedDirections,
                                                             inputBlockId);
            }
          }
        }

        if (mSwipeEventQueue && mSwipeEventQueue->inputBlockId == inputBlockId) {
          mSwipeEventQueue->queuedEvents.AppendElement(panInput);
        }
        break;
      }
      case SCROLLWHEEL_INPUT: {
        event = aEvent.AsScrollWheelInput().ToWidgetWheelEvent(this);
        break;
      };
      default:
        MOZ_CRASH("unsupported event type");
        return;
    }
    if (event.mMessage == eWheel && (event.deltaX != 0 || event.deltaY != 0)) {
      ProcessUntransformedAPZEvent(&event, guid, inputBlockId, result);
    }
    return;
  }

  nsEventStatus status;
  switch(aEvent.mInputType) {
    case PANGESTURE_INPUT: {
      PanGestureInput panInput = aEvent.AsPanGestureInput();
      if (panInput.mType == PanGestureInput::PANGESTURE_MAYSTART ||
          panInput.mType == PanGestureInput::PANGESTURE_START) {
        mCurrentPanGestureBelongsToSwipe = false;
      }
      if (mCurrentPanGestureBelongsToSwipe) {
        // Ignore this event. It's a momentum event from a scroll gesture
        // that was processed as a swipe, and the swipe animation has
        // already finished (so mSwipeTracker is already null).
        MOZ_ASSERT(panInput.IsMomentum(),
          "If the fingers are still on the touchpad, we should still have a SwipeTracker, and it should have consumed this event.");
        return;
      }

      event = panInput.ToWidgetWheelEvent(this);
      if (aCanTriggerSwipe) {
        SwipeInfo swipeInfo = SendMayStartSwipe(panInput);

        // We're in the non-APZ case here, but we still want to know whether
        // the event was routed to a child process, so we use InputAPZContext
        // to get that piece of information.
        ScrollableLayerGuid guid;
        InputAPZContext context(guid, 0, nsEventStatus_eIgnore);

        event.mCanTriggerSwipe = swipeInfo.wantsSwipe;
        DispatchEvent(&event, status);
        if (swipeInfo.wantsSwipe) {
          if (context.WasRoutedToChildProcess()) {
            // We don't know whether this event can start a swipe, so we need
            // to queue up events and wait for a call to ReportSwipeStarted.
            mSwipeEventQueue = MakeUnique<SwipeEventQueue>(swipeInfo.allowedDirections, 0);
          } else if (event.TriggersSwipe()) {
            TrackScrollEventAsSwipe(panInput, swipeInfo.allowedDirections);
          }
        }

        if (mSwipeEventQueue && mSwipeEventQueue->inputBlockId == 0) {
          mSwipeEventQueue->queuedEvents.AppendElement(panInput);
        }
        return;
      }
      break;
    }
    case SCROLLWHEEL_INPUT: {
      event = aEvent.AsScrollWheelInput().ToWidgetWheelEvent(this);
      break;
    }
    default:
      MOZ_CRASH("unexpected event type");
      return;
  }
  if (event.mMessage == eWheel && (event.deltaX != 0 || event.deltaY != 0)) {
    DispatchEvent(&event, status);
  }
}

#ifdef ACCESSIBILITY
already_AddRefed<a11y::Accessible>
nsChildView::GetDocumentAccessible()
{
  if (!mozilla::a11y::ShouldA11yBeEnabled())
    return nullptr;

  if (mAccessible) {
    RefPtr<a11y::Accessible> ret;
    CallQueryReferent(mAccessible.get(),
                      static_cast<a11y::Accessible**>(getter_AddRefs(ret)));
    return ret.forget();
  }

  // need to fetch the accessible anew, because it has gone away.
  // cache the accessible in our weak ptr
  RefPtr<a11y::Accessible> acc = GetRootAccessible();
  mAccessible = do_GetWeakReference(acc.get());

  return acc.forget();
}
#endif

// RectTextureImage implementation

RectTextureImage::~RectTextureImage()
{
  if (mTexture) {
    mGLContext->MakeCurrent();
    mGLContext->fDeleteTextures(1, &mTexture);
    mTexture = 0;
  }
}

LayoutDeviceIntSize
RectTextureImage::TextureSizeForSize(const LayoutDeviceIntSize& aSize)
{
  return LayoutDeviceIntSize(gfx::NextPowerOfTwo(aSize.width),
                             gfx::NextPowerOfTwo(aSize.height));
}

already_AddRefed<gfx::DrawTarget>
RectTextureImage::BeginUpdate(const LayoutDeviceIntSize& aNewSize,
                              const LayoutDeviceIntRegion& aDirtyRegion)
{
  MOZ_ASSERT(!mInUpdate, "Beginning update during update!");
  mUpdateRegion = aDirtyRegion;
  if (aNewSize != mUsedSize) {
    mUsedSize = aNewSize;
    mUpdateRegion =
      LayoutDeviceIntRect(LayoutDeviceIntPoint(0, 0), aNewSize);
  }

  if (mUpdateRegion.IsEmpty()) {
    return nullptr;
  }

  LayoutDeviceIntSize neededBufferSize = TextureSizeForSize(mUsedSize);
  if (!mUpdateDrawTarget || mBufferSize != neededBufferSize) {
    gfx::IntSize size(neededBufferSize.width, neededBufferSize.height);
    mUpdateDrawTarget =
      gfx::Factory::CreateDrawTarget(gfx::BackendType::COREGRAPHICS, size,
                                     gfx::SurfaceFormat::B8G8R8A8);
    mBufferSize = neededBufferSize;
  }

  mInUpdate = true;

  RefPtr<gfx::DrawTarget> drawTarget = mUpdateDrawTarget;
  return drawTarget.forget();
}

#define NSFoundationVersionWithProperStrideSupportForSubtextureUpload NSFoundationVersionNumber10_6_3

static bool
CanUploadSubtextures()
{
return false;
/*
  return NSFoundationVersionNumber >= NSFoundationVersionWithProperStrideSupportForSubtextureUpload;
*/
}

void
RectTextureImage::EndUpdate(bool aKeepSurface)
{
  MOZ_ASSERT(mInUpdate, "Ending update while not in update");

  bool overwriteTexture = false;
  LayoutDeviceIntRegion updateRegion = mUpdateRegion;
  if (!mTexture || (mTextureSize != mBufferSize)) {
    overwriteTexture = true;
    mTextureSize = mBufferSize;
  }

  if (overwriteTexture || !CanUploadSubtextures()) {
    updateRegion =
      LayoutDeviceIntRect(LayoutDeviceIntPoint(0, 0), mTextureSize);
  }

  RefPtr<gfx::SourceSurface> snapshot = mUpdateDrawTarget->Snapshot();
  RefPtr<gfx::DataSourceSurface> dataSnapshot = snapshot->GetDataSurface();

  UploadSurfaceToTexture(mGLContext,
                         dataSnapshot,
                         updateRegion.ToUnknownRegion(),
                         mTexture,
                         overwriteTexture,
                         updateRegion.GetBounds().TopLeft().ToUnknownPoint(),
                         false,
                         LOCAL_GL_TEXTURE0,
                         LOCAL_GL_TEXTURE_RECTANGLE_ARB);

  if (!aKeepSurface) {
    mUpdateDrawTarget = nullptr;
  }

  mInUpdate = false;
}

void
RectTextureImage::UpdateFromCGContext(const LayoutDeviceIntSize& aNewSize,
                                      const LayoutDeviceIntRegion& aDirtyRegion,
                                      CGContextRef aCGContext)
{
  gfx::IntSize size = gfx::IntSize(CGBitmapContextGetWidth(aCGContext),
                                   CGBitmapContextGetHeight(aCGContext));
  mBufferSize.SizeTo(size.width, size.height);
  RefPtr<gfx::DrawTarget> dt = BeginUpdate(aNewSize, aDirtyRegion);
  if (dt) {
    gfx::Rect rect(0, 0, size.width, size.height);
    gfxUtils::ClipToRegion(dt, GetUpdateRegion().ToUnknownRegion());
    RefPtr<gfx::SourceSurface> sourceSurface =
      dt->CreateSourceSurfaceFromData(static_cast<uint8_t *>(CGBitmapContextGetData(aCGContext)),
                                      size,
                                      CGBitmapContextGetBytesPerRow(aCGContext),
                                      gfx::SurfaceFormat::B8G8R8A8);
    dt->DrawSurface(sourceSurface, rect, rect,
                    gfx::DrawSurfaceOptions(),
                    gfx::DrawOptions(1.0, gfx::CompositionOp::OP_SOURCE));
    dt->PopClip();
    EndUpdate();
  }
}

void
RectTextureImage::Draw(GLManager* aManager,
                       const LayoutDeviceIntPoint& aLocation,
                       const Matrix4x4& aTransform)
{
  ShaderProgramOGL* program = aManager->GetProgram(LOCAL_GL_TEXTURE_RECTANGLE_ARB,
                                                   gfx::SurfaceFormat::R8G8B8A8);

  aManager->gl()->fActiveTexture(LOCAL_GL_TEXTURE0);
  aManager->gl()->fBindTexture(LOCAL_GL_TEXTURE_RECTANGLE_ARB, mTexture);

  aManager->ActivateProgram(program);
  program->SetProjectionMatrix(aManager->GetProjMatrix());
  program->SetLayerTransform(Matrix4x4(aTransform).PostTranslate(aLocation.x, aLocation.y, 0));
  program->SetTextureTransform(gfx::Matrix4x4());
  program->SetRenderOffset(nsIntPoint(0, 0));
  program->SetTexCoordMultiplier(mUsedSize.width, mUsedSize.height);
  program->SetTextureUnit(0);

  aManager->BindAndDrawQuad(program,
                            gfx::Rect(0.0, 0.0, mUsedSize.width, mUsedSize.height),
                            gfx::Rect(0.0, 0.0, 1.0f, 1.0f));

  aManager->gl()->fBindTexture(LOCAL_GL_TEXTURE_RECTANGLE_ARB, 0);
}

// GLPresenter implementation

GLPresenter::GLPresenter(GLContext* aContext)
 : mGLContext(aContext)
{
  mGLContext->MakeCurrent();
  ShaderConfigOGL config;
  config.SetTextureTarget(LOCAL_GL_TEXTURE_RECTANGLE_ARB);
  mRGBARectProgram = new ShaderProgramOGL(mGLContext,
    ProgramProfileOGL::GetProfileFor(config));

  // Create mQuadVBO.
  mGLContext->fGenBuffers(1, &mQuadVBO);
  mGLContext->fBindBuffer(LOCAL_GL_ARRAY_BUFFER, mQuadVBO);

  // 1 quad, with the number of the quad (vertexID) encoded in w.
  GLfloat vertices[] = {
    0.0f, 0.0f, 0.0f, 0.0f,
    1.0f, 0.0f, 0.0f, 0.0f,
    0.0f, 1.0f, 0.0f, 0.0f,
    1.0f, 0.0f, 0.0f, 0.0f,
    0.0f, 1.0f, 0.0f, 0.0f,
    1.0f, 1.0f, 0.0f, 0.0f,
  };
  HeapCopyOfStackArray<GLfloat> verticesOnHeap(vertices);
  mGLContext->fBufferData(LOCAL_GL_ARRAY_BUFFER,
                          verticesOnHeap.ByteLength(),
                          verticesOnHeap.Data(),
                          LOCAL_GL_STATIC_DRAW);
   mGLContext->fBindBuffer(LOCAL_GL_ARRAY_BUFFER, 0);
}

GLPresenter::~GLPresenter()
{
  if (mQuadVBO) {
    mGLContext->MakeCurrent();
    mGLContext->fDeleteBuffers(1, &mQuadVBO);
    mQuadVBO = 0;
  }
}

void
GLPresenter::BindAndDrawQuad(ShaderProgramOGL *aProgram,
                             const gfx::Rect& aLayerRect,
                             const gfx::Rect& aTextureRect)
{
  mGLContext->MakeCurrent();

  gfx::Rect layerRects[4];
  gfx::Rect textureRects[4];

  layerRects[0] = aLayerRect;
  textureRects[0] = aTextureRect;

  aProgram->SetLayerRects(layerRects);
  aProgram->SetTextureRects(textureRects);

  const GLuint coordAttribIndex = 0;

  mGLContext->fBindBuffer(LOCAL_GL_ARRAY_BUFFER, mQuadVBO);
  mGLContext->fVertexAttribPointer(coordAttribIndex, 4,
                                   LOCAL_GL_FLOAT, LOCAL_GL_FALSE, 0,
                                   (GLvoid*)0);
  mGLContext->fEnableVertexAttribArray(coordAttribIndex);
  mGLContext->fDrawArrays(LOCAL_GL_TRIANGLES, 0, 6);
  mGLContext->fDisableVertexAttribArray(coordAttribIndex);
}

void
GLPresenter::BeginFrame(LayoutDeviceIntSize aRenderSize)
{
  mGLContext->MakeCurrent();

  mGLContext->fViewport(0, 0, aRenderSize.width, aRenderSize.height);

  // Matrix to transform (0, 0, width, height) to viewport space (-1.0, 1.0,
  // 2, 2) and flip the contents.
  gfx::Matrix viewMatrix = gfx::Matrix::Translation(-1.0, 1.0);
  viewMatrix.PreScale(2.0f / float(aRenderSize.width),
                      2.0f / float(aRenderSize.height));
  viewMatrix.PreScale(1.0f, -1.0f);

  gfx::Matrix4x4 matrix3d = gfx::Matrix4x4::From2D(viewMatrix);
  matrix3d._33 = 0.0f;

  // set the projection matrix for the next time the program is activated
  mProjMatrix = matrix3d;

  // Default blend function implements "OVER"
  mGLContext->fBlendFuncSeparate(LOCAL_GL_ONE, LOCAL_GL_ONE_MINUS_SRC_ALPHA,
                                 LOCAL_GL_ONE, LOCAL_GL_ONE);
  mGLContext->fEnable(LOCAL_GL_BLEND);

  mGLContext->fClearColor(0.0, 0.0, 0.0, 0.0);
  mGLContext->fClear(LOCAL_GL_COLOR_BUFFER_BIT | LOCAL_GL_DEPTH_BUFFER_BIT);

  mGLContext->fEnable(LOCAL_GL_TEXTURE_RECTANGLE_ARB);
}

void
GLPresenter::EndFrame()
{
  mGLContext->SwapBuffers();
  mGLContext->fBindBuffer(LOCAL_GL_ARRAY_BUFFER, 0);
}

#pragma mark -

@implementation ChildView

// globalDragPboard is non-null during native drag sessions that did not originate
// in our native NSView (it is set in |draggingEntered:|). It is unset when the
// drag session ends for this view, either with the mouse exiting or when a drop
// occurs in this view.
// restore bug 966986
NSPasteboardWrapper* globalDragPboard = nil;

// gLastDragView and gLastDragMouseDownEvent are used to communicate information
// to the drag service during drag invocation (starting a drag in from the view).
// gLastDragView is only non-null while mouseDragged is on the call stack.
NSView* gLastDragView = nil;
NSEvent* gLastDragMouseDownEvent = nil;

+ (void)initialize
{
  static BOOL initialized = NO;

  if (!initialized) {
    // Inform the OS about the types of services (from the "Services" menu)
    // that we can handle.

    NSArray *sendTypes = [[NSArray alloc] initWithObjects:NSStringPboardType,NSHTMLPboardType,nil];
    NSArray *returnTypes = [[NSArray alloc] initWithObjects:NSStringPboardType,NSHTMLPboardType,nil];

    [NSApp registerServicesMenuSendTypes:sendTypes returnTypes:returnTypes];

    [sendTypes release];
    [returnTypes release];

    initialized = YES;
  }
}

+ (void)registerViewForDraggedTypes:(NSView*)aView
{
  [aView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,
                                                           NSStringPboardType,
                                                           NSHTMLPboardType,
                                                           NSURLPboardType,
                                                           NSFilesPromisePboardType,
                                                           kWildcardPboardType,
                                                           kCorePboardType_url,
                                                           kCorePboardType_urld,
                                                           kCorePboardType_urln,
                                                           nil]];
}

// initWithFrame:geckoChild:
- (id)initWithFrame:(NSRect)inFrame geckoChild:(nsChildView*)inChild
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  if ((self = [super initWithFrame:inFrame])) {
    mGeckoChild = inChild;
    mPendingDisplay = NO;
    mBlockedLastMouseDown = NO;
    mExpectingWheelStop = NO;

    mLastMouseDownEvent = nil;
    mLastKeyDownEvent = nil;
    mClickThroughMouseDownEvent = nil;
    mDragService = nullptr;

    mGestureState = eGestureState_None;
    mCumulativeMagnification = 0.0;
    mCumulativeRotation = 0.0;

    mCurKeyEvent = nil;
    mKeyDownHandled = false;
    mKeyPressHandled = NO;
    mKeyPressSent = NO;
    mIgnoreNextKeyUpEvent = NO;
    // initialization for NSTextInput
    mMarkedRange.location = NSNotFound;
    mMarkedRange.length = 0;

    // We can't call forceRefreshOpenGL here because, in order to work around
    // the bug, it seems we need to have a draw already happening. Therefore,
    // we call it in drawRect:inContext:, when we know that a draw is in
    // progress.
    mDidForceRefreshOpenGL = NO;

    [self setFocusRingType:NSFocusRingTypeNone];

#ifdef __LP64__
    mCancelSwipeAnimation = nil;
#endif

    mTopLeftCornerMask = NULL;
  }

  // register for things we'll take from other applications
  [ChildView registerViewForDraggedTypes:self];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(systemMetricsChanged)
                                               name:NSControlTintDidChangeNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(systemMetricsChanged)
                                               name:NSSystemColorsDidChangeNotification
                                             object:nil];
  // TODO: replace the string with the constant once we build with the 10.7 SDK
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(scrollbarSystemMetricChanged)
                                               name:@"NSPreferredScrollerStyleDidChangeNotification"
                                             object:nil];
  [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                      selector:@selector(systemMetricsChanged)
                                                          name:@"AppleAquaScrollBarVariantChanged"
                                                        object:nil
                                            suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_surfaceNeedsUpdate:)
                                               name:NSViewGlobalFrameDidChangeNotification
                                             object:self];

  return self;

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}

// NEVER define this in pre-10.6 builds. If you do, NSTextInput doesn't work
// properly (see http://prod.lists.apple.com/archives/cocoa-dev/2013/Dec/msg00068.html ).
// It seems to have something to do with the secret underlying NSInputContext
// and NSTSMInputContext, which became NSTextInputContext in 10.6.
#if(0)
// ComplexTextInputPanel's interpretKeyEvent hack won't work without this.
// It makes calls to +[NSTextInputContext currentContext], deep in system
// code, return the appropriate context.
- (NSTextInputContext *)inputContext
{
  NSTextInputContext* pluginContext = NULL;
  if (mGeckoChild && mGeckoChild->IsPluginFocused()) {
    ComplexTextInputPanel* ctiPanel =
      ComplexTextInputPanel::GetSharedComplexTextInputPanel();
    if (ctiPanel) {
      pluginContext = (NSTextInputContext*) ctiPanel->GetInputContext();
    }
  }
  if (pluginContext) {
    return pluginContext;
  } else {
    return [super inputContext];
  }
}
#endif

- (void)installTextInputHandler:(TextInputHandler*)aHandler
{
#if(0)
  mTextInputHandler = aHandler;
#endif
}

- (void)uninstallTextInputHandler
{
#if(0)
  mTextInputHandler = nullptr;
#endif
}

// Work around bug 603134.
// OS X has a bug that causes new OpenGL windows to only paint once or twice,
// then stop painting altogether. By clearing the drawable from the GL context,
// and then resetting the view to ourselves, we convince OS X to start updating
// again.
// This can cause a flash in new windows - bug 631339 - but it's very hard to
// fix that while maintaining this workaround.
- (void)forceRefreshOpenGL
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  [mGLContext clearDrawable];
  [self updateGLContext];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)setGLContext:(NSOpenGLContext *)aGLContext
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  mGLContext = aGLContext;
  [mGLContext retain];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (bool)preRender:(NSOpenGLContext *)aGLContext
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  if (![self window] ||
      ([[self window] isKindOfClass:[BaseWindow class]] &&
       ![(BaseWindow*)[self window] isVisibleOrBeingShown])) {
    // Before the window is shown, our GL context's front FBO is not
    // framebuffer complete, so we refuse to render.
    return false;
  }

  if (!mGLContext) {
    [self setGLContext:aGLContext];
    [self updateGLContext];
  }

  CGLLockContext((CGLContextObj)[aGLContext CGLContextObj]);

  return true;

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(false);
}

- (void)postRender:(NSOpenGLContext *)aGLContext
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  CGLUnlockContext((CGLContextObj)[aGLContext CGLContextObj]);

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)dealloc
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  [mGLContext release];
  [mPendingDirtyRects release];
  [mLastMouseDownEvent release];
  [mLastKeyDownEvent release];
  [mClickThroughMouseDownEvent release];
  CGImageRelease(mTopLeftCornerMask);
  ChildViewMouseTracker::OnDestroyView(self);

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)widgetDestroyed
{
#ifdef NS_LEOPARD_AND_LATER
  if (mTextInputHandler) {
    mTextInputHandler->OnDestroyWidget(mGeckoChild);
    mTextInputHandler = nullptr;
  }
#else
  nsTSMManager::OnDestroyView(self);
#endif
  mGeckoChild = nullptr;

  // Just in case we're destroyed abruptly and missed the draggingExited
  // or performDragOperation message.
  NS_IF_RELEASE(mDragService);
}

// mozView method, return our gecko child view widget. Note this does not AddRef.
- (nsIWidget*) widget
{
  return static_cast<nsIWidget*>(mGeckoChild);
}

- (void)systemMetricsChanged
{
  if (mGeckoChild)
    mGeckoChild->NotifyThemeChanged();
}

- (void)scrollbarSystemMetricChanged
{
  [self systemMetricsChanged];

  if (mGeckoChild) {
    nsIWidgetListener* listener = mGeckoChild->GetWidgetListener();
    if (listener) {
      nsIPresShell* presShell = listener->GetPresShell();
      if (presShell) {
        presShell->ReconstructFrames();
      }
    }
  }
}

- (void)setNeedsPendingDisplay
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  mPendingFullDisplay = YES;
  if (!mPendingDisplay) {
    [self performSelector:@selector(processPendingRedraws) withObject:nil afterDelay:0];
    mPendingDisplay = YES;
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)setNeedsPendingDisplayInRect:(NSRect)invalidRect
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!mPendingDirtyRects)
    mPendingDirtyRects = [[NSMutableArray alloc] initWithCapacity:1];
  [mPendingDirtyRects addObject:[NSValue valueWithRect:invalidRect]];
  if (!mPendingDisplay) {
    [self performSelector:@selector(processPendingRedraws) withObject:nil afterDelay:0];
    mPendingDisplay = YES;
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

// Clears the queue of any pending invalides
- (void)processPendingRedraws
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (mPendingFullDisplay) {
    [self setNeedsDisplay:YES];
  }
  else if (mPendingDirtyRects) {
    unsigned int count = [mPendingDirtyRects count];
    for (unsigned int i = 0; i < count; ++i) {
      [self setNeedsDisplayInRect:[[mPendingDirtyRects objectAtIndex:i] rectValue]];
    }
  }
  mPendingFullDisplay = NO;
  mPendingDisplay = NO;
  [mPendingDirtyRects release];
  mPendingDirtyRects = nil;

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)setNeedsDisplayInRect:(NSRect)aRect
{
  if (![self isUsingOpenGL]) {
    [super setNeedsDisplayInRect:aRect];
    return;
  }

  if ([[self window] isVisible] && [self isUsingMainThreadOpenGL]) {
    // Draw without calling drawRect. This prevent us from
    // needing to access the normal window buffer surface unnecessarily, so we
    // waste less time synchronizing the two surfaces. (These synchronizations
    // show up in a profiler as CGSDeviceLock / _CGSLockWindow /
    // _CGSSynchronizeWindowBackingStore.) It also means that Cocoa doesn't
    // have any potentially expensive invalid rect management for us.
    if (!mWaitingForPaint) {
// 10.4 doesn't implement NSRunLoopCommonModes, and we never draw with
// OpenGL anyway.
#if(0)
      mWaitingForPaint = YES;
      // Use NSRunLoopCommonModes instead of the default NSDefaultRunLoopMode
      // so that the timer also fires while a native menu is open.
      [self performSelector:@selector(drawUsingOpenGLCallback)
                 withObject:nil
                 afterDelay:0
                    inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
#else
      fprintf(stderr, "setNeedsDisplayInRect thinks we're using OpenGL!!\n");
#endif
    }
  }
}

- (NSString*)description
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  return [NSString stringWithFormat:@"ChildView %p, gecko child %p, frame %@", self, mGeckoChild, NSStringFromRect([self frame])];

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}

// Make the origin of this view the topLeft corner (gecko origin) rather
// than the bottomLeft corner (standard cocoa origin).
- (BOOL)isFlipped
{
  return YES;
}

- (BOOL)isOpaque
{
  return [[self window] isOpaque];
}

- (void)sendFocusEvent:(EventMessage)eventMessage
{
  if (!mGeckoChild)
    return;

  nsEventStatus status = nsEventStatus_eIgnore;
  WidgetGUIEvent focusGuiEvent(true, eventMessage, mGeckoChild);
  focusGuiEvent.time = PR_IntervalNow();
  mGeckoChild->DispatchEvent(&focusGuiEvent, status);
}

// We accept key and mouse events, so don't keep passing them up the chain. Allow
// this to be a 'focused' widget for event dispatch.
- (BOOL)acceptsFirstResponder
{
  return YES;
}

// Accept mouse down events on background windows
- (BOOL)acceptsFirstMouse:(NSEvent*)aEvent
{
  if (![[self window] isKindOfClass:[PopupWindow class]]) {
    // We rely on this function to tell us that the mousedown was on a
    // background window. Inside mouseDown we can't tell whether we were
    // inactive because at that point we've already been made active.
    // Unfortunately, acceptsFirstMouse is called for PopupWindows even when
    // their parent window is active, so ignore this on them for now.
    mClickThroughMouseDownEvent = [aEvent retain];
  }
  return YES;
}

- (void)scrollRect:(NSRect)aRect by:(NSSize)offset
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  // Update any pending dirty rects to reflect the new scroll position
  if (mPendingDirtyRects) {
    unsigned int count = [mPendingDirtyRects count];
    for (unsigned int i = 0; i < count; ++i) {
      NSRect oldRect = [[mPendingDirtyRects objectAtIndex:i] rectValue];
      NSRect newRect = NSOffsetRect(oldRect, offset.width, offset.height);
      [mPendingDirtyRects replaceObjectAtIndex:i
                                    withObject:[NSValue valueWithRect:newRect]];
    }
  }
  [super scrollRect:aRect by:offset];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (BOOL)mouseDownCanMoveWindow
{
  // Return YES so that _regionForOpaqueDescendants gets called, where the
  // actual draggable region will be assembled.
  return YES;
}

-(void)updateGLContext
{
  if (mGLContext) {
    CGLLockContext((CGLContextObj)[mGLContext CGLContextObj]);
    [mGLContext setView:self];
    [mGLContext update];
    CGLUnlockContext((CGLContextObj)[mGLContext CGLContextObj]);
  }
}

- (void)_surfaceNeedsUpdate:(NSNotification*)notification
{
   [self updateGLContext];
}

- (BOOL)wantsBestResolutionOpenGLSurface
{
  return nsCocoaUtils::HiDPIEnabled() ? YES : NO;
}

- (void)viewDidChangeBackingProperties
{
  [super viewDidChangeBackingProperties];
#if(0)
  if (mGeckoChild) {
    // actually, it could be the color space that's changed,
    // but we can't tell the difference here except by retrieving
    // the backing scale factor and comparing to the old value
    mGeckoChild->BackingScaleFactorChanged();
  }
#endif
}

- (BOOL)isCoveringTitlebar
{
  return [[self window] isKindOfClass:[BaseWindow class]] &&
         [(BaseWindow*)[self window] mainChildView] == self &&
         [(BaseWindow*)[self window] drawsContentsIntoWindowFrame];
}

- (void)viewWillStartLiveResize
{
  nsCOMPtr<nsIObserverService> observerService = mozilla::services::GetObserverService();

  if (!observerService) {
    return;
  }

  observerService->NotifyObservers(nullptr, "live-resize-start", nullptr);
}

- (void)viewDidEndLiveResize
{
  nsCOMPtr<nsIObserverService> observerService = mozilla::services::GetObserverService();

  if (!observerService) {
    return;
  }

  observerService->NotifyObservers(nullptr, "live-resize-end", nullptr);
}

- (NSColor*)vibrancyFillColorForThemeGeometryType:(nsITheme::ThemeGeometryType)aThemeGeometryType
{
  if (!mGeckoChild) {
    return [NSColor whiteColor];
  }
  return mGeckoChild->VibrancyFillColorForThemeGeometryType(aThemeGeometryType);
}

- (NSColor*)vibrancyFontSmoothingBackgroundColorForThemeGeometryType:(nsITheme::ThemeGeometryType)aThemeGeometryType
{
  if (!mGeckoChild) {
    return [NSColor clearColor];
  }
  return mGeckoChild->VibrancyFontSmoothingBackgroundColorForThemeGeometryType(aThemeGeometryType);
}

- (LayoutDeviceIntRegion)nativeDirtyRegionWithBoundingRect:(NSRect)aRect
{
  LayoutDeviceIntRect boundingRect = mGeckoChild->CocoaPointsToDevPixels(aRect);
  const NSRect *rects;
  NSInteger count;
  [self getRectsBeingDrawn:&rects count:&count];

  if (count > MAX_RECTS_IN_REGION) {
    return boundingRect;
  }

  LayoutDeviceIntRegion region;
  for (NSInteger i = 0; i < count; ++i) {
    region.Or(region, mGeckoChild->CocoaPointsToDevPixels(rects[i]));
  }
  region.And(region, boundingRect);
  return region;
}

// The display system has told us that a portion of our view is dirty. Tell
// gecko to paint it
- (void)drawRect:(NSRect)aRect
{
  CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  [self drawRect:aRect inContext:cgContext];

  // If we're a transparent window and our contents have changed, we need
  // to make sure the shadow is updated to the new contents.
  if ([[self window] isKindOfClass:[BaseWindow class]]) {
    [(BaseWindow*)[self window] deferredInvalidateShadow];
  }
}

- (void)drawRect:(NSRect)aRect inContext:(CGContextRef)aContext
{
  if (!mGeckoChild || !mGeckoChild->IsVisible())
    return;

#ifdef DEBUG_UPDATE
  LayoutDeviceIntRect geckoBounds;
  mGeckoChild->GetBounds(geckoBounds);

  fprintf (stderr, "---- Update[%p][%p] [%f %f %f %f] cgc: %p\n  gecko bounds: [%d %d %d %d]\n",
           self, mGeckoChild,
           aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height, aContext,
           geckoBounds.x, geckoBounds.y, geckoBounds.width, geckoBounds.height);

  CGAffineTransform xform = CGContextGetCTM(aContext);
  fprintf (stderr, "  xform in: [%f %f %f %f %f %f]\n", xform.a, xform.b, xform.c, xform.d, xform.tx, xform.ty);
#endif

  if ([self isUsingOpenGL]) {
    // For Gecko-initiated repaints in OpenGL mode, drawUsingOpenGL is
    // directly called from a delayed perform callback - without going through
    // drawRect.
    // Paints that come through here are triggered by something that Cocoa
    // controls, for example by window resizing or window focus changes.

    // Since this view is usually declared as opaque, the window's pixel
    // buffer may now contain garbage which we need to prevent from reaching
    // the screen. The only place where garbage can show is in the window
    // corners and the vibrant regions of the window - the rest of the window
    // is covered by opaque content in our OpenGL surface.
    // So we need to clear the pixel buffer contents in these areas.
    mGeckoChild->ClearVibrantAreas();
    [self clearCorners];

    // Do GL composition and return.
    [self drawUsingOpenGL];
    return;
  }

  PROFILER_LABEL("ChildView", "drawRect",
    js::ProfileEntry::Category::GRAPHICS);

  // The CGContext that drawRect supplies us with comes with a transform that
  // scales one user space unit to one Cocoa point, which can consist of
  // multiple dev pixels. But Gecko expects its supplied context to be scaled
  // to device pixels, so we need to reverse the scaling.
  //double scale = mGeckoChild->BackingScaleFactor();
  CGContextSaveGState(aContext);
  CGContextScaleCTM(aContext, 1.0, 1.0); //CGContextScaleCTM(aContext, 1.0 / scale, 1.0 / scale);

  NSSize viewSize = [self bounds].size;
  //nsIntSize backingSize(viewSize.width * scale, viewSize.height * scale);
  nsIntSize backingSize(viewSize.width, viewSize.height);

  CGContextSaveGState(aContext);

  LayoutDeviceIntRegion region = [self nativeDirtyRegionWithBoundingRect:aRect];

  // Create Cairo objects.
  RefPtr<gfxQuartzSurface> targetSurface;

  RefPtr<gfx::DrawTarget> dt =
    gfx::Factory::CreateDrawTargetForCairoCGContext(aContext,
                                                    gfx::IntSize(backingSize.width,
                                                                 backingSize.height));
  MOZ_ASSERT(dt); // see implementation
  dt->AddUserData(&gfxContext::sDontUseAsSourceKey, dt, nullptr);
  RefPtr<gfxContext> targetContext = new gfxContext(dt);

  // Set up the clip region.
  LayoutDeviceIntRegion::RectIterator iter(region);
  targetContext->NewPath();
  for (;;) {
    const LayoutDeviceIntRect* r = iter.Next();
    if (!r)
      break;
    targetContext->Rectangle(gfxRect(r->x, r->y, r->width, r->height));
  }
  targetContext->Clip();

  nsAutoRetainCocoaObject kungFuDeathGrip(self);
  bool painted = false;
  if (mGeckoChild->GetLayerManager()->GetBackendType() == LayersBackend::LAYERS_BASIC) {
    nsBaseWidget::AutoLayerManagerSetup
      setupLayerManager(mGeckoChild, targetContext, BufferMode::BUFFER_NONE);
    painted = mGeckoChild->PaintWindow(region);
  } else if (mGeckoChild->GetLayerManager()->GetBackendType() == LayersBackend::LAYERS_CLIENT) {
    // We only need this so that we actually get DidPaintWindow fired
    painted = mGeckoChild->PaintWindow(region);
  }

  targetContext = nullptr;
  targetSurface = nullptr;

  CGContextRestoreGState(aContext);

  // Undo the scale transform so that from now on the context is in
  // CocoaPoints again.
  CGContextRestoreGState(aContext);

  if (!painted && [self isOpaque]) {
    // Gecko refused to draw, but we've claimed to be opaque, so we have to
    // draw something--fill with white.
    CGContextSetRGBFillColor(aContext, 1, 1, 1, 1);
    //CGContextFillRect(aContext, NSRectToCGRect(aRect));
    CGRect cgr = *(CGRect*)&aRect; CGContextFillRect(aContext, cgr);
  }

  if ([self isCoveringTitlebar]) {
    [self drawTitleString];
    [self drawTitlebarHighlight];
    [self maskTopCornersInContext:aContext];
  }

#ifdef DEBUG_UPDATE
  fprintf (stderr, "---- update done ----\n");

#if 0
  CGContextSetRGBStrokeColor (aContext,
                            ((((unsigned long)self) & 0xff)) / 255.0,
                            ((((unsigned long)self) & 0xff00) >> 8) / 255.0,
                            ((((unsigned long)self) & 0xff0000) >> 16) / 255.0,
                            0.5);
#endif
  CGContextSetRGBStrokeColor(aContext, 1, 0, 0, 0.8);
  CGContextSetLineWidth(aContext, 4.0);
  CGContextStrokeRect(aContext, NSRectToCGRect(aRect));
#endif
}

- (BOOL)isUsingMainThreadOpenGL
{
  if (!mGeckoChild || ![self window])
    return NO;

  return mGeckoChild->GetLayerManager(nullptr)->GetBackendType() == mozilla::layers::LayersBackend::LAYERS_OPENGL;
}

- (BOOL)isUsingOpenGL
{
return NO; // 10.4 doesn't support it.
  if (!mGeckoChild || ![self window])
    return NO;

  return mGLContext || mUsingOMTCompositor || [self isUsingMainThreadOpenGL];
}

- (void)drawUsingOpenGL
{
  PROFILER_LABEL("ChildView", "drawUsingOpenGL",
    js::ProfileEntry::Category::GRAPHICS);

  if (![self isUsingOpenGL] || !mGeckoChild->IsVisible())
    return;

  mWaitingForPaint = NO;

  LayoutDeviceIntRect geckoBounds;
  mGeckoChild->GetBounds(geckoBounds);
  LayoutDeviceIntRegion region(geckoBounds);

  mGeckoChild->PaintWindow(region);

  // Force OpenGL to refresh the very first time we draw. This works around a
  // Mac OS X bug that stops windows updating on OS X when we use OpenGL.
  if (!mDidForceRefreshOpenGL) {
    [self performSelector:@selector(forceRefreshOpenGL) withObject:nil afterDelay:0];
    mDidForceRefreshOpenGL = YES;
  }
}

// Called asynchronously after setNeedsDisplay in order to avoid entering the
// normal drawing machinery.
- (void)drawUsingOpenGLCallback
{
  if (mWaitingForPaint) {
    [self drawUsingOpenGL];
  }
}

- (BOOL)hasRoundedBottomCorners
{
  return [[self window] respondsToSelector:@selector(bottomCornerRounded)] &&
  [[self window] bottomCornerRounded];
}

- (CGFloat)cornerRadius
{
  NSView* frameView = [[[self window] contentView] superview];
  if (!frameView || ![frameView respondsToSelector:@selector(roundedCornerRadius)])
    return 4.0f;
  return [frameView roundedCornerRadius];
}

// Accelerated windows have two NSSurfaces:
//  (1) The window's pixel buffer in the back and
//  (2) the OpenGL view in the front.
// These two surfaces are composited by the window manager. Drawing into the
// CGContext which is provided by drawRect ends up in (1).
// When our window has rounded corners, the OpenGL view has transparent pixels
// in the corners. In these places the contents of the window's pixel buffer
// can show through. So we need to make sure that the pixel buffer is
// transparent in the corners so that no garbage reaches the screen.
// The contents of the pixel buffer in the rest of the window don't matter
// because they're covered by opaque pixels of the OpenGL context.
// Making the corners transparent works even though our window is
// declared "opaque" (in the NSWindow's isOpaque method).
- (void)clearCorners
{
  CGFloat radius = [self cornerRadius];
  CGFloat w = [self bounds].size.width, h = [self bounds].size.height;
  [[NSColor clearColor] set];

  if ([self isCoveringTitlebar]) {
    NSRectFill(NSMakeRect(0, 0, radius, radius));
    NSRectFill(NSMakeRect(w - radius, 0, radius, radius));
  }

  if ([self hasRoundedBottomCorners]) {
    NSRectFill(NSMakeRect(0, h - radius, radius, radius));
    NSRectFill(NSMakeRect(w - radius, h - radius, radius, radius));
  }
}

// 10.4 needs this (below).
extern "C" {
enum PrivateCGCompositeMode {
    kPrivateCGCompositeClear            = 0,
    kPrivateCGCompositeCopy             = 1,
    kPrivateCGCompositeSourceOver       = 2,
    kPrivateCGCompositeSourceIn         = 3,
    kPrivateCGCompositeSourceOut        = 4,
    kPrivateCGCompositeSourceAtop       = 5,
    kPrivateCGCompositeDestinationOver  = 6,
    kPrivateCGCompositeDestinationIn    = 7,
    kPrivateCGCompositeDestinationOut   = 8,
    kPrivateCGCompositeDestinationAtop  = 9,
    kPrivateCGCompositeXOR              = 10,
    kPrivateCGCompositePlusDarker       = 11, // (max (0, (1-d) + (1-s)))
    kPrivateCGCompositePlusLighter      = 12, // (min (1, s + d))
};
}
extern "C" void CGContextSetCompositeOperation (CGContextRef,
	PrivateCGCompositeMode);

// This is the analog of nsChildView::MaybeDrawRoundedCorners for CGContexts.
// We only need to mask the top corners here because Cocoa does the masking
// for the window's bottom corners automatically (starting with 10.7).
- (void)maskTopCornersInContext:(CGContextRef)aContext
{
  CGFloat radius = [self cornerRadius];
  int32_t devPixelCornerRadius = mGeckoChild->CocoaPointsToDevPixels(radius);

  // First make sure that mTopLeftCornerMask is set up.
  if (!mTopLeftCornerMask ||
      int32_t(CGImageGetWidth(mTopLeftCornerMask)) != devPixelCornerRadius) {
    CGImageRelease(mTopLeftCornerMask);
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGContextRef imgCtx = CGBitmapContextCreate(NULL,
                                                devPixelCornerRadius,
                                                devPixelCornerRadius,
                                                8, devPixelCornerRadius * 4,
                                                rgb, kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(rgb);
    DrawTopLeftCornerMask(imgCtx, devPixelCornerRadius);
    mTopLeftCornerMask = CGBitmapContextCreateImage(imgCtx);
    CGContextRelease(imgCtx);
  }

#if NS_LEOPARD_AND_LATER
  // kCGBlendModeDestinationIn is the secret sauce which allows us to erase
  // already painted pixels. It's defined as R = D * Sa: multiply all channels
  // of the destination pixel with the alpha of the source pixel. In our case,
  // the source is mTopLeftCornerMask.
  CGContextSaveGState(aContext);
  CGContextSetBlendMode(aContext, kCGBlendModeDestinationIn);
#else
  // But 10.4 doesn't have that. Its equivalent is
  // kPrivateCGCompositeDestinationIn (which has existed since at least
  // 10.3.9); see gfx/2d/DrawTargetCG.cpp
  CGContextSaveGState(aContext);
  CGContextSetCompositeOperation(aContext, kPrivateCGCompositeDestinationIn);
#endif

  CGRect destRect = CGRectMake(0, 0, radius, radius);

  // Erase the top left corner...
  CGContextDrawImage(aContext, destRect, mTopLeftCornerMask);

  // ... and the top right corner.
  CGContextTranslateCTM(aContext, [self bounds].size.width, 0);
  CGContextScaleCTM(aContext, -1, 1);
  CGContextDrawImage(aContext, destRect, mTopLeftCornerMask);

  CGContextRestoreGState(aContext);
}

- (void)drawTitleString
{
  BaseWindow* window = (BaseWindow*)[self window];
  if (![window wantsTitleDrawn]) {
    return;
  }

  NSView* frameView = [[window contentView] superview];
  if (![frameView respondsToSelector:@selector(_drawTitleBar:)]) {
    return;
  }

  NSGraphicsContext* oldContext = [NSGraphicsContext currentContext];
  CGContextRef ctx = (CGContextRef)[oldContext graphicsPort];
  CGContextSaveGState(ctx);
  if ([oldContext isFlipped] != [frameView isFlipped]) {
    CGContextTranslateCTM(ctx, 0, [self bounds].size.height);
    CGContextScaleCTM(ctx, 1, -1);
  }
  [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:[frameView isFlipped]]];
  [frameView _drawTitleBar:[frameView bounds]];
  CGContextRestoreGState(ctx);
  [NSGraphicsContext setCurrentContext:oldContext];
}

- (void)drawTitlebarHighlight
{
  DrawTitlebarHighlight([self bounds].size, [self cornerRadius],
                        mGeckoChild->DevPixelsToCocoaPoints(1));
}

- (void)releaseWidgets:(NSArray*)aWidgetArray
{
  if (!aWidgetArray) {
    return;
  }
  NSInteger count = [aWidgetArray count];
  for (NSInteger i = 0; i < count; ++i) {
    NSNumber* pointer = (NSNumber*) [aWidgetArray objectAtIndex:i];
    nsIWidget* widget = (nsIWidget*) [pointer unsignedIntegerValue];
    NS_RELEASE(widget);
  }
}

- (void)viewWillDraw
{
  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  if (mGeckoChild) {
    // The OS normally *will* draw our NSWindow, no matter what we do here.
    // But Gecko can delete our parent widget(s) (along with mGeckoChild)
    // while processing a paint request, which closes our NSWindow and
    // makes the OS throw an NSInternalInconsistencyException assertion when
    // it tries to draw it.  Sometimes the OS also aborts the browser process.
    // So we need to retain our parent(s) here and not release it/them until
    // the next time through the main thread's run loop.  When we do this we
    // also need to retain and release mGeckoChild, which holds a strong
    // reference to us (otherwise we might have been deleted by the time
    // releaseWidgets: is called on us).  See bug 550392.
    nsIWidget* parent = mGeckoChild->GetParent();
    if (parent) {
      NSMutableArray* widgetArray = [NSMutableArray arrayWithCapacity:3];
      while (parent) {
        NS_ADDREF(parent);
        [widgetArray addObject:[NSNumber numberWithUnsignedInteger:(NSUInteger)parent]];
        parent = parent->GetParent();
      }
      NS_ADDREF(mGeckoChild);
      [widgetArray addObject:[NSNumber numberWithUnsignedInteger:(NSUInteger)mGeckoChild]];
      [self performSelector:@selector(releaseWidgets:)
                 withObject:widgetArray
                 afterDelay:0];
    }

    if ([self isUsingOpenGL]) {
      if (mGeckoChild->GetLayerManager()->GetBackendType() == LayersBackend::LAYERS_CLIENT) {
        ClientLayerManager *manager = static_cast<ClientLayerManager*>(mGeckoChild->GetLayerManager());
        manager->AsShadowForwarder()->WindowOverlayChanged();
      }
    }

    mGeckoChild->WillPaintWindow();
  }
  [super viewWillDraw];
}

#if USE_CLICK_HOLD_CONTEXTMENU
//
// -clickHoldCallback:
//
// called from a timer two seconds after a mouse down to see if we should display
// a context menu (click-hold). |anEvent| is the original mouseDown event. If we're
// still in that mouseDown by this time, put up the context menu, otherwise just
// fuhgeddaboutit. |anEvent| has been retained by the OS until after this callback
// fires so we're ok there.
//
// This code currently messes in a bunch of edge cases (bugs 234751, 232964, 232314)
// so removing it until we get it straightened out.
//
- (void)clickHoldCallback:(id)theEvent;
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if( theEvent == [NSApp currentEvent] ) {
    // we're still in the middle of the same mousedown event here, activate
    // click-hold context menu by triggering the right mouseDown action.
    NSEvent* clickHoldEvent = [NSEvent mouseEventWithType:NSRightMouseDown
                                                  location:[theEvent locationInWindow]
#ifdef NS_LEOPARD_AND_LATER
                                             modifierFlags:[theEvent modifierFlags]
#else
modifierFlags:nsCocoaUtils::GetCocoaEventModifierFlags(theEvent)
#endif
                                                 timestamp:[theEvent timestamp]
                                              windowNumber:[theEvent windowNumber]
                                                   context:[theEvent context]
                                               eventNumber:[theEvent eventNumber]
                                                clickCount:[theEvent clickCount]
                                                  pressure:[theEvent pressure]];
    [self rightMouseDown:clickHoldEvent];
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}
#endif

// If we've just created a non-native context menu, we need to mark it as
// such and let the OS (and other programs) know when it opens and closes
// (this is how the OS knows to close other programs' context menus when
// ours open).  We send the initial notification here, but others are sent
// in nsCocoaWindow::Show().
- (void)maybeInitContextMenuTracking
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

#ifdef MOZ_USE_NATIVE_POPUP_WINDOWS
  return;
#endif /* MOZ_USE_NATIVE_POPUP_WINDOWS */

  nsIRollupListener* rollupListener = nsBaseWidget::GetActiveRollupListener();
  NS_ENSURE_TRUE_VOID(rollupListener);
  nsCOMPtr<nsIWidget> widget = rollupListener->GetRollupWidget();
  NS_ENSURE_TRUE_VOID(widget);

  NSWindow *popupWindow = (NSWindow*)widget->GetNativeData(NS_NATIVE_WINDOW);
  if (!popupWindow || ![popupWindow isKindOfClass:[PopupWindow class]])
    return;

  [[NSDistributedNotificationCenter defaultCenter]
    postNotificationName:@"com.apple.HIToolbox.beginMenuTrackingNotification"
                  object:@"org.mozilla.gecko.PopupWindow"];
  [(PopupWindow*)popupWindow setIsContextMenu:YES];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

// Returns true if the event should no longer be processed, false otherwise.
// This does not return whether or not anything was rolled up.
- (BOOL)maybeRollup:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  BOOL consumeEvent = NO;

  nsIRollupListener* rollupListener = nsBaseWidget::GetActiveRollupListener();
  NS_ENSURE_TRUE(rollupListener, false);
  nsCOMPtr<nsIWidget> rollupWidget = rollupListener->GetRollupWidget();
  if (rollupWidget) {
    NSWindow* currentPopup = static_cast<NSWindow*>(rollupWidget->GetNativeData(NS_NATIVE_WINDOW));
    if (!nsCocoaUtils::IsEventOverWindow(theEvent, currentPopup)) {
      // event is not over the rollup window, default is to roll up
      bool shouldRollup = true;

      // check to see if scroll events should roll up the popup
      if ([theEvent type] == NSScrollWheel) {
        shouldRollup = rollupListener->ShouldRollupOnMouseWheelEvent();
        // consume scroll events that aren't over the popup
        // unless the popup is an arrow panel
        consumeEvent = rollupListener->ShouldConsumeOnMouseWheelEvent();
      }

      // if we're dealing with menus, we probably have submenus and
      // we don't want to rollup if the click is in a parent menu of
      // the current submenu
      uint32_t popupsToRollup = UINT32_MAX;
      nsAutoTArray<nsIWidget*, 5> widgetChain;
      uint32_t sameTypeCount = rollupListener->GetSubmenuWidgetChain(&widgetChain);
      for (uint32_t i = 0; i < widgetChain.Length(); i++) {
        nsIWidget* widget = widgetChain[i];
        NSWindow* currWindow = (NSWindow*)widget->GetNativeData(NS_NATIVE_WINDOW);
        if (nsCocoaUtils::IsEventOverWindow(theEvent, currWindow)) {
          // don't roll up if the mouse event occurred within a menu of the
          // same type. If the mouse event occurred in a menu higher than
          // that, roll up, but pass the number of popups to Rollup so
          // that only those of the same type close up.
          if (i < sameTypeCount) {
            shouldRollup = false;
          }
          else {
            popupsToRollup = sameTypeCount;
          }
          break;
        }
      }

      if (shouldRollup) {
        if ([theEvent type] == NSLeftMouseDown) {
          NSPoint point = [NSEvent mouseLocation];
          FlipCocoaScreenCoordinate(point);
          nsIntPoint pos(point.x, point.y);
          consumeEvent = (BOOL)rollupListener->Rollup(popupsToRollup, true, &pos, nullptr);
        }
        else {
          consumeEvent = (BOOL)rollupListener->Rollup(popupsToRollup, true, nullptr, nullptr);
        }
      }
    }
  }

  return consumeEvent;

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(NO);
}

/*
 * In OS X Mountain Lion and above, smart zoom gestures are implemented in
 * smartMagnifyWithEvent. In OS X Lion, they are implemented in
 * magnifyWithEvent. See inline comments for more info.
 *
 * The prototypes swipeWithEvent, beginGestureWithEvent, magnifyWithEvent,
 * smartMagnifyWithEvent, rotateWithEvent, and endGestureWithEvent were
 * obtained from the following links:
 * https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/ApplicationKit/Classes/NSResponder_Class/Reference/Reference.html
 * https://developer.apple.com/library/mac/#releasenotes/Cocoa/AppKit.html
 */

- (void)swipeWithEvent:(NSEvent *)anEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!anEvent || !mGeckoChild)
    return;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  float deltaX = [anEvent deltaX];  // left=1.0, right=-1.0
  float deltaY = [anEvent deltaY];  // up=1.0, down=-1.0

  // Setup the "swipe" event.
  WidgetSimpleGestureEvent geckoEvent(true, eSwipeGesture, mGeckoChild);
  [self convertCocoaMouseEvent:anEvent toGeckoEvent:&geckoEvent];

  // Record the left/right direction.
  if (deltaX > 0.0)
    geckoEvent.direction |= nsIDOMSimpleGestureEvent::DIRECTION_LEFT;
  else if (deltaX < 0.0)
    geckoEvent.direction |= nsIDOMSimpleGestureEvent::DIRECTION_RIGHT;

  // Record the up/down direction.
  if (deltaY > 0.0)
    geckoEvent.direction |= nsIDOMSimpleGestureEvent::DIRECTION_UP;
  else if (deltaY < 0.0)
    geckoEvent.direction |= nsIDOMSimpleGestureEvent::DIRECTION_DOWN;

  // Send the event.
  mGeckoChild->DispatchWindowEvent(geckoEvent);

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)beginGestureWithEvent:(NSEvent *)anEvent
{
  if (!anEvent)
    return;

  mGestureState = eGestureState_StartGesture;
  mCumulativeMagnification = 0;
  mCumulativeRotation = 0.0;
}

- (void)magnifyWithEvent:(NSEvent *)anEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!anEvent || !mGeckoChild)
    return;

  /*
   * In OS X 10.7.* (Lion), smart zoom events come through magnifyWithEvent,
   * instead of smartMagnifyWithEvent. See bug 863841.
   */
  if ([ChildView isLionSmartMagnifyEvent: anEvent]) {
    [self smartMagnifyWithEvent: anEvent];
    return;
  }

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  float deltaZ = [anEvent deltaZ];

  EventMessage msg;
  switch (mGestureState) {
  case eGestureState_StartGesture:
    msg = eMagnifyGestureStart;
    mGestureState = eGestureState_MagnifyGesture;
    break;

  case eGestureState_MagnifyGesture:
    msg = eMagnifyGestureUpdate;
    break;

  case eGestureState_None:
  case eGestureState_RotateGesture:
  default:
    return;
  }

  // Setup the event.
  WidgetSimpleGestureEvent geckoEvent(true, msg, mGeckoChild);
  geckoEvent.delta = deltaZ;
  [self convertCocoaMouseEvent:anEvent toGeckoEvent:&geckoEvent];

  // Send the event.
  mGeckoChild->DispatchWindowEvent(geckoEvent);

  // Keep track of the cumulative magnification for the final "magnify" event.
  mCumulativeMagnification += deltaZ;

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)smartMagnifyWithEvent:(NSEvent *)anEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!anEvent || !mGeckoChild) {
    return;
  }

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  // Setup the "double tap" event.
  WidgetSimpleGestureEvent geckoEvent(true, eTapGesture, mGeckoChild);
  [self convertCocoaMouseEvent:anEvent toGeckoEvent:&geckoEvent];
  geckoEvent.clickCount = 1;

  // Send the event.
  mGeckoChild->DispatchWindowEvent(geckoEvent);

  // Clear the gesture state
  mGestureState = eGestureState_None;

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)rotateWithEvent:(NSEvent *)anEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!anEvent || !mGeckoChild)
    return;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  float rotation = [anEvent rotation];

  EventMessage msg;
  switch (mGestureState) {
  case eGestureState_StartGesture:
    msg = eRotateGestureStart;
    mGestureState = eGestureState_RotateGesture;
    break;

  case eGestureState_RotateGesture:
    msg = eRotateGestureUpdate;
    break;

  case eGestureState_None:
  case eGestureState_MagnifyGesture:
  default:
    return;
  }

  // Setup the event.
  WidgetSimpleGestureEvent geckoEvent(true, msg, mGeckoChild);
  [self convertCocoaMouseEvent:anEvent toGeckoEvent:&geckoEvent];
  geckoEvent.delta = -rotation;
  if (rotation > 0.0) {
    geckoEvent.direction = nsIDOMSimpleGestureEvent::ROTATION_COUNTERCLOCKWISE;
  } else {
    geckoEvent.direction = nsIDOMSimpleGestureEvent::ROTATION_CLOCKWISE;
  }

  // Send the event.
  mGeckoChild->DispatchWindowEvent(geckoEvent);

  // Keep track of the cumulative rotation for the final "rotate" event.
  mCumulativeRotation += rotation;

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)endGestureWithEvent:(NSEvent *)anEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!anEvent || !mGeckoChild) {
    // Clear the gestures state if we cannot send an event.
    mGestureState = eGestureState_None;
    mCumulativeMagnification = 0.0;
    mCumulativeRotation = 0.0;
    return;
  }

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  switch (mGestureState) {
  case eGestureState_MagnifyGesture:
    {
      // Setup the "magnify" event.
      WidgetSimpleGestureEvent geckoEvent(true, eMagnifyGesture, mGeckoChild);
      geckoEvent.delta = mCumulativeMagnification;
      [self convertCocoaMouseEvent:anEvent toGeckoEvent:&geckoEvent];

      // Send the event.
      mGeckoChild->DispatchWindowEvent(geckoEvent);
    }
    break;

  case eGestureState_RotateGesture:
    {
      // Setup the "rotate" event.
      WidgetSimpleGestureEvent geckoEvent(true, eRotateGesture, mGeckoChild);
      [self convertCocoaMouseEvent:anEvent toGeckoEvent:&geckoEvent];
      geckoEvent.delta = -mCumulativeRotation;
      if (mCumulativeRotation > 0.0) {
        geckoEvent.direction = nsIDOMSimpleGestureEvent::ROTATION_COUNTERCLOCKWISE;
      } else {
        geckoEvent.direction = nsIDOMSimpleGestureEvent::ROTATION_CLOCKWISE;
      }

      // Send the event.
      mGeckoChild->DispatchWindowEvent(geckoEvent);
    }
    break;

  case eGestureState_None:
  case eGestureState_StartGesture:
  default:
    break;
  }

  // Clear the gestures state.
  mGestureState = eGestureState_None;
  mCumulativeMagnification = 0.0;
  mCumulativeRotation = 0.0;

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

+ (BOOL)isLionSmartMagnifyEvent:(NSEvent*)anEvent
{
#ifndef __LP64__
  // Lion SUCKS!
  return NO;
#else
  /*
   * On Lion, smart zoom events have type NSEventTypeGesture, subtype 0x16,
   * whereas pinch zoom events have type NSEventTypeMagnify. So, use that to
   * discriminate between the two. Smart zoom gestures do not call
   * beginGestureWithEvent or endGestureWithEvent, so mGestureState is not
   * changed. Documentation couldn't be found for the meaning of the subtype
   * 0x16, but it will probably never change. See bug 863841.
   */
  return nsCocoaFeatures::OnLionOrLater() &&
         !nsCocoaFeatures::OnMountainLionOrLater() &&
         [anEvent type] == NSEventTypeGesture &&
         [anEvent subtype] == 0x16;
#endif
}

- (bool)shouldConsiderStartingSwipeFromEvent:(NSEvent*)anEvent
{
return false; // never on 10.6 or earlier
#if(0)
  if (!nsCocoaFeatures::OnLionOrLater()) {
    return false;
  }

  // This method checks whether the AppleEnableSwipeNavigateWithScrolls global
  // preference is set.  If it isn't, fluid swipe tracking is disabled, and a
  // horizontal two-finger gesture is always a scroll (even in Safari).  This
  // preference can't (currently) be set from the Preferences UI -- only using
  // 'defaults write'.
  if (![NSEvent isSwipeTrackingFromScrollEventsEnabled]) {
    return false;
  }

  // Only initiate horizontal tracking for gestures that have just begun --
  // otherwise a scroll to one side of the page can have a swipe tacked on
  // to it.
  NSEventPhase eventPhase = nsCocoaUtils::EventPhase(anEvent);
  if ([anEvent type] != NSScrollWheel ||
      eventPhase != NSEventPhaseBegan ||
      ![anEvent hasPreciseScrollingDeltas]) {
    return false;
  }

  // Only initiate horizontal tracking for events whose horizontal element is
  // at least eight times larger than its vertical element. This minimizes
  // performance problems with vertical scrolls (by minimizing the possibility
  // that they'll be misinterpreted as horizontal swipes), while still
  // tolerating a small vertical element to a true horizontal swipe.  The number
  // '8' was arrived at by trial and error.
  CGFloat deltaX = [anEvent scrollingDeltaX];
  CGFloat deltaY = [anEvent scrollingDeltaY];
  return std::abs(deltaX) > std::abs(deltaY) * 8;
#endif
}

- (void)setUsingOMTCompositor:(BOOL)aUseOMTC
{
  mUsingOMTCompositor = aUseOMTC;
}

// Returning NO from this method only disallows ordering on mousedown - in order
// to prevent it for mouseup too, we need to call [NSApp preventWindowOrdering]
// when handling the mousedown event.
- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent*)aEvent
{
  // Always using system-provided window ordering for normal windows.
  if (![[self window] isKindOfClass:[PopupWindow class]])
    return NO;

  // Don't reorder when we don't have a parent window, like when we're a
  // context menu or a tooltip.
  return ![[self window] parentWindow];
}

- (void)mouseDown:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if ([self shouldDelayWindowOrderingForEvent:theEvent]) {
    [NSApp preventWindowOrdering];
  }

  // If we've already seen this event due to direct dispatch from menuForEvent:
  // just bail; if not, remember it.
  if (mLastMouseDownEvent == theEvent) {
    [mLastMouseDownEvent release];
    mLastMouseDownEvent = nil;
    return;
  }
  else {
    [mLastMouseDownEvent release];
    mLastMouseDownEvent = [theEvent retain];
  }

  [gLastDragMouseDownEvent release];
  gLastDragMouseDownEvent = [theEvent retain];

  // We need isClickThrough because at this point the window we're in might
  // already have become main, so the check for isMainWindow in
  // WindowAcceptsEvent isn't enough. It also has to check isClickThrough.
  BOOL isClickThrough = (theEvent == mClickThroughMouseDownEvent);
  [mClickThroughMouseDownEvent release];
  mClickThroughMouseDownEvent = nil;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  if ([self maybeRollup:theEvent] ||
      !ChildViewMouseTracker::WindowAcceptsEvent([self window], theEvent, self, isClickThrough)) {
    // Remember blocking because that means we want to block mouseup as well.
    mBlockedLastMouseDown = YES;
    return;
  }

#if USE_CLICK_HOLD_CONTEXTMENU
  // fire off timer to check for click-hold after two seconds. retains |theEvent|
  [self performSelector:@selector(clickHoldCallback:) withObject:theEvent afterDelay:2.0];
#endif

  // in order to send gecko events we'll need a gecko widget
  if (!mGeckoChild)
    return;

#if(0)
  NSUInteger modifierFlags = [theEvent modifierFlags];
#else
NSUInteger modifierFlags = nsCocoaUtils::GetCocoaEventModifierFlags(theEvent);
#endif

  WidgetMouseEvent geckoEvent(true, eMouseDown, mGeckoChild,
                              WidgetMouseEvent::eReal);
  [self convertCocoaMouseEvent:theEvent toGeckoEvent:&geckoEvent];

  NSInteger clickCount = [theEvent clickCount];
  if (mBlockedLastMouseDown && clickCount > 1) {
    // Don't send a double click if the first click of the double click was
    // blocked.
    clickCount--;
  }
  geckoEvent.clickCount = clickCount;

  if (modifierFlags & NSControlKeyMask)
    geckoEvent.button = WidgetMouseEvent::eRightButton;
  else
    geckoEvent.button = WidgetMouseEvent::eLeftButton;

  mGeckoChild->DispatchAPZAwareEvent(&geckoEvent);
  mBlockedLastMouseDown = NO;

  // XXX maybe call markedTextSelectionChanged:client: here?

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)mouseUp:(NSEvent *)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!mGeckoChild || mBlockedLastMouseDown)
    return;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  WidgetMouseEvent geckoEvent(true, eMouseUp, mGeckoChild,
                              WidgetMouseEvent::eReal);
  [self convertCocoaMouseEvent:theEvent toGeckoEvent:&geckoEvent];
  if (nsCocoaUtils::GetCocoaEventModifierFlags(theEvent) & NSControlKeyMask)
    geckoEvent.button = WidgetMouseEvent::eRightButton;
  else
    geckoEvent.button = WidgetMouseEvent::eLeftButton;

  // This might destroy our widget (and null out mGeckoChild).
  bool defaultPrevented =
    (mGeckoChild->DispatchAPZAwareEvent(&geckoEvent) == nsEventStatus_eConsumeNoDefault);

  // Check to see if we are double-clicking in the titlebar.
  CGFloat locationInTitlebar = [[self window] frame].size.height - [theEvent locationInWindow].y;
  LayoutDeviceIntPoint pos = geckoEvent.refPoint;
  if (!defaultPrevented && [theEvent clickCount] == 2 &&
      mGeckoChild->GetDraggableRegion().Contains(pos.x, pos.y) &&
      [[self window] isKindOfClass:[ToolbarWindow class]] &&
      (locationInTitlebar < [(ToolbarWindow*)[self window] titlebarHeight] ||
       locationInTitlebar < [(ToolbarWindow*)[self window] unifiedToolbarHeight])) {
    if ([self shouldZoomOnDoubleClick]) {
      [[self window] performZoom:nil];
    } else if ([self shouldMinimizeOnTitlebarDoubleClick]) {
      NSButton *minimizeButton = [[self window] standardWindowButton:NSWindowMiniaturizeButton];
      [minimizeButton performClick:self];
    }
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)sendMouseEnterOrExitEvent:(NSEvent*)aEvent
                            enter:(BOOL)aEnter
                             type:(WidgetMouseEvent::exitType)aType
{
  if (!mGeckoChild)
    return;

  NSPoint windowEventLocation = nsCocoaUtils::EventLocationForWindow(aEvent, [self window]);
  NSPoint localEventLocation = [self convertPoint:windowEventLocation fromView:nil];

  EventMessage msg = aEnter ? eMouseEnterIntoWidget : eMouseExitFromWidget;
  WidgetMouseEvent event(true, msg, mGeckoChild, WidgetMouseEvent::eReal);
  event.refPoint = mGeckoChild->CocoaPointsToDevPixels(localEventLocation);

  event.exit = aType;

  nsEventStatus status; // ignored
  mGeckoChild->DispatchEvent(&event, status);
}

- (void)updateWindowDraggableState
{
  // Trigger update to the window server.
  [[self window] setMovableByWindowBackground:NO];
  [[self window] setMovableByWindowBackground:YES];
}

// aRect is in view coordinates relative to this NSView.
- (CGRect)convertToFlippedWindowCoordinates:(NSRect)aRect
{
  // First, convert the rect to regular window coordinates...
  NSRect inWindowCoords = [self convertRect:aRect toView:nil];
  // ... and then flip it again because window coordinates have their origin
  // in the bottom left corner, and we need it to be in the top left corner.
  inWindowCoords.origin.y = [[self window] frame].size.height - NSMaxY(inWindowCoords);
  //return NSRectToCGRect(inWindowCoords);
  return *(CGRect*)&inWindowCoords;
}

#if(0)
static CGSRegionObj
NewCGSRegionFromRegion(const LayoutDeviceIntRegion& aRegion,
                       CGRect (^aRectConverter)(const LayoutDeviceIntRect&))
{
  nsTArray<CGRect> rects;
  LayoutDeviceIntRegion::RectIterator iter(aRegion);
  for (;;) {
    const LayoutDeviceIntRect* r = iter.Next();
    if (!r) {
      break;
    }
    rects.AppendElement(aRectConverter(*r));
  }

  CGSRegionObj region;
  CGSNewRegionWithRectList(rects.Elements(), rects.Length(), &region);
  return region;
}

// This function is called with forMove:YES to calculate the draggable region
// of the window which will be submitted to the window server. Window dragging
// is handled on the window server without calling back into our process, so it
// also works while our app is unresponsive.
- (CGSRegionObj)_regionForOpaqueDescendants:(NSRect)aRect forMove:(BOOL)aForMove
{
  if (!aForMove || !mGeckoChild) {
    return [super _regionForOpaqueDescendants:aRect forMove:aForMove];
  }

  LayoutDeviceIntRect boundingRect = mGeckoChild->CocoaPointsToDevPixels(aRect);

  LayoutDeviceIntRegion opaqueRegion;
  opaqueRegion.Sub(boundingRect, mGeckoChild->GetDraggableRegion());

  return NewCGSRegionFromRegion(opaqueRegion, ^(const LayoutDeviceIntRect& r) {
    return [self convertToFlippedWindowCoordinates:mGeckoChild->DevPixelsToCocoaPoints(r)];
  });
}
#else
// 10.4 (non-block) version.
- (CGSRegionObj)_regionForOpaqueDescendants:(NSRect)aRect forMove:(BOOL)aForMove
{
  if (!aForMove || !mGeckoChild) {
    return [super _regionForOpaqueDescendants:aRect forMove:aForMove];
  }

  LayoutDeviceIntRect boundingRect = mGeckoChild->CocoaPointsToDevPixels(aRect);

  LayoutDeviceIntRegion opaqueRegion;
  opaqueRegion.Sub(boundingRect, mGeckoChild->GetDraggableRegion());

  nsTArray<CGRect> rects;
  LayoutDeviceIntRegion::RectIterator iter(opaqueRegion);
  for (;;) {
    const LayoutDeviceIntRect* r = iter.Next();
    if (!r)
      break;
    // We can cheat here if needed, because the backing scale is always 1.
    NSRect n = mGeckoChild->DevPixelsToCocoaPoints(*r);
    rects.AppendElement([self convertToFlippedWindowCoordinates:n]);
  }
  
  CGSRegionObj region;
  CGSNewRegionWithRectList(rects.Elements(), rects.Length(), &region);
  return region;
}
#endif

// Starting with 10.10, in addition to the traditional
// -[NSView _regionForOpaqueDescendants:forMove:] method, there's a new form with
// an additional forUnderTitlebar argument, which is sometimes called instead of
// the old form. We need to override the new variant as well.
- (CGSRegionObj)_regionForOpaqueDescendants:(NSRect)aRect
                                    forMove:(BOOL)aForMove
                           forUnderTitlebar:(BOOL)aForUnderTitlebar
{
  if (!aForMove || !mGeckoChild) {
    return [super _regionForOpaqueDescendants:aRect
                                      forMove:aForMove
                             forUnderTitlebar:aForUnderTitlebar];
  }

  return [self _regionForOpaqueDescendants:aRect forMove:aForMove];
}

- (void)mouseMoved:(NSEvent*)aEvent
{
  ChildViewMouseTracker::MouseMoved(aEvent);
}

- (void)handleMouseMoved:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!mGeckoChild)
    return;

  WidgetMouseEvent geckoEvent(true, eMouseMove, mGeckoChild,
                              WidgetMouseEvent::eReal);
  [self convertCocoaMouseEvent:theEvent toGeckoEvent:&geckoEvent];

  mGeckoChild->DispatchAPZAwareEvent(&geckoEvent);

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)mouseDragged:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!mGeckoChild)
    return;

  gLastDragView = self;

  WidgetMouseEvent geckoEvent(true, eMouseMove, mGeckoChild,
                              WidgetMouseEvent::eReal);
  [self convertCocoaMouseEvent:theEvent toGeckoEvent:&geckoEvent];

  mGeckoChild->DispatchInputEvent(&geckoEvent);

  // Note, sending the above event might have destroyed our widget since we didn't retain.
  // Fine so long as we don't access any local variables from here on.
  gLastDragView = nil;

  // XXX maybe call markedTextSelectionChanged:client: here?

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  [self maybeRollup:theEvent];
  if (!mGeckoChild)
    return;

  // The right mouse went down, fire off a right mouse down event to gecko
  WidgetMouseEvent geckoEvent(true, eMouseDown, mGeckoChild,
                              WidgetMouseEvent::eReal);
  [self convertCocoaMouseEvent:theEvent toGeckoEvent:&geckoEvent];
  geckoEvent.button = WidgetMouseEvent::eRightButton;
  geckoEvent.clickCount = [theEvent clickCount];

  mGeckoChild->DispatchAPZAwareEvent(&geckoEvent);
  if (!mGeckoChild)
    return;

  // Let the superclass do the context menu stuff.
  [super rightMouseDown:theEvent];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!mGeckoChild)
    return;

  WidgetMouseEvent geckoEvent(true, eMouseUp, mGeckoChild,
                              WidgetMouseEvent::eReal);
  [self convertCocoaMouseEvent:theEvent toGeckoEvent:&geckoEvent];
  geckoEvent.button = WidgetMouseEvent::eRightButton;
  geckoEvent.clickCount = [theEvent clickCount];

  nsAutoRetainCocoaObject kungFuDeathGrip(self);
  mGeckoChild->DispatchAPZAwareEvent(&geckoEvent);

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)rightMouseDragged:(NSEvent*)theEvent
{
  if (!mGeckoChild)
    return;

  WidgetMouseEvent geckoEvent(true, eMouseMove, mGeckoChild,
                              WidgetMouseEvent::eReal);
  [self convertCocoaMouseEvent:theEvent toGeckoEvent:&geckoEvent];
  geckoEvent.button = WidgetMouseEvent::eRightButton;

  // send event into Gecko by going directly to the
  // the widget.
  mGeckoChild->DispatchInputEvent(&geckoEvent);
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  if ([self maybeRollup:theEvent] ||
      !ChildViewMouseTracker::WindowAcceptsEvent([self window], theEvent, self))
    return;

  if (!mGeckoChild)
    return;

  WidgetMouseEvent geckoEvent(true, eMouseDown, mGeckoChild,
                              WidgetMouseEvent::eReal);
  [self convertCocoaMouseEvent:theEvent toGeckoEvent:&geckoEvent];
  geckoEvent.button = WidgetMouseEvent::eMiddleButton;
  geckoEvent.clickCount = [theEvent clickCount];

  mGeckoChild->DispatchInputEvent(&geckoEvent);

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
  if (!mGeckoChild)
    return;

  WidgetMouseEvent geckoEvent(true, eMouseUp, mGeckoChild,
                              WidgetMouseEvent::eReal);
  [self convertCocoaMouseEvent:theEvent toGeckoEvent:&geckoEvent];
  geckoEvent.button = WidgetMouseEvent::eMiddleButton;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);
  mGeckoChild->DispatchInputEvent(&geckoEvent);
}

- (void)otherMouseDragged:(NSEvent*)theEvent
{
  if (!mGeckoChild)
    return;

  WidgetMouseEvent geckoEvent(true, eMouseMove, mGeckoChild,
                              WidgetMouseEvent::eReal);
  [self convertCocoaMouseEvent:theEvent toGeckoEvent:&geckoEvent];
  geckoEvent.button = WidgetMouseEvent::eMiddleButton;

  // send event into Gecko by going directly to the
  // the widget.
  mGeckoChild->DispatchInputEvent(&geckoEvent);
}

static int32_t RoundUp(double aDouble)
{
  return aDouble < 0 ? static_cast<int32_t>(floor(aDouble)) :
                       static_cast<int32_t>(ceil(aDouble));
}

- (void)sendWheelStartOrStop:(EventMessage)msg forEvent:(NSEvent *)theEvent
{
  WidgetWheelEvent wheelEvent(true, msg, mGeckoChild);
  [self convertCocoaMouseWheelEvent:theEvent toGeckoEvent:&wheelEvent];
  mExpectingWheelStop = (msg == eWheelOperationStart);
  mGeckoChild->DispatchAPZAwareEvent(wheelEvent.AsInputEvent());
}

- (void)sendWheelCondition:(BOOL)condition
                     first:(EventMessage)first
                    second:(EventMessage)second
                  forEvent:(NSEvent *)theEvent
{
  if (mExpectingWheelStop == condition) {
    [self sendWheelStartOrStop:first forEvent:theEvent];
  }
  [self sendWheelStartOrStop:second forEvent:theEvent];
}

static PanGestureInput::PanGestureType
PanGestureTypeForEvent(NSEvent* aEvent)
{
  switch (nsCocoaUtils::EventPhase(aEvent)) {
    case NSEventPhaseMayBegin:
      return PanGestureInput::PANGESTURE_MAYSTART;
    case NSEventPhaseCancelled:
      return PanGestureInput::PANGESTURE_CANCELLED;
    case NSEventPhaseBegan:
      return PanGestureInput::PANGESTURE_START;
    case NSEventPhaseChanged:
      return PanGestureInput::PANGESTURE_PAN;
    case NSEventPhaseEnded:
      return PanGestureInput::PANGESTURE_END;
    case NSEventPhaseNone:
      switch (nsCocoaUtils::EventMomentumPhase(aEvent)) {
        case NSEventPhaseBegan:
          return PanGestureInput::PANGESTURE_MOMENTUMSTART;
        case NSEventPhaseChanged:
          return PanGestureInput::PANGESTURE_MOMENTUMPAN;
        case NSEventPhaseEnded:
          return PanGestureInput::PANGESTURE_MOMENTUMEND;
        default:
          NS_ERROR("unexpected event phase");
          return PanGestureInput::PANGESTURE_PAN;
      }
    default:
      NS_ERROR("unexpected event phase");
      return PanGestureInput::PANGESTURE_PAN;
  }
}

- (void)scrollWheel:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (gfxPrefs::AsyncPanZoomSeparateEventThread() && [self apzctm]) {
    // Disable main-thread scrolling completely when using APZ with the
    // separate event thread. This is bug 1013412.
    return;
  }

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  ChildViewMouseTracker::MouseScrolled(theEvent);

  if ([self maybeRollup:theEvent]) {
    return;
  }

  if (!mGeckoChild) {
    return;
  }

  NSEventPhase phase = nsCocoaUtils::EventPhase(theEvent);
  // Fire eWheelOperationStart/End events when 2 fingers touch/release the
  // touchpad.
  if (phase & NSEventPhaseMayBegin) {
    [self sendWheelCondition:YES
                       first:eWheelOperationEnd
                      second:eWheelOperationStart
                    forEvent:theEvent];
  } else if (phase & (NSEventPhaseEnded | NSEventPhaseCancelled)) {
    [self sendWheelCondition:NO
                       first:eWheelOperationStart
                      second:eWheelOperationEnd
                    forEvent:theEvent];
  }

  NSPoint locationInWindow = nsCocoaUtils::EventLocationForWindow(theEvent, [self window]);

  ScreenPoint position = ViewAs<ScreenPixel>(
    [self convertWindowCoordinates:locationInWindow],
    PixelCastJustification::LayoutDeviceIsScreenForUntransformedEvent);

  bool usePreciseDeltas = nsCocoaUtils::HasPreciseScrollingDeltas(theEvent) &&
    Preferences::GetBool("mousewheel.enable_pixel_scrolling", true);
  bool hasPhaseInformation = nsCocoaUtils::EventHasPhaseInformation(theEvent);

  int32_t lineOrPageDeltaX = RoundUp(-[theEvent deltaX]);
  int32_t lineOrPageDeltaY = RoundUp(-[theEvent deltaY]);

  Modifiers modifiers = nsCocoaUtils::ModifiersForEvent(theEvent);

#if(0)
  NSTimeInterval beforeNow = [[NSProcessInfo processInfo] systemUptime] - [theEvent timestamp];
#else
  // NSProcessInfo in 10.4 doesn't have systemUptime, so we have to gyrate a bit in Carbon.
  Nanoseconds nano = AbsoluteToNanoseconds(UpTime());
  NSTimeInterval systemUptime = nano.hi * 4.294967296 + nano.lo * 1e-9;
  NSTimeInterval beforeNow = systemUptime - [theEvent timestamp];
#endif
  PRIntervalTime eventIntervalTime = PR_IntervalNow() - PR_MillisecondsToInterval(beforeNow * 1000);
  TimeStamp eventTimeStamp = TimeStamp::Now() - TimeDuration::FromSeconds(beforeNow);

  ScreenPoint preciseDelta;
  if (usePreciseDeltas) {
    CGFloat pixelDeltaX = 0, pixelDeltaY = 0;
    nsCocoaUtils::GetScrollingDeltas(theEvent, &pixelDeltaX, &pixelDeltaY);
    //double scale = mGeckoChild->BackingScaleFactor();
    //preciseDelta = ScreenPoint(-pixelDeltaX * scale, -pixelDeltaY * scale);
    preciseDelta = ScreenPoint(-pixelDeltaX, -pixelDeltaY);
  }

#if(0)
  if (usePreciseDeltas && hasPhaseInformation) {
    PanGestureInput panEvent(PanGestureTypeForEvent(theEvent),
                             eventIntervalTime, eventTimeStamp,
                             position, preciseDelta, modifiers);
    panEvent.mLineOrPageDeltaX = lineOrPageDeltaX;
    panEvent.mLineOrPageDeltaY = lineOrPageDeltaY;

    bool canTriggerSwipe = [self shouldConsiderStartingSwipeFromEvent:theEvent];
    panEvent.mRequiresContentResponseIfCannotScrollHorizontallyInStartDirection = canTriggerSwipe;
    mGeckoChild->DispatchAPZWheelInputEvent(panEvent, canTriggerSwipe);
  } else if (usePreciseDeltas) {
#else
  if (usePreciseDeltas) {
#endif
    // This is on 10.6 or old touchpads that don't have any phase information.
    ScrollWheelInput wheelEvent(eventIntervalTime, eventTimeStamp, modifiers,
                                ScrollWheelInput::SCROLLMODE_INSTANT,
                                ScrollWheelInput::SCROLLDELTA_PIXEL,
                                position,
                                preciseDelta.x,
                                preciseDelta.y);
    wheelEvent.mLineOrPageDeltaX = lineOrPageDeltaX;
    wheelEvent.mLineOrPageDeltaY = lineOrPageDeltaY;
    wheelEvent.mIsMomentum = nsCocoaUtils::IsMomentumScrollEvent(theEvent);
    mGeckoChild->DispatchAPZWheelInputEvent(wheelEvent, false);
  } else {
    ScrollWheelInput::ScrollMode scrollMode = ScrollWheelInput::SCROLLMODE_INSTANT;
    if (gfxPrefs::SmoothScrollEnabled() && gfxPrefs::WheelSmoothScrollEnabled()) {
      scrollMode = ScrollWheelInput::SCROLLMODE_SMOOTH;
    }
    ScrollWheelInput wheelEvent(eventIntervalTime, eventTimeStamp, modifiers,
                                scrollMode,
                                ScrollWheelInput::SCROLLDELTA_LINE,
                                position,
                                lineOrPageDeltaX,
                                lineOrPageDeltaY);
    wheelEvent.mLineOrPageDeltaX = lineOrPageDeltaX;
    wheelEvent.mLineOrPageDeltaY = lineOrPageDeltaY;
    mGeckoChild->DispatchAPZWheelInputEvent(wheelEvent, false);
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)handleAsyncScrollEvent:(CGEventRef)cgEvent ofType:(CGEventType)type
{
#if(1)
  // Unfortunately there is no way to support APZC yet because there is
  // no documented way to convert a CGEventRef into an NSEvent on 10.4.
#else
  APZCTreeManager* apzctm = [self apzctm];
  if (!apzctm) {
    return;
  }

  CGPoint loc = CGEventGetLocation(cgEvent);
  loc.y = nsCocoaUtils::FlippedScreenY(loc.y);
  NSPoint locationInWindow = [[self window] convertScreenToBase:NSPointFromCGPoint(loc)];
  ScreenIntPoint location = ViewAs<ScreenPixel>(
    [self convertWindowCoordinates:locationInWindow],
    PixelCastJustification::LayoutDeviceIsScreenForUntransformedEvent);

  static NSTimeInterval sStartTime = [NSDate timeIntervalSinceReferenceDate];
  static TimeStamp sStartTimeStamp = TimeStamp::Now();

  if (type == kCGEventScrollWheel) {
    NSEvent* event = [NSEvent eventWithCGEvent:cgEvent];
    NSEventPhase phase = nsCocoaUtils::EventPhase(event);
    NSEventPhase momentumPhase = nsCocoaUtils::EventMomentumPhase(event);
    CGFloat pixelDeltaX = 0, pixelDeltaY = 0;
    nsCocoaUtils::GetScrollingDeltas(event, &pixelDeltaX, &pixelDeltaY);
    uint32_t eventTime = ([event timestamp] - sStartTime) * 1000;
    TimeStamp eventTimeStamp = sStartTimeStamp +
      TimeDuration::FromSeconds([event timestamp] - sStartTime);
    NSPoint locationInWindowMoved = NSMakePoint(
      locationInWindow.x + pixelDeltaX,
      locationInWindow.y - pixelDeltaY);
    ScreenIntPoint locationMoved = ViewAs<ScreenPixel>(
      [self convertWindowCoordinates:locationInWindowMoved],
      PixelCastJustification::LayoutDeviceIsScreenForUntransformedEvent);
    ScreenPoint delta = ScreenPoint(locationMoved - location);
    ScrollableLayerGuid guid;

    // MayBegin and Cancelled are dispatched when the fingers start or stop
    // touching the touchpad before any scrolling has occurred. These events
    // can be used to control scrollbar visibility or interrupt scroll
    // animations. They are only dispatched on 10.8 or later, and only by
    // relatively modern devices.
    if (phase == NSEventPhaseMayBegin) {
      PanGestureInput panInput(PanGestureInput::PANGESTURE_MAYSTART, eventTime,
                               eventTimeStamp, location, ScreenPoint(0, 0), 0);
      apzctm->ReceiveInputEvent(panInput, &guid, nullptr);
      return;
    }
    if (phase == NSEventPhaseCancelled) {
      PanGestureInput panInput(PanGestureInput::PANGESTURE_CANCELLED, eventTime,
                               eventTimeStamp, location, ScreenPoint(0, 0), 0);
      apzctm->ReceiveInputEvent(panInput, &guid, nullptr);
      return;
    }

    // Legacy scroll events are dispatched by devices that do not have a
    // concept of a scroll gesture, for example by USB mice with
    // traditional mouse wheels.
    // For these kinds of scrolls, we want to surround every single scroll
    // event with a PANGESTURE_START and a PANGESTURE_END event. The APZC
    // needs to know that the real scroll gesture can end abruptly after any
    // one of these events.
    bool isLegacyScroll = (phase == NSEventPhaseNone &&
      momentumPhase == NSEventPhaseNone && delta != ScreenPoint(0, 0));

    if (phase == NSEventPhaseBegan || isLegacyScroll) {
      PanGestureInput panInput(PanGestureInput::PANGESTURE_START, eventTime,
                               eventTimeStamp, location, ScreenPoint(0, 0), 0);
      apzctm->ReceiveInputEvent(panInput, &guid, nullptr);
    }
    if (momentumPhase == NSEventPhaseNone && delta != ScreenPoint(0, 0)) {
      PanGestureInput panInput(PanGestureInput::PANGESTURE_PAN, eventTime,
                               eventTimeStamp, location, delta, 0);
      apzctm->ReceiveInputEvent(panInput, &guid, nullptr);
    }
    if (phase == NSEventPhaseEnded || isLegacyScroll) {
      PanGestureInput panInput(PanGestureInput::PANGESTURE_END, eventTime,
                               eventTimeStamp, location, ScreenPoint(0, 0), 0);
      apzctm->ReceiveInputEvent(panInput, &guid, nullptr);
    }

    // Any device that can dispatch momentum events supports all three momentum phases.
    if (momentumPhase == NSEventPhaseBegan) {
      PanGestureInput panInput(PanGestureInput::PANGESTURE_MOMENTUMSTART, eventTime,
                               eventTimeStamp, location, ScreenPoint(0, 0), 0);
      apzctm->ReceiveInputEvent(panInput, &guid, nullptr);
    }
    if (momentumPhase == NSEventPhaseChanged && delta != ScreenPoint(0, 0)) {
      PanGestureInput panInput(PanGestureInput::PANGESTURE_MOMENTUMPAN, eventTime,
                               eventTimeStamp, location, delta, 0);
      apzctm->ReceiveInputEvent(panInput, &guid, nullptr);
    }
    if (momentumPhase == NSEventPhaseEnded) {
      PanGestureInput panInput(PanGestureInput::PANGESTURE_MOMENTUMEND, eventTime,
                               eventTimeStamp, location, ScreenPoint(0, 0), 0);
      apzctm->ReceiveInputEvent(panInput, &guid, nullptr);
    }
  }
#endif
}

-(NSMenu*)menuForEvent:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  if (!mGeckoChild)
    return nil;

#ifdef DEBUG
  fprintf(stderr, "MenuForEvent\n");
#endif

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  [self maybeRollup:theEvent];
  if (!mGeckoChild)
    return nil;

  // Cocoa doesn't always dispatch a mouseDown: for a control-click event,
  // depends on what we return from menuForEvent:. Gecko always expects one
  // and expects the mouse down event before the context menu event, so
  // get that event sent first if this is a left mouse click.
  if ([theEvent type] == NSLeftMouseDown) {
    [self mouseDown:theEvent];
    if (!mGeckoChild)
      return nil;
  }

  WidgetMouseEvent geckoEvent(true, eContextMenu, mGeckoChild,
                              WidgetMouseEvent::eReal);
  [self convertCocoaMouseEvent:theEvent toGeckoEvent:&geckoEvent];
  geckoEvent.button = WidgetMouseEvent::eRightButton;
  mGeckoChild->DispatchInputEvent(&geckoEvent);
  if (!mGeckoChild)
    return nil;

  [self maybeInitContextMenuTracking];

  // Go up our view chain to fetch the correct menu to return.
  return [self contextMenu];

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}

- (NSMenu*)contextMenu
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  NSView* superView = [self superview];
  if ([superView respondsToSelector:@selector(contextMenu)])
    return [(NSView<mozView>*)superView contextMenu];

  return nil;

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}

- (void) convertCocoaMouseWheelEvent:(NSEvent*)aMouseEvent
                        toGeckoEvent:(WidgetWheelEvent*)outWheelEvent
{
  [self convertCocoaMouseEvent:aMouseEvent toGeckoEvent:outWheelEvent];

  bool usePreciseDeltas = nsCocoaUtils::HasPreciseScrollingDeltas(aMouseEvent) &&
    Preferences::GetBool("mousewheel.enable_pixel_scrolling", true);

  outWheelEvent->deltaMode = usePreciseDeltas ? nsIDOMWheelEvent::DOM_DELTA_PIXEL
                                              : nsIDOMWheelEvent::DOM_DELTA_LINE;
  outWheelEvent->isMomentum = nsCocoaUtils::IsMomentumScrollEvent(aMouseEvent);
}

- (void) convertCocoaMouseEvent:(NSEvent*)aMouseEvent
                   toGeckoEvent:(WidgetInputEvent*)outGeckoEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  NS_ASSERTION(outGeckoEvent, "convertCocoaMouseEvent:toGeckoEvent: requires non-null aoutGeckoEvent");
  if (!outGeckoEvent)
    return;

  nsCocoaUtils::InitInputEvent(*outGeckoEvent, aMouseEvent);

  // convert point to view coordinate system
  NSPoint locationInWindow = nsCocoaUtils::EventLocationForWindow(aMouseEvent, [self window]);

  outGeckoEvent->refPoint = [self convertWindowCoordinates:locationInWindow];

  WidgetMouseEventBase* mouseEvent = outGeckoEvent->AsMouseEventBase();
  mouseEvent->buttons = 0;
#if(0) // wtf, but this works.
  NSUInteger mouseButtons = [NSEvent pressedMouseButtons];

  if (mouseButtons & 0x01) {
    mouseEvent->buttons |= WidgetMouseEvent::eLeftButtonFlag;
  }
  if (mouseButtons & 0x02) {
    mouseEvent->buttons |= WidgetMouseEvent::eRightButtonFlag;
  }
  if (mouseButtons & 0x04) {
    mouseEvent->buttons |= WidgetMouseEvent::eMiddleButtonFlag;
  }
  if (mouseButtons & 0x08) {
    mouseEvent->buttons |= WidgetMouseEvent::e4thButtonFlag;
  }
  if (mouseButtons & 0x10) {
    mouseEvent->buttons |= WidgetMouseEvent::e5thButtonFlag;
  }
#endif

  switch ([aMouseEvent type]) {
    case NSLeftMouseDown:
    case NSLeftMouseUp:
    case NSLeftMouseDragged:
    case NSRightMouseDown:
    case NSRightMouseUp:
    case NSRightMouseDragged:
    case NSOtherMouseDown:
    case NSOtherMouseUp:
    case NSOtherMouseDragged:
      if ([aMouseEvent subtype] == NSTabletPointEventSubtype) {
        mouseEvent->pressure = [aMouseEvent pressure];
        MOZ_ASSERT(mouseEvent->pressure >= 0.0 && mouseEvent->pressure <= 1.0);
      }
      break;

    default:
      // Don't check other NSEvents for pressure.
      break;
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

#if(0)
- (BOOL)shouldZoomOnDoubleClick
{
  if ([NSWindow respondsToSelector:@selector(_shouldZoomOnDoubleClick)]) {
    return [NSWindow _shouldZoomOnDoubleClick];
  }
  return nsCocoaFeatures::OnYosemiteOrLater();
}

- (BOOL)shouldMinimizeOnTitlebarDoubleClick
{
  NSString *MDAppleMiniaturizeOnDoubleClickKey =
                                      @"AppleMiniaturizeOnDoubleClick";
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  bool shouldMinimize = [[userDefaults
          objectForKey:MDAppleMiniaturizeOnDoubleClickKey] boolValue];

  return shouldMinimize;
}
#else
- (BOOL)shouldZoomOnDoubleClick
{
  return false;
}

- (BOOL)shouldMinimizeOnTitlebarDoubleClick
{
  // It's not clear that 10.4 has this key (it doesn't seem to).
  // It doesn't have [NSWindow _shouldMiniaturizeOnDoubleClick] either,
  // so to always minimize seems the safest approach.
  if (!nsCocoaFeatures::OnLeopardOrLater()) return true;

  NSString *MDAppleMiniaturizeOnDoubleClickKey =
                                      @"AppleMiniaturizeOnDoubleClick";
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  bool shouldMinimize = [[userDefaults
          objectForKey:MDAppleMiniaturizeOnDoubleClickKey] boolValue];

  return shouldMinimize;
}
#endif

// Backout bug 519972
// This is a big one!
// Damn you, Masayuki and Steven!
// Consolidated for Mozilla 17

static void ConvertCocoaKeyEventToNPCocoaEvent(NSEvent* cocoaEvent, NPCocoaEvent& pluginEvent, uint32_t keyType = 0)
{
  nsCocoaUtils::InitNPCocoaEvent(&pluginEvent);
  NSEventType nativeType = [cocoaEvent type];
  switch (nativeType) {
    case NSKeyDown:
      pluginEvent.type = NPCocoaEventKeyDown;
      break;
    case NSKeyUp:
      pluginEvent.type = NPCocoaEventKeyUp;
      break;
    case NSFlagsChanged:
      pluginEvent.type = NPCocoaEventFlagsChanged;
      break;
    default:
      printf("Asked to convert key event of unknown type to Cocoa plugin event!");
  }
#ifdef NS_LEOPARD_AND_LATER
  pluginEvent.data.key.modifierFlags = [cocoaEvent modifierFlags];
#else
  pluginEvent.data.key.modifierFlags =
    nsCocoaUtils::GetCocoaEventModifierFlags(cocoaEvent);
#endif
  pluginEvent.data.key.keyCode = [cocoaEvent keyCode];
  // don't try to access character data for flags changed events, it will raise an exception
  if (nativeType != NSFlagsChanged) {
    pluginEvent.data.key.characters = (NPNSString*)[cocoaEvent characters];
    pluginEvent.data.key.charactersIgnoringModifiers = (NPNSString*)[cocoaEvent charactersIgnoringModifiers];
    pluginEvent.data.key.isARepeat = [cocoaEvent isARepeat];
  }
}

static bool IsPrintableChar(char16_t aChar)
{
  return (aChar >= 0x20 && aChar <= 0x7E) || aChar >= 0xA0;
}

static uint32_t GetGeckoKeyCodeFromChar(char16_t aChar)
{
  // We don't support the key code for non-ASCII characters
  if (aChar > 0x7E)
    return 0;

  if (aChar >= 'a' && aChar <= 'z') // lowercase
    return uint32_t(toupper(aChar));
  else if (aChar >= 'A' && aChar <= 'Z') // uppercase
    return uint32_t(aChar);
  else if (aChar >= '0' && aChar <= '9')
    return uint32_t(aChar - '0' + NS_VK_0);

  switch (aChar)
  {
    case kReturnCharCode:
    case kEnterCharCode:
    case '\n':
      return NS_VK_RETURN;
    case '{':
    case '[':
      return NS_VK_OPEN_BRACKET;
    case '}':
    case ']':
      return NS_VK_CLOSE_BRACKET;
    case '\'':
    case '"':
      return NS_VK_QUOTE;

    case '\\':                  return NS_VK_BACK_SLASH;
    case ' ':                   return NS_VK_SPACE;
    case ';':                   return NS_VK_SEMICOLON;
    case '=':                   return NS_VK_EQUALS;
    case ',':                   return NS_VK_COMMA;
    case '.':                   return NS_VK_PERIOD;
    case '/':                   return NS_VK_SLASH;
    case '`':                   return NS_VK_BACK_QUOTE;
    case '\t':                  return NS_VK_TAB;
    case '-':                   return NS_VK_SUBTRACT;
    case '+':                   return NS_VK_ADD;

    default:
      if (!IsPrintableChar(aChar))
        NS_WARNING("GetGeckoKeyCodeFromChar has failed.");
      return 0;
    }
}

// XXX: aKeyEvent isn't actually used
static uint32_t ConvertMacToGeckoKeyCode(UInt32 keyCode, WidgetKeyboardEvent* aKeyEvent, NSString* characters)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  uint32_t geckoKeyCode = 0;

  switch (keyCode)
  {
    // modifiers. We don't get separate events for these
    case kEscapeKeyCode:        geckoKeyCode = NS_VK_ESCAPE;         break;
    case kRCommandKeyCode:
    case kCommandKeyCode:       geckoKeyCode = NS_VK_META;           break;
    case kRShiftKeyCode:
    case kShiftKeyCode:         geckoKeyCode = NS_VK_SHIFT;          break;
    case kCapsLockKeyCode:      geckoKeyCode = NS_VK_CAPS_LOCK;      break;
    case kRControlKeyCode:
    case kControlKeyCode:       geckoKeyCode = NS_VK_CONTROL;        break;
    case kROptionKeyCode:
    case kOptionkeyCode:        geckoKeyCode = NS_VK_ALT;            break;
    case kClearKeyCode:         geckoKeyCode = NS_VK_CLEAR;          break;

    // function keys
    case kF1KeyCode:            geckoKeyCode = NS_VK_F1;             break;
    case kF2KeyCode:            geckoKeyCode = NS_VK_F2;             break;
    case kF3KeyCode:            geckoKeyCode = NS_VK_F3;             break;
    case kF4KeyCode:            geckoKeyCode = NS_VK_F4;             break;
    case kF5KeyCode:            geckoKeyCode = NS_VK_F5;             break;
    case kF6KeyCode:            geckoKeyCode = NS_VK_F6;             break;
    case kF7KeyCode:            geckoKeyCode = NS_VK_F7;             break;
    case kF8KeyCode:            geckoKeyCode = NS_VK_F8;             break;
    case kF9KeyCode:            geckoKeyCode = NS_VK_F9;             break;
    case kF10KeyCode:           geckoKeyCode = NS_VK_F10;            break;
    case kF11KeyCode:           geckoKeyCode = NS_VK_F11;            break;
    case kF12KeyCode:           geckoKeyCode = NS_VK_F12;            break;
    // case kF13KeyCode:           geckoKeyCode = NS_VK_F13;            break; 
   // clash with the 3 below
    // case kF14KeyCode:           geckoKeyCode = NS_VK_F14;            break;
    // case kF15KeyCode:           geckoKeyCode = NS_VK_F15;            break;
    case kPauseKeyCode:         geckoKeyCode = NS_VK_PAUSE;          break;
    case kScrollLockKeyCode:    geckoKeyCode = NS_VK_SCROLL_LOCK;    break;
    case kPrintScreenKeyCode:   geckoKeyCode = NS_VK_PRINTSCREEN;    break;

    // keypad
    case kKeypad0KeyCode:       geckoKeyCode = NS_VK_NUMPAD0;        break;
    case kKeypad1KeyCode:       geckoKeyCode = NS_VK_NUMPAD1;        break;
    case kKeypad2KeyCode:       geckoKeyCode = NS_VK_NUMPAD2;        break;
    case kKeypad3KeyCode:       geckoKeyCode = NS_VK_NUMPAD3;        break;
    case kKeypad4KeyCode:       geckoKeyCode = NS_VK_NUMPAD4;        break;
    case kKeypad5KeyCode:       geckoKeyCode = NS_VK_NUMPAD5;        break;
    case kKeypad6KeyCode:       geckoKeyCode = NS_VK_NUMPAD6;        break;
    case kKeypad7KeyCode:       geckoKeyCode = NS_VK_NUMPAD7;        break;
    case kKeypad8KeyCode:       geckoKeyCode = NS_VK_NUMPAD8;        break;
    case kKeypad9KeyCode:       geckoKeyCode = NS_VK_NUMPAD9;        break;

    case kKeypadMultiplyKeyCode:  geckoKeyCode = NS_VK_MULTIPLY;     break;
    case kKeypadAddKeyCode:       geckoKeyCode = NS_VK_ADD;          break;
    case kKeypadSubtractKeyCode:  geckoKeyCode = NS_VK_SUBTRACT;     break;
    case kKeypadDecimalKeyCode:   geckoKeyCode = NS_VK_DECIMAL;      break;
    case kKeypadDivideKeyCode:    geckoKeyCode = NS_VK_DIVIDE;       break;

    // these may clash with forward delete and help
    case kInsertKeyCode:        geckoKeyCode = NS_VK_INSERT;         break;
    case kDeleteKeyCode:        geckoKeyCode = NS_VK_DELETE;         break;

    case kBackspaceKeyCode:     geckoKeyCode = NS_VK_BACK;           break;
    case kTabKeyCode:           geckoKeyCode = NS_VK_TAB;            break;
    case kHomeKeyCode:          geckoKeyCode = NS_VK_HOME;           break;
    case kEndKeyCode:           geckoKeyCode = NS_VK_END;            break;
    case kPageUpKeyCode:        geckoKeyCode = NS_VK_PAGE_UP;        break;
    case kPageDownKeyCode:      geckoKeyCode = NS_VK_PAGE_DOWN;      break;
    case kLeftArrowKeyCode:     geckoKeyCode = NS_VK_LEFT;           break;
    case kRightArrowKeyCode:    geckoKeyCode = NS_VK_RIGHT;          break;
    case kUpArrowKeyCode:       geckoKeyCode = NS_VK_UP;             break;
    case kDownArrowKeyCode:     geckoKeyCode = NS_VK_DOWN;           break;
    case kVK_ANSI_1:            geckoKeyCode = NS_VK_1;              break;
    case kVK_ANSI_2:            geckoKeyCode = NS_VK_2;              break;
    case kVK_ANSI_3:            geckoKeyCode = NS_VK_3;              break;
    case kVK_ANSI_4:            geckoKeyCode = NS_VK_4;              break;
    case kVK_ANSI_5:            geckoKeyCode = NS_VK_5;              break;
    case kVK_ANSI_6:            geckoKeyCode = NS_VK_6;              break;
    case kVK_ANSI_7:            geckoKeyCode = NS_VK_7;              break;
    case kVK_ANSI_8:            geckoKeyCode = NS_VK_8;              break;
    case kVK_ANSI_9:            geckoKeyCode = NS_VK_9;              break;
    case kVK_ANSI_0:            geckoKeyCode = NS_VK_0;              break;

    default:
      // if we haven't gotten the key code already, look at the char code
      if ([characters length])
        geckoKeyCode = GetGeckoKeyCodeFromChar([characters characterAtIndex:0]);
  }

  return geckoKeyCode;

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(0);
}

static bool IsSpecialGeckoKey(UInt32 macKeyCode)
{
  bool  isSpecial;
  
  // this table is used to determine which keys are special and should not generate a charCode
  switch (macKeyCode)
  {
    // modifiers - we don't get separate events for these yet
    case kEscapeKeyCode:
    case kShiftKeyCode:
    case kRShiftKeyCode:
    case kCommandKeyCode:
    case kRCommandKeyCode:
    case kCapsLockKeyCode:
    case kControlKeyCode:
    case kRControlKeyCode:
    case kOptionkeyCode:
    case kROptionKeyCode:
    case kClearKeyCode:
      
    // function keys
    case kF1KeyCode:
    case kF2KeyCode:
    case kF3KeyCode:
    case kF4KeyCode:
    case kF5KeyCode:
    case kF6KeyCode:
    case kF7KeyCode:
    case kF8KeyCode:
    case kF9KeyCode:
    case kF10KeyCode:
    case kF11KeyCode:
    case kF12KeyCode:
    case kPauseKeyCode:
    case kScrollLockKeyCode:
    case kPrintScreenKeyCode:
      
    case kInsertKeyCode:
    case kDeleteKeyCode:
    case kTabKeyCode:
    case kBackspaceKeyCode:
     
    case kHomeKeyCode:
    case kEndKeyCode:
    case kPageUpKeyCode:
    case kPageDownKeyCode:
    case kLeftArrowKeyCode:
    case kRightArrowKeyCode:
    case kUpArrowKeyCode:
    case kDownArrowKeyCode:
    case kReturnKeyCode:
    case kEnterKeyCode:
    case kPowerbookEnterKeyCode:
      isSpecial = true;
      break;
      
    default:
      isSpecial = false;
      break;
  }
  
  return isSpecial;
}

static bool IsNormalCharInputtingEvent(const WidgetKeyboardEvent& aEvent)
{
  // this is not a character event.
  if (!aEvent.isChar || !aEvent.charCode || aEvent.IsMeta())
    return false;
  // if this is a unicode char input event, we don't need to check
  // ctrl/alt/command keys.
  if (aEvent.charCode > 0x7F)
    return true;
  // ASCII chars should be input without ctrl/alt/command keys
  return !aEvent.IsControl() && !aEvent.IsAlt();
}

#define CHARCODE_MASK_1 0x00FF0000
#define CHARCODE_MASK_2 0x000000FF
#define CHARCODE_MASK   0x00FF00FF

static uint32_t
KeyTranslateToUnicode(Handle aHandle, UInt32 aKeyCode, UInt32 aModifiers,
                      TextEncoding aEncoding)
{
#ifdef DEBUG_KB
  NSLog(@"****  KeyTranslateToUnicode: aHandle: %p, aKeyCode: %X, aModifiers: %X, aEncoding: %X",
        aHandle, aKeyCode, aModifiers, aEncoding);
  bool isShift = aModifiers & shiftKey;
  bool isCtrl = aModifiers & controlKey;
  bool isOpt = aModifiers & optionKey;
  bool isCmd = aModifiers & cmdKey;
  bool isCL = aModifiers & alphaLock;
  bool isNL = aModifiers & kEventKeyModifierNumLockMask;
  NSLog(@"        Shift: %s, Ctrl: %s, Opt: %s, Cmd: %s, CapsLock: %s, NumLock: %s",
        isShift ? "ON" : "off", isCtrl ? "ON" : "off", isOpt ? "ON" : "off",
        isCmd ? "ON" : "off", isCL ? "ON" : "off", isNL ? "ON" : "off");
#endif
  UInt32 state = 0;
  UInt32 val =
    ::KeyTranslate(aHandle, aKeyCode | aModifiers, &state) & CHARCODE_MASK;
  // If state is not zero, it is in dead key state. Then, we need to recall
  // KeyTranslate for getting the actual character.
  if (state) {
    val =
      ::KeyTranslate(aHandle, aKeyCode | aModifiers, &state) & CHARCODE_MASK;
  }
  uint32_t ch = 0;
  UInt8 buf[2];
  CFIndex len = 0;
  if (val & CHARCODE_MASK_1)
    buf[len++] = (val & CHARCODE_MASK_1) >> 16;
  buf[len++] = val & CHARCODE_MASK_2;

  CFStringRef str =
    ::CFStringCreateWithBytes(kCFAllocatorDefault, buf, len,
                              (CFStringEncoding)aEncoding, false);
  ch = ::CFStringGetLength(str) == 1 ?
         ::CFStringGetCharacterAtIndex(str, 0) : 0;
  ::CFRelease(str);
#ifdef DEBUG_KB
  NSLog(@"       result: %X(%C)", ch, ch > ' ' ? ch : ' ');
#endif
  return ch;
}

static uint32_t
UCKeyTranslateToUnicode(const UCKeyboardLayout* aHandle, UInt32 aKeyCode, UInt32 aModifiers,
                        UInt32 aKbType)
{
#ifdef DEBUG_KB
  NSLog(@"**** UCKeyTranslateToUnicode: aHandle: %p, aKeyCode: %X, aModifiers: %X, aKbType: %X",
        aHandle, aKeyCode, aModifiers, aKbType);
  bool isShift = aModifiers & shiftKey;
  bool isCtrl = aModifiers & controlKey;
  bool isOpt = aModifiers & optionKey;
  bool isCmd = aModifiers & cmdKey;
  bool isCL = aModifiers & alphaLock;
  bool isNL = aModifiers & kEventKeyModifierNumLockMask;
  NSLog(@"        Shift: %s, Ctrl: %s, Opt: %s, Cmd: %s, CapsLock: %s, NumLock: %s",
        isShift ? "ON" : "off", isCtrl ? "ON" : "off", isOpt ? "ON" : "off",
        isCmd ? "ON" : "off", isCL ? "ON" : "off", isNL ? "ON" : "off");
#endif
  UInt32 deadKeyState = 0;
  UniCharCount len;
  UniChar chars[5];
  OSStatus err = ::UCKeyTranslate(aHandle, aKeyCode,
                                  kUCKeyActionDown, aModifiers >> 8,
                                  aKbType, kUCKeyTranslateNoDeadKeysMask,
                                  &deadKeyState, 5, &len, chars);
  uint32_t ch = (err == noErr && len == 1) ? uint32_t(chars[0]) : 0;
#ifdef DEBUG_KB
  NSLog(@"       result: %X(%C)", ch, ch > ' ' ? ch : ' ');
#endif
  return ch;
}

struct KeyTranslateData {
  KeyTranslateData() {
    mUchr.mLayout = nullptr;
    mUchr.mKbType = 0;
    mKchr.mHandle = nullptr;
    mKchr.mEncoding = NULL; // TextEncoding won't accept nullptr
  }
  // The script of the layout determines the encoding of characters obtained
  // from kchr resources.
  SInt16 mScript;
  // The keyboard layout identifier
  SInt32 mLayoutID;
  struct {
    const UCKeyboardLayout* mLayout;
    UInt32 mKbType;
  } mUchr;
  struct {
    Handle mHandle;
    TextEncoding mEncoding;
  } mKchr;
};

static uint32_t
GetUniCharFromKeyTranslate(KeyTranslateData& aData,
                           UInt32 aKeyCode, UInt32 aModifiers)
{
  if (aData.mUchr.mLayout) {
    return UCKeyTranslateToUnicode(aData.mUchr.mLayout, aKeyCode, aModifiers,
                                   aData.mUchr.mKbType);
  }
  if (aData.mKchr.mHandle) {
    return KeyTranslateToUnicode(aData.mKchr.mHandle, aKeyCode, aModifiers,
                                 aData.mKchr.mEncoding);
  }
  return 0;
}

static SInt32
GetScriptFromKeyboardLayout(SInt32 aLayoutID)
{
  switch (aLayoutID) {
    case 0:                      // US
    case 3:                      // German
    case 224:                    // Swedish
    case -2:     return smRoman; // US-Extended
    case -18944: return smGreek; // Greek
    default: NS_NOTREACHED("unknown keyboard layout");
  }
  return smRoman;
}

static CFStringRef
GetInputSourceIDFromKeyboardLayout(SInt32 aLayoutID)
{
  NS_ASSERTION(nsCocoaFeatures::OnLeopardOrLater() &&
               Leopard_TISCopyCurrentKeyboardLayoutInputSource &&
               Leopard_TISGetInputSourceProperty &&
               Leopard_TISCreateInputSourceList &&
               kOurTISPropertyUnicodeKeyLayoutData &&
               kOurTISPropertyInputSourceID,
               "GetInputSourceIDFromKeyboardLayout should only be used on Leopard or later.");

  KeyboardLayoutRef keylayout;
  if (KLGetKeyboardLayoutWithIdentifier(aLayoutID, &keylayout) != noErr)
    return nullptr;

  const void* uchrFromID;
  if (KLGetKeyboardLayoutProperty(keylayout, kKLuchrData, &uchrFromID) != noErr)
    return nullptr;

  CFDictionaryRef dict = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, NULL, NULL);
  CFArrayRef inputSources = Leopard_TISCreateInputSourceList(dict, true);
  CFRelease(dict);

  CFStringRef sourceID = nullptr;
  for (CFIndex i = 0; i < CFArrayGetCount(inputSources); ++i) {
    TISInputSourceRef tis = static_cast<TISInputSourceRef>(const_cast<void *>(CFArrayGetValueAtIndex(inputSources, i)));
    CFDataRef data = static_cast<CFDataRef>(Leopard_TISGetInputSourceProperty(tis, kOurTISPropertyUnicodeKeyLayoutData));
    if (!data)
      continue;

    const UCKeyboardLayout* uchr = reinterpret_cast<const UCKeyboardLayout*>(CFDataGetBytePtr(data));
    if (uchr == uchrFromID) {
      sourceID = static_cast<CFStringRef>(Leopard_TISGetInputSourceProperty(tis, kOurTISPropertyInputSourceID));
      break;
    }
  }

  CFRelease(inputSources);

  return sourceID;
}

static void
GetKCHRData(KeyTranslateData &aKT)
{
  KeyboardLayoutRef kbRef;
  OSStatus err =
    ::KLGetKeyboardLayoutWithIdentifier(aKT.mLayoutID, &kbRef);
  if (err != noErr)
    return;

  err = ::KLGetKeyboardLayoutProperty(kbRef, kKLKCHRData,
                                      (const void**)&aKT.mKchr.mHandle);
  if (err != noErr || !aKT.mKchr.mHandle)
    return;

  err = ::GetTextEncodingFromScriptInfo(aKT.mScript, kTextLanguageDontCare,
                                        kTextRegionDontCare,
                                        &aKT.mKchr.mEncoding);
  if (err != noErr)
    aKT.mKchr.mHandle = nullptr;
}

static uint32_t
GetUSLayoutCharFromKeyTranslate(UInt32 aKeyCode, UInt32 aModifiers)
{
  KeyboardLayoutRef kbRef = nullptr;
  OSStatus err = ::KLGetKeyboardLayoutWithIdentifier(kKLUSKeyboard, &kbRef);
  NS_ENSURE_TRUE(err == noErr && kbRef, 0);
  const UCKeyboardLayout* layout = nullptr;
  err = ::KLGetKeyboardLayoutProperty(kbRef, kKLuchrData,
                                      (const void**)&layout);
  NS_ENSURE_TRUE(err == noErr && layout, 0);
  UInt32 kbType = 40; // ANSI, don't use actual layout
  return UCKeyTranslateToUnicode(layout, aKeyCode,
                                 aModifiers, kbType);
}

- (void) convertCocoaKeyEvent:(NSEvent*)aKeyEvent toGeckoEvent:(WidgetKeyboardEvent*)outGeckoEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  NS_ASSERTION(aKeyEvent && outGeckoEvent, "convertCocoaKeyEvent:toGeckoEvent: requires non-null arguments");
  if (!aKeyEvent || !outGeckoEvent)
    return;

  nsCocoaUtils::InitInputEvent(*outGeckoEvent, aKeyEvent);

  // coords for key events are always 0,0
  outGeckoEvent->refPoint.x = outGeckoEvent->refPoint.y = 0;

  // Initialize whether or not we are using charCodes to false.
  outGeckoEvent->isChar = false;

  // Check to see if the message is a key press that does not involve
  // one of our special key codes.
  if (outGeckoEvent->mMessage == eKeyPress &&
      !IsSpecialGeckoKey(nsCocoaUtils::GetCocoaEventKeyCode(aKeyEvent))) {
    outGeckoEvent->isChar = true; // this is not a special key
    
    outGeckoEvent->charCode = 0;
    outGeckoEvent->keyCode  = 0; // not set for key press events
    
    NSString* chars = [aKeyEvent characters];
    if ([chars length] > 0)
      outGeckoEvent->charCode = [chars characterAtIndex:0];
    
    // convert control-modified charCode to raw charCode (with appropriate case)
    if (outGeckoEvent->IsControl() && outGeckoEvent->charCode <= 26)
      outGeckoEvent->charCode += (outGeckoEvent->IsShift()) ? ('A' - 1) : ('a' - 1);

    // Accel and access key handling needs to know the characters that this
    // key produces with Shift up or down.  So, provide this information
    // when Ctrl or Command or Alt is pressed.
    if (outGeckoEvent->IsControl() || outGeckoEvent->IsMeta() ||
        outGeckoEvent->IsAlt()) {
      KeyTranslateData kt;

      bool isRomanKeyboardLayout;

      if (gOverrideKeyboardLayout.mOverrideEnabled) {
        kt.mLayoutID = gOverrideKeyboardLayout.mKeyboardLayout;
        kt.mScript = GetScriptFromKeyboardLayout(kt.mLayoutID);
      } else {
        // GetScriptManagerVariable and GetScriptVariable are both deprecated.
        // KLGetCurrentKeyboardLayout is newer but also deprecated in OS X
        // 10.5.  It's not clear from the documentation but it seems that
        // KLGetKeyboardLayoutProperty with kKLGroupIdentifier may provide the
        // script identifier for a KeyboardLayoutRef (bug 432388 comment 6).
        // The "Text Input Source Services" API is not available prior to OS X
        // 10.5.
        kt.mScript = ::GetScriptManagerVariable(smKeyScript);
        kt.mLayoutID = ::GetScriptVariable(kt.mScript, smScriptKeys);
      }
      isRomanKeyboardLayout = (kt.mScript == smRoman);

      bool isUchrKeyboardLayout = false;
      // GetResource('uchr', kt.mLayoutID) fails on OS X 10.5
      if (nsCocoaFeatures::OnLeopardOrLater() &&
          Leopard_TISCopyCurrentKeyboardLayoutInputSource &&
          Leopard_TISGetInputSourceProperty &&
          Leopard_TISCreateInputSourceList &&
          kOurTISPropertyUnicodeKeyLayoutData &&
          kOurTISPropertyInputSourceID) {
        CFDataRef uchr = NULL;
        if (gOverrideKeyboardLayout.mOverrideEnabled) {
          CFStringRef sourceID = GetInputSourceIDFromKeyboardLayout(kt.mLayoutID);
          NS_ASSERTION(sourceID, "unable to map keyboard layout ID to input source ID");
          const void* keys[] = { kOurTISPropertyInputSourceID };
          const void* vals[] = { sourceID };
          CFDictionaryRef dict = CFDictionaryCreate(kCFAllocatorDefault, keys, vals, 1, NULL, NULL);
          CFArrayRef inputSources = Leopard_TISCreateInputSourceList(dict, true);
          CFRelease(dict);
          if (CFArrayGetCount(inputSources) == 1) {
            TISInputSourceRef tis = static_cast<TISInputSourceRef>(const_cast<void *>(CFArrayGetValueAtIndex(inputSources, 0)));
            uchr = static_cast<CFDataRef>(Leopard_TISGetInputSourceProperty(tis, kOurTISPropertyUnicodeKeyLayoutData));
          }
          CFRelease(inputSources);
        } else {
          TISInputSourceRef tis = Leopard_TISCopyCurrentKeyboardLayoutInputSource();
          uchr = static_cast<CFDataRef>(Leopard_TISGetInputSourceProperty(tis, kOurTISPropertyUnicodeKeyLayoutData));
        }
        if (uchr) {
          // We should be here on OS X 10.5 for any Apple provided layout, as
          // they are all uchr.  It may be possible to still use kchr resources
          // from elsewhere, so they may be picked by GetKCHRData below
          kt.mUchr.mLayout = reinterpret_cast<const UCKeyboardLayout*>
            (CFDataGetBytePtr(uchr));
          isUchrKeyboardLayout = true;
        }
      } else {
        // 10.4
        KeyboardLayoutRef kbRef = nullptr;
        OSStatus err = ::KLGetKeyboardLayoutWithIdentifier(kt.mLayoutID,
                                                           &kbRef);
        if (err == noErr && kbRef) {
          SInt32 kind;
          err = ::KLGetKeyboardLayoutProperty(kbRef, kKLKind,
                                              (const void **)&kind);
          if (err == noErr && kind != kKLKCHRKind) {
            err = ::KLGetKeyboardLayoutProperty(kbRef, kKLuchrData,
                      (const void**)&kt.mUchr.mLayout);
            if (err != noErr) {
              kt.mUchr.mLayout = nullptr;
              // if the kind is kKLKCHRuchrKind, we can retry by KCHR.
              isUchrKeyboardLayout = kind != kKLKCHRuchrKind;
            } else {
              isUchrKeyboardLayout = true;
            }
          }
        }
      }

      if (!isUchrKeyboardLayout) {
        GetKCHRData(kt);
      }
      // If a keyboard layout override is set, we also need to force the
      // keyboard type to something ANSI to avoid test failures on machines
      // with JIS keyboards (since the pair of keyboard layout and physical
      // keyboard type form the actual key layout).  This assumes that the
      // test setting the override was written assuming an ANSI keyboard.
      if (kt.mUchr.mLayout)
        kt.mUchr.mKbType = gOverrideKeyboardLayout.mOverrideEnabled ? 40 : ::LMGetKbdType();

      UInt32 key = nsCocoaUtils::GetCocoaEventKeyCode(aKeyEvent);
      // Caps lock and num lock modifier state:
      UInt32 lockState = 0;
      if (nsCocoaUtils::GetCocoaEventModifierFlags(aKeyEvent) & NSAlphaShiftKeyMask)
        lockState |= alphaLock;
      if (nsCocoaUtils::GetCocoaEventModifierFlags(aKeyEvent) & NSNumericPadKeyMask)
        lockState |= kEventKeyModifierNumLockMask;
      // normal chars
      uint32_t unshiftedChar = GetUniCharFromKeyTranslate(kt, key, lockState);
      UInt32 shiftLockMod = shiftKey | lockState;
      uint32_t shiftedChar = GetUniCharFromKeyTranslate(kt, key, shiftLockMod);

      // characters generated with Cmd key
      // XXX we should remove CapsLock state, which changes characters from
      //     Latin to Cyrillic with Russian layout on 10.4 only when Cmd key
      //     is pressed.
      UInt32 numState = (lockState & ~alphaLock); // only num lock state
      uint32_t uncmdedChar = GetUniCharFromKeyTranslate(kt, key, numState);
      UInt32 shiftNumMod = numState | shiftKey;
      uint32_t uncmdedShiftChar =
                 GetUniCharFromKeyTranslate(kt, key, shiftNumMod);
      uint32_t uncmdedUSChar = GetUSLayoutCharFromKeyTranslate(key, numState);
      UInt32 cmdNumMod = cmdKey | numState;
      uint32_t cmdedChar = GetUniCharFromKeyTranslate(kt, key, cmdNumMod);
      UInt32 cmdShiftNumMod = shiftKey | cmdNumMod;
      uint32_t cmdedShiftChar =
        GetUniCharFromKeyTranslate(kt, key, cmdShiftNumMod);

      // Is the keyboard layout changed by Cmd key?
      // E.g., Arabic, Russian, Hebrew, Greek and Dvorak-QWERTY.
      bool isCmdSwitchLayout = uncmdedChar != cmdedChar;
      // Is the keyboard layout for Latin, but Cmd key switches the layout?
      // I.e., Dvorak-QWERTY
      bool isDvorakQWERTY = isCmdSwitchLayout && isRomanKeyboardLayout;

      // If the current keyboard is not Dvorak-QWERTY or Cmd is not pressed,
      // we should append unshiftedChar and shiftedChar for handling the
      // normal characters.  These are the characters that the user is most
      // likely to associate with this key.
      if ((unshiftedChar || shiftedChar) &&
          (!outGeckoEvent->IsMeta() || !isDvorakQWERTY)) {
        AlternativeCharCode altCharCodes(unshiftedChar, shiftedChar);
        outGeckoEvent->alternativeCharCodes.AppendElement(altCharCodes);
      }

      // Most keyboard layouts provide the same characters in the NSEvents
      // with Command+Shift as with Command.  However, with Command+Shift we
      // want the character on the second level.  e.g. With a US QWERTY
      // layout, we want "?" when the "/","?" key is pressed with
      // Command+Shift.

      // On a German layout, the OS gives us '/' with Cmd+Shift+SS(eszett)
      // even though Cmd+SS is 'SS' and Shift+'SS' is '?'.  This '/' seems
      // like a hack to make the Cmd+"?" event look the same as the Cmd+"?"
      // event on a US keyboard.  The user thinks they are typing Cmd+"?", so
      // we'll prefer the "?" character, replacing charCode with shiftedChar
      // when Shift is pressed.  However, in case there is a layout where the
      // character unique to Cmd+Shift is the character that the user expects,
      // we'll send it as an alternative char.
      bool hasCmdShiftOnlyChar =
        cmdedChar != cmdedShiftChar && uncmdedShiftChar != cmdedShiftChar;
      uint32_t originalCmdedShiftChar = cmdedShiftChar;

      // If we can make a good guess at the characters that the user would
      // expect this key combination to produce (with and without Shift) then
      // use those characters.  This also corrects for CapsLock, which was
      // ignored above.
      if (!isCmdSwitchLayout) {
        // The characters produced with Command seem similar to those without
        // Command.
        if (unshiftedChar)
          cmdedChar = unshiftedChar;
        if (shiftedChar)
          cmdedShiftChar = shiftedChar;
      } else if (uncmdedUSChar == cmdedChar) {
        // It looks like characters from a US layout are provided when Command
        // is down.
        uint32_t ch = GetUSLayoutCharFromKeyTranslate(key, lockState);
        if (ch)
          cmdedChar = ch;
        ch = GetUSLayoutCharFromKeyTranslate(key, shiftLockMod);
        if (ch)
          cmdedShiftChar = ch;
      }

      // Only charCode (not alternativeCharCodes) is available to javascript,
      // so attempt to set this to the most likely intended (or most useful)
      // character.  Note that cmdedChar and cmdedShiftChar are usually
      // Latin/ASCII characters and that is what is wanted here as accel
      // keys are expected to be Latin characters.
      //
      // XXX We should do something similar when Control is down (bug 429510).
      if (outGeckoEvent->IsMeta() &&
           !(outGeckoEvent->IsControl() || outGeckoEvent->IsAlt())) {

        // The character to use for charCode.
        uint32_t preferredCharCode = 0;
        preferredCharCode = outGeckoEvent->IsShift() ? cmdedShiftChar : cmdedChar;

        if (preferredCharCode) {
#ifdef DEBUG_KB
          if (outGeckoEvent->charCode != preferredCharCode) {
            NSLog(@"      charCode replaced: %X(%C) to %X(%C)",
                  outGeckoEvent->charCode,
                  outGeckoEvent->charCode > ' ' ? outGeckoEvent->charCode : ' ',
                  preferredCharCode,
                  preferredCharCode > ' ' ? preferredCharCode : ' ');
          }
#endif
          outGeckoEvent->charCode = preferredCharCode;
        }
      }

      // If the current keyboard layout is switched by the Cmd key,
      // we should append cmdedChar and shiftedCmdChar that are
      // Latin char for the key. But don't append at Dvorak-QWERTY.
      if ((cmdedChar || cmdedShiftChar) &&
          isCmdSwitchLayout && !isDvorakQWERTY) {
        AlternativeCharCode altCharCodes(cmdedChar, cmdedShiftChar);
        outGeckoEvent->alternativeCharCodes.AppendElement(altCharCodes);
      }
      // Special case for 'SS' key of German layout. See the comment of
      // hasCmdShiftOnlyChar definition for the detail.
      if (hasCmdShiftOnlyChar && originalCmdedShiftChar) {
        AlternativeCharCode altCharCodes(0, originalCmdedShiftChar);
        outGeckoEvent->alternativeCharCodes.AppendElement(altCharCodes);
      }
    }
  }
  else {
    NSString* characters = nil;
    if ([aKeyEvent type] != NSFlagsChanged)
      characters = [aKeyEvent charactersIgnoringModifiers];
    
    outGeckoEvent->keyCode =
      ConvertMacToGeckoKeyCode([aKeyEvent keyCode], outGeckoEvent, characters);
    outGeckoEvent->charCode = 0;
  } 

  // For NativeKeyBindings
  outGeckoEvent->mNativeKeyEvent = aKeyEvent;

  if (outGeckoEvent->mMessage == eKeyPress && !outGeckoEvent->IsMeta())
    [NSCursor setHiddenUntilMouseMoves:YES];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

// Mozilla 6 removed this code, but we still need it for TenFourFox.

- (void)sendCompositionEvent:(int32_t) aEventType
{
#ifdef DEBUG_IME
  NSLog(@"****in sendCompositionEvent; type = %d", aEventType);
#endif

  if (!mGeckoChild)
    return;

  if (aEventType == eCompositionStart)
    [self initTSMDocument];

  // static void init_composition_event( *aEvent, int aType)
  WidgetCompositionEvent event(true, aEventType, mGeckoChild);
  event.time = PR_IntervalNow();
  if (aEventType == eCompositionEnd)
    event.mData = mLastDispatchedCompositionString;
  mGeckoChild->DispatchWindowEvent(event);
  mLastDispatchedCompositionString.Truncate();
}

- (void)sendTextEvent:(char16_t*) aBuffer 
                      attributedString:(NSAttributedString*) aString  
                      selectedRange:(NSRange) selRange 
                      markedRange:(NSRange) markRange
                      doCommit:(BOOL) doCommit
{
#ifdef DEBUG_IME
  NSLog(@"****in sendTextEvent; string = '%@'", aString);
  NSLog(@" markRange = %d, %d;  selRange = %d, %d", markRange.location, markRange.length, selRange.location, selRange.length);
#endif
  if (!mGeckoChild)
    return;

  WidgetCompositionEvent textEvent(true, eCompositionChange, mGeckoChild);
  textEvent.time = PR_IntervalNow();
  textEvent.mData = aBuffer;
  if (!doCommit)
    textEvent.mRanges = ConvertAttributeToGeckoRange(aString,
	markRange, selRange, CountRanges(aString)); // harmonize bug 974318

  // Do everything here that TextInputHandler's
  // DispatchCompositionChangeEvent does.
  mLastDispatchedCompositionString = textEvent.mData;
  mGeckoChild->DispatchWindowEvent(textEvent);
}
// Whew!

#pragma mark -

#if(0)
// NSTextInputClient implementation

- (NSRange)markedRange
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  NS_ENSURE_TRUE(mTextInputHandler, NSMakeRange(NSNotFound, 0));
  return mTextInputHandler->MarkedRange();

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(NSMakeRange(0, 0));
}

- (NSRange)selectedRange
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  NS_ENSURE_TRUE(mTextInputHandler, NSMakeRange(NSNotFound, 0));
  return mTextInputHandler->SelectedRange();

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(NSMakeRange(0, 0));
}

- (BOOL)drawsVerticallyForCharacterAtIndex:(NSUInteger)charIndex
{
  NS_ENSURE_TRUE(mTextInputHandler, NO);
  if (charIndex == NSNotFound) {
    return NO;
  }
  return mTextInputHandler->DrawsVerticallyForCharacterAtIndex(charIndex);
}

- (NSUInteger)characterIndexForPoint:(NSPoint)thePoint
{
  NS_ENSURE_TRUE(mTextInputHandler, 0);
  return mTextInputHandler->CharacterIndexForPoint(thePoint);
}

- (NSArray*)validAttributesForMarkedText
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  NS_ENSURE_TRUE(mTextInputHandler, [NSArray array]);
  return mTextInputHandler->GetValidAttributesForMarkedText();

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  NS_ENSURE_TRUE_VOID(mGeckoChild);

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  NSAttributedString* attrStr;
  if ([aString isKindOfClass:[NSAttributedString class]]) {
    attrStr = static_cast<NSAttributedString*>(aString);
  } else {
    attrStr = [[[NSAttributedString alloc] initWithString:aString] autorelease];
  }

  mTextInputHandler->InsertText(attrStr, &replacementRange);

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)doCommandBySelector:(SEL)aSelector
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!mGeckoChild || !mTextInputHandler) {
    return;
  }

  const char* sel = reinterpret_cast<const char*>(aSelector);
  if (!mTextInputHandler->DoCommandBySelector(sel)) {
    [super doCommandBySelector:aSelector];
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)unmarkText
{
  NS_ENSURE_TRUE_VOID(mTextInputHandler);
  mTextInputHandler->CommitIMEComposition();
}

- (BOOL) hasMarkedText
{
  NS_ENSURE_TRUE(mTextInputHandler, NO);
  return mTextInputHandler->HasMarkedText();
}

- (void)setMarkedText:(id)aString selectedRange:(NSRange)selectedRange
                               replacementRange:(NSRange)replacementRange
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  NS_ENSURE_TRUE_VOID(mTextInputHandler);

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  NSAttributedString* attrStr;
  if ([aString isKindOfClass:[NSAttributedString class]]) {
    attrStr = static_cast<NSAttributedString*>(aString);
  } else {
    attrStr = [[[NSAttributedString alloc] initWithString:aString] autorelease];
  }

  mTextInputHandler->SetMarkedText(attrStr, selectedRange, &replacementRange);

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (NSAttributedString*)attributedSubstringForProposedRange:(NSRange)aRange
                                        actualRange:(NSRangePointer)actualRange
{
  NS_ENSURE_TRUE(mTextInputHandler, nil);
  return mTextInputHandler->GetAttributedSubstringFromRange(aRange,
                                                            actualRange);
}

- (NSRect)firstRectForCharacterRange:(NSRange)aRange
                         actualRange:(NSRangePointer)actualRange
{
  NS_ENSURE_TRUE(mTextInputHandler, NSMakeRect(0.0, 0.0, 0.0, 0.0));
  return mTextInputHandler->FirstRectForCharacterRange(aRange, actualRange);
}

- (NSInteger)windowLevel
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  NS_ENSURE_TRUE(mTextInputHandler, [[self window] level]);
  return mTextInputHandler->GetWindowLevel();

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(NSNormalWindowLevel);
}
#else
// NSTextInput and partial NSTextInputClient implementation

- (void)insertText:(id)insertString
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  NS_ENSURE_TRUE_VOID(mGeckoChild);

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  if (![insertString isKindOfClass:[NSAttributedString class]])
    insertString = [[[NSAttributedString alloc] initWithString:insertString] autorelease];

  NSString *tmpStr = [insertString string];
  unsigned int len = [tmpStr length];
  if (!nsTSMManager::IsComposing() && len == 0)
    return; // nothing to do
#define MAX_BUFFER_SIZE 32
  char16_t buffer[MAX_BUFFER_SIZE];
  char16_t *bufPtr = (len >= MAX_BUFFER_SIZE) ? new char16_t[len + 1] : buffer;
  [tmpStr getCharacters:bufPtr];
  bufPtr[len] = char16_t('\0');

  if (len == 1 && !nsTSMManager::IsComposing()) {
    // don't let the same event be fired twice when hitting
    // enter/return! (Bug 420502)
    if (mKeyPressSent)
      return;

    // dispatch keypress event with char instead of textEvent
    WidgetKeyboardEvent geckoEvent(true, eKeyPress, mGeckoChild);
    geckoEvent.charCode  = bufPtr[0]; // gecko expects OS-translated unicode
    geckoEvent.keyCode   = 0;
    geckoEvent.isChar    = true;
    if (mKeyDownHandled)
      geckoEvent.mFlags.mDefaultPrevented = true;

    // Don't set other modifiers from the current event, because here in
    // -insertText: they've already been taken into account in creating
    // the input string.
        
    if (mCurKeyEvent) {
      nsCocoaUtils::InitInputEvent(geckoEvent, mCurKeyEvent);

      // XXX The ASCII characters inputting mode of egbridge (Japanese IME)
      // might send the keyDown event with wrong keyboard layout if other
      // keyboard layouts are already loaded. In that case, the native event
      // doesn't match to this gecko event...

      if (!IsPrintableChar(geckoEvent.charCode)) {
        geckoEvent.keyCode = ConvertMacToGeckoKeyCode(nsCocoaUtils::GetCocoaEventKeyCode(mCurKeyEvent), &geckoEvent, [mCurKeyEvent charactersIgnoringModifiers]);
        geckoEvent.charCode = 0;
      }
    } else {
      nsCocoaUtils::InitInputEvent(geckoEvent, static_cast<NSEvent*>(nullptr));
      // Note that insertText is not called only at key pressing.
      if (!IsPrintableChar(geckoEvent.charCode)) {
        geckoEvent.keyCode = GetGeckoKeyCodeFromChar(geckoEvent.charCode);
        geckoEvent.charCode = 0;
      }
    }

    // Remove basic modifiers from keypress event because if they are included,
    // nsPlaintextEditor ignores the event.
    geckoEvent.modifiers &= ~(mozilla::MODIFIER_CONTROL |
                              mozilla::MODIFIER_ALT |
                              mozilla::MODIFIER_META);
  
    // TODO:
    // If mCurrentKeyEvent.mKeyEvent is null and when we implement textInput
    // event of DOM3 Events, we should dispatch it instead of keypress event.
    bool keyPressHandled = mGeckoChild->DispatchWindowEvent(geckoEvent);

    // Note: mGeckoChild might have become null here. Don't count on it from here on.
    // Only record the results of dispatching geckoEvent if we're currently
    // processing a keyDown event.
    if (mCurKeyEvent) {
      mKeyPressHandled = keyPressHandled;
      mKeyPressSent = YES;
    }
  }
  else {
    if (!nsTSMManager::IsComposing()) {
      [self sendCompositionEvent:eCompositionStart];
      // Note: mGeckoChild might have become null here. Don't count on it from here on.
      nsTSMManager::StartComposing(self);
    }

    if (nsTSMManager::IgnoreCommit()) {
      tmpStr = [tmpStr init];
      len = 0;
      bufPtr[0] = char16_t('\0');
      insertString =
        [[[NSAttributedString alloc] initWithString:tmpStr] autorelease];
    }
    [self sendTextEvent:bufPtr attributedString:insertString
                               selectedRange:NSMakeRange(0, len)
                               markedRange:mMarkedRange
                               doCommit:YES];

    [self sendCompositionEvent:eCompositionEnd];
    nsTSMManager::EndComposing();
    mMarkedRange = NSMakeRange(NSNotFound, 0);
  }
  if (bufPtr != buffer)
    delete[] bufPtr;

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)insertNewline:(id)sender
{
  [self insertText:@"\n"];
}

- (void) doCommandBySelector:(SEL)aSelector
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

#if DEBUG_IME 
  NSLog(@"**** in doCommandBySelector %s (ignore %d)", aSelector, mKeyPressHandled);
#endif

  if (!mKeyPressHandled)
    [super doCommandBySelector:aSelector];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void) setMarkedText:(id)aString selectedRange:(NSRange)selRange
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!mGeckoChild)
    return;
  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  if (![aString isKindOfClass:[NSAttributedString class]])
    aString = [[[NSAttributedString alloc] initWithString:aString] autorelease];

  NSMutableAttributedString *mutableAttribStr = aString;
  NSString *tmpStr = [mutableAttribStr string];
  unsigned int len = [tmpStr length];
  char16_t buffer[MAX_BUFFER_SIZE];
  char16_t *bufPtr = (len >= MAX_BUFFER_SIZE) ? new char16_t[len + 1] : buffer;
  [tmpStr getCharacters:bufPtr];
  bufPtr[len] = char16_t('\0');
  mMarkedRange.length = len;

  if (!nsTSMManager::IsComposing() && len > 0) {
    WidgetQueryContentEvent
	selection(true, eQuerySelectedText, mGeckoChild);
    mGeckoChild->DispatchWindowEvent(selection);
    mMarkedRange.location = selection.mSucceeded ? selection.mReply.mOffset : 0;
    [self sendCompositionEvent:eCompositionStart];
    // Note: mGeckoChild might have become null here. Don't count on it from here on.
    nsTSMManager::StartComposing(self);
  }

  if (nsTSMManager::IsComposing()) {
    nsTSMManager::UpdateComposing(tmpStr);

    BOOL commit = len == 0;
    [self sendTextEvent:bufPtr attributedString:aString
                                  selectedRange:selRange
                                    markedRange:mMarkedRange
                                       doCommit:commit];
    // Note: mGeckoChild might have become null here. Don't count on it from here on.

    if (commit) {
      [self sendCompositionEvent:eCompositionEnd];
      // Note: mGeckoChild might have become null here. Don't count on it from here on.
      nsTSMManager::EndComposing();
    }
  }

  if (bufPtr != buffer)
    delete[] bufPtr;

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void) unmarkText
{
  nsTSMManager::CommitIME();
}

- (BOOL) hasMarkedText
{
  return (mMarkedRange.location != NSNotFound) && (mMarkedRange.length != 0);
}

- (NSInteger) conversationIdentifier
{
  if (!mGeckoChild)
    return (long)self;
  WidgetQueryContentEvent textContent(true, eQueryTextContent, mGeckoChild);
  textContent.InitForQueryTextContent(0, 0);
  mGeckoChild->DispatchWindowEvent(textContent);
  if (!textContent.mSucceeded)
    return (long)self;
  return (long)textContent.mReply.mContentsRoot;
}

- (NSAttributedString *) attributedSubstringFromRange:(NSRange)theRange
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  if (!mGeckoChild || theRange.length == 0)
    return nil;

  nsAutoString str;
  WidgetQueryContentEvent textContent(true, eQueryTextContent, mGeckoChild);
  textContent.InitForQueryTextContent(theRange.location, theRange.length);
  mGeckoChild->DispatchWindowEvent(textContent);

  if (!textContent.mSucceeded || textContent.mReply.mString.IsEmpty())
    return nil;

  NSString* nsstr = ToNSString(textContent.mReply.mString);
  NSAttributedString* result =
    [[[NSAttributedString alloc] initWithString:nsstr
                                     attributes:nil] autorelease];
  return result;

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}

- (NSRange) markedRange
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  if (![self hasMarkedText])
    return NSMakeRange(NSNotFound, 0);
  return mMarkedRange;

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(NSMakeRange(0, 0));
}

- (NSRange) selectedRange
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  if (!mGeckoChild)
    return NSMakeRange(NSNotFound, 0);
  WidgetQueryContentEvent selection(true, eQuerySelectedText, mGeckoChild);
  mGeckoChild->DispatchWindowEvent(selection);
  if (!selection.mSucceeded)
    return NSMakeRange(NSNotFound, 0);

  return NSMakeRange(selection.mReply.mOffset,
                     selection.mReply.mString.Length());

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(NSMakeRange(0, 0));
}

- (BOOL)drawsVerticallyForCharacterAtIndex:(NSUInteger)charIndex
{
  return NO; // XXX. See bug 1076657 if we need to support this.
}

- (NSRect) firstRectForCharacterRange:(NSRange)theRange
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  // XXX
  // This only returns the first character rect or caret rect right
  // now, not the first line rect, but this is sufficient for IME.
  NSRect rect;
  if (!mGeckoChild || theRange.location == NSNotFound)
    return rect;

  LayoutDeviceIntRect r;
  bool useCaretRect = theRange.length == 0;
  if (!useCaretRect) {
    WidgetQueryContentEvent charRect(true, eQueryTextRect, mGeckoChild);
    charRect.InitForQueryTextRect(theRange.location, 1);
    mGeckoChild->DispatchWindowEvent(charRect);
    if (charRect.mSucceeded)
      r = charRect.mReply.mRect;
      // XXX: actualRange code from TextInputHandler should be added here.
    else
      useCaretRect = true;
  }

  if (useCaretRect) {
    WidgetQueryContentEvent caretRect(true, eQueryCaretRect, mGeckoChild);
    caretRect.InitForQueryCaretRect(theRange.location);
    mGeckoChild->DispatchWindowEvent(caretRect);
    if (!caretRect.mSucceeded)
      return rect;
    r = caretRect.mReply.mRect;
    r.width = 0;
    // XXX: actualRange code from TextInputHandler should be added here.
  }
  nsIWidget* rootWidget = mGeckoChild->GetTopLevelWidget();
  NSWindow* rootWindow =
    static_cast<NSWindow*>(rootWidget->GetNativeData(NS_NATIVE_WINDOW));
  NSView* rootView =
    static_cast<NSView*>(rootWidget->GetNativeData(NS_NATIVE_WIDGET));
  if (!rootWindow || !rootView)
    return rect;
  rect = nsCocoaUtils::DevPixelsToCocoaPoints(r);
  rect = [rootView convertRect:rect toView:nil];
  rect.origin = [rootWindow convertBaseToScreen:rect.origin];
  return rect;

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(NSMakeRect(0.0, 0.0, 0.0, 0.0));
}

- (NSUInteger)characterIndexForPoint:(NSPoint)thePoint
{
  NS_WARNING("characterIndexForPoint not supported on 10.4");
  // this requires much mucking around with text frames. no thanks.
  // if we need this, implement it from TextInputHandler.mm and pray.
  return 0;
}

- (NSArray*) validAttributesForMarkedText
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  NS_WARNING("validAttributesForMarkedText not supported on 10.4");
  return [NSArray array]; // empty array, no attributes supported

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}
#endif

#pragma mark -

// More backouts for TenFourFox
+ (NSEvent*)makeNewCocoaEventWithType:(NSEventType)type fromEvent:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  NSEvent* newEvent = [NSEvent keyEventWithType:type
                                       location:[theEvent locationInWindow] 
modifierFlags:nsCocoaUtils::GetCocoaEventModifierFlags(theEvent)
                                      timestamp:[theEvent timestamp]
                                   windowNumber:[theEvent windowNumber]
                                        context:[theEvent context]
                                     characters:[theEvent characters]
                    charactersIgnoringModifiers:[theEvent charactersIgnoringModifiers]
                                      isARepeat:[theEvent isARepeat]
keyCode:nsCocoaUtils::GetCocoaEventKeyCode(theEvent)];
  return newEvent;

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}

#ifdef PR_LOGGING
static const char* ToEscapedString(NSString* aString, nsAutoCString& aBuf)
{
  for (uint32_t i = 0; i < [aString length]; ++i) {
    unichar ch = [aString characterAtIndex:i];
    if (ch >= 32 && ch < 128) {
      aBuf.Append(char(ch));
    } else {
      //aBuf += nsPrintfCString("\\u%04x", ch);
      aBuf += ".";
    }
  }
  return aBuf.get();
}
#endif

// This is a better solution to our menu problem on 10.4, and properly handles
// the case of Cmd-equivalents that are not menu shortcuts (10.4Fx issue 22).
- (BOOL)performKeyEquivalent:(NSEvent*)theEvent
{
    UInt32 mf = nsCocoaUtils::GetCocoaEventModifierFlags(theEvent) & NSDeviceIndependentModifierFlagsMask;
    // Only bother if a Cmd-combination. The rest, we use the regular event
    // processing routines. Otherwise we get doubled events for certain keys,
    // most notoriously anything with NSFunctionKeyMask (arrow keys, Fn, etc.).
    // But don't do this for Cmd-~ (10.4Fx issue 33).
    if (mf & NSCommandKeyMask) {
        UInt32 kc = nsCocoaUtils::GetCocoaEventKeyCode(theEvent);
        if (kc != kTildeKeyCode) {
    		[self keyDown:theEvent]; // this calls processKeyDownEvent too
    		return YES;
	}
    }
    return NO; // handlers take over
}
// end issue

// Returns true if Gecko claims to have handled the event, false otherwise.
- (bool)processKeyDownEvent:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  if (!mGeckoChild) return NO;

#ifdef PR_LOGGING
  nsAutoCString str1;
  nsAutoCString str2;
#endif
#if(0)
  PR_LOG(sCocoaLog, PR_LOG_ALWAYS,
         ("ChildView processKeyDownEvent: keycode=%d,modifiers=%x,chars=%s,charsIgnoringModifiers=%s IMEopenstate=%s\n",
          nsCocoaUtils::GetCocoaEventKeyCode(theEvent),
          nsCocoaUtils::GetCocoaEventModifierFlags(theEvent),
          ToEscapedString([theEvent characters], str1),
          ToEscapedString([theEvent charactersIgnoringModifiers], str2),
((nsTSMManager::GetIMEOpenState()) ? "TRUE" : "false")));
#endif

  nsAutoRetainCocoaObject kungFuDeathGrip(self);
  mCurKeyEvent = theEvent;

  BOOL nonDeadKeyPress = [[theEvent characters] length] > 0;
  if (nonDeadKeyPress && !nsTSMManager::IsComposing()) {
    NSResponder* firstResponder = [[self window] firstResponder];

    WidgetKeyboardEvent geckoKeydown(true, eKeyDown, mGeckoChild);
    [self convertCocoaKeyEvent:theEvent toGeckoEvent:&geckoKeydown];

    mKeyDownHandled = mGeckoChild->DispatchWindowEvent(geckoKeydown);
    if (!mGeckoChild) {
      return mKeyDownHandled;
    }

    // The key down event may have shifted the focus, in which
    // case we should not fire the key press.
    if (firstResponder != [[self window] firstResponder]) {
      bool handled = mKeyDownHandled;
      mCurKeyEvent = nil;
      mKeyDownHandled = false;
      return handled;
    }

    // If this is the context menu key command, send a context menu key event.
    unsigned int modifierFlags = nsCocoaUtils::GetCocoaEventModifierFlags(theEvent) & NSDeviceIndependentModifierFlagsMask;

    if (modifierFlags == NSControlKeyMask && [[theEvent charactersIgnoringModifiers] isEqualToString:@" "]) {
      WidgetMouseEvent contextMenuEvent(true, eContextMenu, [self widget], WidgetMouseEvent::eReal, WidgetMouseEvent::eContextMenuKey);
      contextMenuEvent.modifiers = 0;
      bool cmEventHandled = mGeckoChild->DispatchWindowEvent(contextMenuEvent);
      [self maybeInitContextMenuTracking];
      // Bail, there is nothing else to do here.
      bool handled = (cmEventHandled || mKeyDownHandled);
      mCurKeyEvent = nil;
      mKeyDownHandled = false;
      return handled;
    }

    WidgetKeyboardEvent geckoKeypress(true, eKeyPress, mGeckoChild);
    [self convertCocoaKeyEvent:theEvent toGeckoEvent:&geckoKeypress];

    // if this is a non-letter keypress, or the control key is down,
    // dispatch the keydown to gecko, so that we trap delete,
    // control-letter combinations etc before Cocoa tries to use
    // them for keybindings.
    if ((!geckoKeypress.isChar || geckoKeypress.IsControl()) &&
        !nsTSMManager::IsComposing()) {
      if (mKeyDownHandled)
        geckoKeypress.mFlags.mDefaultPrevented = true;
      mKeyPressHandled = mGeckoChild->DispatchWindowEvent(geckoKeypress);
      mKeyPressSent = YES;
      if (!mGeckoChild)
        return (mKeyDownHandled || mKeyPressHandled);
    }
  }

  // Let Cocoa interpret the key events, caching IsIMEComposing first.
  // We don't do it if this came from performKeyEquivalent because
  // interpretKeyEvents isn't set up to handle those key combinations.
  // XXX?
  bool wasComposing = nsTSMManager::IsComposing();
  bool interpretKeyEventsCalled = false;
  if (//!isKeyEquiv && // XXX? Cameron
      (nsTSMManager::IsIMEEnabled() || nsTSMManager::IsRomanKeyboardsOnly())) {
    [super interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
    interpretKeyEventsCalled = true;
  }

  if (!mGeckoChild) {
    return (mKeyDownHandled || mKeyPressHandled);
  }

  if (!mKeyPressSent && nonDeadKeyPress && !wasComposing &&
      !nsTSMManager::IsComposing()) {
    WidgetKeyboardEvent geckoKeypress(true, eKeyPress, mGeckoChild);
    [self convertCocoaKeyEvent:theEvent toGeckoEvent:&geckoKeypress];

    // If we called interpretKeyEvents and this isn't normal character input
    // then IME probably ate the event for some reason. We do not want to
    // send a key press event in that case.
    if (!(interpretKeyEventsCalled && IsNormalCharInputtingEvent(geckoKeypress))) {
      if (mKeyDownHandled) {
        geckoKeypress.mFlags.mDefaultPrevented = true;
      }
      mKeyPressHandled = mGeckoChild->DispatchWindowEvent(geckoKeypress);
    }
  }

  // Note: mGeckoChild might have become null here. Don't count on it from here on.

  bool handled = (mKeyDownHandled || mKeyPressHandled);

  // See note about nested event loops where these variables are declared in header.
  mKeyPressHandled = false;
  mKeyPressSent = NO;
  mCurKeyEvent = nil;
  mKeyDownHandled = false;

  return handled;

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(NO);
}

- (void)initTSMDocument
{
  if (!mGeckoChild)
    return;

  // We need to get actual focused view. E.g., the view is in bookmark dialog
  // that is <panel> element. Then, the key events are processed the parent
  // window's view that has native focus.
  WidgetQueryContentEvent textContent(true, eQueryTextContent,
                                  mGeckoChild);
  textContent.InitForQueryTextContent(0, 0);
  mGeckoChild->DispatchWindowEvent(textContent);
  NSView<mozView>* focusedView = self;
  if (textContent.mSucceeded && textContent.mReply.mFocusedWidget) {
    NSView<mozView>* view =
      static_cast<NSView<mozView>*>(textContent.mReply.mFocusedWidget->
                                    GetNativeData(NS_NATIVE_WIDGET));
    if (view)
      focusedView = view;
  }
  nsTSMManager::InitTSMDocument(focusedView);
}
// Double whew!
// End of NSTextInput

#pragma mark -

// This is a private API that Cocoa uses.
// Cocoa will call this after the menu system returns "NO" for "performKeyEquivalent:".
// We want all they key events we can get so just return YES. In particular, this fixes
// ctrl-tab - we don't get a "keyDown:" call for that without this.
- (BOOL)_wantsKeyDownForEvent:(NSEvent*)event
{
  return YES;
}

- (NSEvent*)lastKeyDownEvent
{
  return mLastKeyDownEvent;
}

// This is Leopard-specific.
#if(0)
- (void)keyDown:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  [mLastKeyDownEvent release];
  mLastKeyDownEvent = [theEvent retain];

  // Weird things can happen on keyboard input if the key window isn't in the
  // current space.  For example see bug 1056251.  To get around this, always
  // make sure that, if our window is key, it's also made frontmost.  Doing
  // this automatically switches to whatever space our window is in.  Safari
  // does something similar.  Our window should normally always be key --
  // otherwise why is the OS sending us a key down event?  But it's just
  // possible we're in Gecko's hidden window, so we check first.
  NSWindow *viewWindow = [self window];
  if (viewWindow && [viewWindow isKeyWindow]) {
    [viewWindow orderWindow:NSWindowAbove relativeTo:0];
  }

#if !defined(RELEASE_BUILD) || defined(DEBUG)
  if (!Preferences::GetBool("intl.allow-insecure-text-input", false) &&
      mGeckoChild && mTextInputHandler && mTextInputHandler->IsFocused()) {
#ifdef MOZ_CRASHREPORTER
    NSWindow* window = [self window];
    NSString* info = [NSString stringWithFormat:@"\nview [%@], window [%@], window is key %i, is fullscreen %i, app is active %i",
                      self, window, [window isKeyWindow], ([window styleMask] & (1 << 14)) != 0,
                      [NSApp isActive]];
    nsAutoCString additionalInfo([info UTF8String]);
#endif
    if (mGeckoChild->GetInputContext().IsPasswordEditor() &&
               !TextInputHandler::IsSecureEventInputEnabled()) {
      #define CRASH_MESSAGE "A password editor has focus, but not in secure input mode"
#ifdef MOZ_CRASHREPORTER
      CrashReporter::AppendAppNotesToCrashReport(NS_LITERAL_CSTRING("\nBug 893973: ") +
                                                 NS_LITERAL_CSTRING(CRASH_MESSAGE));
      CrashReporter::AppendAppNotesToCrashReport(additionalInfo);
#endif
      MOZ_CRASH(CRASH_MESSAGE);
      #undef CRASH_MESSAGE
    } else if (!mGeckoChild->GetInputContext().IsPasswordEditor() &&
               TextInputHandler::IsSecureEventInputEnabled()) {
      #define CRASH_MESSAGE "A non-password editor has focus, but in secure input mode"
#ifdef MOZ_CRASHREPORTER
      CrashReporter::AppendAppNotesToCrashReport(NS_LITERAL_CSTRING("\nBug 893973: ") +
                                                 NS_LITERAL_CSTRING(CRASH_MESSAGE));
      CrashReporter::AppendAppNotesToCrashReport(additionalInfo);
#endif
      MOZ_CRASH(CRASH_MESSAGE);
      #undef CRASH_MESSAGE
    }
  }
#endif // #if !defined(RELEASE_BUILD) || defined(DEBUG)

  nsAutoRetainCocoaObject kungFuDeathGrip(self);
  bool handled = false;
  if (mGeckoChild && mTextInputHandler) {
    handled = mTextInputHandler->HandleKeyDownEvent(theEvent);
  }

  // We always allow keyboard events to propagate to keyDown: but if they are not
  // handled we give special Application menu items a chance to act.
  if (!handled && sApplicationMenu) {
    [sApplicationMenu performKeyEquivalent:theEvent];
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)keyUp:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  NS_ENSURE_TRUE(mGeckoChild, );

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  mTextInputHandler->HandleKeyUpEvent(theEvent);

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)insertNewline:(id)sender
{
  if (mTextInputHandler) {
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:@"\n"];
    mTextInputHandler->InsertText(attrStr);
    [attrStr release];
  }
}

- (void)flagsChanged:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  NS_ENSURE_TRUE(mGeckoChild, );

  nsAutoRetainCocoaObject kungFuDeathGrip(self);
  mTextInputHandler->HandleFlagsChanged(theEvent);

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

#else
// Use the 7.0 code.

- (void)keyDown:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  bool handled = [self processKeyDownEvent:theEvent];

  // We always allow keyboard events to propagate to keyDown: but if they are not
  // handled we give special Application menu items a chance to act.
  if (!handled && sApplicationMenu) {
    [sApplicationMenu performKeyEquivalent:theEvent];
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

static BOOL keyUpAlreadySentKeyDown = NO;

- (void)keyUp:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

#ifdef PR_LOGGING
  nsAutoCString str1;
  nsAutoCString str2;
#endif
#if(0)
  PR_LOG(sCocoaLog, PR_LOG_ALWAYS,
         ("ChildView keyUp: keycode=%d,modifiers=%x,chars=%s,charsIgnoringModifiers=%s\n",
          nsCocoaUtils::GetCocoaEventKeyCode(theEvent),
          nsCocoaUtils::GetCocoaEventModifierFlags(theEvent),
          ToEscapedString([theEvent characters], str1),
          ToEscapedString([theEvent charactersIgnoringModifiers], str2)));
#endif
  if (!mGeckoChild)
    return;

  if (mIgnoreNextKeyUpEvent) {
    mIgnoreNextKeyUpEvent = NO;
    return;
  }

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  // if we don't have any characters we can't generate a keyUp event
  if ([[theEvent characters] length] == 0 ||
      nsTSMManager::IsComposing()) {
    return;
  }

  // Cocoa doesn't send an NSKeyDown event for control-tab on 10.4, so if this
  // is an NSKeyUp event for control-tab, send a down event to gecko first.
  if (!nsCocoaFeatures::OnLeopardOrLater() && !keyUpAlreadySentKeyDown &&
      nsCocoaUtils::GetCocoaEventModifierFlags(theEvent) & NSControlKeyMask &&
      nsCocoaUtils::GetCocoaEventKeyCode(theEvent) == kTabKeyCode) {
    // We'll need an NSKeyDown copy of our native event so we convert to a gecko event correctly.
    NSEvent* nativeKeyDownEvent = [ChildView makeNewCocoaEventWithType:NSKeyDown fromEvent:theEvent];

    // send a key down event if we should
    bool keyDownHandled = false;
    if (![nativeKeyDownEvent isARepeat]) {
      WidgetKeyboardEvent geckoEvent(true, eKeyDown, mGeckoChild);
      [self convertCocoaKeyEvent:nativeKeyDownEvent toGeckoEvent:&geckoEvent];

      keyDownHandled = mGeckoChild->DispatchWindowEvent(geckoEvent);
      if (!mGeckoChild)
        return;
    }

    // Check to see if we are still the first responder.
    // The key down event may have shifted the focus, in which
    // case we should not fire the key press.
    NSResponder* resp = [[self window] firstResponder];
    if (resp != (NSResponder*)self) {
      keyUpAlreadySentKeyDown = YES;
      [resp keyUp:theEvent];      
      keyUpAlreadySentKeyDown = NO;
      return;
    }

    // now send a key press event if we should
    WidgetKeyboardEvent geckoEvent(true, eKeyPress, mGeckoChild);
    [self convertCocoaKeyEvent:nativeKeyDownEvent toGeckoEvent:&geckoEvent];
    if (keyDownHandled)
      geckoEvent.mFlags.mDefaultPrevented = true;

    mGeckoChild->DispatchWindowEvent(geckoEvent);
    if (!mGeckoChild)
      return;
  }

  WidgetKeyboardEvent geckoEvent(true, eKeyUp, mGeckoChild);
  [self convertCocoaKeyEvent:theEvent toGeckoEvent:&geckoEvent];

  mGeckoChild->DispatchWindowEvent(geckoEvent);

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)flagsChanged:(NSEvent*)theEvent
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!mGeckoChild)
    return;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  // CapsLock state and other modifier states are different:
  // CapsLock state does not revert when the CapsLock key goes up, as the
  // modifier state does for other modifier keys on key up.
  if ([theEvent keyCode] == kCapsLockKeyCode) {
    // Fire key down event for caps lock.
    [self fireKeyEventForFlagsChanged:theEvent keyDown:YES];
    if (!mGeckoChild)
      return;
    // XXX should we fire keyup event too? The keyup event for CapsLock key
    // is never sent to gecko.
  } else if ([theEvent type] == NSFlagsChanged) {
    // Fire key up/down events for the modifier keys (shift, alt, ctrl, command).
unsigned int modifiers = nsCocoaUtils::GetCocoaEventModifierFlags(theEvent) & NSDeviceIndependentModifierFlagsMask;
    const uint32_t kModifierMaskTable[] =
      { NSShiftKeyMask, NSControlKeyMask, NSAlternateKeyMask, NSCommandKeyMask };
    const uint32_t kModifierCount = sizeof(kModifierMaskTable) /
                                    sizeof(kModifierMaskTable[0]);

    for (uint32_t i = 0; i < kModifierCount; i++) {
      uint32_t modifierBit = kModifierMaskTable[i];
      if ((modifiers & modifierBit) != (gLastModifierState & modifierBit)) {
        BOOL isKeyDown = (modifiers & modifierBit) != 0 ? YES : NO;

        [self fireKeyEventForFlagsChanged:theEvent keyDown:isKeyDown];

        if (!mGeckoChild)
          return;

        // Stop if focus has changed.
        // Check to see if we are still the first responder.
        if (![self isFirstResponder])
          break;
      }
    }

    gLastModifierState = modifiers;
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)fireKeyEventForFlagsChanged:(NSEvent*)theEvent keyDown:(BOOL)isKeyDown
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!mGeckoChild || [theEvent type] != NSFlagsChanged ||
	nsTSMManager::IsComposing()) return;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  uint32_t message = isKeyDown ? eKeyDown : eKeyUp;

  NPCocoaEvent cocoaEvent;
	
  // Fire a key event.
  WidgetKeyboardEvent geckoEvent(true, message, mGeckoChild);
  [self convertCocoaKeyEvent:theEvent toGeckoEvent:&geckoEvent];

  mGeckoChild->DispatchWindowEvent(geckoEvent);

  NS_OBJC_END_TRY_ABORT_BLOCK;
}
#endif

- (BOOL) isFirstResponder
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  NSResponder* resp = [[self window] firstResponder];
  return (resp == (NSResponder*)self);

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(NO);
}

- (BOOL)isDragInProgress
{
  if (!mDragService)
    return NO;

  nsCOMPtr<nsIDragSession> dragSession;
  mDragService->GetCurrentSession(getter_AddRefs(dragSession));
  return dragSession != nullptr;
}

- (BOOL)inactiveWindowAcceptsMouseEvent:(NSEvent*)aEvent
{
  // 10.4Fx issue 19, see below
  OSStatus err;
  ProcessSerialNumber psn = { 0, kCurrentProcess };

  // If we're being destroyed assume the default -- return YES.
  if (!mGeckoChild)
    return YES;

  // Do not accept non-click events, because we get tooltips and other things.
  // 10.4Fx issue 19, issue 168
  if (([aEvent type] != NSLeftMouseDown && [aEvent type] != NSRightMouseDown))
    return NO;

  // Activate just this window, if we're not foreground. 10.4Fx issue 19.
    err = SetFrontProcessWithOptions(&psn, kSetFrontProcessFrontWindowOnly);
    nsWindowType wType = mGeckoChild->WindowType();
    NSWindow *swin = [self window];
    if (swin && ![swin parentWindow] &&
               ![swin attachedSheet] &&
               wType != eWindowType_popup &&
               wType != eWindowType_dialog &&
               wType != eWindowType_sheet) {
       // Make it main, then make it key. This dance seems reliable.
       // Note, however, that most of the time we are NOT entering this code.
       // Most of our window stuff goes through ::WindowAcceptsEvent, even
       // if the window is "inactive."
       [swin makeMainWindow];
       [swin makeKeyWindow];
       [swin orderFrontRegardless]; // safe, because we are the
               // front app, the main window *and* the key window.
  }

  WidgetMouseEvent geckoEvent(true, eMouseActivate, mGeckoChild,
                              WidgetMouseEvent::eReal);
  [self convertCocoaMouseEvent:aEvent toGeckoEvent:&geckoEvent];
  return (mGeckoChild->DispatchInputEvent(&geckoEvent) != nsEventStatus_eConsumeNoDefault);
}

// We must always call through to our superclass, even when mGeckoChild is
// nil -- otherwise the keyboard focus can end up in the wrong NSView.
- (BOOL)becomeFirstResponder
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  return [super becomeFirstResponder];

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(YES);
}

- (void)viewsWindowDidBecomeKey
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!mGeckoChild)
    return;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  // check to see if the window implements the mozWindow protocol. This
  // allows embedders to avoid re-entrant calls to -makeKeyAndOrderFront,
  // which can happen because these activate calls propagate out
  // to the embedder via nsIEmbeddingSiteWindow::SetFocus().
  BOOL isMozWindow = [[self window] respondsToSelector:@selector(setSuppressMakeKeyFront:)];
  if (isMozWindow)
    [[self window] setSuppressMakeKeyFront:YES];

  nsIWidgetListener* listener = mGeckoChild->GetWidgetListener();
  if (listener)
    listener->WindowActivated();

  if (isMozWindow)
    [[self window] setSuppressMakeKeyFront:NO];

#if(0)
  if (mGeckoChild->GetInputContext().IsPasswordEditor()) {
    TextInputHandler::EnableSecureEventInput();
  } else {
    TextInputHandler::EnsureSecureEventInputDisabled();
  }
#else
  if (mGeckoChild->GetInputContext().IsPasswordEditor())
  	ChildViewEnableSecureEventInput();
  else
  	ChildViewEnsureSecureEventInputDisabled();
#endif

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

- (void)viewsWindowDidResignKey
{
  if (!mGeckoChild)
    return;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  nsIWidgetListener* listener = mGeckoChild->GetWidgetListener();
  if (listener)
    listener->WindowDeactivated();

#if(0)
  TextInputHandler::EnsureSecureEventInputDisabled();
#else
  ChildViewEnsureSecureEventInputDisabled();
#endif
}

// If the call to removeFromSuperview isn't delayed from nsChildView::
// TearDownView(), the NSView hierarchy might get changed during calls to
// [ChildView drawRect:], which leads to "beyond bounds" exceptions in
// NSCFArray.  For more info see bmo bug 373122.  Apple's docs claim that
// removeFromSuperviewWithoutNeedingDisplay "can be safely invoked during
// display" (whatever "display" means).  But it's _not_ true that it can be
// safely invoked during calls to [NSView drawRect:].  We use
// removeFromSuperview here because there's no longer any danger of being
// "invoked during display", and because doing do clears up bmo bug 384343.
- (void)delayedTearDown
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  [self removeFromSuperview];
  [self release];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

#pragma mark -

// drag'n'drop stuff
#define kDragServiceContractID "@mozilla.org/widget/dragservice;1"

- (NSDragOperation)dragOperationFromDragAction:(int32_t)aDragAction
{
  if (nsIDragService::DRAGDROP_ACTION_LINK & aDragAction)
    return NSDragOperationLink;
  if (nsIDragService::DRAGDROP_ACTION_COPY & aDragAction)
    return NSDragOperationCopy;
  if (nsIDragService::DRAGDROP_ACTION_MOVE & aDragAction)
    return NSDragOperationGeneric;
  return NSDragOperationNone;
}

- (LayoutDeviceIntPoint)convertWindowCoordinates:(NSPoint)aPoint
{
  if (!mGeckoChild) {
    return LayoutDeviceIntPoint(0, 0);
  }

  NSPoint localPoint = [self convertPoint:aPoint fromView:nil];
  return mGeckoChild->CocoaPointsToDevPixels(localPoint);
}

- (APZCTreeManager*)apzctm
{
  return mGeckoChild ? mGeckoChild->APZCTM() : nullptr;
}

// This is a utility function used by NSView drag event methods
// to send events. It contains all of the logic needed for Gecko
// dragging to work. Returns the appropriate cocoa drag operation code.
- (NSDragOperation)doDragAction:(EventMessage)aMessage sender:(id)aSender
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  if (!mGeckoChild)
    return NSDragOperationNone;

  MOZ_LOG(sCocoaLog, LogLevel::Info, ("ChildView doDragAction: entered\n"));

  if (!mDragService) {
    CallGetService(kDragServiceContractID, &mDragService);
    NS_ASSERTION(mDragService, "Couldn't get a drag service - big problem!");
    if (!mDragService)
      return NSDragOperationNone;
  }

  if (aMessage == eDragEnter) {
    mDragService->StartDragSession();
  }

  nsCOMPtr<nsIDragSession> dragSession;
  mDragService->GetCurrentSession(getter_AddRefs(dragSession));
  if (dragSession) {
    if (aMessage == eDragOver) {
      // fire the drag event at the source. Just ignore whether it was
      // cancelled or not as there isn't actually a means to stop the drag
      mDragService->FireDragEventAtSource(eDrag);
      dragSession->SetCanDrop(false);
    } else if (aMessage == eDrop) {
      // We make the assumption that the dragOver handlers have correctly set
      // the |canDrop| property of the Drag Session.
      bool canDrop = false;
      if (!NS_SUCCEEDED(dragSession->GetCanDrop(&canDrop)) || !canDrop) {
        [self doDragAction:eDragExit sender:aSender];

        nsCOMPtr<nsIDOMNode> sourceNode;
        dragSession->GetSourceNode(getter_AddRefs(sourceNode));
        if (!sourceNode) {
          mDragService->EndDragSession(false);
        }
        return NSDragOperationNone;
      }
    }

    unsigned int modifierFlags = nsCocoaUtils::GetCocoaEventModifierFlags([NSApp currentEvent]);
    uint32_t action = nsIDragService::DRAGDROP_ACTION_MOVE;
    // force copy = option, alias = cmd-option, default is move
    if (modifierFlags & NSAlternateKeyMask) {
      if (modifierFlags & NSCommandKeyMask)
        action = nsIDragService::DRAGDROP_ACTION_LINK;
      else
        action = nsIDragService::DRAGDROP_ACTION_COPY;
    }
    dragSession->SetDragAction(action);
  }

  // set up gecko event
  WidgetDragEvent geckoEvent(true, aMessage, mGeckoChild);
  nsCocoaUtils::InitInputEvent(geckoEvent, [NSApp currentEvent]);

  // Use our own coordinates in the gecko event.
  // Convert event from gecko global coords to gecko view coords.
  NSPoint draggingLoc = [aSender draggingLocation];

  geckoEvent.refPoint = [self convertWindowCoordinates:draggingLoc];

  nsAutoRetainCocoaObject kungFuDeathGrip(self);
  mGeckoChild->DispatchInputEvent(&geckoEvent);
  if (!mGeckoChild)
    return NSDragOperationNone;

  if (dragSession) {
    switch (aMessage) {
      case eDragEnter:
      case eDragOver: {
        uint32_t dragAction;
        dragSession->GetDragAction(&dragAction);

        // If TakeChildProcessDragAction returns something other than
        // DRAGDROP_ACTION_UNINITIALIZED, it means that the last event was sent
        // to the child process and this event is also being sent to the child
        // process. In this case, use the last event's action instead.
        nsDragService* dragService = static_cast<nsDragService *>(mDragService);
        int32_t childDragAction = dragService->TakeChildProcessDragAction();
        if (childDragAction != nsIDragService::DRAGDROP_ACTION_UNINITIALIZED) {
          dragAction = childDragAction;
        }

        return [self dragOperationFromDragAction:dragAction];
      }
      case eDragExit:
      case eDrop: {
        nsCOMPtr<nsIDOMNode> sourceNode;
        dragSession->GetSourceNode(getter_AddRefs(sourceNode));
        if (!sourceNode) {
          // We're leaving a window while doing a drag that was
          // initiated in a different app. End the drag session,
          // since we're done with it for now (until the user
          // drags back into mozilla).
          mDragService->EndDragSession(false);
        }
      }
      default:
        break;
    }
  }

  return NSDragOperationGeneric;

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(NSDragOperationNone);
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  MOZ_LOG(sCocoaLog, LogLevel::Info, ("ChildView draggingEntered: entered\n"));

  // there should never be a globalDragPboard when "draggingEntered:" is
  // called, but just in case we'll take care of it here.
  [globalDragPboard release];

  // Set the global drag pasteboard that will be used for this drag session.
  // This will be set back to nil when the drag session ends (mouse exits
  // the view or a drop happens within the view).
// restore bug 966986
#if(0)
  globalDragPboard = [[sender draggingPasteboard] retain];
#else
  globalDragPboard =
    [[NSPasteboardWrapper alloc] initWithPasteboard:[sender draggingPasteboard]];
#endif

  return [self doDragAction:eDragEnter sender:sender];

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(NSDragOperationNone);
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
  MOZ_LOG(sCocoaLog, LogLevel::Info, ("ChildView draggingUpdated: entered\n"));

  return [self doDragAction:eDragOver sender:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
  MOZ_LOG(sCocoaLog, LogLevel::Info, ("ChildView draggingExited: entered\n"));

  nsAutoRetainCocoaObject kungFuDeathGrip(self);
  [self doDragAction:eDragExit sender:sender];
  NS_IF_RELEASE(mDragService);
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
  nsAutoRetainCocoaObject kungFuDeathGrip(self);
  BOOL handled = [self doDragAction:eDrop sender:sender] != NSDragOperationNone;
  NS_IF_RELEASE(mDragService);
  return handled;
}

// NSDraggingSource
- (void)draggedImage:(NSImage *)anImage movedTo:(NSPoint)aPoint
{
  // Get the drag service if it isn't already cached. The drag service
  // isn't cached when dragging over a different application.
  nsCOMPtr<nsIDragService> dragService = mDragService;
  if (!dragService) {
    dragService = do_GetService(kDragServiceContractID);
  }

  if (dragService) {
    NSPoint pnt = [NSEvent mouseLocation];
    FlipCocoaScreenCoordinate(pnt);

    LayoutDeviceIntPoint devPoint = mGeckoChild->CocoaPointsToDevPixels(pnt);
    dragService->DragMoved(devPoint.x, devPoint.y);
  }
}

// NSDraggingSource
- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  gDraggedTransferables = nullptr;

  NSEvent *currentEvent = [NSApp currentEvent];
  gUserCancelledDrag = ([currentEvent type] == NSKeyDown &&
                        [currentEvent keyCode] == kEscapeKeyCode); // kVK_Escape); // we use the old key constants; see bug 764285

  if (!mDragService) {
    CallGetService(kDragServiceContractID, &mDragService);
    NS_ASSERTION(mDragService, "Couldn't get a drag service - big problem!");
  }

  if (mDragService) {
    // set the dragend point from the current mouse location
    nsDragService* dragService = static_cast<nsDragService *>(mDragService);
    NSPoint pnt = [NSEvent mouseLocation];
    FlipCocoaScreenCoordinate(pnt);
    dragService->SetDragEndPoint(nsIntPoint(NSToIntRound(pnt.x), NSToIntRound(pnt.y)));

    // XXX: dropEffect should be updated per |operation|.
    // As things stand though, |operation| isn't well handled within "our"
    // events, that is, when the drop happens within the window: it is set
    // either to NSDragOperationGeneric or to NSDragOperationNone.
    // For that reason, it's not yet possible to override dropEffect per the
    // given OS value, and it's also unclear what's the correct dropEffect
    // value for NSDragOperationGeneric that is passed by other applications.
    // All that said, NSDragOperationNone is still reliable.
    if (operation == NSDragOperationNone) {
      nsCOMPtr<nsIDOMDataTransfer> dataTransfer;
      dragService->GetDataTransfer(getter_AddRefs(dataTransfer));
      if (dataTransfer)
        dataTransfer->SetDropEffectInt(nsIDragService::DRAGDROP_ACTION_NONE);
    }

    mDragService->EndDragSession(true);
    NS_RELEASE(mDragService);
  }

  [globalDragPboard release];
  globalDragPboard = nil;
  [gLastDragMouseDownEvent release];
  gLastDragMouseDownEvent = nil;

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

// NSDraggingSource
// this is just implemented so we comply with the NSDraggingSource informal protocol
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
  return UINT_MAX;
}

// This method is a callback typically invoked in response to a drag ending on the desktop
// or a Findow folder window; the argument passed is a path to the drop location, to be used
// in constructing a complete pathname for the file(s) we want to create as a result of
// the drag.
- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL*)dropDestination
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  nsresult rv;

  MOZ_LOG(sCocoaLog, LogLevel::Info, ("ChildView namesOfPromisedFilesDroppedAtDestination: entering callback for promised files\n"));

  nsCOMPtr<nsIFile> targFile;
  NS_NewLocalFile(EmptyString(), true, getter_AddRefs(targFile));
  nsCOMPtr<nsILocalFileMac> macLocalFile = do_QueryInterface(targFile);
  if (!macLocalFile) {
    NS_ERROR("No Mac local file");
    return nil;
  }

  if (!NS_SUCCEEDED(macLocalFile->InitWithCFURL((CFURLRef)dropDestination))) {
    NS_ERROR("failed InitWithCFURL");
    return nil;
  }

  if (!gDraggedTransferables)
    return nil;

  uint32_t transferableCount;
  rv = gDraggedTransferables->Count(&transferableCount);
  if (NS_FAILED(rv))
    return nil;

  for (uint32_t i = 0; i < transferableCount; i++) {
    nsCOMPtr<nsISupports> genericItem;
    gDraggedTransferables->GetElementAt(i, getter_AddRefs(genericItem));
    nsCOMPtr<nsITransferable> item(do_QueryInterface(genericItem));
    if (!item) {
      NS_ERROR("no transferable");
      return nil;
    }

    item->SetTransferData(kFilePromiseDirectoryMime, macLocalFile, sizeof(nsIFile*));

    // now request the kFilePromiseMime data, which will invoke the data provider
    // If successful, the returned data is a reference to the resulting file.
    nsCOMPtr<nsISupports> fileDataPrimitive;
    uint32_t dataSize = 0;
    item->GetTransferData(kFilePromiseMime, getter_AddRefs(fileDataPrimitive), &dataSize);
  }

  NSPasteboard* generalPboard = [NSPasteboard pasteboardWithName:NSDragPboard];
  NSData* data = [generalPboard dataForType:@"application/x-moz-file-promise-dest-filename"];
  NSString* name = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  NSArray* rslt = [NSArray arrayWithObject:name];

  [name release];

  return rslt;

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}

#pragma mark -

// Support for the "Services" menu. We currently only support sending strings
// and HTML to system services.

- (id)validRequestorForSendType:(NSString *)sendType
                     returnType:(NSString *)returnType
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  // sendType contains the type of data that the service would like this
  // application to send to it.  sendType is nil if the service is not
  // requesting any data.
  //
  // returnType contains the type of data the the service would like to
  // return to this application (e.g., to overwrite the selection).
  // returnType is nil if the service will not return any data.
  //
  // The following condition thus triggers when the service expects a string
  // or HTML from us or no data at all AND when the service will either not
  // send back any data to us or will send a string or HTML back to us.

#define IsSupportedType(typeStr) ([typeStr isEqual:NSStringPboardType] || [typeStr isEqual:NSHTMLPboardType])

  id result = nil;

  if ((!sendType || IsSupportedType(sendType)) &&
      (!returnType || IsSupportedType(returnType))) {
    if (mGeckoChild) {
      // Assume that this object will be able to handle this request.
      result = self;

      // Keep the ChildView alive during this operation.
      nsAutoRetainCocoaObject kungFuDeathGrip(self);

      // Determine if there is a selection (if sending to the service).
      if (sendType) {
        WidgetQueryContentEvent event(true, eQueryContentState, mGeckoChild);
        // This might destroy our widget (and null out mGeckoChild).
        mGeckoChild->DispatchWindowEvent(event);
        if (!mGeckoChild || !event.mSucceeded || !event.mReply.mHasSelection)
          result = nil;
      }

      // Determine if we can paste (if receiving data from the service).
      if (mGeckoChild && returnType) {
        WidgetContentCommandEvent command(true,
                                          eContentCommandPasteTransferable,
                                          mGeckoChild, true);
        // This might possibly destroy our widget (and null out mGeckoChild).
        mGeckoChild->DispatchWindowEvent(command);
        if (!mGeckoChild || !command.mSucceeded || !command.mIsEnabled)
          result = nil;
      }
    }
  }

#undef IsSupportedType

  // Give the superclass a chance if this object will not handle this request.
  if (!result)
    result = [super validRequestorForSendType:sendType returnType:returnType];

  return result;

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
                             types:(NSArray *)types
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);

  // Make sure that the service will accept strings or HTML.
  if ([types containsObject:NSStringPboardType] == NO &&
      [types containsObject:NSHTMLPboardType] == NO)
    return NO;

  // Bail out if there is no Gecko object.
  if (!mGeckoChild)
    return NO;

  // Obtain the current selection.
  WidgetQueryContentEvent event(true, eQuerySelectionAsTransferable,
                                mGeckoChild);
  mGeckoChild->DispatchWindowEvent(event);
  if (!event.mSucceeded || !event.mReply.mTransferable)
    return NO;

  // Transform the transferable to an NSDictionary.
  NSDictionary* pasteboardOutputDict = nsClipboard::PasteboardDictFromTransferable(event.mReply.mTransferable);
  if (!pasteboardOutputDict)
    return NO;

  // Declare the pasteboard types.
  unsigned int typeCount = [pasteboardOutputDict count];
  NSMutableArray* declaredTypes = [NSMutableArray arrayWithCapacity:typeCount];
  [declaredTypes addObjectsFromArray:[pasteboardOutputDict allKeys]];
  [pboard declareTypes:declaredTypes owner:nil];

  // Write the data to the pasteboard.
  for (unsigned int i = 0; i < typeCount; i++) {
    NSString* currentKey = [declaredTypes objectAtIndex:i];
    id currentValue = [pasteboardOutputDict valueForKey:currentKey];

    if (currentKey == NSStringPboardType ||
        currentKey == kCorePboardType_url ||
        currentKey == kCorePboardType_urld ||
        currentKey == kCorePboardType_urln) {
      [pboard setString:currentValue forType:currentKey];
    } else if (currentKey == NSHTMLPboardType) {
      [pboard setString:(nsClipboard::WrapHtmlForSystemPasteboard(currentValue)) forType:currentKey];
    } else if (currentKey == NSTIFFPboardType) {
      [pboard setData:currentValue forType:currentKey];
    } else if (currentKey == NSFilesPromisePboardType) {
      [pboard setPropertyList:currentValue forType:currentKey];
    }
  }

  return YES;

  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(NO);
}

// Called if the service wants us to replace the current selection.
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard
{
  nsresult rv;
  nsCOMPtr<nsITransferable> trans = do_CreateInstance("@mozilla.org/widget/transferable;1", &rv);
  if (NS_FAILED(rv))
    return NO;
  trans->Init(nullptr);

  trans->AddDataFlavor(kUnicodeMime);
  trans->AddDataFlavor(kHTMLMime);

  rv = nsClipboard::TransferableFromPasteboard(trans, pboard);
  if (NS_FAILED(rv))
    return NO;

  NS_ENSURE_TRUE(mGeckoChild, false);

  WidgetContentCommandEvent command(true,
                                    eContentCommandPasteTransferable,
                                    mGeckoChild);
  command.mTransferable = trans;
  mGeckoChild->DispatchWindowEvent(command);

  return command.mSucceeded && command.mIsEnabled;
}

#pragma mark -

#ifdef ACCESSIBILITY

/* Every ChildView has a corresponding mozDocAccessible object that is doing all
   the heavy lifting. The topmost ChildView corresponds to a mozRootAccessible
   object.

   All ChildView needs to do is to route all accessibility calls (from the NSAccessibility APIs)
   down to its object, pretending that they are the same.
*/
- (id<mozAccessible>)accessible
{
  if (!mGeckoChild)
    return nil;

  id<mozAccessible> nativeAccessible = nil;

  nsAutoRetainCocoaObject kungFuDeathGrip(self);
  nsCOMPtr<nsIWidget> kungFuDeathGrip2(mGeckoChild);
  RefPtr<a11y::Accessible> accessible = mGeckoChild->GetDocumentAccessible();
  if (!accessible)
    return nil;

  accessible->GetNativeInterface((void**)&nativeAccessible);

#ifdef DEBUG_hakan
  NSAssert(![nativeAccessible isExpired], @"native acc is expired!!!");
#endif

  return nativeAccessible;
}

/* Implementation of formal mozAccessible formal protocol (enabling mozViews
   to talk to mozAccessible objects in the accessibility module). */

- (BOOL)hasRepresentedView
{
  return YES;
}

- (id)representedView
{
  return self;
}

- (BOOL)isRoot
{
  return [[self accessible] isRoot];
}

#ifdef DEBUG
- (void)printHierarchy
{
  [[self accessible] printHierarchy];
}
#endif

#pragma mark -

// general

- (BOOL)accessibilityIsIgnored
{
  if (!mozilla::a11y::ShouldA11yBeEnabled())
    return [super accessibilityIsIgnored];

  return [[self accessible] accessibilityIsIgnored];
}

- (id)accessibilityHitTest:(NSPoint)point
{
  if (!mozilla::a11y::ShouldA11yBeEnabled())
    return [super accessibilityHitTest:point];

  return [[self accessible] accessibilityHitTest:point];
}

- (id)accessibilityFocusedUIElement
{
  if (!mozilla::a11y::ShouldA11yBeEnabled())
    return [super accessibilityFocusedUIElement];

  return [[self accessible] accessibilityFocusedUIElement];
}

// actions

- (NSArray*)accessibilityActionNames
{
  if (!mozilla::a11y::ShouldA11yBeEnabled())
    return [super accessibilityActionNames];

  return [[self accessible] accessibilityActionNames];
}

- (NSString*)accessibilityActionDescription:(NSString*)action
{
  if (!mozilla::a11y::ShouldA11yBeEnabled())
    return [super accessibilityActionDescription:action];

  return [[self accessible] accessibilityActionDescription:action];
}

- (void)accessibilityPerformAction:(NSString*)action
{
  if (!mozilla::a11y::ShouldA11yBeEnabled())
    return [super accessibilityPerformAction:action];

  return [[self accessible] accessibilityPerformAction:action];
}

// attributes

- (NSArray*)accessibilityAttributeNames
{
  if (!mozilla::a11y::ShouldA11yBeEnabled())
    return [super accessibilityAttributeNames];

  return [[self accessible] accessibilityAttributeNames];
}

- (BOOL)accessibilityIsAttributeSettable:(NSString*)attribute
{
  if (!mozilla::a11y::ShouldA11yBeEnabled())
    return [super accessibilityIsAttributeSettable:attribute];

  return [[self accessible] accessibilityIsAttributeSettable:attribute];
}

- (id)accessibilityAttributeValue:(NSString*)attribute
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  if (!mozilla::a11y::ShouldA11yBeEnabled())
    return [super accessibilityAttributeValue:attribute];

  id<mozAccessible> accessible = [self accessible];

  // if we're the root (topmost) accessible, we need to return our native AXParent as we
  // traverse outside to the hierarchy of whoever embeds us. thus, fall back on NSView's
  // default implementation for this attribute.
  if ([attribute isEqualToString:NSAccessibilityParentAttribute] && [accessible isRoot]) {
    id parentAccessible = [super accessibilityAttributeValue:attribute];
    return parentAccessible;
  }

  return [accessible accessibilityAttributeValue:attribute];

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}

#endif /* ACCESSIBILITY */

@end

#ifndef NS_LEOPARD_AND_LATER

#pragma mark -

void
nsTSMManager::OnDestroyView(NSView<mozView>* aDestroyingView)
{
  if (aDestroyingView != sComposingView)
    return;
  if (IsComposing()) {
    CancelIME(); // XXX Might CancelIME() fail because sComposingView is being destroyed?
    EndComposing();
  }
}

bool
nsTSMManager::GetIMEOpenState()
{
  return GetScriptManagerVariable(smKeyScript) != smRoman ? true : false;
}

static const NSString* GetCurrentIMELanguage()
{
  if (!nsCocoaFeatures::OnLeopardOrLater()) {
    // XXX [[NSInputManager currentInputManager] language] doesn't work fine.
    switch (::GetScriptManagerVariable(smKeyScript)) {
      case smJapanese:
        return @"ja";
      default:
        return nil;
    }
  }

  NS_PRECONDITION(Leopard_TISCopyCurrentKeyboardInputSource,
    "Leopard_TISCopyCurrentKeyboardInputSource is not initialized");
  TISInputSourceRef inputSource = Leopard_TISCopyCurrentKeyboardInputSource();
  if (!inputSource) {
    NS_ERROR("Leopard_TISCopyCurrentKeyboardInputSource failed");
    return nil;
  }

  NS_PRECONDITION(Leopard_TISGetInputSourceProperty,
    "Leopard_TISGetInputSourceProperty is not initialized");
  CFArrayRef langs = static_cast<CFArrayRef>(
    Leopard_TISGetInputSourceProperty(inputSource,
                                      kOurTISPropertyInputSourceLanguages));
  return static_cast<const NSString*>(CFArrayGetValueAtIndex(langs, 0));
}

void
nsTSMManager::InitTSMDocument(NSView<mozView>* aViewForCaret)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  sDocumentID = ::TSMGetActiveDocument();
  if (!sDocumentID)
    return;

  // We need to set the focused window level to TSMDocument. Then, the popup
  // windows of IME (E.g., a candidate list window) will be over the focused
  // view. See http://developer.apple.com/technotes/tn2005/tn2128.html#TNTAG1
  NSInteger TSMLevel, windowLevel;
  UInt32 size = sizeof(TSMLevel);

  OSStatus err =
    ::TSMGetDocumentProperty(sDocumentID, kTSMDocumentWindowLevelPropertyTag,
                             size, &size, &TSMLevel);
  windowLevel = [[aViewForCaret window] level];

  // Chinese IMEs on 10.5 don't work fine if the level is NSNormalWindowLevel,
  // then, we need to increment the value.
  if (windowLevel == NSNormalWindowLevel)
    windowLevel++;

  if (err == noErr && TSMLevel >= windowLevel)
    return;
  ::TSMSetDocumentProperty(sDocumentID, kTSMDocumentWindowLevelPropertyTag,
                           sizeof(windowLevel), &windowLevel);

  // ATOK (Japanese IME) updates the window level at activating,
  // we need to notify the change with this hack.
  const NSString* lang = ::GetCurrentIMELanguage();
  if (lang && [lang isEqualToString:@"ja"]) {
    ::DeactivateTSMDocument(sDocumentID);
    ::ActivateTSMDocument(sDocumentID);
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

void
nsTSMManager::StartComposing(NSView<mozView>* aComposingView)
{
  if (sComposingView && sComposingView != sComposingView)
    CommitIME();
  sComposingView = aComposingView;
  NS_ASSERTION(::TSMGetActiveDocument() == sDocumentID,
               "We didn't initialize the TSMDocument");
}

void
nsTSMManager::UpdateComposing(NSString* aComposingString)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (sComposingString)
    [sComposingString release];
  sComposingString = [aComposingString retain];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

void
nsTSMManager::EndComposing()
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  sComposingView = nullptr;
  if (sComposingString) {
    [sComposingString release];
    sComposingString = nullptr;
  }

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

void
nsTSMManager::EnableIME(bool aEnable)
{
  if (aEnable == sIsIMEEnabled)
    return;
  CommitIME();
  sIsIMEEnabled = aEnable;
}

void
nsTSMManager::SetIMEOpenState(bool aOpen)
{
  if (aOpen == GetIMEOpenState())
    return;
  CommitIME();
  KeyScript(aOpen ? smKeySwapScript : smKeyRoman);
}

nsresult
nsTSMManager::SetIMEEnabled(uint32_t aEnabled)
{
  switch (aEnabled) {
    case IMEState::ENABLED:
    case IMEState::PLUGIN:
      SetRomanKeyboardsOnly(false);
      EnableIME(true);
      break;
    case IMEState::DISABLED:
      SetRomanKeyboardsOnly(false);
      EnableIME(false);
      break;
    case IMEState::PASSWORD:
      SetRomanKeyboardsOnly(true);
      EnableIME(false);
      break;
    default:
      NS_ERROR("not implemented!");
      return NS_ERROR_UNEXPECTED;
  }
  sIMEEnabledStatus = aEnabled;
  return NS_OK;
}

#define ENABLE_ROMAN_KYBDS_ONLY -23
void
nsTSMManager::SetRomanKeyboardsOnly(bool aRomanOnly)
{
  CommitIME();

  if (sIMEEnabledStatus != IMEState::PLUGIN &&
      sIsRomanKeyboardsOnly == aRomanOnly) {
    return;
  }

  sIsRomanKeyboardsOnly = aRomanOnly;
  CallKeyScriptAPI();
}

void
nsTSMManager::CallKeyScriptAPI()
{
  // If timer has been alreay enabled, we don't need to recreate it.
  if (sSyncKeyScriptTimer) {
    return;
  }

  nsCOMPtr<nsITimer> timer = do_CreateInstance(NS_TIMER_CONTRACTID);
  NS_ENSURE_TRUE(timer, );
  NS_ADDREF(sSyncKeyScriptTimer = timer);
  sSyncKeyScriptTimer->InitWithFuncCallback(SyncKeyScript, nullptr, 0,
                                            nsITimer::TYPE_ONE_SHOT);
}

void
nsTSMManager::SyncKeyScript(nsITimer* aTimer, void* aClosure)
{
  // This is a workaround of Bug 548480 for Snow Leopard.
  //
  // KeyScript may cause the crash in CFHash.  We need call
  // [NSInputManager currentInputManager] before it.
  [NSInputManager currentInputManager];
 
  KeyScript(sIsRomanKeyboardsOnly ? ENABLE_ROMAN_KYBDS_ONLY : smKeyEnableKybds);
  NS_RELEASE(sSyncKeyScriptTimer);
}

void
nsTSMManager::Shutdown()
{
  if (!sSyncKeyScriptTimer) {
    return;
  }
  sSyncKeyScriptTimer->Cancel();
  NS_RELEASE(sSyncKeyScriptTimer);
}

void
nsTSMManager::KillComposing()
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  // Force commit the current composition
  // XXX Don't use NSInputManager. Because it cannot control the non-forcused
  // input manager, therefore, on deactivating a window, it does not work fine.
  NS_ASSERTION(sDocumentID, "The TSMDocumentID is null");
  ::FixTSMDocument(sDocumentID);

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

void
nsTSMManager::CommitIME()
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!IsComposing())
    return;
  KillComposing();
  if (!IsComposing())
    return;
  // If the composing transaction is still there, KillComposing only kills the
  // composing in TSM. We also need to kill the our composing transaction too.
  NSAttributedString* str =
    [[NSAttributedString alloc] initWithString:sComposingString];
  [sComposingView insertText:str];
  [str release];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

void
nsTSMManager::CancelIME()
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  if (!IsComposing())
    return;
  // For canceling the current composing, we need to ignore the param of
  // insertText. But this code is ugly...
  sIgnoreCommit = true;
  KillComposing();
  sIgnoreCommit = false;
  if (!IsComposing())
    return;
  // If the composing transaction is still there, KillComposing only kills the
  // composing in TSM. We also need to kill the our composing transaction too.
  NSAttributedString* str = [[NSAttributedString alloc] initWithString:@""];
  [sComposingView insertText:str];
  [str release];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

#endif // NS_LEOPARD_AND_LATER

#pragma mark -

void
ChildViewMouseTracker::OnDestroyView(ChildView* aView)
{
  if (sLastMouseEventView == aView) {
    sLastMouseEventView = nil;
    [sLastMouseMoveEvent release];
    sLastMouseMoveEvent = nil;
  }
}

void
ChildViewMouseTracker::OnDestroyWindow(NSWindow* aWindow)
{
  if (sWindowUnderMouse == aWindow) {
    sWindowUnderMouse = nil;
  }
}

void
ChildViewMouseTracker::MouseEnteredWindow(NSEvent* aEvent)
{
  sWindowUnderMouse = [aEvent window];
  ReEvaluateMouseEnterState(aEvent);
}

void
ChildViewMouseTracker::MouseExitedWindow(NSEvent* aEvent)
{
  if (sWindowUnderMouse == [aEvent window]) {
    sWindowUnderMouse = nil;
    ReEvaluateMouseEnterState(aEvent);
  }
}

void
ChildViewMouseTracker::ReEvaluateMouseEnterState(NSEvent* aEvent, ChildView* aOldView)
{
  ChildView* oldView = aOldView ? aOldView : sLastMouseEventView;
  sLastMouseEventView = ViewForEvent(aEvent);
  if (sLastMouseEventView != oldView) {
    // Send enter and / or exit events.
    WidgetMouseEvent::exitType type =
      [sLastMouseEventView window] == [oldView window] ?
        WidgetMouseEvent::eChild : WidgetMouseEvent::eTopLevel;
    [oldView sendMouseEnterOrExitEvent:aEvent enter:NO type:type];
    // After the cursor exits the window set it to a visible regular arrow cursor.
    if (type == WidgetMouseEvent::eTopLevel) {
      [[nsCursorManager sharedInstance] setCursor:eCursor_standard];
    }
    [sLastMouseEventView sendMouseEnterOrExitEvent:aEvent enter:YES type:type];
  }
}

void
ChildViewMouseTracker::ResendLastMouseMoveEvent()
{
  if (sLastMouseMoveEvent) {
    MouseMoved(sLastMouseMoveEvent);
  }
}

void
ChildViewMouseTracker::MouseMoved(NSEvent* aEvent)
{
  ReEvaluateMouseEnterState(aEvent); // undoing bug 675208
  //MouseEnteredWindow(aEvent);
  [sLastMouseEventView handleMouseMoved:aEvent];
  if (sLastMouseMoveEvent != aEvent) {
    [sLastMouseMoveEvent release];
    sLastMouseMoveEvent = [aEvent retain];
  }
}

void
ChildViewMouseTracker::MouseScrolled(NSEvent* aEvent)
{
  if (!nsCocoaUtils::IsMomentumScrollEvent(aEvent)) {
    // Store the position so we can pin future momentum scroll events.
    sLastScrollEventScreenLocation = nsCocoaUtils::ScreenLocationForEvent(aEvent);
  }
}

ChildView*
ChildViewMouseTracker::ViewForEvent(NSEvent* aEvent)
{
  //NSWindow* window = sWindowUnderMouse;
  NSWindow* window = WindowForEvent(aEvent); // undoing bug 675208
  if (!window)
    return nil;

  NSPoint windowEventLocation = nsCocoaUtils::EventLocationForWindow(aEvent, window);
  NSView* view = [[[window contentView] superview] hitTest:windowEventLocation];

  if (![view isKindOfClass:[ChildView class]])
    return nil;

  ChildView* childView = (ChildView*)view;
  // If childView is being destroyed return nil.
  if (![childView widget])
    return nil;
  return WindowAcceptsEvent(window, aEvent, childView) ? childView : nil;
}

// added back from bug 675208
static CGWindowLevel kDockWindowLevel = 0;
static CGWindowLevel kPopupWindowLevel = 0;

static BOOL WindowNumberIsUnderPoint(NSInteger aWindowNumber, NSPoint aPoint) {
  NSWindow* window = [NSApp windowWithWindowNumber:aWindowNumber];
  if (window) {
    // This is one of our own windows.
    return NSMouseInRect(aPoint, [window frame], NO);
  }

  CGSConnection cid = _CGSDefaultConnection();

  if (!kDockWindowLevel) {
    // These constants are in fact function calls, so cache them.
    kDockWindowLevel = kCGDockWindowLevel;
    kPopupWindowLevel = kCGPopUpMenuWindowLevel;
  }

  // Some things put transparent windows on top of everything. Ignore them.
  CGWindowLevel level;
  if ((kCGErrorSuccess == CGSGetWindowLevel(cid, aWindowNumber, &level)) &&
      (level == kDockWindowLevel ||     // Transparent layer, spanning the whole screen
       level > kPopupWindowLevel))      // Snapz Pro X while recording a screencast
    return false;

  // Ignore transparent windows.
  float alpha;
  if ((kCGErrorSuccess == CGSGetWindowAlpha(cid, aWindowNumber, &alpha)) &&
      alpha < 0.1f)
    return false;

  CGRect rect;
  if (kCGErrorSuccess != CGSGetScreenRectForWindow(cid, aWindowNumber, &rect))
    return false;

  CGPoint point = { aPoint.x, nsCocoaUtils::FlippedScreenY(aPoint.y) };
  return CGRectContainsPoint(rect, point);
}

// Find the window number of the window under the given point, regardless of
// which app the window belongs to. Returns 0 if no window was found.
static NSInteger WindowNumberAtPoint(NSPoint aPoint) {
  // We'd like to use the new windowNumberAtPoint API on 10.6 but we can't rely
  // on it being up-to-date. For example, if we've just opened a window,
  // windowNumberAtPoint might not know about it yet, so we'd send events to the
  // wrong window. See bug 557986.
  // So we'll have to find the right window manually by iterating over all
  // windows on the screen and testing whether the mouse is inside the window's
  // rect. We do this using private CGS functions.
  // Another way of doing it would be to use tracking rects, but those are
  // view-controlled, so they need to be reset whenever an NSView changes its
  // size or position, which is expensive. See bug 300904 comment 20.
  // A problem with using the CGS functions is that we only look at the windows'
  // rects, not at the transparency of the actual pixel the mouse is over. This
  // means that we won't treat transparent pixels as transparent to mouse
  // events, which is a disadvantage over using tracking rects and leads to the
  // crummy window level workarounds in WindowNumberIsUnderPoint.
  // But speed is more important.

  // Get the window list.
  NSInteger windowCount;
  NSCountWindows(&windowCount);
  NSInteger* windowList = (NSInteger*)malloc(sizeof(NSInteger) * windowCount);
  if (!windowList)
    return nil;

  // The list we get back here is in order from front to back.
  NSWindowList(windowCount, windowList);
  for (NSInteger i = 0; i < windowCount; i++) {
    NSInteger windowNumber = windowList[i];
    if (WindowNumberIsUnderPoint(windowNumber, aPoint)) {
      free(windowList);
      return windowNumber;
    }
  }

  free(windowList);
  return 0;
}

// Find Gecko window under the mouse. Returns nil if the mouse isn't over
// any of our windows.
NSWindow*
ChildViewMouseTracker::WindowForEvent(NSEvent* anEvent)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_NIL;

  NSPoint screenPoint = nsCocoaUtils::ScreenLocationForEvent(anEvent);
  NSInteger windowNumber = WindowNumberAtPoint(screenPoint);

  // This will return nil if windowNumber belongs to a window that we don't own.
  return [NSApp windowWithWindowNumber:windowNumber];

  NS_OBJC_END_TRY_ABORT_BLOCK_NIL;
}

BOOL
ChildViewMouseTracker::WindowAcceptsEvent(NSWindow* aWindow, NSEvent* aEvent,
                                          ChildView* aView, BOOL aIsClickThrough)
{
  // Force us forward if we were not. 10.4Fx issue 19.
  if ([aEvent type] == NSLeftMouseDown || [aEvent type] == NSRightMouseDown) {
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    OSStatus err = SetFrontProcessWithOptions(&psn, kSetFrontProcessFrontWindowOnly);
  }

  // Right mouse down events may get through to all windows, even to a top level
  // window with an open sheet.
  if (!aWindow) // || [aEvent type] == NSRightMouseDown)
    return YES;

  id delegate = [aWindow delegate];
  if (!delegate || ![delegate isKindOfClass:[WindowDelegate class]])
    return YES;

  nsIWidget *windowWidget = [(WindowDelegate *)delegate geckoWidget];
  if (!windowWidget)
    return YES;

  NSWindow* topLevelWindow = nil;
  nsWindowType windowType = windowWidget->WindowType();

  // Make us the main window as long as we are not a popup, dialogue or sheet
  // if we click on it.
  if (windowType != eWindowType_popup &&
	windowType != eWindowType_dialog &&
	windowType != eWindowType_sheet &&
	![aWindow attachedSheet] &&
	([aEvent type] == NSLeftMouseDown || [aEvent type] == NSRightMouseDown))
{
     	[aWindow makeMainWindow];
	[aWindow makeKeyWindow];
	[aWindow orderFrontRegardless]; // safe, because we are the
		// front app, the main window *and* the key window.
		// 10.4Fx issue 19 etc.
}

  switch (windowWidget->WindowType()) {
    case eWindowType_popup:
      // If this is a context menu, it won't have a parent. So we'll always
      // accept mouse move events on context menus even when none of our windows
      // is active, which is the right thing to do.
      // For panels, the parent window is the XUL window that owns the panel.
      return WindowAcceptsEvent([aWindow parentWindow], aEvent, aView, aIsClickThrough);

    case eWindowType_toplevel:
    case eWindowType_dialog:
      if ([aWindow attachedSheet])
        return NO;

      topLevelWindow = aWindow;
      break;
    case eWindowType_sheet: {
      if ([aEvent type] == NSRightMouseDown) return YES;
      nsIWidget* parentWidget = windowWidget->GetSheetWindowParent();
      if (!parentWidget)
        return YES;

      topLevelWindow = (NSWindow*)parentWidget->GetNativeData(NS_NATIVE_WINDOW);
      break;
    }

    default:
      return YES;
  }

  if (!topLevelWindow ||
      ([topLevelWindow isMainWindow] && !aIsClickThrough) ||
      [aEvent type] == NSOtherMouseDown ||
      (([aEvent modifierFlags] & NSCommandKeyMask) != 0 &&
       [aEvent type] != NSMouseMoved))
    return YES;

  // If we're here then we're dealing with a left click or mouse move on an
  // inactive window or something similar. Ask Gecko what to do.
  return [aView inactiveWindowAcceptsMouseEvent:aEvent];
}

#pragma mark -

@interface EventThreadRunner(Private)
- (void)runEventThread;
- (void)shutdownAndReleaseCalledOnEventThread;
- (void)shutdownAndReleaseCalledOnAnyThread;
- (void)handleEvent:(CGEventRef)cgEvent type:(CGEventType)type;
@end

static EventThreadRunner* sEventThreadRunner = nil;

@implementation EventThreadRunner

+ (void)start
{
  sEventThreadRunner = [[EventThreadRunner alloc] init];
}

+ (void)stop
{
  if (sEventThreadRunner) {
    [sEventThreadRunner shutdownAndReleaseCalledOnAnyThread];
    sEventThreadRunner = nil;
  }
}

- (id)init
{
  if ((self = [super init])) {
    mThread = nil;
    [NSThread detachNewThreadSelector:@selector(runEventThread)
                             toTarget:self
                           withObject:nil];
  }
  return self;
}

static CGEventRef
HandleEvent(CGEventTapProxy aProxy, CGEventType aType,
            CGEventRef aEvent, void* aClosure)
{
  [(EventThreadRunner*)aClosure handleEvent:aEvent type:aType];
  return aEvent;
}

- (void)runEventThread
{
  char aLocal;
  profiler_register_thread("APZC Event Thread", &aLocal);
  PR_SetCurrentThreadName("APZC Event Thread");

  mThread = [NSThread currentThread];
  ProcessSerialNumber currentProcess;
  GetCurrentProcess(&currentProcess);
  CFMachPortRef eventPort =
    CGEventTapCreateForPSN(&currentProcess,
                           kCGHeadInsertEventTap,
                           kCGEventTapOptionListenOnly,
                           CGEventMaskBit(kCGEventScrollWheel),
                           HandleEvent,
                           self);
  CFRunLoopSourceRef eventPortSource =
    CFMachPortCreateRunLoopSource(kCFAllocatorSystemDefault, eventPort, 0);
  CFRunLoopAddSource(CFRunLoopGetCurrent(), eventPortSource, kCFRunLoopCommonModes);
  CFRunLoopRun();
  CFRunLoopRemoveSource(CFRunLoopGetCurrent(), eventPortSource, kCFRunLoopCommonModes);
  CFRelease(eventPortSource);
  CFRelease(eventPort);
  [self release];
}

- (void)shutdownAndReleaseCalledOnEventThread
{
  CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)shutdownAndReleaseCalledOnAnyThread
{
  [self performSelector:@selector(shutdownAndReleaseCalledOnEventThread) onThread:mThread withObject:nil waitUntilDone:NO];
}

static const CGEventField kCGWindowNumberField = (const CGEventField) 51;

// Called on scroll thread
- (void)handleEvent:(CGEventRef)cgEvent type:(CGEventType)type
{
  if (type != kCGEventScrollWheel) {
    return;
  }

  int windowNumber = CGEventGetIntegerValueField(cgEvent, kCGWindowNumberField);
  NSWindow* window = [NSApp windowWithWindowNumber:windowNumber];
  if (!window || ![window isKindOfClass:[BaseWindow class]]) {
    return;
  }

  ChildView* childView = [(BaseWindow*)window mainChildView];
  [childView handleAsyncScrollEvent:cgEvent ofType:type];
}

@end

@interface NSView (MethodSwizzling)
- (BOOL)nsChildView_NSView_mouseDownCanMoveWindow;
@end

@implementation NSView (MethodSwizzling)

// All top-level browser windows belong to the ToolbarWindow class and have
// NSTexturedBackgroundWindowMask turned on in their "style" (see particularly
// [ToolbarWindow initWithContentRect:...] in nsCocoaWindow.mm).  This style
// normally means the window "may be moved by clicking and dragging anywhere
// in the window background", but we've suppressed this by giving the
// ChildView class a mouseDownCanMoveWindow method that always returns NO.
// Normally a ToolbarWindow's contentView (not a ChildView) returns YES when
// NSTexturedBackgroundWindowMask is turned on.  But normally this makes no
// difference.  However, under some (probably very unusual) circumstances
// (and only on Leopard) it *does* make a difference -- for example it
// triggers bmo bugs 431902 and 476393.  So here we make sure that a
// ToolbarWindow's contentView always returns NO from the
// mouseDownCanMoveWindow method.
- (BOOL)nsChildView_NSView_mouseDownCanMoveWindow
{
  NSWindow *ourWindow = [self window];
  NSView *contentView = [ourWindow contentView];
  if ([ourWindow isKindOfClass:[ToolbarWindow class]] && (self == contentView))
    return [ourWindow isMovableByWindowBackground];
  return [self nsChildView_NSView_mouseDownCanMoveWindow];
}

@end

#ifdef __LP64__
// When using blocks, at least on OS X 10.7, the OS sometimes calls
// +[NSEvent removeMonitor:] more than once on a single event monitor, which
// causes crashes.  See bug 678607.  We hook these methods to work around
// the problem.
@interface NSEvent (MethodSwizzling)
+ (id)nsChildView_NSEvent_addLocalMonitorForEventsMatchingMask:(unsigned long long)mask handler:(id)block;
+ (void)nsChildView_NSEvent_removeMonitor:(id)eventMonitor;
@end

// This is a local copy of the AppKit frameworks sEventObservers hashtable.
// It only stores "local monitors".  We use it to ensure that +[NSEvent
// removeMonitor:] is never called more than once on the same local monitor.
static NSHashTable *sLocalEventObservers = nil;

@implementation NSEvent (MethodSwizzling)

+ (id)nsChildView_NSEvent_addLocalMonitorForEventsMatchingMask:(unsigned long long)mask handler:(id)block
{
  if (!sLocalEventObservers) {
    sLocalEventObservers = [[NSHashTable hashTableWithOptions:
      NSHashTableStrongMemory | NSHashTableObjectPointerPersonality] retain];
  }
  id retval =
    [self nsChildView_NSEvent_addLocalMonitorForEventsMatchingMask:mask handler:block];
  if (sLocalEventObservers && retval && ![sLocalEventObservers containsObject:retval]) {
    [sLocalEventObservers addObject:retval];
  }
  return retval;
}

+ (void)nsChildView_NSEvent_removeMonitor:(id)eventMonitor
{
  if (sLocalEventObservers && [eventMonitor isKindOfClass: ::NSClassFromString(@"_NSLocalEventObserver")]) {
    if (![sLocalEventObservers containsObject:eventMonitor]) {
      return;
    }
    [sLocalEventObservers removeObject:eventMonitor];
  }
  [self nsChildView_NSEvent_removeMonitor:eventMonitor];
}

@end
#endif // #ifdef __LP64__
