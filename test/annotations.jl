using Images, Color
import ImageView
z = ones(10,50);
y = 8; x = 2;
z[y,x] = 0
zimg = convert(Image, z)
imgc, img2 = ImageView.view(zimg,pixelspacing=[1,1]);
# resize!(ImageView.toplevel(imgc), 200, 200)
idx = ImageView.annotate!(imgc, img2, ImageView.AnnotationText(x, y, "x", color=RGB(0,0,1), fontsize=3))
idx2 = ImageView.annotate!(imgc, img2, ImageView.AnnotationPoint(x+10, y, shape='.', size=4, color=RGB(1,0,0)))
idx3 = ImageView.annotate!(imgc, img2, ImageView.AnnotationPoint(x+20, y-6, shape='.', size=1, color=RGB(1,0,0), linecolor=RGB(0,0,0), scale=true))
idx4 = ImageView.annotate!(imgc, img2, ImageView.AnnotationLine(x+10, y, x+20, y-6, linewidth=2, color=RGB(0,1,0)))
# delete!(imgc, idx)
