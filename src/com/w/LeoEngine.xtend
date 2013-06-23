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
//import android.R
import java.util.HashMap
import java.util.ArrayList
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import info.vv.leoreader.R
import android.view.LayoutInflater
import android.widget.LinearLayout
import android.widget.LinearLayout$LayoutParams
import android.widget.RelativeLayout
import java.util.Stack

@Data class Course {
}

@Data class LeoEdge {
	String a
	String b
	// depth is redundant, and a hack, just for quick and dirty impl
	int depth	
	
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

	ArrayList<LeoEdge> edges
	
	new() {
		nodes = new Hashtable<String, LeoNode>
		edges = new ArrayList<LeoEdge>

	}

	def getEdges() {
		edges
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
		nodes.clear		//super.getView(position, convertView, parent)
		val p = pf.newPullParser
		p.setInput(new InputStreamReader(is))
		var eventType = p.eventType
		var text = ""
		var gnx = ""		
		var depth = 0
		val parent_stack = new Stack<String>()
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
							val parent_gnx = parent_stack.peek()
							val edge = new LeoEdge(parent_gnx, gnx, depth)
							edges.add(edge)
							nodes.put(gnx, node)
						}
						case "t": {
							val node = get(gnx)
							node.b = text
						}
						
						case "v": {
							parent_stack.pop()		
							depth = depth - 1
						}
					}
				case XmlPullParser::START_TAG:
					switch name {
						case "v": {
							parent_stack.push(gnx)
							gnx = p.getAttributeValue("", "t")							
							
							depth = depth + 1						
						}
							
							
							
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


class HeadlineAdapter extends ArrayAdapter<OutlineItem> {
	
	LayoutInflater inflater
	ArrayList<OutlineItem> items
	
	new(Context c, int layoutResourceId, ArrayList<OutlineItem> data) {
		super(c,0,data)
		//super(c, layoutResourceId, data)
		items = data
		inflater = context.getSystemService(Context::LAYOUT_INFLATER_SERVICE) as LayoutInflater
		
	
	}
	
	override getView(int position, View convertView, ViewGroup parent) {
		//throw new Exception("hello")
		println(" **************8 getView " + position)
	
		val olit = items.get(position)
		
		var view = convertView
		
		if (view == null) {
			view = inflater.inflate(R$layout::headline_item, null)
		}
		

 			
		
		var RelativeLayout$LayoutParams p = new RelativeLayout$LayoutParams(RelativeLayout$LayoutParams::WRAP_CONTENT,
			LinearLayout$LayoutParams::WRAP_CONTENT)
			
		p.setMargins(olit.depth * 5, 0,0,0)		
		
		
		val tv = view.findViewById(R$id::headline_text) as TextView
		tv.setLayoutParams(p)
		
		tv.setText(olit.content)
		
		return view
	
	}
	
}

class LeoEngine {
	LeoDoc doc
	Activity rootActivity
	
	ArrayAdapter<OutlineItem> adapter
	public ArrayList<OutlineItem> ITEMS // = new ArrayList<OutlineItem>();
	
	
	public HashMap<String, OutlineItem> ITEM_MAP
		
	
	
	def setRootActivity(Activity a) {
		rootActivity = a
		
		adapter = new HeadlineAdapter(a,
			R$id::headline_list_item,			
			ITEMS
		);
				 		
	}
	
	
	static LeoEngine _le

	LeoNode _currentNode

	new() {
		ITEM_MAP = new HashMap<String, OutlineItem>()
		ITEMS = new ArrayList<OutlineItem>()
		val ol = new OutlineItem("a", "",0)
		ITEMS.add(ol)
		val ol2 = new OutlineItem("b", "",0)
		ITEMS.add(ol2)

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
		val edges = doc.edges
		val ns = doc.nodes
		ITEMS.clear
		ITEM_MAP.clear
		edges.forEach[ edge |
			
			val v = ns.get(edge.b)
			println("Edge: " + edge.toString )
			val olit = new OutlineItem(v.gnx, v.h, edge.depth)
			addItem(olit)
		]
		/*
		ns.forEach [ k, v |
			val olit = new OutlineItem(v.gnx, v.h)
			addItem(olit)
		]
		*  */
		
		adapter.notifyDataSetChanged

	}

}
// ui classes
