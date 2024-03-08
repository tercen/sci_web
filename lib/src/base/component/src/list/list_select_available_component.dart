import 'dart:async';
import 'dart:html';

import 'package:sci_base/value.dart';

import '../../component.dart';
import 'list_component.dart';
import 'list_search_component.dart';

class SelectAvailableListComponent<T> extends Component {
  @override
  Iterable<String> get rootClasses => ['SelectAvailableListComponent'];

  final Set<T> _innerAvailable;
  final Value<Set<T>> _available;
  final ListModel<T> _model;
  final ListModel<T> _availableModel;

  late SearchListComponent<T> selectedComponent;
  late SearchListComponent<T> availableComponent;

  SelectAvailableListComponent(
      this._model, this._available, ValueToStringFn<T> valueToString,
      {Value<String>? title,
      Value<String>? availableTitle,
      String notAvailableMsg = "not available",
      bool removeLastOnly = false,
      bool showRemoveAll = true})
      : _availableModel = ListModel.from(_available.value
            .where((element) => !_model.contains(element))
            .toList()),
        _innerAvailable = Set.from(_available.value) {
    Element selectedValueToElement(T value) {
      var element = Element.div()
        ..classes.add('value')
        ..innerText = valueToString(value);
      if (!_innerAvailable.contains(value)) {
        element.children.add(Element.div()
          ..innerText = notAvailableMsg
          ..style.color = 'red');
      }
      return element;
    }

    availableComponent = SearchListComponent(
        _availableModel, ListModel<T>(), valueToString,
        title: availableTitle,
        actionCssClass: 'fa-plus',
        cssClasses: ["available"],
        showRemoveAll: showRemoveAll);

    selectedComponent = SearchListComponent(
        _model, ListModel<T>(), valueToString,
        valueToElement: selectedValueToElement,
        title: title,
        cssClasses: ["selected"],
        removeLastOnly: removeLastOnly,
        showRemoveAll: showRemoveAll);

    addToRoot(availableComponent);
    addToRoot(selectedComponent);

    addSubscription('model', _available.onChange.listen(onAvailableChanged));
    addSubscription('model', _model.onListChanged.listen(onModelChanged));
    addSubscription(
        'model', _availableModel.onListChanged.listen(onAvailableModelChanged));
  }

  void onAvailableChanged(evt) {
    _availableModel
      ..clear()
      ..addAll(_available.value.where((element) => !_model.contains(element)));
  }

  void onModelChanged(ListModelEvent<T> evt) {
    switch (evt) {
      case ListModelAddEvent<T>():
        break;
      case ListModelRemoveEvent<T>():
        {
          _availableModel
            ..clear()
            ..addAll(_available.value.where(
                (element) => !_model.contains(element))); // to keep the order
        }

      case ListModelInsertEvent<T>():
        assert(false, "onModelChanged");
      case ListModelClearEvent<T>():
        {
          Timer.run(() {
            _availableModel
              ..clear()
              ..addAll(_available.value.where(
                  (element) => !_model.contains(element))); // to keep the order
          });
        }
        break;
    }
  }

  void onAvailableModelChanged(ListModelEvent<T> evt) {
    switch (evt) {
      case ListModelAddEvent<T>():
        break;
      case ListModelRemoveEvent<T>(elements: var elements):
        // assert(!_model.contains(element));
        _model.addAll(elements);
      case ListModelInsertEvent<T>():
        assert(false, "onAvailableModelChanged");
      case ListModelClearEvent<T>():
        break;
    }
  }

  void showSelected(bool flag) {
    selectedComponent.show(flag);
  }

  void showAvailableFilter(bool flag) {
    availableComponent.showFilter(flag);
  }

  void setReadOnly(bool flag) {
    availableComponent.setReadOnly(flag);
    selectedComponent.setReadOnly(flag);
  }

  void removeLastOnly(bool flag) {
    selectedComponent.removeLastOnly(flag);
  }
}
