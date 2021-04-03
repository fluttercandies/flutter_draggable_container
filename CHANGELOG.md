### [1.0.7+2]
Fixed some issues.

### [1.0.7+1]
Fixed some issues.

### [1.0.7]
Add the attribute name of 'shrinkWrap' for shrink the horizontal size.

### [1.0.6]
Keep to fixed the issue about of v1.0.5.

### [1.0.5]
Fixed a bug about when dragging the item from back to front will lost item.

### [1.0.4+1]
Updated.

### [1.0.4]
Add beforeDrop callback.

### [1.0.3+2]
Updated the logic about to create the overlay.

### [1.0.3+1]
Updated.

### [1.0.3]
Updated.

### [1.0.2+2]
Updated README.md.

### [1.0.2+1]
Updated.

### [1.0.2]
Updated.

### [1.0.1]
Fixed the '_dragTo' logic.

### [1.0.0]
Support null safety.
Support GridSliverDelegate.
Support tap outside of container to exit edit mode.

### [0.1.8+5]

Fixed the trigger logic for the onDraggableModeChanged.

### [0.1.8+4]

Update document

### [0.1.8+3]

Update document

### [0.1.8+2]

Update document

### [0.1.8+1]

补全文档
Completion document


### [0.1.8]

Add two methods:

- Future<void> addSlot
- Future<void> addSlots(int count)
- Future<T extends DraggableItem> popSlot()

Methods changed name:
- deleteItem -> removeItem
- deleteIndex -> removeIndex
 
Add the addSlot, addSlots, removeSlot methods tester.

Add LoopCheck class to wait the widget build

### [0.1.7+1]

Set the stack.overflow to Overflow.visible.

### [0.1.7]

Fixed a issue.

### [0.1.6+3]

Fixed a issue of reorder error when autoReorder = false.

### [0.1.6+2]

Fixed a draggable mode issue.

Add onDragEnd event.

### [0.1.6+1]

Fixed: when second times enter the draggable mode, the draggable item move faster than finger

### [0.1.6]

Add bool moveTo(int from, int to, {bool triggerEvent: true, bool force: false}) method

Updated the example code.

### [0.1.5]

Fixed some issues.

Updated the example code.

Updated the test code.

### [0.1.4+hotfix]

Fixed some issues.

Updated the example code.

### [0.1.4]

Fixed some issues.

### [0.1.3]

Fixed some issues.

Add getItem(int index) method

### [0.1.2]

Add insteadOfIndex(int index, DraggableItem item, {bool triggerEvent: true}) method

### [0.1.1]

Updated README.md

### [0.1.0]

Updated README.md

### [0.0.9]

Add onBeforeDelete event.

The addItem, deleteIndex, deleteItem methods add a parameter called triggerEvent, default is true.

Updated the example code.

Updated the demo gif.

Updated README.md

### [0.0.8]

Fixed long press to drag the item move faster than finger.

Fixed some issue.

Add the demo gif.

### [0.0.7]

* All class names begin with Draggable

* Add parameters to DraggableContainer:
    - draggableMode
    - allWayUseLongPress
    
* Rewrote the reorder algorithm

* Use the tester to test the reorder logic.
    
### [0.0.6]
Updated the example code.

### [0.0.5]
Updated code.

### [0.0.4]
Updated the example code.

### [0.0.3]
Updated code.

### [0.0.2]
Updated the pubspec.yaml file and the example code.

### [0.0.1]
init.
