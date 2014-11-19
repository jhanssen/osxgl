#ifndef COMMON_H
#define COMMON_H

#include <OpenGL/gl.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

inline void _glcheck(const char* function, const char* file, int line)
{
    const GLenum e = glGetError();
    if (e != GL_NO_ERROR) {
        fprintf(stderr, ">> GL ERROR 0x%x @ %s - %s:%d\n", e, function, file, line);
        abort();
    }
}
#define GL_CHECK _glcheck(__PRETTY_FUNCTION__, __FILE__, __LINE__)

#endif
