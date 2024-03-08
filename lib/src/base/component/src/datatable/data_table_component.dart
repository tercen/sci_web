import 'dart:html';

import '../../component.dart';

class DataTableComponent extends ValueComponent<DataTable> {
  @override
  Iterable<String> get rootClasses => ['DataTableComponent'];

  DataTableComponent(Value<DataTable> value) : super(value) {
    addSubscription(value, value.onChange.listen((event) {
      _draw(event);
    }));
    _draw(value.value);
  }

  void _draw(DataTable tbl) {
    removeSubscriptionsSync('cells');
    removeSubscriptionsSync('cell');
    removeAllChildrenFrom(root);
    var cells = Element.div()
      ..classes.add('cells')
      ..style.gridTemplateColumns =
          '40px repeat(${tbl.columns.length}, calc((100% - 50px) / ${tbl.columns.length}))'
      ..style.gridTemplateRows = 'repeat(${tbl.nRows + 1}, 25px)';

    var cellSpacer = Element.div()..classes.add('cells__spacer');
    cells.children.add(cellSpacer);

    addSubscription(
        'cells', root.onMouseEnter.listen((e) => onHeaderMouseEnter(null, e)));
    addSubscription(
        'cells', root.onMouseLeave.listen((e) => onHeaderMouseLeave(null, e)));
    addSubscription(
        'cells', root.onDragOver.listen((e) => onHeaderDragOver(null, e)));
    addSubscription(
        'cells', root.onDragLeave.listen((e) => onHeaderDragLeave(null, e)));
    addSubscription('cells', root.onDrop.listen((e) => onHeaderDrop(null, e)));

    for (var col in tbl.columns) {
      var cell = Element.html('<div class="cells__alphabet">'
          '<div class="cells__alphabet__content">${col.name}</div>'
          '<div class="cells__alphabet__menu">&#x2715;</div>'
          '</div>');

      addSubscription(
          'cell', cell.onMouseEnter.listen((e) => onHeaderMouseEnter(col, e)));
      addSubscription(
          'cell', cell.onMouseLeave.listen((e) => onHeaderMouseLeave(col, e)));
      addSubscription(
          'cell', cell.onDragOver.listen((e) => onHeaderDragOver(col, e)));
      addSubscription(
          'cell', cell.onDragLeave.listen((e) => onHeaderDragLeave(col, e)));
      addSubscription('cell', cell.onDrop.listen((e) => onHeaderDrop(col, e)));

      var menu = cell.querySelector('.cells__alphabet__menu')!;

      addSubscription(
          'cell', menu.onClick.listen((e) => onHeaderMenuClick(col, e)));

      cells.children.add(cell);
    }

    for (var ri = 0; ri < tbl.nRows; ri++) {
      var cell = Element.div()
        ..classes.add('cells__number')
        ..text = (ri + 1).toString();
      cells.children.add(cell);
    }

    for (var ri = 0; ri < tbl.nRows; ri++) {
      for (var col in tbl.columns) {
        if (col.isEditable) {
          var cell = InputElement()
            ..classes.add('cells__input')
            ..value = col.getValue(ri);

          cells.children.add(cell);

          addSubscription('cell',
              cell.onKeyUp.listen((e) => onCellValueChange(col, ri, e)));
        } else {
          var cell = DivElement()
            ..classes.add('cells__text')
            ..text = col.getValue(ri);

          cells.children.add(cell);
        }
      }
    }

    root.children.add(cells);
  }

  void onCellValueChange(DataColumn column, int ri, KeyboardEvent e) {
    var input = e.target as InputElement;
    column.setValue(ri, input.value!);
  }

  void onHeaderMenuClick(DataColumn column, MouseEvent e) {
    triggerEvent(DataColumnEvent(this, column, DataColumnEventType.delete, e));
  }

  void onHeaderMouseEnter(DataColumn? column, MouseEvent e) {
    var target = e.target as Element;
    print(target.innerHtml);
    target.querySelector('.cells__alphabet__menu')?.style.visibility =
        'visible';
  }

  void onHeaderMouseLeave(DataColumn? column, MouseEvent e) {
    var target = e.target as Element;
    target.querySelector('.cells__alphabet__menu')?.style.visibility = 'hidden';
  }

  void onHeaderDragOver(DataColumn? column, MouseEvent e) {
    triggerEvent(
        DataColumnEvent(this, column, DataColumnEventType.dragOver, e));
  }

  void onHeaderDragLeave(DataColumn? column, MouseEvent e) {
    triggerEvent(
        DataColumnEvent(this, column, DataColumnEventType.dragLeave, e));
  }

  void onHeaderDrop(DataColumn? column, MouseEvent e) {
    triggerEvent(DataColumnEvent(this, column, DataColumnEventType.drop, e));
  }
}

enum DataColumnEventType { dragOver, dragLeave, drop, delete }

class DataColumnEvent extends ComponentEvent {
  DataColumnEvent(Component source, DataColumn? column,
      DataColumnEventType eventType, MouseEvent e)
      : super.fromData(
            source, {"column": column, "eventType": eventType, "event": e});

  DataColumn? get column => data["column"] as DataColumn?;
  DataColumnEventType get eventType => data["eventType"] as DataColumnEventType;
  MouseEvent? get event => data["event"] as MouseEvent?;
}

abstract class DataColumn {
  String get name;
  bool get isEditable;
  set isEditable(bool flag);
  String getValue(int ri);
  void setValue(int ri, String value);
}

abstract class DataTable {
  List<DataColumn> get columns;
  int get nRows;

  void removeColumn(DataColumn column);
}
