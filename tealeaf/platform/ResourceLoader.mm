/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License v. 2.0 as published by Mozilla.
 
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * Mozilla Public License v. 2.0 for more details.
 
 * You should have received a copy of the Mozilla Public License v. 2.0
 * along with the Game Closure SDK.	 If not, see <http://mozilla.org/MPL/2.0/>.
 */

#include <sys/stat.h>
#include <string.h>
#import "ResourceLoader.h"
#import "Base64.h"
#import "TeaLeafAppDelegate.h"
#import "RawImageInfo.h"

#include "text_manager.h"
#include "texture_manager.h"
#include "events.h"
#include "log.h"
#include "core/core.h"
#include "core/image_loader.h"
#include "core/config.h"
#include "core/util/detect.h"
#include "image_cache.h"
#import <core/platform/gl.h>


#define APP @"app.bundle"

#define MAX_HALFSIZE_SKIP 64

static BOOL VERBOSE_LOGS = true;
static ResourceLoader *instance = nil;
static NSThread *imgThread = nil;
static const char *base_path = 0;
static int base_path_len = 0;

@interface ResourceLoader ()
@property (nonatomic, assign) TeaLeafAppDelegate *appDelegate;
@end


@interface ImageInfo : NSObject
@property(retain) NSString *url;
@property(retain) UIImage *image;
- (id) initWithImage: (UIImage *)image andUrl:(NSString *)url;
@end


@implementation ImageInfo
- (void) dealloc {
	self.url = nil;
	self.image = nil;
	
	[super dealloc];
}

- (id) initWithImage: (UIImage *)image andUrl:(NSString *)url {
	if((self = [super init])) {
		self.url = url;
		self.image = image;
	}
	return self;
}

@end


@implementation ResourceLoader

+ (void) release {
	if (instance != nil) {
        image_cache_destroy();
		[instance release];
		instance = nil;
	}
}

+ (ResourceLoader *) get {
	if (instance == nil) {
		instance = [[ResourceLoader alloc] init];
		image_cache_init([instance.documentsDirectory UTF8String], &image_cache_load_callback);
		imgThread = [[NSThread alloc] initWithTarget:instance selector:@selector(imageThread) object:nil];
		instance.appDelegate = ((TeaLeafAppDelegate *)[[UIApplication sharedApplication] delegate]);
		[imgThread start];
		LOG("creating resourceloader");
	}
	return [instance retain];
}

- (void) dealloc {
	self.appBundle = nil;
	self.appBase = nil;
	self.images = nil;
	self.imageWaiter = nil;
	self.baseURL = nil;
	[imgThread release];
	[super dealloc];
}

- (id) init {
	self = [super init];

	self.appBundle = [[NSBundle mainBundle] pathForResource:@"resources" ofType:@"bundle"];

	NSLOG(@"Using resource path %@", self.appBundle);
	
	self.appBase = [[NSBundle mainBundle] resourcePath];
	self.images = [[[NSMutableArray alloc] init] autorelease];
	self.imageWaiter = [[[NSCondition alloc] init] autorelease];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    self.documentsDirectory = [paths objectAtIndex:0];


	return self;
}

- (NSString *) initStringWithContentsOfURL:(NSString *)url {
	//check config for test app

	NSURLRequest *request = [NSURLRequest requestWithURL:[self resolve:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:600];
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if (data == nil) {
		NSLOG(@"{resources} FAILED: Unable to read '%@' : %@", url, [error localizedFailureReason]);
		return nil;
	} else {
		NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

		if (NSOrderedSame == [result compare:@"Cannot GET" options:NSLiteralSearch range:NSMakeRange(0, 10)]) {
			[result release];
			return nil;
		} else {
			return result;
		}
	}
}

- (NSURL *) resolve:(NSString *)url {
	if([url hasPrefix: @"http"] || [url hasPrefix: @"data"]) {
		return [NSURL URLWithString: url];
	}

	// Prefix with "@root://" to access things at the root of the app data outside the resources.bundle
	BOOL inBundle = YES;
	if ([url hasPrefix: @"@root://"]) {
		inBundle = NO;
		url = [url substringFromIndex:8];
	}
	
	if (self.appDelegate.isTestApp) {
		return [self resolveFileUrl:url];
	} else {
		return [self resolveFile:url inBundle:inBundle];
	}
}

- (NSURL *) resolveFile:(NSString *)path inBundle:(BOOL)inBundle {
	if (inBundle) {
		return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.appBundle, path]];
	} else {
		return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.appBase, path]];
	}
}

- (NSURL *) resolveFileUrl:(NSString *)url {
	return [NSURL URLWithString:[NSString stringWithFormat:@"file://%@/%@", [[instance.appDelegate.config objectForKey:@"app_files_dir"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], url ]];
	//return url to file on disk
}
- (NSString*) getFileNameFromURL: (NSString*) url {
    return [NSString stringWithFormat:@"%@/%@", self.documentsDirectory, [url stringByReplacingOccurrencesOfString:@"/" withString:@"-"]];
}
- (void) cacheRemoteImage: (NSData*) data forURL: (NSString*) url {
    NSString *path = [self getFileNameFromURL: url];
    [data writeToFile:path atomically:NO];
}

- (NSData*) getCachedImageFromURL: (NSString*) url {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [self getFileNameFromURL: url];
    NSData *contents = nil;
    if ([fileManager fileExistsAtPath:path]) {
        contents = [fileManager contentsAtPath:path];
    }
    return contents;
}

- (void) makeTexture2DFromData: (NSData*) data url: (NSString*) url {
    unsigned char *tex_data = NULL;
    int ch, w, h, ow, oh, scale;
    unsigned long raw_length = [data length];
    if (raw_length > 0) {
        const void *raw_data = [data bytes];
        
        if (raw_data) {
            long size;
            int compression_type;
            tex_data = texture_2d_load_texture_raw([url UTF8String], raw_data, raw_length, &ch, &w, &h, &ow, &oh, &scale, &size, &compression_type);
        }
    }
    
    if(tex_data) {
        RawImageInfo* info = [[RawImageInfo alloc] initWithData:tex_data andURL:url andW:w andH:h andOW:ow andOH:oh andScale:scale andChannels:ch];
        [self performSelectorOnMainThread:@selector(finishLoadingRawImage:) withObject:info waitUntilDone:NO];
    } else {
        LOG("{resources} WARNING: 404 %s", [url UTF8String]);
        [self performSelectorOnMainThread:@selector(failedLoadImage:) withObject: url waitUntilDone:NO];
    }
}

- (void) imageThread {
  @autoreleasepool {
    while(true) {
      //continue;
      [self.imageWaiter lock];
      [self.imageWaiter wait];
      NSArray* imgs = [NSArray arrayWithArray: self.images];
      [self.images removeAllObjects];
      [self.imageWaiter unlock];
      do {
        for (NSUInteger i = 0, count = [imgs count]; i < count; i++) {
          NSString* url = [imgs objectAtIndex:i];
          NSLOG(@"{resources} Loading url:%@", url);
          if([url hasPrefix: @"@TEXT"]) {
            [self performSelectorOnMainThread: @selector(finishLoadingText:) withObject: url waitUntilDone:NO];
          } else if([url hasPrefix: @"@CONTACTPICTURE"]) {
            // TODO Contact pictures again...
          } else if([url hasPrefix: @"MULTICONTACTPICTURES"]) {
            // TODO sprite contact pictures...
            NSLOG(@"{resources} ERROR: Contact pictures not supported yet!");
          } else if([url hasPrefix: @"CAMERA"]) {
            // do nothing for now
            NSLOG(@"{resources} ERROR: Camera not supported yet!");
          } else if([url hasPrefix: @"GALLERYPHOTO"]) {
            // do nothing for now
            NSLOG(@"{resources} ERROR: Gallery photo picking not supported yet!");
          } else {
            // it's a plain url
            NSData* data = nil;
            if([url hasPrefix: @"data:"]) {
              NSRange range = [url rangeOfString:@","];
              NSString* str = [url substringFromIndex: range.location+1];
              data = decodeBase64(str);
            } else {
              data = [NSData dataWithContentsOfURL: [self resolve:url]];
              [self makeTexture2DFromData: data url: url];
            }
          }
        }
        imgs = [NSArray arrayWithArray: self.images];
        [self.images removeAllObjects];
      } while([imgs count] > 0);
    }
  }
}

- (UIImage *) normalize: (UIImage *) src {
	
	CGSize size = CGSizeMake(round(src.size.width), round(src.size.height));
	CGColorSpaceRef genericColorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef thumbBitmapCtxt = CGBitmapContextCreate(NULL,
														 size.width,
														 size.height,
														 8, (4 * size.width),
														 genericColorSpace,
														 kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(genericColorSpace);
	CGContextSetInterpolationQuality(thumbBitmapCtxt, kCGInterpolationDefault);
	CGRect destRect = CGRectMake(0, 0, size.width, size.height);
	CGContextDrawImage(thumbBitmapCtxt, destRect, src.CGImage);
	CGImageRef tmpThumbImage = CGBitmapContextCreateImage(thumbBitmapCtxt);
	CGContextRelease(thumbBitmapCtxt);
	UIImage *result = [UIImage imageWithCGImage:tmpThumbImage scale:1.0 orientation:UIImageOrientationUp];
	CGImageRelease(tmpThumbImage);
	
	return result;
}

- (void) loadImage:(NSString *)url {
	if([url hasPrefix: @"@TEXT"]) {
		if ([NSThread isMainThread]) {
			// Normal case: Most text load requests come from JavaScript from main GL thread
			[self finishLoadingText:url];
		} else {
			// This will put it on a queue and execute it later, which is not ideal
			[self performSelectorOnMainThread: @selector(finishLoadingText:) withObject:url waitUntilDone:NO];
		}
	} else if (url) {
		[self.images addObject: url];
		[self.imageWaiter broadcast];
	}
}

- (void) failedLoadImage: (NSString*) url {
	texture_manager_on_texture_failed_to_load(texture_manager_get(), [url UTF8String]);
	NSString* evt = [NSString stringWithFormat:@"{\"name\":\"imageError\",\"url\":\"%@\"}", url];
	core_dispatch_event([evt UTF8String]);
}

- (void) finishLoadingText: (NSString *) url {
	// Format: @TEXT<font>|<pt size>|<red>|<green>|<blue>|<alpha>|<max width>|<text style>|<stroke width>|<text>
	NSArray* parts = [[url substringFromIndex:5] componentsSeparatedByString: @"|"];

	// If text string is formatted properly,
	if (parts && [parts count] >= 10) {
		NSString *family = [parts objectAtIndex: 0],
		*str = [parts objectAtIndex: 9];
		CGFloat size = [[parts objectAtIndex: 1] floatValue];
		GLfloat colorf[] = {
			[[parts objectAtIndex: 2] floatValue] / 255.f,
			[[parts objectAtIndex: 3] floatValue] / 255.f,
			[[parts objectAtIndex: 4] floatValue] / 255.f,
			[[parts objectAtIndex: 5] floatValue] / 255.f
		};
		GLint maxWidth = [[parts objectAtIndex:6] intValue];
		GLint textStyle = [[parts objectAtIndex:7] intValue];
		GLfloat strokeWidth = [[parts objectAtIndex:8] intValue] / 4.f;
		
		Texture2D *tex = [[[Texture2D alloc] initWithString:str fontName:family fontSize:size color:colorf maxWidth:maxWidth textStyle:textStyle strokeWidth:strokeWidth] autorelease];

		if (tex) {
			texture_manager_on_texture_loaded(texture_manager_get(), [url UTF8String], tex.name, tex.width, tex.height, tex.originalWidth, tex.originalHeight, 4, 1, true, 0, 0);
			if (VERBOSE_LOGS) {
				NSLOG(@"{resources} Loaded text %@ id:%d (%d,%d)->(%u,%u)", url, tex.name, tex.originalWidth, tex.originalHeight, tex.width, tex.height);
			}
		}
	}
}

- (void) finishLoadingImage:(ImageInfo *)info {
	Texture2D* tex = [[Texture2D alloc] initWithImage:info.image andUrl: info.url];
	int scale = use_halfsized_textures ? 2 : 1;
	texture_manager_on_texture_loaded(texture_manager_get(), [tex.src UTF8String], tex.name, tex.width * scale, tex.height * scale, tex.originalWidth * scale, tex.originalHeight * scale, 4, scale, false, 0, 0);
	NSString* evt = [NSString stringWithFormat: @"{\"name\":\"imageLoaded\",\"url\":\"%@\",\"glName\":%d,\"width\":%d,\"height\":%d,\"originalWidth\":%d,\"originalHeight\":%d}",
					 tex.src, tex.name, tex.width, tex.height, tex.originalWidth, tex.originalHeight];
	core_dispatch_event([evt UTF8String]);
	NSLOG(@"{resources} Loaded image %@ id:%d (%d,%d)->(%u,%u)", tex.src, tex.name, tex.originalWidth, tex.originalHeight, tex.width, tex.height);

	[info release];
	[tex release];
}

- (void) finishLoadingRawImage:(RawImageInfo *)info {
	GLuint texture = 0;
	GLTRACE(glGenTextures(1, &texture));
	GLTRACE(glBindTexture(GL_TEXTURE_2D, texture));
	GLTRACE(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST));
	GLTRACE(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
	GLTRACE(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT));
	GLTRACE(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT));

	const char *url = [info.url UTF8String];

	// Select the right internal and input format based on the number of channels
	GLint format;
	switch (info.channels) {
	case 1: format = GL_LUMINANCE; break;
	case 3: format = GL_RGB; break;
	default:
	case 4: format = GL_RGBA; break;
	}

	//create the texture
	int shift = info.scale - 1;
	GLTRACE(glTexImage2D(GL_TEXTURE_2D, 0, format, info.w >> shift, info.h >> shift, 0, format, GL_UNSIGNED_BYTE, info.raw_data));

	texture_manager_on_texture_loaded(texture_manager_get(), url, texture,
									  info.w, info.h, info.ow, info.oh,
									  info.channels, info.scale, false, 0, 0);
    
    [self sendImageLoadedEventForURL:[info.url UTF8String] glName:texture width:info.w height:info.h originalWidth:info.ow originalHeight:info.oh];
	
   	[info release];
}

-(void) sendImageLoadedEventForURL: (const char *) url glName: (int) glName width: (int) width height: (int) height originalWidth: (int) originalWidth originalHeight: (int) originalHeight {
	char *event_str;
	int event_len;
	
	char *dynamic_str = 0;
	char stack_str[512];
	
	// Generate event string
	{
		int url_len = (int)strlen(url);
		
		if (url_len > 300) {
			event_len = url_len + 212;
			dynamic_str = (char*)malloc(event_len);
			event_str = dynamic_str;
		} else {
			event_len = 512;
			event_str = stack_str;
		}
	}
	
	//create json event string
	event_len = snprintf(event_str, event_len,
						  "{\"url\":\"%s\",\"height\":%d,\"originalHeight\":%d,\"originalWidth\":%d" \
						  ",\"glName\":%d,\"width\":%d,\"name\":\"imageLoaded\",\"priority\":0}",
						  url, (int)height,
						  (int)originalHeight, (int)originalWidth,
						  (int)glName, (int)width);
	event_str[event_len] = '\0';
	
	core_dispatch_event(event_str);
	
	// If dynamically allocated the string,
	if (dynamic_str) {
		free(dynamic_str);
	}
}

@end


#include <sys/mman.h>
#include <sys/fcntl.h>

static bool read_file(const char *url, unsigned long *sz, unsigned char **data) {
	// Try to use stack memory if it is small
	char full_path[512];
	unsigned long url_len = strlen(url);
	unsigned long full_path_len = base_path_len + url_len + 1 + 1;
	char *path = full_path;
	if (full_path_len > sizeof(full_path)) {
		path = (char*)malloc(full_path_len);
	}

	// Concatenate path
	sprintf(path, "%s/%s", base_path, url);

	// Open the file
	int fd = open(path, O_RDONLY);

	bool success = false;

	if (fd != -1) {
		off_t len = lseek(fd, 0, SEEK_END);

		fcntl(fd, F_NOCACHE, 1);
		fcntl(fd, F_RDAHEAD, 1);

		if (len > 0) {
			void *raw = mmap(0, (size_t)len, PROT_READ, MAP_PRIVATE, fd, 0);

			if (raw == MAP_FAILED) {
				LOG("{resources} WARNING: mmap failed errno=%d for %s/%s len=%d", errno, base_path, url, (int)len);
			} else {
				*data = (unsigned char*)raw;
				*sz = (unsigned long)len;
				success = true;
			}
		}

		close(fd);
	}

	// Release path memory if it was long
	if (path != full_path) {
		free(path);
	}

	return success;
}

CEXPORT bool resource_loader_load_image_with_c(texture_2d *texture) {
	unsigned long sz = 0;
	unsigned char *data;

	// If base64 data used,
	if (texture->url[0] == 'd' &&
		texture->url[1] == 'a' &&
		texture->url[2] == 't' &&
		texture->url[3] == 'a' &&
		texture->url[4] == ':') {
		char *after = strchr(texture->url, ',');
		if (after) {
			NSString *urlstr = [NSString stringWithUTF8String:(after + 1)];
			NSData *nsd = decodeBase64(urlstr);
			data = (unsigned char*)[nsd bytes];
			sz = [nsd length];
			
			texture->pixel_data = texture_2d_load_texture_raw(texture->url, data, sz, &texture->num_channels, &texture->width, &texture->height, &texture->originalWidth, &texture->originalHeight, &texture->scale, &texture->used_texture_bytes, &texture->compression_type);
			
			return true;
		}
	}
	
	if (!read_file(texture->url, &sz, &data)) {
		texture->pixel_data = NULL;

		return false;
	} else {
		texture->pixel_data = texture_2d_load_texture_raw(texture->url, data, sz, &texture->num_channels, &texture->width, &texture->height, &texture->originalWidth, &texture->originalHeight, &texture->scale, &texture->used_texture_bytes, &texture->compression_type);
		
		// Release map
		munmap(data, sz);
		return true;
	}
}

CEXPORT const char* resource_loader_string_from_url(const char *url) {
	ResourceLoader* loader = [ResourceLoader get];
	NSString* nsurl = [NSString stringWithUTF8String:url];
	NSString* contents = [[loader initStringWithContentsOfURL:nsurl] autorelease];
	const char *contents_str = [contents UTF8String];
	if (contents_str) {
		contents_str = strdup(contents_str);
	}
	return contents_str;
}

CEXPORT void resource_loader_initialize(const char *path) {
	base_path = strdup(path);
	base_path_len = (int)strlen(base_path);
}

CEXPORT void resource_loader_load_image(const char* url) {
	if (VERBOSE_LOGS) {
		LOG("{resources} Queuing %s", url);
	}
	[[ResourceLoader get] loadImage: [NSString stringWithUTF8String: url]];
}

CEXPORT void launch_remote_texture_load(const char *url) {
	resource_loader_load_image(url);
}
