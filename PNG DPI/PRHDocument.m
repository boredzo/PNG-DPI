#import "PRHDocument.h"

static const CGFloat centimetersPerMeter = 100.0;

static const CGFloat centimetersPerInch = 2.54;
static const CGFloat inchesPerCentimeter = 1.0 / centimetersPerInch;
static const CGFloat inchesPerMeter = inchesPerCentimeter * centimetersPerMeter;

@implementation PRHDocument
{
	NSMutableDictionary *_props;
	CGImageSourceRef _imageSource;
}

- (id) init {
	self = [super init];
	if (self) {
	}
	return self;
}

- (void) dealloc {
	CFRelease(_imageSource);
}

- (NSString *) windowNibName {
	return @"PRHDocument";
}

- (void) windowControllerDidLoadNib:(NSWindowController *)aController {
	[super windowControllerDidLoadNib:aController];
}

+ (BOOL) autosavesInPlace {
	return YES;
}

- (CGFloat) pixelsWide {
	return [_props[(__bridge NSString *)kCGImagePropertyPixelWidth] doubleValue];
}

- (CGFloat) pixelsTall {
	return [_props[(__bridge NSString *)kCGImagePropertyPixelHeight] doubleValue];
}

- (CGFloat) centimetersWide {
	return self.pixelsWide / self.pixelsPerCentimeterWide;
}
- (void) setCentimetersWide:(CGFloat)centimetersWide {
	self.pixelsPerCentimeterWide = self.pixelsWide / centimetersWide;
}

- (CGFloat) centimetersTall {
	return self.pixelsTall / self.pixelsPerCentimeterTall;
}
- (void) setCentimetersTall:(CGFloat)centimetersTall {
	self.pixelsPerCentimeterTall = self.pixelsTall / centimetersTall;
}

- (CGFloat) inchesWide {
	return self.pixelsWide / self.pixelsPerInchWide;
}
- (void) setInchesWide:(CGFloat)inchesWide {
	self.pixelsPerInchWide = self.pixelsWide / inchesWide;
}

- (CGFloat) inchesTall {
	return self.pixelsTall / self.pixelsPerInchTall;
}
- (void) setInchesTall:(CGFloat)inchesTall {
	self.pixelsPerInchTall = self.pixelsTall / inchesTall;
}

- (CGFloat) pixelsPerInchWide {
	return [_props[(__bridge NSString *)kCGImagePropertyDPIWidth] doubleValue];
}
- (void) setPixelsPerInchWide:(CGFloat)pixelsPerInchWide {
	CGFloat pixelsPerMeterWide = pixelsPerInchWide * inchesPerMeter;
	[self setPixelsPerInchWide:pixelsPerInchWide andPixelsPerMeterWide:pixelsPerMeterWide];
}

- (CGFloat) pixelsPerInchTall {
	return [_props[(__bridge NSString *)kCGImagePropertyDPIHeight] doubleValue];
}
- (void) setPixelsPerInchTall:(CGFloat)pixelsPerInchTall {
	CGFloat pixelsPerMeterTall = pixelsPerInchTall * inchesPerMeter;
	[self setPixelsPerInchTall:pixelsPerInchTall andPixelsPerMeterTall:pixelsPerMeterTall];
}

- (void) setPixelsPerInchWide:(CGFloat)pixelsPerInchWide andPixelsPerMeterWide:(CGFloat)pixelsPerMeterWide {
	_props[(__bridge NSString *)kCGImagePropertyDPIWidth] = @(pixelsPerInchWide);
	_props[(__bridge NSString *)kCGImagePropertyPNGDictionary][(__bridge NSString *)kCGImagePropertyPNGXPixelsPerMeter] = @(pixelsPerMeterWide);
}
- (void) setPixelsPerInchTall:(CGFloat)pixelsPerInchTall andPixelsPerMeterTall:(CGFloat)pixelsPerMeterTall {
	_props[(__bridge NSString *)kCGImagePropertyDPIHeight] = @(pixelsPerInchTall);
	_props[(__bridge NSString *)kCGImagePropertyPNGDictionary][(__bridge NSString *)kCGImagePropertyPNGYPixelsPerMeter] = @(pixelsPerMeterTall);
}

- (CGFloat) pixelsPerCentimeterWide {
	return self.pixelsPerMeterWide / centimetersPerMeter;
}
- (void) setPixelsPerCentimeterWide:(CGFloat)pixelsPerCentimeterWide {
	self.pixelsPerMeterWide = pixelsPerCentimeterWide * centimetersPerMeter;
}

- (CGFloat) pixelsPerCentimeterTall {
	return self.pixelsPerMeterTall / centimetersPerMeter;
}
- (void) setPixelsPerCentimeterTall:(CGFloat)pixelsPerCentimeterTall {
	self.pixelsPerMeterTall = pixelsPerCentimeterTall * centimetersPerMeter;
}

- (CGFloat) pixelsPerMeterWide {
	return [_props[(__bridge NSString *)kCGImagePropertyPNGDictionary][(__bridge NSString *)kCGImagePropertyPNGXPixelsPerMeter] doubleValue];
}
- (void) setPixelsPerMeterWide:(CGFloat)pixelsPerMeterWide {
	CGFloat pixelsPerInchWide = pixelsPerMeterWide / inchesPerMeter;
	[self setPixelsPerInchWide:pixelsPerInchWide andPixelsPerMeterWide:pixelsPerMeterWide];
}

- (CGFloat) pixelsPerMeterTall {
	return [_props[(__bridge NSString *)kCGImagePropertyPNGDictionary][(__bridge NSString *)kCGImagePropertyPNGYPixelsPerMeter] doubleValue];
}
- (void) setPixelsPerMeterTall:(CGFloat)pixelsPerMeterTall {
	CGFloat pixelsPerInchTall = pixelsPerMeterTall / inchesPerMeter;
	[self setPixelsPerInchTall:pixelsPerInchTall andPixelsPerMeterTall:pixelsPerMeterTall];
}

- (BOOL) readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	NSDictionary *sourceOptions = @{ (__bridge NSString *)kCGImageSourceTypeIdentifierHint: (__bridge NSString *)kUTTypePNG };
	_imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, (__bridge CFDictionaryRef)sourceOptions);

	_props = [[self extractImagePropertiesFromSource:_imageSource] mutableCopy];

	return (_props != nil);
}

- (BOOL) readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
	NSDictionary *sourceOptions = @{ (__bridge NSString *)kCGImageSourceTypeIdentifierHint: (__bridge NSString *)kUTTypePNG };
	_imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, (__bridge CFDictionaryRef)sourceOptions);

	_props = [[self extractImagePropertiesFromSource:_imageSource] mutableCopy];

	return (_props != nil);
}

- (NSDictionary *) extractImagePropertiesFromSource:(CGImageSourceRef)imageSource {
	NSDictionary *copyPropsOptions = @{
		(__bridge NSString *)kCGImageSourceShouldCache : (__bridge NSNumber *)kCFBooleanFalse,
	};
	CFDictionaryRef props = CGImageSourceCopyPropertiesAtIndex(imageSource, /*idx*/ 0, (__bridge CFDictionaryRef)copyPropsOptions);
	return (__bridge_transfer NSDictionary *)props;
}

- (NSData *) dataOfType:(NSString *)typeName error:(NSError **)outError {
	NSMutableData *mutableData = [NSMutableData data];
	CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData,
		(__bridge CFStringRef)typeName, /*count*/ 1,
		/*options*/ NULL
	);
	return [self writeToDestination:imageDestination]
		? mutableData
		: nil;
}

- (BOOL) writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
	CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, (__bridge CFStringRef)typeName, /*count*/ 1,
		/*options*/ NULL
	);
	return [self writeToDestination:imageDestination];
}


- (bool) writeToDestination:(CGImageDestinationRef)imageDestination {
	CGImageDestinationAddImageFromSource(imageDestination, _imageSource, /*idx*/ 0,
		(__bridge CFDictionaryRef)_props
	);
	bool finalized = CGImageDestinationFinalize(imageDestination);
	CFRelease(imageDestination);
	return finalized;
}

@end
