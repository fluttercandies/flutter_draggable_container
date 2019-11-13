import 'package:draggable_container/draggable_container.dart';
import 'package:test/test.dart';

void main() {
  test("test loopcheck", () async {
    final loop = LoopCheck.check();
    Future.delayed(Duration(seconds: 1)).then((_) {
      loop.stop();
    });
    await loop.start();
    print('ok');
    expect(true, true);
  });
}
