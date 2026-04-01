dynamic override(dynamic input) {
  final List<dynamic> proxies = (input["proxies"] as List? ?? []);

  // 内置完整 YAML 模板
  final dynamic out = {
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
        "include-all": true,
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
        "include-all": true,
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
        "include-all": true,
        "timeout": 2000,
        "max-failed-times": 2,
        "proxies": <String>[]
      }
    ],
    "proxies": proxies
  };


  return out;
}