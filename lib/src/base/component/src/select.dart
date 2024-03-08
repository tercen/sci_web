part of sci_component;

class SelectComponent<T> extends SelectionListComponent<T> {
  @override
  Iterable<String> get rootClasses => ['SelectComponent'];

  SelectComponent(List<T> list, {ObjectToText? objectToText})
      : super(list, objectToText: objectToText);

  @override
  String get template => '''<select class="form-control"></select>''';
  @override
  OptionElement getListElement(T object) =>
      htmlElement('<option>${objectToText(object!)}</option>') as OptionElement;

  @override
  void created() {
    super.created();
    addSubscription(root, root.onChange.listen((_onSelectListChange)));
  }

  SelectElement get selectElement => root as SelectElement;

  void _onSelectListChange(_) {
    if (selectElement.selectedIndex! >= 0) {
      _selected = _list[selectElement.selectedIndex!];
      triggerEvent(ListSelectionChangedEvent<T?>.fromSelection(this, selected));
    }
  }

  @override
  void draw() {
    removeAllChildrenFrom(selectElement);

    if (_selected == null && _list.isNotEmpty) {
      _selected = _list.first;
    }
    for (var object in _list) {
      var option = getListElement(object);
      option.selected = _selected == object;
      selectElement.children.add(option);
    }
    if (_selected != null) {
      _onSelectListChange(null);
    }
  }
}
