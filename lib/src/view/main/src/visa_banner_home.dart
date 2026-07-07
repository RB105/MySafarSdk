import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/visa/delivery_location_page.dart';

class VisaBannerHome extends StatelessWidget {
  const VisaBannerHome({super.key});

  static const String _visaCardAsset = "assets/img/home/visa_card.png";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DeliveryLocationPage(),
        ),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: AspectRatio(
          aspectRatio: 3.58,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.color.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bannerWidth = constraints.maxWidth;
                final bannerHeight = constraints.maxHeight;
                final leftPadding =
                    (bannerWidth * 0.046).clamp(16.0, 30.0).toDouble();
                final titleFontSize =
                    (bannerWidth * 0.047).clamp(15.0, 28.0).toDouble();
                final subtitleFontSize =
                    (bannerWidth * 0.034).clamp(12.0, 24.0).toDouble();
                final cardWidth =
                    (bannerWidth * 0.43).clamp(132.0, 252.0).toDouble();

                return Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: leftPadding,
                      top: bannerHeight * 0.2,
                      right: cardWidth * 0.78,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "visa_home_banner_title".tr(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleLarge?.copyWith(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w700,
                              height: 1.23,
                            ),
                          ),
                          SizedBox(height: bannerHeight * 0.1),
                          Text(
                            "visa_home_banner_subtitle".tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyLarge?.copyWith(
                              color: context.themeProvider.isDark
                                  ? const Color(0xFF707070)
                                  : const Color(0xFF242424),
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -bannerHeight * 0.07,
                      right: -bannerWidth * 0.04,
                      child: Image.asset(
                        _visaCardAsset,
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
