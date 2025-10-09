class ENV {
  // Barcelona server configuration  
  static const String API_BASE_URL = "https://your-actual-domain.com/api";
  static const String DEFAULT_SAMPLE_ID = "barcelona_study_2025";
  
  // Barcelona-specific RSA public key for end-to-end encryption
  // TODO: Replace with actual Barcelona public key after generation
  static const String BARCELONA_PUBLIC_KEY = '''-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEApikJIWEvUYxYabBSu065
4CbsEqn2nULVTc/GYZMEITD4Fm7cHROKearxVAe21GJq4iWN4Ovp1wYgLjr9il8Z
1T0wiScywqTOSoJu0QQtcnhMZMCsj0l9rL3+9UyMLRHgw/93GQzixwreWX2tN0zp
Q72uKFujZuAB9vzysq6fIsWAWMgvcQzYRzC2uNkJxkC9c9kXavnK0oPXhZyMwtaW
wRuhxh+QYlfi6z2WX5pSHk9SIj5/ifZoitqhT8enR1JqPOcGvZxUM4XlaYA/8+Fb
c+LduktiT0rHKaKUzoLi6KW3bIidMkfMBkMLHBt3rxBxBSSrSiEXJEa/RAvayfmq
XMzL8Kbv3EgKPO2WJlPPA56YbZbRRRTvUfB6ifrnejgw5PluZpx3Q28gUNNzq3qt
IH1Z+KgrCN7zltAKN+mDO9Fnl3W6SAgzOy0m5kO7zYeia9NcGR+7FkruPE3Zt+S2
P0oxhmDxdppoSV4JsrNr5tIInryjmWQW+6Vj2lSxrd1N6WZ69fu/BY5Abu7Zkzyu
o9SZ5VFY+5uwvmrbdyDAOhP/L+Mc/pL7KkVH7tvFcPjCC79VzACaXwAMElMKl1nj
jMXr5kMoSP93byfD3MUAkrUgN4/k2E93jbbm4bOvilpOfVyRTzw5bCWBG5UyhvG+
5ZN2tmbJ3rXipAsfT/hgdUMCAwEAAQ==
-----END PUBLIC KEY-----''';
  
  // Legacy tracking - not used in Barcelona version  
  static const TRACKER_HOST = 'XXX'; // Disabled for Barcelona - using API_BASE_URL instead
}