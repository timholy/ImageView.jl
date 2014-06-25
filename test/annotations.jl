using Images, Color
import ImageView
z = ones(10,50);
y = 8; x = 2;
z[y,x] = 0
zimg = convert(Image, z)
imgc, img2 = ImageView.view(zimg,pixelspacing=[1,1]);
# set_size(ImageView.toplevel(imgc), 200, 200)
# Change to: resize!(ImageView.toplevel(imgc), 200, 200)
idx = ImageView.annotate!(imgc, img2, ImageView.AnnotationText(x, y, "x", color=RGB(0,0,1)))
# Also test the following:
# ImageView.delete_annotation!(imgc, idx)
