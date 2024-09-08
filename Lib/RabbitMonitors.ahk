/*
 * Copyright (c) 2023, 2024 Xuesong Peng <pengxuesong.cn@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

global A_IntSize := 4
global A_WCharSize := 2

global CCHDEVICENAME := 32
global MONITOR_DEFAULTTONULL := 0
global MONITOR_DEFAULTTOPRIMARY := 1
global MONITOR_DEFAULTTONEAREST := 2

class Point extends Class {
    __New(x := 0, y := 0) {
        this.buff := Buffer(Point.struct_size(), 0)
        this.x := x
        this.y := y
    }

    static x_offset := (*) => 0
    static y_offset := (*) => Point.x_offset() + A_IntSize
    static struct_size := (*) => Point.y_offset() + A_IntSize

    struct_ptr := (*) => this.buff.Ptr

    x {
        get => NumGet(this.struct_ptr(), Point.x_offset(), "Int")
        set => NumPut("Int", Value, this.struct_ptr(), Point.x_offset())
    }
    y {
        get => NumGet(this.struct_ptr(), Point.y_offset(), "Int")
        set => NumPut("Int", Value, this.struct_ptr(), Point.y_offset())
    }
}

class Rect extends Class {
    __New(left := 0, top := 0, right := 0, bottom := 0) {
        this.buff := Buffer(Rect.struct_size(), 0)
        this.left := left
        this.top := top
        this.right := right
        this.bottom := bottom
    }

    static left_offset := (*) => 0
    static top_offset := (*) => Rect.left_offset() + A_IntSize
    static right_offset := (*) => Rect.top_offset() + A_IntSize
    static bottom_offset := (*) => Rect.right_offset() + A_IntSize
    static struct_size := (*) => Rect.bottom_offset() + A_IntSize

    struct_ptr := (*) => this.buff.Ptr

    left {
        get => NumGet(this.struct_ptr(), Rect.left_offset(), "Int")
        set => NumPut("Int", Value, this.struct_ptr(), Rect.left_offset())
    }
    top {
        get => NumGet(this.struct_ptr(), Rect.top_offset(), "Int")
        set => NumPut("Int", Value, this.struct_ptr(), Rect.top_offset())
    }
    right {
        get => NumGet(this.struct_ptr(), Rect.right_offset(), "Int")
        set => NumPut("Int", Value, this.struct_ptr(), Rect.right_offset())
    }
    bottom {
        get => NumGet(this.struct_ptr(), Rect.bottom_offset(), "Int")
        set => NumPut("Int", Value, this.struct_ptr(), Rect.bottom_offset())
    }

    width() {
        return this.right - this.left
    }
    height() {
        return this.bottom - this.top
    }
} ; Rect

class MonitorInfo extends Class {
    __New() {
        this.buff := Buffer(MonitorInfo.struct_size(), 0)
        NumPut("Int", MonitorInfo.struct_size(), this.struct_ptr())
    }

    static size_offset := (*) => 0
    static monitor_offset := (*) => MonitorInfo.size_offset() + A_IntSize
    static work_offset := (*) => MonitorInfo.monitor_offset() + Rect.struct_size()
    static flags_offset := (*) => MonitorInfo.work_offset() + Rect.struct_size()
    static struct_size := (*) => MonitorInfo.flags_offset() + A_IntSize

    struct_ptr := (*) => this.buff.Ptr

    size {
        get => NumGet(this.struct_ptr(), MonitorInfo.size_offset(), "Int")
    }
    monitor {
        get => Rect(
            NumGet(this.struct_ptr(), MonitorInfo.monitor_offset(), "Int"),
            NumGet(this.struct_ptr(), MonitorInfo.monitor_offset() + A_IntSize, "Int"),
            NumGet(this.struct_ptr(), MonitorInfo.monitor_offset() + A_IntSize * 2, "Int"),
            NumGet(this.struct_ptr(), MonitorInfo.monitor_offset() + A_IntSize * 3, "Int")
        )
    }
    work {
        get => Rect(
            NumGet(this.struct_ptr(), MonitorInfo.work_offset(), "Int"),
            NumGet(this.struct_ptr(), MonitorInfo.work_offset() + A_IntSize, "Int"),
            NumGet(this.struct_ptr(), MonitorInfo.work_offset() + A_IntSize * 2, "Int"),
            NumGet(this.struct_ptr(), MonitorInfo.work_offset() + A_IntSize * 3, "Int")
        )
    }
    flags {
        get => NumGet(this.struct_ptr(), MonitorInfo.flags_offset(), "Int")
    }
} ; MonitorInfo

class MonitorInfoEx extends MonitorInfo {
    __New() {
        this.buff := Buffer(MonitorInfoEx.struct_size(), 0)
        NumPut("Int", MonitorInfoEx.struct_size(), this.struct_ptr())
    }

    static device_offset := (*) => MonitorInfoEx.flags_offset() + A_IntSize
    static struct_size := (*) => MonitorInfoEx.device_offset() + A_WCharSize * CCHDEVICENAME

    device {
        get => StrGet(this.struct_ptr() + MonitorInfoEx.device_offset(), CCHDEVICENAME)
    }
} ; MonitorInfoEx

class MonitorManage extends Class {
    static monitors := Map()

    static MonitorEnumProc(hMon, hDC, rect, data) {
        MonitorManage.monitors[hMon] := MonitorManage.GetMonitorInfo(hMon)
        return true
    }

    static EnumDisplayMonitors() {
        MonitorManage.monitors := Map()
        return DllCall("EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", CallbackCreate(ObjBindMethod(MonitorManage, "MonitorEnumProc"), , 4), "Ptr", 0)
    }

    static MonitorFromWindow(hWnd, flags := MONITOR_DEFAULTTONULL) {
        return DllCall("MonitorFromWindow", "Ptr", hWnd, "UInt", flags)
    }

    static MonitorFromPoint(point, flags := MONITOR_DEFAULTTONULL) {
        return DllCall("MonitorFromPoint", "Int64", (point.x & 0xFFFFFFFF) | (point.y << 32), "UInt", flags)
    }

    static MonitorFromRect(rect, flags := MONITOR_DEFAULTTONULL) {
        return DllCall("MonitorFromRect", "Ptr", rect.struct_ptr(), "UInt", flags)
    }

    static GetMonitorInfo(hMon) {
        info := MonitorInfoEx()
        res := DllCall("GetMonitorInfo", "Ptr", hMon, "Ptr", info.struct_ptr())
        return res ? info : 0
    }
} ; MonitorManage
