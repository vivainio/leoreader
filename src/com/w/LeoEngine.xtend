package com.w

import info.vv.leoreader.dummy.ScreenContent
import info.vv.leoreader.dummy.ScreenContent$OutlineItem
import java.io.FileReader
import java.util.Hashtable
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory
import android.content.Intent
import java.io.InputStreamReader
import java.io.InputStream
import java.io.FileInputStream
import android.net.Uri
import android.content.ContentResolver
import android.app.Activity
import android.widget.ArrayAdapter
import android.content.Context
import java.util.List
import android.R
import java.util.HashMap
import java.util.ArrayList

@Data class Course {
}

class LeoNode {

	String _h
	String _b
	String _gnx

	new(String gnx, String h, String b) {
		_gnx = gnx;
		_h = h;
		_b = b

	}

	def void setB(String body) {
		_b = body
	}

	def getH() {
		_h
	}

	def getB() {
		_b
	}

	def getGnx() {
		_gnx
	}

}

class LeoDoc {
	Hashtable<String, LeoNode> nodes

	new() {
		nodes = new Hashtable<String, LeoNode>

	}

	def getNodes() {
		nodes
	}

	def LeoNode get(String gnx) {
		nodes.get(gnx)
	}

	def readFile(String fname) {
		read(new FileInputStream(fname));

	}

	def read(InputStream is) {
		val pf = XmlPullParserFactory::newInstance
		nodes.clear
		val p = pf.newPullParser
		p.setInput(new InputStreamReader(is))
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
							val node = new LeoNode(gnx, text, "some body\nnew line")
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
	Activity rootActivity
	ArrayAdapter<OutlineItem> adapter
	public List<OutlineItem> ITEMS // = new ArrayList<OutlineItem>();
	public HashMap<String, OutlineItem> ITEM_MAP

	def setRootActivity(Activity a) {
		rootActivity = a
		adapter = new ArrayAdapter<OutlineItem>(a, R$layout::simple_list_item_activated_1, R$id::text1, ITEMS);
	}

	static LeoEngine _le

	LeoNode _currentNode

	new() {
		ITEM_MAP = new HashMap<String, OutlineItem>()
		ITEMS = new ArrayList<OutlineItem>()

	}

	def getAdapter() {
		adapter
	}

	def currentNode() {
		_currentNode
	}

	def selectNode(String gnx) {
		_currentNode = doc.get(gnx)
	}

	def currentBody() {
		return _currentNode.b
	}

	static def getInstance() {
		if (_le == null) {
			_le = new LeoEngine
		}
		return _le

	}

	def openURl(Uri uri) {
		doc = new LeoDoc
		doc.read(rootActivity.contentResolver.openInputStream(uri))
		render()
	}

	def addItem(OutlineItem item) {
		ITEMS.add(item)
		ITEM_MAP.put(item.id, item)
	}

	def render() {
		val ns = doc.nodes
		ITEMS.clear
		ITEM_MAP.clear

		ns.forEach [ k, v |
			val olit = new OutlineItem(v.gnx, v.h)
			addItem(olit)
		]
		adapter.notifyDataSetChanged

	}

}
// ui classes
