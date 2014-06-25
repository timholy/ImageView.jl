import ImageView
using Color
using TestImages

c = ImageView.canvasgrid(2,2)
ImageView.view(c[1,1], testimage("lighthouse"), pixelspacing=[1,1])
ImageView.view(c[1,2], testimage("mountainstream", RGB), pixelspacing=[1,1])
ImageView.view(c[2,1], testimage("moonsurface"), pixelspacing=[1,1])
ImageView.view(c[2,2], testimage("mandrill"), pixelspacing=[1,1])
