
// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/cubit/main/ai/ai_search_cubit.dart';
import 'package:mysafar_sdk/src/view/tickets/ticket_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class MainVoiceSearchWidget extends StatefulWidget {
  const MainVoiceSearchWidget({super.key});

  @override
  State<MainVoiceSearchWidget> createState() => _MainVoiceSearchWidgetState();
}

class _MainVoiceSearchWidgetState extends State<MainVoiceSearchWidget> {
  final AudioRecorder _recorder = AudioRecorder();
  late AiSearchCubit _aiSearchCubit;

  bool _isRecording = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _aiSearchCubit = AiSearchCubit();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      debugPrint("🎤 Microphone permission denied");
    }
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    _filePath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _filePath!,
    );


    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();

    setState(() {
      _isRecording = false;
    });

    if (_filePath != null) {
      final file = await MultipartFile.fromFile(
        _filePath!,
        filename: 'speech.wav',
      );

      final formData = FormData.fromMap({
        'audio': file,
      });


      _aiSearchCubit.searchAiVoice(formData);

      debugPrint("✅ Audio recorded and sent: $_filePath");
    }
  }


  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
        value: _aiSearchCubit,
        child: BlocConsumer<AiSearchCubit, AiSearchState>(
        listener: (context, state) {
      switch (state) {
        case AiSearchLoadingState():
          ProjectDialogs.showAiSearchLoader(context);
          break;
        case AiSearchErrorState():
          ProjectDialogs.dismissCurrentDialog();
          showToastMessage(state.error);
          break;
        case AiSearchSuccessState():
          ProjectDialogs.dismissCurrentDialog();
          ProjectUtils.setRecommendationParams(state.body);
          Navigator.of(context).pushNamed(
              RecommendationsTicketPage.routeName,
              arguments: state.body);
          break;
        default:
          break;
      }
    },
    builder: (context, state) => Center(
      child: GestureDetector(
        onLongPressStart: (_) async {
          await _startRecording();
        },
        onLongPressEnd: (_) async {
          await _stopRecording();
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_isRecording?16:12),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6565), Color(0xFF4F5EFF)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 87, 190, 0.08),
                offset: Offset(0, 1),
                blurRadius: 8,
              ),
            ],
          ),
          child:Padding(padding:EdgeInsets.symmetric(horizontal: 8),child:  Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(
                _isRecording ? Icons.stop : Icons.mic_none_rounded,
                color:Colors.white,
                size: 28,
              ),
              Text(
                _isRecording ? "Yozib olinmoqda" : "Ovozli chat",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    ))));
  }
}
