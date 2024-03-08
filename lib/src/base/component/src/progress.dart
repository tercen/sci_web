part of sci_component;

class TercenWaitTemplateComponent extends Component {
  @override
  String get template => '''
<div class="loader">
    <div class="loader-logo">
    </div>
    <div class="fa-4x  loader-spinner ">
        <i class="fas fa-spinner fa-pulse"></i>
    </div>
</div>  
  ''';
}

class TercenWaitComponent extends Component {
  @override
  Iterable<String> get rootClasses => ['TercenWaitComponent'];

  TercenWaitComponent() {
    addToRoot(TercenWaitTemplateComponent());
  }
}

class WaitComponent extends Component {
  String cssClass = "sci-wait";
  String? waitMessage;

  WaitComponent([this.waitMessage]);

  WaitComponent.showWhile(Future future,
      {this.waitMessage, this.cssClass = "sci-wait"}) {
    future.whenComplete(() {
      removeSync();
    });
  }

  Future showWhile(Future Function() future) async {
    try {
      show(true);
      return await future();
    } finally {
      show(false);
    }
  }

  @override
  String get template {
    if (waitMessage == null) {
      return '''
<div class="$cssClass">
  <img src="/_assets/images/ajax-loader.gif">
</div>''';
    } else {
      return '''
<div class="$cssClass">
  <p>$waitMessage</p>
  <img src="/_assets/images/ajax-loader.gif">
</div>''';
    }
  }
}

class ProgressBarComponent2 extends Component {
  Value<String> message;

  ProgressBarComponent2(Stream<ProgressBarComponentEvent> stream)
      : message = ValueHolder('') {
    addToRoot(ListLayoutComponent(
        [TextComponent(message), ProgressBarComponent.fromEvent(stream)]));
    addSubscription(stream, stream.listen(progressEvent));
  }

  progressEvent(evt) {
    message.value = '';
    if (evt is ProgressEvent) {
    } else if (evt is double) {
    } else if (evt is Map) {
      if (evt['message'] != null) {
        message.value = evt['message'].toString();
      }
    }
  }
}

sealed class ProgressBarComponentEvent {
  static ProgressBarComponentEvent from(dynamic value) {
    if (value is double) {
      return ratio(value);
    } else if (value is ProgressEvent) {
      return progressEvent(value);
    } else if (value is Map) {
      return map(value);
    } else {
      return ProgressBarComponentEventRatio(0);
    }
  }

  static ProgressBarComponentEvent ratio(double value) =>
      ProgressBarComponentEventRatio(value);
  static ProgressBarComponentEvent map(Map value) =>
      ProgressBarComponentEventMap(value);
  static ProgressBarComponentEvent progressEvent(ProgressEvent value) =>
      ProgressBarComponentProgressEvent(value);
}

class ProgressBarComponentEventRatio extends ProgressBarComponentEvent {
  double ratio;
  ProgressBarComponentEventRatio(this.ratio);
}

class ProgressBarComponentEventMap extends ProgressBarComponentEvent {
  Map map;
  ProgressBarComponentEventMap(this.map);
}

class ProgressBarComponentProgressEvent extends ProgressBarComponentEvent {
  ProgressEvent progressEvent;
  ProgressBarComponentProgressEvent(this.progressEvent);
}

class ProgressBarComponent extends Component {
  @override
  String get template => '''
<div class="progress">
  <div class="progress-bar" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"></div>
</div>
''';

  ProgressBarComponent(Stream<double> stream) {
    addSubscription(stream, stream.listen(_progress));
  }

  ProgressBarComponent.fromEvent(Stream<ProgressBarComponentEvent> stream) {
    addSubscription(stream, stream.listen(_progressEvent));
  }

  void _progressEvent(ProgressBarComponentEvent evt) {
    switch (evt) {
      case ProgressBarComponentEventRatio(ratio: var ratio):
        _progress(ratio);

      case ProgressBarComponentEventMap(map: var map):
        var total = map['total'] as num;
        var loaded = map['loaded'] as num;
        _progress((loaded ~/ total).toDouble());

      case ProgressBarComponentProgressEvent(progressEvent: var progressEvent):
        _progress((progressEvent.loaded! ~/ progressEvent.total!).toDouble());
    }
  }

  void _progress(double ratio) {
    selector('.progress-bar').style.width = '${(100 * ratio).toInt()}%';
  }

  reset() {
    selector('.progress-bar').style.width = '0';
  }
}
