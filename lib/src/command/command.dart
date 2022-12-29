import 'dart:math';
import 'dart:typed_data';

import '../color/channel.dart';
import '../color/color.dart';
import '../color/format.dart';
import '../draw/blend_mode.dart';
import '../exif/exif_data.dart';
import '../filter/dither_image.dart';
import '../filter/noise.dart';
import '../filter/pixelate.dart';
import '../filter/quantize.dart';
import '../filter/separable_kernel.dart';
import '../font/bitmap_font.dart';
import '../formats/png_encoder.dart';
import '../image/icc_profile.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import '../image/palette.dart';
import '../transform/flip.dart';
import '../transform/trim.dart';
import '../util/internal.dart';
import '../util/point.dart';
import '../util/quantizer.dart';
import 'draw/composite_image_cmd.dart';
import 'draw/draw_char_cmd.dart';
import 'draw/draw_circle_cmd.dart';
import 'draw/draw_line_cmd.dart';
import 'draw/draw_pixel_cmd.dart';
import 'draw/draw_rect_cmd.dart';
import 'draw/draw_string_cmd.dart';
import 'draw/fill_circle_cmd.dart';
import 'draw/fill_cmd.dart';
import 'draw/fill_flood_cmd.dart';
import 'draw/fill_rect_cmd.dart';
import 'executor.dart';
import 'filter/adjust_color_cmd.dart';
import 'filter/billboard_cmd.dart';
import 'filter/bleach_bypass_cmd.dart';
import 'filter/bulge_distortion_cmd.dart';
import 'filter/bump_to_normal_cmd.dart';
import 'filter/chromatic_aberration_cmd.dart';
import 'filter/color_halftone_cmd.dart';
import 'filter/color_offset_cmd.dart';
import 'filter/contrast_cmd.dart';
import 'filter/convolution_cmd.dart';
import 'filter/dither_image_cmd.dart';
import 'filter/dot_screen_cmd.dart';
import 'filter/drop_shadow_cmd.dart';
import 'filter/edge_glow_cmd.dart';
import 'filter/emboss_cmd.dart';
import 'filter/filter_cmd.dart';
import 'filter/gamma_cmd.dart';
import 'filter/gaussian_blur_cmd.dart';
import 'filter/grayscale_cmd.dart';
import 'filter/hdr_to_ldr_cmd.dart';
import 'filter/hexagon_pixelate_cmd.dart';
import 'filter/image_mask_cmd.dart';
import 'filter/invert_cmd.dart';
import 'filter/luminance_threshold_cmd.dart';
import 'filter/monochrome_cmd.dart';
import 'filter/noise_cmd.dart';
import 'filter/normalize_cmd.dart';
import 'filter/pixelate_cmd.dart';
import 'filter/quantize_cmd.dart';
import 'filter/reinhard_tonemap_cmd.dart';
import 'filter/remap_colors_cmd.dart';
import 'filter/scale_rgba_cmd.dart';
import 'filter/separable_convolution_cmd.dart';
import 'filter/sepia_cmd.dart';
import 'filter/sketch_cmd.dart';
import 'filter/smooth_cmd.dart';
import 'filter/sobel_cmd.dart';
import 'filter/stretch_distortion_cmd.dart';
import 'filter/vignette_cmd.dart';
import 'formats/bmp_cmd.dart';
import 'formats/cur_cmd.dart';
import 'formats/decode_image_cmd.dart';
import 'formats/decode_image_file_cmd.dart';
import 'formats/decode_named_image_cmd.dart';
import 'formats/exr_cmd.dart';
import 'formats/gif_cmd.dart';
import 'formats/ico_cmd.dart';
import 'formats/jpg_cmd.dart';
import 'formats/png_cmd.dart';
import 'formats/psd_cmd.dart';
import 'formats/pvr_cmd.dart';
import 'formats/tga_cmd.dart';
import 'formats/tiff_cmd.dart';
import 'formats/webp_cmd.dart';
import 'formats/write_to_file_cmd.dart';
import 'image/add_frames_cmd.dart';
import 'image/convert_cmd.dart';
import 'image/copy_image_cmd.dart';
import 'image/create_image_cmd.dart';
import 'image/image_cmd.dart';
import 'transform/bake_orientation_cmd.dart';
import 'transform/copy_crop_circle_cmd.dart';
import 'transform/copy_crop_cmd.dart';
import 'transform/copy_flip_cmd.dart';
import 'transform/copy_rectify_cmd.dart';
import 'transform/copy_resize_cmd.dart';
import 'transform/copy_resize_crop_square_cmd.dart';
import 'transform/copy_rotate_cmd.dart';
import 'transform/flip_cmd.dart';
import 'transform/trim_cmd.dart';

/// Base class for commands that create, load, manipulate, and save images.
/// Commands are not executed until either the [execute] or [executeThread]
/// methods are called.
class Command {
  Command? input;
  Command? firstSubCommand;
  Command? _subCommand;
  bool dirty = true;
  /// Output Image generated by the command.
  Image? outputImage;
  /// Output bytes generated by the command.
  Uint8List? outputBytes;
  Object? outputObject;

  Command([this.input = null]);

  // image

  /// Use a specific Image.
  void image(Image image) {
    subCommand = ImageCmd(subCommand, image);
  }

  /// Create an Image.
  void createImage({ required int width, required int height,
        Format format = Format.uint8, int numChannels = 3,
        bool withPalette = false,
        Format paletteFormat = Format.uint8,
        Palette? palette, ExifData? exif,
        IccProfile? iccp, Map<String, String>? textData }) {
    subCommand = CreateImageCmd(subCommand, width: width, height: height,
        format: format, numChannels: numChannels, withPalette: withPalette,
        paletteFormat: paletteFormat, palette: palette, exif: exif,
        iccp: iccp, textData: textData);
  }

  void convert({ int? numChannels, Format? format }) {
    subCommand = ConvertCmd(subCommand, numChannels: numChannels,
        format: format);
  }

  void copy() {
    subCommand = CopyImageCmd(subCommand);
  }

  void addFrames(int count, AddFramesCallback callback) {
    subCommand = AddFramesCmd(subCommand, count, callback);
  }

  // formats
  void decodeImage(Uint8List data) {
    subCommand = DecodeImageCmd(subCommand, data);
  }

  void decodeNamedImage(String path, Uint8List data) {
    subCommand = DecodeNamedImageCmd(subCommand, path, data);
  }

  void decodeImageFile(String path) {
    subCommand = DecodeImageFileCmd(subCommand, path);
  }

  void writeToFile(String path) {
    subCommand = WriteToFileCmd(subCommand, path);
  }

  // Bmp
  void decodeBmp(Uint8List data) {
    subCommand = DecodeBmpCmd(subCommand, data);
  }

  void decodeBmpFile(String path) {
    subCommand = DecodeBmpFileCmd(subCommand, path);
  }

  void encodeBmp() {
    subCommand = EncodeBmpCmd(subCommand);
  }

  void encodeBmpFile(String path) {
    subCommand = EncodeBmpFileCmd(subCommand, path);
  }

  // Cur
  void encodeCur() {
    subCommand = EncodeCurCmd(subCommand);
  }

  void encodeCurFile(String path) {
    subCommand = EncodeCurFileCmd(subCommand, path);
  }

  // Exr
  void decodeExr(Uint8List data) {
    subCommand = DecodeExrCmd(subCommand, data);
  }

  void decodeExrFile(String path) {
    subCommand = DecodeExrFileCmd(subCommand, path);
  }

  // Gif
  void decodeGif(Uint8List data) {
    subCommand = DecodeGifCmd(subCommand, data);
  }

  void decodeGifFile(String path) {
    subCommand = DecodeGifFileCmd(subCommand, path);
  }

  void encodeGif({ int samplingFactor = 10,
      DitherKernel dither = DitherKernel.floydSteinberg,
      bool ditherSerpentine = false }) {
    subCommand = EncodeGifCmd(subCommand, samplingFactor: samplingFactor,
        dither: dither, ditherSerpentine: ditherSerpentine);
  }

  void encodeGifFile(String path, { int samplingFactor = 10,
      DitherKernel dither = DitherKernel.floydSteinberg,
      bool ditherSerpentine = false }) {
    subCommand = EncodeGifFileCmd(subCommand, path,
        samplingFactor: samplingFactor, dither: dither,
        ditherSerpentine: ditherSerpentine);
  }

  // Ico
  void decodeIco(Uint8List data) {
    subCommand = DecodeIcoCmd(subCommand, data);
  }

  void decodeIcoFile(String path) {
    subCommand = DecodeIcoFileCmd(subCommand, path);
  }

  void encodeIco() {
    subCommand = EncodeIcoCmd(subCommand);
  }

  void encodeIcoFile(String path) {
    subCommand = EncodeIcoFileCmd(subCommand, path);
  }

  // Jpeg
  void decodeJpg(Uint8List data) {
    subCommand = DecodeJpgCmd(subCommand, data);
  }

  void decodeJpgFile(String path) {
    subCommand = DecodeJpgFileCmd(subCommand, path);
  }

  void encodeJpg({ int quality = 100 }) {
    subCommand = EncodeJpgCmd(subCommand, quality: quality);
  }

  void encodeJpgFile(String path, { int quality = 100 }) {
    subCommand = EncodeJpgFileCmd(subCommand, path, quality: quality);
  }

  // Png
  void decodePng(Uint8List data) {
    subCommand = DecodePngCmd(subCommand, data);
  }

  void decodePngFile(String path) {
    subCommand = DecodePngFileCmd(subCommand, path);
  }

  void encodePng({ int level = 6, PngFilter filter = PngFilter.paeth }) {
    subCommand = EncodePngCmd(subCommand, level: level, filter: filter);
  }

  void encodePngFile(String path, { int level = 6,
      PngFilter filter = PngFilter.paeth }) {
    subCommand = EncodePngFileCmd(subCommand, path, level: level,
        filter: filter);
  }

  // Psd
  void decodePsd(Uint8List data) {
    subCommand = DecodePsdCmd(subCommand, data);
  }

  void decodePsdFile(String path) {
    subCommand = DecodePsdFileCmd(subCommand, path);
  }

  // Pvr
  void decodePvr(Uint8List data) {
    subCommand = DecodePvrCmd(subCommand, data);
  }

  void decodePvrFile(String path) {
    subCommand = DecodePvrFileCmd(subCommand, path);
  }

  void encodePvr() {
    subCommand = EncodePvrCmd(subCommand);
  }

  void encodePvrFile(String path) {
    subCommand = EncodePvrFileCmd(subCommand, path);
  }

  // Tga
  void decodeTga(Uint8List data) {
    subCommand = DecodeTgaCmd(subCommand, data);
  }

  void decodeTgaFile(String path) {
    subCommand = DecodeTgaFileCmd(subCommand, path);
  }

  void encodeTga() {
    subCommand = EncodeTgaCmd(subCommand);
  }

  void encodeTgaFile(String path) {
    subCommand = EncodeTgaFileCmd(subCommand, path);
  }

  // Tiff
  void decodeTiff(Uint8List data) {
    subCommand = DecodeTiffCmd(subCommand, data);
  }

  void decodeTiffFile(String path) {
    subCommand = DecodeTiffFileCmd(subCommand, path);
  }

  void encodeTiff() {
    subCommand = EncodeTiffCmd(subCommand);
  }

  void encodeTiffFile(String path) {
    subCommand = EncodeTiffFileCmd(subCommand, path);
  }

  // WebP
  void decodeWebP(Uint8List data) {
    subCommand = DecodeWebPCmd(subCommand, data);
  }

  void decodeWebPFile(String path) {
    subCommand = DecodeWebPFileCmd(subCommand, path);
  }


  // draw
  void drawChar(BitmapFont font, int x, int y,
      String char, { Color? color }) {
    subCommand = DrawCharCmd(subCommand, font, x, y, char,
        color: color);
  }

  void drawCircle(int x, int y, int radius, Color color) {
    subCommand = DrawCircleCmd(subCommand, x, y, radius, color);
  }

  void compositeImage(Command? src, { int? dstX, int? dstY, int? dstW,
      int? dstH, int? srcX, int? srcY, int? srcW, int? srcH,
      BlendMode blend = BlendMode.alpha, bool center = false }) {
    subCommand = CompositeImageCmd(subCommand, src, dstX: dstX, dstY: dstY,
        dstW: dstW, dstH: dstH, srcX: srcX, srcY: srcY, srcW: srcW, srcH: srcH,
        blend: blend, center: center);
  }

  void drawLine(int x1, int y1, int x2, int y2, Color c,
      { bool antialias = false, num thickness = 1 }) {
    subCommand = DrawLineCmd(subCommand, x1, y1, x2, y2, c,
        antialias: antialias, thickness: thickness);
  }

  void drawPixel(int x, int y, Color color) {
    subCommand = DrawPixelCmd(subCommand, x, y, color);
  }

  void drawRect(int x1, int y1, int x2, int y2, Color c,
      { num thickness = 1 }) {
    subCommand = DrawRectCmd(subCommand, x1, y1, x2, y2, c,
        thickness: thickness);
  }

  void drawString(BitmapFont font, int x, int y,
      String char, { Color? color }) {
    subCommand = DrawStringCmd(subCommand, font, x, y, char,
        color: color);
  }

  void fill(Color color) {
    subCommand = FillCmd(subCommand, color);
  }

  void fillCircle(int x, int y, int radius, Color color) {
    subCommand = FillCircleCmd(subCommand, x, y, radius, color);
  }

  void fillFlood(int x, int y, Color color,
      { num threshold = 0.0, bool compareAlpha = false }) {
    subCommand = FillFloodCmd(subCommand, x, y, color, threshold: threshold,
        compareAlpha: compareAlpha);
  }

  void fillRect(int x1, int y1, int x2, int y2, Color c) {
    subCommand = FillRectCmd(subCommand, x1, y1, x2, y2, c);
  }

  // filter

  void adjustColor({ Color? blacks, Color? whites, Color? mids,
        num? contrast, num? saturation, num? brightness,
        num? gamma, num? exposure, num? hue, num? amount }) {
    subCommand = AdjustColorCmd(subCommand, blacks: blacks, whites: whites,
        mids: mids, contrast: contrast, saturation: saturation,
        brightness: brightness, gamma: gamma, exposure: exposure,
        hue: hue, amount: amount);
  }

  void billboard({ num grid = 10, num amount = 1 }) {
    subCommand = BillboardCmd(subCommand, grid: grid, amount: amount);
  }

  void bleachBypass({ num amount = 1}) {
    subCommand = BleachBypassCmd(subCommand, amount: amount);
  }

  void bulgeDistortion({ int? centerX, int? centerY,
      num? radius, num scale = 0.5,
      Interpolation interpolation = Interpolation.nearest }) {
    subCommand = BulgeDistortionCmd(subCommand, centerX: centerX,
        centerY: centerY, radius: radius, scale: scale,
        interpolation: interpolation);
  }

  void bumpToNormal({ num strength = 2.0 }) {
    subCommand = BumpToNormalCmd(subCommand, strength: strength);
  }

  void chromaticAberration({ int shift = 5 }) {
    subCommand = ChromaticAberrationCmd(subCommand, shift: shift);
  }

  void colorHalftone({ num amount = 1, int? centerX, int? centerY,
      num angle = 180, num size = 5 }) {
    subCommand = ColorHalftoneCmd(subCommand, amount: amount,
        centerX: centerX, centerY: centerY, angle: angle, size: size);
  }

  void colorOffset({ num red = 0, num green = 0, num blue = 0,
      num alpha = 0 }) {
    subCommand = ColorOffsetCmd(subCommand, red: red, green: green, blue: blue,
        alpha: alpha);
  }

  void contrast(num c) {
    subCommand = ContrastCmd(subCommand, contrast: c);
  }

  void convolution(List<num> filter, { num div = 1.0, num offset = 0.0,
      num amount = 1 }) {
    subCommand = ConvolutionCmd(subCommand, filter, div: div, offset: offset,
        amount: amount);
  }

  void ditherImage({ Quantizer? quantizer,
    DitherKernel kernel = DitherKernel.floydSteinberg,
    bool serpentine = false }) {
    subCommand = DitherImageCmd(subCommand, quantizer: quantizer,
        kernel: kernel, serpentine: serpentine);
  }

  void dotScreen({ num angle = 180, num size = 5.75, int? centerX,
        int? centerY, num amount = 1 }) {
    subCommand = DotScreenCmd(subCommand, angle: angle, size: size,
        centerX: centerX, centerY: centerY, amount: amount);
  }

  void dropShadow(int hShadow, int vShadow, int blur, { Color? shadowColor }) {
    subCommand = DropShadowCmd(subCommand, hShadow, vShadow, blur,
        shadowColor: shadowColor);
  }

  void edgeGlow({ num amount = 1 }) {
    subCommand = EdgeGlowCmd(subCommand, amount: amount);
  }

  void emboss({ num amount = 1 }) {
    subCommand = EmbossCmd(subCommand, amount: amount);
  }

  void gamma({ num gamma = 2.2 }) {
    subCommand = GammaCmd(subCommand, gamma: gamma);
  }

  void gaussianBlur(int radius) {
    subCommand = GaussianBlurCmd(subCommand, radius);
  }

  void grayscale({ num amount = 1 }) {
    subCommand = GrayscaleCmd(subCommand, amount: amount);
  }

  void hdrToLdr({ num? exposure }) {
    subCommand = HdrToLdrCmd(subCommand, exposure: exposure);
  }

  void hexagonPixelate({ int? centerX, int? centerY, int size = 5,
      num amount = 1 }) {
    subCommand = HexagonPixelateCmd(subCommand, centerX: centerX,
        centerY: centerY, size: size, amount: amount);
  }

  void invert() {
    subCommand = InvertCmd(subCommand);
  }

  void luminanceThreshold({ num threshold = 0.5, bool outputColor = false,
      num amount = 1 }) {
    subCommand = LuminanceThresholdCmd(subCommand, threshold: threshold,
        outputColor: outputColor, amount: amount);
  }

  void imageMask(Command? mask, { Channel maskChannel = Channel.luminance,
      bool scaleMask = false }) {
    subCommand = ImageMaskCmd(subCommand, mask, maskChannel: maskChannel,
        scaleMask: scaleMask);
  }

  void monochrome({ Color? color, num amount = 1 }) {
    subCommand = MonochromeCmd(subCommand, color: color, amount: amount);
  }

  void noise(num sigma, { NoiseType type = NoiseType.gaussian,
      Random? random }) {
    subCommand = NoiseCmd(subCommand, sigma, type: type, random: random);
  }

  void normalize(num minValue, num maxValue) {
    subCommand = NormalizeCmd(subCommand, minValue, maxValue);
  }

  void pixelate(int blockSize, { PixelateMode mode = PixelateMode.upperLeft }) {
    subCommand = PixelateCmd(subCommand, blockSize, mode: mode);
  }

  void quantize({ int numberOfColors = 256,
        QuantizeMethod method = QuantizeMethod.neuralNet,
        DitherKernel dither = DitherKernel.none,
        bool ditherSerpentine = false }) {
    subCommand = QuantizeCmd(subCommand, numberOfColors: numberOfColors,
        method: method, dither: dither, ditherSerpentine: ditherSerpentine);
  }

  void reinhardTonemap() {
    subCommand = ReinhardTonemapCmd(subCommand);
  }

  void remapColors({ Channel red = Channel.red,
        Channel green = Channel.green,
        Channel blue = Channel.blue,
        Channel alpha = Channel.alpha }) {
    subCommand = RemapColorsCmd(subCommand, red: red, green: green, blue: blue,
        alpha: alpha);
  }

  void scaleRgba(Color s) {
    subCommand = ScaleRgbaCmd(subCommand, s);
  }

  void separableConvolution(SeparableKernel kernel) {
    subCommand = SeparableConvolutionCmd(subCommand, kernel);
  }

  void sepia({ num amount = 1 }) {
    subCommand = SepiaCmd(subCommand, amount: amount);
  }

  void sketch({ num amount = 1 }) {
    subCommand = SketchCmd(subCommand, amount: amount);
  }

  void smooth(num weight) {
    subCommand = SmoothCmd(subCommand, weight);
  }

  void sobel({ num amount = 1 }) {
    subCommand = SobelCmd(subCommand, amount: amount);
  }

  void stretchDistortion({ int? centerX, int? centerY,
    Interpolation interpolation = Interpolation.nearest }) {
    subCommand = StretchDistortionCmd(subCommand, centerX: centerX,
        centerY: centerY, interpolation: interpolation);
  }

  void vignette({ num start = 0.3, num end = 0.75, Color? color,
      num amount = 0.8 }) {
    subCommand = VignetteCmd(subCommand, start: start, end: end,
        color: color, amount: amount);
  }

  /// Run an arbitrary function on the image within the Command graph.
  /// A FilterFunction is in the `form Image function(Image)`. A new Image
  /// can be returned, replacing the given Image; or the given Image can be
  /// returned.
  ///
  /// @example
  /// final image = Command()
  /// ..createImage(width: 256, height: 256)
  /// ..filter((image) {
  ///   for (final pixel in image) {
  ///     pixel.r = pixel.x;
  ///     pixel.g = pixel.y;
  ///   }
  ///   return image;
  /// })
  /// ..getImage();
  void filter(FilterFunction filter) {
    subCommand = FilterCmd(subCommand, filter);
  }

  // transform
  void bakeOrientation() {
    subCommand = BakeOrientationCmd(subCommand);
  }

  void copyCropCircle({ int? radius, int? centerX, int? centerY }) {
    subCommand = CopyCropCircleCmd(subCommand, radius: radius, centerX: centerX,
        centerY: centerY);
  }

  void copyCrop(int x, int y, int w, int h) {
    subCommand = CopyCropCmd(subCommand, x, y, w, h);
  }

  void copyFlip(FlipDirection direction) {
    subCommand = CopyFlipCmd(subCommand, direction);
  }

  void copyRectify({ required Point topLeft,
      required Point topRight,
      required Point bottomLeft,
      required Point bottomRight,
      Interpolation interpolation = Interpolation.nearest }) {
    subCommand = CopyRectifyCmd(subCommand, topLeft, topRight,
        bottomLeft, bottomRight, interpolation);
  }

  void copyResize({ int? width, int? height,
    Interpolation interpolation = Interpolation.nearest }) {
    subCommand = CopyResizeCmd(subCommand, width: width, height: height,
        interpolation: interpolation);
  }

  void copyResizeCropSquare(int size,
      { Interpolation interpolation = Interpolation.nearest }) {
    subCommand = CopyResizeCropSquareCmd(subCommand, size,
        interpolation: interpolation);
  }

  void copyRotate(num angle,
      { Interpolation interpolation = Interpolation.nearest }) {
    subCommand = CopyRotateCmd(subCommand, angle, interpolation: interpolation);
  }

  void flip(FlipDirection direction) {
    subCommand = FlipCmd(subCommand, direction);
  }

  void trim({ TrimMode mode = TrimMode.transparent, Trim sides = Trim.all }) {
    subCommand = TrimCmd(subCommand, mode: mode, sides: sides);
  }

  //

  Future<Command> execute() async {
    await subCommand.executeIfDirty();
    if (_subCommand != null) {
      outputImage = _subCommand!.outputImage;
      outputBytes = _subCommand!.outputBytes;
      outputObject = _subCommand!.outputObject;
    }
    return this;
  }

  Future<Command> executeThread() async {
    final cmdOrThis = subCommand;
    if (cmdOrThis.dirty) {
      await executeCommandAsync(cmdOrThis).then((value) {
        cmdOrThis
          ..dirty = false
          ..outputImage = value.image
          ..outputBytes = value.bytes
          ..outputObject = value.object;
        if (_subCommand != null) {
          outputImage = _subCommand!.outputImage;
          outputBytes = _subCommand!.outputBytes;
          outputObject = _subCommand!.outputObject;
        }
      });
    }
    return this;
  }

  Future<Image?> getImage() async {
    await execute();
    return subCommand.outputImage;
  }

  Future<Image?> getImageThread() async {
    await executeThread();
    return outputImage;
  }

  Future<Uint8List?> getBytes() async {
    await execute();
    return outputBytes;
  }

  Future<Uint8List?> getBytesThread() async {
    await executeThread();
    return outputBytes;
  }

  @internal
  Future<void> executeIfDirty() async {
    if (dirty) {
      dirty = false;
      await executeCommand();
    }
  }

  @internal
  Future<void> executeCommand() async { }

  @internal
  Command get subCommand => _subCommand ?? this;

  @internal
  set subCommand(Command? cmd) {
    _subCommand = cmd;
    firstSubCommand ??= cmd;
  }

  void setDirty() {
    dirty = true;
    var cmd = _subCommand;
    while (cmd != null) {
      cmd.dirty = true;
      cmd = cmd.input;
    }
  }
}
