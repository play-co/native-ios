/*
 
 File: Texture2D.h
 Abstract: Creates OpenGL 2D textures from images or text.
 
 Version: 1.6
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
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

#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>

//CONSTANTS:

typedef enum {
	kTexture2DPixelFormat_Automatic = 0,
	kTexture2DPixelFormat_RGBA8888,
	kTexture2DPixelFormat_RGB888,
	kTexture2DPixelFormat_RGB565,
	kTexture2DPixelFormat_A8,
} Texture2DPixelFormat;

//CLASS INTERFACES:

/*
 This class allows to easily create OpenGL 2D textures from images, text or raw data.
 The created Texture2D object will always have power-of-two dimensions.
 Depending on how you create the Texture2D object, the actual image area of the texture might be smaller than the texture dimensions i.e. "contentSize" != (pixelsWide, pixelsHigh) and (maxS, maxT) != (1.0, 1.0).
 Be aware that the content of the generated textures will be upside-down!
 */
@interface Texture2D : NSObject
{
	unsigned int width, height;
	NSString *src;
@private
	GLuint _name;
	CGSize _size;
	int _originalWidth;
	int _originalHeight;
  float scale;
	NSUInteger _texWidth, _texHeight;
	Texture2DPixelFormat _format;
	GLfloat _maxS, _maxT;
}
- (id) initWithData:(const void*)data andFormat:(Texture2DPixelFormat)pixelFormat andSize:(CGSize)realSize contentSize:(CGSize)contentSize andScale: (float)tex_scale;

- (void) bind;

@property(readonly) Texture2DPixelFormat format;
@property(readonly) unsigned int width, height;
@property(readonly) NSUInteger texWidth, texHeight;

@property(readonly) GLuint name;
@property(readonly) int originalWidth;
@property(readonly) int originalHeight;
@property(readonly) float scale;

@property(readonly, nonatomic) CGSize contentSize;
@property(readonly) GLfloat maxS;
@property(readonly) GLfloat maxT;
@property(readonly) NSString *src;
@end

/*
 Drawing extensions to make it easy to draw basic quads using a Texture2D object.
 These functions require GL_TEXTURE_2D and both GL_VERTEX_ARRAY and GL_TEXTURE_COORD_ARRAY client states to be enabled.
 */
@interface Texture2D (Drawing)
- (void) drawAtPoint:(CGPoint)point;
- (void) drawAtPoint:(CGPoint)point fromRect:(CGRect)rect;
- (void) drawInRect:(CGRect)rect fromRect:(CGRect)rect;
- (void) drawInRect:(CGRect)rect fromOriginalRect:(CGRect)srcRect;
- (void) drawInRect:(CGRect)rect;
- (void) drawInRect:(CGRect)rect fromS: (GLfloat) sMin toS: (GLfloat) sMax andT: (GLfloat) tMin toT: (GLfloat) tMax;
@end

/*
 Extensions to make it easy to create a Texture2D object from an image file.
 Note that RGBA type textures will have their alpha premultiplied - use the blending mode (GL_ONE, GL_ONE_MINUS_SRC_ALPHA).
 */
@interface Texture2D (Image)
- (id) initWithURLString: (NSString *) url;
- (id) initWithPath: (NSString *) path;
- (id) initWithImage:(UIImage *)uiImage;
- (id) initWithImage:(UIImage *)uiImage andUrl:(NSString *) url;
@end

/*
 Extensions to make it easy to create a Texture2D object from a string of text.
 Note that the generated textures are of type A8 - use the blending mode (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA).

 textStyle: A value from the enumeration TEXT_STYLE in text_manager.h
 */
@interface Texture2D (Text)
- (id) initWithString:(NSString*)string fontName:(NSString*)name fontSize:(CGFloat)size color:(GLfloat*)color maxWidth:(CGFloat)maxWidth textStyle:(int)textStyle strokeWidth:(CGFloat)strokeWidth;
@end

@interface UIImage (Resize)
- (UIImage *)croppedImage:(CGRect)bounds;
- (UIImage *)resizedImage:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality;
@end
