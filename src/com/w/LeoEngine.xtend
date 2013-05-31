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

	new() {
		nodes = new Hashtable<String, Node> 
		
	}
	def Node get(String gnx) {
		nodes.get(gnx)
	}

	def read(String fname) {
		val pf = XmlPullParserFactory::newInstance
		nodes.clear
		val p = pf.newPullParser
		p.setInput(new FileReader(fname))
		var eventType = p.eventType
		var text = ""
		var gnx = ""
		
		while (eventType != XmlPullParser::END_DOCUMENT) {
			val name = p.name
			println(name)
			switch eventType {
				case XmlPullParser::TEXT:
					text = p.text
				case XmlPullParser::END_TAG:
					switch name {
						case "vh": {
							println('''End tag vh t = «text» gnx = «gnx»''')
							val node = new Node(gnx, text, "")
							nodes.put(gnx, node)
						}
							
							
					}
				case XmlPullParser::START_TAG:
					switch name {
						case "v":
							gnx = p.getAttributeValue("", "t")
					}
			}

			eventType = p.next

		}

	}
}

class LeoEngine {

	def start() {
		val doc = new LeoDoc
		doc.read("/sdcard/Download/workbook.leo")
	}

}
