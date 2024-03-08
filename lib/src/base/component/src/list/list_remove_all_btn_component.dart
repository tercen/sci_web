import 'dart:html';

import 'package:sci_base/value.dart';

import '../../component.dart';
import 'list_component.dart';

class RemoveAllButtonListComponent<T> extends ListModelComponent<T> {
  @override
  Iterable<String> get rootClasses => ['RemoveAllButtonListComponent'];

  final ListModel<T> selected;

  Value<List<String>> actionCssClass;

  RemoveAllButtonListComponent(
      super.model, this.selected, this.actionCssClass) {
    addToRoot(IconComponent(actionCssClass));
    addSub(root.onClick.listen(_onClick));
  }

  void _onClick(MouseEvent evt) {
    model.removeAll(selected);
  }
}
