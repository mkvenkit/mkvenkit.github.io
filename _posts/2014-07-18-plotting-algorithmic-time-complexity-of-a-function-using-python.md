---
layout: post
title: Plotting Algorithmic Time Complexity of a Function using Python
excerpt: Plotting Algorithmic Time Complexity of a Function using Python

date: 2014-07-18 12:16:54.000000000 +05:30
categories:
- Python
tags: []
status: publish
type: post
published: true
comments: true
meta:
  _thumbnail_id: '801'
  _edit_last: '5'
image:
  feature: header.jpg

modified: 2014-07-18

thumbnail: images/2014/07/ac-tn.png
---
<p>I have been reading <a href="http://interactivepython.org/courselib/static/pythonds/index.html">Miller & Ranum's e-book on Python/Algorithms</a>. (A superb book which is also free online.) While looking through their chapter on <em>Algorithm Analysis</em>, I took their idea of using the Python <code>Timer</code> and <code>timeit</code> methods a bit forward to create a simple plotting scheme using <code>matplotlib</code>. </p>
<p><!--more--></p>
<p>Here is the code. You can add in your own function here and plot the time complexity.</p>
<p>The code is quite simple. Perhaps the only interesting thing here is the use of <code>partial</code> to pass in the function and the <code>N</code> parameter into <code>Timer</code>. </p>
<p><script src="https://gist.github.com/electronut/a7290a92b48a66fdebee.js"></script></p>
<p>Here is the output.</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2014/07/Screen-Shot-2014-07-18-at-12.00.36-pm.png"/></p>
<p>Have fun! ;-)</p>
