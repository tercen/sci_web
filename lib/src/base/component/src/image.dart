export 'package:sci_base/value.dart';

import '../component.dart';

class ImageThumbnailComponent extends Component {
  @override
  Iterable<String> get rootClasses => ['ImageThumbnailComponent'];
  ImageThumbnailComponent(Value<String> value) {
    var image = ImageComponent(value);
    addToRoot(image);

    addSub(image.root.onClick.listen((event) {
      ImageDialog(value).open();
    }));
  }
}

class ImageDialog extends Dialog {
  @override
  Iterable<String> get rootClasses => ['ImageDialog', 'Dialog'];

  ImageDialog(Value<String> value) {
    beLarge();
    addDialogBody(ListLayoutComponent([ImageComponent(value)]));
  }
}
