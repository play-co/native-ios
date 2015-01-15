/*
 
 ===== IMPORTANT =====
 
 This is sample code demonstrating API, technology or techniques in development.
 Although this sample code has been reviewed for technical accuracy, it is not
 final. Apple is supplying this information to help you plan for the adoption of
 the technologies and programming interfaces described herein. This information
 is subject to change, and software implemented based on this sample code should
 be tested with final operating system software and final documentation. Newer
 versions of this sample code may be provided with future seeds of the API or
 technology. For information about updates to this and other developer
 documentation, view the New & Updated sidebars in subsequent documentation
 seeds.
 
 =====================
 
 File: Texture2D.m
 Abstract: Creates OpenGL 2D textures from images or text.
 
 Version: 1.6
 
 Disclaimer: IMPORTANT:	 This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.	 If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
 */

#import <OpenGLES/ES1/glext.h>

#import "Texture2D.h"
#import "ResourceLoader.h"

#include "geometry.h"
#include "text_manager.h"
#include "core/log.h"
#import <core/platform/gl.h>

static inline int NextPowerOfTwo(int n) {
	n -= 1;
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	return (int)(n + 1);
}


//CONSTANTS:

#define kMaxTextureSize	 2048

//CLASS IMPLEMENTATIONS:

@implementation Texture2D

@synthesize format=_format, width, height, name=_name, maxS=_maxS, maxT=_maxT;
@synthesize src;
@synthesize contentSize=_size;
@synthesize originalWidth=_originalWidth;
@synthesize originalHeight=_originalHeight;
@synthesize texWidth=_texWidth;
@synthesize texHeight=_texHeight;
@synthesize scale;

- (id) initWithData:(const void*)data andFormat:(Texture2DPixelFormat)pixelFormat andSize:(CGSize)realSize contentSize:(CGSize)contentSize andScale: (float) tex_scale
{

	//GLint saveName;
	if((self = [super init])) {
		GLTRACE(glGenTextures(1, &_name));
		//glGetIntegerv(GL_TEXTURE_BINDING_2D, &saveName);
		GLTRACE(glBindTexture(GL_TEXTURE_2D, _name));
		
		GLTRACE(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
		GLTRACE(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
		GLTRACE(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT));
		GLTRACE(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT));

		switch(pixelFormat) {
			case kTexture2DPixelFormat_RGBA8888:
				GLTRACE(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, realSize.width, realSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data));
				break;
			case kTexture2DPixelFormat_RGB888:
				GLTRACE(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, realSize.width, realSize.height, 0, GL_RGB, GL_UNSIGNED_BYTE, data));
				break;
			case kTexture2DPixelFormat_RGB565:
				GLTRACE(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, realSize.width, realSize.height, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, data));
				break;
			case kTexture2DPixelFormat_A8:
				GLTRACE(glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, realSize.width, realSize.height, 0, GL_ALPHA, GL_UNSIGNED_BYTE, data));
				break;
			default:
				[NSException raise:NSInternalInconsistencyException format:@""];
				
		}
		//glBindTexture(GL_TEXTURE_2D, saveName);
		
		_size = contentSize;
		_texWidth = realSize.width;
		_texHeight = realSize.height;
		_format = pixelFormat;
		_maxS = contentSize.width / (float)realSize.width;
		_maxT = contentSize.height / (float)realSize.height;
		
		width = realSize.width;
		height = realSize.height;
		_originalWidth = contentSize.width;
		_originalHeight = contentSize.height;
		
		scale = tex_scale;
	}					
	return self;
}

- (void) bind
{
	GLTRACE(glBindTexture(GL_TEXTURE_2D, _name));
}

- (void) dealloc
{
//	if(_name)
//		glDeleteTextures(1, &_name);
	
	[super dealloc];
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@ = %ld | Name = %i | Dimensions = %ldx%ld | Coordinates = (%.2f, %.2f)>", [self class], (uintptr_t)self, _name, (unsigned long)_texWidth, (unsigned long)_texHeight, _maxS, _maxT];
}

@end

@implementation Texture2D (Image)

- (id) initWithURLString:(NSString *)url
{
	src = [url copy];
	
	ResourceLoader *loader = [ResourceLoader get];
	return [self initWithImage: [UIImage imageWithData: [NSData dataWithContentsOfURL: [loader resolve:url]]]];
}

- (id)initWithPath: (NSString *) path {
	src = [path copy];
	return [self initWithImage: [UIImage imageNamed: path]];
}

- (id) initWithImage:(UIImage *)uiImage andUrl:(NSString *) url {
	self = [self initWithImage:uiImage];
	src = url;
	return self;
}

- (id) initWithImage:(UIImage *)uiImage
{
	NSUInteger				w, h, i;
	CGContextRef			context = nil;
	void*					data = nil;;
	CGColorSpaceRef			colorSpace;
	void*					tempData;
	unsigned int*			inPixel32;
	unsigned short*			outPixel16;
	BOOL					hasAlpha;
	CGImageAlphaInfo		info;
	CGAffineTransform		transform;
	CGSize					imageSize;
	Texture2DPixelFormat	pixelFormat;
	CGImageRef				image;	
	
	image = [uiImage CGImage];
	
	if(image == NULL) {
		[self release];
		LOG("{Texture2D} could not init image: UIImage was null");
		return nil;
	}
	
	
	info = CGImageGetAlphaInfo(image);
	hasAlpha = ((info == kCGImageAlphaPremultipliedLast) || (info == kCGImageAlphaPremultipliedFirst) || (info == kCGImageAlphaLast) || (info == kCGImageAlphaFirst) ? YES : NO);
	if(CGImageGetColorSpace(image)) {
		if(hasAlpha)
			pixelFormat = kTexture2DPixelFormat_RGBA8888;
		else
			pixelFormat = kTexture2DPixelFormat_RGB565;
	} else	//NOTE: No colorspace means a mask image
		pixelFormat = kTexture2DPixelFormat_A8;
	
	imageSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
	transform = CGAffineTransformIdentity;
	
	w = NextPowerOfTwo(imageSize.width);
	h = NextPowerOfTwo(imageSize.height);

	float tex_scale = 1;
	
	while((w > kMaxTextureSize) || (h > kMaxTextureSize)) {
		w /= 2;
		h /= 2;
		tex_scale /= 2;
		transform = CGAffineTransformScale(transform, 0.5, 0.5);
		imageSize.width /= 2;
		imageSize.height /= 2;
	}

	switch(pixelFormat) {		
		case kTexture2DPixelFormat_RGBA8888:
			colorSpace = CGColorSpaceCreateDeviceRGB();
			data = malloc(h * w * 4);
			memset(data, 0, h * w * 4);
			context = CGBitmapContextCreate(data, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
			CGColorSpaceRelease(colorSpace);
			break;
		case kTexture2DPixelFormat_RGB565:
			colorSpace = CGColorSpaceCreateDeviceRGB();
			data = malloc(h * w * 4);
			memset(data, 0, h * w * 4);
			context = CGBitmapContextCreate(data, w, h, 8, 4 * w, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
			CGColorSpaceRelease(colorSpace);
			break;
		case kTexture2DPixelFormat_A8:
			data = malloc(h * w);
			memset(data, 0, h * w);
			context = CGBitmapContextCreate(data, w, h, 8, w, NULL, kCGImageAlphaOnly);
			break;				
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid pixel format"];
	}

	CGContextClearRect(context, CGRectMake(0, 0, w, h));
	CGContextTranslateCTM(context, 0, h - imageSize.height);
	
	if(!CGAffineTransformIsIdentity(transform)) {
		CGContextConcatCTM(context, transform);
	}
	CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
	//Convert "RRRRRRRRRGGGGGGGGBBBBBBBBAAAAAAAA" to "RRRRRGGGGGGBBBBB"
	if(pixelFormat == kTexture2DPixelFormat_RGB565) {
		tempData = malloc(h * w * 2);
		inPixel32 = (unsigned int*)data;
		outPixel16 = (unsigned short*)tempData;
		for(i = 0; i < w * h; ++i, ++inPixel32)
			*outPixel16++ = ((((*inPixel32 >> 0) & 0xFF) >> 3) << 11) | ((((*inPixel32 >> 8) & 0xFF) >> 2) << 5) | ((((*inPixel32 >> 16) & 0xFF) >> 3) << 0);
		free(data);
		data = tempData;
		
	}
	self = [self initWithData:data andFormat:pixelFormat andSize: CGSizeMake(w, h) contentSize:imageSize andScale: tex_scale];

	CGContextRelease(context);
	free(data);

	return self;
}

@end

@implementation Texture2D (Text)

- (id) initWithString:(NSString*)string fontName:(NSString*)name fontSize:(CGFloat)size color:(GLfloat*)color maxWidth:(CGFloat)maxWidth textStyle:(int)textStyle strokeWidth:(CGFloat)strokeWidth
{
	CGContextRef			context;
	void*					data;
	CGColorSpaceRef			colorSpace;
	UIFont *				font;
	CGSize					dimensions;
	CGSize					act_dim;
	NSUInteger				w, h;

	font = [UIFont fontWithName:name size: size];
	dimensions = [string sizeWithFont: font];
	w = NextPowerOfTwo(dimensions.width);
	h = NextPowerOfTwo(dimensions.height);
	if(maxWidth > 0) {
		while(dimensions.width > maxWidth && size > 0) {
			font = [UIFont fontWithName:name size: --size];
			dimensions = [string sizeWithFont: font];
			w = NextPowerOfTwo(dimensions.width);
			h = NextPowerOfTwo(dimensions.height);
		}
	}

	if (textStyle == TEXT_STYLE_STROKE) {
		act_dim.width = dimensions.width + strokeWidth * 2.f;
		act_dim.height = dimensions.height + strokeWidth * 2.f;
		w = NextPowerOfTwo(act_dim.width);
		h = NextPowerOfTwo(act_dim.height);
	} else {
		act_dim = dimensions;
		strokeWidth = 0;
	}

	colorSpace = CGColorSpaceCreateDeviceRGB();
	data = malloc(h * w * 4);
	memset(data, 0, h * w * 4);
	context = CGBitmapContextCreate(data, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

	CGContextTranslateCTM(context, 0.0, h);
	CGContextScaleCTM(context, 1.0, -1.0); //NOTE: NSString draws in UIKit referential i.e. renders upside-down compared to CGBitmapContext referential
    CGFloat cgColor[4] = {
      static_cast<CGFloat>(color[0]),
      static_cast<CGFloat>(color[1]),
      static_cast<CGFloat>(color[2]),
      static_cast<CGFloat>(color[3]),
    };
    UIColor* uiColor = [UIColor colorWithRed:color[0] green:color[1] blue:color[2] alpha:color[3]];
    CGContextSetRGBFillColor(context, color[0], color[1], color[2], color[3]);
    UIGraphicsPushContext(context);

	CGColorRef colorf = CGColorCreate(colorSpace, cgColor);
	CGContextSetFillColorWithColor(context, colorf);

	if (textStyle == TEXT_STYLE_STROKE) {
		CGContextSetTextDrawingMode(context, kCGTextStroke);
		CGContextSetStrokeColorWithColor(context, colorf);
		CGContextSetLineWidth(context, strokeWidth);
		CGContextSetLineJoin(context, kCGLineJoinRound);
	} else {
		CGContextSetTextDrawingMode(context, kCGTextFill);
	}
	CGContextSetAllowsAntialiasing(context, YES);
	CGContextSetShouldAntialias(context, YES);
	CGContextSetShouldSmoothFonts(context, YES);
    CGContextSetFillColorWithColor(context, colorf);

  [string drawInRect:CGRectMake(strokeWidth, strokeWidth, dimensions.width, dimensions.height) withAttributes:@{
    NSFontAttributeName:font,
    NSForegroundColorAttributeName:uiColor
   }];

  
	UIGraphicsPopContext();

	self = [self initWithData:data andFormat:kTexture2DPixelFormat_RGBA8888 andSize: CGSizeMake(w, h) contentSize:act_dim andScale: 1];

	CGColorSpaceRelease(colorSpace);
	CGColorRelease(colorf);
	CGContextRelease(context);
	free(data);

	return self;
}

@end

@implementation Texture2D (Drawing)

- (void) drawAtPoint:(CGPoint)point 
{
	return [self drawInRect:CGRectMake(point.x, point.y, _texWidth * _maxS, _texHeight * _maxT)
					  fromS:0 toS:_maxS
					   andT:0 toT:_maxT];
}

- (void) drawAtPointOriginalSize:(CGPoint)point 
{
	return [self drawInRect:CGRectMake(point.x, point.y, _originalWidth, _originalHeight)
					  fromS:0 toS:_maxS
					   andT:0 toT:_maxT];
}

- (void) drawAtPoint:(CGPoint)point fromRect:(CGRect)rect
{
	CGFloat w = rect.size.width;
	CGFloat h = rect.size.height;
	return [self drawInRect:CGRectMake(point.x, point.y, w, h)
					  fromS:rect.origin.x / _texWidth toS: (rect.origin.x + w) / _texWidth
					   andT:rect.origin.y / _texHeight toT: (rect.origin.y + h) / _texHeight];
}

- (void) drawInRect:(CGRect)rect {
	return [self drawInRect:rect fromS:0 toS:_maxT andT:0 toT:_maxS];
}

- (void) drawInRect:(CGRect)rect fromRect:(CGRect)srcRect {
	return [self drawInRect: rect
					  fromS: srcRect.origin.x / _texWidth toS: (srcRect.origin.x + srcRect.size.width) / _texWidth
					   andT: srcRect.origin.y / _texHeight toT: (srcRect.origin.y + srcRect.size.height) / _texHeight
			];
}

- (void) drawInRect:(CGRect)rect fromOriginalRect:(CGRect)srcRect {
	return [self drawInRect: rect
					  fromS: srcRect.origin.x / width toS: (srcRect.origin.x + srcRect.size.width) / width
					   andT: srcRect.origin.y / height toT: (srcRect.origin.y + srcRect.size.height) / height
			];
}

- (void) drawInRect:(CGRect)rect fromS: (GLfloat) sMin toS: (GLfloat) sMax andT: (GLfloat) tMin toT: (GLfloat) tMax {
	GLfloat coordinates[] = {
		sMin,	tMax,
		sMax,	tMax,
		sMin,	tMin,
		sMax,	tMin
	};
	
	GLfloat vertices[] = {
		(GLfloat)rect.origin.x,                     (GLfloat)(rect.origin.y + rect.size.height), 0.0,
		(GLfloat)(rect.origin.x + rect.size.width), (GLfloat)(rect.origin.y + rect.size.height), 0.0,
		(GLfloat)rect.origin.x,                     (GLfloat)rect.origin.y,                      0.0,
		(GLfloat)(rect.origin.x + rect.size.width), (GLfloat)rect.origin.y,                      0.0
	};
	
	GLTRACE(glEnable(GL_TEXTURE_2D));
	GLTRACE(glEnableClientState(GL_TEXTURE_COORD_ARRAY));
	GLTRACE(glBindTexture(GL_TEXTURE_2D, _name));
	GLTRACE(glVertexPointer(3, GL_FLOAT, 0, vertices));
	GLTRACE(glTexCoordPointer(2, GL_FLOAT, 0, coordinates));
	GLTRACE(glDrawArrays(GL_TRIANGLE_STRIP, 0, 4));
	GLTRACE(glDisableClientState(GL_TEXTURE_COORD_ARRAY));
	GLTRACE(glDisable(GL_TEXTURE_2D));
}


@end

@interface UIImage ()
- (UIImage *)resizedImage:(CGSize)newSize
				transform:(CGAffineTransform)transform
		   drawTransposed:(BOOL)transpose
	 interpolationQuality:(CGInterpolationQuality)quality;
- (CGAffineTransform)transformForOrientation:(CGSize)newSize;
@end

@implementation UIImage (Resize)

// Returns a copy of this image that is cropped to the given bounds.
// The bounds will be adjusted using CGRectIntegral.
// This method ignores the image's imageOrientation setting.
- (UIImage *)croppedImage:(CGRect)bounds {
	CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], bounds);
	UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	return croppedImage;
}

// Returns a rescaled copy of the image, taking into account its orientation
// The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter
- (UIImage *)resizedImage:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality {
	BOOL drawTransposed;
	
	switch (self.imageOrientation) {
		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			drawTransposed = YES;
			break;
			
		default:
			drawTransposed = NO;
	}
	
	return [self resizedImage:newSize
					transform:[self transformForOrientation:newSize]
			   drawTransposed:drawTransposed
		 interpolationQuality:quality];
}

// Resizes the image according to the given content mode, taking into account the image's orientation
- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
								  bounds:(CGSize)bounds
					interpolationQuality:(CGInterpolationQuality)quality {
	CGFloat horizontalRatio = bounds.width / self.size.width;
	CGFloat verticalRatio = bounds.height / self.size.height;
	CGFloat ratio;
	
	switch (contentMode) {
		case UIViewContentModeScaleAspectFill:
			ratio = MAX(horizontalRatio, verticalRatio);
			break;
			
		case UIViewContentModeScaleAspectFit:
			ratio = MIN(horizontalRatio, verticalRatio);
			break;
			
		default:
			[NSException raise:NSInvalidArgumentException format:@"Unsupported content mode: %ld", (long)contentMode];
	}
	
	CGSize newSize = CGSizeMake(self.size.width * ratio, self.size.height * ratio);
	
	return [self resizedImage:newSize interpolationQuality:quality];
}

#pragma mark -
#pragma mark Private helper methods

// Returns a copy of the image that has been transformed using the given affine transform and scaled to the new size
// The new image's orientation will be UIImageOrientationUp, regardless of the current image's orientation
// If the new size is not integral, it will be rounded up
- (UIImage *)resizedImage:(CGSize)newSize
				transform:(CGAffineTransform)transform
		   drawTransposed:(BOOL)transpose
	 interpolationQuality:(CGInterpolationQuality)quality {
	CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
	CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
	CGImageRef imageRef = self.CGImage;
	
	// Build a context that's the same dimensions as the new size
	CGContextRef bitmap = CGBitmapContextCreate(NULL,
												newRect.size.width,
												newRect.size.height,
												CGImageGetBitsPerComponent(imageRef),
												0,
												CGImageGetColorSpace(imageRef),
												CGImageGetBitmapInfo(imageRef));
	
	// Rotate and/or flip the image if required by its orientation
	CGContextConcatCTM(bitmap, transform);
	
	// Set the quality level to use when rescaling
	CGContextSetInterpolationQuality(bitmap, quality);
	
	// Draw into the context; this scales the image
	CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, imageRef);
	
	// Get the resized image from the context and a UIImage
	CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
	UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
	
	// Clean up
	CGContextRelease(bitmap);
	CGImageRelease(newImageRef);
	
	return newImage;
}

// Returns an affine transform that takes into account the image orientation when drawing a scaled image
- (CGAffineTransform)transformForOrientation:(CGSize)newSize {
	CGAffineTransform transform = CGAffineTransformIdentity;
	
	switch (self.imageOrientation) {
		case UIImageOrientationDown:		   // EXIF = 3
		case UIImageOrientationDownMirrored:   // EXIF = 4
			transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
			
		case UIImageOrientationLeft:		   // EXIF = 6
		case UIImageOrientationLeftMirrored:   // EXIF = 5
			transform = CGAffineTransformTranslate(transform, newSize.width, 0);
			transform = CGAffineTransformRotate(transform, M_PI_2);
			break;
			
		case UIImageOrientationRight:		   // EXIF = 8
		case UIImageOrientationRightMirrored:  // EXIF = 7
			transform = CGAffineTransformTranslate(transform, 0, newSize.height);
			transform = CGAffineTransformRotate(transform, -M_PI_2);
			break;
		default: break;
	}

	switch (self.imageOrientation) {
		case UIImageOrientationUpMirrored:	   // EXIF = 2
		case UIImageOrientationDownMirrored:   // EXIF = 4
			transform = CGAffineTransformTranslate(transform, newSize.width, 0);
			transform = CGAffineTransformScale(transform, -1, 1);
			break;
			
		case UIImageOrientationLeftMirrored:   // EXIF = 5
		case UIImageOrientationRightMirrored:  // EXIF = 7
			transform = CGAffineTransformTranslate(transform, newSize.height, 0);
			transform = CGAffineTransformScale(transform, -1, 1);
			break;
		default: break;
	}
	
	return transform;
}

@end
