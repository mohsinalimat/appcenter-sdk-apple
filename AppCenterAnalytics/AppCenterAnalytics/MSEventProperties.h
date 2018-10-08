#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains typed event properties.
 */
@interface MSEventProperties : NSObject

/**
 * Set a string property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (void)setString:(NSString *)value
           forKey:(NSString *)key;

/**
 * Set a double property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (void)setDouble:(double)value forKey:(NSString *)key;

/**
 * Set a 64-bit integer property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (void)setInt64:(int64_t)value forKey:(NSString *)key;

/**
 * Set a boolean property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (void)setBool:(BOOL)value forKey:(NSString *)key;

/**
 * Set a Date property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (void)setDate:(NSDate *)value forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END