import 'dart:async';
import 'dart:html';

import 'package:codemirror/codemirror.dart';

import '../component.dart';

class CodeMirrorValueComponent extends ValueComponent<String?> {
  @override
  Iterable<String> get rootClasses => ['CodeMirrorValueComponent'];

  CodeMirror? editor;

  @override
  String get template => '''
<div>
  <div id="textarea-container">
    <textarea></textarea>
  </div>
</div>
  ''';

  CodeMirrorValueComponent(Value<String?> value,
      {bool lineNumbers = false,
      bool lineWrapping = true,
      String mode = 'markdown'})
      : super(value) {
    var options = {
      'mode': mode,
      'lineNumbers': lineNumbers,
      'lineWrapping': lineWrapping
    };

    editor = CodeMirror.fromTextArea(selector<TextAreaElement>('textarea'),
        options: options);

    addSubscription(
        editor,
        editor!.onChange.listen((evt) {
          value.value = editor!.doc.getValue();
        }));

    drawValue(value.value);

    Timer.run(() => editor!.refresh());
  }

  @override
  drawValue(String? innerValue) {
    var editor = this.editor;
    if (editor != null) {
      selector('textarea').text = innerValue.toString();
      if (editor.doc.getValue() != innerValue) {
        editor.doc.setValue(innerValue.toString());
      }
    }
  }
}
