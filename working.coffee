"""
<file_info>
    <sha1>9640a4d47ede6a0f5cbf3618bd5812b75a386b7f</sha1>
    <sha256>79ae7fa301ff452a0147c4072ebaa89e755461f2b4803a1fef30db9e157e243a</sha256>
    <md5>c21cdead06ae1e433c8c 1d7f6fb3f52d</md5>
    </br>
    <filetype>Microsoft Wo<b> aaa</b>rd 97 - 2003 Document</filetype>
    <size>43008</size>
    <malware>no</malware>
</file_info>
"""

findTag = (s, pattern) ->
  v = s.match(pattern)
  console.log v
  # s.match(pattern)
  v

scanTag = (s, pattern) ->
  findTag(s, pattern).map (tag) ->
    console.log tag
    {tag: tag, state: getTagState(tag)}

getTagState = (tag) ->
  if tag.match(/^<\//)
    'close'
  else
    'open'

# tagPattern = /(<(\/?))([^\s>]+)(>)/
tagPattern = /(<(\/?))([^\s>]+)[^>]*>/
# pattern = /(<(\/?))([^\s>]+)([\s>]|$)/g
# {inspect} = require 'util'
p = (args...) -> console.log inspect(args...)
# p scanTag(s, pattern)
checkTag = (s) ->
  m = s.match(tagPattern)
  console.log m
  [__, __, close, tagname, closed] = m
  # console.log [close, tagname, closed]

checkTag "<abc>"
checkTag "</abc>"
checkTag "<hr />"
checkTag "<hr>"
