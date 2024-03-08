import 'dart:html';

 import 'package:sci_base/value.dart';

import '../../component.dart';

typedef ValueToStringFn<T> = String Function(T value);
typedef ValueToElementFn<T> = Element Function(T value);
typedef FilterValueFn<T> = bool Function(T value);
typedef ValueToComponentFn<T, C extends Component> = C Function(T value);

abstract class ListModelComponent<T> extends Component {
  final ListModel<T> model;
  ListModelComponent(this.model) {
    addSubscription(model, model.onListChanged.listen(onListChanged));
  }

  void onListChanged(ListModelEvent<T> evt) {
    switch (evt) {
      case ListModelAddEvent<T>():
        onListModelAddEvent(evt);
      case ListModelRemoveEvent<T>():
        onListModelRemoveEvent(evt);
      case ListModelInsertEvent<T>():
        onListModelInsertEvent(evt);
      case ListModelClearEvent<T>():
        onListModelClearEvent(evt);
    }
  }

  void onListModelAddEvent(ListModelAddEvent<T> evt) {}
  void onListModelRemoveEvent(ListModelRemoveEvent<T> evt) {}
  void onListModelInsertEvent(ListModelInsertEvent<T> evt) {}
  void onListModelClearEvent(ListModelClearEvent<T> evt) {}
}

class ListComponent<T, C extends Component> extends ListModelComponent<T> {
  @override
  Iterable<String> get rootClasses => ['ListComponent'];

  final ValueToComponentFn<T, C> _factory;
  bool propagateEvents;
  String flexDirection;

  ListComponent(super.model, this._factory,
      {this.propagateEvents = false, this.flexDirection = 'column'}) {
    root.style.display = 'flex';
    root.style.flexDirection = flexDirection;
    _draw();
  }

  @override
  void onListChanged(ListModelEvent<T> evt) {
    _draw();
  }

  void _draw() {
    removeSubComponentsSync();

    for (var element in model) {
      addToRoot(_factory(element), propagateEvents: propagateEvents);
    }
  }
}

class NamedListComponent<T, C extends Component> extends Component {
  @override
  Iterable<String> get rootClasses => ['NamedListComponent'];

  NamedListComponent(
      Value<String> title, ListModel<T> model, ValueToComponentFn<T, C> factory,
      {bool propagateEvents = false,
      String flexDirection = 'column',
      List<String>? cssClasses})
      : super(cssClasses: cssClasses) {
    addToRoot(TextComponent(title, cssClasses: ["title"]));
    addToRoot(ListComponent(model, factory,
        propagateEvents: propagateEvents, flexDirection: flexDirection));

    addSub(model.onListChanged.listen((event) {
      _onListChanged(model);
    }));

    _onListChanged(model);
  }

  void _onListChanged(ListModel<T> model) {
    hide(model.isEmpty);
  }
}
