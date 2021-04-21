---
layout: page
title: Articles
---

{% for post in site.posts %}
 
<hr/>

<div class="art-summary">

<div class="art-img">
<a href="{{ post.url | relative_url }}"><img src ="{{post.thumbnail }}"></a>
</div> 
<div class="art-title"> {{ post.title }} </div>
<div class = "art-desc">
{{ post.excerpt }}...<a href ="{{ post.url | relative_url }}">continue reading...</a>
</div>
 
</div>
{% endfor %}

