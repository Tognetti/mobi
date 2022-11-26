class NullImage implements Exception {
  String _message;

  NullImage(this._message);

  @override
  String toString() {
    return _message;
  }
}
