# 可以拖动子部件的容器部件
# A Draggable Widget Container 

## 可拖动子部件，可删除子部件，可以固定子部件位置
## Each children is draggable, deletable, fixable.

## 截图 / Screenshots

[<img src="https://github.com/gzlock/images/raw/master/flutter_draggable_container/1.gif" width="200">](https://github.com/gzlock/images/raw/master/flutter_draggable_container/1.gif)

### 模式 / Mode

- 正常模式 / Normal Mode:
    - 不拦截子部件的手势事件
    - Do not intercept the GestureDetector events of the child widget
    - 不能拖动和删除子部件
    - Can't drag and delete the children widget
    
- 编辑模式 / Edit mode:
    - 长按子部件进入编辑模式
    - Long press the children widget to enter the edit mode
    - 进入编辑模式后，不再需要长按来拖动子部件，直接拖动就可以了
    - In the edit mode, you can just drag the tile directly.
    - 在可删除子部件上显示删除按钮
    - Show the delete button on the deletable child widget
    - 拦截所有子部件的手势事件
    - Intercept the child widget gesture event.
    - 可以拖动和删除子部件
    - the children widget can drag and delete.
    

- DraggableContainer的构造函数参数 / The DraggableContainer Constructor parameters
    - required List\<T extends DraggableItem\> items
    - required Widget? NullableItemBuilder\<T extends DraggableItem\>(BuildContext context, T? item) itemBuilder
        - 子项widget的构建器。
        - Item widget builder.
    - required SliverGirdDelegate gridDelegate
        - 布局依赖于gridDelegate。
        - The layout depends on the gridDelegate.
    - bool? shrinkWrap
        - 紧缩水平宽度大小，方便水平居中，默认为false。
        - Shrink the horizontal size, default is false.
    - Widget? NullableItemBuilder\<T extends DraggableItem\>(BuildContext context, T? item) deleteButtonBuilder
        - 子项删除按钮的构建器。
        - The delete button builder for the item.
    - Widget? NullableItemBuilder\<T extends DraggableItem\>(BuildContext context, T? item) slotBuilder
        - 槽位组件的构建器。
        - The slot widget builder.
    - BoxDecoration? draggingDecoration, default is a shadow style.
        - 当拖动子项时，包裹在子项外部的样式，默认为阴影效果。
        - When dragging the item widget, the style wrapped the item widget.
    - Duration? animationDuration, default 200ms.
        - 子项widget位移的动画时间。
        - The animation time of the child widget displacement.
    - bool? tapOutSideExitEditMode, default true.
        - 当点击了DraggableContainer外部后，退出编辑模式。
        - When tap outside of the draggable container, exit the edit mode.
    - onChanged(List\<T extends DraggableItem\> items)
        - 当子项目改变时触发(拖动过后，删除后)
        - Trigger when the items changed(dragged, deleted)
    - onEditModeChanged(bool mode)
        - mode为true则进入了编辑模式，为false则退出了编辑模式.
        - When mode is true then in the draggable mode. If false it mean exited the draggable mode.
    - Future\<bool\> beforeRemove(T? item, int slotIndex)
        - 删除item的确认事件，返回true删除，返回false不删除
        - The event for confirm to delete a item, if return true then delete, if false then no action.
    - Future\<bool\> beforeDrop({T? fromItem, int fromSlotIndex, T? toItem, int toSlotIndex})
        - 将一个item从A点移到B点后的确认事件，返回true为允许放下，返回false不允许放下，

            会覆盖toItem.fixed属性。
        - The confirmation event after moving an item from point A to point B. Returns true to allow dropping, returns false to not allow dropping.

            will override the toItem.fixed property.

- DraggableContainerState的方法 / The DraggableContainerState methods:
    - getter / setter bool editMode
        - 读取或设置编辑模式。
        - get or set the edit mode.

    - List\<T extends DraggableItem\> items
        - 项目列表。
        - Item list.

    - Future\<void\> addSlot(\<T extends DraggableItem\>? item)
        - 添加一个新的槽。        
        - Add a new slot.
    - Future\<T extends DraggableItem\> removeSlot(int index)
        - 删除一个槽位，返回item。
        - Remove the slot of index and return the item.

    - removeItem(\<T extends DraggableItem\> item)
    - removeItemAt(int index)
        - 删除item。
        - Delete item.

    - replaceItem(int index, \<T extends DraggableItem\>? item)
        - 替换item。
        - Replace item.