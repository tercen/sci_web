part of sci_component;

class ToolTip extends Component {
  @override
  Iterable<String> get rootClasses => ['ToolTip'];
  @override
  String get template => '''
<div class="tooltip bottom">
    <div class="tooltip-arrow"></div>
    <div class="tooltip-inner"></div>
</div>
''';

  Element element;
  late Component contentComponent;
  bool isStatic;
  String position;

  ToolTip(this.element,
      {Component? content,
      String? textContent = '??',
      double opacity = 0.5,
      this.isStatic = false,
      this.position = ''}) {
    root
      ..style.zIndex = "10000"
      ..style.opacity = "0.0"
      ..style.visibility = 'visible'
      ..style.transition = 'opacity 2s ease-out 0.2s';

    element.children.add(root);

    addSubscription(element, element.onMouseOver.listen((evt) {
      draw();
      root
        ..style.opacity = "$opacity"
        ..style.visibility = 'visible';
    }));
    addSubscription(element, element.onMouseOut.listen((evt) {
      root
        ..style.opacity = "0.0"
        ..style.visibility = 'hidden';
    }));

    contentComponent = content ?? TextComponent(textContent);

    add(contentComponent, '.tooltip-inner');

    draw();
  }

  draw() {
    if (position == "right") {
      var x = (element.getBoundingClientRect().left +
              element.getBoundingClientRect().right) /
          2;

      var width = contentComponent.root.getBoundingClientRect().width;
      var height = contentComponent.root.getBoundingClientRect().height;

      root.style.left = "${(x - (width / 2)).round() - 8}px";
      root.style.left =
          "${(x + element.getBoundingClientRect().width + 5).round()}px";

      root.style.top =
          "${element.getBoundingClientRect().bottom - height + window.scrollY}px";
    } else {
      if (!isStatic) {
        var x = (element.getBoundingClientRect().left +
                element.getBoundingClientRect().right) /
            2;

        var width = contentComponent.root.getBoundingClientRect().width;

        root.style.left = "${(x - (width / 2)).round() - 8}px";

        root.style.top =
            "${element.getBoundingClientRect().bottom + window.scrollY + 5}px";
      }
    }
  }
}
