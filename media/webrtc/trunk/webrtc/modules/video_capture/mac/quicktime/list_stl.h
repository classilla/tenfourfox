/*
 *  Copyright (c) 2011 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#ifndef WEBRTC_SYSTEM_WRAPPERS_SOURCE_LIST_STL_H_
#define WEBRTC_SYSTEM_WRAPPERS_SOURCE_LIST_STL_H_

#include <list>

#include "webrtc/system_wrappers/interface/constructor_magic.h"

namespace webrtc {

class ListItem {
 public:
  ListItem(const void* ptr);
  ListItem(const unsigned int item);
  virtual ~ListItem();
  void* GetItem() const;
  unsigned int GetUnsignedItem() const;

 private:
  friend class ListWrapper;
  mutable std::list<ListItem*>::iterator this_iter_;
  const void*         item_ptr_;
  const unsigned int  item_;
  DISALLOW_COPY_AND_ASSIGN(ListItem);
};

class ListWrapper {
 public:
  ListWrapper();
  ~ListWrapper();

  // ListWrapper functions
  unsigned int GetSize() const;
  int PushBack(const void* ptr);
  int PushBack(const unsigned int item_id);
  int PushFront(const void* ptr);
  int PushFront(const unsigned int item_id);
  int PopFront();
  int PopBack();
  bool Empty() const;
  ListItem* First() const;
  ListItem* Last() const;
  ListItem* Next(ListItem* item) const;
  ListItem* Previous(ListItem* item) const;
  int Erase(ListItem* item);
  int Insert(ListItem* existing_previous_item, ListItem* new_item);
  int InsertBefore(ListItem* existing_next_item, ListItem* new_item);

 private:
  mutable std::list<ListItem*> list_;
  DISALLOW_COPY_AND_ASSIGN(ListWrapper);
};

#ifdef _LISTITEM_SRC

ListItem::ListItem(const void* item)
    : this_iter_(),
      item_ptr_(item),
      item_(0) {
}

ListItem::ListItem(const unsigned int item)
    : this_iter_(),
      item_ptr_(0),
      item_(item) {
}

ListItem::~ListItem() {
}

void* ListItem::GetItem() const {
  return const_cast<void*>(item_ptr_);
}

unsigned int ListItem::GetUnsignedItem() const {
  return item_;
}

ListWrapper::ListWrapper()
    : list_() {
}

ListWrapper::~ListWrapper() {
  if (!Empty()) {
    // Remove all remaining list items.
    while (Erase(First()) == 0) {}
  }
}

bool ListWrapper::Empty() const {
  return list_.empty();
}

unsigned int ListWrapper::GetSize() const {
  return list_.size();
}

int ListWrapper::PushBack(const void* ptr) {
  ListItem* item = new ListItem(ptr);
  list_.push_back(item);
  return 0;
}

int ListWrapper::PushBack(const unsigned int item_id) {
  ListItem* item = new ListItem(item_id);
  list_.push_back(item);
  return 0;
}

int ListWrapper::PushFront(const unsigned int item_id) {
  ListItem* item = new ListItem(item_id);
  list_.push_front(item);
  return 0;
}

int ListWrapper::PushFront(const void* ptr) {
  ListItem* item = new ListItem(ptr);
  list_.push_front(item);
  return 0;
}

int ListWrapper::PopFront() {
  if (list_.empty()) {
    return -1;
  }
  list_.pop_front();
  return 0;
}

int ListWrapper::PopBack() {
  if (list_.empty()) {
    return -1;
  }
  list_.pop_back();
  return 0;
}

ListItem* ListWrapper::First() const {
  if (list_.empty()) {
    return NULL;
  }
  std::list<ListItem*>::iterator item_iter = list_.begin();
  ListItem* return_item = (*item_iter);
  return_item->this_iter_ = item_iter;
  return return_item;
}

ListItem* ListWrapper::Last() const {
  if (list_.empty()) {
    return NULL;
  }
  // std::list::end() addresses the last item + 1. Decrement so that the
  // actual last is accessed.
  std::list<ListItem*>::iterator item_iter = list_.end();
  --item_iter;
  ListItem* return_item = (*item_iter);
  return_item->this_iter_ = item_iter;
  return return_item;
}

ListItem* ListWrapper::Next(ListItem* item) const {
  if (item == NULL) {
    return NULL;
  }
  std::list<ListItem*>::iterator item_iter = item->this_iter_;
  ++item_iter;
  if (item_iter == list_.end()) {
    return NULL;
  }
  ListItem* return_item = (*item_iter);
  return_item->this_iter_ = item_iter;
  return return_item;
}

ListItem* ListWrapper::Previous(ListItem* item) const {
  if (item == NULL) {
    return NULL;
  }
  std::list<ListItem*>::iterator item_iter = item->this_iter_;
  if (item_iter == list_.begin()) {
    return NULL;
  }
  --item_iter;
  ListItem* return_item = (*item_iter);
  return_item->this_iter_ = item_iter;
  return return_item;
}

int ListWrapper::Insert(ListItem* existing_previous_item,
                        ListItem* new_item) {
  // Allow existing_previous_item to be NULL if the list is empty.
  // TODO(hellner) why allow this? Keep it as is for now to avoid
  // breaking API contract.
  if (!existing_previous_item && !Empty()) {
    return -1;
  }

  if (!new_item) {
    return -1;
  }

  std::list<ListItem*>::iterator insert_location = list_.begin();
  if (!Empty()) {
    insert_location = existing_previous_item->this_iter_;
    if (insert_location != list_.end()) {
      ++insert_location;
    }
  }

  list_.insert(insert_location, new_item);
  return 0;
}

int ListWrapper::InsertBefore(ListItem* existing_next_item,
                              ListItem* new_item) {
  // Allow existing_next_item to be NULL if the list is empty.
  // Todo: why allow this? Keep it as is for now to avoid breaking API
  // contract.
  if (!existing_next_item && !Empty()) {
    return -1;
  }
  if (!new_item) {
    return -1;
  }

  std::list<ListItem*>::iterator insert_location = list_.begin();
  if (!Empty()) {
    insert_location = existing_next_item->this_iter_;
  }

  list_.insert(insert_location, new_item);
  return 0;
}

int ListWrapper::Erase(ListItem* item) {
  if (item == NULL) {
    return -1;
  }
  list_.erase(item->this_iter_);
  return 0;
}

#endif

}  // namespace webrtc

#endif  // WEBRTC_SYSTEM_WRAPPERS_SOURCE_LIST_STL_H_
