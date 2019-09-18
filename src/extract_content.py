#!/usr/bin/env python3
# coding: utf8
# 事前準備
#   pip3 install extractcontent3
#   wget -O index.html 適当なニュースサイトURL
import sys
import os
import extractcontent3

def format_to_text(html):
    import re
    import unicodedata
    st = re.sub(r"<p>([^　])", r"　\1", html) # 段落の先頭は全角スペース
    st = re.sub(r"</p>", "\n\n", st) # 段落の末尾は2つ改行する
    st = re.sub(r"</br>", "\n", st)
    st = re.sub(r"<br>", "\n", st)
    st = re.sub(r"<.+?>", "", st)
    # Convert from wide character to ascii
    if st and type(st) != str: st = unicodedata.normalize("NFKC", st)
    st = re.sub(r"[\u2500-\u253f\u2540-\u257f]", "", st)  # 罫線(keisen)
    st = re.sub(r"&(.*?);", lambda x: self.CHARREF.get(x.group(1), x.group()), st)
    st = re.sub(r"[ \t]+", " ", st)
    return st.rstrip("\n\t ")

if len(sys.argv) < 1:
    raise Error('第1引数にHTMLファイルパスを指定してください。')
    exit()
if not os.path.isfile(sys.argv[0]): 
    raise Error('第1引数HTMLファイルパスが存在しません。:'+sys.argv[0])
    exit()

extractor = extractcontent3.ExtractContent()
#https://github.com/yono/python-extractcontent
#opt = {"threshold":50}
#extractor.set_option(opt)

html = open("index.html").read()
extractor.analyse(html)
html, title = extractor.as_html()
print(format_to_text(html))

