package com.w

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.LinearLayout
import android.widget.RelativeLayout
import android.widget.TextView
import info.vv.leoreader.R
import info.vv.leoreader.dummy.ScreenContent
import info.vv.leoreader.dummy.ScreenContent$OutlineItem
import java.io.FileInputStream
import java.io.InputStream
import java.io.InputStreamReader
import java.util.ArrayList
import java.util.HashMap
import java.util.Hashtable
import java.util.Stack
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory


@Data class LeoEdge {
	String a
	String b
	// depth is redundant, and a hack, just for quick and dirty impl
	int depth	
	
}

class LeoNode {

	@Property String h
	@Property String b
	@Property String gnx
	
	new(String gnx, String h, String b) {
		_gnx = gnx;
		_h = h;
		_b = b

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
			//println(name)
			switch eventType {
				case XmlPullParser::TEXT:
					text = p.text
				case XmlPullParser::END_TAG:
					switch name {
						case "vh": {
							//println('''End tag vh t = «text» gnx = «gnx»''')
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
		//println(" **************8 getView " + position)
	
		val olit = items.get(position)
		
		var view = convertView
		
		if (view == null) {
			view = inflater.inflate(R$layout::headline_item, null)
		}
		
		var RelativeLayout$LayoutParams p = new RelativeLayout$LayoutParams(RelativeLayout$LayoutParams::WRAP_CONTENT,
			LinearLayout$LayoutParams::WRAP_CONTENT)
			
		p.setMargins(olit.depth * 15, 0,0,0)		
		
		
		val tv = view.findViewById(R$id::headline_text) as TextView
		tv.setLayoutParams(p)
		
		tv.setText(olit.content)
		
		return view
	
	}
	
}

class LeoGui {
	
	Activity _activity
	
	new(Activity a) {
		_activity = a
	}
	
	def openFile() {
		//share()
		val intent = new Intent("org.openintents.action.PICK_FILE")
		_activity.startActivityForResult(intent, 1)		
		
	}
	
	def share() {
		val shareintent = new Intent(android.content.Intent.ACTION_SEND)
		shareintent.type = "text/plain"
		shareintent.putExtra(android.content.Intent.EXTRA_SUBJECT, "Leo snippet")
		shareintent.putExtra(android.content.Intent.EXTRA_TEXT, "Longer text with stuff")
		
		_activity.startActivity(Intent.createChooser(shareintent, "Share to"))
	}
}

class LeoEngine {
	LeoDoc doc
	Activity rootActivity
	LeoGui gui
	
	ArrayAdapter<OutlineItem> adapter
	public ArrayList<OutlineItem> ITEMS // = new ArrayList<OutlineItem>();
	
	
	public HashMap<String, OutlineItem> ITEM_MAP
		
	
	
	def setRootActivity(Activity a) {
		rootActivity = a
		gui = new LeoGui(rootActivity)	
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
		
		val ol = new OutlineItem("_openfile", "Open a .leo file to start", 0)		
		ITEMS.add(ol)

	}

	def getAdapter() {
		adapter
	}

	def currentNode() {
		_currentNode
	}

	def boolean selectNode(String gnx) {
		switch gnx {
			case '_openfile': {
				gui.openFile()
				return false
			}
			default: {
				_currentNode = doc.get(gnx)
				return true				
			}
			
			
		}		
		
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
		
		adapter.notifyDataSetChanged

	}

}
// ui classes
