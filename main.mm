#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#include <stdio.h>
#include <unistd.h>
#include "common.h"
#include "fbo.h"
#include "shader.h"

class ScopedPool
{
public:
    ScopedPool() { mPool = [[NSAutoreleasePool alloc] init]; }
    ~ScopedPool() { [mPool drain]; }

private:
    NSAutoreleasePool* mPool;
};

// generate a texture with random color lines
static void generateTexture(unsigned int width, unsigned int height, unsigned char* data)
{
    uint32_t* d = reinterpret_cast<uint32_t*>(data);

    const unsigned char colors[6][4] = { { 255, 0,   0,   255 },
                                         { 0,   255, 0,   255 },
                                         { 0,   0,   255, 255 },
                                         { 0,   255, 255, 255 },
                                         { 255, 255, 0,   255 },
                                         { 255, 0,   255, 255 } };

    int color = 0;
    for (int y = 0; y < height; ++y) {
        if (color >= 6)
            color = 0;

        const uint32_t col = (colors[color][0] << 24) | (colors[color][1] << 16) |
                             (colors[color][2] << 8)  | (colors[color][3]);
        for (int x = 0; x < width; ++x) {
            (*d++) = col;
        }

        ++color;
    }
}

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

    enum { TexWidth = 1280, TexHeight = 720 };

    {
        unsigned char* c = new unsigned char[TexWidth * TexHeight * 4];
        generateTexture(TexWidth, TexHeight, c);

        // initialize texture data
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1280, 720, 0, GL_RGBA, GL_UNSIGNED_BYTE, c);
        GL_CHECK;

        delete[] c;
    }

    glClearColor(0, 1, 0, 1);
    // create a ton of FBOs
    unsigned int cnt = 0;
    for (;;) {
        {
            FBO fbo(tex, 1280, 720);
            fprintf(stderr, "created fbo 0x%x (%u) on texture 0x%x -> %s\n",
                    fbo.fbo(), ++cnt, tex, (fbo.isValid() ? "valid" : "invalid"));
            // clear the FBO
            glClear(GL_COLOR_BUFFER_BIT);

            // draw onto the fbo

        }

        // flush the screen
        [ctx flushBuffer];
        usleep(100000);
    }
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
