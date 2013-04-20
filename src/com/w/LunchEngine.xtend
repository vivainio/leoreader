package com.w

import java.net.URI
import java.util.ArrayList
import org.apache.http.client.methods.HttpGet
import org.apache.http.impl.client.BasicResponseHandler
import org.apache.http.impl.client.DefaultHttpClient
import org.json.me.JSONObject
import org.tantalum.Task
import org.tantalum.util.L
import android.text.SpannableStringBuilder
import java.util.List
import android.text.Spanned
import android.text.Html

@Data class Course {
	String title
	String category
	
}

class GetJson {
	String url;
	
	new(String url) {
		this.url = url
	}
	
	def download(String loc) {
		val cli = new DefaultHttpClient()
		var r = new HttpGet()
		r.setURI(new URI(url))
		
		L::i("", "executing")
		val resp = cli.execute(r, new BasicResponseHandler())
		val json = new JSONObject(resp)
		val courses = json.getJSONArray("courses").myArrayList
		
		val ll = new ArrayList<Course>()
		LunchContent::ITEMS.put(loc, ll) 
		for (o : courses) {
			val j = o as JSONObject
			val co = new Course(j.get("title_en") as String, j.get("category") as String)
			L::i("", "Course: " + co)
			ll.add(co)
			
		}
		L::i("", "got courses")
		LunchContent::dump
		
	}
	
}

class LunchEngine {
	def log(String s) {
		L::i("ll", s)
	}
	def start() {
		//val placeid = 731
		val dstring = "2013/4/19"
		val lang = "en"
		val int[] locs = #[424, 731]
		//val url1 = "http://www.sodexo.fi/ruokalistat/output/daily_json/731/2013/4/19/en"
		 				
		//val url = "http://www.sodexo.fi/ruokalistat/output/daily_json/" + placeid + "/" + dstring + "/" + lang + "?mobileRedirect=false";
		
		locs.forEach[ placeid |
			val Task fetcher = [
				val url = "http://www.sodexo.fi/ruokalistat/output/daily_json/" + placeid + "/" + dstring + "/" + lang + "?mobileRedirect=false";
				val g = new GetJson(url)
				log("fetching: " + url)
				g.download(String::valueOf(placeid))
				//var g2 = new GetJson()
				
				null
			]
			fetcher.fork
		]
	}
	def static Spanned renderLunchList(String loc) {
		val List<Course> li = LunchContent::ITEMS.get(loc);
		val b = new StringBuilder()
		li.forEach[co |
			b.append("<p><b>" + co.category + "</b></p>")
			b.append("<p>" + co.title + "</p>")
		]

				
		Html::fromHtml(b.toString)		
		
	}	
}