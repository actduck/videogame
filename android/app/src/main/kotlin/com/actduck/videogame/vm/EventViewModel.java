package com.actduck.videogame.vm;

import androidx.lifecycle.ViewModel;
import org.greenrobot.eventbus.EventBus;

public class EventViewModel extends ViewModel {

  public EventViewModel() {
    EventBus.getDefault().register(this);
  }

  @Override protected void onCleared() {
    super.onCleared();
    EventBus.getDefault().unregister(this);
  }
}