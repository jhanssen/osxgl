#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

class ScopedPool
{
public:
    ScopedPool() { mPool = [[NSAutoreleasePool alloc] init]; }
    ~ScopedPool() { [mPool drain]; }

private:
    NSAutoreleasePool* mPool;
};

int main(int argc, char **argv)
{
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

    [app run];

    return 0;
}
