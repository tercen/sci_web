import 'dart:collection';

import 'package:sci_base/value.dart';

import '../../component.dart';
import 'count_list_component.dart';
import 'list_component.dart';
import 'list_filter_component.dart';

import 'list_remove_all_btn_component.dart';
import 'list_remove_component.dart';

class SearchListComponent<T> extends Component {
  @override
  Iterable<String> get rootClasses => ['SearchListComponent'];

  SearchListComponent(ListModel<T> model, ListModel<T> selected,
      ValueToStringFn<T> valueToString,
      {Value<String>? title,
      ValueToElementFn<T>? valueToElement,
      String actionCssClass = 'fa-minus',
      List<String>? cssClasses,
      bool removeLastOnly = false,
      bool showRemoveAll = true})
      : super(cssClasses: cssClasses) {
    if (title != null) {
      addToRoot(TextComponent(title, cssClasses: ["title"]));
    }
    addToRoot(FilterListComponent(model, selected, valueToString));

    if (showRemoveAll) {
      addToRoot(ListLayoutComponent.row([
        CountListComponent(selected),
        RemoveAllButtonListComponent(
            model, selected, ValueHolder(['action-icon', 'fa', actionCssClass]))
      ], cssClasses: [
        'countContainer'
      ]));
    } else {
      addToRoot(CountListComponent(selected));
    }

    var listComp = ListRemoveComponent(model, selected, valueToString,
        valueToElement: valueToElement,
        actionCssClass: actionCssClass,
        removeLastOnly: removeLastOnly);
    addToRoot(listComp);
    listComp.ensureScroll();
  }

  void showTitle(bool flag) =>
      subComponents.whereType<CountListComponent>().firstOrNull?.show(flag);

  void showCount(bool flag) =>
      allSubComponents.whereType<CountListComponent>().firstOrNull?.show(flag);

  void showFilter(bool flag) =>
      subComponents.whereType<FilterListComponent>().firstOrNull?.show(flag);
  void showList(bool flag) =>
      subComponents.whereType<ListRemoveComponent>().firstOrNull?.show(flag);

  void setReadOnly(bool flag) {
    subComponents
        .whereType<ListRemoveComponent>()
        .firstOrNull
        ?.setReadOnly(flag);
    allSubComponents
        .whereType<RemoveAllButtonListComponent>()
        .firstOrNull
        ?.hide(flag);
  }

  void removeLastOnly(bool flag) {
    subComponents.whereType<ListRemoveComponent>().first.removeLastOnly(flag);
  }
}
