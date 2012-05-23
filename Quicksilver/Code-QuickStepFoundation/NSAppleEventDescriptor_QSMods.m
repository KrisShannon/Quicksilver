//
// NSAppleEventDescriptor+NDAppleScriptObject_QSMods.m
// Quicksilver
//
// Created by Alcor on 8/19/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "NSAppleEventDescriptor_QSMods.h"
#import "NSURL+NDCarbonUtilities.h"

@implementation NSAppleEventDescriptor (NDAppleScriptObject_QSMods)

+ (NSAppleEventDescriptor *)targetDescriptorWithTypeSignature:(OSType)type {
	return [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:(void*)&type length:sizeof(type)];
}

- (NSAppleEventDescriptor *)AESend {
	[self AESendWithSendMode:kAENoReply priority:kAENormalPriority timeout:100];
	return nil;
}

#warning 64BIT: Inspect use of long
- (NSAppleEventDescriptor *)AESendWithSendMode:(AESendMode)sendMode priority:(AESendPriority)priority timeout:(long)timeout {
	AppleEvent reply;
	OSStatus err = AESend([self aeDesc] , &reply, sendMode, priority, timeout, NULL, NULL);
	if (err) {
#warning 64BIT: Inspect use of long
		NSLog(@"sendAppleEventError %ld", (long)err);
		return nil;
	} else {
		AEDisposeDesc(&reply);
		return [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&reply];
	}
}

//[self appleEventWithEventClass:kCoreEventClass eventID:kAEQuitApplication targetDescriptor:aTargetDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID] : nil;
@end
