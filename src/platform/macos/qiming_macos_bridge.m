#import <AppKit/AppKit.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>

@interface QimingWindowDelegate : NSObject <NSWindowDelegate>
@property(nonatomic, assign) BOOL shouldClose;
@end

@implementation QimingWindowDelegate
- (instancetype)init {
    self = [super init];
    if (self) {
        _shouldClose = NO;
    }
    return self;
}

- (BOOL)windowShouldClose:(id)sender {
    (void)sender;
    _shouldClose = YES;
    return YES;
}
@end

typedef struct QimingMacOSWindow {
    NSWindow *window;
    NSView *view;
    CAMetalLayer *metalLayer;
    id<MTLDevice> device;
    QimingWindowDelegate *delegate;
} QimingMacOSWindow;

static NSString *qimingNSStringFromUtf8(const char *text) {
    if (text == NULL) {
        return @"Qiming Editor";
    }
    NSString *string = [NSString stringWithUTF8String:text];
    if (string == nil) {
        return @"Qiming Editor";
    }
    return string;
}

void qiming_macos_init_app(void) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
}

void *qiming_macos_create_window(const char *title, int width, int height) {
    qiming_macos_init_app();

    NSRect frame = NSMakeRect(0, 0, width, height);
    NSUInteger style = NSWindowStyleMaskTitled |
                       NSWindowStyleMaskClosable |
                       NSWindowStyleMaskMiniaturizable |
                       NSWindowStyleMaskResizable;

    NSWindow *window = [[NSWindow alloc]
        initWithContentRect:frame
                  styleMask:style
                    backing:NSBackingStoreBuffered
                      defer:NO];

    [window setTitle:qimingNSStringFromUtf8(title)];
    [window center];
    [window setAcceptsMouseMovedEvents:YES];

    NSView *view = [[NSView alloc] initWithFrame:frame];
    [view setWantsLayer:YES];

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    CAMetalLayer *layer = [CAMetalLayer layer];
    layer.device = device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly = YES;
    layer.contentsScale = [NSScreen mainScreen].backingScaleFactor;
    layer.drawableSize = CGSizeMake(width * layer.contentsScale, height * layer.contentsScale);

    [view setLayer:layer];
    [window setContentView:view];

    QimingWindowDelegate *delegate = [[QimingWindowDelegate alloc] init];
    [window setDelegate:delegate];

    QimingMacOSWindow *handle = (QimingMacOSWindow *)calloc(1, sizeof(QimingMacOSWindow));
    handle->window = window;
    handle->view = view;
    handle->metalLayer = layer;
    handle->device = device;
    handle->delegate = delegate;

    return handle;
}

void qiming_macos_show_window(void *handle_ptr) {
    if (handle_ptr == NULL) return;
    QimingMacOSWindow *handle = (QimingMacOSWindow *)handle_ptr;
    [handle->window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

void qiming_macos_close_window(void *handle_ptr) {
    if (handle_ptr == NULL) return;
    QimingMacOSWindow *handle = (QimingMacOSWindow *)handle_ptr;
    [handle->window close];
}

void qiming_macos_destroy_window(void *handle_ptr) {
    if (handle_ptr == NULL) return;
    QimingMacOSWindow *handle = (QimingMacOSWindow *)handle_ptr;
    [handle->window setDelegate:nil];
    [handle->window close];
    free(handle);
}

int qiming_macos_window_should_close(void *handle_ptr) {
    if (handle_ptr == NULL) return 1;
    QimingMacOSWindow *handle = (QimingMacOSWindow *)handle_ptr;
    return handle->delegate.shouldClose ? 1 : 0;
}

void qiming_macos_set_drawable_size(void *handle_ptr, int width, int height, double scale) {
    if (handle_ptr == NULL) return;
    QimingMacOSWindow *handle = (QimingMacOSWindow *)handle_ptr;
    handle->metalLayer.contentsScale = scale;
    handle->metalLayer.drawableSize = CGSizeMake(width * scale, height * scale);
}

void *qiming_macos_get_metal_layer(void *handle_ptr) {
    if (handle_ptr == NULL) return NULL;
    QimingMacOSWindow *handle = (QimingMacOSWindow *)handle_ptr;
    return (__bridge void *)handle->metalLayer;
}

void *qiming_macos_get_metal_device(void *handle_ptr) {
    if (handle_ptr == NULL) return NULL;
    QimingMacOSWindow *handle = (QimingMacOSWindow *)handle_ptr;
    return (__bridge void *)handle->device;
}

int qiming_macos_pump_events(void) {
    qiming_macos_init_app();

    @autoreleasepool {
        NSEvent *event = nil;
        do {
            event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                       untilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]
                                          inMode:NSDefaultRunLoopMode
                                         dequeue:YES];
            if (event != nil) {
                [NSApp sendEvent:event];
            }
        } while (event != nil);

        [NSApp updateWindows];
    }

    return 1;
}
