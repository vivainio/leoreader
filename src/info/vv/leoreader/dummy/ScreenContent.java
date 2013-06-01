package info.vv.leoreader.dummy;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Helper class for providing sample content for user interfaces created by
 * Android template wizards.
 * <p>
 * TODO: Replace all uses of this class before publishing your app.
 */
public class ScreenContent {

	/**
	 * An array of sample (dummy) items.
	 */
	public static List<OutlineItem> ITEMS = new ArrayList<OutlineItem>();

	/**
	 * A map of sample (dummy) items, by ID.
	 */
	public static Map<String, OutlineItem> ITEM_MAP = new HashMap<String, OutlineItem>();

	static {
		// Add 3 sample items.
		addItem(new OutlineItem("731", "Hermia 3"));
		addItem(new OutlineItem("424", "Hermia 6"));
		//addItem(new DummyItem("3", "Item 3"));
	}

	public static void addItem(OutlineItem item) {
		ITEMS.add(item);
		ITEM_MAP.put(item.id, item);
	}

	/**
	 * A dummy item representing a piece of content.
	 */
	public static class OutlineItem {
		public String id;
		public String content;

		public OutlineItem(String id, String content) {
			this.id = id;
			this.content = content;
		}

		@Override
		public String toString() {
			return content;
		}
	}
}
