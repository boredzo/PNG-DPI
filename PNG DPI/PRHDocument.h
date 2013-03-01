@interface PRHDocument : NSDocument

@property(nonatomic, readonly) CGFloat pixelsWide, pixelsTall;
@property(nonatomic) CGFloat centimetersWide, centimetersTall;
@property(nonatomic) CGFloat inchesWide, inchesTall;
@property(nonatomic) CGFloat pixelsPerInchWide, pixelsPerInchTall;
@property(nonatomic) CGFloat pixelsPerCentimeterWide, pixelsPerCentimeterTall;
@property(nonatomic) CGFloat pixelsPerMeterWide, pixelsPerMeterTall;

@end
