part of sci_component;

class CheckBoxGroup extends Object with SubscriptionHelper {
  List<CheckboxInputElement> list;
  bool hasDefaultSelection;

  final StreamController<CheckboxInputElement> _controller =
      StreamController<CheckboxInputElement>.broadcast();
  Stream<CheckboxInputElement> get onCheckboxChanged => _controller.stream;

  CheckBoxGroup(this.list, {this.hasDefaultSelection = true}) {
    _listen();
  }

  void _listen() {
    for (var cb in list) {
      addSubscription(cb, cb.onChange.listen((evt) {
        _onCheckboxChanged(evt, cb);
      }));
    }
  }

  bool _inEvent = false;

  void _onCheckboxChanged(evt, CheckboxInputElement checkbox) {
    if (_inEvent) return;
    _inEvent = true;

    for (var c in list) {
      if (c != checkbox) {
        c.checked = false;
      }
    }

    var cbt = checkbox;

    if (hasDefaultSelection && !checkbox.checked!) {
      cbt = list.first;
      cbt.checked = true;
    }

    _inEvent = false;

    _controller.add(cbt);
  }

  // Future release() {
  //   return releaseSubscriptions();
  // }

  void releaseSync() {
    releaseSubscriptionsSync();
  }
}
