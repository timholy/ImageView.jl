# ImageView.jl

An image display GUI for [Julia](http://julialang.org/).

## Installation

You'll need the `ImageView` package:

```
Pkg.add("ImageView")
```

## Preparation

First let's try it with a photograph. Load one this way:
```
using ImageView, Images
img = imread("my_photo.jpg")
```
Any typical image format should be fine, it doesn't have to be a jpg. You can also use a GUI file-picker if you omit the filename:
```
img = imread()
```
Note that the [`TestImages`](https://github.com/timholy/TestImages.jl) package contains several standard images:
```
using TestImages
img = testimage("mandrill")
```

## Demonstration of the GUI

Now display the image:
```
display(img, pixelspacing = [1,1])
```
The basic command to view the image is `display`.
The optional `pixelspacing` input tells `display` that this image has a fixed aspect ratio, and that this needs to be honored when displaying the image. (Alternatively, you could set `img["pixelspacing"] = [1,1]` and then you wouldn't have to tell this to the `display` function.)

**Note:** If you are running Julia from a script file, the julia process will terminate towards the end of the program. This will cause any windows opened with `display()` to terminate (Which is probably not what you intend). Refer to [calling display from a script file](#calling-display-from-a-script-file) section for more information on how to avoid this behavior. 

You should get a window with your image:

![photo](readme_images/photo1.jpg)

OK, nice.
But we can start to have some fun if we resize the window, which causes the image to get bigger or smaller:

![photo](readme_images/photo2.jpg)

Note the black perimeter; that's because we've specified the aspect ratio through the `pixelspacing` input, and when the window doesn't have the same aspect ratio as the image you'll have a perimeter either horizontally or vertically.
Try it without specifying `pixelspacing`, and you'll see that the image stretches to fill the window, but it looks distorted:

```
display(img)
```

![photo](readme_images/photo3.jpg)

(This won't work if you've already defined `"pixelspacing"` for `img`; if necessary, use `delete!(img, "pixelspacing")` to remove that setting.)

Next, click and drag somewhere inside the image.
You'll see the typical rubberband selection, and once you let go the image display will zoom in on the selected region. 

![photo](readme_images/photo4.jpg)
![photo](readme_images/photo5.jpg)

Again, the aspect ratio of the display is preserved.
Double-clicking on the image restores the display to full size.

If you have a wheel mouse, zoom in again and scroll the wheel, which should cause the image to pan vertically.
If you scroll while holding down Shift, it pans horizontally; hold down Ctrl and you affect the zoom setting.
Note as you zoom via the mouse, the zoom stays focused around the mouse pointer location, making it easy to zoom in on some small feature simply by pointing your mouse at it and then Ctrl-scrolling.


But wait, there's more!
You can display the image upside-down with
```
display(img, pixelspacing = [1,1], flipy=true)
```
or switch the `x` and `y` axes with
```
display(img, pixelspacing = [1,1], xy=["y","x"])
```
![photo](readme_images/photo6.jpg)
![photo](readme_images/photo7.jpg)

To experience the full functionality, you'll need a "4D  image," a movie (time sequence) of 3D images.
If you don't happen to have one lying around, you can create one via `include("test/test4d.jl")`, where `test` means the test directory in `ImageView`.
(Assuming you installed `ImageView` via the package manager, you can say `include(joinpath(Pkg.dir(), "ImageView", "test", "test4d.jl"))`.)
This creates a solid cone that changes color over time, again in the variable `img`.
Load this file, then type `display(img)`.
You should see something like this:

![GUI snapshot](readme_images/display_GUI.jpg)

The green circle is a "slice" from the cone.
At the bottom of the window you'll see a number of buttons and our current location, `z=1` and `t=1`, which correspond to the base of the cone and the beginning of the movie, respectively.
Click the upward-pointing green arrow, and you'll "pan" through the cone in the `z` dimension, making the circle smaller.
You can go back with the downward-pointing green arrow, or step frame-by-frame with the black arrows.
Next, clicking the "play forward" button moves forward in time, and you'll see the color change through gray to magenta.
The black square is a stop button. You can, of course, type a particular `z`, `t` location into the entry boxes, or grab the sliders and move them.

If you have a wheel mouse, Alt-scroll changes the time, and Ctrl-Alt-scroll changes the z-slice.

You can change the playback speed by right-clicking in an empty space within the navigation bar, which brings up a popup (context) menu:

![GUI snapshot](readme_images/popup.jpg)


<br />
<br />

By default, `display` will show you slices in the `xy`-plane.
You might want to see a different set of slices from the 4d image:
```
display(img, xy=["x","z"])
```
Initially you'll see nothing, but that's because this edge of the image is black.
Type 151 into the `y:` entry box (note its name has changed) and hit enter, or move the "y" slider into the middle of its range; now you'll see the cone from the side.

![GUI snapshot](readme_images/display_GUI2.jpg)

This GUI is also useful for "plain movies" (2d images with time), in which case the `z` controls will be omitted and it will behave largely as a typical movie-player.
Likewise, the `t` controls will be omitted for 3d images lacking a temporal component, making this a nice viewer for MRI scans.


Finally, for grayscale images, right-clicking on the image yields a brightness/contrast GUI:

![Contrast GUI snapshot](readme_images/contrast.jpg)


## Programmatic usage

`display` returns two outputs:
```
imgc, imgslice = display(img)
```
`imgc` is an `ImageCanvas`, and holds information and settings about the display. `imgslice` is useful if you're supplying multidimensional images; from it, you can infer the currently-selected frame in the GUI.

Using these outputs, you can display a new image in place of the old one:
```
display(imgc, newimg)
```
This preserves settings (like `pixelspacing`); should you want to forget everything and start fresh, do it this way:
```
display(canvas(imgc), newimg)
```
`canvas(imgc)` just returns a [Tk Canvas](https://github.com/JuliaLang/Tk.jl/tree/master/examples), so this shows you can view images inside any pre-defined `Canvas`.

Likewise, you can close the display,
```
destroy(toplevel(imgc))
```
and resize it:
```
set_size(toplevel(imgc), w, h)
```

Another nice tool is `canvasgrid`:
```
c = canvasgrid(2,2)
ops = [:pixelspacing => [1,1]]
display(c[1,1], testimage("lighthouse"); ops...)
display(c[1,2], testimage("mountainstream"); ops...)
display(c[2,1], testimage("moonsurface"); ops...)
display(c[2,2], testimage("mandrill"); ops...)
```
![canvasgrid snapshot](readme_images/canvasgrid.jpg)


## Additional notes

### Calling display from a script file

If you call Julia from a script file, the julia process will terminate towards the end of the program. This will cause any windows opened with `display()` to terminate (Which is probably not what you intend). We want to make it only terminate the process when the image window changes. Bellow is some example code to do this:

```
using Tk
using Images
using ImageView

img = imread()
imgc, imgslice = display(img);

#If we are not in a REPL
if (!isinteractive())

	# Create a condition object
    c = Condition()

    # Get the main window (A Tk toplevel object)
    win = toplevel(imgc)

    # Notify the condition object when the window closes
    bind(win, "<Destroy>", e->notify(c))

    # Wait for the notification before proceeding ... 
    wait(c)
end
```

This will stop the julia process from terminating immediately. Note that if we did not add the `bind` function, the process will keep waiting even after the image window has closed, and you will have to manually close it with `CTRL + C`.

If you are opening more than one window you may need to create more than one `Condition` object.

<br>
<br> 