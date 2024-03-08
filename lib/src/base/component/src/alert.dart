part of sci_component;

class Alert extends Component {
  @override
  Iterable<String> get rootClasses =>
      ['AlertComponent', 'sci-alert-position-$position'];

  @override
  String get template => '''
    <div>
      <div class="sci-alert-content">
        <div class="sci-alert-title"></div>
        <div class="sci-alert-text"></div>
      </div>
    </div>
  ''';

  final String _htmlMessage;
  String? title;
  String position;
  String id;
  int delay = 5;

  Element get alert => root;

  Alert.info(this._htmlMessage,
      {this.title, this.position = "top", this.id = ""}) {
    root.classes.add("sci-alert-info");
  }

  Alert.warning(this._htmlMessage,
      {this.title, this.position = "top", this.id = ""}) {
    root.classes.add("sci-alert-warning");
  }

  Alert.danger(this._htmlMessage,
      {this.title, this.position = "top", this.id = ""}) {
    delay = 0;
    root.classes.add("sci-alert-danger");
  }

  Alert.success(this._htmlMessage,
      {this.title, this.position = "top", this.id = ""}) {
    root.classes.add("sci-alert-success");
  }

  void display() {
    if (delay > 0) {
      Future.delayed(Duration(seconds: delay)).then((value) => removeSync());
    }

    root.children.add(htmlElement(
        '<div class="sci-alert-close" id="sci-alert-close$id"><i class="fa fa-times"></i></div>'));

    addSub(selector('#sci-alert-close$id').onClick.listen((_) {
      removeSync();
    }));

    if (title != null) {
      selector('.sci-alert-title').innerHtml = '<b>$title</b>';
    }

    selector('.sci-alert-text').innerHtml = _htmlMessage;

    var container = querySelector('#sci-alerts-$position');
    if (container != null) {
      addTo(container);
    } else {
      addTo(document.body!);
    }
  }
}
