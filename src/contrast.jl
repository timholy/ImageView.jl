module ImageContrast

using Cairo
using Gtk.ShortNames
using Winston
using Images

type ContrastSettings
    min
    max
end

type ContrastData
    imgmin
    imgmax
    phist::FramedPlot
    chist::Canvas
end

# The callback should have the syntax:
#    callback(cs)
# The callback's job is to replot the image with the new contrast settings
function contrastgui{T}(img::AbstractArray{T}, cs::ContrastSettings, callback::Function)
    win = Window("Adjust contrast", 500, 300)
    contrastgui(win, img, cs, callback)
end

function contrastgui{T}(win, img::AbstractArray{T}, cs::ContrastSettings, callback::Function)
    # Get initial values
    dat = img[:,:]
    immin = minfinite(dat)
    immax = maxfinite(dat)
    if is(cs.min, nothing)
        cs.min = immin
    end
    if is(cs.max, nothing)
        cs.max = immax
    end
    cs.min = convert(T, cs.min)
    cs.max = convert(T, cs.max)

    # Set up GUI
    
    g = Grid() #Table(2,3)
    push!(win, g)
    w = width(win)
    h = height(win)

    slider_range = float64(immin):float64(immax-immin)/200:float64(immax)
    max_slider = Scale(false,slider_range)
    G_.value(max_slider, float64(cs.max))
    chist = Canvas(int(2w/3), h)
    min_slider = Scale(false,slider_range)
    G_.value(min_slider, float64(cs.min))

    g[1,1] = max_slider
    g[1,2] = chist
    g[1,3] = min_slider
    chist[:expand] = true
    
    emax = Entry()
    emin = Entry()
    emax[:text] = string(float64(cs.max))
    emin[:text] = string(float64(cs.min))
    g[2,1] = emax
    g[2,3] = emin
    
#    emax[:textvariable] = max_slider[:variable]
#    emin[:textvariable] = min_slider[:variable]
    
    bx = ButtonBox(true)
    zoom = Button("Zoom")
    full = Button("Full range")
    push!(bx, zoom)
    push!(bx, full)
    g[2,2] = bx
    
    # Prepare the histogram
    nbins = iceil(min(sqrt(length(img)), 200))
    p = prepare_histogram(dat, nbins, immin, immax)
    
    # Store data we'll need for updating
    cdata = ContrastData(immin, immax, p, chist)
    
    function rerender()
        pcopy = deepcopy(cdata.phist)
        bb = Winston.limits(cdata.phist)
        add(pcopy, Curve([cs.min, cs.max], [bb.ymin, bb.ymax], "linewidth", 10, "color", "white"))
        add(pcopy, Curve([cs.min, cs.max], [bb.ymin, bb.ymax], "linewidth", 5, "color", "black"))
        Winston.display(chist, pcopy)
        reveal(chist)
        callback(cs)
    end
    # If we have a image sequence, we might need to generate a new histogram.
    # So this function will be returned to the caller
    function replaceimage(newimg, minval = min(newimg), maxval = max(newimg))
        p = prepare_histogram(newimg, nbins, minval, maxval)
        cdata.imgmin = minval
        cdata.imgmax = maxval
        cdata.phist = p
        rerender()
    end

    # Set initial histogram scale
    setrange(cdata.chist, cdata.phist, cdata.imgmin, cdata.imgmax, rerender) 

    # All bindings
    signal_connect(emin, "activate") do widget
        try
            my_min = float64(emin[:text,String])
            my_max = float64(emax[:text,String])
            update_values(emin, emax, min_slider, max_slider, my_min, my_max, cs, cdata, rerender)
        catch
            emin[:text] = string(cs.min)
        end
    end
    signal_connect(emax, "activate") do widget
        try
            my_min = float64(emin[:text,String])
            my_max = float64(emax[:text,String])
            update_values(emin, emax, min_slider, max_slider, my_min, my_max, cs, cdata, rerender)
        catch
            emax[:text] = string(cs.max)
        end
    end
    signal_connect(min_slider, "value-changed") do widget
        my_min = G_.value(min_slider)
        my_max = G_.value(max_slider)
        update_values(emin, emax, min_slider, max_slider, my_min, my_max, cs, cdata, rerender)
    end
    signal_connect(max_slider, "value-changed") do widget
        my_min = G_.value(min_slider)
        my_max = G_.value(max_slider)
        update_values(emin, emax, min_slider, max_slider, my_min, my_max, cs, cdata, rerender)
    end
    signal_connect(zoom, "clicked") do widget
        setrange(cdata.chist, cdata.phist, cdata.imgmin, cdata.imgmax, rerender)
    end
    signal_connect(full, "clicked") do widget
        setrange(cdata.chist, cdata.phist, min(cdata.imgmin, cs.min), max(cdata.imgmax, cs.max), rerender)
    end
    showall(win)
    replaceimage
end

function update_values(emin, emax, min_slider, max_slider, my_min, my_max, cs, cdata, rerender)
    # Don't let values cross
    my_max = my_max < my_min ? my_min + 0.01 : my_max # offset is arbitrary
    cs.min = convertsafely(typeof(cs.min), my_min)
    cs.max = convertsafely(typeof(cs.max), my_max)
    emin[:text] = string(my_min)
    emax[:text] = string(my_max)
    min_adj = Adjustment(min_slider)
    max_adj = Adjustment(max_slider)
    bb = Winston.limits(cdata.phist)
    xl = getattr(cdata.phist, "xrange")
    xlmin = xl == nothing ? bb.xmin : xl[1]
    xlmax = xl == nothing ? bb.xmax : xl[2]
    if my_max > max_adj[:upper,Float64]
        min_adj[:upper] = my_max
        max_adj[:upper] = my_max
        xlmax = my_max
    end
    if my_min < min_adj[:lower,Float64]
        min_adj[:lower] = my_min
        max_adj[:lower] = my_min
        xlmin = my_min
    end
    min_adj[:value] = my_min
    max_adj[:value] = my_max
#     G_.value(min_slider, my_min)
#     G_.value(max_slider, my_max)
    setattr(cdata.phist, "xrange", (xlmin, xlmax))
    rerender()
end

convertsafely{T<:Integer}(::Type{T}, val) = convert(T, round(val))
convertsafely{T}(::Type{T}, val) = convert(T, val)

function prepare_histogram(img, nbins, immin, immax)
    e = immin:(immax-immin)/(nbins-1):immax*(1+1e-6)
    dat = img[:]
    e, counts = hist(dat[isfinite(dat)], e)
    counts += 1   # because of log scaling
    x, y = stairs(e, counts)
    p = FramedPlot()
    setattr(p, "ylog", true)
    setattr(p.y, "draw_nothing", true)
    setattr(p.x2, "draw_nothing", true)
    setattr(p.frame, "tickdir", 1)
    add(p, FillBetween(x, ones(length(x)), x, y, "color", "black"))
    p
end

function stairs(xin::AbstractVector, yin::Vector)
    nbins = length(yin)
    if length(xin) != nbins+1
        error("Pass edges for x, and bin values for y")
    end
    xout = zeros(0)
    yout = zeros(0)
    sizehint(xout, 2nbins)
    sizehint(yout, 2nbins)
    push!(xout, xin[1])
    for i = 2:nbins
        xtmp = xin[i]
        push!(xout, xtmp)
        push!(xout, xtmp)
    end
    push!(xout, xin[end])
    for i = 1:nbins
        ytmp = yin[i]
        push!(yout, ytmp)
        push!(yout, ytmp)
    end
    xout, yout
end

function setrange(c::Canvas, p, minval, maxval, render::Function)
    setattr(p, "xrange", (minval, maxval))
    render()
end
    
end
