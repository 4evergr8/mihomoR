Map<String, dynamic> override(Map<String, dynamic> input) {


  final Map<String, dynamic> template = {
    "tun": {
      "enable": true,
      "stack": "system",
      "device": "tun0",
      "auto-route": true,
      "auto-detect-interface": true,
      "strict-route": true,
      "exclude-package": [
        "com.byyoung.setting",
        "com.tencent.mm",
        "com.xunmeng.pinduoduo",
        "com.zhihu.android",
        "com.autonavi.minimap",
        "com.taobao.taobao",
        "com.android.bluetooth",
        "com.eg.android.AlipayGphone",
        "org.localsend.localsend_app",
        "com.coolapk.market",
        "com.coloros.accessibilityassistant",
        "com.oplus.blacklistapp",
        "com.coloros.directui",
        "com.coloros.ocrscanner",
        "com.quark.browser",
        "tv.danmaku.bili",
        "com.xunlei.downloadprovider",
        "com.tmall.wireless",
        "com.oplus.cast",
        "com.ss.android.ugc.aweme",
        "com.bilibili.app.in",
        "com.heytap.cloud",
        "com.mfcloudcalculate.networkdisk",
        "com.tencent.androidqqmail",
        "com.oplus.account",
        "com.hpbr.bosszhipin",
        "com.MobileTicket",
        "com.baidu.netdisk",
        "com.bilibili.studio",
        "com.tencent.tim",
        "com.coloros.translate",
        "com.taobao.litetao",
        "com.oplus.vdc",
        "com.heytap.speechassist",
        "com.oplus.aimemory"
      ]
    },
    "dns": {
      "enable": true,
      "cache-algorithm": "lru",
      "prefer-h3": false,
      "listen": "0.0.0.0:1053",
      "ipv6": true,
      "enhanced-mode": "fake-ip",
      "fake-ip-range": "198.18.0.1/16",
      "fake-ip-filter-mode": "blacklist",
      "fake-ip-filter": ["geosite:cn", "geosite:private"],
      "use-hosts": false,
      "use-system-hosts": true,
      "default-nameserver": ["tls://1.12.12.12:853", "tls://223.5.5.5:853"],
      "nameserver": [
        "https://dns.alidns.com/dns-query#h3=true",
        "https://doh.pub/dns-query"
      ],
      "proxy-server-nameserver": [
        "https://cloudflare-dns.com/dns-query#h3=true",
        "https://dns.google/dns-query#h3=true",
        "tls://1.1.1.1:853",
        "tls://8.8.8.8:853"
      ]
    },
  };

  // 输出对象，拷贝输入
  final Map<String, dynamic> out = Map<String, dynamic>.from(input);

  // 删除原有 dns 和 tun 完全替换
  out["dns"] = template["dns"];
  out["tun"] = template["tun"];

  return out;
}