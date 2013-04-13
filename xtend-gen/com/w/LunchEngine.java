package com.w;

import org.tantalum.Task;
import org.tantalum.util.L;

@SuppressWarnings("all")
public class LunchEngine {
  public Task start() {
    Task _xblockexpression = null;
    {
      final Task _function = new Task() {
          @Override
          protected Object exec(final Object it) {
            L.i("test", "Hello from Tantalum");
            return null;
          }
        };
      final Task getlists = _function;
      Task _fork = getlists.fork();
      _xblockexpression = (_fork);
    }
    return _xblockexpression;
  }
}
