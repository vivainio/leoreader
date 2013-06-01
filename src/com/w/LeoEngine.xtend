package com.w

import info.vv.leoreader.dummy.ScreenContent
import info.vv.leoreader.dummy.ScreenContent$OutlineItem
import java.io.FileReader
import java.util.Hashtable
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory

@Data class Course {
}


class Node {
	
	String _h
	String _b
	String _gnx

	new(String gnx, String h, String b) {
		_gnx = gnx; _h = h; _b = b
		
	}	
	def void setB(String body) {
		_b = body
	}
	
	def getH() { _h }
	def getB() { _b }
	def getGnx() { _gnx }

}

class LeoDoc {
	Hashtable<String, Node> nodes

	new() {
		nodes = new Hashtable<String, Node>

	}

	def getNodes() {
		nodes
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
							val node = new Node(gnx, text, "some body\nnew line")
							nodes.put(gnx, node)
						}
						case "t": {
							val node = get(gnx)
							node.b = text	
						}
					}
				case XmlPullParser::START_TAG:
					switch name {
						case "v":
							gnx = p.getAttributeValue("", "t")
						case "t":
							gnx = p.getAttributeValue("", "tx")
					}
			}
			ScreenContent::ITEMS.clear
			ScreenContent::ITEM_MAP.clear

			eventType = p.next

		}

	}

}

class LeoEngine {
	LeoDoc doc

	static LeoEngine _le

	Node currentNode

	def selectNode(String gnx) {
		currentNode = doc.get(gnx)
	}

	def currentBody() {
		return currentNode.b
	}

	static def getInstance() {
		if (_le == null) {
			_le = new LeoEngine
		}
		return _le

	}

	def start() {
		doc = new LeoDoc
		doc.read("/sdcard/Download/workbook.leo")
		val ns = doc.nodes

		ScreenContent::ITEMS.clear
		ScreenContent::ITEM_MAP.clear

		ns.forEach [ k, v |
			val olit = new OutlineItem(v.gnx, v.h)
			ScreenContent::addItem(olit)
		]

	}

}
