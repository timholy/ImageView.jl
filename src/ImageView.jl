module ImageView

using Base.Graphics

using Color
using Gtk, Gtk.ShortNames, Gtk.GConstants
using Cairo
using Images

import Base: parent, show
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
    delete_annotation!,
    delete_annotations!,
    destroy,
    display,
#     ftshow,
#     imshow,
    parent,
    scalebar,
    toplevel

end
