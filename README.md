MSS: messed up style sheet
==========================

Write modular, composable CSS in a functional way with pure javascript.  Check out the [online compiler](http://winterland1989.github.io/mss).

Intro
-----

MSS.parse takes a mss object as input and output a css string

+ A mss object is a plain javascript object, usually nested

+ A key will be a CSS selector if its value is another mss object, otherwise it will be taken as a property name for CSS.

+ MSS will parse the nested object into nested selectors by connnecting selectors into a descendant selector

Let's see an example:

```javascript
mss = {
  FooClass: {
    zIndex: 999,
    $BarId_AnotherClass: {
      MozBoxShadow: '10px 10px 5px #888',
      input: {
        borderRadius: '12px',
        padding: '12px',
        width: '100%'
      }
    }
  }
};

// set second argmument to true to enable prettify
console.log(MSS.parse(mss, true));

```

will yield:

```css
.FooClass #barId input,
.FooClass .AnotherClass input{
  border-radius:12px;
  padding:12px;
  width:100%;
}
.FooClass #barId,
.FooClass .AnotherClass{
  -moz-box-shadow:10px 10px 5px #888;
}
.FooClass{
  z-index:999;
}
```

As shown above, the selectors and prop name are converted for the writing ease in Javascript(using valid variable as much as possible) 

As a coffeescript user, i would write former example in coffeescript:

```coffee
mss =
    FooClass:
        zIndex: 999
        $BarId_AnotherClass:
            MozBoxShadow: '10px 10px 5px #888888'
            Input:
                borderRadius: '12px'
                padding: '12px'
                width: '100%'   
                
console.log MSS.parse(mss, true)
```

Much nicer! For the sake of clearity, following example will be written in coffee, really sorry for the inconveince, but coffeescript's object literal is very easy to read. Let's explain how mss translate your plain object into a css string in detail:

Rules for parsing a mss selectors
---------------------------------

+ Class selector is written in UpperCase and keep UpperCase
+ html tag selector is written in lowerCase and keep lowerCase
+ id selector is written in $UpperCase and turn into lowerCase

mss

    Slider: 
        margin: ...

    canvas: 
        margin: ...

    $Index:
        margin: ...

css

    .Slider { margin: ...}

    canvas { margin: ...}

    #index { margin: ...}

+ `$` used to write pesudo-class selector:

mss

    SliderBtn:
        padding: ...
        $hover:
            color: ...

css

    .SliderBtn { padding: ... }
    .SliderBtn:hover { color: ... }

+ `_` turn selector into a list of selectors, and you can nest list

mss

    BlueBird_BlueOcean:
        color: \blue
        RedText_$RedWine_Span:
            color: \red

css

    .BlueBird, 
    .BlueOcean {
        color: blue;
    }
    .BlueBird .RedText, 
    .BlueBird #redWine,
    .BlueBird span,
    .BlueOcean .RedText, 
    .BlueOcean #redWine,
    .BlueOcean span { 
        color: red;
    }

Rules for parsing a mss property name
-------------------------------------

+ turn `camelCase` to `camel-case` and `MyCamelCase` to `-my-camel-case`

mss

    FooBar:
        marginLeft: \50%
        MozBoxShadow: '10px 10px 5px #888888'

css

    .FooBar {
        margin-left: 50%;
        -moz-box-shadow: 10px 10px 5px #888888;
    }

Notes
-----

+ You can use an array of mss as a mss object, and mss will merge all the elements first(from the first to last order, so the last one with the hightest precedence), this's very handy when you want to compose nested mss.

mss

    otherMss =
        OtherWidget:
                margin: '2px'

    Foo: [
            padding: '10px'
            Bar:
                color: '#ddd'
        ,    
            otherMss
        ]

css
    
    .Foo{
        padding: 10px;
    }
    .Foo Bar{
        color: '#ddd';
    }
    .Foo .OtherWidget{
        margin: '2px';
    }

+ Number values can be use as property values, they will be converted to string, eg. `margin: 0` will be parsed as `margin: '0'`, so if you want to add unit, write string literals like `'2px'` or `'10%'`.

+ While the selector's syntax covered most of the cases in basic modular css design, You can alway fallback to write a real css selector using string literal as key:

mss

    '.css-selector:nth-child(2)':
        background: '#ff0000';

css

    .css-selector::nth-child(2){
        background: #ff0000;
    } 

+ Selectors begin with `@` are preserved to make media query and keyframe composable, see [here](https://github.com/winterland1989/mss#special-mixins)

Functions and Mixins
--------------------

Here comes the fun part, since the plain mss object you write is actual a simplified CSS AST, so all functions and mixins can be write in plain javascript.

Functions
---------

Since all property are strings, we can write a function to help us convert between numbers and string, for example:

mss

    px = (x) -> x + 'px' 
    pc = (x) -> x + '%'

    $OhMyGod:
        margin: px 2
        padding: pc 10

css

    #ohMyGod {
        margin: 2px 4px 5px;
        padding 10% 10%;
    }
 
There's some functions built-in with mss, they are written in camelCase, such as `px` or `hsl`, and often they are quite general, for example the built-in `px` function can take multiple arguments, here's built-in list:

```coffee
num           # num('2px') == 2
unit          # unit('2%') == '%'
px            # px(1, 2, 3) == '1px, 2px, 3px'
pc            # pc(1, 2, 3) == '1%, 2%, 3%'

gold          # px(v) == Math.round(v*0.618), golden ratio caculator
goldR         # px(v) == Math.round(v/0.618), golden ratio caculator 2

rgb           # rgb(0, 128, 255) == 'rgb(0,128,255)'
rgba          # rgba(0, 128, 255, 0.2) == 'rgba(0,128,255,0.2)'
bw            # bw(128) == 'rgb(128,128,128)'
hsl           # same as rgb, h: 0~360, s: 0~100, l: 0~100
hsla          # same as rgba, h: 0~360, s: 0~100, l: 0~100 a: 0.0~1.0
```

Mixins
------

Mixins are special functions, they should take some parameters(or none if don't need), then return a function that modify mss objects, let's write one:

mss

    Center$ = (mss) ->
        mss.textAlign = 'center'
        mss

    Padding = (pad) -> (mss) ->
        mss.padding = pad
        mss


    input: Center$ Padding('2px')
        margin: 0

css

    input{
        margin: 0;
        padding: '2px';
        text-align: 'center';
    }

The mixins are totally composable because they have the same type: take a mss, return a modified mss back, notice how the coffeescript shine here, if you choose to write javascript, you have to take care of the nest function application carefully:

```javascript

var Center$ = function(mss) {
  mss.textAlign = 'center';
  return mss;
};

var Padding = function(pad) {
  return function(mss) {
    mss.padding = pad;
    return mss;
  };
};

{
  input: Center$(Padding('2px')({
    margin: 0
  }))
}

```

Here's some built-in mixins with their equivalent mss:

```coffee
# Vendor add vendor prefix to given property
Foo: Vendor('borderRadius')
    borderRadius: '2px' 

Foo:
    mozBorderRadius: '2px'
    WebkitBorderRadius: '2px'
    MsBorderRadius: '2px'
    borderRadius: '2px'

# Mixin mix another mss object
Foo: Mixin(padding:'2px')
        otherProp: '...' 

Foo:
    padding: '2px'
    otherProp: '...'

# Size are shorthand for width and height
Foo: Size('200px', '100%')
    otherProp: '...' 

Foo:
    width: '200px'
    height: '100%'
    otherProp: '...'

# PosAbs set position to absolute and set top, right, bottom, left in arguments order.
Foo: PosAbs('10px', '10px', 0, 0)
    otherProp: '...' 

Foo:
    position: 'absolute'
    top: '10px'
    right: '10px'
    bottom: 0
    left: 0
    otherProp: '...'

# Same as PosAbs
Foo: PosRel('10px', '10px', 0)
    otherProp: '...' 

Foo:
    position: 'relative'
    top: '10px'
    right: '10px'
    bottom: 0
    otherProp: '...'

# LineSize set height = lineHeight = first argument, and fontSize = second
Foo: LineSize('14px', '10px')
    otherProp: '...' 

Foo:
    height: '14px'
    lineHeight: '14px'
    fontSize: '10px'
    otherProp: '...'

# TextEllip$ make ellipsis text easy
Foo: TextEllip$
    otherProp: '...' 

Foo:
    whiteSpace = 'nowrap'
    overflow = 'hidden'
    textOverflow = 'ellipsis'
    otherProp: '...'

# ClearFix$, well... just classic ClearFix
Foo: ClearFix$
    otherProp: '...' 

Foo:
    '*zoom': 1
    $before_$after:
        content: "''"
        display: 'table'
    $after:
        clear: 'both'
    otherProp: '...'
```

Special mixins
--------------

There're two very special Mixins that can be used as example show mss turn `@` rules into composable functions:

mss

```coffee
myMedia = mss.MediaQuery(
        all:
           maxWidth: '1200px'
        _handheld:
           minWidth: '700px'
        $tv:
           color: '#red'
    )
        Content: 
            width: '960px'

```

css

```css
@media all and (max-width:1200px),not handheld and (min-width:700px),only tv and (color:#red){
     .Content{
      width:960px;
    }
}
```

The rules of `MediaQuery` is: use `_` for `not` and `$` for `only`, that's all. We got `KeyFrames` too:

mss

```coffee
mss.KeyFrames('myKeyFrameAnima')
    10: 
        top: '20px'
    20:
        top: '40px'
    30:
        top: '50px'

```

css

```css
@keyframes myKeyFrameAnima{
    33.333333333333336%{
        top:20px;
    }
    66.66666666666667%{
        top:40px;
    }
    100%{
        top:50px;
    }
}
```

The keys are numbers that will be normalized to pencentage, so you can just write them in proportion.

Other functions
---------------

You can define other functions to achieve more powerful effect easily based on mss's nested object presentation, here comes a simple built-in function `TRAVERSE`, it's UPPER_CASE to distinguish from functions and mixins, it can be used in some interesting situations such as substitute all static assets' url.

```coffee
originMss =
    Foo:
        p:
            otherProp: '...'
        Bar:
            otherProp: '...'
            span:
                background: url('debug.png')

mssFn = (selector, mss) ->
    if selector == 'Bar'
        mss.padding = '2px'
    mss

propFn = (propName, propValue) ->
    if propName == 'background'
        propValue.replace(/^url\(.+\)$/g, 'product.png')
    else propValue

TRAVERSE(originMss, mssFn, propFn) ==
    Foo:
        p:
            otherProp: '...'
        Bar:
            padding: '2px'
            otherProp: '...'
            span:
                background: url('product.png')

```

Applications
------------

Mss provide some basic functions to parse an mss object, insert them to DOM, update, or remove from DOM:

```coffee
s = mss

myStyle =
    body:
        width: '640px'

console.log(s.parse(myStyle))         # parse a mss object into a string.
console.log(s.parse(myStyle, true))   # parse a mss object into a string with prettify.

styleTag = s.tag(myStyle)             # insert the style to <head>, return the <style> tag's node.
styleTag = s.tag(myStyle, 'myStyle')  # insert the style to <head> with id=myStyle, return tag's node.

s.retag(myStyle2, styleTag)           # update the styleTag node's style with new mss object
s.unTag(styleTag)                     # remove the styleTag node
```

Use mss with some declarative ui frameworks such as [React](https://facebook.github.io/react/) [mithril](https://github.com/lhorie/mithril.js) or [mecury](https://github.com/Raynos/mercury) to keep web component modular and composable, the basic idea is that a component should manage its own DOM and CSS, and since mss is just plain object or array of objects, it's trivial to nest small component into larger one.

An easy way to do this is providing a function for mss along aside your DOM templete, and call children's mss function inside the parent one just like how you compose the DOM, take following `Dialog` written using [mithril](https://github.com/lhorie/mithril.js) as an example:

```coffee
class Dialog
    constructor: (...) ->
    view: ->
        m '.Dialog', '...'

Dialog.mss = (bgColor) ->
    Dialog:
        background: color
```

You can easily embed it into another `BiggerDialog`:

```coffee
class BiggerDialog
    constructor:
        @childDialog = new Dialog(...)
    view: ->
        m '.BiggerDialog', [
                childDialog.view()
            ,   
                m '.OtherThings', '...'
            ,   
                ...
            ]

BiggerDialog.mss = (bgColor, childDialogBgColor) ->
    BiggerDialog: [
            background: color
    
            OtherThings:
                ...
        ,   
            Dialog.mss(childDialogBgColor)
        ,   
            ...
        ]
```

BTW. The online compiler's page's style is powered by mss(written in coffeescript), here is the source code for amusing:

```coffee
s = mss

html_body: s.Size('100%', '100%')
    overflow: 'hidden'
    fontSize: '14px'
$I: s.PosRel(0, 0) s.Size('100%', '100%')
    background: '#eee'
    Doc: s.PosAbs(0, '50%', 0 , 0)  s.Size('46%', '100%')
        padding: '2%'
        overflow: 'scroll'

    LiveParser: s.PosAbs(0, 0, 0, '50%') s.Size('46%', '96%')
        padding: '2%'
        MssInput_MssOutput:
            border: '1px solid #ccc'
            background: '#fff'
            fontSize: '1em'
        MssInput: s.Size('100%', '44%')
            background: '#F5F2F0'
        ParseHint: s.Size('100%', '2%')
            padding: '2%'
        MssOutput: s.Size('100%', '44%')
            background: '#F5F2F0'

```

The compiled CSS is directly inserted into DOM:

```css
html,
body {
    overflow: hidden;
    font-size: 14px;
    width: 100%;
    height: 100%;
}
#i {
    background: #eee;
    width: 100%;
    height: 100%;
    position: relative;
    top: 0;
    right: 0;
}
#i .Doc {
    padding: 2%;
    overflow: scroll;
    width: 46%;
    height: 100%;
    position: absolute;
    top: 0;
    right: 50%;
    bottom: 0;
    left: 0;
}
#i .LiveParser {
    padding: 2%;
    width: 46%;
    height: 96%;
    position: absolute;
    top: 0;
    right: 0;
    bottom: 0;
    left: 50%;
}
#i .LiveParser .MssInput,
#i .LiveParser .MssOutput {
    border: 1px solid #ccc;
    background: #fff;
    font-size: 1em;
}
#i .LiveParser .MssInput {
    background: #F5F2F0;
    width: 100%;
    height: 44%;
}
#i .LiveParser .ParseHint {
    padding: 2%;
    width: 100%;
    height: 2%;
}
#i .LiveParser .MssOutput {
    background: #F5F2F0;
    width: 100%;
    height: 44%;
}
```

If you don't mind too much verbose here's javascript version:
```javascript
var s = mss;

html_body: s.Size('100%', '100%')({
    overflow: 'hidden',
    fontSize: '14px'
}),
$I: s.PosRel(0, 0)(s.Size('100%', '100%')({
    background: '#eee',
    Doc: s.PosAbs(0, '50%', 0, 0)(s.Size('46%', '100%')({
      padding: '2%',
      overflow: 'scroll'
    })),
    LiveParser: s.PosAbs(0, 0, 0, '50%')(s.Size('46%', '96%')({
        padding: '2%',
        MssInput_MssOutput: {
            border: '1px solid #ccc',
            background: '#fff',
            fontSize: '1em'
        },
        MssInput: s.Size('100%', '44%')({
            background: '#F5F2F0'
        }),
        ParseHint: s.Size('100%', '2%')({
            padding: '2%'
        }),
        MssOutput: s.Size('100%', '44%')({
            background: '#F5F2F0'
        })
    }))
}))

```
That'all, happy hacking!
