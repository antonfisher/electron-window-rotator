#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

#include "rotator.h"

const int DIRECTION_LEFT = 0;

napi_value rotate(napi_env env, napi_callback_info info) {
  NSLog(@"rotate()");

  napi_status status;

  size_t argc = 4;
  napi_value args[4];
  status = napi_get_cb_info(env, info, &argc, args, 0, 0);
  if (status != napi_ok) {
    napi_throw_error(env, NULL, "rotate(): failed to get arguments");
    return NULL;
  } else if (argc < 4) {
    napi_throw_error(env, NULL, "rotate(): wrong number of arguments");
    return NULL;
  }

  void *windowBuffer;
  size_t windowBufferLength;
  status =
      napi_get_buffer_info(env, args[0], &windowBuffer, &windowBufferLength);
  if (status != napi_ok) {
    napi_throw_error(env, NULL, "rotate(): cannot read window handle");
    return NULL;
  } else if (windowBufferLength == 0) {
    napi_throw_error(env, NULL, "rotate(): empty window handle");
    return NULL;
  }

  NSView *mainWindowView = *static_cast<NSView **>(windowBuffer);
  if (![mainWindowView respondsToSelector:@selector(window)] ||
      mainWindowView.window == nil) {
    napi_throw_error(env, NULL, "rotate(): NSView doesn't contain window");
    return NULL;
  }

  void *electronScreenshotBuffer;
  size_t electronScreenshotBufferLength;
  status = napi_get_buffer_info(env, args[1], &electronScreenshotBuffer,
                                &electronScreenshotBufferLength);
  if (status != napi_ok) {
    napi_throw_error(env, NULL, "rotate(): cannot read screenshot handle");
    return NULL;
  } else if (electronScreenshotBufferLength == 0) {
    napi_throw_error(env, NULL, "rotate(): empty screenshot handle");
    return NULL;
  }

  int duration;
  status = napi_get_value_int32(env, args[2], &duration);
  if (status != napi_ok) {
    napi_throw_error(env, NULL, "rotate(): cannot read duration from args");
    return NULL;
  } else if (duration == 0) {
    napi_throw_error(env, NULL, "rotate(): empty duration arg");
    return NULL;
  }

  int direction;
  status = napi_get_value_int32(env, args[3], &direction);
  if (status != napi_ok) {
    napi_throw_error(env, NULL, "rotate(): cannot read direction from args");
    return NULL;
  }

  NSWindow *window = mainWindowView.window;
  NSView *windowView = [window.contentView superview];

  CGFloat shadowMaxLength = 40.0;
  CGFloat width = NSWidth(window.frame);
  CGFloat height = NSHeight(window.frame);
  CGFloat l = sqrt(width * width + height * height) + shadowMaxLength * 2;
  CGFloat offsetX = (l - width) / 2;
  CGFloat offsetY = (l - height) / 2;

  // create bigger window to play rotation animation in it
  NSRect animationWindowContentRect = NSMakeRect(
      window.frame.origin.x - offsetX, window.frame.origin.y - offsetY, l, l);
  NSWindow *animationWindow =
      [[NSWindow alloc] initWithContentRect:animationWindowContentRect
                                  styleMask:NSWindowStyleMaskBorderless
                                    backing:NSBackingStoreBuffered
                                      defer:NO];
  [animationWindow setOpaque:NO];
  [animationWindow setHasShadow:NO];
  [animationWindow setBackgroundColor:[NSColor clearColor]];
  [animationWindow.contentView setWantsLayer:YES];

  // create native window frame screenshot (doesn't include electron's webview)
  NSBitmapImageRep *windowScreenshotRep =
      [windowView bitmapImageRepForCachingDisplayInRect:windowView.bounds];
  [windowView cacheDisplayInRect:windowView.bounds
                toBitmapImageRep:windowScreenshotRep];
  NSSize windowScreenshotSize =
      NSMakeSize(CGImageGetWidth([windowScreenshotRep CGImage]),
                 CGImageGetHeight([windowScreenshotRep CGImage]));
  NSImage *windowScreenshot =
      [[NSImage alloc] initWithSize:windowScreenshotSize];
  [windowScreenshot addRepresentation:windowScreenshotRep];
  NSLog(@"rotate(): window screenshot size: %0.0f x "
        @"%0.0f",
        windowScreenshotSize.width, windowScreenshotSize.height);

  // create electron app screenshot
  NSData *data = [NSData dataWithBytes:electronScreenshotBuffer
                                length:electronScreenshotBufferLength];
  NSBitmapImageRep *electronScreenshotRep =
      [NSBitmapImageRep imageRepWithData:data];
  NSSize electronScreenshotSize =
      NSMakeSize(CGImageGetWidth([electronScreenshotRep CGImage]),
                 CGImageGetHeight([electronScreenshotRep CGImage]));
  NSImage *electronScreenshot =
      [[NSImage alloc] initWithSize:electronScreenshotSize];
  [electronScreenshot addRepresentation:electronScreenshotRep];
  NSLog(@"rotate(): electron screenshot size: %0.0f x "
        @"%0.0f",
        electronScreenshotSize.width, electronScreenshotSize.height);

  // combine two screenshots -- put electron app screenshot into native one
  [windowScreenshot lockFocus];
  CGRect electronScreenshotRect = CGRectMake(0, 0, electronScreenshotSize.width,
                                             electronScreenshotSize.height);
  [electronScreenshot drawInRect:electronScreenshotRect];
  [windowScreenshot unlockFocus];

  // create image layer with rounded corners
  CALayer *imageLayer = [CALayer layer];
  [imageLayer setContents:windowScreenshot];
  [imageLayer setCornerRadius:10.0f];
  [imageLayer setMasksToBounds:YES]; // cuts shadows as well

  // show the animation window to calculate its real offset from the top of the
  // screen -- macOS doesn't allow window to go up of the top edge of the screen
  [animationWindow setAlphaValue:0.0];
  [animationWindow makeKeyAndOrderFront:nil];
  offsetY = window.frame.origin.y - animationWindow.frame.origin.y;
  [imageLayer setFrame:CGRectMake(offsetX, offsetY, width, height)];

  // add image layer to the animation window, set up OS shadows
  CALayer *animationWindowLayer = [animationWindow.contentView layer];
  [animationWindowLayer addSublayer:imageLayer];
  [animationWindowLayer setShadowRadius:20.0f];
  [animationWindowLayer setShadowOpacity:0.7f];
  [animationWindowLayer setShadowOffset:CGSizeMake(0, -20)];

  // replace the original window with its screenshot and start animation
  [window setAlphaValue:0.0];
  [animationWindow setAlphaValue:1.0];
  [CATransaction begin];
  CABasicAnimation *animation =
      [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  [animation setFromValue:[NSNumber numberWithDouble:0.0]];
  CGFloat endAngle = (direction == DIRECTION_LEFT ? 1 : -1) * 2.0 * M_PI;
  [animation setToValue:[NSNumber numberWithDouble:endAngle]];
  [animation setDuration:duration / 1000.0];
  [CATransaction setCompletionBlock:^{
    [window setAlphaValue:1.0];
    [animationWindow close];
    NSLog(@"rotate(): animation done");
  }];
  [imageLayer addAnimation:animation forKey:@"rotation"];
  [CATransaction commit];

  NSLog(@"rotate(): done");
  return NULL;
}
