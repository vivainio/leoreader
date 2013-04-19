package com.w;

import com.w.GetJson;
import org.tantalum.Task;
import org.tantalum.util.L;

@SuppressWarnings("all")
public class LunchEngine {
  public void log(final String s) {
    L.i("ll", s);
  }
  
  public Task start() {
    Task _xblockexpression = null;
    {
      final int placeid = 731;
      final String dstring = "18/4/2013";
      final String lang = "en";
      final String url = "http://www.sodexo.fi/ruokalistat/output/daily_json/731/2013/4/19/en";
      final Task _function = new Task() {
          @Override
          protected Object exec(final Object it) {
            Object _xblockexpression = null;
            {
              GetJson _getJson = new GetJson(url);
              final GetJson g = _getJson;
              String _plus = ("fetching: " + url);
              LunchEngine.this.log(_plus);
              g.download();
              _xblockexpression = (null);
            }
            return _xblockexpression;
          }
        };
      final Task fetcher = _function;
      Task _fork = fetcher.fork();
      _xblockexpression = (_fork);
    }
    return _xblockexpression;
  }
}
