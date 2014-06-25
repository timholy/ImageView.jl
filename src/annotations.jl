# Once this stabilizes, migrate to a Base.Graphics layer? Only if that supports text, which seems unlikely.
using Color
using Base.Graphics

abstract AbstractAnnotation

# Use this type when you want your annotation to be linked to particular data-coordinates
# (for example, to highlight a particular data point)
# devicebb(data) returns a BoundingBox in device coordinates, userbb(data) returns one in user coordinates.
# It's up to the draw() function to decide how to exploit these (most commonly, with set_coords())
type AnchoredAnnotation{T} <: AbstractAnnotation
    devicebb::Function
    userbb::Function
    data::T
    valid::Bool
end
AnchoredAnnotation{T}(devicebb::Function, userbb::Function, data::T) = AnchoredAnnotation{T}(devicebb, userbb, data, true)

# Use this type when you want your annotation to appear at a specific point on the screen, regardless
# of zoom/resize state (e.g., a scale bar)
type FloatingAnnotation{T} <: AbstractAnnotation
    devicebb::Function
    data::T
end
# FloatingAnnotation{T}(devicebb::Function, data::T) = AnchoredAnnotation{T}(devicebb, data)

type AnnotationScalebarFixed{T}
    width::T   # Probably has units
    height::T
    getsize::Function   # syntax w,h = getsize(width,height)
    centerx::Float64
    centery::Float64
    color::ColorValue
end
# AnnotationScalebar{T}(width::T, height::T, getsize::Function, centerx::Real, centery::Real, color::ColorValue = RGB(1,1,1)) = AnnotationScalebar{T}(width, height, getsize, float64(centerx), float64(centery), color)

type AnnotationText
    x::Float64
    y::Float64
    z::Float64
    t::Float64
    string::String
    color::ColorValue
    fontfamily::ASCIIString
    fontoptions::ASCIIString
    fontsize::Integer
    fontdesc::ASCIIString
    angle::Float64
    halign::ASCIIString
    valign::ASCIIString
    markup::Bool
    scale::Bool
end

function AnnotationText(x::Real, y::Real, str::String;
                        z = NaN, t = NaN,
                        color = RGB(0,0,0), angle = 0.0, fontfamily = "sans", fontsize = 10,
                        fontoptions = "",  halign = "center", valign = "center", markup = false, scale=true)
    AnnotationText(float64(x), float64(y), float64(z), float64(t), str, color, fontfamily, fontoptions, fontsize, fontdescription(fontfamily, fontoptions, fontsize),
                   float64(angle), halign, valign, markup, scale)
end

fontdescription(fontfamily, fontoptions, fontsize) = string(fontfamily, " ", fontoptions, " ", fontsize)

type AnnotationPoints{R<:Union(Real,(Real,Real)),T<:Union(R,Vector{R},Matrix{R})}
    pts::T
    z::Float64
    t::Float64
    size::Float64
    shape::Char
    color::ColorValue
    linewidth::Float64
    linecolor::ColorValue
    scale::Bool
end

AnnotationPoints{R<:(Real,Real)}(xys::Vector{R}=(Float64,Float64)[]; z = NaN, t = NaN, size=10.0, shape::Char='x', color = RGB(1,1,1), linewidth=1.0, linecolor=color, scale::Bool=false) = AnnotationPoints{R,Vector{R}}(xys, z, t, float(size), shape, Color.color(color), float(linewidth), Color.color(linecolor), scale)

AnnotationPoints{R<:Real}(xys::Matrix{R}; z = NaN, t = NaN, size=10.0, shape::Char='x', color = RGB(1,1,1), linewidth=1.0, linecolor=color, scale::Bool=false) = AnnotationPoints{R,Matrix{R}}(xys, z, t, float(size), shape, Color.color(color), float(linewidth), Color.color(linecolor), scale)

AnnotationPoint(xy::(Real,Real); z = NaN, t = NaN, size=10.0, shape::Char='x', color = RGB(1,1,1), linewidth=1.0, linecolor=color, scale::Bool=false) = AnnotationPoints{Float64,(Float64,Float64)}((float64(xy[1]), float64(xy[2])), z, t, float(size), shape, Color.color(color), float(linewidth), Color.color(linecolor), scale)

AnnotationPoint(x::Real, y::Real; args...) = AnnotationPoint((float64(x), float64(y)); args...)


type AnnotationLines{R<:Union(Real,(Real,Real)),T<:Union((R,R),Vector{(R,R)},Matrix{R})}
    lines::T
    z::Float64
    t::Float64
    linecolor::ColorValue
    linewidth::Float64
    coordinate_order::Vector{Int}

    function AnnotationLines(lines::T, z, t, linecolor, linewidth, coord_order_str)
        ord = sortperm(coord_order_str.data)
        @assert coord_order_str[ord] == "xxyy"
        new(lines,z,t,linecolor,linewidth,ord)
    end
end

AnnotationLines{R<:Real}(lines::Vector{((R,R),(R,R))}=(((Float64,Float64),(Float64,Float64)))[]; z = NaN, t = NaN, color=RGB(1,1,1), linewidth=1.0, coord_order="xyxy") = AnnotationLines{R,Vector{((R,R),(R,R))}}(lines, z, t, color, linewidth, coord_order)

AnnotationLines{R<:Real}(lines::Matrix{R}; z = NaN, t = NaN, color=RGB(1,1,1), linewidth=1.0, coord_order="xyxy") = AnnotationLines{R,Matrix{R}}(lines, z, t, color, linewidth, coord_order)

AnnotationLine{R<:Real}(line::((R,R),(R,R)); z = NaN, t = NaN, color=RGB(1,1,1), linewidth=1.0) = AnnotationLines{R,((R,R),(R,R))}(line, z, t, color, linewidth, "xyxy")
AnnotationLine(pt1::(Real,Real), pt2::(Real,Real); args...) = AnnotationLine((pt1, pt2); args...)

function AnnotationLine(c1::Real, c2::Real, c3::Real, c4::Real; coord_order="xyxy", args...)
    ord = sortperm(coord_order.data)
    @assert coord_order[ord] == "xxyy"
    (x1,x2,y1,y2) = [c1,c2,c3,c4][ord]
    AnnotationLine((float64(x1),float64(y1)),(float64(x2),float64(y2)); args...)
end

setvalid!(ann::AnchoredAnnotation, z, t) = (ann.valid = annotation_isvalid(ann.data, z, t))

annotation_isvalid(dat::Union(AnnotationText, AnnotationPoints, AnnotationLines), z, t) =
    (isnan(dat.z) || round(dat.z) == z) && (isnan(dat.t) || round(dat.t) == t)

annotation_isvalid(x, z, t) = true

function setvalid!(ann::FloatingAnnotation, z, t)
end

function draw(c::Canvas, ann::AnchoredAnnotation)
    if ann.valid
        ctx = getgc(c)
        save(ctx)
        data = ann.data
        set_coords(ctx, ann.devicebb(data), ann.userbb(data))
        scale_x = width(ann.userbb(data))/width(ann.devicebb(data))
        scale_y = height(ann.userbb(data))/height(ann.devicebb(data))
        draw_anchored(ctx, data, scale_x, scale_y)
        restore(ctx)
    end
end

function draw{T}(c::Canvas, ann::FloatingAnnotation{AnnotationScalebarFixed{T}})
    ctx = getgc(c)
    save(ctx)
    data = ann.data
    set_coords(ctx, ann.devicebb(data), BoundingBox(0,1,0,1))
    set_source(ctx, data.color)
    w, h = data.getsize(data.width, data.height)
    bb = BoundingBox(-w/2+data.centerx, w/2+data.centerx, -h/2+data.centery, h/2+data.centery)
    rectangle(ctx, bb)
    fill(ctx)
    restore(ctx)
end

function draw_anchored(ctx::CairoContext, data::AnnotationText, scale_x, scale_y)
    set_source(ctx, data.color)
    if data.scale && scale_x != 1
        fontdesc = fontdescription(data.fontfamily, data.fontoptions, iround(data.fontsize/scale_x))
    else
        fontdesc = data.fontdesc
    end
    Cairo.set_font_face(ctx, fontdesc)
    Cairo.text(ctx, data.x-0.5, data.y-0.5, data.string, halign = data.halign, valign = data.valign,
               angle = data.angle, markup = data.markup)
end

function draw_anchored(ctx::CairoContext, data::AnnotationPoints, scale_x, scale_y)
    set_line_width(ctx, data.linewidth)
    set_source(ctx, data.linecolor)
    if data.scale
        sz_x = sz_y = data.size
    else
        sz_x =  scale_x * data.size
        sz_y =  scale_y * data.size
    end
    draw_pts(ctx, data.pts, sz_x, sz_y, data.shape, data.color, data.linecolor)
end

draw_pts(ctx::CairoContext, pt::NTuple{2}, args...) = draw_pt(ctx, pt, args...)

function draw_pts{R<:Real}(ctx::CairoContext, pts::Vector{(R,R)}, args...)
    for pt in pts
        draw_pt(ctx, pt, args...)
    end
end

function draw_pts(ctx::CairoContext, pts::Matrix, args...)
    @assert size(pts,1) == 2
    for i in 1:size(pts,2)
        pt = pts[:,i]
        draw_pt(ctx, pt, args...)
    end
end


function draw_pt(ctx::CairoContext, pt, sz_x, sz_y, shape::Char, color::ColorValue, linecolor::ColorValue)
    x::Float64,y::Float64 = pt
    hsz_x = sz_x/2
    hsz_y = sz_y/2

    if (shape == '.') | (shape == 'o')
        move_to(ctx, x, y)
        if sz_x == sz_y
            new_sub_path(ctx)
            circle(ctx, x, y, sz_x)
        else
            # draw an ellipse
            save(ctx)
            translate(ctx, x, y)
            scale(ctx, sz_x, sz_y)
            new_sub_path(ctx)
            circle(ctx, 0, 0, 1);
            restore(ctx)
        end
        if shape == '.'
            set_source(ctx, color)
            fill_preserve(ctx)
            set_source(ctx, linecolor)
        end
    elseif (shape == 'x') | (shape == '*') | (shape == '+')
        if (shape == 'x') | (shape == '*')
            move_to(ctx, x-hsz_x, y-hsz_y)
            line_to(ctx, x+hsz_x, y+hsz_y)
            move_to(ctx, x-hsz_x, y+hsz_y)
            line_to(ctx, x+hsz_x, y-hsz_y)
        end
        if (shape == '+') | (shape == '*')
            move_to(ctx, x-hsz_x, y)
            line_to(ctx, x+hsz_x, y)
            move_to(ctx, x, y-hsz_y)
            line_to(ctx, x, y+hsz_y)
        end
    end

    stroke(ctx)
end

function draw_anchored(ctx::CairoContext, data::AnnotationLines, args...)
    set_line_width(ctx, data.linewidth)
    set_source(ctx, data.linecolor)
    draw_lines(ctx, data.lines, data.coordinate_order)
end

draw_lines(ctx::CairoContext, line::((Real,Real),(Real,Real)), _) = draw_line(ctx, line)

function draw_lines{R<:Real}(ctx::CairoContext, lines::Vector{((R,R),(R,R))}, _)
    for line in lines
        draw_line(ctx, line)
    end
end

function draw_lines{R<:Real}(ctx::CairoContext, lines::Matrix{R}, coordinate_order)
    for i in 1:size(lines,2)
        pt = tuple(lines[coordinate_order,i]...)
        draw_line(ctx, pt)
    end
end

function draw_lines{R<:(Real,Real)}(ctx::CairoContext, lines::Matrix{R}, _)
    for i in 1:size(lines,2)
        pt = tuple(lines[:,i]...)
        draw_line(ctx, pt)
    end
end

function draw_line(ctx::CairoContext, line::((Real,Real),(Real,Real)))
    (x1,y1),(x2,y2) = line
    move_to(ctx, x1,y1)
    line_to(ctx, x2,y2)
    stroke(ctx)
end

function draw_line(ctx::CairoContext, line::(Real,Real,Real,Real))
    x1,y1,x2,y2 = line
    move_to(ctx, x1,y1)
    line_to(ctx, x2,y2)
    stroke(ctx)
end
