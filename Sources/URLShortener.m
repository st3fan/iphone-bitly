/*
 * (C) Copyright 2010, Stefan Arentz, Arentz Consulting Inc.
 *
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "URLShortener.h"

@interface URLShortener()

@property (nonatomic, assign) __unsafe_unretained id<URLShortenerDelegate> delegate;
@property (nonatomic, strong) URLShortenerCredentials* credentials;
@property (nonatomic, copy) NSURL* url;

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, assign) NSInteger statusCode;

@end


@implementation URLShortener

- (NSString *) _formEncodeString: (NSString*) string
{
    NSString* encoded = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);

    return encoded;
}

#pragma mark -
- (instancetype) initWithCredentials: (URLShortenerCredentials* )credentials
                                 url: (NSURL *)url
                            delegate: (id<URLShortenerDelegate>)delegate {

    if (self = [super init]) {
        self.credentials = credentials;
        self.url = url;
        self.delegate = delegate;
    }
    return self;
}

- (void) execute
{
    if (self.connection == nil)
    {
        self.data = [NSMutableData new];

        NSString* urlString = [NSString stringWithFormat: @"http://api.bit.ly/v3/shorten?login=%@&apiKey=%@&uri=%@&format=txt",
            [self _formEncodeString: _credentials.login],
            [self _formEncodeString: _credentials.key],
            [self _formEncodeString: [_url absoluteString]]];

        NSURLRequest* request = [NSURLRequest requestWithURL: [NSURL URLWithString: urlString]
            cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: 30.0];
        _connection = [NSURLConnection connectionWithRequest: request delegate: self];
    }
}

#pragma mark -

- (void) connection: (NSURLConnection*) connection didReceiveData: (NSData*) data
{
    [self.data appendData: data];
}

- (void)connection: (NSURLConnection*) connection didReceiveResponse: (NSHTTPURLResponse*) response
{
    self.statusCode = [response statusCode];
}

- (void) connection: (NSURLConnection*) connection didFailWithError: (NSError*) error
{
    [self.delegate shortener: self didFailWithError: error];
    self.connection = nil;
    self.data = nil;
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection
{
    if (self.statusCode != 200) {
        [self.delegate shortener: self didFailWithStatusCode: self.statusCode];
    } else {
        NSString* string = [[NSString alloc] initWithData: self.data encoding: NSASCIIStringEncoding];
        string = [string stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]];
        [self.delegate shortener: self didSucceedWithShortenedURL: [NSURL URLWithString: string]];
    }
}

@end