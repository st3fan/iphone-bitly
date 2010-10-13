// URLShortenerCredentials.m

#import "URLShortenerCredentials.h"

@implementation URLShortenerCredentials

@synthesize login = _login, key = _key;

- (void) dealloc
{
	[_login release];
	[_key release];
	[super dealloc];
}

@end