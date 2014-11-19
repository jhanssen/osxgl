#ifndef SHADER_H
#define SHADER_H

#include <OpenGL/gl.h>
#include <vector>
#include <iostream>
#include <memory>
#include <string>

class Shader
{
public:
    Shader(const GLchar* vertex, const GLchar* fragment)
    {
        const GLchar* v[] = { vertex };
        const GLchar* f[] = { fragment };
        init(v, f);
    }

    template<int VertexCount, int FragmentCount>
    Shader(const GLchar* (&vertex)[VertexCount], const GLchar* (&fragment)[FragmentCount])
    {
        init(vertex, fragment);
    }

    ~Shader()
    {
        if (mValid) {
            glDeleteProgram(mProgram);
        }
    }

    template<int VertexCount, int FragmentCount>
    void init(const GLchar* (&vertex)[VertexCount], const GLchar* (&fragment)[FragmentCount])
    {
        const GLuint v = compile(GL_VERTEX_SHADER, vertex, &mValid);
        if (!mValid)
            return;
        const GLuint f = compile(GL_FRAGMENT_SHADER, fragment, &mValid);
        if (!mValid)
            return;
        mProgram = glCreateProgram();
        glAttachShader(mProgram, v);
        glAttachShader(mProgram, f);

        glLinkProgram(mProgram);

        glDeleteShader(v);
        glDeleteShader(f);
    }

    operator GLuint() { return mProgram; }
    GLuint program() const { return mProgram; }

    GLuint takeProgram();

    void operator()() { glUseProgram(mProgram); }
    void use() { glUseProgram(mProgram); }

    bool isValid() const { return mValid; }

    void defineVariable(size_t pos, GLuint location)
    {
        if (mVariables.size() <= pos) {
            mVariables.resize(pos + 1);
        }
        mVariables[pos] = location;
    }
    void defineUniform(size_t pos, const char* name) { defineVariable(pos, glGetUniformLocation(mProgram, name)); }
    void defineAttribute(size_t pos, const char* name) { defineVariable(pos, glGetAttribLocation(mProgram, name)); }
    GLuint variable(size_t pos) const { assert(pos < mVariables.size()); return mVariables[pos]; }

    template<typename T>
    class Scope
    {
    public:
        Scope(const std::shared_ptr<T>& ptr)
            : shader(ptr)
        {
            shader->use();
            shader->prepare();
        }
        ~Scope()
        {
            shader->clear();
        }
    private:
        std::shared_ptr<T> shader;
    };

private:
    template<int Count>
    GLuint compile(GLuint type, const GLchar* (&source)[Count], bool* ok)
    {
        GLuint shader = glCreateShader(type);
        glShaderSource(shader, Count, source, 0);
        glCompileShader(shader);
        GLint compiled;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
        if (!compiled) {
            GLint length;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
            std::string log(length, ' ');
            glGetShaderInfoLog(shader, length, &length, &log[0]);
            std::cerr << "Shader error: " << log << std::endl;
            *ok = false;
            return 0;
        }
        *ok = true;
        return shader;
    }

private:
    std::vector<GLuint> mVariables;
    GLuint mProgram;
    bool mValid;
};

inline GLuint Shader::takeProgram()
{
    const GLuint prog = mProgram;
    mProgram = 0;
    mValid = false;
    return prog;
}

#endif
