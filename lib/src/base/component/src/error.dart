part of '../component.dart';

class ServiceErrorComponent extends Component {
  @override
  Iterable<String> get rootClasses => ['ServiceErrorComponent'];
  @override
  String get template => '''
  <div>
      <div class="status-container">
        <span class="statusCode"></span> : <span class="statusCodeDescription"></span>
      </div>
      <div class="error"></div>
      <div class="reason"></div>
      <div class="reasonObject"></div>
  </div>
  ''';
  ServiceErrorComponent(ServiceError error) {
    selector('.statusCode').text = error.statusCode.toString();
    selector('.statusCodeDescription').text = error.statusCodeDescription;
    selector('.reason').text = error.reason;
    if (error.reasonObject != null)
      selector('.reasonObject').text = error.reasonObject.toString();
    selector('.error').text = error.error;
  }
}

class ErrorInfoComponent extends Component {
  @override
  Iterable<String> get rootClasses => ['ErrorInfoComponent'];

  Object? _error;

  ErrorInfoComponent.alert(this._error) {
    show(false);
    root.classes
      ..add('alert')
      ..add('alert-danger');
    _draw();
  }
  ErrorInfoComponent.info(this._error) {
    show(false);
    root.classes
      ..add('alert')
      ..add('alert-info');
    _draw();
  }

  set error(Object? e) {
    _error = e;
    _draw();
  }

  Object? get error => _error;

  String get errorMsg =>
      _error is ServiceError ? (_error as ServiceError).reason : '$_error';

  _draw() {
    removeAllChildrenFrom(root);
    show(_error != null);

    if (_error != null) {
      var e = _error;

      if (e is ServiceError) {
        root.innerHtml = e.reason;
      } else {
        root.innerHtml = '$_error';
      }
    }
  }
}
