import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OfertaPage extends StatefulWidget {
  const OfertaPage({super.key});

  static const String routeName = "/oferta";
  static const String _ofertaUrl = "https://mysafar.uz/en/oferta-autopay";

  @override
  State<OfertaPage> createState() => _OfertaPageState();
}

class _OfertaPageState extends State<OfertaPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ScrollNotifier',
        onMessageReceived: (msg) {
          if (msg.message == 'end' && !_reachedEnd && mounted) {
            setState(() => _reachedEnd = true);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
            _injectScrollListener();
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(OfertaPage._ofertaUrl));
  }

  Future<void> _injectScrollListener() async {
    const js = '''
      (function() {
        function check() {
          var scrollTop = window.pageYOffset || document.documentElement.scrollTop;
          var viewport = window.innerHeight;
          var fullHeight = Math.max(
            document.body.scrollHeight,
            document.documentElement.scrollHeight
          );
          if (scrollTop + viewport >= fullHeight - 80) {
            ScrollNotifier.postMessage('end');
          }
        }
        window.addEventListener('scroll', check, { passive: true });
        window.addEventListener('resize', check, { passive: true });
        setTimeout(check, 400);
      })();
    ''';
    try {
      await _controller.runJavaScript(js);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text("offer_title".tr()),
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size(double.infinity, 3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _controller)),
          if (!_reachedEnd && !_loading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: ProjectTheme.warning.withAlpha(28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: ProjectTheme.warning, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "scroll_to_end_hint".tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: ProjectTheme.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
        child: _AcknowledgeButton(
          enabled: _reachedEnd,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ),
    );
  }
}

class _AcknowledgeButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _AcknowledgeButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: enabled
                  ? LinearGradient(
                      colors: [ProjectTheme.brandColor, ProjectTheme.blueBg],
                    )
                  : null,
              color: enabled ? null : ProjectTheme.brandColor.withAlpha(40),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (enabled) ...[
                    const Icon(Icons.check_circle_outline_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    "i_have_read".tr(),
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
