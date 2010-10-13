// URLShortenerCredentials.h

#import <Foundation/Foundation.h>

@interface URLShortenerCredentials : NSObject {
  @private
	NSString* _login;
	NSString* _key;
}

@property (nonatomic,retain) NSString* login;
@property (nonatomic,retain) NSString* key;

@end