 import 'package:sci_base/value.dart';

import '../../component.dart';
import 'list_component.dart';

class FilterListComponent<T> extends ListModelComponent<T> {
  @override
  Iterable<String> get rootClasses => ['FilterListComponent'];

  final ListModel<T> selected;
  final ValueToStringFn<T> valueToString;
  Value<String> searchQuery;

  FilterListComponent(super.model, this.selected, this.valueToString,
      {Value<String>? searchQuery})
      : searchQuery = searchQuery ??= ValueHolder('') {
    addSubscription(
        'searchQuery', this.searchQuery.onChange.listen(onSearchQueryChanged));
    addToRoot(InputTextComponent(searchQuery, cssClasses: ["searchQuery"]));
    _onChange();
  }

  @override
  void onListChanged(ListModelEvent<T> evt) {
    _onChange();
  }

  void onSearchQueryChanged(evt) {
    _onChange();
  }

  void _onChange() {
    selected.clear();
    if (searchQuery.value.isEmpty) {
      selected.addAll(model);
    } else {
      selected.addAll(model.where((element) => valueToString(element)
          .toLowerCase()
          .contains(searchQuery.value.toLowerCase())));
    }
  }
}
