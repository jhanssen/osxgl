#include "fbo.h"
#include <iostream>

FBO::FBO(GLuint tex, unsigned int width, unsigned int height)
    : mWidth(width), mHeight(height), mValid(true)
{
    init(tex);
}

FBO::~FBO()
{
    if (!mValid)
        return;

    glDeleteFramebuffers(1, &mFbo);
    glDeleteRenderbuffers(mRb.size(), &mRb[0]);
}

GLenum FBO::generate(GLuint tex, unsigned int width, unsigned int height, unsigned int flags)
{
    glGenFramebuffers(1, &mFbo);
    glBindFramebuffer(GL_FRAMEBUFFER, mFbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);

    if (flags & DepthStencil) {
        mRb.resize(1);
        glGenRenderbuffers(mRb.size(), &mRb[0]);
        glBindRenderbuffer(GL_RENDERBUFFER, mRb[0]);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_STENCIL, width, height);
        glBindRenderbuffer(GL_RENDERBUFFER, 0);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, mRb[0]);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, mRb[0]);
    } else {
        if (flags & Depth) {
            assert(mRb.empty());
            mRb.resize(1);
            GLuint& rb = mRb.back();
            glGenRenderbuffers(1, &rb);
            glBindRenderbuffer(GL_RENDERBUFFER, rb);
            glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rb);
        }
        if (flags & Stencil) {
            mRb.resize(mRb.size() + 1);
            GLuint& rb = mRb.back();
            glGenRenderbuffers(1, &rb);
            glBindRenderbuffer(GL_RENDERBUFFER, rb);
            glRenderbufferStorage(GL_RENDERBUFFER, GL_STENCIL_INDEX8, width, height);
            glBindRenderbuffer(GL_RENDERBUFFER, 0);
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rb);
        }
    }

    const GLenum fbstatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (fbstatus != GL_FRAMEBUFFER_COMPLETE) {
        // flush any error if we got one
        glGetError();

        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glDeleteFramebuffers(1, &mFbo);
        glDeleteRenderbuffers(mRb.size(), &mRb[0]);
        mFbo = 0;
        mRb.clear();
    }
    return fbstatus;
}

void FBO::init(GLuint tex)
{
    static unsigned int tryFlags[] = {
        DepthStencil,
        Depth | Stencil,
        Depth,
        Stencil,
        0
    };

    GL_CHECK;
    GLenum status;
    for (size_t idx = 0; idx < sizeof(tryFlags) / sizeof(tryFlags[0]); ++idx) {
        std::cerr << "FBO generate attempt " << (idx + 1) << std::endl;
        status = generate(tex, mWidth, mHeight, tryFlags[idx]);
        if (status == GL_FRAMEBUFFER_COMPLETE)
            break;
    }
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        mValid = false;
        std::string message;
        switch (status) {
        case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
            std::cerr << "Incomplete attachment" << std::endl;
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
            std::cerr << "Missing attachment" << std::endl;
            break;
        case GL_FRAMEBUFFER_UNSUPPORTED:
            std::cerr << "Unsupported framebuffer" << std::endl;
            break;
        default:
            std::cerr << "Unknown status 0x" << std::hex << status << std::endl;
            break;
        }
    }

    GL_CHECK;
}
