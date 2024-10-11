import CWaylandClient
import CWaylandEGL
import CEGL
import XDGShellProtocol

fileprivate var wl_compositor_interface_ptr = wl_compositor_interface
fileprivate var xdg_wm_base_interface_ptr = xdg_wm_base_interface

// MARK: - xdg_wm_base_listener
fileprivate func xdg_wm_base_ping(
    _ data: UnsafeMutableRawPointer?,
    _ shell: OpaquePointer?, 
    serial: UInt32) {
    xdg_wm_base_pong(shell, serial)
}
fileprivate var xdg_wm_base_listener_obj = xdg_wm_base_listener(
    ping: xdg_wm_base_ping)

// MARK: - registry
fileprivate func registry_add_object(
    _ data: UnsafeMutableRawPointer?, 
    registry: OpaquePointer?, 
    name: UInt32, 
    interface: UnsafePointer<CChar>?, 
    version: UInt32) {
    guard let data,
        let interface else {
        return
    }
    let unmanagedSelf = Unmanaged<Display>.fromOpaque(data).takeUnretainedValue()
    unmanagedSelf.onListenerGlobal(name: name, interfaceName: String(cString: interface), version: version)
}

fileprivate func registry_remove_object(
    _ data: UnsafeMutableRawPointer?, 
    _ registry: OpaquePointer?, 
    _ name: UInt32) {
    guard let data else {
        return
    }
    let unmanagedSelf = Unmanaged<Display>.fromOpaque(data).takeUnretainedValue()
    unmanagedSelf.onListenerGlobalRemove(name: name)
}

fileprivate var registry_listener = wl_registry_listener(
    global: registry_add_object, 
    global_remove: registry_remove_object)

// MARK: - xdg_surface_listener
fileprivate func handle_surface_configure(
    _ data: UnsafeMutableRawPointer?, 
    _ surface: OpaquePointer?, 
    _ serial: UInt32) {
    xdg_surface_ack_configure(surface, serial)
}

fileprivate var xdg_surface_listener_obj = xdg_surface_listener(
    configure: handle_surface_configure)

// MARK: - xdg_toplevel_listener
fileprivate func handle_toplevel_configure(
    _ data: UnsafeMutableRawPointer?, 
    _ toplevel: OpaquePointer?, 
    _ width: Int32, 
    _ height: Int32, 
    _ states: UnsafeMutablePointer<wl_array>?) {

}

fileprivate func handle_toplevel_close(
    _ data: UnsafeMutableRawPointer?, 
    _ xdg_toplevel: OpaquePointer?) {

}

fileprivate func handle_toplevel_configure_bounds(
    _ data: UnsafeMutableRawPointer?, 
    _ xdg_toplevel: OpaquePointer?, 
    _ widht: Int32, 
    _ height: Int32) {

}

fileprivate var xdg_toplevel_listener_obj = xdg_toplevel_listener(
    configure: handle_toplevel_configure, 
    close: handle_toplevel_close, 
    configure_bounds: handle_toplevel_configure_bounds)

// MARK: - Display
class Display {
    fileprivate var display: OpaquePointer?
    fileprivate var registry: OpaquePointer?
	fileprivate var compositor: OpaquePointer?
	fileprivate var surface: OpaquePointer?
    fileprivate var xdgSurface: OpaquePointer?
    fileprivate var xdgWindowManagerBase: OpaquePointer?
    fileprivate var xdgTopLevel: OpaquePointer?

	var seat: OpaquePointer?
	var pointer: OpaquePointer?
	var keyboard: OpaquePointer?
	var shm: OpaquePointer?
	var cursorTheme: OpaquePointer?
	var defaultCursor: OpaquePointer?
	var cursorSurface: OpaquePointer?

    private var egl: EGL?

    init(name: String? = nil) {
        display = wl_display_connect(name?.withCString{$0} ?? nil)
        registry = wl_display_get_registry(display)

        let pointerToSelf = Unmanaged.passUnretained(self).toOpaque()
        wl_registry_add_listener(registry, &registry_listener, pointerToSelf)
    }

    fileprivate func onListenerGlobal(name: UInt32, interfaceName: String, version: UInt32) {
        print("Global add name: \(name), interface: \(interfaceName), version: \(version)")
        switch interfaceName {
            case String(cString: wl_compositor_interface_ptr.name):
                compositor = OpaquePointer(wl_registry_bind(registry, name, &wl_compositor_interface_ptr, 1))
            case String(cString: xdg_wm_base_interface_ptr.name):
                xdgWindowManagerBase = OpaquePointer(wl_registry_bind(registry, name, &xdg_wm_base_interface_ptr, 1))
                xdg_wm_base_add_listener(xdgWindowManagerBase, &xdg_wm_base_listener_obj, nil)
            default:
                break
        }
    }

    fileprivate func onListenerGlobalRemove(name: UInt32) {
        print("Global remove name: \(name)")
    }

    func open(name: String? = nil) {
        wl_display_dispatch(display)

        let surface = wl_compositor_create_surface(compositor)
        self.surface = surface

        let xdgSurface = xdg_wm_base_get_xdg_surface(xdgWindowManagerBase, surface)
        self.xdgSurface = xdgSurface
        xdg_surface_add_listener(xdgSurface, &xdg_surface_listener_obj, nil)

        let xdgTopLevel = xdg_surface_get_toplevel(xdgSurface)
        self.xdgTopLevel = xdgTopLevel
        xdg_toplevel_add_listener(xdgTopLevel, &xdg_toplevel_listener_obj, nil)
        xdg_toplevel_set_title(xdgTopLevel, name?.withCString{$0})
    }

    func createWindow(size: Size) -> Window? {
        // EGL
        let egl = EGL(display: self, size: size)
        self.egl = egl
        return Window(size: size,
                      egl: egl)
    }

    func dispatchPending() {
        wl_display_dispatch_pending(display)
    }
}

// MARK: - EGL
extension Display {
    class EGL {
        var eglDisplay: EGLDisplay?
        var eglContext: EGLContext?
        var eglConfig: EGLConfig?
        var eglSurface: EGLSurface?

        init(display: Display, size: Size) {
            var contextAttributes: [EGLint] = [
                EGL_CONTEXT_CLIENT_VERSION, 2,
                EGL_NONE
            ].map{EGLint($0)}

            var configAttribute: [EGLint] = [
                EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
                EGL_RED_SIZE, 8,
                EGL_GREEN_SIZE, 8,
                EGL_BLUE_SIZE, 8,
                EGL_ALPHA_SIZE, 8,
                EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
                EGL_NONE
            ].map{EGLint($0)}

            let nativeDisplay = EGLNativeDisplayType(display.display)
            self.eglDisplay = eglGetDisplay(nativeDisplay)
            assert(self.eglDisplay != nil)

            var major: EGLint = 0
            var minor: EGLint = 0
            var numberOfConfig: EGLint = 0
            var ret: EGLBoolean = 0
            ret = eglInitialize(self.eglDisplay, &major, &minor)
            assert(ret == EGL_TRUE)
            ret = eglBindAPI(EGLenum(EGL_OPENGL_ES_API))
            assert(ret == EGL_TRUE)

            var eglConfig: EGLConfig? = nil
            ret = eglChooseConfig(self.eglDisplay, &configAttribute, &eglConfig, 1, &numberOfConfig)
            assert(ret == EGL_TRUE && numberOfConfig == 1)

            self.eglConfig = eglConfig

            self.eglContext = eglCreateContext(self.eglDisplay, self.eglConfig, nil, &contextAttributes)
            assert(self.eglContext != nil)

            let window = wl_egl_window_create(display.surface, Int32(size.width), Int32(size.height))
            let windowNative = EGLNativeWindowType(bitPattern: window)
            let eglSurface = eglCreateWindowSurface(eglDisplay, eglConfig, windowNative, nil)
            self.eglSurface = eglSurface
        }
    }
}