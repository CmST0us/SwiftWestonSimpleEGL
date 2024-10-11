import CWaylandClient
import GLEW
import CEGL
import XDGShellProtocol

class Window {
    let windowSize: Size

    let egl: Display.EGL
    
    var isFullscreen: Bool = false
    var isConfigured: Bool = false
    var isOpaque: Bool = false

    init(size: Size,
         egl: Display.EGL) {
        self.windowSize = size
        self.egl = egl
    }

    func makeKeyWindow() -> Bool {
        var ret: EGLBoolean = 0
        ret = eglMakeCurrent(egl.eglDisplay, egl.eglSurface, egl.eglSurface, egl.eglContext)
        return ret == EGL_TRUE
    }
}