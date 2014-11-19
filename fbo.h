#ifndef FBO_H
#define FBO_H

#include <vector>
#include "common.h"

class FBO
{
public:
    FBO(GLuint tex, unsigned int width, unsigned int height);
    ~FBO();

    bool isValid() const { return mValid; }
    GLuint fbo() const { return mFbo; }

private:
    void init(GLuint tex);

    enum GenerateFlags {
        DepthStencil = 0x1,
        Depth = 0x2,
        Stencil = 0x4
    };
    GLenum generate(GLuint tex, unsigned int width, unsigned int height, unsigned int flags);

private:
    GLuint mFbo;
    std::vector<GLuint> mRb;
    unsigned int mWidth, mHeight;
    bool mValid;
};

#endif
