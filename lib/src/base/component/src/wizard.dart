part of sci_component;

abstract class WizardStepComponent extends Component {
  @override
  Iterable<String> get rootClasses => ['WizardStepComponent'];

  bool isInWizard = false;

  WizardStepComponent? _nextComponent;
  WizardStepComponent? get nextComponent => _nextComponent;
  set nextComponent(WizardStepComponent? next) {
    _nextComponent = next;
    _nextComponent!.previousComponent = this;
  }

  WizardStepComponent? _previousComponent;
  WizardStepComponent? get previousComponent => _previousComponent;
  set previousComponent(WizardStepComponent? previous) {
    _previousComponent = previous;
  }

  bool get hasNext => nextComponent != null;

  Future<bool> canGoNext() async => false;
  void sendChangedEventOn(_) {
    triggerEvent(ComponentEvent.fromData(this, {}));
  }

  Future doInsertedInWizard() async {
    isInWizard = true;
    await insertedInWizard();
  }

  Future doRemovedFromWizard() async {
    isInWizard = false;
    await removedFromWizard();
  }

  Future insertedInWizard() async {}
  Future removedFromWizard() async {}

  Future onBeforeGoNext() async {}
  Future onBeforeGoPrevious() async {}

  String? get caption => null;
  String? get subtitle => null;
  String? get nextButtonText => null;
  bool get showOk => true;
}
