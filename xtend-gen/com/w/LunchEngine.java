package com.w;

import android.text.Html;
import android.text.Spanned;
import com.w.Course;
import com.w.GetJson;
import com.w.LunchContent;
import java.util.List;
import org.eclipse.xtext.xbase.lib.Conversions;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1;
import org.tantalum.Task;
import org.tantalum.util.L;

@SuppressWarnings("all")
public class LunchEngine {
  public void log(final String s) {
    L.i("ll", s);
  }
  
  public void start() {
    final String dstring = "2013/4/19";
    final String lang = "en";
    final int[] locs = { 424, 731 };
    final Procedure1<Integer> _function = new Procedure1<Integer>() {
        public void apply(final Integer placeid) {
          final Task _function = new Task() {
              @Override
              protected Object exec(final Object it) {
                Object _xblockexpression = null;
                {
                  String _plus = ("http://www.sodexo.fi/ruokalistat/output/daily_json/" + placeid);
                  String _plus_1 = (_plus + "/");
                  String _plus_2 = (_plus_1 + dstring);
                  String _plus_3 = (_plus_2 + "/");
                  String _plus_4 = (_plus_3 + lang);
                  final String url = (_plus_4 + "?mobileRedirect=false");
                  GetJson _getJson = new GetJson(url);
                  final GetJson g = _getJson;
                  String _plus_5 = ("fetching: " + url);
                  LunchEngine.this.log(_plus_5);
                  String _valueOf = String.valueOf(placeid);
                  g.download(_valueOf);
                  _xblockexpression = (null);
                }
                return _xblockexpression;
              }
            };
          final Task fetcher = _function;
          fetcher.fork();
        }
      };
    IterableExtensions.<Integer>forEach(((Iterable<Integer>)Conversions.doWrapArray(locs)), _function);
  }
  
  public static Spanned renderLunchList(final String loc) {
    Spanned _xblockexpression = null;
    {
      final List<Course> li = LunchContent.ITEMS.get(loc);
      StringBuilder _stringBuilder = new StringBuilder();
      final StringBuilder b = _stringBuilder;
      final Procedure1<Course> _function = new Procedure1<Course>() {
          public void apply(final Course co) {
            String _category = co.getCategory();
            String _plus = ("<p><b>" + _category);
            String _plus_1 = (_plus + "</b></p>");
            b.append(_plus_1);
            String _title = co.getTitle();
            String _plus_2 = ("<p>" + _title);
            String _plus_3 = (_plus_2 + "</p>");
            b.append(_plus_3);
          }
        };
      IterableExtensions.<Course>forEach(li, _function);
      String _string = b.toString();
      Spanned _fromHtml = Html.fromHtml(_string);
      _xblockexpression = (_fromHtml);
    }
    return _xblockexpression;
  }
}
