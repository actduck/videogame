package com.actduck.videogame.ui.ads;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.RatingBar;
import android.widget.TextView;
import com.actduck.videogame.R;
import com.google.android.gms.ads.nativead.MediaView;
import com.google.android.gms.ads.nativead.NativeAd;
import com.google.android.gms.ads.nativead.NativeAdView;
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin;
import java.util.Map;

import static android.view.View.GONE;
import static android.view.View.VISIBLE;

public class HomeTileNativeAdFactory implements GoogleMobileAdsPlugin.NativeAdFactory {

  private final Context context;

  public HomeTileNativeAdFactory(Context context) {
    this.context = context;
  }

  @Override
  public NativeAdView createNativeAd(
      NativeAd nativeAd, Map<String, Object> customOptions) {
    NativeAdView nativeAdView = (NativeAdView) LayoutInflater.from(context)
        .inflate(R.layout.home_tile_native_ad, null);

    TextView attributionViewSmall = nativeAdView
        .findViewById(R.id.tv_list_tile_native_ad_attribution_small);
    TextView attributionViewLarge = nativeAdView
        .findViewById(R.id.tv_list_tile_native_ad_attribution_large);
    MediaView mediaView = nativeAdView.findViewById(R.id.media_view);
    RatingBar ratingBar = nativeAdView
        .findViewById(R.id.rating_bar);

    mediaView.setImageScaleType(ImageView.ScaleType.CENTER_CROP);

    ImageView iconView = nativeAdView.findViewById(R.id.iv_list_tile_native_ad_icon);
    NativeAd.Image icon = nativeAd.getIcon();
    if (icon != null) {
      attributionViewSmall.setVisibility(VISIBLE);
      attributionViewLarge.setVisibility(View.INVISIBLE);
      iconView.setImageDrawable(icon.getDrawable());
    } else {
      attributionViewSmall.setVisibility(View.INVISIBLE);
      attributionViewLarge.setVisibility(VISIBLE);
    }
    nativeAdView.setIconView(iconView);

    TextView headlineView = nativeAdView.findViewById(R.id.tv_list_tile_native_ad_headline);
    headlineView.setText(nativeAd.getHeadline());
    nativeAdView.setHeadlineView(headlineView);

    TextView bodyView = nativeAdView.findViewById(R.id.tv_list_tile_native_ad_body);
    bodyView.setText(nativeAd.getBody());
    bodyView.setVisibility(nativeAd.getBody() != null ? VISIBLE : View.INVISIBLE);
    nativeAdView.setBodyView(bodyView);

    //  Set the secondary view to be the star rating if available.
    Double starRating = nativeAd.getStarRating();

    if (starRating != null && starRating > 0) {
      //secondaryView.setVisibility(GONE);
      ratingBar.setVisibility(VISIBLE);
      ratingBar.setRating(starRating.floatValue());

      nativeAdView.setStarRatingView(ratingBar);
    } else {
      //secondaryView.setText(secondaryText);
      //secondaryView.setVisibility(VISIBLE);
      ratingBar.setVisibility(GONE);
    }

    nativeAdView.setMediaView(mediaView);

    nativeAdView.setNativeAd(nativeAd);

    return nativeAdView;
  }
}

