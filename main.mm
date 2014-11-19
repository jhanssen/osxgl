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
    // memset(data, 250, width * height * 4);
    // return;

    uint32_t* d = reinterpret_cast<uint32_t*>(data);

    const unsigned char colors[18][4] = { { 255, 80,  80,  255 },
                                          { 255, 80,  80,  255 },
                                          { 128, 128, 128, 255 },
                                          { 128, 128, 128, 255 },
                                          { 128, 128, 128, 255 },
                                          { 128, 128, 128, 255 },
                                          { 80,  80,  255, 255 },
                                          { 80,  80,  255, 255 },
                                          { 128, 128, 128, 255 },
                                          { 128, 128, 128, 255 },
                                          { 128, 128, 128, 255 },
                                          { 128, 128, 128, 255 },
                                          { 80,  255, 80,  255 },
                                          { 80,  255, 80,  255 },
                                          { 128, 128, 128, 255 },
                                          { 128, 128, 128, 255 },
                                          { 128, 128, 128, 255 },
                                          { 128, 128, 128, 255 } };

    int color = 0;
    for (int y = 0; y < height; ++y) {
        if (color >= 18)
            color = 0;

        const uint32_t col = (colors[color][3] << 24) | (colors[color][2] << 16) |
                             (colors[color][1] << 8)  | (colors[color][0]);
        for (int x = 0; x < width; ++x) {
            (*d++) = col;
        }

        ++color;
    }
}

static void blit(GLuint texture, unsigned int x, unsigned int y, unsigned int width, unsigned int height,
                 const std::shared_ptr<BlitShader>& shader)
{
    GL_CHECK;
    Shader::Scope<BlitShader> scope(shader);

    const GLuint pos = shader->variable(BlitShader::Position);
    const GLuint tex = shader->variable(BlitShader::TexCoord);

    glEnableVertexAttribArray(pos);
    glEnableVertexAttribArray(tex);

    shader->bindVertexBuffer();
    glVertexAttribPointer(pos, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), 0);

    shader->bindTextureBuffer();
    glVertexAttribPointer(tex, 2, GL_UNSIGNED_BYTE, GL_FALSE, 2 * sizeof(GLubyte), 0);

    glBindTexture(GL_TEXTURE_2D, texture);
    GL_CHECK;
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
    GL_CHECK;
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
    GLuint tex[2];
    glGenTextures(2, tex);
    GL_CHECK;

    std::shared_ptr<BlitShader> blitShader;
    {
        const GLchar* vertex[] = {
            "attribute vec4 a_position;\n"
            "attribute vec2 a_texCoord;\n"
            "varying vec2   v_texCoord;\n"
            "void main()\n"
            "{\n"
            "  gl_Position = a_position;\n"
            "  v_texCoord.x = a_texCoord.x;\n"
            "  v_texCoord.y = a_texCoord.y;\n"
            "}\n"
        };

        const GLchar* fragment[] = {
            "#ifdef GL_ES\n"
            "precision highp float;\n"
            "#endif\n"
            "varying vec2      v_texCoord;\n"
            "uniform sampler2D s_texture;\n"
            "void main()\n"
            "{\n"
            "  gl_FragColor = texture2D(s_texture, v_texCoord);\n"
            "}\n"
        };

        blitShader = std::make_shared<BlitShader>(vertex, fragment);
        blitShader->use();
        blitShader->defineAttribute(BlitShader::Position, "a_position");
        blitShader->defineAttribute(BlitShader::TexCoord, "a_texCoord");

        glUniform1i(glGetUniformLocation(blitShader->program(), "s_texture"), 0);
    }

    enum { TexWidth = 1280, TexHeight = 720 };

    {
        unsigned char* c = new unsigned char[TexWidth * TexHeight * 4];

        // initialize texture data
        generateTexture(TexWidth, TexHeight, c);
        glBindTexture(GL_TEXTURE_2D, tex[0]);
        GL_CHECK;
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TexWidth, TexHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, c);
        GL_CHECK;

        //generateTexture(TexWidth, TexHeight, c);
        glBindTexture(GL_TEXTURE_2D, tex[1]);
        GL_CHECK;
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TexWidth, TexHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, c);
        GL_CHECK;

        delete[] c;
    }

    glClearColor(0, 1, 1, 1);
    // create a ton of FBOs
    unsigned int cnt = 0;
    for (;;) {
        {
            FBO fbo(tex[0], TexWidth, TexHeight);
            fprintf(stderr, "created fbo 0x%x (%u) on texture 0x%x -> %s\n",
                    fbo.fbo(), ++cnt, tex[0], (fbo.isValid() ? "valid" : "invalid"));
            // clear the FBO
            glClear(GL_COLOR_BUFFER_BIT);

            // blit to the fbo
            blit(tex[1], 0, 0, TexWidth, TexHeight, blitShader);
        }

        // blit to the screen
        blit(tex[0], 0, 0, TexWidth, TexHeight, blitShader);

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
