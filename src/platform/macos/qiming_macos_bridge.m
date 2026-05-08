#import <AppKit/AppKit.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>
#include <stdlib.h>
#include <string.h>

// ─────────────────────────────────────────────────────────────────────────────
// Event queue
// ─────────────────────────────────────────────────────────────────────────────

#define QIMING_EVENT_NONE       0
#define QIMING_EVENT_KEY        1
#define QIMING_EVENT_MOUSE_DOWN 2
#define QIMING_EVENT_MOUSE_UP   3
#define QIMING_EVENT_MOUSE_MOVE 4
#define QIMING_EVENT_SCROLL     5
#define QIMING_EVENT_RESIZE     6
#define QIMING_EVENT_CLOSE      7
#define QIMING_EVENT_TEXT       8

typedef struct QimingEvent {
    int type;
    // Key events
    uint16_t keycode;
    uint32_t modifiers;    // NSEventModifierFlags
    char     text[8];      // UTF-8 text input (up to 7 bytes + null)
    // Mouse events
    float    mouse_x;
    float    mouse_y;
    float    scroll_dx;
    float    scroll_dy;
    // Resize
    int      width;
    int      height;
} QimingEvent;

#define QIMING_EVENT_QUEUE_SIZE 256
static QimingEvent s_event_queue[QIMING_EVENT_QUEUE_SIZE];
static int s_event_queue_head = 0;
static int s_event_queue_tail = 0;

static void qiming_push_event(QimingEvent evt) {
    int next = (s_event_queue_tail + 1) % QIMING_EVENT_QUEUE_SIZE;
    if (next != s_event_queue_head) {
        s_event_queue[s_event_queue_tail] = evt;
        s_event_queue_tail = next;
    }
}

int qiming_poll_event(QimingEvent *out) {
    if (s_event_queue_head == s_event_queue_tail) return 0;
    *out = s_event_queue[s_event_queue_head];
    s_event_queue_head = (s_event_queue_head + 1) % QIMING_EVENT_QUEUE_SIZE;
    return 1;
}

// ─────────────────────────────────────────────────────────────────────────────
// Window delegate (extended with resize + keyboard)
// ─────────────────────────────────────────────────────────────────────────────

@interface QimingWindowDelegate : NSObject <NSWindowDelegate>
@property(nonatomic, assign) BOOL shouldClose;
@end

@implementation QimingWindowDelegate

- (instancetype)init {
    self = [super init];
    if (self) { _shouldClose = NO; }
    return self;
}

- (BOOL)windowShouldClose:(id)sender {
    (void)sender;
    _shouldClose = YES;
    QimingEvent e = {0};
    e.type = QIMING_EVENT_CLOSE;
    qiming_push_event(e);
    return YES;
}

- (void)windowDidResize:(NSNotification *)notification {
    NSWindow *win = notification.object;
    NSSize size = win.contentView.bounds.size;
    QimingEvent e = {0};
    e.type   = QIMING_EVENT_RESIZE;
    e.width  = (int)size.width;
    e.height = (int)size.height;
    qiming_push_event(e);
}

@end

// ─────────────────────────────────────────────────────────────────────────────
// Keyboard-aware view
// ─────────────────────────────────────────────────────────────────────────────

@interface QimingMetalView : NSView
@end

@implementation QimingMetalView

- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)isFlipped { return YES; }   // (0,0) top-left

- (void)keyDown:(NSEvent *)event {
    QimingEvent e = {0};
    e.type      = QIMING_EVENT_KEY;
    e.keycode   = event.keyCode;
    e.modifiers = (uint32_t)event.modifierFlags;

    NSString *chars = event.characters;
    if (chars && chars.length > 0) {
        const char *utf8 = [chars UTF8String];
        if (utf8) {
            strncpy(e.text, utf8, sizeof(e.text) - 1);
        }
    }
    qiming_push_event(e);
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
    QimingEvent e = {0};
    e.type    = QIMING_EVENT_MOUSE_DOWN;
    e.mouse_x = (float)p.x;
    e.mouse_y = (float)p.y;
    qiming_push_event(e);
    [self.window makeFirstResponder:self];
}

- (void)mouseUp:(NSEvent *)event {
    NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
    QimingEvent e = {0};
    e.type    = QIMING_EVENT_MOUSE_UP;
    e.mouse_x = (float)p.x;
    e.mouse_y = (float)p.y;
    qiming_push_event(e);
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
    QimingEvent e = {0};
    e.type    = QIMING_EVENT_MOUSE_MOVE;
    e.mouse_x = (float)p.x;
    e.mouse_y = (float)p.y;
    qiming_push_event(e);
}

- (void)scrollWheel:(NSEvent *)event {
    QimingEvent e = {0};
    e.type      = QIMING_EVENT_SCROLL;
    e.scroll_dx = (float)event.scrollingDeltaX;
    e.scroll_dy = (float)event.scrollingDeltaY;
    qiming_push_event(e);
}

@end

// ─────────────────────────────────────────────────────────────────────────────
// Metal render state (global singleton per-window for simplicity)
// ─────────────────────────────────────────────────────────────────────────────

typedef struct QimingRenderState {
    id<MTLDevice>               device;
    id<MTLCommandQueue>         cmdQueue;
    CAMetalLayer               *layer;
    id<MTLRenderPipelineState>  rectPipeline;
    id<MTLRenderPipelineState>  textPipeline;

    // Current frame
    id<CAMetalDrawable>         drawable;
    id<MTLCommandBuffer>        cmdBuffer;
    id<MTLRenderCommandEncoder> encoder;

    // Glyph texture atlas (simple 512x512 grayscale)
    id<MTLTexture>              glyphAtlas;
    int                         atlasX;
    int                         atlasY;
    int                         atlasRowH;

    // Viewport
    float vpWidth;
    float vpHeight;
} QimingRenderState;

static QimingRenderState *s_rs = NULL;

// ─────────────────────────────────────────────────────────────────────────────
// Embedded MSL shaders
// ─────────────────────────────────────────────────────────────────────────────

static NSString *kRectShaderSrc = @""
"#include <metal_stdlib>\n"
"using namespace metal;\n"
"\n"
"struct RectVIn  { float2 pos [[attribute(0)]]; float4 col [[attribute(1)]]; };\n"
"struct RectVOut { float4 pos [[position]]; float4 col; };\n"
"\n"
"struct Viewport { float2 size; };\n"
"\n"
"vertex RectVOut rect_vert(\n"
"    RectVIn v [[stage_in]],\n"
"    constant Viewport &vp [[buffer(1)]])\n"
"{\n"
"    RectVOut out;\n"
"    // Convert pixel coords to NDC: x: [-1,1], y: [1,-1] (top-left origin)\n"
"    float2 ndc = float2(v.pos.x / vp.size.x * 2.0 - 1.0,\n"
"                        1.0 - v.pos.y / vp.size.y * 2.0);\n"
"    out.pos = float4(ndc, 0.0, 1.0);\n"
"    out.col = v.col;\n"
"    return out;\n"
"}\n"
"\n"
"fragment float4 rect_frag(RectVOut in [[stage_in]]) { return in.col; }\n"
;

static NSString *kTextShaderSrc = @""
"#include <metal_stdlib>\n"
"using namespace metal;\n"
"\n"
"struct TextVIn  { float2 pos [[attribute(0)]]; float2 uv [[attribute(1)]]; float4 col [[attribute(2)]]; };\n"
"struct TextVOut { float4 pos [[position]]; float2 uv; float4 col; };\n"
"\n"
"struct Viewport { float2 size; };\n"
"\n"
"vertex TextVOut text_vert(\n"
"    TextVIn v [[stage_in]],\n"
"    constant Viewport &vp [[buffer(1)]])\n"
"{\n"
"    TextVOut out;\n"
"    float2 ndc = float2(v.pos.x / vp.size.x * 2.0 - 1.0,\n"
"                        1.0 - v.pos.y / vp.size.y * 2.0);\n"
"    out.pos = float4(ndc, 0.0, 1.0);\n"
"    out.uv  = v.uv;\n"
"    out.col = v.col;\n"
"    return out;\n"
"}\n"
"\n"
"fragment float4 text_frag(\n"
"    TextVOut in [[stage_in]],\n"
"    texture2d<float> atlas [[texture(0)]],\n"
"    sampler           smp   [[sampler(0)]])\n"
"{\n"
"    float a = atlas.sample(smp, in.uv).r;\n"
"    return float4(in.col.rgb, in.col.a * a);\n"
"}\n"
;

// ─────────────────────────────────────────────────────────────────────────────
// Pipeline creation
// ─────────────────────────────────────────────────────────────────────────────

static id<MTLRenderPipelineState> qiming_make_rect_pipeline(id<MTLDevice> device) {
    NSError *err = nil;
    id<MTLLibrary> lib = [device newLibraryWithSource:kRectShaderSrc options:nil error:&err];
    if (!lib) {
        NSLog(@"[Qiming] Rect shader error: %@", err);
        return nil;
    }
    MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
    desc.vertexFunction   = [lib newFunctionWithName:@"rect_vert"];
    desc.fragmentFunction = [lib newFunctionWithName:@"rect_frag"];
    desc.colorAttachments[0].pixelFormat              = MTLPixelFormatBGRA8Unorm;
    desc.colorAttachments[0].blendingEnabled          = YES;
    desc.colorAttachments[0].sourceRGBBlendFactor     = MTLBlendFactorSourceAlpha;
    desc.colorAttachments[0].destinationRGBBlendFactor= MTLBlendFactorOneMinusSourceAlpha;
    desc.colorAttachments[0].sourceAlphaBlendFactor   = MTLBlendFactorOne;
    desc.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

    // Vertex layout: float2 pos, float4 color
    MTLVertexDescriptor *vd = [MTLVertexDescriptor new];
    vd.attributes[0].format      = MTLVertexFormatFloat2;
    vd.attributes[0].offset      = 0;
    vd.attributes[0].bufferIndex = 0;
    vd.attributes[1].format      = MTLVertexFormatFloat4;
    vd.attributes[1].offset      = 8;
    vd.attributes[1].bufferIndex = 0;
    vd.layouts[0].stride         = 24; // 2*4 + 4*4
    desc.vertexDescriptor = vd;

    id<MTLRenderPipelineState> ps = [device newRenderPipelineStateWithDescriptor:desc error:&err];
    if (!ps) NSLog(@"[Qiming] Rect pipeline error: %@", err);
    return ps;
}

static id<MTLRenderPipelineState> qiming_make_text_pipeline(id<MTLDevice> device) {
    NSError *err = nil;
    id<MTLLibrary> lib = [device newLibraryWithSource:kTextShaderSrc options:nil error:&err];
    if (!lib) {
        NSLog(@"[Qiming] Text shader error: %@", err);
        return nil;
    }
    MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
    desc.vertexFunction   = [lib newFunctionWithName:@"text_vert"];
    desc.fragmentFunction = [lib newFunctionWithName:@"text_frag"];
    desc.colorAttachments[0].pixelFormat              = MTLPixelFormatBGRA8Unorm;
    desc.colorAttachments[0].blendingEnabled          = YES;
    desc.colorAttachments[0].sourceRGBBlendFactor     = MTLBlendFactorSourceAlpha;
    desc.colorAttachments[0].destinationRGBBlendFactor= MTLBlendFactorOneMinusSourceAlpha;
    desc.colorAttachments[0].sourceAlphaBlendFactor   = MTLBlendFactorOne;
    desc.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

    // Vertex layout: float2 pos, float2 uv, float4 color
    MTLVertexDescriptor *vd = [MTLVertexDescriptor new];
    vd.attributes[0].format      = MTLVertexFormatFloat2;
    vd.attributes[0].offset      = 0;
    vd.attributes[0].bufferIndex = 0;
    vd.attributes[1].format      = MTLVertexFormatFloat2;
    vd.attributes[1].offset      = 8;
    vd.attributes[1].bufferIndex = 0;
    vd.attributes[2].format      = MTLVertexFormatFloat4;
    vd.attributes[2].offset      = 16;
    vd.attributes[2].bufferIndex = 0;
    vd.layouts[0].stride         = 32; // 2*4 + 2*4 + 4*4
    desc.vertexDescriptor = vd;

    id<MTLRenderPipelineState> ps = [device newRenderPipelineStateWithDescriptor:desc error:&err];
    if (!ps) NSLog(@"[Qiming] Text pipeline error: %@", err);
    return ps;
}

// ─────────────────────────────────────────────────────────────────────────────
// Glyph atlas
// ─────────────────────────────────────────────────────────────────────────────

#define ATLAS_SIZE 2048

static id<MTLTexture> qiming_make_glyph_atlas(id<MTLDevice> device) {
    MTLTextureDescriptor *td = [MTLTextureDescriptor new];
    td.pixelFormat = MTLPixelFormatR8Unorm;
    td.width       = ATLAS_SIZE;
    td.height      = ATLAS_SIZE;
    td.storageMode = MTLStorageModeManaged;
    td.usage       = MTLTextureUsageShaderRead;
    return [device newTextureWithDescriptor:td];
}

// ─────────────────────────────────────────────────────────────────────────────
// Window handle
// ─────────────────────────────────────────────────────────────────────────────

typedef struct QimingMacOSWindow {
    NSWindow              *window;
    QimingMetalView       *view;
    CAMetalLayer          *metalLayer;
    id<MTLDevice>          device;
    QimingWindowDelegate  *delegate;
} QimingMacOSWindow;

static NSString *qimingNSStringFromUtf8(const char *text) {
    if (!text) return @"Qiming Editor";
    NSString *s = [NSString stringWithUTF8String:text];
    return s ? s : @"Qiming Editor";
}

// ─────────────────────────────────────────────────────────────────────────────
// Public C API — Window lifecycle
// ─────────────────────────────────────────────────────────────────────────────

void qiming_macos_init_app(void) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
}

void *qiming_macos_create_window(const char *title, int width, int height) {
    qiming_macos_init_app();

    NSRect frame = NSMakeRect(0, 0, width, height);
    NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                       NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;

    NSWindow *window = [[NSWindow alloc]
        initWithContentRect:frame styleMask:style
        backing:NSBackingStoreBuffered defer:NO];

    [window setTitle:qimingNSStringFromUtf8(title)];
    [window center];
    [window setAcceptsMouseMovedEvents:YES];

    QimingMetalView *view = [[QimingMetalView alloc] initWithFrame:frame];
    [view setWantsLayer:YES];

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    CAMetalLayer *layer = [CAMetalLayer layer];
    layer.device            = device;
    layer.pixelFormat       = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly   = NO;   // allow texture read for screenshots
    layer.contentsScale     = [NSScreen mainScreen].backingScaleFactor;
    layer.drawableSize      = CGSizeMake(width  * layer.contentsScale,
                                         height * layer.contentsScale);

    [view setLayer:layer];
    [window setContentView:view];
    [window makeFirstResponder:view];

    QimingWindowDelegate *del = [[QimingWindowDelegate alloc] init];
    [window setDelegate:del];

    QimingMacOSWindow *handle = calloc(1, sizeof(QimingMacOSWindow));
    handle->window     = window;
    handle->view       = view;
    handle->metalLayer = layer;
    handle->device     = device;
    handle->delegate   = del;

    return handle;
}

void qiming_macos_show_window(void *h) {
    if (!h) return;
    QimingMacOSWindow *w = h;
    [w->window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

void qiming_macos_close_window(void *h) {
    if (!h) return;
    [((QimingMacOSWindow *)h)->window close];
}

void qiming_macos_destroy_window(void *h) {
    if (!h) return;
    QimingMacOSWindow *w = h;
    [w->window setDelegate:nil];
    [w->window close];
    free(w);
}

int qiming_macos_window_should_close(void *h) {
    if (!h) return 1;
    return ((QimingMacOSWindow *)h)->delegate.shouldClose ? 1 : 0;
}

void qiming_macos_set_drawable_size(void *h, int w, int ht, double scale) {
    if (!h) return;
    QimingMacOSWindow *win = h;
    win->metalLayer.contentsScale = scale;
    win->metalLayer.drawableSize  = CGSizeMake(w * scale, ht * scale);
}

void *qiming_macos_get_metal_layer(void *h) {
    if (!h) return NULL;
    return (__bridge void *)((QimingMacOSWindow *)h)->metalLayer;
}

void *qiming_macos_get_metal_device(void *h) {
    if (!h) return NULL;
    return (__bridge void *)((QimingMacOSWindow *)h)->device;
}

double qiming_macos_get_backing_scale_factor(void) {
    return (double)[NSScreen mainScreen].backingScaleFactor;
}

int qiming_macos_pump_events(void) {
    @autoreleasepool {
        NSEvent *ev;
        do {
            ev = [NSApp nextEventMatchingMask:NSEventMaskAny
                                    untilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]
                                       inMode:NSDefaultRunLoopMode
                                      dequeue:YES];
            if (ev) [NSApp sendEvent:ev];
        } while (ev);
        [NSApp updateWindows];
    }
    return 1;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public C API — Metal render pipeline setup
// ─────────────────────────────────────────────────────────────────────────────

int qiming_metal_setup(void *window_handle) {
    if (!window_handle) return 0;
    QimingMacOSWindow *win = window_handle;

    if (s_rs) { free(s_rs); }
    s_rs = calloc(1, sizeof(QimingRenderState));

    s_rs->device    = win->device;
    s_rs->layer     = win->metalLayer;
    s_rs->cmdQueue  = [win->device newCommandQueue];

    s_rs->rectPipeline = qiming_make_rect_pipeline(win->device);
    s_rs->textPipeline = qiming_make_text_pipeline(win->device);
    s_rs->glyphAtlas   = qiming_make_glyph_atlas(win->device);
    s_rs->atlasX = 0;
    s_rs->atlasY = 0;
    s_rs->atlasRowH = 0;

    CGSize sz = win->metalLayer.drawableSize;
    s_rs->vpWidth  = (float)sz.width;
    s_rs->vpHeight = (float)sz.height;

    NSLog(@"[Qiming Metal] 渲染管线初始化完成 %.0fx%.0f", s_rs->vpWidth, s_rs->vpHeight);
    return (s_rs->rectPipeline && s_rs->textPipeline) ? 1 : 0;
}

void qiming_metal_set_viewport(float w, float h) {
    if (s_rs) { s_rs->vpWidth = w; s_rs->vpHeight = h; }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public C API — Per-frame rendering
// ─────────────────────────────────────────────────────────────────────────────

int qiming_metal_begin_frame(float r, float g, float b) {
    if (!s_rs || !s_rs->rectPipeline) return 0;

    s_rs->drawable  = [s_rs->layer nextDrawable];
    if (!s_rs->drawable) return 0;

    s_rs->cmdBuffer = [s_rs->cmdQueue commandBuffer];

    MTLRenderPassDescriptor *rpd = [MTLRenderPassDescriptor new];
    rpd.colorAttachments[0].texture    = s_rs->drawable.texture;
    rpd.colorAttachments[0].loadAction = MTLLoadActionClear;
    rpd.colorAttachments[0].clearColor = MTLClearColorMake(r, g, b, 1.0);
    rpd.colorAttachments[0].storeAction= MTLStoreActionStore;

    s_rs->encoder = [s_rs->cmdBuffer renderCommandEncoderWithDescriptor:rpd];
    [s_rs->encoder setViewport:(MTLViewport){0,0,s_rs->vpWidth,s_rs->vpHeight,0,1}];

    return 1;
}

void qiming_metal_end_frame(void) {
    if (!s_rs || !s_rs->encoder) return;
    [s_rs->encoder endEncoding];
    [s_rs->cmdBuffer presentDrawable:s_rs->drawable];
    [s_rs->cmdBuffer commit];
    s_rs->encoder  = nil;
    s_rs->drawable = nil;
    s_rs->cmdBuffer= nil;
}

// ─────────────────────────────────────────────────────────────────────────────
// Draw rect (6 vertices, 2 triangles)
// ─────────────────────────────────────────────────────────────────────────────

void qiming_metal_draw_rect(float x, float y, float w, float h,
                             float r, float g, float b, float a) {
    if (!s_rs || !s_rs->encoder) return;

    // 6 vertices: pos(float2) + col(float4) = 24 bytes each
    float verts[6 * 6] = {
        x,   y,   r,g,b,a,
        x+w, y,   r,g,b,a,
        x,   y+h, r,g,b,a,
        x+w, y,   r,g,b,a,
        x+w, y+h, r,g,b,a,
        x,   y+h, r,g,b,a,
    };
    float vp[2] = { s_rs->vpWidth, s_rs->vpHeight };

    [s_rs->encoder setRenderPipelineState:s_rs->rectPipeline];
    [s_rs->encoder setVertexBytes:verts  length:sizeof(verts) atIndex:0];
    [s_rs->encoder setVertexBytes:vp     length:sizeof(vp)    atIndex:1];
    [s_rs->encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
}

// ─────────────────────────────────────────────────────────────────────────────
// Draw text via CoreText → glyph atlas → Metal quads
// ─────────────────────────────────────────────────────────────────────────────

// Glyph cache entry
#define GLYPH_CACHE_SIZE 2048
typedef struct GlyphEntry {
    uint32_t codepoint;
    float    size;
    // Atlas region
    int      ax, ay, aw, ah;  // pixel coords in atlas
    // Metrics
    float    advance;
    float    bearingX;
    float    bearingY;
    int      valid;
} GlyphEntry;

static GlyphEntry s_glyph_cache[GLYPH_CACHE_SIZE];
static int        s_glyph_cache_count = 0;

static GlyphEntry *qiming_find_glyph(uint32_t cp, float size) {
    for (int i = 0; i < s_glyph_cache_count; i++) {
        if (s_glyph_cache[i].codepoint == cp &&
            fabsf(s_glyph_cache[i].size - size) < 0.1f) {
            return &s_glyph_cache[i];
        }
    }
    return NULL;
}

static GlyphEntry *qiming_rasterize_glyph(uint32_t codepoint, float size,
                                            const char *font_name) {
    if (s_glyph_cache_count >= GLYPH_CACHE_SIZE) return NULL;

    // Detect CJK codepoint and choose appropriate font
    bool is_cjk = ((codepoint >= 0x4E00 && codepoint <= 0x9FFF)
                || (codepoint >= 0x3400 && codepoint <= 0x4DBF)
                || (codepoint >= 0x2E80 && codepoint <= 0x2EFF)
                || (codepoint >= 0x3000 && codepoint <= 0x303F)
                || (codepoint >= 0xFF00 && codepoint <= 0xFFEF)
                || (codepoint >= 0x3040 && codepoint <= 0x30FF)
                || (codepoint >= 0xAC00 && codepoint <= 0xD7AF)
                || (codepoint >= 0xF900 && codepoint <= 0xFAFF)
                || (codepoint >= 0xFE30 && codepoint <= 0xFE4F)
                || (codepoint >= 0x20000 && codepoint <= 0x2FFFF));

    const char *use_font = font_name;
    if (!use_font || !*use_font) {
        use_font = is_cjk ? "PingFang SC" : "Menlo";
    }

    CFStringRef fn = CFStringCreateWithCString(NULL, use_font, kCFStringEncodingUTF8);
    CTFontRef font = CTFontCreateWithName(fn, size, NULL);
    if (!font) {
        // Fallback to system font
        font = CTFontCreateUIFontForLanguage(kCTFontUIFontSystem, size, NULL);
    }
    CFRelease(fn);

    // Get glyph for codepoint
    UniChar chars[2]; int nchars = 1;
    if (codepoint > 0xFFFF) {
        // Surrogate pair
        codepoint -= 0x10000;
        chars[0] = (UniChar)(0xD800 + (codepoint >> 10));
        chars[1] = (UniChar)(0xDC00 + (codepoint & 0x3FF));
        nchars = 2;
    } else {
        chars[0] = (UniChar)codepoint;
    }
    CGGlyph glyph[2] = {0};
    CTFontGetGlyphsForCharacters(font, chars, glyph, nchars);

    // Metrics
    CGSize advances[1];
    CTFontGetAdvancesForGlyphs(font, kCTFontOrientationDefault, glyph, advances, 1);

    CGRect bbox[1];
    CTFontGetBoundingRectsForGlyphs(font, kCTFontOrientationDefault, glyph, bbox, 1);

    int gw = (int)ceil(bbox[0].size.width)  + 2;
    int gh = (int)ceil(bbox[0].size.height) + 2;
    if (gw <= 0) gw = 1;
    if (gh <= 0) gh = 1;

    // Check atlas space — simple row packing
    if (s_rs->atlasX + gw > ATLAS_SIZE) {
        s_rs->atlasX  = 0;
        s_rs->atlasY += s_rs->atlasRowH + 1;
        s_rs->atlasRowH = 0;
    }
    if (s_rs->atlasY + gh > ATLAS_SIZE) {
        // Atlas full — clear and restart (simple eviction)
        s_rs->atlasX = 0; s_rs->atlasY = 0; s_rs->atlasRowH = 0;
        s_glyph_cache_count = 0;
    }

    // Rasterize glyph into bitmap
    size_t bytesPerRow = (size_t)gw;
    uint8_t *pixels = calloc(gw * gh, 1);

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef ctx = CGBitmapContextCreate(pixels, gw, gh, 8, bytesPerRow, cs,
                                              kCGImageAlphaOnly & 0); // grayscale
    CGColorSpaceRelease(cs);
    if (!ctx) { free(pixels); CFRelease(font); return NULL; }

    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    CGContextSetShouldAntialias(ctx, true);
    CGContextSetAllowsAntialiasing(ctx, true);

    CGPoint drawPt = CGPointMake(-bbox[0].origin.x + 1,
                                  -bbox[0].origin.y + 1);
    CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
    CTFontDrawGlyphs(font, glyph, &drawPt, 1, ctx);
    CGContextFlush(ctx);

    // Upload to atlas
    MTLRegion region = MTLRegionMake2D(s_rs->atlasX, s_rs->atlasY, gw, gh);
    [s_rs->glyphAtlas replaceRegion:region
                        mipmapLevel:0
                          withBytes:pixels
                        bytesPerRow:bytesPerRow];

    GlyphEntry *entry = &s_glyph_cache[s_glyph_cache_count++];
    entry->codepoint = codepoint;
    entry->size      = size;
    entry->ax        = s_rs->atlasX;
    entry->ay        = s_rs->atlasY;
    entry->aw        = gw;
    entry->ah        = gh;
    entry->advance   = (float)advances[0].width;
    entry->bearingX  = (float)bbox[0].origin.x;
    entry->bearingY  = (float)bbox[0].origin.y;
    entry->valid     = 1;

    s_rs->atlasX   += gw + 1;
    if (gh > s_rs->atlasRowH) s_rs->atlasRowH = gh;

    CGContextRelease(ctx);
    free(pixels);
    CFRelease(font);
    return entry;
}

void qiming_metal_draw_text(const char *utf8_text,
                              float x, float y,
                              float r, float g, float b, float a,
                              float font_size,
                              const char *font_name) {
    if (!s_rs || !s_rs->encoder || !utf8_text) return;

    // Build quad vertices into a stack buffer
    // Each glyph = 6 verts * (pos2 + uv2 + col4) = 6*8*4 = 192 bytes
    // Max 256 glyphs per call
    #define MAX_GLYPHS 256
    float verts[MAX_GLYPHS * 6 * 8];
    int   numVerts = 0;

    const uint8_t *p = (const uint8_t *)utf8_text;
    float cx = x;

    float invW = 1.0f / ATLAS_SIZE;
    float invH = 1.0f / ATLAS_SIZE;

    float lh = font_size * 1.2f;

    while (*p && numVerts + 6 * 8 <= MAX_GLYPHS * 6 * 8) {
        // Decode UTF-8 codepoint
        uint32_t cp;
        int bytes;
        if ((*p & 0x80) == 0)        { cp = *p; bytes = 1; }
        else if ((*p & 0xE0) == 0xC0){ cp = (*p & 0x1F); bytes = 2; }
        else if ((*p & 0xF0) == 0xE0){ cp = (*p & 0x0F); bytes = 3; }
        else if ((*p & 0xF8) == 0xF0){ cp = (*p & 0x07); bytes = 4; }
        else { p++; continue; }

        for (int i = 1; i < bytes; i++) {
            if ((p[i] & 0xC0) != 0x80) { bytes = 1; break; }
            cp = (cp << 6) | (p[i] & 0x3F);
        }
        p += bytes;

        if (cp == '\n') { cx = x; y += lh; continue; }
        if (cp == ' ')  { cx += font_size * 0.37f; continue; }  // space width ~0.37em for Menlo

        GlyphEntry *ge = qiming_find_glyph(cp, font_size);
        if (!ge) ge = qiming_rasterize_glyph(cp, font_size, font_name);
        if (!ge) { cx += font_size * 0.5f; continue; }
        // Use actual CoreText glyph advance, not fixed-width
        // ge->advance already stores the proper glyph advance from CTFontGetAdvancesForGlyphs

        float gx0 = cx + ge->bearingX;
        float gy0 = y  - ge->bearingY - ge->ah;
        float gx1 = gx0 + ge->aw;
        float gy1 = gy0 + ge->ah;

        float u0 = ge->ax * invW;
        float v0 = ge->ay * invH;
        float u1 = (ge->ax + ge->aw) * invW;
        float v1 = (ge->ay + ge->ah) * invH;

        // Triangle 1
        float *v = &verts[numVerts * 8];
        v[ 0]=gx0; v[ 1]=gy0; v[ 2]=u0; v[ 3]=v0; v[ 4]=r; v[ 5]=g; v[ 6]=b; v[ 7]=a;
        v[ 8]=gx1; v[ 9]=gy0; v[10]=u1; v[11]=v0; v[12]=r; v[13]=g; v[14]=b; v[15]=a;
        v[16]=gx0; v[17]=gy1; v[18]=u0; v[19]=v1; v[20]=r; v[21]=g; v[22]=b; v[23]=a;
        // Triangle 2
        v[24]=gx1; v[25]=gy0; v[26]=u1; v[27]=v0; v[28]=r; v[29]=g; v[30]=b; v[31]=a;
        v[32]=gx1; v[33]=gy1; v[34]=u1; v[35]=v1; v[36]=r; v[37]=g; v[38]=b; v[39]=a;
        v[40]=gx0; v[41]=gy1; v[42]=u0; v[43]=v1; v[44]=r; v[45]=g; v[46]=b; v[47]=a;
        numVerts += 6;

        cx += ge->advance;
    }
    #undef MAX_GLYPHS

    if (numVerts == 0) return;

    float vp[2] = { s_rs->vpWidth, s_rs->vpHeight };
    id<MTLSamplerState> smp;
    MTLSamplerDescriptor *sd = [MTLSamplerDescriptor new];
    sd.minFilter = MTLSamplerMinMagFilterLinear;
    sd.magFilter = MTLSamplerMinMagFilterLinear;
    smp = [s_rs->device newSamplerStateWithDescriptor:sd];

    [s_rs->encoder setRenderPipelineState:s_rs->textPipeline];
    [s_rs->encoder setVertexBytes:verts        length:(size_t)(numVerts*8*4)  atIndex:0];
    [s_rs->encoder setVertexBytes:vp           length:sizeof(vp)              atIndex:1];
    [s_rs->encoder setFragmentTexture:s_rs->glyphAtlas atIndex:0];
    [s_rs->encoder setFragmentSamplerState:smp atIndex:0];
    [s_rs->encoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0 vertexCount:(NSUInteger)numVerts];
}

// ─────────────────────────────────────────────────────────────────────────────
// Event polling
// ─────────────────────────────────────────────────────────────────────────────

int qiming_poll_event_zig(void *out) {
    return qiming_poll_event((QimingEvent *)out);
}

int qiming_event_size(void) {
    return (int)sizeof(QimingEvent);
}
