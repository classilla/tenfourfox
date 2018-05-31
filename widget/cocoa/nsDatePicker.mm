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

////// NSPopUpDatePicker
////// based on NSAlertCheckbox, http://cocoadev.github.io/NSAlertCheckbox/

@interface NSPopUpDatePicker : NSAlert {
  NSDatePicker *_picker;
}

- (void)dealloc;
- (NSPopUpDatePicker *)datePicker:(NSString *)message
  defaultButton:(NSString *)defaultButton
  alternateButton:(NSString *)alternateButton
  otherButton:(NSString *)otherButton
  informativeTextWithFormat:(NSString *)format;
- (NSDate *)date;
- (void)setDate:(NSDate *)date;
@end

@interface NSPopUpDatePicker(Private)
- (void)_ensureDatePicker;
- (void)_addDatePickerToAlert;
@end

@implementation NSPopUpDatePicker

- (void)dealloc
{
  [_picker release];
  [super dealloc];
}

- (NSPopUpDatePicker *)datePicker:(NSString *)message
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
  return (NSPopUpDatePicker *)alert;
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
  [self _addDatePickerToAlert];
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
  [self _addDatePickerToAlert];
  return rv;
}

- (NSDate *)date
{
  [self _ensureDatePicker];
  return [_picker dateValue];
}

- (void)setDate:(NSDate *)date
{
  [self _ensureDatePicker];
  [_picker setDateValue:date];
}
@end

@implementation NSPopUpDatePicker(Private)
- (void)_ensureDatePicker
{
  if (!_picker) {
    _picker = [[NSDatePicker alloc] initWithFrame:NSMakeRect(10,10,295,154)];
    [_picker setDatePickerStyle:NSClockAndCalendarDatePickerStyle];
    [_picker setDatePickerElements:NSYearMonthDayDatePickerElementFlag];
  }
}
- (void)_addDatePickerToAlert
{
  NSWindow *window = [self window];
  NSView *content = [window contentView];
  float padding = 14.0f;
	
  NSArray *subviews = [content subviews];
  NSEnumerator *en = [subviews objectEnumerator];
  NSView *subview = nil;
  NSTextField *messageText = nil;
  int count = 0;
	
  [self _ensureDatePicker];
	
  // Find the main text field.
  while (subview = [en nextObject]) {
    if ([subview isKindOfClass:[NSTextField class]]) {
      if (++count == 2)
        messageText = (NSTextField *)subview;
    }
  }
  if (messageText) {
    [content addSubview:_picker];
    [_picker sizeToFit];
		
    // Expand the alert window.
    NSRect windowFrame = [window frame];
    NSRect pickerFrame = [_picker frame];
		
    windowFrame.size.height += pickerFrame.size.height + padding;
    [window setFrame:windowFrame display:YES];
		
    // Insert the picker below the main text field.
    pickerFrame.origin.y = [messageText frame].origin.y -
                            pickerFrame.size.height - padding;
    pickerFrame.origin.x = [messageText frame].origin.x;
		
    [_picker setFrame:pickerFrame];
  } else
    fprintf(stderr, "Could not insinuate modal NSDatePicker.\n");
}
@end

using namespace mozilla;

NS_IMPL_ISUPPORTS(nsDatePicker, nsIDatePicker)

nsDatePicker::nsDatePicker()
{
  mHasDefault = false;
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
  int16_t retVal = returnCancel;
  
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
  [formatter setDateFormat:@"yyyy-MM-dd"];
  NSPopUpDatePicker *alert = [NSPopUpDatePicker
    alertWithMessageText:@"One"
           defaultButton:@"OK"
         alternateButton:@"Cancel"
             otherButton:nil
    informativeTextWithFormat:@"Blah blah"];
  if (mHasDefault) {
    NSDate *newDate = [formatter dateFromString:nsCocoaUtils::ToNSString(mDefault)];
    [alert setDate:newDate];
  } else
    [alert setDate:[NSDate date]];

  nsCocoaUtils::PrepareForNativeAppModalDialog();
  int result = [alert runModal]; //[NSApp runModalForWindow:pwin];
  nsCocoaUtils::CleanUpAfterNativeAppModalDialog();
  if (result == NSFileHandlingPanelCancelButton)
    return retVal;

  nsCocoaUtils::GetStringForNSString([formatter stringFromDate:[alert date]],
    mDate);

  return retVal;
  NS_OBJC_END_TRY_ABORT_BLOCK_RETURN(returnCancel);
}

// XXX Not used
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
  mMinDate = aString;
  return NS_OK;
}

NS_IMETHODIMP nsDatePicker::GetMinDate(nsAString& aString)
{
  return NS_ERROR_FAILURE;
}

NS_IMETHODIMP nsDatePicker::SetMaxDate(const nsAString& aString)
{
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
