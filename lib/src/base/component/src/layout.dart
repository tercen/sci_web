part of sci_component;

//import 'dart:html';
//import 'package:sci_web_component2/src/component/component/component.dart';
//import 'package:sci_web_component2/src/model/app_router.dart';
//import "package:synchronized/synchronized.dart" as synchro;
typedef DeferComponentFactory<T extends Component> = FutureOr<T> Function();

class CollapseComponent2 extends Component {
  @override
  Iterable<String> get rootClasses =>
      ['CollapseComponent', 'CollapseComponent2'];
  ValueHolder<List<String>> icon;
  final DeferComponent _defered;

  Value<bool> state;

  String iconOpen;
  String iconClose;

  CollapseComponent2(String name, this.state, DeferComponentFactory factory,
      {this.iconOpen = 'icon-left', this.iconClose = 'icon-right'})
      : icon = ValueHolder([state.value ? iconOpen : iconClose]),
        _defered = DeferComponent(factory),
        super() {
    var iconComp = IconComponent(icon)..root.style.cursor = 'pointer';

    addToRoot(ListLayoutComponent([iconComp], cssClasses: ["icon-container"]));

    addToRoot(_defered);

    addSubscription(state, state.onChange.listen(_onStateChange));
    addSubscription(iconComp.root, iconComp.root.onClick.listen(_onIconClick));

    _onStateChange(null);
  }

  void _onStateChange(_) {
    if (state.value) {
      _defered.invalidate();
      root.classes.add(("open"));
      // root.style.flex = "1";
      icon.value = [iconOpen];
    } else {
      root.classes.remove(("open"));
      // root.style.flex = "";
      _defered.removeDeferred();
      icon.value = [iconClose];
    }
  }

  void _onIconClick(_) {
    state.value = !state.value;
  }
}

class CollapseComponent extends DeferComponent {
  @override
  Iterable<String> get rootClasses => ['CollapseComponnent'];

  @override
  String get template => '''
  <div>
    <div class="name"></div>
    <div class="component"></div>
  </div>
  ''';

  ValueHolder<List<String>> icon;
  bool propagateEvents;

  CollapseComponent(String name, DeferComponentFactory factory,
      {this.propagateEvents = false})
      : icon = ValueHolder(['icon-up']),
        super(factory) {
    root.style.display = '';

    add(IconComponent(icon), '.name');
    add(TextComponent(name), '.name');

    selector('.name').style.cursor = 'pointer';

    addSubscription(
        selector('.name'),
        selector('.name').onClick.listen((event) {
          invalidate();
          show(icon.value.contains('icon-up'));
          icon.value =
              icon.value.contains('icon-up') ? ['icon-down'] : ['icon-up'];
        }));
  }
}

class DeferComponent<T extends Component> extends Component {
  DeferComponentFactory<T> factory;
  T? component;
  FutureOr<T>? _futOrComp;
  final bool removeOnHide;

  DeferComponent(this.factory, {this.removeOnHide = true}) {
    root.style.display = 'none';
  }

  Future<T> getComponent() async {
    if (component != null) return component!;
    _futOrComp ??= _getComponent();
    return await _futOrComp!;
  }

  Future<T> _getComponent() async {
    var _futComp = factory();
    var comp = await _futComp;
    component = comp;
    comp.addTo(root, where: 'beforeBegin');
    addSubscription('', comp.onEvent.listen(_onComponentTriggerEvent));
    return comp;
  }

  void _onComponentTriggerEvent(ComponentEvent evt) {
    triggerEvent(evt);
  }

  @override
  void invalidate() {
    if (component == null) {
      getComponent();
    } else {
      component!.invalidate();
    }
  }

  @override
  void removeSync() {
    var old = component;
    component = null;
    _futOrComp = null;

    if (old != null) {
      removeSubscriptionsSync('');
      old.removeSync();
    }

    super.removeSync();
  }

  Future removeDeferred() async {
    var futOrComp = _futOrComp;
    component = null;
    _futOrComp = null;
    if (futOrComp == null) return;

    synchronized(() async {
      var comp = await futOrComp;
      comp.removeSync();
      removeSubscriptionsSync('');
      component = null;
    });
  }

  @override
  void show(bool b) {
    if (b) {
      getComponent().then((value) => value.show(b));
    } else {
      if (removeOnHide) {
        removeDeferred();
      } else if (_futOrComp != null) {
        getComponent().then((value) => value.show(b));
      }
    }
  }

  // @override
  // void show(bool b) {
  //   print("DeferComponent -- show $b -- $component");
  //   synchronized(() async {
  //     if (b) {
  //       await getComponent().then((value) => value.show(b));
  //     } else {
  //       await removeDeferred();
  //     }
  //   });
  // }
}

class TabComponent<T> extends Component {
  @override
  Iterable<String> get rootClasses => ['TabComponent', 'horizontal'];

  @override
  String get template => '''
    <div>
      <div class="buttons-container">
        <div class="open-close-container"></div>
        <div class="buttons"></div>
      </div>
      <div class="component"></div>
    </div>
    ''';

  Map<T, Component> _components;
  Map<T, Element> _buttons;
  Map<T, String> _buttonsUrls;

  late Value<T?> _currentTabModel;

  Value<T?> get currentTabModel => _currentTabModel;

  T? get currentTab => _currentTabModel.value;

  String iconOpen;
  String iconClose;

  Value<bool> state;
  ValueHolder<List<String>> icon;

  factory TabComponent(
      {Value<T?>? model,
      Value<bool>? state,
      String iconOpen = 'icon-left',
      String iconClose = 'icon-right',
      bool showOpenClose = false}) {
    return TabComponent._(
        model: model,
        state: state ?? ValueHolder(true),
        iconOpen: iconOpen,
        iconClose: iconClose,
        showOpenClose: showOpenClose);
  }

  TabComponent._(
      {Value<T?>? model,
      required this.state,
      this.iconOpen = 'icon-left',
      this.iconClose = 'icon-right',
      bool showOpenClose = false})
      : icon = ValueHolder([state.value ? iconOpen : iconClose]),
        _components = {},
        _buttons = {},
        _buttonsUrls = {},
        super() {
    if (model != null) {
      _currentTabModel = model;
    } else {
      _currentTabModel = ValueHolder(null);
    }

    addSubscription(_currentTabModel, _currentTabModel.onChange.listen((event) {
      onCurrentTabChanged();
    }));

    var iconComp = IconComponent(icon)..root.style.cursor = 'pointer';

    addSubComponent(iconComp, element: selector('.open-close-container'));

    selector('.open-close-container').style.display =
        showOpenClose ? '' : 'none';

    addSubscription(state, state.onChange.listen(_onStateChange));
    addSubscription(iconComp.root, iconComp.root.onClick.listen(_onIconClick));

    _onStateChange(null);
  }

  void _onStateChange(_) {
    if (state.value) {
      invalidate();
      root.classes.add(("tab-open"));
      root.classes.remove(("tab-close"));
      // root.style.flex = "1";
      icon.value = [iconOpen];
    } else {
      root.classes.remove(("tab-open"));
      root.classes.add(("tab-close")); // root.style.flex = "";
      // _defered.removeDeferred();
      icon.value = [iconClose];
    }
  }

  void _onIconClick(_) {
    state.value = !state.value;
  }

  bool containsTab(T name) => _buttons.containsKey(name);

  Component? get currentComponent =>
      currentTab == null ? null : _components[currentTab!];

  Component? getComponent(T name) => _components[name];

  void setVertical(bool b) {
    if (b) {
      root.classes
        ..remove('horizontal')
        ..add('vertical');
    } else {
      root.classes
        ..remove('vertical')
        ..add('horizontal');
    }
  }

  Element get buttonGroup => selector(".buttons");
  Element get componentContainer => selector(".component");
  Element get navTabsContainer => selector(".buttons");

  @override
  void invalidate() {
    currentComponent?.invalidate();
  }

  void showNavTabs(bool b) {
    navTabsContainer.style.display = b ? '' : 'none';
  }

  void addTab(T name, Component component,
      {String? url, bool showIfFirst = true, bool propagateEvents = true}) {
    bool isFirst = _components.isEmpty;
    if (_components[name] != null) {
      removeSubComponentSync(_components[name]!);
      _removeButton(name);
    }
    _components[name] = component;
    //to ensure that the component will be released
    addSubComponent(component, propagateEvents: propagateEvents);

    if (url != null) _buttonsUrls[name] = url;

    _drawBtn();

    if (showIfFirst && isFirst) {
      showCurrentTab();
    }

    if (name == currentTabModel.value) {
      _ensureCurrentTabVisibility();
    }
  }

  void removeTab(T name) {
    if (_components[name] != null) {
      removeSubComponentSync(_components[name]!);
    }
    _removeButton(name);

    T? tabToShow;
    var entries = _components.entries.toList();
    var index = entries.toList().indexWhere((element) => element.key == name);
    if (index > 0) {
      tabToShow = entries[index - 1].key;
    } else if (index + 1 < entries.length) {
      tabToShow = entries[index + 1].key;
    }
    _components.remove(name);

    if (currentTab == name && tabToShow != null) {
      navigateTab(tabToShow);
    }
  }

  void _removeButton(T name) {
    if (_buttons[name] != null) {
      removeSubscriptionsSync(_buttons[name]);
      _buttons[name]!.remove();
      _buttons.remove(name);
    }
  }

  void _drawBtn() {
    _components.keys
        .where((name) => !_buttons.containsKey(name))
        .forEach((name) {
      String? href = '';

      if (_buttonsUrls[name] != null) href = _buttonsUrls[name];

      var buttonContainer =
          Element.html('<a class="tab-btn" href="$href">${name.toString()}</>');

      _buttons[name] = buttonContainer;

      if (currentTab == name) {
        buttonContainer.classes.add('active');
      }

      addSubscription(buttonContainer, buttonContainer.onClick.listen((evt) {
        if (_buttonsUrls[name] == null) {
          onButtonClick(name);
          evt.preventDefault();
          evt.stopImmediatePropagation();
        }
      }));

      buttonGroup.children.add(buttonContainer);
    });

    if (currentTab != null) {
      if (_buttons[currentTab!] != null) {
        var buttonContainer = _buttons[currentTab!]!;
        var active = buttonContainer.parent!.querySelector(".active");
        if (active != null) active.classes.remove("active");
        buttonContainer.classes.add('active');
      } else {
        throw 'current tab button $currentTab is null';
        // print('current tab button $currentTab is null');
      }
    }
  }

  bool get hasCurrentTab => currentTab != null;

  void showCurrentTab() {
    if (currentTab == null && _components.isNotEmpty) {
      showTab(_components.keys.toList().first);
    }
  }

  void onButtonClick(T name) {
    if (currentTab == name) return;
    showTab(name);
  }

  void onCurrentTabChanged() {
    _ensureCurrentTabVisibility();
    triggerEvent(ComponentEvent.fromData(this, {}));
  }

  void _ensureCurrentTabVisibility() {
    _drawBtn();
    var tab = currentTab;
    if (tab == null) return;

    var currentComp = _components[tab];
    if (currentComp == null) return;

    for (var c
        in _components.values.where((element) => element != currentComp)) {
      c.show(false);
    }

    var index = _components.values.toList().indexOf(currentComp);

    var comp = selector('.component')
        .children
        .firstWhereOrNull((each) => each.classes.contains('.tab$index'));

    if (comp == null) {
      currentComp.root.classes.add('tab$index');
      add(currentComp, ".component");
    }

    currentComp.show(true);
    currentComp.invalidate();
  }

  void showTab(T name) {
    if (currentTab == name) return;
    _currentTabModel.value = name;
  }

  void navigateTab(T name) {
    print("navigateTab $name");

    if (currentTab == name) {
      print("navigateTab currentTab == name");

      return;
    }

    print("navigateTab click ${_buttons[name]}");
    _buttons[name]!.click();
  }

  void showTabComponent(Component comp) {
    _components.forEach((key, value) {
      if (value == comp) showTab(key);
    });
  }

  void showTabIndex(int index) {
    if (index < _components.length) {
      var key = _components.keys.elementAt(index);
      showTab(key);
    }
  }
}

class BorderLayoutComponent extends Component {
  //
  @override
  Iterable<String> get rootClasses => ['BorderLayoutComponent'];

  @override
  String get template => '''
<div>
  <div class="left">
    <div class="left-btn"></div>
    <div class="left-container"></div>
  </div>
  <div class="central-container"></div>
</div>
''';

  BorderLayoutComponent(Component left, Component central,
      {bool propagateEvents = false, Component? centralBottom}) {
    //
    add(left, ".left-container", propagateEvents: propagateEvents);
    add(central, ".central-container", propagateEvents: propagateEvents);

    if (centralBottom != null) {
      add(centralBottom, ".central-container",
          propagateEvents: propagateEvents);
    }

    var button = selector(".left-btn");

    addSubscription(
        button,
        button.onClick
            .listen((_) => selector(".left").classes.toggle("bl-close")));
  }
}

class ListLayoutComponent<T extends Component> extends Component {
  @override
  Iterable<String> get rootClasses => ['ListLayoutComponent'];

  @override
  String get template => '''<div class="components"></div>''';

  bool isVertical;
  bool propagateEvents;

  ListLayoutComponent.row(Iterable<T> components,
      {List<String>? cssClasses,
      bool nowrap = false,
      this.propagateEvents = false})
      : isVertical = false {
    if (cssClasses != null) {
      root.classes.addAll(cssClasses);
    }
    root.classes
        .add(isVertical ? "FlexBoxC" : (nowrap ? "FlexBoxRNW" : "FlexBoxR"));
    for (var comp in components) {
      addToLayout(comp);
    }
  }

  ListLayoutComponent(Iterable<T> components,
      {this.isVertical = true,
      List<String>? cssClasses,
      this.propagateEvents = false}) {
    if (cssClasses != null) {
      root.classes.addAll(cssClasses);
    }
    root.classes.add(isVertical ? "FlexBoxC" : "FlexBoxR");
    for (var comp in components) {
      addToRoot(comp, propagateEvents: propagateEvents);
    }
  }

  void addToLayout(T comp) {
    addToRoot(comp, propagateEvents: propagateEvents);
  }
}

class DynamicLayout {
  String relativePosition;
  Element relativeElement;
  Element positionAbsoluteElement;

  DynamicLayout(this.relativeElement, this.positionAbsoluteElement,
      {this.relativePosition = 'bottomLeft'}) {
    window.onResize.listen(_onBodyResize);
  }

  _onBodyResize(Event evt) {
    layout();
  }

  layout() {
    var relativeRec = relativeElement.getBoundingClientRect();

    num top = 0;
    num left = 0;

    var rec = positionAbsoluteElement.getBoundingClientRect();

    if (relativePosition == 'bottomRight') {
      top = relativeRec.bottom - rec.height;
      left = relativeRec.right - rec.width;
    } else if (relativePosition == 'bottomLeft') {
      top = relativeRec.bottom - rec.height;
      left = relativeRec.left;
    } else if (relativePosition == 'topRight') {
      top = relativeRec.top;
      left = relativeRec.right - rec.width;
    }

    positionAbsoluteElement.style.top = '${top.round().toString()}px';
    positionAbsoluteElement.style.left = '${left.round().toString()}px';
  }
}
