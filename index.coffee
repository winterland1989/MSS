import CoffeeScript from './libs/coffeescript.js'
s = window.mss

docHTML = '<h1>Loading...</h1>'
parseHint = 'Please type your mss ^^^'

mssInput =
"""
Foo:
    margin: '2px'
    $hover:
        color: '#fff'

MixinTest: mss.Size('100%', '100%') mss.TextEllip$
    otherProp: '...'

"""
parseHint = ''
mssOutput = ''

marked.setOptions highlight: (code) ->
    hljs.highlightAuto(code).value

m.request(
    url: 'README.md.html'
    method: 'GET'
    extract: (xhr) -> marked xhr.response
).then (html) ->
    docHTML = html

onInputKeyDown = (e) ->
    if e.keyCode == 9
        e.preventDefault()
        self = e.target
        selStart = self.selectionStart
        self.value = self.value.substring(0, selStart) + '    ' + self.value.substring(selStart)
        self.selectionStart = self.selectionEnd = selStart + 4
        m.redraw.strategy('none')

onInputInput = (e) ->
    mssInput = e.target.value
    evalMss e.target.value

evalMss = (src) ->
    try
        CoffeeScript.eval 'window.mssInputObj = \n' + src
        parseHint = 'Look NICE!'
        mssOutput = s.parse(window.mssInputObj, true)
    catch err
        lineNumberRegex = /line (\d+)\:/
        errMsg = err.toString()
        errMsg = errMsg.replace(lineNumberRegex, (matched, digits) ->
            'line ' + parseInt(digits) - 1 + ':'
        )
        parseHint = errMsg

evalMss mssInput

mssLiveDoc = view: ->
    m '#i', [
            m '.Doc', m.trust(docHTML)
        ,
            m '.LiveParser', [
                    m 'textarea.MssInput' ,
                        value: mssInput
                        onkeydown: onInputKeyDown
                        oninput: onInputInput
                ,
                    m '.ParseHint', parseHint
                ,
                    m 'textarea.MssOutput',
                            disabled: true
                            value: mssOutput
                ]
        ]


s.tag
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

m.mount document.body, mssLiveDoc
