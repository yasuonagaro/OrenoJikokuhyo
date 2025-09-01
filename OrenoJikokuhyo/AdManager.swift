//
//  AdManager.swift
//  OrenoJikokuhyo
//
//  Created by ynagaro on 2025/09/01.
//

import UIKit
import GoogleMobileAds

class AdManager: NSObject, BannerViewDelegate {

    func startGoogleMobileAdsSDK(bannerView: BannerView, rootViewController: UIViewController, in view: UIView, adUnitID: String) {
        // バナー広告の設定
        bannerView.adUnitID = adUnitID // テスト用広告ユニットID
        bannerView.rootViewController = rootViewController // バナー広告の表示に必要
        bannerView.delegate = self // BannerViewDelegateを設定
        
        // Google Mobile Ads SDKの初期化
        MobileAds.shared.start()
        
        let frame = view.frame // 画面全体のフレームを取得
        let viewWidth = frame.inset(by: view.safeAreaInsets).width // 安全領域を考慮した幅を取得
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth) // 画面幅に合わせたバナーサイズ
        
        // 広告リクエストの作成と読み込み
        bannerView.load(Request())
    }
    
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
      print(#function)
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
      print(#function + ": " + error.localizedDescription)
    }

    func bannerViewDidRecordClick(_ bannerView: BannerView) {
      print(#function)
    }

    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
      print(#function)
    }

    func bannerViewWillPresentScreen(_ bannerView: BannerView) {
      print(#function)
    }

    func bannerViewWillDismissScreen(_ bannerView: BannerView) {
      print(#function)
    }

    func bannerViewDidDismissScreen(_ bannerView: BannerView) {
      print(#function)
    }
}
