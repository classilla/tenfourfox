/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Time Picker widget for TenFourFox (C)2018 Cameron Kaiser */

/* IMPORTANT!
   Because the step determines how the NSDatePickers are configured and
   the time format (HH:mm or HH:mm:ss), it must be set *before* setting
   the default time and time range, if any. */

#import <Cocoa/Cocoa.h>

#include "nsTimePicker.h"
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

@class NSDoubleTimePicker; // forward declaration

@interface NSDoubleTimeDelegate : NSObject {
  NSDoubleTimePicker *_parentAlert;
  NSDatePicker *_source;
}

- (void)datePickerCell:(NSDatePickerCell *)aDatePickerCell
  validateProposedDateValue:(NSDate **)proposedDateValue
  timeInterval:(NSTimeInterval *)proposedTimeInterval;
- (void)setParentAlert:(NSDoubleTimePicker *)parentAlert
  withSource:(NSDatePicker *)source;
@end

@implementation NSDoubleTimeDelegate
- (void)datePickerCell:(NSDatePickerCell *)aDatePickerCell
  validateProposedDateValue:(NSDate **)proposedDateValue
  timeInterval:(NSTimeInterval *)proposedTimeInterval
{
  //NSLog(@"validate");
  [_parentAlert onSwitchControl:_source newDate:proposedDateValue];
}

- (void)setParentAlert:(NSDoubleTimePicker *)parentAlert
  withSource:(NSDatePicker *)source
{
  _parentAlert = parentAlert;
  _source = source;
}
@end

////// NSDoubleTimePicker
////// based on NSAlertCheckbox, http://cocoadev.github.io/NSAlertCheckbox/

@interface NSDoubleTimePicker : NSAlert {
  NSDatePicker *_pickertop;
  NSDatePicker *_pickerbottom;
  NSDoubleTimeDelegate *_topdelegate;
  NSDoubleTimeDelegate *_bottomdelegate;
  double step;
}

- (void)dealloc;
- (NSDoubleTimePicker *)datePicker:(NSString *)message
  defaultButton:(NSString *)defaultButton
  alternateButton:(NSString *)alternateButton
  otherButton:(NSString *)otherButton
  informativeTextWithFormat:(NSString *)format;
- (void)onSwitchControl:(NSDatePicker *)which newDate:(NSDate **)newDate;
- (void)setStep:(double)newStep;
- (NSDate *)time;
- (void)setTime:(NSDate *)time;
- (void)setMinTime:(NSDate *)time;
- (void)setMaxTime:(NSDate *)time;
@end

@interface NSDoubleTimePicker(Private)
- (void)_ensureDatePickers;
- (void)_addDatePickersToAlert;
@end

@implementation NSDoubleTimePicker

- (void)dealloc
{
//NSLog(@"dealloc");
  [_pickertop release];
  [_pickerbottom release];
  [_topdelegate release];
  [_bottomdelegate release];
  [super dealloc];
}

- (NSDoubleTimePicker *)datePicker:(NSString *)message
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
  return (NSDoubleTimePicker *)alert;
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

- (void)setStep:(double)newStep
{
  step = newStep;
}

- (NSDate *)time
{
  [self _ensureDatePickers];
  return [_pickertop dateValue];
}

- (void)setTime:(NSDate *)time
{
  [self _ensureDatePickers];
  [_pickertop setDateValue:time];
  [_pickerbottom setDateValue:time];
}

- (void)setMinTime:(NSDate *)time
{
  [self _ensureDatePickers];
  [_pickertop setMinDate:time];
  [_pickerbottom setMinDate:time];
}

- (void)setMaxTime:(NSDate *)time
{
  [self _ensureDatePickers];
  [_pickertop setMaxDate:time];
  [_pickerbottom setMaxDate:time];
}
@end

@implementation NSDoubleTimePicker(Private)
- (void)_ensureDatePickers
{
  if (!_pickertop) {
//  NSLog(@"picker init");
    _pickertop = [[NSDatePicker alloc] initWithFrame:NSMakeRect(10,10,295,154)];
    [_pickertop setDatePickerStyle:NSClockAndCalendarDatePickerStyle];
    if (step >= 60.0)
      [_pickertop setDatePickerElements:NSHourMinuteDatePickerElementFlag];
    else
      [_pickertop setDatePickerElements:NSHourMinuteSecondDatePickerElementFlag];

    _topdelegate = [[NSDoubleTimeDelegate alloc] init];
    [_topdelegate setParentAlert:self withSource:_pickertop];
    [_pickertop setDelegate:_topdelegate];

    _pickerbottom = [[NSDatePicker alloc] initWithFrame:NSMakeRect(10,10,295,154)];
    [_pickerbottom setDatePickerStyle:NSTextFieldAndStepperDatePickerStyle];
    if (step >= 60.0)
      [_pickerbottom setDatePickerElements:NSHourMinuteDatePickerElementFlag];
    else
      [_pickerbottom setDatePickerElements:NSHourMinuteSecondDatePickerElementFlag];

    _bottomdelegate = [[NSDoubleTimeDelegate alloc] init];
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

NS_IMPL_ISUPPORTS(nsTimePicker, nsITimePicker)

nsTimePicker::nsTimePicker()
{
  mHasDefault = false;
  mHasMin = false;
  mHasMax = false;
  mStep = 60.0;
}

nsTimePicker::~nsTimePicker()
{
}

// XXX Not used
void
nsTimePicker::InitNative(nsIWidget *aParent, const nsAString& aTitle)
{
  mTitle = aTitle;
}

// Display the date dialog
NS_IMETHODIMP nsTimePicker::Show(int16_t *retval)
{
  NS_ENSURE_ARG_POINTER(retval);

  *retval = returnCancel;

  int16_t userClicksOK = GetTime();

  *retval = userClicksOK;
  return NS_OK;
}

// Returns |returnOK| if the user presses OK in the dialog.
int16_t
nsTimePicker::GetTime()
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK_RETURN;
  nsCOMPtr<nsIStringBundle> stringBundle;
  NSString *cancelString = @"Cancel";
  nsXPIDLString intlString;
  nsresult rv;

  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
  if (mStep >= 60.0)
    [formatter setDateFormat:@"HH:mm"];
  else
    [formatter setDateFormat:@"HH:mm:ss"];

  nsCOMPtr<nsIStringBundleService> bundleSvc = do_GetService(NS_STRINGBUNDLE_CONTRACTID);
  rv = bundleSvc->CreateBundle("chrome://global/locale/commonDialogs.properties", getter_AddRefs(stringBundle));
  if (NS_SUCCEEDED(rv)) {
    stringBundle->GetStringFromName(MOZ_UTF16("Cancel"), getter_Copies(intlString));
    if (intlString)
      cancelString = [NSString stringWithCharacters:reinterpret_cast<const unichar*>(intlString.get())
                               length:intlString.Length()];
  }

  NSDoubleTimePicker *alert = [NSDoubleTimePicker
    alertWithMessageText:@" "// XXX: localize this eventually
           defaultButton:nil // "OK"
         alternateButton:cancelString // "Cancel"
             otherButton:nil // nothin'
    informativeTextWithFormat:@""];
  [alert setStep:mStep];
  if (mHasDefault) {
    NSDate *newTime = [formatter dateFromString:nsCocoaUtils::ToNSString(mDefault)];
    if (newTime)
      [alert setTime:newTime];
  } else
    [alert setTime:[NSDate date]];
  if (mHasMin) {
    NSDate *newTime = [formatter dateFromString:nsCocoaUtils::ToNSString(mMinTime)];
    if (newTime)
      [alert setMinTime:newTime];
  }
  if (mHasMax) {
    NSDate *newTime = [formatter dateFromString:nsCocoaUtils::ToNSString(mMaxTime)];
    if (newTime)
      [alert setMaxTime:newTime];
  }

  nsCocoaUtils::PrepareForNativeAppModalDialog();
  int result = [alert runModal];
  nsCocoaUtils::CleanUpAfterNativeAppModalDialog();
  if (result == NSAlertAlternateReturn) // cancel
    return returnCancel;

  nsCocoaUtils::GetStringForNSString([formatter stringFromDate:[alert time]],
    mTime);

  return returnOK;
  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(returnCancel);
}

// XXX Not used currently, needs localization
// Sets the dialog title to whatever it should be.  If it fails, eh,
// the OS will provide a sensible default.
void
nsTimePicker::SetDialogTitle(const nsString& inTitle, id aPanel)
{
  NS_OBJC_BEGIN_TRY_ABORT_BLOCK;

  [aPanel setTitle:[NSString stringWithCharacters:(const unichar*)inTitle.get() length:inTitle.Length()]];

  NS_OBJC_END_TRY_ABORT_BLOCK;
}

NS_IMETHODIMP nsTimePicker::SetDefaultTime(const nsAString& aString)
{
  mDefault = aString;
  mHasDefault = true;
  return NS_OK;
}

NS_IMETHODIMP nsTimePicker::GetDefaultTime(nsAString& aString)
{
  return NS_ERROR_FAILURE;
}

NS_IMETHODIMP nsTimePicker::SetMinTime(const nsAString& aString)
{
  mHasMin = true;
  mMinTime = aString;
  return NS_OK;
}

NS_IMETHODIMP nsTimePicker::GetMinTime(nsAString& aString)
{
  return NS_ERROR_FAILURE;
}

NS_IMETHODIMP nsTimePicker::SetMaxTime(const nsAString& aString)
{
  mHasMax = true;
  mMaxTime = aString;
  return NS_OK;
}

NS_IMETHODIMP nsTimePicker::GetMaxTime(nsAString& aString)
{
  return NS_ERROR_FAILURE;
}

NS_IMETHODIMP nsTimePicker::SetStep(const double aStep)
{
  mStep = aStep;
  return NS_OK;
}

NS_IMETHODIMP nsTimePicker::GetStep(double *aStep)
{
  return NS_ERROR_FAILURE;
}

NS_IMETHODIMP nsTimePicker::GetSelectedTime(nsAString& aString)
{
  aString = mTime;
  return NS_OK;
}
