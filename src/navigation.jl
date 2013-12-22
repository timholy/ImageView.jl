### GUI controls for play forward/backward, up/down, and frame stepping ###

module Navigation

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

# f is a TkFrame
function init_navigation!(f, ctrls::NavigationControls, state::NavigationState, showframe::Function)
#     btnsz, pad = widget_size()
#     stop = trues(btnsz)
#     mask = copy(stop)
#     stop[[1,btnsz[1]],:] = false
#     stop[:,[1,btnsz[2]]] = false
#     bkg = "gray70"
#     icon = Tk.Image(stop, mask, bkg, "black")
#     ctrls.stop = Button(f, icon)
#     bind(ctrls.stop, "command", path -> stop_playing!(state))
#     local zindex
#     local tindex
#     local stopindex
#     havez = state.zmax > 1
#     havet = state.tmax > 1
#     zindex = 1:6
#     stopindex = 7
#     tindex = 8:13
#     if !havez
#         stopindex = 1
#         tindex = 2:7
#     end
#     grid(ctrls.stop, 1, stopindex, padx=3*pad, pady=pad)
#     win = toplevel(f)
#     if havez || havet
#         bind(win, "<space>", path->stop_playing!(state))
#     end
#     if havez
#         callback = (path->stepz(1,ctrls,state,showframe), path->playz(1,ctrls,state,showframe), 
#             path->playz(-1,ctrls,state,showframe), path->stepz(-1,ctrls,state,showframe),
#             path->setz(ctrls,state,showframe), path->scalez(ctrls,state,showframe))
#         ctrls.stepup, ctrls.playup, ctrls.playdown, ctrls.stepdown, ctrls.textz, ctrls.editz, ctrls.scalez = 
#             addbuttons(f, btnsz, bkg, pad, zindex, "z", callback, 1:state.zmax)
#         bind(win, "<Alt-Up>", path->stepz(1,ctrls,state,showframe))
#         bind(win, "<Alt-Down>", path->stepz(-1,ctrls,state,showframe))
#         bind(win, "<Alt-Shift-Up>", path->playz(1,ctrls,state,showframe))
#         bind(win, "<Alt-Shift-Down>", path->playz(-1,ctrls,state,showframe))
#         updatez(ctrls, state)
#     end
#     if havet
#         callback = (path->stept(-1,ctrls,state,showframe), path->playt(-1,ctrls,state,showframe), 
#             path->playt(1,ctrls,state,showframe), path->stept(1,ctrls,state,showframe),
#             path->sett(ctrls,state,showframe), path->scalet(ctrls,state,showframe))
#         ctrls.stepback, ctrls.playback, ctrls.playfwd, ctrls.stepfwd, ctrls.textt, ctrls.editt, ctrls.scalet = 
#             addbuttons(f, btnsz, bkg, pad, tindex, "t", callback, 1:state.tmax)
#         bind(win, "<Alt-Right>", path->stept(1,ctrls,state,showframe))
#         bind(win, "<Alt-Left>", path->stept(-1,ctrls,state,showframe))
#         bind(win, "<Alt-Shift-Right>", path->playt(1,ctrls,state,showframe))
#         bind(win, "<Alt-Shift-Left>", path->playt(-1,ctrls,state,showframe))
#         updatet(ctrls, state)
#     end
#     # Context menu for settings
#     menu = Menu(f)
#     menu_fps = menu_add(menu, "Playback speed...", path -> set_fps!(state))
#     tk_popup(f, menu)
end

# GUI to set the frame rate
function set_fps!(state::NavigationState)
    win = Toplevel()
    f = Frame(win)
    pack(f, expand=true, fill="both")
    
    l = Label(f, "Frames per second:")
    e = Entry(f, width=5)
    set_value(e, string(state.fps))
    ok = Button(f, "OK")
    cancel = Button(f, "Cancel")
    
    grid(l, 1, 1)
    grid(e, 1, 2, pady=5)
    grid(cancel, 2, 1)
    grid(ok, 2, 2)
    
    function set_close!(state::NavigationState)
        try
            fps = float64(get_value(e))
            state.fps = fps
            destroy(win)
        catch
            set_value(e, string(state.fps))
        end
    end
    bind(e, "<Return>", path->set_close!(state))
    bind(ok, "command", path->set_close!(state))
    bind(cancel, "command", path->destroy(win))
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
function addbuttons(f, sz, bkg, pad, index, orientation, callback, rng)
    rotflag = orientation == "z"
    ctrl = Array(Any, 7)
    ctrl[1], ctrl[2], ctrl[3], ctrl[4] = arrowheads(sz, rotflag)
    mask = trues(sz)
    const color = ("black", "green", "green", "black")
    ibutton = [1,2,5,6]
    for i = 1:4
        icon = Tk.Image(ctrl[i], mask, bkg, color[i])
        b = Button(f, icon)
        grid(b, 1, index[ibutton[i]], padx=pad, pady=pad)
        bind(b, "command", callback[i])
        ctrl[i] = b
    end
    ctrl[5] = Label(f, orientation*":")
    grid(ctrl[5], 1, index[3], padx=pad, pady=pad)
    ctrl[6] = Entry(f, "1")
    configure(ctrl[6], width=5)
    grid(ctrl[6], 1, index[4], padx=pad, pady=pad)
    bind(ctrl[6], "<Return>", callback[5])
    ctrl[7] = Slider(f, rng)
    grid(ctrl[7], 2, index, sticky="ew", padx=pad)
    bind(ctrl[7], "command", callback[6])
    tuple(ctrl...)
end

function updatez(ctrls, state)
    set_value(ctrls.editz, string(state.z))
    set_value(ctrls.scalez, state.z)
    enabledown = state.z > 1
    set_enabled(ctrls.stepdown, enabledown)
    set_enabled(ctrls.playdown, enabledown)
    enableup = state.z < state.zmax
    set_enabled(ctrls.stepup, enableup)
    set_enabled(ctrls.playup, enableup)
end

function updatet(ctrls, state)
    set_value(ctrls.editt, string(state.t))
    set_value(ctrls.scalet, state.t)
    enableback = state.t > 1
    set_enabled(ctrls.stepback, enableback)
    set_enabled(ctrls.playback, enableback)
    enablefwd = state.t < state.tmax
    set_enabled(ctrls.stepfwd, enablefwd)
    set_enabled(ctrls.playfwd, enablefwd)
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
    zstr = get_value(ctrls.editz)
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
    state.z = int(get_value(ctrls.scalez))
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
    tstr = get_value(ctrls.editt)
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
    state.t = int(get_value(ctrls.scalet))
    updatet(ctrls, state)
    showframe(state)
end


export NavigationState,
    NavigationControls,
    init_navigation!

end
