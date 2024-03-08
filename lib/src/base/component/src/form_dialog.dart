part of sci_component;

class FormComponent extends Component {
  static const String TEXT_AREA_DISPLAY_TYPE = Property.TEXT_AREA_DISPLAY_TYPE;
  static const String TEXT_DISPLAY_TYPE = Property.TEXT_DISPLAY_TYPE;
  static const String PASSWORD_DISPLAY_TYPE = Property.PASSWORD_DISPLAY_TYPE;
  static const String CHECK_BOX_DISPLAY_TYPE = Property.CHECK_BOX_DISPLAY_TYPE;

  static const String STRING_VALUE_TYPE = Property.STRING_VALUE_TYPE;
  static const String DOUBLE_VALUE_TYPE = Property.DOUBLE_VALUE_TYPE;
  static const String BOOL_VALUE_TYPE = Property.BOOL_VALUE_TYPE;

  final bool isInline;
  bool inputFirst = false;
  @override
  Iterable<String> get rootClasses =>
      isInline ? ['InlineFormComponent'] : ['FormComponent'];
  @override
  String get template => isInline ? inlineTemplate : baseTemplate;

  String get baseTemplate => '<div>'
      '<div class="form-controls">'
      '</div>'
      '<div class="form-button"></div>'
      '</div>';

  String get inlineTemplate => '<div>'
      '<div class="form-controls"></div>'
      '<div class="form-button"></div>'
      '</div>';

  late PropertyList propertyList;

  FormComponent({
    PropertyList? propertyList,
    this.isInline = false,
    this.inputFirst = false,
    List<String>? cssClasses,
  })  : propertyList = propertyList ?? PropertyList(),
        super(cssClasses: cssClasses) {
    if (this.propertyList.properties.isNotEmpty) {
      draw();
    }

    addSubscription(
        selector('.form-button'),
        selector('.form-button').onClick.listen((evt) {
          triggerEvent(
              ComponentEvent.fromData(this, {'formBtnClick': 'form-button'}));
        }));
  }

  FormComponent.fromList(this.propertyList,
      {this.isInline = false, this.inputFirst = false}) {
    draw();
    addSubscription(
        selector('.form-button'),
        selector('.form-button').onClick.listen((evt) {
          triggerEvent(
              ComponentEvent.fromData(this, {'formBtnClick': 'form-button'}));
        }));
  }

  void setProperties(PropertyList list) {
    clear();
    propertyList = list;
  }

  void addObject(base.Base object, String propertyName,
          {String label = '',
          String displayType = Property.TEXT_DISPLAY_TYPE,
          bool enable = true,
          List<dynamic>? enumeration,
          List<String>? displayEnumeration,
          String info = '',
          String description = '',
          bool required = false}) =>
      propertyList.addObject(object, propertyName,
          label: label,
          displayType: displayType,
          enable: enable,
          enumeration: enumeration,
          displayEnumeration: displayEnumeration,
          info: info,
          description: description,
          required: required);

  void addValue(Value value, String propertyName,
          {String label = '',
          String displayType = Property.TEXT_DISPLAY_TYPE,
          bool enable = true,
          List<dynamic>? enumeration,
          List<String>? displayEnumeration,
          String info = '',
          String description = '',
          bool required = false}) =>
      propertyList.addValue(value, propertyName,
          label: label,
          displayType: displayType,
          enable: enable,
          enumeration: enumeration,
          displayEnumeration: displayEnumeration,
          info: info,
          description: description,
          required: required);

  void draw() {
    if (isInline) {
      drawInline();
    } else {
      baseDraw();
    }
  }

  void clear() {
    removeSubComponentsSync();
    propertyList.properties.clear();
  }

  List<PropertyComponent> get propertyComponents =>
      subComponents.whereType<PropertyComponent>().toList();

  void enable(bool flag) {
    for (var comp in propertyComponents) {
      comp.enable(flag);
    }
  }

  void baseDraw() {
    for (var property in propertyList.properties) {
      if (inputFirst) {
        add(PropertyComponent.from(property), '.form-controls',
            propagateEvents: true);
        add(FormLabel(property), '.form-controls');
      } else {
        add(FormLabel(property), '.form-controls');
        add(PropertyComponent.from(property), '.form-controls',
            propagateEvents: true);
      }
    }
  }

  // void baseDraw2() {
  //   var labels = selector('.labels');
  //   for (var p in propertyList.properties) {
  //     if (p.displayType == Property.TEXT_AREA_DISPLAY_TYPE) {
  //       labels.children
  //           .add(htmlElement('<div class="LabelArea">${p.displayName}</div>'));
  //     } else {
  //       if (p.required) {
  //         labels.children.add(htmlElement(
  //             '<div class="Label">${p.displayName}<span class="required">(required)</span></div>'));
  //       } else {
  //         if (p.description.isNotEmpty) {
  //           var labelElement = htmlElement(
  //               '<div class="form-label-container"><span class="form-label">${p.displayName}</span> <i class="icon-question"></i></div>');
  //
  //           labels.children.add(labelElement);
  //
  //           addSubComponent(ToolTip(
  //               labelElement.querySelector('.icon-question')!,
  //               textContent: p.description));
  //         } else {
  //           labels.children
  //               .add(htmlElement('<div class="Label">${p.displayName}</div>'));
  //         }
  //       }
  //     }
  //
  //     var pComp = PropertyComponent.from(p);
  //     add(pComp, '.controls', propagateEvents: true);
  //   }
  // }

  void drawInline() {
    var form = selector('.form-controls');
    for (var p in propertyList.properties) {
      if (p.displayName != null && p.displayName!.isNotEmpty) {
        if (p.displayType == Property.TEXT_AREA_DISPLAY_TYPE) {
          form.children.add(
              htmlElement('<div class="LabelArea">${p.displayName}</div>'));
        } else {
          form.children.add(
              htmlElement('<div class="inline-label">${p.displayName}</div>'));
        }
      }

      var pComp = PropertyComponent.from(p);
      add(pComp, '.form-controls', propagateEvents: true);
    }
  }
}

class FormLabel extends Component {
  @override
  Iterable<String> get rootClasses => ['FormLabel'];
  FormLabel(Property property) {
    addSub(property.onPropertyChange.listen((_) {
      show(property.show);
    }));
    addToRoot(TextComponent(property.displayName, cssClasses: ['name']));
    if (property.required) {
      addToRoot(TextComponent('(required)', cssClasses: ['required']));
    }
    if (property.description.isNotEmpty) {
      addToRoot(IconComponent.css('icon-question'));
      addToolTip(
          selectors: '.icon-question',
          textContent: property.description,
          opacity: 1.0,
          position: '', //position: 'right',
          isStatic: true);
    }
  }
}

abstract class PropertyComponent<T extends Property> extends Component {
  @override
  Iterable<String> get rootClasses =>
      ['PropertyComponent', 'PropertyComponent'];

  final T property;

  PropertyComponent(this.property) {
    addSub(property.onPropertyChange.listen((event) {
      show(property.show);
    }));
  }

  static PropertyComponent from(Property p) {
    if (p is EnumerationProperty) {
      if (p.displayType == Property.CHECK_BOX_DISPLAY_TYPE) {
        return CheckboxPropertyComponent._(p);
      }
      return EnumPropertyComponent._(p);
    } else {
      if (p.valueType == Property.BOOL_VALUE_TYPE) {
        if (p.displayType == Property.CHECK_BOX_DISPLAY_TYPE) {
          return BoolPropertyCheckBoxComponent._(p);
        }
        return BoolPropertyComponent._(p);
      } else {
        if (p.displayType == Property.TEXT_AREA_DISPLAY_TYPE) {
          return TextAreaPropertyComponent._(p);
        } else if (p.displayType == Property.PASSWORD_DISPLAY_TYPE) {
          return PasswordPropertyComponent._(p);
        } else {
          return InputPropertyComponent._(p);
        }
      }
    }
  }

  void sendChangeEvent() => triggerEvent(ComponentEvent.fromData(this, {}));

  @override
  void releaseSync() {
    super.releaseSync();
    property.releaseSync();
  }

  void enable(bool flag);
}

class BoolPropertyCheckBoxComponent extends PropertyComponent {
  @override
  Iterable<String> get rootClasses =>
      ['BoolPropertyCheckBoxComponent', 'PropertyComponent'];
  @override
  String get template => '''
<div>
  <div>
    <input type="checkbox" class="form-control" value="true">  
  </div>
</div>
  ''';

  BoolPropertyCheckBoxComponent._(super.property) {
    (selector('input') as CheckboxInputElement)
      ..disabled = !property.enable
      ..checked = property.value as bool?;

    property.onChange.listen((_) {
      if ((selector('input') as CheckboxInputElement).checked !=
          property.value as bool?) {
        (selector('input') as CheckboxInputElement).checked =
            property.value as bool?;
        sendChangeEvent();
      }
    });

    selector('input').onChange.listen((evt) {
      if (property.value !=
          (selector('input') as CheckboxInputElement).checked) {
        property.value = (selector('input') as CheckboxInputElement).checked;
        sendChangeEvent();
      }
    });
  }

  @override
  void enable(bool flag) {
    if (flag) {
      selector('input').removeAttribute('disabled');
    } else {
      selector('input').setAttribute('disabled', '');
    }
  }
}

class BoolPropertyComponent extends PropertyComponent {
  static int INSTANCE_NUM = 0;

  @override
  Iterable<String> get rootClasses =>
      ['BoolPropertyComponent', 'PropertyComponent'];

  late int instanceNum;

  BoolPropertyComponent._(super.property) {
    instanceNum = INSTANCE_NUM;
    INSTANCE_NUM++;

    _listen();
    _draw();

    addSubscription(property, property.onChange.listen((_) {
      _unlisten();
      _draw();
      _listen();
    }));
  }

  _draw() {
    radioTrue.checked = property.value as bool?;
    radioFalse.checked = !(property.value as bool);
    if (!property.enable) {
      radioTrue.setAttribute('disabled', '');
      radioFalse.setAttribute('disabled', '');
    }
  }

  @override
  void enable(bool flag) {
    if (flag) {
      radioTrue.removeAttribute('disabled');
      radioFalse.removeAttribute('disabled');
    } else {
      radioTrue.setAttribute('disabled', '');
      radioFalse.setAttribute('disabled', '');
    }
  }

  _listen() {
    addSubscription(radioTrue, radioTrue.onChange.listen((evt) {
      property.value = radioTrue.checked;
      sendChangeEvent();
    }));

    addSubscription(radioFalse, radioFalse.onChange.listen((evt) {
      property.value = !radioFalse.checked!;
      sendChangeEvent();
    }));
  }

  Future _unlisten() async {
    removeSubscriptionsSync(radioTrue);
    removeSubscriptionsSync(radioFalse);
  }

  @override
  String get template => '''
<div>
  <div>
    <input type="radio" class="true form-control" value="true"><div>true</div> 
  </div>
  <div>
    <input type="radio" class="false form-control" value="false"><div>false</div> 
  </div>
</div>
  ''';

  RadioButtonInputElement get radioTrue =>
      selector('.true') as RadioButtonInputElement;
  RadioButtonInputElement get radioFalse =>
      selector('.false') as RadioButtonInputElement;

  @override
  void inserted() {
    // root has parent only after inserted
    radioTrue.name = 'radio$instanceNum${root.parent!.children.length}';
    radioFalse.name = 'radio$instanceNum${root.parent!.children.length}';
  }
}

class InputPropertyComponent<T extends Property> extends PropertyComponent<T> {
  @override
  Iterable<String> get rootClasses => ['InputPropertyComponent'];

  InputPropertyComponent._(super.property) {
    addSubscription(valueInput, valueInput.onInput.listen((_) {
      setValue();
      sendChangeEvent();
    }));
    addSubscription(property, property.onChange.listen((_) {
      getValue();
    }));
    getValue();
    if (!property.enable) {
      valueInput.setAttribute('disabled', '');
    }
  }

  @override
  void enable(bool flag) {
    if (flag) {
      valueInput.removeAttribute('disabled');
    } else {
      valueInput.setAttribute('disabled', '');
    }
  }

  @override
  String get template => '<div>'
      '<input type="text" class="value form-control" autocomplete="new-password">'
      '<div><div class="error" style="display: none"></div></div>'
      '</div>';

  Element get valueInput => selector('.value');

  getValue() {
    (valueInput as InputElement).value = property.value.toString();
  }

  void setValue() {
    var error = selector('.error');
    error
      ..text = ''
      ..style.display = 'none';
    try {
      if (property.valueType == Property.DOUBLE_VALUE_TYPE) {
        var strValue = (valueInput as InputElement).value!;
        var doubleValue = double.tryParse(strValue);
        if (doubleValue == null) {
          throw ServiceError.bad(
              'form.input.bad.format', '$strValue is not a number');
        } else {
          property.value = doubleValue;
        }
      } else {
        property.value = (valueInput as InputElement).value;
      }
    } on ServiceError catch (e) {
      var error = selector('.error');
      error
        ..style.display = ''
        ..text = e.reason;
    } on FormatException catch (e) {
      var error = selector('.error');
      error
        ..style.display = ''
        ..text = e.message;
    } catch (e) {
      var error = selector('.error');
      error
        ..style.display = ''
        ..text = e.toString();
    }
  }
}

class PasswordPropertyComponent extends InputPropertyComponent {
  @override
  Iterable<String> get rootClasses => ['PasswordPropertyComponent'];
  @override
  String get template =>
      '<div><input class="value form-control" type="password" autocomplete="new-password"><div class="error" style="display: none"></div></div>';

  PasswordPropertyComponent._(Property property) : super._(property);
}

class EnumPropertyComponent
    extends InputPropertyComponent<EnumerationProperty> {
  @override
  Iterable<String> get rootClasses =>
      ['EnumPropertyComponent', 'PropertyComponent'];
  @override
  String get template =>
      '<div><select class="value form-control"></select></div>';

  EnumPropertyComponent._(EnumerationProperty property) : super._(property);

  @override
  void created() {
    super.created();
    var se = valueInput as SelectElement;
    var ep = property;
    for (var i = 0; i < ep.enumeration.length; i++) {
      var value = ep.enumeration[i];
      var displayValue = ep.displayEnumeration[i];
      var option =
          OptionElement(data: displayValue, selected: value == property.value);
      se.children.add(option);
    }
  }

  @override
  getValue() {
    var se = valueInput as SelectElement;
    var options = se.options;
    var ep = property;
    for (var i = 0; i < ep.enumeration.length; i++) {
      var value = ep.enumeration[i];
      var option = options[i];
      option.selected = value == property.value;
    }
  }

  @override
  void setValue() {
    var se = valueInput as SelectElement;
    property.value = (property).enumeration[se.selectedIndex!];
  }
}

class CheckboxPropertyComponent extends PropertyComponent<EnumerationProperty> {
  @override
  Iterable<String> get rootClasses =>
      ['CheckboxPropertyComponent', 'PropertyComponent'];
  String getCheckBoxTemplate(String label) =>
      '<div><input type="checkbox"><div>$label</div></div>';

  CheckboxPropertyComponent._(super.property);

  @override
  void created() {
    for (var i = 0; i < property.displayEnumeration.length; i++) {
      var element =
          htmlElement(getCheckBoxTemplate(property.displayEnumeration[i]));
      root.children.add(element);
      var checkbox = element.querySelector('input') as CheckboxInputElement;
      if (!property.enable) {
        checkbox.setAttribute('disabled', '');
      }
      checkbox.value = property.enumeration[i] as String?;

      checkbox.checked = property.enumeration[i] == property.value;

      if (!property.enable) {
        checkbox.setAttribute('disabled', '');
      }

      _listen(checkbox);
    }
  }

  @override
  void enable(bool flag) {
    if (flag) {
      selector('input').removeAttribute('disabled');
    } else {
      selector('input').setAttribute('disabled', '');
    }
  }

  _listen(CheckboxInputElement checkbox) {
    addSubscription(checkbox, checkbox.onChange.listen((_) {
      var isCheck = checkbox.checked!;

      if (isCheck) {
        property.value = checkbox.value;
        for (var cb in root
            .querySelectorAll('input')
            .whereType<CheckboxInputElement>()) {
          if (cb != checkbox) {
            removeSubscriptionsSync(cb);
            cb.checked = false;
            _listen(cb);
          }
        }
      } else {
        var other = root
            .querySelectorAll('input')
            .whereType<CheckboxInputElement>()
            .firstWhereOrNull((element) => element != checkbox);
        if (other != null) {
          other.checked = true;
          property.value = other.value;
        } else {
          removeSubscriptionsSync(checkbox);
          checkbox.checked = true;
          _listen(checkbox);
        }
      }
      sendChangeEvent();
    }));
  }
}

class TextAreaPropertyComponent extends InputPropertyComponent {
  @override
  Iterable<String> get rootClasses =>
      ['TextAreaPropertyComponent', 'PropertyComponent'];

  TextAreaPropertyComponent._(Property property) : super._(property) {
    addSubscription(valueInput, valueInput.onInput.listen((evt) {
      setValue();
      sendChangeEvent();
    }));

    getValue();
  }

  @override
  String get template => '''
<div>
  <textarea class="value form-control"></textarea>
</div>
  ''';

  @override
  getValue() {
    (valueInput as TextAreaElement).value = property.value.toString();
  }

  @override
  void setValue() {
    if (property.valueType == Property.DOUBLE_VALUE_TYPE) {
      property.value = double.parse((valueInput as TextAreaElement).value!);
    } else {
      property.value = (valueInput as TextAreaElement).value;
    }
    if (!property.enable) {
      valueInput.setAttribute('disabled', '');
    }
  }
}

class FormDialog extends Dialog {
  FormComponent formComponent;

  FormDialog()
      : caption = '',
        formComponent = FormComponent() {
    beLarge();
    addDialogBody(formComponent);
  }

  PropertyList get propertyList => formComponent.propertyList;

  @override
  String caption;

  @override
  Future<bool> open() {
    formComponent.draw();
    return super.open();
  }
}
