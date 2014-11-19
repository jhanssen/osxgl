#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#include "common.h"

class ScopedPool
{
public:
    ScopedPool() { mPool = [[NSAutoreleasePool alloc] init]; }
    ~ScopedPool() { [mPool drain]; }

private:
    NSAutoreleasePool* mPool;
};

static void gl(NSOpenGLContext* ctx)
{
    // initialize GL
    glDisable(GL_BLEND);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glViewport(0, 0, 1280, 720);
    glClearColor(1, 0, 0, 1);
    glActiveTexture(GL_TEXTURE0);
    glDisable(GL_DEPTH_TEST);
    GL_CHECK;

    // clear and flush
    glClear(GL_COLOR_BUFFER_BIT);
    [ctx flushBuffer];

    // create a texture
    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    GL_CHECK;

    // initialize texture data
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1280, 720, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    GL_CHECK;
}

int main(int argc, char **argv)
{
    ScopedPool pool;

    NSApplication* app = [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    NSRect rect = NSMakeRect(0, 0, 1280, 720);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:rect
                                         styleMask:(NSResizableWindowMask | NSClosableWindowMask | NSTitledWindowMask | NSMiniaturizableWindowMask)
                                         backing:NSBackingStoreBuffered defer:NO];
    [window setAcceptsMouseMovedEvents:YES];
    [window setTitle:@"GL test"];
    [window retain];

    NSView* contentView = [window contentView];
    [contentView setAutoresizesSubviews:YES];

    NSOpenGLPixelFormatAttribute pixelFormatAttributes[] = {
        //NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersionLegacy,
        NSOpenGLPFAColorSize    , 24                           ,
        NSOpenGLPFAAlphaSize    , 8                            ,
        NSOpenGLPFASampleBuffers, 1                            ,
        NSOpenGLPFASamples      , 16                           ,
        NSOpenGLPFASampleAlpha  ,
        NSOpenGLPFAMultisample  ,
        NSOpenGLPFADoubleBuffer ,
        NSOpenGLPFAAccelerated  ,
        NSOpenGLPFANoRecovery   ,
        0 };

    NSOpenGLPixelFormat* pixelFormat = [[[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes] autorelease];
    NSOpenGLView* glview = [[[NSOpenGLView alloc] initWithFrame:[contentView bounds]] autorelease];
    [glview setPixelFormat:pixelFormat];
    [contentView addSubview:glview];
    [glview retain];
    [app activateIgnoringOtherApps:YES];
    [window makeKeyAndOrderFront:window];
    NSOpenGLContext* ctx = [glview openGLContext];
    [ctx makeCurrentContext];

    gl(ctx);

    [app run];

    return 0;
}
