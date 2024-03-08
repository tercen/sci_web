part of sci_component;

typedef OnOkCallback = Future Function();

class Dialog extends Component {
  @override
  Iterable<String> get rootClasses => ['Dialog'];

  OnOkCallback? onOkCallback;

  @override
  String get template => '''
<div>
  <div class="back-drop-old"></div>
  <div class="sci-modal-dialog">
    <div class="sci-modal-content sci-modal-default">
      <div class="sci-modal-header">
          <div class="caption"></div>
      </div>
      <div class="sci-modal-body">
          <div class="wait"></div>
          <div class="dialogbody"></div>
          <div class="errors"></div>
      </div>
      <div class="sci-modal-footer">
          <button type="button" class="btn btn-default" id="cancel">Cancel</button>
          <button type="button" class="btn btn-default btn-primary" id="ok">OK</button>
      </div>
    </div>
  </div>
</div>
''';

  Element get dialog => root;
  Element get dialogModal => selector(".sci-modal-dialog");
  Element get dialogModalBody => selector(".sci-modal-body");
  Element get dialogBody => selector(".dialogbody");
  Element get wait => selector(".wait");
  Element get okButton => selector("#ok");
  Element get cancelButton => selector("#cancel");
  Element get captionElement => selector(".caption");
  Element? get errorsElement => root.querySelector(".errors");

  String get caption => "";
  set caption(String c) {
    captionElement.text = c;
  }

  void setCancelButtonDisplayText(String value) {
    cancelButton.innerText = value;
  }

  Element? backdrop;
  bool _isOpen = false;
  bool get hasError => errors.isNotEmpty;
  late List errors;
  late Completer<bool> _completer;

  void beLarge() {
    root.classes
      ..add("large-dialog")
      ..remove("full-dialog")
      ..remove('tall-dialog')
      ..remove('sci-modal-default');
  }

  void beTall() {
    root.classes
      ..add("tall-dialog")
      ..remove("full-dialog")
      ..remove("large-dialog")
      ..remove('sci-modal-default');
  }

  void beSmall() {
    root.classes
      ..add('sci-modal-default')
      ..remove('tall-dialog')
      ..remove("large-dialog")
      ..remove("full-dialog");
  }

  void noHeader() {
    selector('.sci-modal-header').remove();
  }

  void beFullScreen() {
    root.classes
      ..remove("large-dialog")
      ..add("full-dialog")
      ..remove('sci-modal-default');
  }

  void listenKeyBoard() {
    addSubscription('window_key_board', window.onKeyDown.listen((event) {
      if (event.keyCode == KeyCode.ENTER) onKeyboardOk();
    }));
  }

  _listen() {
    listenBtn();
    listenKeyBoard();
  }

  _unlisten() {
    unlistenKeyBoard();
    unlistenBtn();
  }

  void listenBtn() {
    addSubscription(selector("#ok"), selector("#ok").onClick.listen(onOkClick));
    if (root.querySelector("#cancel") != null) {
      addSubscription(
          "#cancel",
          selector("#cancel").onClick.listen((_) {
            cancel();
          }));
    }
  }

  onOkClick(_) => ok();

  void unlistenKeyBoard() {
    removeSubscriptionsSync('window_key_board');
  }

  void unlistenBtn() {
    removeSubscriptionsSync(selector("#ok"));
    removeSubscriptionsSync(selector("#cancel"));
  }

  void addDialogBody(Component component) => add(component, ".dialogbody");

  void hideOkButton() {
    okButton.style.visibility = "hidden";
  }

  void hideCancelButton() {
    cancelButton.style.display = "none";
  }

  void showOkButton() {
    okButton.style.visibility = "";
  }

  void showCancelButton() {
    cancelButton.style.display = "";
  }

  void bindValues() {
    if (captionElement.text!.isEmpty) {
      captionElement.text = caption;
    }
  }

  @override
  void created() {
    super.created();
    document.activeElement!.blur();
    root.focus();
  }

  Future<bool> open() => openDialog();

  String get backdropOpacity => "0.5";

  Future<bool> openDialog() {
    if (_isOpen) throw "$this already open";
    _completer = Completer<bool>();

    document.body!.children
        .add(htmlElement('<div class="modal-overlay"></div>'));

    addTo(document.body!);
    bindValues();
    _listen();
    _isOpen = true;
    removeErrors();
    onDialogOpened();

    var overlay = document.body!.querySelector('.modal-overlay');
    if (overlay != null) {
      addSubscription('.modal-overlay', overlay.onClick.listen((event) {
        cancel();
      }));
    }

    return _completer.future;
  }

  void onDialogOpened() {}

  void closeDialog(bool flag) {
    // removeErrors();
    // dialog.style.display = "none";
    removeSync();
    document.body!.querySelector('.modal-overlay')?.remove();
    _isOpen = false;

    dialogClosed(flag);

    if (!_completer.isCompleted) {
      _completer.complete(flag);
    }

    _completer = Completer();

    // remove().then((_) {
    //   var overlay = document.body!.querySelector('.modal-overlay');
    //   overlay?.remove();
    //   _isOpen = false;
    //   dialogClosed(flag);
    //   if (!_completer.isCompleted) {
    //     _completer.complete(flag);
    //   }
    //   _completer = Completer();
    // });
  }

  void dialogClosed(bool flag) {}

  void removeErrors() {
    errors = [];
    _drawErrors();
  }

  void addError(e) {
    errors.add(e);
    _drawErrors();
  }

  _drawErrors() {
    if (errorsElement != null) {
      removeAllChildrenFrom(errorsElement!);
      for (var e in errors) {
        String msg;
        if (e is ServiceError) {
          msg = e.reason;
        } else {
          msg = "$e";
        }
        var errorElement = Element.html(
            '<div class="alert alert-info" role="alert">$msg</div>');
        errorsElement!.children.add(errorElement);
      }
    }
  }

  bool okOnEnter = true;

  void onKeyboardOk() {
    if (okOnEnter) ok();
  }

  String get waitMessage => '';

  Future showWait(Future future) async {
    dialogBody.style.visibility = "hidden";

    var wait = WaitComponent(waitMessage);
    add(wait, ".wait");

    return future.whenComplete(() {
      dialogBody.style.visibility = "";
      wait.removeSync();
    });
  }

  void ok() {
    removeErrors();
    _unlisten();
    hideOkButton();
    showWait(validateOnOk().then((_) {
      if (!hasError) {
        closeDialog(true);
      } else {
        _listen();
        showOkButton();
      }
    }).catchError((e, st) {
      print(st);
      addError(e);
      _listen();
      showOkButton();
    }));
  }

  void cancel() => closeDialog(false);

  //use validateOnOk instead
  onOk() {}

  Future validateOnOk() {
    return Future.sync(() {
      if (onOkCallback != null) {
        return onOkCallback!();
      } else {
        onOk();
      }
    });
  }
}

class MessageDialog extends Dialog {
  late String htmlMessage;
  @override
  late String caption;
  bool canCancel = false;

  MessageDialog.error(e, [String? caption]) {
    if (caption == null) {
      this.caption = "Error";
    } else {
      this.caption = caption;
    }

    if (e is ServiceError) {
      htmlMessage =
          '<div class="alert alert-danger" role="alert">${formatHtmlReason(e.reason)}</div>';
    } else {
      htmlMessage =
          '<div class="alert alert-danger" role="alert">${formatHtmlReason(e.toString())}</div>';
    }
  }

  String formatHtmlReason(String reason) {
    var splitter = LineSplitter();
    return splitter.convert(reason).join('<br>');
  }

  MessageDialog.warning(this.caption, String msg) {
    htmlMessage = '<div class="alert alert-warning" role="alert">$msg</div>';
  }

  MessageDialog.info(this.caption, String msg) {
    htmlMessage =
        '<div class="alert alert-info" role="alert">${formatHtmlReason(msg)}</div>';
  }

  MessageDialog(this.caption, this.htmlMessage,
      {this.canCancel = false, OnOkCallback? onOkCallback}) {
    this.onOkCallback = onOkCallback;
  }

  @override
  void bindValues() {
    super.bindValues();
    if (!canCancel) cancelButton.style.display = "none";
    dialogBody.children.add(htmlElement(htmlMessage));
  }

  @override
  onOk() {}
}

class ErrorMessageDialog extends Dialog {
  static const String SearchMoreUrl = "https://tercen.com/search.html?q=";
  late String htmlMessage;
  @override
  String caption;

  ErrorMessageDialog(this.caption,
      {List<String>? dangers,
      List<String>? warnings,
      List<String>? infos,
      String? moreQuery}) {
    var sb = StringBuffer();
    sb.write('<div>');
    if (dangers != null) {
      for (var msg in dangers) {
        _add(sb, "alert-danger", "glyphicon-warning-sign", msg);
      }
    }
    if (warnings != null) {
      for (var msg in warnings) {
        _add(sb, "alert-warning", "glyphicon-warning-sign", msg);
      }
    }

    if (infos != null) {
      for (var msg in infos) {
        _add(sb, "alert-info", "glyphicon-info-sign", msg);
      }
    }

    if (moreQuery != null) {
      _add(sb, "alert-success", "glyphicon-question-sign",
          '<a href="$SearchMoreUrl$moreQuery" target="_blank" class="alert-link">Search for more info ...</a>');
    }

    sb.write('</div>');
    htmlMessage = sb.toString();
  }

  void _add(
      StringBuffer buffer, String alertClass, String iconClass, String msg) {
    buffer.write(
        '<div class="alert $alertClass" role="alert"><h4 style="display:inline;margin-right:10px;"><span class="glyphicon $iconClass" aria-hidden="true"></span></h4> $msg</div>');
  }

  @override
  void bindValues() {
    super.bindValues();
    cancelButton.style.display = "none";
    dialogBody.children.add(htmlElement(htmlMessage));
  }

  @override
  onOk() {}
}
