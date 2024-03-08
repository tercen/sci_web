part of sci_component;

class InputFileComponent extends ValueComponent<List<File>> {
  @override
  Iterable<String> get rootClasses => ['FileInputComponent'];
  @override
  String get template => '<input type="file">';

  InputFileComponent(Value<List<File>> model) : super(model) {
    var input = root as FileUploadInputElement;
    addSubscription(input, input.onChange.listen((_) {
      if (input.files != null) {
        model.value = input.files!;
      }
      triggerEvent(ComponentEvent.fromData(this, {'files': input.files}));
    }));
  }

  @override
  drawValue(List<File> innerValue) {
    var input = root as FileUploadInputElement;
    if (innerValue.isEmpty) {
      input.value = '';
    } else {
      if (input.files!.isNotEmpty && innerValue.first != input.files!.first) {
        input.value = '';
      }
    }
  }
}

class DragInputFileComponent extends ValueComponent<List<File>> {
  @override
  Iterable<String> get rootClasses => ['DragInputFileComponent'];

  static String getFileSize(int size) {
    if (size > 1000000000) {
      return '${(size / 1000000000).toStringAsFixed(2)} GB';
    } else if (size > 1000000) {
      return '${(size / 1000000).toStringAsFixed(2)} MB';
    } else if (size > 1000) {
      return '${(size / 1000).toStringAsFixed(2)} KB';
    }
    return '${size.toString()} B';
  }

  DragInputFileComponent([Value<List<File>>? valueOrNull])
      : super(valueOrNull ?? ValueHolder(<File>[])) {
    var selectedFileNameModel = model.convert(
        get: (List<File> value) =>
            value.isEmpty ? 'No file chosen.' : value.first.name);
    var selectedFileSizeModel = model.convert(
        get: (List<File> value) =>
            value.isEmpty ? '' : getFileSize(value.first.size));
    var inputFileComponent = InputFileComponent(model);
    var dropBox = ListLayoutComponent([
      IconComponent.css('icon-drop-file'),
      TextComponent('Choose file or drag it here.',
          cssClasses: ['action-description']),
      ListLayoutComponent([
        TextComponent(selectedFileNameModel, cssClasses: ['filename']),
        TextComponent(selectedFileSizeModel, cssClasses: ['size'])
      ], cssClasses: [
        'filename-container'
      ]),
    ], cssClasses: [
      'drop-box'
    ]);

    addToRoot(inputFileComponent);
    addToRoot(dropBox);

    addSub(dropBox.root.onDragEnter.listen((event) {
      event.preventDefault();
      dropBox.root.classes.add('dragging');
    }));

    addSub(dropBox.root.onDrag.listen((event) {
      event.preventDefault();
      dropBox.root.classes.add('dragging');
    }));

    addSub(dropBox.root.onDragLeave.listen((event) {
      event.preventDefault();
      dropBox.root.classes.remove('dragging');
    }));

    addSub(dropBox.root.onDragOver.listen((event) {
      event.preventDefault();
      dropBox.root.classes.add('dragging');
    }));

    addSub(dropBox.root.onDrop.listen((MouseEvent event) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();

      dropBox.root.classes.remove('dragging');
      var droppedFiles = event.dataTransfer.files;

      if (droppedFiles != null) {
        model.value = droppedFiles;
      }
    }));
  }

  // @override
  // drawValue(List<File>? innerValue) {
  //   _selectedFileName.value =
  //       model.value.isEmpty ? 'No file chosen.' : model.value.first.name;
  // }
}

//
//class InputTextComponent extends Component {
//
//  String label;
//  String placeHolder;
//  ValueHolder<String> value;
//
//  InputTextComponent(this.value, {this.label, this.placeHolder:''});
//
//  String get template => label == null ? '''
//<div class="form-group">
//    <input id="value" type="text" class="form-control" value="${value.value}" placeholder="${placeHolder}">
//</div>
//  ''': '''
//<div class="form-group">
//    <label>${label}</label>
//    <input id="value" type="text" class="form-control" value="${value.value}" placeholder="${placeHolder}">
//</div>
//''';
//
//  TextInputElement get valueElement => this.root.querySelector('#value');
//
//  void created(){
//    this.addSubscription( valueElement, valueElement.onChange.listen(_onValueChanged));
//  }
//
//  void _onValueChanged(Event evt){
//    value.value = valueElement.value;
//  }
//}
