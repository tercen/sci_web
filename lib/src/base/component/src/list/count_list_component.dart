import '../../component.dart';
import 'list_component.dart';

class CountListComponent<T> extends ListModelComponent<T> {
  @override
  Iterable<String> get rootClasses => ['CountListComponent'];

  Value<int> count;

  CountListComponent(super.model, {Value<int>? count})
      : count = count ??= ValueHolder(model.length) {
    addToRoot(LabelComponent(this.count));
  }

  @override
  void onListChanged(ListModelEvent<T> evt) {
    count.value = model.length;
  }
}
