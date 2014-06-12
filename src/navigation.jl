### GUI controls for play forward/backward, up/down, and frame stepping ###

module Navigation

import Gtk
using Gtk.ShortNames

## Type for holding GUI state
# This specifies a particular 2d slice from a possibly-4D image
type NavigationState
    # Dimensions:
    zmax::Int          # number of frames in z, set to 1 if only 2 spatial dims
    tmax::Int          # number of frames in t, set to 1 if only a single image
    z::Int             # current position in z-stack
    t::Int             # current moment in time
    # Other state data:
    timer              # nothing if not playing, TimeoutAsyncWork if we are
    fps::Float64       # playback speed in frames per second
end

NavigationState(zmax::Integer, tmax::Integer, z::Integer, t::Integer) = NavigationState(int(zmax), int(tmax), int(z), int(t), nothing, 30.0)
NavigationState(zmax::Integer, tmax::Integer) = NavigationState(zmax, tmax, 1, 1)

function stop_playing!(state::NavigationState)
    if !is(state.timer, nothing)
        stop_timer(state.timer)
        state.timer = nothing
    end
end

## Type for holding "handles" to GUI controls
type NavigationControls
    stepup                            # z buttons...
    stepdown
    playup
    playdown
    stepback                          # t buttons...
    stepfwd
    playback
    playfwd
    stop
    editz                             # edit boxes
    editt
    textz                             # static text (information)
    textt
    scalez                            # scale (slider) widgets
    scalet
end
NavigationControls() = NavigationControls(nothing, nothing, nothing, nothing,
                                          nothing, nothing, nothing, nothing,
                                          nothing, nothing, nothing, nothing,
                                          nothing, nothing, nothing)

# g is a container (e.g., Grid) for all the navigation controls)
function init_navigation!(g, ctrls::NavigationControls, state::NavigationState, showframe::Function)
    btnsz, pad = widget_size()
    # Build the stop button
    bkg = Gtk.RGB(0xb0, 0xb0, 0xb0)
    blk = Gtk.RGB(0x00, 0x00, 0x00)
    stopicon = fill(blk, btnsz)
    stopicon[[1,btnsz[1]],:] = bkg
    stopicon[:,[1,btnsz[2]]] = bkg
    icon = @Pixbuf(data=stopicon, has_alpha=false)
    ctrls.stop = @Button(Gtk.@Image(icon))
    setproperty!(ctrls.stop, :border_width, pad)
    signal_connect(ctrls.stop, "clicked") do widget
        stop_playing!(state)
    end
    # Determine the button layout. This is a bit complex because
    # the arrangement of buttons depends on whether we have z and/or t information
    local zindex
    local tindex
    local stopindex
    havez = state.zmax > 1
    havet = state.tmax > 1
    zindex = 1:6
    stopindex = 7
    tindex = 8:13
    if !havez
        stopindex = 1
        tindex = 2:7
    end
    g[stopindex, 1] = ctrls.stop
#     g[ctrls.stop, :margin_left] = 3*pad
#     g[ctrls.stop, :margin_right] = 3*pad
#     g[ctrls.stop, :margin_top] = pad
#     g[ctrls.stop, :margin_bottom] = pad
    win = toplevel(g)
#     if havez || havet
#         bind(win, "<space>", path->stop_playing!(state))
#     end
    if havez
        callback = (obj->stepz(1,ctrls,state,showframe), obj->playz(1,ctrls,state,showframe), 
            obj->playz(-1,ctrls,state,showframe), obj->stepz(-1,ctrls,state,showframe),
            obj->setz(ctrls,state,showframe), obj->scalez(ctrls,state,showframe))
        ctrls.stepup, ctrls.playup, ctrls.playdown, ctrls.stepdown, ctrls.textz, ctrls.editz, ctrls.scalez = 
            addbuttons(g, btnsz, bkg, pad, zindex, "z", callback, 1:state.zmax)
#         bind(win, "<Alt-Up>", obj->stepz(1,ctrls,state,showframe))
#         bind(win, "<Alt-Down>", obj->stepz(-1,ctrls,state,showframe))
#         bind(win, "<Alt-Shift-Up>", obj->playz(1,ctrls,state,showframe))
#         bind(win, "<Alt-Shift-Down>", obj->playz(-1,ctrls,state,showframe))
        updatez(ctrls, state)
    end
    if havet
        callback = (obj->stept(-1,ctrls,state,showframe), obj->playt(-1,ctrls,state,showframe), 
            obj->playt(1,ctrls,state,showframe), obj->stept(1,ctrls,state,showframe),
            obj->sett(ctrls,state,showframe), obj->scalet(ctrls,state,showframe))
        ctrls.stepback, ctrls.playback, ctrls.playfwd, ctrls.stepfwd, ctrls.textt, ctrls.editt, ctrls.scalet = 
            addbuttons(g, btnsz, bkg, pad, tindex, "t", callback, 1:state.tmax)
#         bind(win, "<Alt-Right>", obj->stept(1,ctrls,state,showframe))
#         bind(win, "<Alt-Left>", obj->stept(-1,ctrls,state,showframe))
#         bind(win, "<Alt-Shift-Right>", obj->playt(1,ctrls,state,showframe))
#         bind(win, "<Alt-Shift-Left>", obj->playt(-1,ctrls,state,showframe))
        updatet(ctrls, state)
    end
    # Context menu for settings
    menu = @Menu()
    signal_connect(parent(g), "button_press_event") do widget, event
        if event.button == 3 && event.event_type == EventType.BUTTON_PRESS
            popup(menu, event)
        end
    end
    playback = @MenuItem("Playback speed...")
    signal_connect(playback, "activate") do widget
        set_fps!(state)
    end
    push!(menu, playback)
end

# GUI to set the frame rate
function set_fps!(state::NavigationState)
    l = @Label("Frames per second:")
    e = @Entry()
    setproperty!(e, :text, string(state.fps))
    ok = @Button("OK")
    cancel = Button("Cancel")
    
    g = @Table(2, 2)
    win = Window("Set frame rate",200,60)
    push!(win, g)
    g[1,1] = l
    g[2,1] = e
    g[1,2] = cancel
    g[2,2] = ok
    showall(win)
    
    function set_close!(state::NavigationState)
        try
            fps = float64(getproperty(e, :text, String))
            state.fps = fps
            destroy(win)
        catch
            setproperty!(e, :text, string(state.fps))
        end
    end
    signal_connect(ok, "clicked") do widget
        set_close!(state)
        destroy(win)
    end
    signal_connect(cancel, "clicked") do widget
        destroy(win)
    end
end

function widget_size()
    btnsz = OS_NAME == :Darwin ? (13, 13) : (21, 21)
    pad = 5
    return btnsz, pad
end

# Functions for drawing icons
function arrowheads(sz, vert::Bool)
    datasm = icondata(sz, 0.5)
    datalg = icondata(sz, 0.8)
    if vert
        return datasm[:,end:-1:1], datalg[:,end:-1:1], datalg, datasm
    else
        datasm = datasm'
        datalg = datalg'
        return datasm[end:-1:1,:], datalg[end:-1:1,:], datalg, datasm
    end
end

function icondata(iconsize, frac)
    center = iceil(iconsize[1]/2)
    data = Bool[ 2abs(i-center)< iconsize[2]-(j-1)/frac for i = 1:iconsize[1], j = 1:iconsize[2] ]
    data .== true
end

# index contains the grid position of each object
# orientation is "t" or "z"
# callback is an array of 5 entries, the 5th being the edit box
function addbuttons(g, sz, bkg, pad, index, orientation, callback, rng)
    rotflag = orientation == "z"
    ctrl = Array(Any, 7)
    ctrl[1], ctrl[2], ctrl[3], ctrl[4] = arrowheads(sz, rotflag)
    buf = Array(Gtk.RGB, sz)
    const color = (Gtk.RGB(0,0,0), Gtk.RGB(0,0xff,0), Gtk.RGB(0,0xff,0), Gtk.RGB(0,0,0))
    ibutton = [1,2,5,6]
    for i = 1:4
        fill!(buf, bkg)
        buf[ctrl[i]] = color[i]
        icon = @Pixbuf(data=copy(buf), has_alpha=false)
        b = @Button(@Image(icon))
        g[index[ibutton[i]],1] = b
        setproperty!(b, :border_width, pad)
        signal_connect(callback[i], b, "clicked")
        ctrl[i] = b
    end
    l = @Label(orientation*":")
    g[index[3],1] = l
    setproperty!(l, :xpad, pad)
    setproperty!(l, :ypad, pad)
    ctrl[5] = l
    e = @Entry()
    setproperty!(e, :text, "1")
#     configure(ctrl[6], width=5)
    g[index[4],1] = e
#     e[:padding] = pad
    signal_connect(callback[5], e, "activate")
    ctrl[6] = e
    s = @Scale(false, rng)
    g[index,2] = s
#     s[:padding] = pad
    signal_connect(callback[6], s, "value-changed")
    ctrl[7] = s
    tuple(ctrl...)
end

function updatez(ctrls, state)
    setproperty!(ctrls.editz, :text, string(state.z))
    G_.value(ctrls.scalez, state.z)
    enabledown = state.z > 1
    setproperty!(ctrls.stepdown, :sensitive, enabledown)
    setproperty!(ctrls.playdown, :sensitive, enabledown)
    enableup = state.z < state.zmax
    setproperty!(ctrls.stepup, :sensitive, enableup)
    setproperty!(ctrls.playup, :sensitive, enableup)
end

function updatet(ctrls, state)
    setproperty!(ctrls.editt, :text, string(state.t))
    G_.value(ctrls.scalet, state.t)
    enableback = state.t > 1
    setproperty!(ctrls.stepback, :sensitive, enableback)
    setproperty!(ctrls.playback, :sensitive, enableback)
    enablefwd = state.t < state.tmax
    setproperty!(ctrls.stepfwd, :sensitive, enablefwd)
    setproperty!(ctrls.playfwd, :sensitive, enablefwd)
end

function incrementz(inc, ctrls, state, showframe)
    state.z += inc
    updatez(ctrls, state)
    showframe(state)
end

function stepz(inc, ctrls, state, showframe)
    if 1 <= state.z+inc <= state.zmax
        incrementz(inc, ctrls, state, showframe)
    else
        stop_playing!(state)
    end
end

function playz(inc, ctrls, state, showframe)
    if !(state.fps > 0)
        error("Frame rate is not positive")
    end
    stop_playing!(state)
    dt = 1/state.fps
    state.timer = TimeoutAsyncWork((timer, status) -> stepz(inc, ctrls, state, showframe))
    start_timer(state.timer, dt, dt)
end

function setz(ctrls,state, showframe)
    zstr = getproperty(ctrls.editz, :text, String)
    try
        val = int(zstr)
        state.z = val
        updatez(ctrls, state)
        showframe(state)
    catch
        updatez(ctrls, state)
    end
end

function scalez(ctrls, state, showframe)
    state.z = int(G_.value(ctrls.scalez))
    updatez(ctrls, state)
    showframe(state)
end

function incrementt(inc, ctrls, state, showframe)
    state.t += inc
    updatet(ctrls, state)
    showframe(state)
end

function stept(inc, ctrls, state, showframe)
    if 1 <= state.t+inc <= state.tmax
        incrementt(inc, ctrls, state, showframe)
    else
        stop_playing!(state)
    end
end

function playt(inc, ctrls, state, showframe)
    if !(state.fps > 0)
        error("Frame rate is not positive")
    end
    stop_playing!(state)
    dt = 1/state.fps
    state.timer = TimeoutAsyncWork((timer, status) -> stept(inc, ctrls, state, showframe))
    start_timer(state.timer, dt, dt)
end

function sett(ctrls,state, showframe)
    tstr = getproperty(ctrls.editt, :text, String)
    try
        val = int(tstr)
        state.t = val
        updatet(ctrls, state)
        showframe(state)
    catch
        updatet(ctrls, state)
    end
end

function scalet(ctrls, state, showframe)
    state.t = int(G_.value(ctrls.scalet))
    updatet(ctrls, state)
    showframe(state)
end


export NavigationState,
    NavigationControls,
    init_navigation!

end
