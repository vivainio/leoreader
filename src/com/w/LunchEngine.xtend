package com.w



import org.tantalum.util.L
import org.tantalum.net.HttpGetter
//import org.json.JSONObject
import org.tantalum.net.json.JSONGetter
import org.tantalum.net.json.JSONModel
import org.apache.http.client.HttpClient
import org.apache.http.impl.client.DefaultHttpClient
import org.apache.http.client.methods.HttpGet
import android.net.Uri
import java.net.URI
import java.io.BufferedReader
import java.io.InputStreamReader
import org.apache.http.impl.client.BasicResponseHandler
import org.apache.http.HttpResponse
import org.tantalum.Task
import org.json.me.JSONObject

@Data class Course {
	String title
	String category
	
}

class GetJson {
	String url;
	
	new(String url) {
		this.url = url
	}
	
	def download() {
		val cli = new DefaultHttpClient()
		var r = new HttpGet()
		r.setURI(new URI(url))
		
		L::i("", "executing")
		val resp = cli.execute(r, new BasicResponseHandler())
		val json = new JSONObject(resp)
		val courses = json.getJSONArray("courses").myArrayList
		for (o : courses) {
			val j = o as JSONObject
			val co = new Course(j.get("title_en") as String, j.get("category") as String)
			L::i("", "Course: " + co)
			
			
			
		
			
			
		}
		L::i("", "got courses:" + courses.length)
		
	}
	
}

class LunchEngine {
	def log(String s) {
		L::i("ll", s)
	}
	def start() {
		val placeid = 731
		val dstring = "18/4/2013"
		val lang = "en"
		val url = "http://www.sodexo.fi/ruokalistat/output/daily_json/731/2013/4/19/en"				
		//val url = "http://www.sodexo.fi/ruokalistat/output/daily_json/" + placeid + "/" + dstring + "/" + lang + "?mobileRedirect=false";
		
		val Task fetcher = [
			val g = new GetJson(url)
			log("fetching: " + url)
			g.download
			
			null
			
			
		]
		
		fetcher.fork
		
		
		
		//val m = new JSONModel;
		
		/* 
		var jsg = new JSONGetter(url, m)
				
		jsg.chain [ res |			
			
			val obj = m.take
			val en = obj.keys
			while (en.hasMoreElements) {
				val o = en.nextElement
				L::i("", "Have key: " + o as String)
				 
				
			}
			
			val courses = obj.getJSONArray("courses")
			L::i("", "Courses: " + courses.length)
			
						
			
						
			
			
			null
		]
		jsg.fork
		*/
		
		
		/*
		val Task getlists = [
			L::i("test", "Hello from Tantalum")
			null
		]
		
		getlists.chain [
			L::i("", "another task")
			null
		]
		
		getlists.fork()
		* 
		*/
		
		
	}	
}