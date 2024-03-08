import 'dart:html';
import 'dart:async';
import 'dart:js' as js;

Future? _IS_INST;

Future installCodeMirror() {
  if (js.context['CodeMirror'] != null) {
    return Future.value();
  }

  _IS_INST ??= Future.sync(() async {
    var link = LinkElement()
      ..href = '/packages/codemirror/css/codemirror.css'
      ..rel = 'stylesheet';

    var script = ScriptElement()..src = '/packages/codemirror/codemirror.js';
    var script2 = ScriptElement()..src = '/packages/codemirror/mode/gfm/gfm.js';

    document.head!.children
      ..add(link)
      ..add(script)
      ..add(script2);

    await Future.wait([script.onLoad.first, script2.onLoad.first]);
  });

  return _IS_INST!;
}
