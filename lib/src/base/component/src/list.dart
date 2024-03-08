part of sci_component;


typedef ObjectToText = String Function(Object o);

class SimpleSelectionListComponent<T> extends SelectionListComponent<T> {
  @override
  String get template => '''<div></div>''';

  SimpleSelectionListComponent(List<T> _list,
      {required ObjectToText objectToText})
      : super(_list, objectToText: objectToText);

  @override
  Element getListElement(T object) => htmlElement('''
<div class="list-element">
  <div class="icon"></div>
  <div class="value">${objectToText(object!)}</div>
</div>''');
}

class SelectionListComponent<T> extends Component {
  @override
  Iterable<String> get rootClasses => ['SelectionListComponent'];
  @override
  String get template =>
      '''<div><div class="header"><div class="title"></div><div class="menu"></div></div></div>''';

  List<T> _list;
  late ObjectToText objectToText;

  SelectionListComponent(this._list, {ObjectToText? objectToText}) {
    if (objectToText != null) {
      this.objectToText = objectToText;
    } else {
      this.objectToText = (Object object) => object.toString();
    }
    draw();
  }

  T? _selected;

  List<T> get list => _list;
  set list(List<T> l) {
    _list = l;
    _selected = null;
    triggerEvent(ComponentListChangedEvent.fromList(this, _list));
    draw();
  }

  T? get selected => _selected;
  set selected(T? o) {
    _selected = o;
//    if (this.isInitialized) draw();
    draw();
  }

  Element getListElement(T object) => htmlElement('''
<div class="list-element">
  <div class="icon"></div>
  <div class="value">${objectToText(object!)}</div>
  <div class="remove-btn"></div>
  <div class="edit-btn"></div>
</div>''');

  void draw() {
    root.children
        .where((e) => !e.classes.contains('.header'))
        .forEach((e) => removeChild(e));

    // if (this._list == null) return;

    for (var object in _list) {
      var li = getListElement(object);
      if (_selected == object) li.classes.add("active");
      li.onClick.listen((evt) => _setSelected(object, li));
      root.children.add(li);
    }
  }

  void _setSelected(T object, Element li) {
    _selected = object;
    root
        .querySelectorAll(".active")
        .forEach((el) => el.classes.remove("active"));
    li.classes.add("active");
    triggerEvent(ListSelectionChangedEvent<T?>.fromSelection(this, selected));
  }
}

class MultiSelectionListComponent<T> extends Component {
  static String DefaultObjectToText(Object object) => "$object";
  List<T> _list;
  late Set<T> _selections;
  String? _template;
  ObjectToText objectToText;
  bool showSelectAll;

  MultiSelectionListComponent(this._list,
      {Set<T>? selections,
      this.showSelectAll = false,
      this.objectToText = DefaultObjectToText})
      : super() {
    _selections = selections ?? <T>{};

    listElement.style.setProperty("overflow-y", "auto");

    if (this.showSelectAll) {
      addSubscription(selectAllElement,
          selectAllElement.onChange.listen(_onSelectAllChanged));
    } else {
      selectAllContainerElement.style.display = 'none';
    }
  }

  List<T> get list => _list;
  set list(List<T> l) {
    _list = l;
    if (showSelectAll && selectAllElement.checked!) {
      _selections = _list.toSet();
    } else {
      _selections = <T>{};
    }

    triggerEvent(ComponentListChangedEvent.fromList(this, _list));
    draw();
  }

  Set<T> get selection => _selections;
  set selections(Set<T> s) {
    _selections = s;
    triggerEvent(ListSelectionChangedEvent.fromSelections(this, _selections));
    draw();
  }

  set template(String t) {
    _template = t;
  }

  @override
  String get template => _template == null
      ? '''
<div>
  <div class="checkbox"  id="selectAllContainer" style="margin-bottom: 10px">
    <label>
      <input class="hasRun" type="checkbox" id="selectAll"> Select all
    </label>
  </div>
  <div class="list-group well" id="list"></div>
</div>'''
      : _template!;

  Element get listElement => selector('#list');
  CheckboxInputElement get selectAllElement =>
      selector<CheckboxInputElement>('#selectAll');
  Element get selectAllContainerElement => selector('#selectAllContainer');

  void draw() {
    removeAllChildrenFrom(listElement);

    _list.forEach(_drawElement);
  }

  Element getListElement(T object) {
    var itemHtml = '''
<div class="list-group">
  <div class="list-group-item">
    <div class="checkbox">
      <label>
        <input type="checkbox" id="checkbox">
        <h4 class="list-group-item-heading" id="name">${objectToText(object!)}</h4>
      </label>
    </div>
  </div>
</div>
''';
    return htmlElement(itemHtml);
  }

  void _drawElement(T object) {
    var rowElement = getListElement(object);
    var checkboxElement =
        rowElement.querySelector("#checkbox") as CheckboxInputElement;
    checkboxElement.checked = this._selections.contains(object);
    this._listenCheckBox(checkboxElement, object);
    this.listElement.children.add(rowElement);
  }

  void _listenCheckBox(CheckboxInputElement checkboxElement, T object) {
    checkboxElement.onChange.listen((evt) {
      var hrefParent = checkboxElement.parent!.parent!.parent;
      if (checkboxElement.checked!) {
        _addSelection(object);
        hrefParent!.classes.add("active");
      } else {
        _removeSelection(object);
        hrefParent!.classes.remove("active");
      }
    });
  }

  void _onSelectAllChanged(_) {
    if (selectAllElement.checked!) {
      selections = _list.toSet();
    } else {
      selections = <T>{};
    }
  }

  void _removeSelection(T o) {
    _selections.remove(o);
    triggerEvent(ListSelectionChangedEvent.fromSelections(this, _selections));
  }

  void _addSelection(T o) {
    _selections.add(o);
    triggerEvent(ListSelectionChangedEvent.fromSelections(this, _selections));
  }
}
