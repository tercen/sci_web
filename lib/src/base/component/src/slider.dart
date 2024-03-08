part of sci_component;

// 25, 33, 50, 67, 75, 80, 90, 100, 110, 125, 150, 175, 200, 250, 300
class SliderComponent extends Component {
  @override
  Iterable<String> get rootClasses => ['SliderComponent'];

  SliderComponent(Value<double> model) {
    var minus = IconComponent.minus();
    var plus = IconComponent.add();

    addToRoot(minus);
    addToRoot(TextComponent(model
        .convert(get: (value) => '${(value * 100.0).round()}%')
        .asReadOnly()));
    addToRoot(plus);

    addSub(minus.root.onClick.listen((_) {
      if (model.value > 0.1) {
        model.value = model.value - 0.1;
      }
    }));

    addSub(plus.root.onClick.listen((_) {
      model.value += 0.1;
    }));
  }
}
