dynamic override(dynamic input) {
  final Map<String, dynamic> template = {
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
  };

  // 输出对象，拷贝输入
  final dynamic out = Map.from(input);
  out["dns"] = template["dns"];
  out["tun"] = template["tun"];

  return out;
}