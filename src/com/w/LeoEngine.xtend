package com.w

import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory
import java.io.FileInputStream
import java.io.FileReader
import java.util.Hashtable

@Data class Course {
	
}

@Data class Node {
	String gnx
	String h
	String b
	
}

class LeoDoc {
	Hashtable<String, Node> nodes

	def Node get(String gnx) { nodes.get(gnx) }	
	
}

class LeoEngine {

	
		
	def start() {
		val pf = XmlPullParserFactory::newInstance
		val p =  pf.newPullParser
		p.setInput(new FileReader("/sdcard/Download/workbook.leo"))
		var eventType = p.eventType
		var text = ""
		var gnx = ""
		while (eventType != XmlPullParser::END_DOCUMENT) {
			val name = p.name
			println(name)
			switch eventType {
				case XmlPullParser::TEXT: text = p.text
				case XmlPullParser::END_TAG:
					switch name {
						case "vh":
							println('''End tag vh t = «text» gnx = «gnx»''')
							
					}
				 case XmlPullParser::START_TAG:
				 	switch name {
				 		case "v":
				 			gnx = p.getAttributeValue("", "t")
				 	}
				
				
				
			}
			
			eventType = p.next
			
			
		}
		
		
		null
		
	}
}