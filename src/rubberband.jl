# For rubberband, we draw the selection region on the front canvas, and repair
# by copying from the back. Note that the front canvas has
#     user coordinates = device coordinates,
# so device_to_user doesn't do anything. The back canvas has
#     user coordinates = image pixel coordinates,
# so is the correct reference for anything dealing with image pixels.
type RubberBand
    pos1::Vec2
    pos2::Vec2
    moved::Bool
end

function rbdraw(r::GraphicsContext, rb::RubberBand)
    rectangle(r, rb.pos1.x, rb.pos1.y, rb.pos2.x-rb.pos1.x, rb.pos2.y-rb.pos1.y)
    set_line_width(r, 1)
    set_dash(r, [3.0,3.0], 3.0)
    set_source_rgb(r, 1, 1, 1)
    stroke_preserve(r)
    set_dash(r, [3.0,3.0], 0.0)
    set_source_rgb(r, 0, 0, 0)
    stroke_preserve(r)
end

# callback_done is executed when the user finishes drawing the rubberband.
# Its syntax is callback_done(canvas, boundingbox), where the boundingbox is
# in user coordinates.
function rubberband_start(c::Canvas, x, y, callback_done::Function)
    # Copy the surface to another buffer, so we can repaint the areas obscured by the rubberband
    r = getgc(c)
    save(r)
    reset_transform(r)
    ctxcopy = copy(r)
    rb = RubberBand(Vec2(x,y), Vec2(x,y), false)
    callbacks_old = (c.mouse.button1motion, c.mouse.button1release)
    c.mouse.button1motion = (c, event) -> rubberband_move(c, rb, event.x, event.y, ctxcopy)
    c.mouse.button1release = (c, event) -> rubberband_stop(c, rb, event.x, event.y, ctxcopy, callbacks_old, callback_done)
end

function rubberband_move(c::Canvas, rb::RubberBand, x, y, ctxcopy)
    r = getgc(c)
    if rb.moved
        # Erase the previous rubberband by copying from back surface to front
        set_source(r, ctxcopy)
        # Since the path was already created and preserved, we just modify its properties
        set_line_width(r, 2)
        set_dash(r, Float64[])
        stroke(r)
    end
    rb.moved = true
    # Draw the new rubberband
    rb.pos2 = Vec2(x, y)
    rbdraw(r, rb)
    reveal(c)
#     Tk.update()
end

function rubberband_stop(c::Canvas, rb::RubberBand, x, y, ctxcopy, callbacks_old, callback_done)
    c.mouse.button1motion = callbacks_old[1]
    c.mouse.button1release = callbacks_old[2]
    if !rb.moved
        return
    end
    r = getgc(c)
    set_source(r, ctxcopy)
    set_line_width(r, 2)
    stroke(r)
    reveal(c)
    restore(r)
#     Tk.update()
    x1, y1 = rb.pos1.x, rb.pos1.y
    if abs(x1-x) > 2 || abs(y1-y) > 2
        # It moved sufficiently, let's execute the callback
        xu, yu = device_to_user(r, x, y)
        x1u, y1u = device_to_user(r, x1, y1)
        zoombb = BoundingBox(min(x1u,xu), max(x1u,xu), min(y1u,yu), max(y1u,yu))
        callback_done(c, zoombb)
    end
end
