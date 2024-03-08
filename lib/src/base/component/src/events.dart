part of sci_component;

class ComponentEvent {
  Component source;
  Map data;
  ComponentEvent.fromData(this.source, this.data);

  @override
  String toString() {
    return '$runtimeType($source,$data)';
  }
}

class ComponentObjectChangedEvent extends ComponentEvent {
  ComponentObjectChangedEvent.fromData(Component source, Map data)
      : super.fromData(source, data);
}

class ComponentListChangedEvent<T> extends ComponentEvent {
  ComponentListChangedEvent.fromList(Component source, List<T> list)
      : super.fromData(source, {"list": list});
  List<T>? get list => data["list"] as List<T>?;
}

class ListSelectionChangedEvent<T> extends ComponentEvent {
  ListSelectionChangedEvent.fromSelections(Component source, Set<T> object)
      : super.fromData(source, {"selections": object.toList()});
  ListSelectionChangedEvent.fromSelection(Component source, T object)
      : super.fromData(source, {
          "selections": [object]
        });
  T? get selection => selections.isNotEmpty ? selections.first : null;
  Set<T> get selections => Set<T>.from(data["selections"] as Iterable);
}
