/*
 * QSUTI.c
 * Quicksilver
 *
 * Created by Alcor on 4/5/05.
 * Copyright 2005 Blacktree. All rights reserved.
 *
 */

#include "QSUTI.h"

BOOL QSIsUTI(NSString *UTIString) {
    return UTTypeConformsTo((__bridge CFStringRef)UTIString, (__bridge CFStringRef)@"public.item") || ([UTIString rangeOfString:@"."].location != NSNotFound && [UTIString rangeOfString:@"."].location != 0);
}

/**
 *  Returns whether a uniform type identifier conforms to another uniform type identifier. It's better than the UTType function. See discussion
 *
 *  @param inUTI           A uniform type identifier to compare.
 *  @param inConformsToUTI The uniform type identifier to compare it to.
 *
 *  @return Returns true if the uniform type identifier is equal to or conforms to the second type.
 *
 *  @discussion The UTTypeConformsTo() function isn't great in all cases. If a UTI for an unknown file extension has been created (e.g. "dyn-xxxxx" was created for the extension "myextension"), and subsequently an application regisers the extension "myextension" with the UTI "com.me.myextension", the OS will not say that "dyn-xxxxx" conforms to "com.me.myextension" (or vice-versa) when, in fact, they do. This function first resolves the extensions for the two UTIs, then attempts to convert them back to UTIs in order to check for UTI conformance
 */
BOOL QSTypeConformsTo(NSString *inUTI, NSString *inConformsToUTI) {
    if (UTTypeConformsTo((__bridge CFStringRef)inUTI, (__bridge CFStringRef)inConformsToUTI)) {
        return YES;
    }
    CFStringRef inUTIExtension = UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)inUTI, kUTTagClassFilenameExtension);
    NSString *resolvedInUTI = nil;
    if (inUTIExtension) {
        resolvedInUTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, inUTIExtension, NULL);
        CFRelease(inUTIExtension);
    }
    CFStringRef inConformsToUTIExtension = UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)inConformsToUTI, kUTTagClassFilenameExtension);
    NSString *resolvedInConformsToUTI = nil;
    if (inConformsToUTIExtension) {
        resolvedInConformsToUTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, inConformsToUTIExtension, NULL);
        CFRelease(inConformsToUTIExtension);
    }
    return UTTypeConformsTo((__bridge CFStringRef)(resolvedInUTI ? resolvedInUTI : inUTI), (__bridge CFStringRef)(resolvedInConformsToUTI ? resolvedInConformsToUTI : inConformsToUTI));
}

NSString *QSUTIOfURL(NSURL *fileURL) {
    LSItemInfoRecord infoRec;
	LSCopyItemInfoForURL((__bridge CFURLRef)fileURL, kLSRequestTypeCreator|kLSRequestBasicFlagsOnly, &infoRec);
	return QSUTIWithLSInfoRec([fileURL path], &infoRec);
}

NSString *QSUTIOfFile(NSString *path) {
    LSItemInfoRecord infoRec;
	LSCopyItemInfoForURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], kLSRequestTypeCreator|kLSRequestBasicFlagsOnly, &infoRec);
	return QSUTIWithLSInfoRec(path, &infoRec);
}

NSString *QSUTIWithLSInfoRec(NSString *path, LSItemInfoRecord *infoRec) {
	NSString *extension = [path pathExtension];
	if (![extension length])
		extension = nil;
	BOOL isDirectory;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory])
		return nil;

	if (infoRec->flags & kLSItemInfoIsAliasFile)
		return (NSString *)kUTTypeAliasFile;
	if (infoRec->flags & kLSItemInfoIsVolume)
		return (NSString *)kUTTypeVolume;

	NSString *extensionUTI = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL));
	if (extensionUTI && ![extensionUTI hasPrefix:@"dyn"])
		return extensionUTI;

	NSString *hfsType = (NSString *)CFBridgingRelease(UTCreateStringForOSType(infoRec->filetype));
	if (![hfsType length] && isDirectory)
		return (NSString *)kUTTypeFolder;

	NSString *hfsUTI = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType, (__bridge CFStringRef)hfsType, NULL));
	if (![hfsUTI hasPrefix:@"dyn"])
		return hfsUTI;

	if ([[NSFileManager defaultManager] isExecutableFileAtPath:path])
		return @"public.executable";

	return (extensionUTI ? extensionUTI : hfsUTI);
}

NSString *QSUTIForAnyTypeString(NSString *type) {
	NSString *itemUTI = NULL;

	OSType filetype = 0;
	NSString *extension = nil;

	if ([type hasPrefix:@"'"] && [type length] == 6)
		filetype = NSHFSTypeCodeFromFileType(type);
	else
		extension = type;
	itemUTI = QSUTIForExtensionOrType(extension, filetype);
	if ([itemUTI hasPrefix:@"dyn"])
		itemUTI = nil;
	return itemUTI;
}


// WARNING: This does not necessarily return the correct UTI. QSUTIWithLSInfoRec() is more reliable
NSString *QSUTIForExtensionOrType(NSString *extension, OSType filetype) {
	NSString *itemUTI = nil;

	if (extension != nil) {
		itemUTI = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL));
	} else {
		CFStringRef fileTypeUTI = UTCreateStringForOSType(filetype);
		itemUTI = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType, fileTypeUTI, NULL));
		CFRelease(fileTypeUTI);
	}
	return itemUTI;
}

/* Deprecated */
NSString *QSUTIForInfoRec(NSString *extension, OSType filetype) {
	return QSUTIForExtensionOrType(extension, filetype);
}

