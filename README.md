# 可以拖动子部件的容器部件
# A Draggable Widget Container 

## 可拖动子部件，可删除子部件，可以固定子部件位置
## Each children is draggable, deletable, fixable.

## 截图 / Screenshots

[<img src="https://github.com/gzlock/images/raw/master/flutter_draggable_container/1.gif" width="200">](https://github.com/gzlock/images/raw/master/flutter_draggable_container/1.gif)

[<img src="https://github.com/gzlock/images/raw/master/flutter_draggable_container/2.gif" width="200">](https://github.com/gzlock/images/raw/master/flutter_draggable_container/2.gif)

[<img src="https://github.com/gzlock/images/raw/master/flutter_draggable_container/3.gif" width="200">](https://github.com/gzlock/images/raw/master/flutter_draggable_container/3.gif)

### 模式 / Mode

- 正常模式 / Normal Mode:
    - 不拦截子部件的手势事件
    - Do not intercept the GestureDetector events of the child widget
    - 不能拖动和删除子部件
    - Can't drag and delete the children widget
    
- 编辑模式 / Draggable mode:
    - 长按子部件进入编辑模式
    - Long press the children widget to enter the draggable mode
    - 进入编辑模式后，不再需要长按来拖动子部件，直接拖动就可以了
    - In the draggable mode, do not need to long press to drag the children widget,
      just drag it.
    - 在可删除子部件上显示删除按钮
    - Show the delete button on the deletable child widget
    - 拦截可拖动可删除的子部件的手势事件
    - Intercept the GestureDetector events of the draggable and deletable child widget
    - 可以拖动和删除子部件
    - Can drag and delete the children widget
    - 返回键 退出编辑模式
    - Press the Back key to exit the draggable mode.
    


```
下文中的T意味着T extends DraggableItem
In the following, T means T extends DraggableItem
```
    
- 事件 / Events
    - onChanged(List\<T\> items)
        - 当子项目改变时触发(拖动过后，删除后)
        - Trigger when the items changed(dragged, deleted)
    - onDraggableModeChanged(bool mode)
        - mode为true则进入了编辑模式，为false则退出了编辑模式.
        - When mode is true then in the draggable mode. If false it mean exited the draggable mode.
    - Future\<bool\> onBeforeDelete(int index, T item)
        - 删除item的确认事件，返回true删除，返回false不删除
        - The event for confirm to delete a item, if return true then delete, if false then no action.

- DraggableContainerState的方法 / The DraggableContainerState methods:
    - Future<void> addSlot({T item, bool triggerEvent: true})
        - 添加一个新的槽。        
        - Add a new slot.
    - Future<void> addSlots(int count, {bool triggerEvent: true})
        - 添加多个槽，用对应数量的null填充
        - Add multiple slots and fill with null.    
    - Future<T> popSlot()
        - 移除最后一个槽位，返回对应的item
        - Remove the last slot and return the item.
    - findSlot(Offset position)
        - 根本坐标寻找槽
        - find the slot use Offset position.
        
    - T getItem(int index)
        - 使用index获取item，空的槽item为null
        - Use index get item, the empty slot's item is null.
    - bool insteadOfIndex(int index, T item, {bool triggerEvent: true, bool force: false})
        - 使用item替换到index的位置
        - Use item to instead of the index position.
    - bool moveTo(int from, int to, {bool triggerEvent: true, bool force: false})
        - 将item从from移动到to
        - Move the item from the 'from' index to the 'to' index.
    - bool removeItem(T item, {bool triggerEvent: true})
        - 根据item删除item
        - Delete item according to item
    - bool removeIndex(int index, {bool triggerEvent: true})
        - 删除index位置的item
        - Delete item from the index position.
    - bool addItem(T item, {bool triggerEvent: true})
        - 添加item，永远添加到第一个null的位置，找不到null则返回false代表添加失败
        - Add item, always add to the first null position, if can't find null, return false it mean to add failure.
    
- 关于上文提到的参数 / About the Parameters:
    - bool triggerEvent:
        - 是否触发onChanged事件
        - Trigger the onChanged event or not
    - bool force:
        - 如果目标item的deletable为false，则强制覆盖
        - Forced override if the target item's deleteable is false