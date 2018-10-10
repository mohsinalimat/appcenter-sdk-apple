#import <Foundation/Foundation.h>

#import "MSSerializableObject.h"

static NSString *const kMSTypedPropertyValue = @"value";

@interface MSTypedProperty : NSObject <MSSerializableObject>

/**
 * Property type.
 */
@property(nonatomic, copy) NSString *type;

/**
* Property name.
*/
@property(nonatomic, copy) NSString *name;

@end
