import 'dart:html';

import 'package:sci_base/value.dart';

import 'list_component.dart';

class ListRemoveComponent<T> extends ListModelComponent<T> {
  static Element _defaultValueToElement<T>(
      T value, ValueToStringFn<T> valueToString) {
    return Element.div()
      ..classes.add('value')
      ..innerText = valueToString(value);
  }

  static ValueToElementFn<T> defaultValueToElement<T>(
          ValueToStringFn<T> valueToString) =>
      (T v) => _defaultValueToElement(v, valueToString);

  @override
  Iterable<String> get rootClasses => ['ListModelRemoveComponent'];

  final ListModel<T> selected;
  final ValueToStringFn<T> valueToString;
  late ValueToElementFn<T> valueToElement;
  String actionCssClass;
  bool _isReadOnly = false;
  bool _removeLastOnly;

  ListRemoveComponent(super.model, this.selected, this.valueToString,
      {ValueToElementFn<T>? valueToElement,
      this.actionCssClass = 'fa-minus',
      bool removeLastOnly = false})
      : _removeLastOnly = removeLastOnly {
    this.valueToElement =
        valueToElement ?? defaultValueToElement(valueToString);

    addSubscription(
        'selected', selected.onListChanged.listen(onSelectedChanged));

    draw();
  }

  void setReadOnly(bool flag) {
    if (_isReadOnly == flag) return;
    _isReadOnly = flag;
    draw();
  }

  void removeLastOnly(bool flag) {
    if (_removeLastOnly == flag) return;
    _removeLastOnly = flag;
    draw();
  }

  @override
  void onListChanged(ListModelEvent<T> evt) {
    draw();
  }

  void onSelectedChanged(ListModelEvent<T> evt) {
    draw();
  }

  @override
  void draw() {
    removeSubscriptionsSync('itemSubscription');
    removeAllChildrenFrom(root);

    var items = model
        .where((element) => selected.contains(element))
        .map((value) => (value, valueToItem(value)))
        .toList();

    if (_isReadOnly) {
      for (var (_, itemElem) in items) {
        itemElem.querySelector('.action-icon')!.style.display = "none";
      }
    } else if (_removeLastOnly && items.isNotEmpty) {
      for (var (_, itemElem) in items.reversed.skip(1)) {
        itemElem.querySelector('.action-icon')!.style.display = "none";
      }
      var (value, itemElem) = items.last;
      itemElem.querySelector('.action-icon')!.style.display = "";
      addSubscription('itemSubscription', itemElem.onClick.listen((event) {
        model.remove(value);
      }));
    } else {
      for (var (value, itemElem) in items) {
        addSubscription('itemSubscription', itemElem.onClick.listen((event) {
          model.remove(value);
        }));
      }
    }

    for (var (_, itemElem) in items) {
      root.children.add(itemElem);
    }
  }

  Element valueToItem(T value) {
    return DivElement()
      ..classes.add('item')
      ..children.add(valueToElement(value))
      ..children.add(Element.tag('i')
        ..classes.addAll(['action-icon', 'fa', actionCssClass]));
  }
}
