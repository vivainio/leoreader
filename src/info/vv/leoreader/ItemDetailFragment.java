package info.vv.leoreader;

import com.w.LeoEngine;
import com.w.LeoNode;

import info.vv.leoreader.dummy.ScreenContent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

/**
 * A fragment representing a single Item detail screen. This fragment is either
 * contained in a {@link ItemListActivity} in two-pane mode (on tablets) or a
 * {@link ItemDetailActivity} on handsets.
 */
public class ItemDetailFragment extends Fragment {
	/**
	 * The fragment argument representing the item ID that this fragment
	 * represents.
	 */
	public static final String ARG_ITEM_ID = "item_id";

	/**
	 * Mandatory empty constructor for the fragment manager to instantiate the
	 * fragment (e.g. upon screen orientation changes).
	 */
	public ItemDetailFragment() {
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		if (getArguments().containsKey(ARG_ITEM_ID)) {
			ScreenContent.ITEM_MAP.get(getArguments().getString(
					ARG_ITEM_ID));
		}
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		View rootView = inflater.inflate(R.layout.fragment_item_detail,
				container, false);

		LeoEngine e = LeoEngine.getInstance();
		LeoNode n = e.currentNode();
		
		
		getActivity().setTitle(n.getH());
		
		((TextView) rootView.findViewById(R.id.item_detail))
				.setText(n.getB());
		
		
			
			/*
			String loc = getArguments().getString(
					ARG_ITEM_ID);
			StringBuilder b = new StringBuilder();
			b.append(mItem.content);
			
			List<Course> li = LunchContent.ITEMS.get(loc);
			// fetch the courses for this restaurant
			for (Course c : li) {
				b.append(c.getCategory());
				b.append("\n");
				b.append(c.getTitle());
				b.append("\n");
				
				
			}
			*/
			//String loc = getArguments().getString(
			//		ARG_ITEM_ID);
			
			//Spanned span = LunchEngine.renderLunchList(loc);
			//((TextView) rootView.findViewById(R.id.item_detail))
			//.setText(span);
		

		return rootView;
	}
}
