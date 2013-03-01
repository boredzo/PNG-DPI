#import "PRHDocument.h"

static const CGFloat centimetersPerMeter = 100.0;

static const CGFloat centimetersPerInch = 2.54;
static const CGFloat inchesPerCentimeter = 1.0 / centimetersPerInch;
static const CGFloat inchesPerMeter = inchesPerCentimeter * centimetersPerMeter;

@interface PRHDocument ()

@property(nonatomic, strong) NSMutableDictionary *propertiesDictionary;

@end

@implementation PRHDocument
{
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
	return [self.propertiesDictionary[(__bridge NSString *)kCGImagePropertyPixelWidth] doubleValue];
}

- (CGFloat) pixelsTall {
	return [self.propertiesDictionary[(__bridge NSString *)kCGImagePropertyPixelHeight] doubleValue];
}

+ (NSSet *) keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *baseSet = [super keyPathsForValuesAffectingValueForKey:key];

	NSRange keyRange = (NSRange){ 0, [key length] };
	NSRegularExpression *regularExpression;
	NSTextCheckingResult *result;

	regularExpression = [NSRegularExpression regularExpressionWithPattern:@"(inch|centimeter)e?s(Wide|Tall)"
	                                                             options:0
		                                                           error:NULL];
	result = [regularExpression firstMatchInString:key options:NSMatchingAnchored range:keyRange];
	if (result) {
		//This is a (unit)s(axis) key.
		NSString *unit = [key substringWithRange:[result rangeAtIndex:1]];
		NSMutableSet *otherUnits = [self setOfUnitsThatAreNot:unit];
		NSString *axis = [key substringWithRange:[result rangeAtIndex:2]];
		NSMutableSet *set = [[baseSet setByAddingObjectsFromArray:@[
			@"propertiesDictionary",
			[@"pixels" stringByAppendingString:axis],
			[@"pixelsPerInch" stringByAppendingString:axis],
			[@"pixelsPerCentimeter" stringByAppendingString:axis],
		]] mutableCopy];
		for (unit in otherUnits) {
			[set addObject:[[self pluralizeUnit:unit]
				stringByAppendingString:axis]];
		}
		return set;
	}

	regularExpression = [NSRegularExpression regularExpressionWithPattern:@"pixelsPer(Inch|Centimeter)(Wide|Tall)"
	                                                              options:0
		                                                            error:NULL];
	result = [regularExpression firstMatchInString:key options:NSMatchingAnchored range:keyRange];
	if (result) {
		//This is a pixelsPer(unit)(axis) key.
		NSString *unit = [[key substringWithRange:[result rangeAtIndex:1]] lowercaseString];
		NSMutableSet *otherUnits = [self setOfUnitsThatAreNot:unit];
		NSString *axis = [key substringWithRange:[result rangeAtIndex:2]];
		NSMutableSet *set = [[baseSet setByAddingObjectsFromArray:@[
			@"propertiesDictionary",
			[@"pixels" stringByAppendingString:axis],
			[@"inches" stringByAppendingString:axis],
			[@"centimeters" stringByAppendingString:axis],
		]] mutableCopy];
		for (unit in otherUnits) {
			[set addObject:[[@"pixelsPer" stringByAppendingString:unit]
				stringByAppendingString:axis]];
		}
		return set;
	}

	if ([key hasPrefix:@"pixels"]) {
		//This is a pixels(axis) key.
		return [baseSet setByAddingObject:@"propertiesDictionary"];
	}

	//No match.
	return baseSet;
}

+ (NSString *) pluralizeUnit:(NSString *)unit {
	return [unit isEqualToString:@"inch"]
		? @"es"
		: @"s";
}

+ (NSMutableSet *) setOfUnitsThatAreNot:(NSString *)unit {
	NSMutableSet *allUnits = [NSMutableSet setWithArray:@[
		@"inch", @"centimeter"
	]];
	[allUnits removeObject:unit];
	return allUnits;
}

- (CGFloat) centimetersWide {
	return self.pixelsWide / self.pixelsPerCentimeterWide;
}
- (void) setCentimetersWide:(CGFloat)centimetersWide {
	[[[self undoManager] prepareWithInvocationTarget:self] setPixelsPerCentimeterWide:self.pixelsPerCentimeterWide];
	self.pixelsPerCentimeterWide = self.pixelsWide / centimetersWide;
}

- (CGFloat) centimetersTall {
	return self.pixelsTall / self.pixelsPerCentimeterTall;
}
- (void) setCentimetersTall:(CGFloat)centimetersTall {
	[[[self undoManager] prepareWithInvocationTarget:self] setPixelsPerCentimeterTall:self.pixelsPerCentimeterTall];
	self.pixelsPerCentimeterTall = self.pixelsTall / centimetersTall;
}

- (CGFloat) inchesWide {
	return self.pixelsWide / self.pixelsPerInchWide;
}
- (void) setInchesWide:(CGFloat)inchesWide {
	[[[self undoManager] prepareWithInvocationTarget:self] setInchesWide:self.inchesWide];
	self.pixelsPerInchWide = self.pixelsWide / inchesWide;
}

- (CGFloat) inchesTall {
	return self.pixelsTall / self.pixelsPerInchTall;
}
- (void) setInchesTall:(CGFloat)inchesTall {
	[[[self undoManager] prepareWithInvocationTarget:self] setInchesTall:self.inchesTall];
	self.pixelsPerInchTall = self.pixelsTall / inchesTall;
}

- (CGFloat) pixelsPerInchWide {
	NSNumber *widthNum = self.propertiesDictionary[(__bridge NSString *)kCGImagePropertyDPIWidth];
	return widthNum
		? [widthNum doubleValue]
		: self.pixelsPerMeterWide / inchesPerMeter;
}
- (void) setPixelsPerInchWide:(CGFloat)pixelsPerInchWide {
	[[[self undoManager] prepareWithInvocationTarget:self] setPixelsPerInchWide:self.pixelsPerInchWide];
	CGFloat pixelsPerMeterWide = pixelsPerInchWide * inchesPerMeter;
	[self setPixelsPerInchWide:pixelsPerInchWide andPixelsPerMeterWide:pixelsPerMeterWide];
}

- (CGFloat) pixelsPerInchTall {
	NSNumber *heightNum = self.propertiesDictionary[(__bridge NSString *)kCGImagePropertyDPIHeight];
	return heightNum
		? [heightNum doubleValue]
		: self.pixelsPerMeterTall / inchesPerMeter;
}
- (void) setPixelsPerInchTall:(CGFloat)pixelsPerInchTall {
	[[[self undoManager] prepareWithInvocationTarget:self] setPixelsPerInchTall:self.pixelsPerInchTall];
	CGFloat pixelsPerMeterTall = pixelsPerInchTall * inchesPerMeter;
	[self setPixelsPerInchTall:pixelsPerInchTall andPixelsPerMeterTall:pixelsPerMeterTall];
}

- (void) setPixelsPerInchWide:(CGFloat)pixelsPerInchWide andPixelsPerMeterWide:(CGFloat)pixelsPerMeterWide {
	self.propertiesDictionary[(__bridge NSString *)kCGImagePropertyDPIWidth] = @(pixelsPerInchWide);
	self.propertiesDictionary[(__bridge NSString *)kCGImagePropertyPNGDictionary][(__bridge NSString *)kCGImagePropertyPNGXPixelsPerMeter] = @(pixelsPerMeterWide);
}
- (void) setPixelsPerInchTall:(CGFloat)pixelsPerInchTall andPixelsPerMeterTall:(CGFloat)pixelsPerMeterTall {
	self.propertiesDictionary[(__bridge NSString *)kCGImagePropertyDPIHeight] = @(pixelsPerInchTall);
	self.propertiesDictionary[(__bridge NSString *)kCGImagePropertyPNGDictionary][(__bridge NSString *)kCGImagePropertyPNGYPixelsPerMeter] = @(pixelsPerMeterTall);
}

- (CGFloat) pixelsPerCentimeterWide {
	return self.pixelsPerMeterWide / centimetersPerMeter;
}
- (void) setPixelsPerCentimeterWide:(CGFloat)pixelsPerCentimeterWide {
	[[[self undoManager] prepareWithInvocationTarget:self] setPixelsPerCentimeterWide:self.pixelsPerCentimeterWide];
	self.pixelsPerMeterWide = pixelsPerCentimeterWide * centimetersPerMeter;
}

- (CGFloat) pixelsPerCentimeterTall {
	return self.pixelsPerMeterTall / centimetersPerMeter;
}
- (void) setPixelsPerCentimeterTall:(CGFloat)pixelsPerCentimeterTall {
	[[[self undoManager] prepareWithInvocationTarget:self] setPixelsPerCentimeterTall:self.pixelsPerCentimeterTall];
	self.pixelsPerMeterTall = pixelsPerCentimeterTall * centimetersPerMeter;
}

- (CGFloat) pixelsPerMeterWide {
	return [self.propertiesDictionary[(__bridge NSString *)kCGImagePropertyPNGDictionary][(__bridge NSString *)kCGImagePropertyPNGXPixelsPerMeter] doubleValue];
}
- (void) setPixelsPerMeterWide:(CGFloat)pixelsPerMeterWide {
	[[[self undoManager] prepareWithInvocationTarget:self] setPixelsPerMeterWide:self.pixelsPerMeterWide];
	CGFloat pixelsPerInchWide = pixelsPerMeterWide / inchesPerMeter;
	[self setPixelsPerInchWide:pixelsPerInchWide andPixelsPerMeterWide:pixelsPerMeterWide];
}

- (CGFloat) pixelsPerMeterTall {
	return [self.propertiesDictionary[(__bridge NSString *)kCGImagePropertyPNGDictionary][(__bridge NSString *)kCGImagePropertyPNGYPixelsPerMeter] doubleValue];
}
- (void) setPixelsPerMeterTall:(CGFloat)pixelsPerMeterTall {
	[[[self undoManager] prepareWithInvocationTarget:self] setPixelsPerMeterTall:self.pixelsPerMeterTall];
	CGFloat pixelsPerInchTall = pixelsPerMeterTall / inchesPerMeter;
	[self setPixelsPerInchTall:pixelsPerInchTall andPixelsPerMeterTall:pixelsPerMeterTall];
}

- (BOOL) readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	NSDictionary *sourceOptions = @{ (__bridge NSString *)kCGImageSourceTypeIdentifierHint: (__bridge NSString *)kUTTypePNG };
	_imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, (__bridge CFDictionaryRef)sourceOptions);

	self.propertiesDictionary = [[self extractImagePropertiesFromSource:_imageSource] mutableCopy];

	return (self.propertiesDictionary != nil);
}

- (BOOL) readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
	NSDictionary *sourceOptions = @{ (__bridge NSString *)kCGImageSourceTypeIdentifierHint: (__bridge NSString *)kUTTypePNG };
	_imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, (__bridge CFDictionaryRef)sourceOptions);

	self.propertiesDictionary = [[self extractImagePropertiesFromSource:_imageSource] mutableCopy];

	return (self.propertiesDictionary != nil);
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
		(__bridge CFDictionaryRef)self.propertiesDictionary
	);
	bool finalized = CGImageDestinationFinalize(imageDestination);
	CFRelease(imageDestination);
	return finalized;
}

@end
