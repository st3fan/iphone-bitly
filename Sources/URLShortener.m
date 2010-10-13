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

@implementation URLShortener

@synthesize
	delegate = _delegate,
	credentials = _credentials,
	url = _url;

- (NSString*) _formEncodeString: (NSString*) string
{
	NSString* encoded = (NSString*) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
		(CFStringRef) string, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
	return [encoded autorelease];
}

#pragma mark -

- (void) execute
{
	if (_connection == nil)
	{
		_data = [NSMutableData new];
		
		NSString* urlString = [NSString stringWithFormat: @"http://api.bit.ly/v3/shorten?login=%@&apiKey=%@&uri=%@&format=txt",
			[self _formEncodeString: _credentials.login],
			[self _formEncodeString: _credentials.key],
			[self _formEncodeString: [_url absoluteString]]];
			
		NSURLRequest* request = [NSURLRequest requestWithURL: [NSURL URLWithString: urlString]
			cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: 30.0];
		_connection = [[NSURLConnection connectionWithRequest: request delegate: self] retain];
	}
}

#pragma mark -

- (void) connection: (NSURLConnection*) connection didReceiveData: (NSData*) data
{
	[_data appendData: data];
}

- (void)connection: (NSURLConnection*) connection didReceiveResponse: (NSHTTPURLResponse*) response
{
	_statusCode = [response statusCode];
}

- (void) connection: (NSURLConnection*) connection didFailWithError: (NSError*) error
{
	[_delegate shortener: self didFailWithError: error];

	[_connection release];
	_connection = nil;

	[_data release];
	_data = nil;
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection
{
	if (_statusCode != 200) {
		[_delegate shortener: self didFailWithStatusCode: _statusCode];
	} else {
		NSString* string = [[[NSString alloc] initWithData: _data encoding: NSASCIIStringEncoding] autorelease];
		string = [string stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]];
		[_delegate shortener: self didSucceedWithShortenedURL: [NSURL URLWithString: string]];
	}

	[_connection release];
	_connection = nil;
	
	[_data release];
	_data = nil;
}

#pragma mark -

- (void) dealloc
{
	[_credentials release];
	[_url release];
	[super dealloc];
}

@end