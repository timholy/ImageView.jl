module ImageView

using Base.Graphics

using Color
using Gtk, Gtk.ShortNames, Gtk.GConstants
using Cairo
using Images

import Base: parent, show, delete!, empty!
import Base.Graphics: width, height, fill, set_coords
import Gtk: toplevel, draw

# include("config.jl")
# include("external.jl")
include("rubberband.jl")
include("annotations.jl")
include("navigation.jl")
include("contrast.jl")
include("display.jl")

export # types
    AnnotationText,
    AnnotationScalebarFixed,
    # display functions
    annotate!,
    canvas,
    canvasgrid,
    delete_annotations!,
    destroy,
#     ftshow,
#     imshow,
    parent,
    scalebar,
    toplevel,
    view,
    write_to_png

@deprecate delete_annotations! empty!
@deprecate delete_annotation! delete!
@deprecate display(c::Canvas, img::AbstractArray; proplist...) view(c, img; proplist...)
@deprecate display(imgc::ImageCanvas, img::AbstractArray; proplist...) view(imgc, img; proplist...)
@deprecate display(img::AbstractArray; proplist...) view(img; proplist...)

end
