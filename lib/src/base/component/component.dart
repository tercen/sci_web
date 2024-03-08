library sci_component;

export 'src/image.dart';
export 'package:sci_base/value.dart';

import 'dart:collection';
import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:markdown/markdown.dart' as md;
import 'package:collection/collection.dart' show IterableExtension;
import 'package:logging/logging.dart';

import 'package:synchronized/extension.dart';
import 'package:synchronized/synchronized.dart' as sync;

import 'package:sci_base/sci_base.dart' as base;
import 'package:sci_base/value.dart';
import 'package:sci_base/subscription.dart';
import 'package:sci_base/property.dart';

// import 'package:sci_util/rgb.dart' as sci_rgb;

import '../../../sci_web.dart';
import './src/lazy_codemirror.dart' deferred as lazy_code_mirror;
import './src/lazy_install_codemirror.dart' as lazy_install_codemirror;
import 'package:sci_http_client/error.dart';

part 'src/alert.dart';
part 'src/form_dialog.dart';
part 'src/dialog.dart';
part 'src/wizard.dart';
part 'src/wizard2.dart';
part 'src/list.dart';
part 'src/select.dart';
part 'src/error.dart';
part 'src/checkbox_group.dart';
part 'src/progress.dart';
part 'src/layout.dart';
part 'src/events.dart';
part 'src/base_component.dart';
part 'src/tool_tip.dart';
part 'src/input.dart';
part 'src/slider.dart';

class OSUtil {
  static String get OSName {
    var OSName = "Unknown OS";

    try {
      if (window.navigator.appVersion.contains("Win")) OSName = "Windows";
      if (window.navigator.appVersion.contains("Mac")) OSName = "MacOS";
      if (window.navigator.appVersion.contains("X11")) OSName = "UNIX";
      if (window.navigator.appVersion.contains("Linux")) OSName = "Linux";
      if (window.navigator.appVersion.contains("iPhone")) OSName = "iOS";
      if (window.navigator.appVersion.contains("Android")) {
        OSName = "Android";
      }
    } catch (_) {
      //
    }

    return OSName;
  }

  static bool get isMobile =>
      OSName == "iOS" || OSName == "Android" || OSName == "Unknown OS";
}

class AbstractComponent {
  Iterable<String> get rootClasses => [];
}

typedef AsyncInvalidateFn = Future Function([dynamic evt]);

class AsyncInvalidate {
  final dynamic evt;
  bool _isInvalidating;
  int _nCallsWhileInvalidating;
  final AsyncInvalidateFn _invalidate;
  Future? _invalidateFuture;

  AsyncInvalidate(this._invalidate, this.evt)
      : _isInvalidating = false,
        _nCallsWhileInvalidating = 0;

  void invalidate() {
    if (_isInvalidating) {
      _nCallsWhileInvalidating++;
      return;
    }
    _invalidateFuture ??= Future.delayed(Duration(seconds: 0), _callInvalidate);
  }

  Future _callInvalidate() async {
    _isInvalidating = true;
    await _invalidate(evt);
    while (_nCallsWhileInvalidating > 0) {
      _nCallsWhileInvalidating = 0;
      await _invalidate(evt);
    }
    _isInvalidating = false;
    _invalidateFuture = null;
  }
}

class Component extends AbstractComponent with SubscriptionHelper {
  static final Logger log = Logger("Component");
  static final NodeValidatorComp VALIDATOR = NodeValidatorComp();

  late Element root;
  final Map<String, HashSet<Component>> _children;
  AsyncInvalidate? _asyncInvalidate;

  @override
  Iterable<String> get rootClasses => ['Component'];
  Iterable<String> get childrenClasses => [];

  Logger get logger => log;

  // SciRouter get SciRouter() => SciRouter();

  Component({List<String>? cssClasses}) : _children = HashMap() {
    if (template != null) {
      root = Element.html(template, validator: VALIDATOR);
    } else {
      root = createRoot();
      createChildrenClasses(childrenClasses.toList());
    }
    root.classes.addAll(rootClasses);
    if (cssClasses != null) {
      root.classes.addAll(cssClasses);
    }
    // if (Uri.base.queryParameters.containsKey('style')) {
    //   root.classes.add(Uri.base.queryParameters['style']!);
    // }
    created();
  }

  void asyncInvalidate([dynamic evt]) {
    _asyncInvalidate ??= AsyncInvalidate(asyncDraw, evt);
    _asyncInvalidate!.invalidate();
  }

  Future asyncDraw([dynamic evt]) async {}

  void ensureScroll() {
    ensureScrollOn(root);
  }

  void ensureScrollOn(Element container) {
    container.style.height = '100%';
    container.style.overflow = 'auto';
    _ensureHeightSettingForScroll(container);
  }

  void _ensureHeightSettingForScroll(Element container) {
    if (container.tagName == 'BODY') return;
    var parent = container.parent;
    if (parent == null) return;

    var parentStyle = parent.getComputedStyle();

    if (parentStyle.display == 'flex') {
      if (parentStyle.flexDirection == 'row') {
        container.style.height = '100%';
      } else {
        container.style.flexGrow = '1';
        container.style.minHeight = '0';
      }
    } else {
      // throw 'parent is not flex on container.classes ${container.classes.join(",")} -- parent.classes ${parent.classes.join(",")}';
    }

    _ensureHeightSettingForScroll(parent);
  }

  Dialog toDialog() => Dialog()..addDialogBody(this);

  void addToolTip(
      {String? selectors,
      Component? content,
      String? textContent = '??',
      double opacity = 0.5,
      bool isStatic = false,
      String? position}) {
    if (getToolTip(selectors: selectors) != null) {
      removeToolTip(selectors: selectors);
    }
    var element = selectors != null ? selector(selectors) : root;
    addSubComponent(ToolTip(element,
        content: content,
        textContent: textContent,
        opacity: opacity,
        isStatic: isStatic,
        position: position ?? ''));
  }

  ToolTip? getToolTip({String? selectors}) {
    var element = selectors != null ? selector(selectors) : root;
    return subComponents
        .whereType<ToolTip>()
        .firstWhereOrNull((toolTip) => toolTip.element == element);
  }

  void removeToolTip({String? selectors}) {
    var element = selectors != null ? selector(selectors) : root;
    var toolTips = subComponents
        .whereType<ToolTip>()
        .where((toolTip) => toolTip.element == element);

    for (var toolTip in toolTips) {
      removeSubComponentSync(toolTip);
    }
  }

  void addClass(String cssClass) => root.classes.add(cssClass);

  void bindText(base.Base object, String propertyName, {String? selector}) {
    selector ??= '.${propertyName.replaceAll('.', '-')}';

    Element element = selector == 'root' ? root : this.selector(selector);

    element.text = propertyName
        .split('.')
        .fold(object, (dynamic obj, prop) => obj.get(prop))
        .toString();

    addSubscription(object, object.onChange.listen((_) {
      element.text = propertyName
          .split('.')
          .fold(object, (dynamic obj, prop) => obj.get(prop))
          .toString();
    }));
  }

  Element createRoot() => DivElement();

  Component? selectorChild([String selectors = 'root']) =>
      _children[selectors] == null || _children[selectors]!.isEmpty
          ? null
          : _children[selectors]!.first;

  T selector<T extends Element>(String selectors) =>
      root.querySelector(selectors) as T;

  void _addChild(String selector, Component child,
      {bool propagateEvents = false}) {
    var set = _children.putIfAbsent(selector, () => HashSet<Component>());
    set.add(child);
    if (propagateEvents) {
      addSubscription(child, child.onEvent.listen(_onChildTriggerEvent));
    }
  }

  void _onChildTriggerEvent(ComponentEvent evt) {
    triggerEvent(evt);
  }

  void _removeChild(Component child) {
    for (var set in _children.values) {
      set.remove(child);
    }
  }

  // bool get isInitialized => _isInitialized;

  final StreamController<ComponentEvent> _controller =
      StreamController<ComponentEvent>.broadcast();

  Stream<ComponentEvent> get onEvent => _controller.stream;

  String? get template => null;

  // Future synchronize(dynamic lock, computation(), {timeout: null}) {
  //
  //   return sync.synchronized(lock, computation, timeout: timeout);
  // }

  Iterable<Component> get allSubComponents sync* {
    for (var components in _children.values) {
      yield* components;
      for (var subC in components) {
        yield* subC.allSubComponents;
      }
    }
  }

  List<Component> get subComponents => _children.values
      .fold<List<Component>>([], (list, set) => list..addAll(set));

  void releaseSync() {
    releaseSubscriptionsSync();
    for (var c in subComponents) {
      c.releaseSync();
    }
  }

  // Future release() async {
  //   releaseSync();
  //   // return Future.wait(
  //   //     [releaseSubscriptions(), ...subComponents.map((c) => c.release())]);
  // }

  void addSubComponent(Component child,
      {Element? element,
      String where = 'beforeEnd',
      bool propagateEvents = false}) {
    if (element != null) {
      child.addTo(element, where: where);
    }
    _addChild('root', child, propagateEvents: propagateEvents);
  }

  // Future _removeSubComponents(List<Component> list) {
  //   var list = List<Component>.from(subComponents);
  //   for (var comp in list) {
  //     _removeChild(comp);
  //   }
  //
  //   return Future(() async {
  //     for (var comp in list) {
  //       await removeSubscriptions(comp);
  //       await comp.remove();
  //     }
  //   });
  // }

  void _removeSubComponentsSync(List<Component> list) {
    for (var comp in list) {
      _removeChild(comp);
    }

    for (var comp in list) {
      removeSubscriptionsSync(comp);
      comp.removeSync();
    }
  }

  // Future removeSubComponent(Component comp) {
  //   _removeChild(comp);
  //   return Future.wait([comp.remove(), removeSubscriptions(comp)]);
  // }

  // Future removeSubComponent(Component comp) async {
  //   _removeSubComponentsSync([comp]);
  //   // return  _removeSubComponents(List<Component>.from(subComponents));
  // }

  void removeSubComponentSync(Component comp) {
    _removeSubComponentsSync([comp]);
  }

  // Future removeSubComponents() async {
  //   removeSubComponentsSync();
  //   // return _removeSubComponents(List<Component>.from(subComponents));
  // }

  void removeSubComponentsSync() {
    return _removeSubComponentsSync(List<Component>.from(subComponents));
  }

  void removeSync() => basicRemoveSync();

  void basicRemoveSync({bool removeRoot = true}) {
    if (removeRoot) {
      root.remove();
    } else {
      removeAllChildrenFrom(root);
    }
    removeSubComponentsSync();
    releaseSync();
  }

  // Future basicRemove({bool removeRoot = true}) async {
  //   basicRemoveSync(removeRoot: removeRoot);
  //   // if (removeRoot) {
  //   //   root.remove();
  //   // } else {
  //   //   removeAllChildrenFrom(root);
  //   // }
  //   // return Future.wait([removeSubComponents(), release()]);
  // }

  T? selectorComp<T extends Component?>(String selectors) {
    var el = selector(selectors);
    return subComponents.firstWhereOrNull((comp) => comp.root == el) as T?;
  }

  //afterBegin, beforeBegin, beforeEnd, afterEnd
  void addToRoot(Component child,
      {bool propagateEvents = false, String where = 'beforeEnd'}) {
    child.addTo(root, where: where);
    _addChild('root', child, propagateEvents: propagateEvents);
  }

  //afterBegin, beforeBegin, beforeEnd, afterEnd
  void add(Component child, String selectors,
      {bool propagateEvents = false, String where = 'beforeEnd'}) {
    var el = root.querySelector(selectors);
    if (el == null) {
      throw ArgumentError.value(
          selectors, 'add', 'cannot find selector $selectors');
    }
    child.addTo(el, where: where);
    if (propagateEvents) {
      addSubscription(child, child.onEvent.listen(triggerEvent));
    }

    _addChild(selectors, child, propagateEvents: false);
  }

  void removeAllChildrenFrom(Element el) {
    el.children.clear();
    // while (el.children.isNotEmpty) {
    //   el.children.removeLast();
    // }
  }

  void removeChild(Element el) {
    removeSubscriptionsSync(el);
    removeAllChildrenFrom(el);
    el.remove();
  }

  void triggerEvent(ComponentEvent event) => _controller.add(event);

  Element htmlElement(String html) =>
      Element.html(html, validator: NodeValidatorComp());

  void createChildrenClasses(List<String> classes) {
    for (var c in classes) {
      root.children.add(DivElement()..classes.add(c));
    }
  }

  void created() {}

  bool _hasBodyHasParent() {
    var parent = root.parent;
    while (parent != null && parent.tagName != 'BODY') {
      parent = parent.parent;
    }

    if (parent == null) return false;
    return parent.tagName == 'BODY';
  }

  void invalidate() {
    for (var each in subComponents) {
      each.invalidate();
    }
  }

  //afterBegin, beforeBegin, beforeEnd, afterEnd
  void addTo(Element el, {String where = 'beforeEnd'}) {
    el.insertAdjacentElement(where, root);
    _onInserted();
  }

  void inserted() {}

  void _onInserted() {
    inserted();
    if (_hasBodyHasParent()) {
      _onDocumentInserted();
    }
  }

  void _onDocumentInserted() {
    onDocumentInserted();
    for (var element in subComponents) {
      element._onDocumentInserted();
    }
  }

  void onDocumentInserted() {}

  void insertInto(Element el, {String where = 'beforeEnd'}) {
    addTo(el, where: where);
  }

  void show(bool b) {
    root.style.display = b ? '' : 'none';
  }

  void hide(bool b) => show(!b);

  void visibilityHidden(flag) {
    root.style.visibility = flag ? 'hidden' : '';
  }
}

class NodeValidatorComp implements NodeValidator {
  @override
  bool allowsAttribute(Element element, String attributeName, String value) =>
      true;

  @override
  bool allowsElement(Element element) => true;
}
