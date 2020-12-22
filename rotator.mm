#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

#include "rotator.h"

napi_value rotate(napi_env env, napi_callback_info info) {
  NSLog(@"electron-window-rotator:rotate()");

  napi_status status;

  size_t argc = 2;
  napi_value args[2];
  status = napi_get_cb_info(env, info, &argc, args, 0, 0);
  if (status != napi_ok) {
    napi_throw_error(
        env, NULL, "electron-window-rotator:rotate(): failed to get arguments");
    return NULL;
  } else if (argc < 2) {
    napi_throw_error(
        env, NULL,
        "electron-window-rotator:rotate(): wrong number of arguments");
    return NULL;
  }

  void *windowBuffer;
  size_t windowBufferLength;
  status =
      napi_get_buffer_info(env, args[0], &windowBuffer, &windowBufferLength);
  if (status != napi_ok) {
    napi_throw_error(
        env, NULL,
        "electron-window-rotator:rotate(): cannot read window handle");
    return NULL;
  } else if (windowBufferLength == 0) {
    napi_throw_error(env, NULL,
                     "electron-window-rotator:rotate(): empty window handle");
    return NULL;
  }

  NSView *mainWindowView = *static_cast<NSView **>(windowBuffer);
  if (![mainWindowView respondsToSelector:@selector(window)] ||
      mainWindowView.window == nil) {
    napi_throw_error(
        env, NULL,
        "electron-window-rotator:rotate(): NSView doesn't contain window");
    return NULL;
  }

  void *electronScreenshotBuffer;
  size_t electronScreenshotBufferLength;
  status = napi_get_buffer_info(env, args[1], &electronScreenshotBuffer,
                                &electronScreenshotBufferLength);
  if (status != napi_ok) {
    napi_throw_error(
        env, NULL,
        "electron-window-rotator:rotate(): cannot read screenshot handle");
    return NULL;
  } else if (electronScreenshotBufferLength == 0) {
    napi_throw_error(
        env, NULL, "electron-window-rotator:rotate(): empty screenshot handle");
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
  NSLog(@"electron-window-rotator:rotate(): window screenshot size: %0.0f x "
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
  NSLog(@"electron-window-rotator:rotate(): electron screenshot size: %0.0f x "
        @"%0.0f",
        electronScreenshotSize.width, electronScreenshotSize.height);

  // combine two screenshots
  NSImage *image = [[NSImage alloc] initWithSize:windowScreenshotSize];
  [image lockFocus];
  CGRect windowScreenshotRect =
      CGRectMake(0, 0, windowScreenshotSize.width, windowScreenshotSize.height);
  [windowScreenshot drawInRect:windowScreenshotRect];
  CGRect electronScreenshotRect = CGRectMake(0, 0, electronScreenshotSize.width,
                                             electronScreenshotSize.height);
  [electronScreenshot drawInRect:electronScreenshotRect];
  [image unlockFocus];

  // create image layer with rounded corners
  CALayer *imageLayer = [CALayer layer];
  [imageLayer setContents:image];
  [imageLayer setCornerRadius:10.0f];
  [imageLayer setMasksToBounds:YES]; // cuts shadows as well
  [imageLayer setFrame:CGRectMake(offsetX, offsetY, width, height)];

  // add image layer to the animation window, set up OS shadows
  CALayer *animationWindowLayer = [animationWindow.contentView layer];
  [animationWindowLayer addSublayer:imageLayer];
  [animationWindowLayer setShadowRadius:20.0f];
  [animationWindowLayer setShadowOpacity:0.7f];
  [animationWindowLayer setShadowOffset:CGSizeMake(0, -20)];

  // replace window with its screenshot and start animation
  [window setAlphaValue:0.0];
  [animationWindow makeKeyAndOrderFront:nil];
  [CATransaction begin];
  CABasicAnimation *animation =
      [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  [animation setFromValue:[NSNumber numberWithDouble:0.0]];
  [animation setToValue:[NSNumber numberWithDouble:2.0 * M_PI]];
  [animation setDuration:1.0];
  [CATransaction setCompletionBlock:^{
    [window setAlphaValue:1.0];
    [animationWindow close];
    NSLog(@"electron-window-rotator:rotate(): animation done");
  }];
  [imageLayer addAnimation:animation forKey:@"rotation"];
  [CATransaction commit];

  NSLog(@"electron-window-rotator:rotate(): done");
  return NULL;
}
