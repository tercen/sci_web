part of sci_component;

abstract class ValueComponent<T> extends Component {
  Value<T> model;

  ValueComponent(this.model, {List<String>? cssClasses})
      : super(cssClasses: cssClasses) {
    if (model is NamedValue<T>) {
      var name = (model as NamedValue<T>).name;
      if (name.isNotEmpty) {
        root.classes.add(name.replaceAll('.', '-'));
      }
    }

    addSubscription(model, model.onChange.listen(onChange));
    onChange(model.value);
  }

  void onChange(T innerValue) {
    drawValue(innerValue);
  }

  drawValue(T innerValue) {}

  @override
  Future release() async {
    return subscriptionKeys
        .whereType<Value<T>>()
        .firstWhereOrNull((k) => true)
        ?.release();
  }
}

class KeyValueComponent extends ValueComponent {
  @override
  Iterable<String> get rootClasses => ['KeyValueComponent'];

  KeyValueComponent(dynamic key, dynamic value,
      {String separator = ':', List<String>? cssClasses})
      : super(value is Value ? value : ValueHolder(value),
            cssClasses: cssClasses) {
    addToRoot(TextComponent(key, cssClasses: ['key']));
    addToRoot(TextComponent(separator, cssClasses: ['sep']));
    addToRoot(TextComponent(value, cssClasses: ['value']));
  }
}

class TextComponent extends ValueComponent {
  @override
  Iterable<String> get rootClasses => ['TextComponent'];
  @override
  String get template => '''<span></span>''';

  String? defaultValue = '';

  TextComponent(dynamic value, {this.defaultValue, List<String>? cssClasses})
      : super(value is Value ? value : ValueHolder(value),
            cssClasses: cssClasses);

  @override
  drawValue(innerValue) {
    if (innerValue.toString().trim().isEmpty) {
      root.text = defaultValue;
      root.classes.add('default-value');
    } else {
      root.classes.remove('default-value');
      root.text = innerValue.toString();
    }
  }
}

class ReadOnlyTextComponent extends Component {
  @override
  Iterable<String> get rootClasses => ['TextComponent'];
  @override
  String get template => '''<span></span>''';

  ReadOnlyTextComponent(String value, {List<String>? cssClasses})
      : super(cssClasses: cssClasses) {
    root.text = value;
  }
}

class LabelComponent extends TextComponent {
  @override
  String get template => '''<label></label>''';
  LabelComponent(super.value);
}

class CheckBoxComponent extends InputTextComponent {
  @override
  Iterable<String> get rootClasses => ['CheckBoxComponent'];
  CheckBoxComponent(Value<bool> value,
      {List<String>? cssClasses, String? placeholder})
      : super(value, type: 'checkbox', cssClasses: cssClasses);
}

class InputBtnComponent extends ValueComponent {
  @override
  Iterable<String> get rootClasses => ['InputBtnComponent'];

  @override
  String get template => '''<input type="button"></input>''';

  InputBtnComponent(Value<String> value) : super(value) {
    var input = root as ButtonInputElement;
    input.value = value.value;
  }

  @override
  drawValue(innerValue) {
    (root as ButtonInputElement).value = innerValue.toString();
  }
}

class InputTextComponent extends ValueComponent {
  @override
  Iterable<String> get rootClasses => ['InputTextComponent'];
  @override
  String get template => '''<input></input>''';
  InputTextComponent(Value value,
      {String type = 'text', List<String>? cssClasses, String placeholder = ''})
      : super(value, cssClasses: cssClasses) {
    var input = root as InputElement;
    input
      ..type = type
      ..placeholder = placeholder;

    addSubscription(input, input.onKeyUp.listen((evt) {
      try {
        triggerEvent(ComponentEvent.fromData(this, {'key': evt.key}));
        value.value = input.value;
      } on FormatException catch (e) {
        input.value = value.value.toString();
        triggerEvent(ComponentEvent.fromData(this, {'FormatException': e}));
      }
    }));
  }

  @override
  drawValue(innerValue) {
    (root as InputElement).value = innerValue.toString();
  }

  int? get selectionStart => (root as InputElement).selectionStart;
  int? get selectionEnd => (root as InputElement).selectionEnd;

  set selectionStart(int? i) => (root as InputElement).selectionStart = i;
  set selectionEnd(int? i) => (root as InputElement).selectionEnd = i;
}

class ButtonComponent extends ValueComponent {
  @override
  String get template =>
      '''<button type="submit" class="btn btn-default"></button>''';

  ButtonComponent(dynamic value, {List<String>? cssClasses})
      : super(value is Value ? value : ValueHolder(value),
            cssClasses: cssClasses);

  @override
  drawValue(innerValue) {
    (root as ButtonElement).text = innerValue.toString();
  }
}

class IconComponent extends ValueComponent<List<String>> {
  @override
  Iterable<String> get rootClasses => ['IconComponent'];
  @override
  String get template => '''<i></i>''';

  List<String> _currentCss;

  factory IconComponent.css(String value) {
    return IconComponent(ValueHolder([value]));
  }

  factory IconComponent.add() {
    return IconComponent(ValueHolder(['icon-add']));
  }

  factory IconComponent.minus() {
    return IconComponent(ValueHolder(['icon-minus']));
  }

  IconComponent(super.model) : _currentCss = model.value;

  @override
  drawValue(List<String> innerValue) {
    for (var css in _currentCss) {
      root.classes.remove(css);
    }

    _currentCss = innerValue;
    for (var css in _currentCss) {
      root.classes.add(css);
    }
  }
}

class ImageComponent extends ValueComponent {
  @override
  Iterable<String> get rootClasses => ['ImageComponent'];
  @override
  String get template => '''<img></img>''';

  ImageComponent(dynamic value)
      : super(value is Value ? value : ValueHolder(value));

  @override
  drawValue(innerValue) {
    (root as ImageElement).src = innerValue.toString();
  }
}

class AnchorComponent extends ValueComponent {
  @override
  Iterable<String> get rootClasses => ['AnchorComponent'];
  @override
  String get template => '''<a></a>''';

  AnchorComponent(dynamic value,
      {String? href,
      List<String>? cssClasses,
      String? target,
      int? tabindex,
      void Function(MouseEvent)? onClick})
      : super(value is Value ? value : ValueHolder(value.toString()),
            cssClasses: cssClasses) {
    if (href != null) {
      this.href = href;
    }

    if (target != null) {
      this.target = target;
    }

    if (tabindex != null) {
      root.setAttribute('tabindex', tabindex.toString());
    }

    if (onClick != null) {
      addSubscription('', root.onClick.listen(onClick));
    }
  }

  @override
  drawValue(innerValue) {
    root.text = innerValue.toString();
  }

  set href(String url) {
    (root as AnchorElement).href = url;
  }

  set target(String target) {
    (root as AnchorElement).target = target;
  }
}

// class EditMarkDownValueComponent extends ValueComponent {
//   @override
//   Iterable<String> get rootClasses => ['EditMarkDownValueComponent'];
//
//   EditMarkDownValueComponent(Value value,
//       {bool lineNumbers = false, bool lineWrapping = true})
//       : super(value) {
//     lazy_install_codemirror.installCodeMirror().whenComplete(() {
//       lazycodemirror.loadLibrary().whenComplete(() {
//         var _comp = lazycodemirror.CodeMirrorValueComponent(value,
//             lineNumbers: lineNumbers, lineWrapping: lineWrapping);
//         addToRoot(_comp, propagateEvents: true);
//       });
//     });
//   }
//
//
// }

class EditMarkDownValueComponent extends ValueComponent<String?> {
  @override
  Iterable<String> get rootClasses => ['EditMarkDownValueComponent'];
  bool lineNumbers;
  bool lineWrapping;
  String mode;

  EditMarkDownValueComponent(Value<String?> value,
      {this.lineNumbers = false,
      this.lineWrapping = true,
      this.mode = 'markdown'})
      : super(value) {
    asyncInvalidate();
  }

  @override
  Future asyncDraw([dynamic evt]) async {
    await lazy_install_codemirror.installCodeMirror();
    await lazy_code_mirror.loadLibrary();
    var _comp = lazy_code_mirror.CodeMirrorValueComponent(model,
        lineNumbers: lineNumbers, lineWrapping: lineWrapping, mode: mode);
    addToRoot(_comp, propagateEvents: true);
  }
}

class MarkDownValueComponent extends ValueComponent<String?> {
  @override
  Iterable<String> get rootClasses =>
      ['MarkDownValueComponent', 'markdown-body'];

  MarkDownValueComponent(Value<String?> value, {List<String>? cssClasses})
      : super(value, cssClasses: cssClasses);

  @override
  drawValue(String? innerValue) {
    innerValue ??= '';
    var htmlContent = md.markdownToHtml(innerValue.toString(),
        extensionSet: md.ExtensionSet.gitHubWeb);

    root.setInnerHtml(htmlContent, validator: NodeValidatorComp());
  }
}

class FontawesomeIconComponent extends Component {
  @override
  Iterable<String> get rootClasses => ['FaIconComponent'];
  @override
  String get template => '''<i class="fa fa-$icon"></i>''';

  String icon;

  FontawesomeIconComponent(this.icon) : super();
}
