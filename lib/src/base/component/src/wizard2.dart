part of sci_component;

abstract class WizardDialog extends Dialog {
  @override
  String get template => '''
<div>
  <div class="back-drop"></div>
  <div class="sci-modal-dialog">
    <div class="sci-modal-content default">
      <div class="sci-modal-header">
          <div class="caption"></div>
          <button type="button" class="btn btn-default btn-primary" id="next">Next</button>
      </div>
      <div class="sci-modal-body">
          <div class="wait"></div>
          <div class="dialogbody"></div>
          <div class="errors"></div>
      </div>
      <div class="sci-modal-footer">
        <div>
          <button type="button" class="btn btn-default" id="previous">Previous</button>
        </div>
        <div>
          <button type="button" class="btn btn-default" id="cancel">Cancel</button>
        </div>
        <div>
          <button type="button" class="btn btn-default btn-primary" id="ok">OK</button>
        </div>
      </div>
    </div>
  </div>
</div>
''';

  late sync.Lock _lock;

  WizardDialog() {
    _lock = sync.Lock(reentrant: true);
    showElement(previousButton, false);
    showElement(nextButton, false);
    init();
  }

  void init() {
    if (currentWizardStep == null && wizardStepComponents.isNotEmpty) {
      currentWizardStep = wizardStepComponents.first;
    }
    drawStepWizard();
  }

  WizardStepComponent? currentWizardStep;
  List<WizardStepComponent> wizardStepComponents = [];

  void addNextComponent(WizardStepComponent wizardStep) {
    if (currentWizardStep == null) {
      currentWizardStep = wizardStep;
    } else {
      var _wizardStep = currentWizardStep!;
      while (_wizardStep.nextComponent != null) {
        _wizardStep = _wizardStep.nextComponent!;
      }
      _wizardStep.nextComponent = wizardStep;
    }
  }

  List<WizardStepComponent> getWizardStepComponents() {
    if (wizardStepComponents.isNotEmpty) return wizardStepComponents;

    var previous = <WizardStepComponent>[];
    var s = currentWizardStep!.previousComponent;
    while (s != null) {
      previous.add(s);
      s = s.previousComponent;
    }
    var list = <WizardStepComponent>[...previous.reversed, currentWizardStep!];
    s = currentWizardStep!.nextComponent;
    while (s != null) {
      list.add(s);
      s = s.nextComponent;
    }

    return list;
  }

  WizardStepComponent? nextComponent() {
    if (wizardStepComponents.isNotEmpty) {
      return wizardStepComponents[
          wizardStepComponents.indexOf(currentWizardStep!) + 1];
    } else {
      return currentWizardStep!.nextComponent;
    }
  }

  WizardStepComponent? previousComponent() {
    if (wizardStepComponents.isNotEmpty) {
      return wizardStepComponents[
          wizardStepComponents.indexOf(currentWizardStep!) - 1];
    } else {
      return currentWizardStep!.previousComponent;
    }
  }

  bool get hasNextStep {
    if (wizardStepComponents.isNotEmpty) {
      return wizardStepComponents.isNotEmpty &&
          wizardStepComponents.last != currentWizardStep;
    } else {
      return currentWizardStep!.nextComponent != null;
    }
  }

  bool get hasPreviousStep {
    if (wizardStepComponents.isNotEmpty) {
      return wizardStepComponents.isNotEmpty &&
          wizardStepComponents.first != currentWizardStep;
    } else {
      return currentWizardStep!.previousComponent != null;
    }
  }

  Element get nextButton => selector("#next");
  Element get previousButton => selector("#previous");

  Future drawStepWizard() async {
    removeAllChildrenFrom(dialogBody);
    var step = currentWizardStep;
    if (step == null) return;

    removeSubscriptionsSync('currentWizardStep');

    addSubscription(
        'currentWizardStep', step.onEvent.listen(onWizardStepComponentEvent));

    addDialogBody(step);
    await step.doInsertedInWizard();
    await updateButtons();
  }

  @override
  _listen() {
    super._listen();
    addSubscription(nextButton, nextButton.onClick.listen((_) => gotNext()));
    addSubscription(
        previousButton, previousButton.onClick.listen((_) => goPrevious()));
  }

  @override
  onOkClick(_) async {
    if (await canOk()) {
      super.onOkClick(_);
    } else {
      if (hasNextStep) gotNext();
    }
  }

  Future gotNext() {
    return _lock.synchronized(goNextUnsynchronized);
  }

  Future goNextUnsynchronized() async {
    if (hasNextStep) {
      try {
        await currentWizardStep?.onBeforeGoNext();
      } catch (e) {
        await drawStepWizard();
        addError(e);
        return;
      }

      try {
        await currentWizardStep?.doRemovedFromWizard();
        currentWizardStep = nextComponent();
        removeErrors();
        await drawStepWizard();
      } catch (e) {
        await currentWizardStep?.doRemovedFromWizard();
        currentWizardStep = previousComponent();
        await drawStepWizard();
        addError(e);
        return;
      }
    }
  }

  Future goPrevious() async {
    return _lock.synchronized(() async {
      if (hasPreviousStep) {
        try {
          await currentWizardStep!.onBeforeGoPrevious();
        } catch (e) {
          addError(e);
          return;
        }

        await currentWizardStep?.doRemovedFromWizard();
        currentWizardStep = previousComponent();
        removeErrors();
        await drawStepWizard();
      }
    });
  }

  void onWizardStepComponentEvent(ComponentEvent evt) {
    updateButtons();
    removeErrors();
  }

  String get nextButtonText => 'Next';

  Future<bool> canOk() => Future.wait<bool>(getWizardStepComponents()
          .map((WizardStepComponent step) => step.canGoNext()))
      .then((list) => list.every((b) => b));

  Future updateButtons() async {
    var currentStep = currentWizardStep!;
    var enableOk = await canOk();
    var enableNext = false;
    if (hasNextStep) enableNext = await currentStep.canGoNext();
    if (enableOk) {
      okButton.text = okButtonText;
      showElement(okButton, true);
      enableElement(okButton, true);
      enableElement(nextButton, enableNext);
      showElement(nextButton, enableNext);
    } else {
      // ok button act as next
      enableElement(okButton, enableNext);
      showElement(nextButton, false);
      okButton.text = currentStep.nextButtonText ?? nextButtonText;
    }
    showElement(previousButton, hasPreviousStep);
    enableElement(previousButton, hasPreviousStep);
    caption = currentStep.caption != null ? currentStep.caption! : caption;
    nextButton.text = currentStep.nextButtonText ?? nextButtonText;
  }

  String get okButtonText => 'Ok';

  void enableElement(Element element, bool b) {
    if (b) {
      element.attributes.remove("disabled");
    } else {
      element.attributes["disabled"] = "";
    }
  }

  void showElement(Element element, bool b) {
    if (b) {
      element.style.display = "";
    } else {
      element.style.display = "none";
    }
  }
}
