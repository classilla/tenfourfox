/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Mozilla XUL Toolkit.
 *
 * The Initial Developer of the Original Code is
 * the Mozilla Foundation.
 * Portions created by the Initial Developer are Copyright (C) 2010-2019
 * the Initial Developer. All Rights Reserved.
 *
 * Based on original works by Scott Greenlay <scott@greenlay.net> (bug 608049).
 * Expanded and ported to TenFourFox and 10.4 SDK by Cameron Kaiser
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

#import <Cocoa/Cocoa.h>
#import <objc/objc-runtime.h>
extern "C" {
    IMP class_lookupMethod(Class, SEL);
};
#define class_getMethodImplementation(x,y) class_lookupMethod(x,y)

#import "MacScripting.h"

#include "nsIApplescriptService.h"

#include "nsCOMPtr.h"
#include "nsComponentManagerUtils.h"
#include "nsArrayUtils.h"
#include "nsString.h"
#include "nsContentCID.h"
#include "nsNetUtil.h"
#include "nsIServiceManager.h"
#include "nsServiceManagerUtils.h"
#include "nsIAppStartup.h"
#include "nsISelection.h"
#include "nsIDocShell.h"
#include "nsIDOMNode.h"
#include "nsIDOMDocument.h"
#include "nsIDOMHTMLDocument.h"
#include "nsIDOMLocation.h"
#include "nsIDOMSerializer.h"
#include "nsIDocument.h"
#include "nsIDocumentEncoder.h"
#include "nsISelection.h"
#include "nsISelectionController.h"
#include "nsIWindowMediator.h"
#include "nsISimpleEnumerator.h"
#include "nsIBaseWindow.h"
#include "nsIWidget.h"
#include "nsIXULWindow.h"
#include "nsIURI.h"
#include "nsIWebNavigation.h"
#include "nsIDOMWindow.h"
#include "nsPIDOMWindow.h"
#include "nsIDOMWindowUtils.h"
#include "nsIInterfaceRequestor.h"
#include "nsIDOMLocation.h"
#include "nsIPresShell.h"
#include "nsObjCExceptions.h"
#include "nsToolkitCompsCID.h"
#include "nsContentUtils.h"
#include "mozilla/dom/Selection.h"

// 10.4 no haz.
typedef int NSInteger;
typedef unsigned int NSUInteger;

#define NSIntegerMax    LONG_MAX
#define NSIntegerMin    LONG_MIN
#define NSUIntegerMax   ULONG_MAX

@class GeckoObject;
@class GeckoWindow;
@class GeckoTab;

#pragma mark -

@interface GeckoScriptingRoot : NSObject
{
  @private
  // These must persist for the life of the scripting application.
  struct objc_method swinMeth;
  struct objc_method insoMeth;
  struct objc_method insiMeth;
  struct objc_method remoMeth;
  struct objc_method openMeth;
  struct objc_method_list methodList;
}

+ (GeckoScriptingRoot*)sharedScriptingRoot;
- (id)init;
- (void)makeApplicationScriptable:(NSApplication*)application;
- (void)insertObject:(NSObject*)object inScriptWindowsAtIndex:(NSUInteger)index;
- (NSArray*)scriptWindows;
- (void)insertInScriptWindows:(id)value;

@end

#pragma mark -

@interface GeckoWindow : NSObject
{
  NSUInteger                mIndex;
  nsCOMPtr<nsIXULWindow>    mXULWindow;
}

- (id)initWithIndex:(NSUInteger)index andXULWindow:(nsIXULWindow*)xulWindow;
+ (id)windowWithIndex:(NSUInteger)index andXULWindow:(nsIXULWindow*)xulWindow;

// Default Scripting Dictionary
- (NSString*)title;
- (NSUInteger)orderedIndex;
- (BOOL)isMiniaturizable;
- (BOOL)isMiniaturized;
- (void)setIsMiniaturized:(BOOL)miniaturized;
- (BOOL)isResizable;
- (BOOL)isVisible;
- (void)setIsVisible:(BOOL)visible;
- (BOOL)isZoomable;
- (BOOL)isZoomed;
- (void)setIsZoomed:(BOOL)zoomed;
- (BOOL)fullscreen;
- (void)setFullscreen:(BOOL)fullscreen;

- (id)handleCloseScriptCommand:(NSCloseCommand*)command;

// Gecko Scripting Dictionary
- (NSArray*)scriptTabs;
- (void)insertInScriptTabs:(id)value;
- (GeckoTab*)selectedScriptTab;
- (void)setSelectedScriptTab:(id)value;

// Helper Methods
- (void)_setIndex:(NSUInteger)index;

@end

#pragma mark -

@interface GeckoTab : NSObject
{
  NSUInteger                mIndex;
  GeckoWindow               *mWindow;
  nsCOMPtr<nsIDOMWindow>    mContentWindow;
}

- (id)initWithIndex:(NSUInteger)index andContentWindow:(nsIDOMWindow*)contentWindow andWindow:(GeckoWindow*)window;
+ (id)tabWithIndex:(NSUInteger)index andContentWindow:(nsIDOMWindow*)contentWindow andWindow:(GeckoWindow*)window;

// Gecko Scripting Dictionary
- (NSString*)title;
- (NSUInteger)orderedIndex;
- (NSString*)URL;
- (NSString*)source;
- (NSString*)text;
- (NSString*)selectedText;

- (void)setURL:(NSString*)newURL;

- (id)handleCloseScriptCommand:(NSCloseCommand*)command;
- (id)handleReloadScriptCommand:(NSScriptCommand*)command;
- (NSString*)handleRunJavaScriptCommand:(NSScriptCommand*)command;

// Helper Methods
- (void)_setWindow:(GeckoWindow*)window;
- (void)_setIndex:(NSUInteger)index;
- (NSUInteger)_index;

@end

#pragma mark -

@interface GeckoQuit : NSScriptCommand
{
}

@end

#pragma mark -
void SetupMacScripting(void) {
    NS_OBJC_BEGIN_TRY_ABORT_BLOCK;
 
    [[GeckoScriptingRoot sharedScriptingRoot] makeApplicationScriptable:[NSApplication sharedApplication]];

    NS_OBJC_END_TRY_ABORT_BLOCK;
}

#pragma mark -

static GeckoScriptingRoot *sharedScriptingRoot = nil;
static NSUInteger openExpected = 1; // we always start with a window
static BOOL didInit = NO;

@implementation GeckoScriptingRoot

+ (GeckoScriptingRoot*)sharedScriptingRoot {
  @synchronized (sharedScriptingRoot) {
    if (!sharedScriptingRoot) {
      sharedScriptingRoot = [[GeckoScriptingRoot alloc] init];
    }
  }
  return sharedScriptingRoot;
}

- (id)init {
  self = [super init];
  return self;
}

- (void)makeApplicationScriptable:(NSApplication*)application {
  if (didInit) return;

  NS_WARNING("starting Script Host");
  IMP scriptWindows = class_getMethodImplementation([self class], @selector(scriptWindows));
//  class_addMethod([application class], @selector(scriptWindows), scriptWindows, "@@:");

  IMP insertScriptWindowsAI = class_getMethodImplementation([self class], @selector(insertObject:inScriptWindowsAtIndex:));
//  class_addMethod([application class], @selector(insertObject:inScriptWindowsAtIndex:), insertScriptWindowsAI, "v@:@I");

  IMP insertScriptWindows = class_getMethodImplementation([self class], @selector(insertInScriptWindows:));
//  class_addMethod([application class], @selector(insertInScriptWindows:), insertScriptWindows, "v@:@");

  IMP removeScriptWindows = class_getMethodImplementation([self class], @selector(removeObjectFromScriptWindowsAtIndex:));
//  class_addMethod([application class], @selector(removeObjectFromScriptWindowsAtIndex:), removeScriptWindows, "v@:I");

  IMP openingP = class_getMethodImplementation([self class], @selector(opening));
//  class_addMethod([application class], @selector(opening), openingP, "c@:");

  // The 10.4 SDK doesn't have class_addMethod, but it does have class_addMethods.
  swinMeth.method_name = @selector(scriptWindows);
  swinMeth.method_imp = scriptWindows;
  swinMeth.method_types = "@@:";

  insoMeth.method_name = @selector(insertObject:inScriptWindowsAtIndex:);
  insoMeth.method_imp = insertScriptWindowsAI;
  insoMeth.method_types = "v@:@l";

  insiMeth.method_name = @selector(insertInScriptWindows:);
  insiMeth.method_imp = insertScriptWindows;
  insiMeth.method_types = "v@:@";

  remoMeth.method_name = @selector(removeObjectFromScriptWindowsAtIndex:);
  remoMeth.method_imp = removeScriptWindows;
  remoMeth.method_types = "v@:l";

  openMeth.method_name = @selector(opening);
  openMeth.method_imp = openingP;
  openMeth.method_types = "c@:";

  methodList.method_count = 5;
  methodList.method_list[0] = swinMeth;
  methodList.method_list[1] = insoMeth;
  methodList.method_list[2] = insiMeth;
  methodList.method_list[3] = remoMeth;
  methodList.method_list[4] = openMeth;

  class_addMethods([application class], &methodList);
  didInit = YES;
  openExpected = 1;
}

- (NSArray*)scriptWindows {
  NS_WARNING("AppleScript: root scriptWindows");
	nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (!applescriptService) {
    return [NSArray arrayWithObjects:nil];
  }
  
  nsCOMPtr<nsIArray> windows;
  if (NS_FAILED(applescriptService->GetWindows(getter_AddRefs(windows))) || !windows) {
    return [NSArray arrayWithObjects:nil];
  }
  
  NSUInteger index = 0;
  NSMutableArray *windowArray = [NSMutableArray array];
  
  uint32_t length;
  windows->GetLength(&length);
  for (uint32_t i = 0; i < length; ++i) {
    nsCOMPtr<nsIXULWindow> xulWindow(do_QueryElementAt(windows, i));
    if (xulWindow) {
      GeckoWindow *window = [GeckoWindow windowWithIndex:index andXULWindow:xulWindow];
      if (window) {
        [windowArray addObject:window];
        index++;
      }
    }
  }
  return windowArray;
}

- (void)insertObject:(NSObject*)object inScriptWindowsAtIndex:(NSUInteger)index {
  NS_WARNING("AppleScript: root insertObject inScriptWindowsAtIndex");
  if (![object isKindOfClass:[GeckoWindow class]]) {
    return;
  }

  nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (applescriptService) {
    (void)applescriptService->CreateWindowAtIndex(index);
  }

  openExpected = [[self scriptWindows] count] + 1;
  [(GeckoWindow*)object _setIndex:index];
}

- (void)insertInScriptWindows:(id)value {
  NS_WARNING("AppleScript: root insertInScriptWindows");
  if (![(NSObject*)value isKindOfClass:[GeckoWindow class]])
    return;

  // The ordering works rather oddly for windows. The frontmost window is
  // zero, so for things like set w to make new browser window / tell w, we
  // have to insert at index 0 instead of at the end like we do for tabs or
  // we start talking to the wrong window and things show up in the wrong
  // place. In practise it seems the index really works more like Z-order.
  // We get away with this because the indices get rebuilt by scriptWindows:
  // off the actual XUL indexes; we don't really have multiple index 0s
  // because there isn't a persistent array of GeckoWindows.
  //
  // For some reason [self insertObject:inScriptWindowsAtIndex:] doesn't
  // work properly, and trying to access it through the singleton
  // sharedScriptingRoot causes memory failures, so we just copy the
  // logic here. On 10.4, [s iO:iSWAI:] doesn't even seem to be called.
  nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (applescriptService) {
    (void)applescriptService->CreateWindowAtIndex(0);
  }

  openExpected = [[self scriptWindows] count] + 1;
  [(GeckoWindow*)value _setIndex:0];
}

- (void)removeObjectFromScriptWindowsAtIndex:(NSUInteger)index {
  NSArray *windows = [self scriptWindows];
  if (windows && index < [windows count]) {
    NSCloseCommand *closeCommend = [[[NSCloseCommand alloc] init] autorelease];
    [(GeckoWindow*)[windows objectAtIndex:index] handleCloseScriptCommand:closeCommend];
  }
}

- (BOOL)opening {
  NS_WARNING("AppleScript: root opening");
  // XXX: We don't decrement openExpected for closed windows since it will
  // be resynchronized after any new window operation. Should we? Is it useful
  // to call this method at any other time than after opening?
  return [[self scriptWindows] count] < openExpected;
}
@end

#pragma mark -

@implementation GeckoWindow

+ (id)windowWithIndex:(NSUInteger)index andXULWindow:(nsIXULWindow*)xulWindow {
  return [[[self alloc] initWithIndex:index andXULWindow:xulWindow] autorelease];
}

- (id)initWithIndex:(NSUInteger)index andXULWindow:(nsIXULWindow*)xulWindow {
  self = [super init];
  
  if (self) {
    mIndex = index;
    mXULWindow = xulWindow;
  }
  
  return self;
}

- (void)dealloc {
  [super dealloc];
}

- (void)_setIndex:(NSUInteger)index {
  mIndex = index;
}

- (id)uniqueID {
  return [NSNumber numberWithInt:mIndex];
}

- (NSScriptObjectSpecifier*)objectSpecifier
{
  NSScriptObjectSpecifier *objectSpecifier = [[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:[NSApp class]] 
                                                                                         containerSpecifier:[NSApp objectSpecifier]
                                                                                                        key:@"scriptWindows"
                                                                                                   uniqueID:[self uniqueID]];
  return [objectSpecifier autorelease];
}

- (NSWindow*)window
{
  nsresult rv;
  nsCOMPtr<nsIBaseWindow> baseWindow = do_QueryInterface(mXULWindow, &rv);
  NS_ENSURE_SUCCESS(rv, nil);

  nsCOMPtr<nsIWidget> widget;
  rv = baseWindow->GetMainWidget(getter_AddRefs(widget));
  NS_ENSURE_SUCCESS(rv, nil);

  return (NSWindow*)widget->GetNativeData(NS_NATIVE_WINDOW);
}

- (NSString*)title
{
  NS_WARNING("AppleScript: window title");
  NSWindow *window = [self window];
  return window ? [window title] : @"";
}

- (NSUInteger)orderedIndex {
  return mIndex; 
}

- (BOOL)isMiniaturizable {
  NSWindow *window = [self window];
  return window ? [window isMiniaturizable] : false;
}

- (BOOL)isMiniaturized {
  NSWindow *window = [self window];
  return window ? [window isMiniaturizable] : false;
}

- (void)setIsMiniaturized:(BOOL)miniaturized {
  NSWindow *window = [self window];
  if (window) {
    [window setIsMiniaturized:miniaturized];
  }
}

- (BOOL)isResizable {
  NSWindow *window = [self window];
  return window ? [window isResizable] : false;
}

- (BOOL)isVisible {
  NSWindow *window = [self window];
  return window ? [window isVisible] : false;
}

- (void)setIsVisible:(BOOL)visible {
  NSWindow *window = [self window];
  if (window) {
    [window setIsVisible:visible];
  }
}

- (BOOL)isZoomable {
  NSWindow *window = [self window];
  return window ? [window isZoomable] : false;
}

- (BOOL)isZoomed {
  NSWindow *window = [self window];
  return window ? [window isZoomed] : false;
}

- (void)setIsZoomed:(BOOL)zoomed {
  NSWindow *window = [self window];
  if (window) {
    [window setIsZoomed:zoomed];
  }
}

- (BOOL)fullscreen {
  NS_WARNING("AppleScript: window fullscreen");
  nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (applescriptService) {
    bool isfs;
    if (NS_SUCCEEDED(applescriptService->GetWindowIsFullScreen(mIndex, &isfs))) {
      return (isfs) ? YES : NO;
    }
  }
  return NO;
}

- (void)setFullscreen:(BOOL)fullscreen {
  NS_WARNING("AppleScript: window setFullscreen");
  nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (applescriptService) {
    applescriptService->SetWindowIsFullScreen(mIndex, (fullscreen == YES));
  }
}

- (id)handleCloseScriptCommand:(NSCloseCommand*)command {
  NS_WARNING("AppleScript: window handleCloseScriptCommand");
  // Try to close with the scripted handler, since it's faster. If not,
  // fallback on Cocoa.
  nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (applescriptService) {
    if (NS_SUCCEEDED(applescriptService->CloseWindowAtIndex(mIndex))) {
      return nil;
    }
  }
  NS_WARNING("window close from Gecko failed; trying from NSWindow");
  NSWindow *window = [self window];
  if (window) {
    return [window handleCloseScriptCommand:command];
  }
  return nil;
}

- (NSArray*)scriptTabs {
  NS_WARNING("AppleScript: window scriptTabs");
  NSScriptCommand* c = [NSScriptCommand currentCommand];

  if (!mXULWindow) {
    // A newly created but not instantiated window the user held a reference to,
    // e.g., |set w to make new browser window| and then trying to |tell w|.
    // XXX: Right now, this is an error.
    if (c) {
      [c setScriptErrorNumber:-10003]; // errAENotModifiable
      [c setScriptErrorString:@"Parameter Error: Don't keep references to new windows."];
    }
    return [NSArray arrayWithObjects:nil];
  }

  nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (!applescriptService) {
    return [NSArray arrayWithObjects:nil];
  }

  nsCOMPtr<nsIArray> tabs;
  if (NS_FAILED(applescriptService->GetTabsInWindow(mIndex, getter_AddRefs(tabs))) || !tabs) {
    return [NSArray arrayWithObjects:nil];
  }
  
  NSUInteger index = 0;
  NSMutableArray *tabArray = [NSMutableArray array];
  
  uint32_t length;
  tabs->GetLength(&length);
  for (uint32_t i = 0; i < length; ++i) {
    nsCOMPtr<nsIDOMWindow> contentWindow(do_QueryElementAt(tabs, i));
    if (contentWindow) {
      GeckoTab *tab = [GeckoTab tabWithIndex:index andContentWindow:contentWindow andWindow:self];
      [tabArray addObject:tab];
      index++;
    }
  }
  return tabArray;
}

- (GeckoTab*)selectedScriptTab {
  NS_WARNING("AppleScript: window selectedScriptTab");
  nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (!applescriptService) {
    return nil;
  }

  nsCOMPtr<nsIDOMWindow> contentWindow;
  uint32_t tabIndex = 0;
  if (NS_FAILED(applescriptService->GetCurrentTabInWindow(mIndex, &tabIndex, getter_AddRefs(contentWindow))) || !contentWindow) {
    return nil;
  }

  return [GeckoTab tabWithIndex:tabIndex andContentWindow:contentWindow andWindow:self];
}

- (void)setSelectedScriptTab:(id)value {
  NS_WARNING("AppleScript: window setSelectedScriptTab");
  if (![(NSObject*)value isKindOfClass:[GeckoTab class]]) {
    return;
  }
  nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (!applescriptService) {
    return;
  }
  (void)applescriptService->SetCurrentTabInWindow([(GeckoTab*)value _index], mIndex);
}

- (void)insertObject:(NSObject*)object inScriptTabsAtIndex:(NSUInteger)index {
  NS_WARNING("AppleScript: window insertObject:inScriptTabsAtIndex");
  if (![object isKindOfClass:[GeckoTab class]]) {
    return;
  }

  nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (applescriptService) {
    (void)applescriptService->CreateTabAtIndexInWindow(index, mIndex);
  }

  [(GeckoTab*)object _setWindow:self];
  [(GeckoTab*)object _setIndex:index];
}

- (void)insertInScriptTabs:(id)value {
  NS_WARNING("AppleScript: window insertInScriptTabs");
  if (![(NSObject*)value isKindOfClass:[GeckoTab class]])
    return;

  [self insertObject:value inScriptTabsAtIndex:[[self scriptTabs] count]];
}

- (void)removeObjectFromScriptTabsAtIndex:(NSUInteger)index {
  NS_WARNING("AppleScript: window removeObjectFromScriptTabsAtIndex");
  NSArray *tabs = [self scriptTabs];
  if (tabs && index < [tabs count]) {
    NSCloseCommand *closeCommend = [[[NSCloseCommand alloc] init] autorelease];
    [(GeckoTab*)[tabs objectAtIndex:index] handleCloseScriptCommand:closeCommend];
  }
}

@end

#pragma mark -

@implementation GeckoTab

+ (id)tabWithIndex:(NSUInteger)index andContentWindow:(nsIDOMWindow*)contentWindow andWindow:(GeckoWindow*)window {
  return [[[self alloc] initWithIndex:index andContentWindow:contentWindow andWindow:window] autorelease];
}

- (id)init {
  /* AppleScript may call directly. */
  self = [super init];
  return self;
}

- (id)initWithIndex:(NSUInteger)index andContentWindow:(nsIDOMWindow*)contentWindow andWindow:(GeckoWindow*)window {
  self = [super init];
  
  if (self) {
    mIndex = index;
    mWindow = [window retain];
    mContentWindow = contentWindow;
  }

  return self;
}

- (void)dealloc {
  [mWindow release];
  [super dealloc];
}

- (void)_setWindow:(GeckoWindow*)window {
  if (mWindow) {
    [mWindow release];
  }
  
  mWindow = nil;
  
  if (window) {
    mWindow = [window retain];
  }
}

- (void)_setIndex:(NSUInteger)index {
  mIndex = index;
}

- (NSUInteger)_index {
  return mIndex;
}

- (NSScriptObjectSpecifier*)objectSpecifier
{
  if (!mWindow) {
    return nil;
  }
  NSScriptObjectSpecifier *objectSpecifier = [[NSIndexSpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:[mWindow class]]
                                                                                      containerSpecifier:[mWindow objectSpecifier]
                                                                                                     key:@"scriptTabs"
                                                                                                   index:[self orderedIndex]];
  return [objectSpecifier autorelease];
}

- (NSString*)title
{
  NS_WARNING("AppleScript: tab title");
  nsCOMPtr<nsPIDOMWindow> piWindow = do_QueryInterface(mContentWindow);
  if (!piWindow)
    return @"";
  nsCOMPtr<nsIDocument> pdoc = piWindow->GetDoc();
  if (!pdoc)
    return @"";
  if (pdoc) {
    nsCOMPtr<nsIDOMHTMLDocument> htmlDocument(do_QueryInterface(pdoc));
    if (htmlDocument) {
      nsAutoString title;
      if (NS_SUCCEEDED(htmlDocument->GetTitle(title))) {
        return [NSString stringWithUTF8String:NS_ConvertUTF16toUTF8(title).get()];
      }
    }
  }
  return @"";
}

- (NSString*)URL
{
  NS_WARNING("AppleScript: tab URL");
  nsCOMPtr<nsPIDOMWindow> piWindow = do_QueryInterface(mContentWindow);
  if (!piWindow)
    return @"";
  nsCOMPtr<nsIDocument> pdoc = piWindow->GetDoc();
  if (!pdoc)
    return @"";
  nsCOMPtr<nsIURI> u = pdoc->GetDocumentURI();
  if (u) {
    nsAutoCString url;
    u->GetAsciiSpec(url);
    return [NSString stringWithUTF8String:url.get()];
  }
  return @"";
}

- (BOOL)busy
{
  NS_WARNING("AppleScript: tab busy");

  // This is deliberately inexact and is designed to mostly tell the caller when
  // it's okay to start working with the tab's properties.
  nsCOMPtr<nsPIDOMWindow> piWindow = do_QueryInterface(mContentWindow);
  if (!piWindow)
    return YES; // Gecko is still creating this tab.
  nsCOMPtr<nsIDocShell> d = piWindow->GetDocShell();
  if (!d)
    return YES; // Ditto.
  uint32_t bz;
  if (NS_FAILED(d->GetBusyFlags(&bz)))
    return YES; // Hmmm.
  return (bz == nsIDocShell::BUSY_FLAGS_NONE) ? NO : YES;
}

- (void)setURL:(NSString*)newURL
{
  NS_WARNING("AppleScript: tab newURL");
  nsAutoCString geckoURL;
  nsIURI* uri;
  NSScriptCommand* c = [NSScriptCommand currentCommand];
  nsCOMPtr<nsIDocShell> d;

  geckoURL.Assign([newURL UTF8String]);
  if (NS_FAILED(NS_NewURI(&uri, geckoURL, nullptr, nullptr, nsContentUtils::GetIOService()))) {
    if (c) {
      [c setScriptErrorNumber:-2131]; // urlDataHHTTPURLErr
      [c setScriptErrorString:@"Parameter Error: URL is not valid."];
    }
    return;
  }
  nsCOMPtr<nsPIDOMWindow> piWindow = do_QueryInterface(mContentWindow);
  if (piWindow)
    d = piWindow->GetDocShell();
  if (!d) {
    // XXX: This usually happens when we try to open a new tab with properties.
    // Gecko's asynchronous nature doesn't work well with this, so right now
    // we just return a fatal error so people learn right away this won't fly.
    // The busy property would tell the caller if we're ready.
    if (c) {
      [c setScriptErrorNumber:-10003]; // errAENotModifiable
      [c setScriptErrorString:@"Parameter Error: The tab is busy. Don't use properties when creating a tab. Check busy first."];
    }
    return;
  }
  d->LoadURI(uri, nullptr, nsIWebNavigation::LOAD_FLAGS_NONE, true);
}

- (NSString*)source {
  NS_WARNING("AppleScript: tab HTML");
  nsresult rv;

  nsCOMPtr<nsPIDOMWindow> piWindow = do_QueryInterface(mContentWindow);
  if (!piWindow)
    return @"";
  nsCOMPtr<nsIDocument> pdoc = piWindow->GetDoc();
  if (!pdoc)
    return @"";
  nsCOMPtr<nsIDOMDocument> domdoc = do_QueryInterface(pdoc);
  if (!domdoc)
    return @"";

  nsAutoString outbuf;
  nsCOMPtr<nsIDocumentEncoder> encoder = do_CreateInstance(
    "@mozilla.org/layout/documentEncoder;1?type=text/html");
  rv = encoder->Init(domdoc, NS_LITERAL_STRING("text/html"), 0 |
    nsIDocumentEncoder::OutputLFLineBreak |
    0);
  if (NS_FAILED(rv))
    return @"";
  if (NS_SUCCEEDED(encoder->EncodeToString(outbuf))) {
    return [NSString stringWithUTF8String:NS_ConvertUTF16toUTF8(outbuf).get()];
  }
  return @"";
}

- (NSString*)text {
  NS_WARNING("AppleScript: tab plaintext");
  nsresult rv;

  nsCOMPtr<nsPIDOMWindow> piWindow = do_QueryInterface(mContentWindow);
  if (!piWindow)
    return @"";
  nsCOMPtr<nsIDocument> pdoc = piWindow->GetDoc();
  if (!pdoc)
    return @"";
  nsCOMPtr<nsIDOMDocument> domdoc = do_QueryInterface(pdoc);
  if (!domdoc)
    return @"";

  nsAutoString outbuf;
  nsCOMPtr<nsIDocumentEncoder> encoder = do_CreateInstance(
    "@mozilla.org/layout/documentEncoder;1?type=text/plain");
  rv = encoder->Init(domdoc, NS_LITERAL_STRING("text/plain"), 0 |
    nsIDocumentEncoder::SkipInvisibleContent |
    nsIDocumentEncoder::OutputFormatted |
    nsIDocumentEncoder::OutputLFLineBreak |
    nsIDocumentEncoder::OutputFormatFlowed |
    0);
  if (NS_FAILED(rv))
    return @"";
  if (NS_SUCCEEDED(encoder->EncodeToString(outbuf))) {
    return [NSString stringWithUTF8String:NS_ConvertUTF16toUTF8(outbuf).get()];
  }
  return @"";
}

- (NSString*)selectedText {
  NS_WARNING("AppleScript: tab selected");
  nsCOMPtr<nsPIDOMWindow> piWindow = do_QueryInterface(mContentWindow);
  if (!piWindow)
    return @"";
  // We can't just call GetSelection() directly on the nsPIDOMWindow
  // since we're not actually an outer, so we have to do this the long
  // way through the presshell.
  //nsCOMPtr<nsISelection> selection = piWindow->GetSelection();
  nsIDocShell* d = piWindow->GetDocShell();
  if (!d)
    return @"";
  nsIPresShell* s = d->GetPresShell();
  if (!s)
    return @"";
  nsCOMPtr<nsISelection> selection = static_cast<mozilla::dom::Selection*>(s->GetCurrentSelection(nsISelectionController::SELECTION_NORMAL));
  if (selection) {
    nsAutoString selectedTextChars;
    if (NS_SUCCEEDED(selection->ToString(selectedTextChars))) {
      return [NSString stringWithUTF8String:NS_ConvertUTF16toUTF8(selectedTextChars).get()];
    }
  }
  return @"";
}

- (NSUInteger)orderedIndex {
  return mIndex; 
}

- (id)handleCloseScriptCommand:(NSCloseCommand*)command {
  nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (applescriptService) {
    (void)applescriptService->CloseTabAtIndexInWindow(mIndex, [mWindow orderedIndex]);
  }
  return nil;
}

- (id)handleReloadScriptCommand:(NSScriptCommand*)command {
  nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (applescriptService) {
    (void)applescriptService->ReloadTabAtIndexInWindow(mIndex, [mWindow orderedIndex]);
  }
  return nil;
}

- (NSString*)handleRunJavaScriptCommand:(NSScriptCommand*)command {
  nsCOMPtr<nsIApplescriptService> applescriptService(do_GetService("@mozilla.org/applescript-service;1"));
  if (applescriptService) {
    NSDictionary *args = [command evaluatedArguments];
    if (args) {
      NSString *script = [args objectForKey:@"script"];
      if (script) {
        nsAutoCString s, r;
        bool ok = false;

        s.Assign([script UTF8String]);
        r.Truncate();
        if (NS_SUCCEEDED(applescriptService->RunScriptInTabAtIndexInWindow(mIndex,
                                                                           [mWindow orderedIndex],
                                                                           s, r, &ok))) {
          if (ok)
            return [NSString stringWithUTF8String:r.get()];

          [command setScriptErrorNumber:-2740]; // OSASyntaxError
          [command setScriptErrorString:@"Parameter Error: Failed to run JavaScript."]; // XXX
        }
      }
    }
  }
  return @"";
}

@end

#pragma mark -

@implementation GeckoQuit

- (id)performDefaultImplementation {
  NS_WARNING("AppleScript: quit");
  nsCOMPtr<nsIAppStartup> appStartup = do_GetService(NS_APPSTARTUP_CONTRACTID);
  if (appStartup) {
    appStartup->Quit(nsIAppStartup::eAttemptQuit);
  }
  return nil;
}

@end
