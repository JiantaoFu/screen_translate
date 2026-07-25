import 'package:onnxruntime/onnxruntime.dart';

void main() async {
  OrtEnv.instance.init();
  final sessionOptions = OrtSessionOptions();
  final session = OrtSession.fromFile(
    'C:/Users/fuji2/AppData/Roaming/screen_translate/onnx_models/opus-mt-en-zh/decoder_with_past_model.onnx',
    sessionOptions,
  );
  print('Inputs:');
  for (int i = 0; i < session.inputCount; i++) {
    print('- \${session.inputNames[i]}');
  }
  print('Outputs:');
  for (int i = 0; i < session.outputCount; i++) {
    print('- \${session.outputNames[i]}');
  }
  session.release();
  sessionOptions.release();
  OrtEnv.instance.release();
}
