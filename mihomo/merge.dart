Map<String, dynamic> override(Map<String, dynamic> input) {
  final List<Map<String, dynamic>> proxies =
  (input["proxies"] as List? ?? []).cast<Map<String, dynamic>>();

  // 内置完整 YAML 模板
  final Map<String, dynamic> out = {
    "mode": "rule",
    "external-controller": "127.0.0.1:9090",
    "external-ui": "./metacubexd",
    "allow-lan": false,
    "log-level": "warning",
    "ipv6": true,
    "keep-alive-idle": 0,
    "keep-alive-interval": 30,
    "disable-keep-alive": true,
    "unified-delay": true,
    "tcp-concurrent": true,
    "geodata-loader": "memconservative",
    "find-process-mode": "off",
    "geo-auto-update": true,
    "geo-update-interval": 24,
    "etag-support": true,
    "geodata-mode": true,
    "geox-url": {
      "geoip":
      "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat",
      "geosite":
      "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
    },
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
    "rules": [
      "GEOSITE,category-ads-all,REJECT-DROP",
      "IP-CIDR,0.0.0.0/32,REJECT-DROP,no-resolve",
      "GEOSITE,cn,DIRECT",
      "GEOSITE,private,DIRECT",
      "GEOIP,cn,DIRECT,no-resolve",
      "GEOIP,private,DIRECT,no-resolve",
      "GEOSITE,CATEGORY-AI-!CN,🧠人工智能🧠",
      "DOMAIN-SUFFIX,jp,🇯🇵日本网站🇯🇵",
      "GEOSITE,DLSITE,🇯🇵日本网站🇯🇵",
      "GEOSITE,DMM,🇯🇵日本网站🇯🇵",
      "DOMAIN,rss.4evergr8.workers.dev,🇯🇵日本网站🇯🇵",
      "GEOSITE,category-cryptocurrency,🪙加密货币🪙",
      "GEOSITE,youtube,🌍国外媒体🌍",
      "MATCH,⚡自动选择⚡"
    ],
    "proxy-groups": [
      {
        "name": "⚡自动选择⚡",
        "type": "url-test",
        "url": "https://www.google.com",
        "exclude-filter":
        "直连|订阅|到期|官网|剩余|RU|俄罗斯|🇷🇺|KR|韩国|🇰🇷",
        "icon":
        "https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Dark/Speedtest.png",
        "interval": 600,
        "lazy": false,
        "timeout": 2000,
        "max-failed-times": 2,
        "tolerance": 50,
        "proxies": <String>[]
      },
      {
        "name": "🧠人工智能🧠",
        "type": "url-test",
        "url": "https://chatgpt.com",
        "exclude-filter":
        "直连|订阅|到期|官网|剩余|RU|俄罗斯|🇷🇺|HK|香港|🇭🇰",
        "icon":
        "https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Dark/Bot.png",
        "interval": 617,
        "lazy": true,
        "timeout": 2000,
        "max-failed-times": 2,
        "tolerance": 50,
        "proxies": <String>[]
      },
      {
        "name": "🌍国外媒体🌍",
        "type": "url-test",
        "url": "https://music.youtube.com",
        "exclude-filter":
        "直连|订阅|到期|官网|剩余|RU|俄罗斯|🇷🇺|KR|韩国|🇰🇷|VN|越南|🇻🇳|MY|马来西亚|🇲🇾|🇷🇺|HK|香港|🇭🇰",
        "icon":
        "https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Dark/YouTube_Music.png",
        "interval": 631,
        "lazy": true,
        "timeout": 2000,
        "max-failed-times": 2,
        "proxies": <String>[]
      },
      {
        "name": "🇯🇵日本网站🇯🇵",
        "type": "fallback",
        "url": "https://special.dmm.com",
        "filter": "JP|日本|🇯🇵",
        "icon":
        "https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Dark/Japan.png",
        "interval": 647,
        "lazy": true,
        "timeout": 2000,
        "max-failed-times": 2,
        "proxies": <String>[]
      },
      {
        "name": "🪙加密货币🪙",
        "type": "url-test",
        "url": "https://api.binance.com/api/v3/ping",
        "exclude-filter":
        "直连|订阅|到期|官网|剩余|RU|俄罗斯|🇷🇺|HK|香港|🇭🇰|US|美国|🇺🇸|CA|加拿大|🇨🇦",
        "icon":
        "https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Dark/Available_Alt.png",
        "interval": 659,
        "lazy": true,
        "timeout": 2000,
        "max-failed-times": 2,
        "proxies": <String>[]
      }
    ],
    "proxies": proxies
  };

  final proxyNames = proxies.map((e) => e['name'].toString()).toList();

  // 填充自动选择组
  final autoGroup =
  (out["proxy-groups"] as List).firstWhere((g) => g["name"] == "⚡自动选择⚡");
  autoGroup["proxies"] = proxyNames;

  // 填充其他分组
  for (final group in out["proxy-groups"]) {
    final String name = group["name"];
    if (name == "⚡自动选择⚡") continue;

    List<String> matched = [];

    if (group.containsKey("filter")) {
      final reg = RegExp(group["filter"]);
      matched = proxyNames.where((n) => reg.hasMatch(n)).toList();
      if (matched.isNotEmpty) matched.add("⚡自动选择⚡");
    } else if (group.containsKey("exclude-filter")) {
      final reg = RegExp(group["exclude-filter"]);
      matched = proxyNames.where((n) => !reg.hasMatch(n)).toList();
      if (matched.isEmpty) matched.add("⚡自动选择⚡");
    }

    group["proxies"] = matched;
  }

  return out;
}