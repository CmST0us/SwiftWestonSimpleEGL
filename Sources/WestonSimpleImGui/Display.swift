import CWaylandClient
import CWaylandEGL
import CEGL
import XDGShellProtocol
import ImGui
import CImGui

// MARK: - wl_interface
fileprivate var wl_compositor_interface_ptr = wl_compositor_interface
fileprivate var xdg_wm_base_interface_ptr = xdg_wm_base_interface
fileprivate var wl_seat_interface_ptr = wl_seat_interface

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

// MARK: - wl_pointer
fileprivate func pointer_enter(
    _ data: UnsafeMutableRawPointer?,
    _ pointer: OpaquePointer?,
    _ serial: UInt32, 
    _ surface: OpaquePointer?,
    _ sx: wl_fixed_t,
    _ sy: wl_fixed_t) {
    print("Pointer enter: sx: \(sx), sy: \(sy)")
    
}

fileprivate func pointer_leave(
    _ data: UnsafeMutableRawPointer?,
    _ pointer: OpaquePointer?,
    _ serial: UInt32, 
    _ surface: OpaquePointer?) {
    print("Pointer leave")
    
}

fileprivate func pointer_motion(
    _ data: UnsafeMutableRawPointer?,
    _ pointer: OpaquePointer?,
    _ time: UInt32,
    _ sx: wl_fixed_t,
    _ sy: wl_fixed_t) {

    print("Pointer motion: sx: \(sx), sy: \(sy)")
    var io = ImGui.io
    io?.pointee.MousePos = .init(x: Float(wl_fixed_to_double(sx)), y: Float(wl_fixed_to_double(sy)))
}

fileprivate func pointer_button(
    _ data: UnsafeMutableRawPointer?,
    _ pointer: OpaquePointer?,
    _ serial: UInt32,
    _ time: UInt32,
    _ button: UInt32,
    _ state: UInt32) {
    print("Pointer button: \(button), state: \(state)")
    var io = ImGui.io
    io?.pointee.MouseDown.0 = (state == WL_POINTER_BUTTON_STATE_PRESSED.rawValue)
}

fileprivate var pointer_listener_obj = wl_pointer_listener(
    enter: pointer_enter,
    leave: pointer_leave, 
    motion: pointer_motion, 
    button: pointer_button, 
    axis: {_, _, _, _, _ in }, 
    frame: { _, _ in },
    axis_source: {_, _, _ in}, 
    axis_stop: {_, _, _, _ in}, 
    axis_discrete: {_, _, _, _ in})

// MARK - wl_keyboard
func mapKeycodeToImGuiKey(keycode: UInt32) -> ImGuiKey? {
    switch keycode {
    // 数字键 0-9
    case 11: // KEY_0
        return ImGuiKey_0
    case 2:  // KEY_1
        return ImGuiKey_1
    case 3:  // KEY_2
        return ImGuiKey_2
    case 4:  // KEY_3
        return ImGuiKey_3
    case 5:  // KEY_4
        return ImGuiKey_4
    case 6:  // KEY_5
        return ImGuiKey_5
    case 7:  // KEY_6
        return ImGuiKey_6
    case 8:  // KEY_7
        return ImGuiKey_7
    case 9:  // KEY_8
        return ImGuiKey_8
    case 10: // KEY_9
        return ImGuiKey_9

    // 字母键 A-Z
    case 30: // KEY_A
        return ImGuiKey_A
    case 48: // KEY_B
        return ImGuiKey_B
    case 46: // KEY_C
        return ImGuiKey_C
    case 32: // KEY_D
        return ImGuiKey_D
    case 18: // KEY_E
        return ImGuiKey_E
    case 33: // KEY_F
        return ImGuiKey_F
    case 34: // KEY_G
        return ImGuiKey_G
    case 35: // KEY_H
        return ImGuiKey_H
    case 23: // KEY_I
        return ImGuiKey_I
    case 36: // KEY_J
        return ImGuiKey_J
    case 37: // KEY_K
        return ImGuiKey_K
    case 38: // KEY_L
        return ImGuiKey_L
    case 50: // KEY_M
        return ImGuiKey_M
    case 49: // KEY_N
        return ImGuiKey_N
    case 24: // KEY_O
        return ImGuiKey_O
    case 25: // KEY_P
        return ImGuiKey_P
    case 16: // KEY_Q
        return ImGuiKey_Q
    case 19: // KEY_R
        return ImGuiKey_R
    case 31: // KEY_S
        return ImGuiKey_S
    case 20: // KEY_T
        return ImGuiKey_T
    case 22: // KEY_U
        return ImGuiKey_U
    case 47: // KEY_V
        return ImGuiKey_V
    case 17: // KEY_W
        return ImGuiKey_W
    case 45: // KEY_X
        return ImGuiKey_X
    case 21: // KEY_Y
        return ImGuiKey_Y
    case 44: // KEY_Z
        return ImGuiKey_Z

    // 功能键
    case 1:   // KEY_ESC
        return ImGuiKey_Escape
    case 14:  // KEY_BACKSPACE
        return ImGuiKey_Backspace
    case 15:  // KEY_TAB
        return ImGuiKey_Tab
    case 28:  // KEY_ENTER
        return ImGuiKey_Enter
    case 57:  // KEY_SPACE
        return ImGuiKey_Space
    case 58:  // KEY_CAPSLOCK
        return ImGuiKey_CapsLock
    case 42:  // KEY_LEFTSHIFT
        return ImGuiKey_LeftShift
    case 54:  // KEY_RIGHTSHIFT
        return ImGuiKey_RightShift
    case 29:  // KEY_LEFTCTRL
        return ImGuiKey_LeftCtrl
    case 97:  // KEY_RIGHTCTRL
        return ImGuiKey_RightCtrl
    case 56:  // KEY_LEFTALT
        return ImGuiKey_LeftAlt
    case 100: // KEY_RIGHTALT
        return ImGuiKey_RightAlt
    case 125: // KEY_LEFTMETA
        return ImGuiKey_LeftSuper
    case 126: // KEY_RIGHTMETA
        return ImGuiKey_RightSuper
    case 127: // KEY_COMPOSE
        return ImGuiKey_Menu

    // 箭头键
    case 105: // KEY_LEFT
        return ImGuiKey_LeftArrow
    case 106: // KEY_RIGHT
        return ImGuiKey_RightArrow
    case 103: // KEY_UP
        return ImGuiKey_UpArrow
    case 108: // KEY_DOWN
        return ImGuiKey_DownArrow

    // 编辑键
    case 102: // KEY_HOME
        return ImGuiKey_Home
    case 107: // KEY_END
        return ImGuiKey_End
    case 104: // KEY_PAGEUP
        return ImGuiKey_PageUp
    case 109: // KEY_PAGEDOWN
        return ImGuiKey_PageDown
    case 110: // KEY_INSERT
        return ImGuiKey_Insert
    case 111: // KEY_DELETE
        return ImGuiKey_Delete

    // 功能键 F1-F12
    case 59: // KEY_F1
        return ImGuiKey_F1
    case 60: // KEY_F2
        return ImGuiKey_F2
    case 61: // KEY_F3
        return ImGuiKey_F3
    case 62: // KEY_F4
        return ImGuiKey_F4
    case 63: // KEY_F5
        return ImGuiKey_F5
    case 64: // KEY_F6
        return ImGuiKey_F6
    case 65: // KEY_F7
        return ImGuiKey_F7
    case 66: // KEY_F8
        return ImGuiKey_F8
    case 67: // KEY_F9
        return ImGuiKey_F9
    case 68: // KEY_F10
        return ImGuiKey_F10
    case 87: // KEY_F11
        return ImGuiKey_F11
    case 88: // KEY_F12
        return ImGuiKey_F12

    // 小键盘（数字键盘）
    case 82: // KEY_KP0
        return ImGuiKey_Keypad0
    case 79: // KEY_KP1
        return ImGuiKey_Keypad1
    case 80: // KEY_KP2
        return ImGuiKey_Keypad2
    case 81: // KEY_KP3
        return ImGuiKey_Keypad3
    case 75: // KEY_KP4
        return ImGuiKey_Keypad4
    case 76: // KEY_KP5
        return ImGuiKey_Keypad5
    case 77: // KEY_KP6
        return ImGuiKey_Keypad6
    case 71: // KEY_KP7
        return ImGuiKey_Keypad7
    case 72: // KEY_KP8
        return ImGuiKey_Keypad8
    case 73: // KEY_KP9
        return ImGuiKey_Keypad9
    case 78: // KEY_KPPLUS
        return ImGuiKey_KeypadAdd
    case 74: // KEY_KPMINUS
        return ImGuiKey_KeypadSubtract
    case 83: // KEY_KPDOT
        return ImGuiKey_KeypadDecimal
    case 96: // KEY_KPENTER
        return ImGuiKey_KeypadEnter
    case 55: // KEY_KPASTERISK
        return ImGuiKey_KeypadMultiply
    case 98: // KEY_KPSLASH
        return ImGuiKey_KeypadDivide

    // 符号键
    case 12: // KEY_MINUS
        return ImGuiKey_Minus       // '-'
    case 13: // KEY_EQUAL
        return ImGuiKey_Equal       // '='
    case 26: // KEY_LEFTBRACE
        return ImGuiKey_LeftBracket // '['
    case 27: // KEY_RIGHTBRACE
        return ImGuiKey_RightBracket // ']'
    case 39: // KEY_SEMICOLON
        return ImGuiKey_Semicolon   // ';'
    case 40: // KEY_APOSTROPHE
        return ImGuiKey_Apostrophe  // '''
    case 41: // KEY_GRAVE
        return ImGuiKey_GraveAccent // '`'
    case 43: // KEY_BACKSLASH
        return ImGuiKey_Backslash   // '\'
    case 51: // KEY_COMMA
        return ImGuiKey_Comma       // ','
    case 52: // KEY_DOT
        return ImGuiKey_Period      // '.'
    case 53: // KEY_SLASH
        return ImGuiKey_Slash       // '/'
    case 125: // KEY_LEFTMETA
        return ImGuiKey_LeftSuper
    case 126: // KEY_RIGHTMETA
        return ImGuiKey_RightSuper

    // 其他按键
    case 70:  // KEY_SCROLLLOCK
        return ImGuiKey_ScrollLock
    case 83:  // KEY_NUMLOCK
        return ImGuiKey_NumLock
    case 69:  // KEY_PAUSE
        return ImGuiKey_Pause
    case 127: // KEY_COMPOSE
        return ImGuiKey_Menu

    default:
        return nil
    }
}


fileprivate func keyboard_key(
    _ data: UnsafeMutableRawPointer?,
    _ keyboard: OpaquePointer?,
    _ serial: UInt32, 
    _ time: UInt32,
    _ key: UInt32,
    _ state: UInt32
) {
    if let io = ImGui.io {
        if let mapping = mapKeycodeToImGuiKey(keycode: key) {
            let imguiKey = ImGui.Key(rawValue: Int32(mapping.rawValue)) ?? .none
            io.pointee.addKeyEvent(key: imguiKey, down: state == WL_KEYBOARD_KEY_STATE_PRESSED.rawValue)
            
            // 将ImGuiKey转换为对应的字符
            if state == WL_KEYBOARD_KEY_STATE_PRESSED.rawValue {
                var c: UInt32 = 0
                switch mapping {
                    case ImGuiKey_A: c = UInt32(UnicodeScalar("a").value)
                    case ImGuiKey_B: c = UInt32(UnicodeScalar("b").value)
                    case ImGuiKey_C: c = UInt32(UnicodeScalar("c").value)
                    case ImGuiKey_D: c = UInt32(UnicodeScalar("d").value)
                    case ImGuiKey_E: c = UInt32(UnicodeScalar("e").value)
                    case ImGuiKey_F: c = UInt32(UnicodeScalar("f").value)
                    case ImGuiKey_G: c = UInt32(UnicodeScalar("g").value)
                    case ImGuiKey_H: c = UInt32(UnicodeScalar("h").value)
                    case ImGuiKey_I: c = UInt32(UnicodeScalar("i").value)
                    case ImGuiKey_J: c = UInt32(UnicodeScalar("j").value)
                    case ImGuiKey_K: c = UInt32(UnicodeScalar("k").value)
                    case ImGuiKey_L: c = UInt32(UnicodeScalar("l").value)
                    case ImGuiKey_M: c = UInt32(UnicodeScalar("m").value)
                    case ImGuiKey_N: c = UInt32(UnicodeScalar("n").value)
                    case ImGuiKey_O: c = UInt32(UnicodeScalar("o").value)
                    case ImGuiKey_P: c = UInt32(UnicodeScalar("p").value)
                    case ImGuiKey_Q: c = UInt32(UnicodeScalar("q").value)
                    case ImGuiKey_R: c = UInt32(UnicodeScalar("r").value)
                    case ImGuiKey_S: c = UInt32(UnicodeScalar("s").value)
                    case ImGuiKey_T: c = UInt32(UnicodeScalar("t").value)
                    case ImGuiKey_U: c = UInt32(UnicodeScalar("u").value)
                    case ImGuiKey_V: c = UInt32(UnicodeScalar("v").value)
                    case ImGuiKey_W: c = UInt32(UnicodeScalar("w").value)
                    case ImGuiKey_X: c = UInt32(UnicodeScalar("x").value)
                    case ImGuiKey_Y: c = UInt32(UnicodeScalar("y").value)
                    case ImGuiKey_Z: c = UInt32(UnicodeScalar("z").value)
                    default: break
                }
                if c != 0 {
                    io.pointee.addInputCharacter(c: c)
                }
            }
            
            io.pointee.setKeyEventNativeData(key: imguiKey, nativeKeycode: Int(key), nativeScancode: -1)
        }
    }
}

fileprivate var keyboard_listener_obj = wl_keyboard_listener(
    keymap: {_, _, _, _, _ in}, 
    enter: {_, _, _, _, _ in}, 
    leave: {_, _, _, _ in}, 
    key: keyboard_key, 
    modifiers: {_ , _, _, _, _, _, _ in}, 
    repeat_info: {_, _, _, _ in}
)

// MARK: - Display
class Display {
    fileprivate var display: OpaquePointer?
    fileprivate var registry: OpaquePointer?
	fileprivate var compositor: OpaquePointer?
	fileprivate var surface: OpaquePointer?
    fileprivate var xdgSurface: OpaquePointer?
    fileprivate var xdgWindowManagerBase: OpaquePointer?
    fileprivate var xdgTopLevel: OpaquePointer?
    fileprivate var wlSeat: OpaquePointer?

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
            case String(cString: wl_seat_interface_ptr.name):
                wlSeat = OpaquePointer(wl_registry_bind(registry, name, &wl_seat_interface_ptr, 1))
                let pointer = wl_seat_get_pointer(wlSeat)
                wl_pointer_add_listener(pointer, &pointer_listener_obj, nil)

                let keyboard = wl_seat_get_keyboard(wlSeat)
                wl_keyboard_add_listener(keyboard, &keyboard_listener_obj, nil)
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