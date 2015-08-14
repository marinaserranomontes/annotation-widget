package com.opentok.android.plugin;

import android.content.Context;
import android.content.res.XmlResourceParser;
import android.util.Log;
import android.view.View;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

class AnnotationMenuInflator {
    /** MenuItem tag name in XML. */
    private static final String XML_MENU = "menu-item";

    /** Item tag name in XML. */
    private static final String XML_ITEM = "item";

    public interface ActionListener {
        public void didTapMenuItem(AnnotationToolbarMenuItem menuItem);
        public void didTapItem(AnnotationToolbarItem item);
    }

    public static void inflate(Context context, int menuRes, AnnotationMenuView menu, final ActionListener listener) throws IOException, XmlPullParserException {
        XmlResourceParser xrp = context.getResources().getXml(menuRes);
        xrp.next();
        int eventType = xrp.getEventType();
        while (eventType != XmlPullParser.END_DOCUMENT) {
            if (eventType == XmlPullParser.START_TAG) {
                String idAttr = xrp.getAttributeValue("http://schemas.android.com/apk/res/android", "id");
                String iconAttr = xrp.getAttributeValue("http://schemas.android.com/apk/res-auto", "icon");

                int id = -1;
                if (idAttr != null) {
                    id = Integer.parseInt(idAttr.replace("@", ""));
                }

                int iconRes = -1;
                if (iconAttr != null) {
                    iconRes = Integer.parseInt(iconAttr.replace("@", ""));
                }

                if (xrp.getName().equalsIgnoreCase(XML_MENU)) {
                    Log.i("AnnotationsToolbar", "Found menu item: " + xrp.getName());
                    AnnotationToolbarMenuItem menuItem = null;
                    List<AnnotationToolbarItem> items = new ArrayList<AnnotationToolbarItem>();

                    // Iterate through the <item>s until we reach an end tag
                    do {
                        eventType = xrp.next();

                        if (eventType == XmlPullParser.START_TAG && xrp.getName().equalsIgnoreCase("item")) {
                            Log.i("AnnotationsToolbar", "Found submenu item: " + xrp.getName());

                            String itemIdAttr = xrp.getAttributeValue("http://schemas.android.com/apk/res/android", "id");

                            int itemId = -1;
                            if (itemIdAttr != null) {
                                itemId = Integer.parseInt(itemIdAttr.replace("@", ""));
                            }

                            String itemIconAttr = xrp.getAttributeValue("http://schemas.android.com/apk/res-auto", "icon");

                            int itemIconRes = -1;
                            if (itemIconAttr != null) {
                                itemIconRes = Integer.parseInt(itemIconAttr.replace("@", ""));
                            }

                            String action = null;

                            // FIXME Pass the path as an action - not sure using a string is the best route
                            if (itemId == R.id.item_arrow) {
                                action = "Arrow";
                            } else if (itemId == R.id.item_rectangle) {
                                action = "Rectangle";
                            } else if (itemId == R.id.item_oval) {
                                action = "Oval";
                            }
                            items.add(new AnnotationToolbarItem(context, action, itemIconRes));
                        }
                    } while (xrp.getName().equalsIgnoreCase(XML_ITEM));

                    String action = null;

                    if (id == R.id.menu_colors) {
                        // TODO Use tintColor to handle this?
                        final AnnotationToolbarMenuItem item = menuItem = new AnnotationToolbarMenuItem(context, "#ff0000", null);
                        menuItem.setOnClickListener(new View.OnClickListener() {
                            @Override
                            public void onClick(View v) {
                                if (listener != null) {
                                    listener.didTapMenuItem(item);
                                }
                            }
                        });

                        menuItem.setItems(items);
                        menu.addView(menuItem);
                    } else {
                        if (id == R.id.menu_shape) {
                            action = "Shape";
                        }

                        final AnnotationToolbarMenuItem item = menuItem = new AnnotationToolbarMenuItem(context, action, iconRes);
                        menuItem.setOnClickListener(new View.OnClickListener() {
                            @Override
                            public void onClick(View v) {
                                if (listener != null) {
                                    listener.didTapMenuItem(item);
                                }
                            }
                        });

                        menuItem.setItems(items);
                        menu.addView(menuItem);
                    }
                } else if (xrp.getName().equalsIgnoreCase("item")) {
                    Log.i("AnnotationsToolbar", "Found item: " + xrp.getName());
                    String action = null;

                    if (id == R.id.item_pen) {
                        action = "Pen";
                    } else if (id == R.id.item_line) {
                        action = "Line";
                    } else if (id == R.id.item_text) {
                        action = "Text";
                    } else if (id == R.id.menu_clear) {
                        action = "Clear";
                    } else if (id == R.id.menu_capture) {
                        action = "Capture";
                    }

                    final AnnotationToolbarItem item = new AnnotationToolbarItem(context, action, iconRes);
                    item.setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(View v) {
                            if (listener != null) {
                                listener.didTapItem(item);
                            }
                        }
                    });
                    menu.addView(item);
                }
            }
            eventType = xrp.next();
        }
    }
}
