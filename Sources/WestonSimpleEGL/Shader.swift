import GLEW

enum Shader {
    case vertex(source: String)
    case fragment(source: String)
}

extension Shader {

    private var type: GLenum {
        switch self {
        case .vertex(_):
            return GLenum(GL_VERTEX_SHADER)
        case .fragment(_):
            return GLenum(GL_FRAGMENT_SHADER)
        }
    }

    private var source: String {
        switch self {
        case .vertex(let source):
            return source
        case .fragment(let source):
            return source
        }
    }
}

extension Shader {
    func compile() -> GLuint? {
        let shader = glCreateShader(type)
        guard shader != 0 else {
            return nil
        }

        source.withCString { str in
            var src: UnsafePointer<GLchar>? = str
            glShaderSource(shader, 1, &src, nil)
        }
        glCompileShader(shader)

        var shaderCompileStatus: GLint = -1
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &shaderCompileStatus)
        if shaderCompileStatus == 0 {
            return nil
        }

        return shader
    }
}