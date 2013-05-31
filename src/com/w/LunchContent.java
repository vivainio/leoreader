package com.w;

import java.util.HashMap;
import java.util.List;
import java.util.Map;


/**
 * Helper class for providing sample content for user interfaces created by
 * Android template wizards.
 * <p>
 * TODO: Replace all uses of this class before publishing your app.
 */
public class LunchContent {

	
	public static Map<String, List<Course>> ITEMS = new HashMap<String, List<Course>>(); 
	/**
	 * An array of sample (dummy) items.
	 */
	//public static List<Course> ITEMS = new ArrayList<Course>();

	/**
	 * A map of sample (dummy) items, by ID.
	 */
	
	public static Map<String, Course> ITEM_MAP = new HashMap<String, Course>();

	static {
		
		// Add 3 sample items.
		//addItem(new Course("1", "Hermia 3"));
		//addItem(new Course("2", "Hermia 6"));
		//addItem(new DummyItem("3", "Item 3"));
	}

	

}
