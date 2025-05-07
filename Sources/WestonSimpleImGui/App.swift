import GLEW
import CEGL
import CWaylandClient
import ImGui
import ImGuiBackend
import Glibc
class App {
    private let display: Display
    private var window: Window? = nil

    private static let vertexShader = """
    attribute vec3 vPosition;
    void main()
    {
       gl_Position = vec4 (vPosition, 1.0);
    }
    """

    private static let fragmentShaderSource = """
    precision mediump float;
    void main()
    {
       gl_FragColor = vec4 (1.0,0.0,0.0,1.0);
    }
    """

    private static let VertexArray: GLuint = 0

    class GL {
        var rotationUniform: GLuint = 0
        var position: GLuint = 0
        var column: GLuint = 0
    }

    init(size: Size) {
        self.display = Display()                
    }

    private func setupScene() {
        let fragment = Shader.fragment(source: Self.fragmentShaderSource)
        let vertex = Shader.vertex(source: Self.vertexShader)

        guard let fragmentShader = fragment.compile(),
              let vertexShader = vertex.compile() else {
            print("compile shader failed")
            exit(-1)
        }

        let shaderProgram = glCreateProgram()
        glAttachShader(shaderProgram, fragmentShader)
        glAttachShader(shaderProgram, vertexShader)

        glBindAttribLocation(shaderProgram, 0, "vPosition")

        glLinkProgram(shaderProgram)

        glDeleteShader(vertexShader)
        glDeleteShader(fragmentShader)

        var isLinked: GLint = 0
        glGetProgramiv(shaderProgram, GLenum(GL_LINK_STATUS), &isLinked)
        guard isLinked != 0 else {
            print("link failed")
            exit(-1)
        }

        glUseProgram(shaderProgram)

        
    }
    
    private func renderScene() {
        imgui_backend_OpenGL3_NewFrame()
        ImGui.newFrame()
        ImGui.showDemoWindow()

        ImGui.render()

        let vVertices: [Float] = [
            0.0, 0.5, 0.0,
            -0.5, -0.5, 0.0,
            0.5, -0.5, 0.0
        ]
        
        glViewport(0, 0, GLsizei(WIDTH), GLsizei(HEIGHT))
        glClearColor(0.0, 0, 0, 0.5)
        glClear(GLenum(GL_COLOR_BUFFER_BIT))

        glEnableVertexAttribArray(Self.VertexArray)
        glVertexAttribPointer(Self.VertexArray, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, vVertices)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 3)
    
        let drawData = UnsafeMutableRawPointer(ImGui.drawData)
        imgui_backend_OpenGL3_RenderDrawData(drawData!)
        eglSwapBuffers(window?.egl.eglDisplay, window?.egl.eglSurface)
    }

    func run() {
        display.open(name: "EGL")
        if let window = display.createWindow(size: Size(WIDTH, HEIGHT)) {
            self.window = window
            let isKeyWindow = window.makeKeyWindow()
            print("key window \(isKeyWindow)")
        }

        glewInit()

        setupScene()

        let context = ImGui.createContext()
        context?.pointee.IO.DisplaySize.x = Float(WIDTH)
        context?.pointee.IO.DisplaySize.y = Float(HEIGHT)
        ImGui.io.pointee.ConfigFlags = ImGui.ConfigFlags.navEnableKeyboard.rawValue
        
        imgui_backend_OpenGL3_Init("#version 100");
        ImGui.styleColorsDark();

        while true {
            display.dispatchPending()
            renderScene()
        }
    }
}