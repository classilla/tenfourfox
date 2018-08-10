/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Date Picker widget for TenFourFox (C)2018 Cameron Kaiser */

#import <Cocoa/Cocoa.h>

#include "nsDatePicker.h"
#include "nsCOMPtr.h"
#include "nsReadableUtils.h"
#include "nsNetUtil.h"
#include "nsIComponentManager.h"
#include "nsQueryObject.h"
#include "nsServiceManagerUtils.h"
#include "nsIStringBundle.h"
#include "nsCocoaFeatures.h"
#include "nsCocoaUtils.h"
#include "mozilla/Preferences.h"

// This must be included last:
#include "nsObjCExceptions.h"

// 10.4 does not have an accessory view method for NSAlert, but we can
// simulate it with these undocumented methods.
@interface NSAlert(WithCustomStyle)
- (void)prepare;
- (id)buildAlertStyle:(int)fp8 title:(id)fp12 formattedMsg:(id)fp16 first:(id)fp20 second:(id)fp24 third:(id)fp28 oldStyle:(BOOL)fp32;
- (id)buildAlertStyle:(int)fp8 title:(id)fp12 message:(id)fp16 first:(id)fp20 second:(id)fp24 third:(id)fp28 oldStyle:(BOOL)fp32 args:(char *)fp36;
@end

@class NSDoubleDatePicker; // forward declaration

@interface NSDoubleDateDelegate : NSObject {
  NSDoubleDatePicker *_parentAlert;
  NSDatePicker *_source;
}

- (void)datePickerCell:(NSDatePickerCell *)aDatePickerCell
  validateProposedDateValue:(NSDate **)proposedDateValue
  timeInterval:(NSTimeInterval *)proposedTimeInterval;
- (void)setParentAlert:(NSDoubleDatePicker *)parentAlert
  withSource:(NSDatePicker *)source;
@end

@implementation NSDoubleDateDelegate
- (void)datePickerCell:(NSDatePickerCell *)aDatePickerCell
  validateProposedDateValue:(NSDate **)proposedDateValue
  timeInterval:(NSTimeInterval *)proposedTimeInterval
{
  //NSLog(@"validate");
  [_parentAlert onSwitchControl:_source newDate:proposedDateValue];
}

- (void)setParentAlert:(NSDoubleDatePicker *)parentAlert
  withSource:(NSDatePicker *)source
{
  _parentAlert = parentAlert;
  _source = source;
}
@end

////// NSDoubleDatePicker
////// based on NSAlertCheckbox, http://cocoadev.github.io/NSAlertCheckbox/

@interface NSDoubleDatePicker : NSAlert {
  NSDatePicker *_pickertop;
  NSDatePicker *_pickerbottom;
  NSDoubleDateDelegate *_topdelegate;
  NSDoubleDateDelegate *_bottomdelegate;
}

- (void)dealloc;
- (NSDoubleDatePicker *)datePicker:(NSString *)message
  defaultButton:(NSString *)defaultButton
  alternateButton:(NSString *)alternateButton
  otherButton:(NSString *)otherButton
  informativeTextWithFormat:(NSString *)format;
- (void)onSwitchControl:(NSDatePicker *)which newDate:(NSDate **)newDate;
- (NSDate *)date;
- (void)setDate:(NSDate *)date;
- (void)setMinDate:(NSDate *)date;
- (void)setMaxDate:(NSDate *)date;
@end

@interface NSDoubleDatePicker(Private)
- (void)_ensureDatePickers;
- (void)_addDatePickersToAlert;
@end

@implementation NSDoubleDatePicker

- (void)dealloc
{
//NSLog(@"dealloc");
  [_pickertop release];
  [_pickerbottom release];
  [_topdelegate release];
  [_bottomdelegate release];
  [super dealloc];
}

- (NSDoubleDatePicker *)datePicker:(NSString *)message
  defaultButton:(NSString *)defaultButton
  alternateButton:(NSString *)alternateButton
  otherButton:(NSString *)otherButton
  informativeTextWithFormat:(NSString *)format
{
  NSAlert *alert = [super alertWithMessageText:message
                                 defaultButton:defaultButton
                               alternateButton:alternateButton
                                   otherButton:otherButton
                     informativeTextWithFormat:format];
  return (NSDoubleDatePicker *)alert;
}

- (id)buildAlertStyle:(int)fp8
  title:(id)fp12
  formattedMsg:(id)fp16
  first:(id)fp20
  second:(id)fp24
  third:(id)fp28
  oldStyle:(BOOL)fp32
{
  id rv = [super buildAlertStyle:fp8
                           title:fp12
                    formattedMsg:fp16
                           first:fp20
                          second:fp24
                           third:fp28
                        oldStyle:fp32];
  [self _addDatePickersToAlert];
  return rv;
}

- (id)buildAlertStyle:(int)fp8
  title:(id)fp12
  message:(id)fp16
  first:(id)fp20
  second:(id)fp24
  third:(id)fp28
  oldStyle:(BOOL)fp32
  args:(char *)fp36
{
  id rv = [super buildAlertStyle:fp8
                           title:fp12
                         message:fp16
                           first:fp20
                          second:fp24
                           third:fp28
                        oldStyle:fp32
                            args:fp36];
  [self _addDatePickersToAlert];
  return rv;
}

- (void)onSwitchControl:(NSDatePicker *)which newDate:(NSDate **)newDate
{
  // Halt the delegate on the one we're setting first.
  if (which == _pickertop) {
    //NSLog(@"control event: top");
    [_pickerbottom setDelegate:nil];
    [_pickerbottom setDateValue:*newDate];
    [_pickerbottom setDelegate:_bottomdelegate];
  } else if (which == _pickerbottom) {
    //NSLog(@"control event: bottom");
    [_pickertop setDelegate:nil];
    [_pickertop setDateValue:*newDate];
    [_pickertop setDelegate:_topdelegate];
  } else
    NSLog(@"wtf");
}

- (NSDate *)date
{
  [self _ensureDatePickers];
  return [_pickertop dateValue];
}

- (void)setDate:(NSDate *)date
{
  [self _ensureDatePickers];
  [_pickertop setDateValue:date];
  [_pickerbottom setDateValue:date];
}

- (void)setMinDate:(NSDate *)date
{
  [self _ensureDatePickers];
  [_pickertop setMinDate:date];
  [_pickerbottom setMinDate:date];
}

- (void)setMaxDate:(NSDate *)date
{
  [self _ensureDatePickers];
  [_pickertop setMaxDate:date];
  [_pickerbottom setMaxDate:date];
}
@end

@implementation NSDoubleDatePicker(Private)
- (void)_ensureDatePickers
{
  if (!_pickertop) {
//  NSLog(@"picker init");
    _pickertop = [[NSDatePicker alloc] initWithFrame:NSMakeRect(10,10,295,154)];
    [_pickertop setDatePickerStyle:NSClockAndCalendarDatePickerStyle];
    [_pickertop setDatePickerElements:NSYearMonthDayDatePickerElementFlag];

    _topdelegate = [[NSDoubleDateDelegate alloc] init];
    [_topdelegate setParentAlert:self withSource:_pickertop];
    [_pickertop setDelegate:_topdelegate];

    _pickerbottom = [[NSDatePicker alloc] initWithFrame:NSMakeRect(10,10,295,154)];
    [_pickerbottom setDatePickerStyle:NSTextFieldAndStepperDatePickerStyle];
    [_pickerbottom setDatePickerElements:NSYearMonthDayDatePickerElementFlag];

    _bottomdelegate = [[NSDoubleDateDelegate alloc] init];
    [_bottomdelegate setParentAlert:self withSource:_pickerbottom];
    [_pickerbottom setDelegate:_bottomdelegate];
  }
}

- (void)_addDatePickersToAlert
{
  NSWindow *window = [self window];
  NSView *content = [window contentView];
  float padding = 10.0f;

  NSArray *subviews = [content subviews];
  NSEnumerator *en = [subviews objectEnumerator];
  NSView *subview = nil;
  NSTextField *messageText = nil;
  int count = 0;

  [self _ensureDatePickers];

  // Find the main text field.
  while (subview = [en nextObject]) {
    if ([subview isKindOfClass:[NSTextField class]]) {
      if (++count == 2)
        messageText = (NSTextField *)subview;
    }
  }
  if (messageText) {
    [content addSubview:_pickertop];
    [_pickertop sizeToFit];
    [content addSubview:_pickerbottom];
    [_pickerbottom sizeToFit];

    // Expand the alert window.
    NSRect windowFrame = [window frame];
    NSRect topPickerFrame = [_pickertop frame];
    NSRect bottomPickerFrame = [_pickerbottom frame];

    windowFrame.size.height += topPickerFrame.size.height + padding +
      bottomPickerFrame.size.height + padding;
    [window setFrame:windowFrame display:YES];

    // Insert the pickers below the main text field.
    topPickerFrame.origin.y = [messageText frame].origin.y -
      bottomPickerFrame.size.height - padding -
      topPickerFrame.size.height - padding;
    topPickerFrame.origin.x = [messageText frame].origin.x;

    bottomPickerFrame.origin.y = topPickerFrame.origin.y +
      topPickerFrame.size.height + padding;
    bottomPickerFrame.origin.x = topPickerFrame.origin.x;

    [_pickertop setFrame:topPickerFrame];
    [_pickerbottom setFrame:bottomPickerFrame];
    //NSLog(@"Picker installed");
  } else
    NSLog(@"Couldn't find message text, did not add pickers");
}
@end

using namespace mozilla;

NS_IMPL_ISUPPORTS(nsDatePicker, nsIDatePicker)

nsDatePicker::nsDatePicker()
{
  mHasDefault = false;
  mHasMin = false;
  mHasMax = false;
}

nsDatePicker::~nsDatePicker()
{
}

// XXX Not used
void
nsDatePicker::InitNative(nsIWidget *aParent, const nsAString& aTitle)
{
  mTitle = aTitle;
}

// Display the date dialog
NS_IMETHODIMP nsDatePicker::Show(int16_t *retval)
{
  NS_ENSURE_ARG_POINTER(retval);

  *retval = returnCancel;

  int16_t userClicksOK = GetDate();

  *retval = userClicksOK;
  return NS_OK;
}

// Returns |returnOK| if the user presses OK in the dialog.
int16_t
nsDatePicker::GetDate()
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;
  nsCOMPtr<nsIStringBundle> stringBundle;
  NSString *cancelString = @"Cancel";
  nsXPIDLString intlString;
  nsresult rv;

  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
  [formatter setDateFormat:@"yyyy-MM-dd"];

  nsCOMPtr<nsIStringBundleService> bundleSvc = do_GetService(NS_STRINGBUNDLE_CONTRACTID);
  rv = bundleSvc->CreateBundle("chrome://global/locale/commonDialogs.properties", getter_AddRefs(stringBundle));
  if (NS_SUCCEEDED(rv)) {
    stringBundle->GetStringFromName(MOZ_UTF16("Cancel"), getter_Copies(intlString));
    if (intlString)
      cancelString = [NSString stringWithCharacters:reinterpret_cast<const unichar*>(intlString.get())
                               length:intlString.Length()];
  }

  NSDoubleDatePicker *alert = [NSDoubleDatePicker
    alertWithMessageText:@" "// XXX: localize this eventually
           defaultButton:nil // "OK"
         alternateButton:cancelString // "Cancel"
             otherButton:nil // nothin'
    informativeTextWithFormat:@""];
  if (mHasDefault) {
    NSDate *newDate = [formatter dateFromString:nsCocoaUtils::ToNSString(mDefault)];
    if (newDate)
      [alert setDate:newDate];
  } else
    [alert setDate:[NSDate date]];
  if (mHasMin) {
    NSDate *newDate = [formatter dateFromString:nsCocoaUtils::ToNSString(mMinDate)];
    if (newDate)
      [alert setMinDate:newDate];
  }
  if (mHasMax) {
    NSDate *newDate = [formatter dateFromString:nsCocoaUtils::ToNSString(mMaxDate)];
    if (newDate)
      [alert setMaxDate:newDate];
  }

  nsCocoaUtils::PrepareForNativeAppModalDialog();
  int result = [alert runModal];
  nsCocoaUtils::CleanUpAfterNativeAppModalDialog();
  if (result == NSAlertAlternateReturn) // cancel
    return returnCancel;

  nsCocoaUtils::GetStringForNSString([formatter stringFromDate:[alert date]],
    mDate);

  return returnOK;
  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(returnCancel);
}

// XXX Not used currently, needs localization
// Sets the dialog title to whatever it should be.  If it fails, eh,
// the OS will provide a sensible default.
void
nsDatePicker::SetDialogTitle(const nsString& inTitle, id aPanel)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  [aPanel setTitle:[NSString stringWithCharacters:(const unichar*)inTitle.get() length:inTitle.Length()]];

  NS_OBJC_END_TRY_ABORT_BLOCK;
} 

NS_IMETHODIMP nsDatePicker::SetDefaultDate(const nsAString& aString)
{
  mDefault = aString;
  mHasDefault = true;
  return NS_OK;
}

NS_IMETHODIMP nsDatePicker::GetDefaultDate(nsAString& aString)
{
  return NS_ERROR_FAILURE;
}

NS_IMETHODIMP nsDatePicker::SetMinDate(const nsAString& aString)
{
  mHasMin = true;
  mMinDate = aString;
  return NS_OK;
}

NS_IMETHODIMP nsDatePicker::GetMinDate(nsAString& aString)
{
  return NS_ERROR_FAILURE;
}

NS_IMETHODIMP nsDatePicker::SetMaxDate(const nsAString& aString)
{
  mHasMax = true;
  mMaxDate = aString;
  return NS_OK;
}

NS_IMETHODIMP nsDatePicker::GetMaxDate(nsAString& aString)
{
  return NS_ERROR_FAILURE;
}

NS_IMETHODIMP nsDatePicker::GetSelectedDate(nsAString& aString)
{
  aString = mDate;
  return NS_OK;
}
