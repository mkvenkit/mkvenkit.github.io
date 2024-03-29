---
layout: post
title: Koch Snowflake and the Thue-Morse Sequence
excerpt: Guess what's hidden in the snowflake? Math is deep.
date: 2014-08-03 13:44:35.000000000 +05:30
categories:
- Python
tags:
- fractal
- Koch snowflake
- Python
- recursion
- Thue-Morse
status: publish
type: post
published: true
comments: true
meta:
  _edit_last: '5'
  _thumbnail_id: '814'

modified: 2014-08-03

thumbnail: images/2014/08/koch-tn.png
---
<p>When you first study recursion, you will invariably run into a "factorial" example. But if you are lucky, you will also run into a far more interesting algorithm - one that draws a fractal geometry construct called the "Koch snowflake". This curve was discovered in 1904 by Swedish mathematician Helge von Koch [1]. Drawing this curve is straightforward, and we will do so using Python <code>turtle</code> graphics. But this curve also has a deeper connection with a mathematical sequence called the Thue-Morse sequence [2], which we will explore in a bit.</p>
<p><!--more--></p>
<h2>Koch Snowflake Construction</h2>
<p>The Koch snowflake being a fractal, its structure can be defined in terms of itself. The math involved is shown in the figure below.</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2014/08/Doc-03-08-14-8-34-am.jpg"/>
</p>
<p>Once you know how to draw the line $$A_{1}-P_{1}-P_{2}-P_{3}-B$$ you can draw the curve recursively as follows.</p>
<p><code><br />
drawKoch(A, B):<br />
&nbsp; &nbsp;if |AB| < delta:<br />
&nbsp; &nbsp;&nbsp; &nbsp;draw A-P1-P2-P3-B<br />
&nbsp; &nbsp;else:<br />
&nbsp; &nbsp;&nbsp; &nbsp;drawKoch(A, P1)<br />
&nbsp; &nbsp;&nbsp; &nbsp;drawKoch(P1, P2)<br />
&nbsp; &nbsp;&nbsp; &nbsp;drawKoch(P2, PP3)<br />
&nbsp; &nbsp;&nbsp; &nbsp;drawKoch(P3, B)<br />
</code></p>
<p>Now we are ready to draw this with <em>turtle</em>. The output is shown below. (Full code listing at the end of this article.)</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2014/08/Screen-Shot-2014-08-03-at-9.39.48-am.png"/>
</p>
<h2>Connection with the Thue-Morse Sequence</h2>
<p>The Thue-Morse sequence is constructed as follows:</p>
<ol>
<li>Start with <code>0</code>.</li>
<li>Append the complement. You get <code>01</code>.</li>
<li>Repeat the previous step.</li>
</ol>
<p>Here are the first five terms of the above procedure:</p>
<p><code>0<br />
01<br />
0110<br />
01101001<br />
0110100110010110<br />
</code></p>
<p>Now, consider the following drawing procedure.</p>
<p>Let \( t(n) \) be the Thue-Morse sequence.</p>
<ul>
<li>
If \( t(n) \) is 0, move forward by one unit.
</li>
<li>
If \( t(n) \) is 1, rotate (just change heading, don't move) by 60 degrees anti-clockwise.
</li>
</ul>
<p>Keep repeating the above procedure, and guess what you get? Something astonishingly similar to the Koch snowflake! This idea has been explored by Jun Ma and Judy Holdener, in their 2005 paper "When Thue-Morse Meets Koch" [3]. The paper is not for the faint of heart, and although I am no mathematician, it looks like you need a background in Abstract Algebra and Topology to understand it. But you don't need to know much to draw it. Here is what you get when you put turtle to task to draw the above.</p>
<p style="padding:20px;">
<img src="{{ site.baseurl }}/images/2014/08/Screen-Shot-2014-08-02-at-5.18.39-pm.png"/>
</p>
<p>I think this is mind-blowing, and this is why I love mathematics! ;-)</p>
<p>Below is the full source code. Notice that we use a Python <code>generator</code> to create the Thue-Morse sequence.</p>
<p>To see the traditional Koch snowflake, run as:</p>
<p><code>$python koch.py</code></p>
<p>To see the Thue-Morse magic in action, run as:</p>
<p><code>$python koch.py --thue<br />
</code></p>
<p><script src="https://gist.github.com/electronut/3b07fe9c7ca8a9ccdf9f.js"></script></p>
<h2>References</h2>
<ol>
<li>
<a href="http://en.wikipedia.org/wiki/Koch_snowflake">http://en.wikipedia.org/wiki/Koch_snowflake</a>
</li>
<li>
<a href="http://en.wikipedia.org/wiki/Thue%E2%80%93Morse_sequence">http://en.wikipedia.org/wiki/Thue%E2%80%93Morse_sequence</a>
</li>
<li>
JUN MA AND JUDY HOLDENER, "When Thue-Morse meets Koch," Fractals: Complex Geometry, Patterns, and Scaling in Nature and Society,13(2005) 191-206.
</li>
</ol>
