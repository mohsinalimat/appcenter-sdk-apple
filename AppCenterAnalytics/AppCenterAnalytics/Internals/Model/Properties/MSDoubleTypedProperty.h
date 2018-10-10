#import <Foundation/Foundation.h>

#import "MSTypedProperty.h"

@interface MSDoubleTypedProperty : MSTypedProperty

/**
 * Double property value. Saved as NSNumber
 */
@property(nonatomic) double value;

@end