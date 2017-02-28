//
//  NSDictionary+MTLJSONKeyPath.m
//  Mantle
//
//  Created by Robert Böhnke on 19/03/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "NSDictionary+MTLJSONKeyPath.h"

#import "MTLJSONAdapter.h"

@implementation NSDictionary (MTLJSONKeyPath)

- (id)mtl_valueForJSONKeyPath:(NSString *)JSONKeyPath success:(BOOL *)success error:(NSError **)error {
	NSScanner *scanner = [[NSScanner alloc] initWithString:JSONKeyPath];
	scanner.charactersToBeSkipped = [NSCharacterSet new];
	
	NSMutableString *buffer = [NSMutableString new];
	NSMutableArray *components = [NSMutableArray new];
	NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@"\\."];
	while (scanner.scanLocation < JSONKeyPath.length) {
		NSString *result = nil;
		if ([scanner scanUpToCharactersFromSet:separatorSet intoString:&result])
			[buffer appendString:result];
		
		NSUInteger scanLocation = scanner.scanLocation;
		if (scanLocation >= JSONKeyPath.length)
			break;
		
		unichar character = [JSONKeyPath characterAtIndex:scanLocation];
		if (character == '\\') {
			if (scanLocation + 1 < JSONKeyPath.length) {
				unichar literal = [JSONKeyPath characterAtIndex:(scanLocation + 1)];
				if (literal == '.') {
					[buffer appendString:@"."];
					scanner.scanLocation = (scanLocation + 2);
					continue;
				}
			}
			[buffer appendString:@"\\"];
		} else if (character == '.') {
			[components addObject:buffer];
			buffer = [NSMutableString new];
		}
		
		scanner.scanLocation = (scanLocation + 1);
	}
	
	[components addObject:buffer];

	id result = self;
	for (NSString *component in components) {
		// Check the result before resolving the key path component to not
		// affect the last value of the path.
		if (result == nil || result == NSNull.null) break;

		if (![result isKindOfClass:NSDictionary.class]) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid JSON dictionary", @""),
					NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"JSON key path %1$@ could not resolved because an incompatible JSON dictionary was supplied: \"%2$@\"", @""), JSONKeyPath, self]
				};

				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
			}

			if (success != NULL) *success = NO;

			return nil;
		}

		result = result[component];
	}

	if (success != NULL) *success = YES;

	return result;
}

@end
