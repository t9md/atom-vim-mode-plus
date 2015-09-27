# Refactoring status: N/A
_ = require 'underscore-plus'

Base       = require './base'
Operator   = require './operator'
Motion     = require './motion'
TextObject = require './text-object'
InsertMode = require './insert-mode'
Scroll     = require './scroll'
VisualBlockwise = require './visual-blockwise'
settings   = require './settings'
{debug}     = require './utils'
introspection = require './introspection'

module.exports =
class Developer
  constructor: (@vimState) ->
    {@editor} = @vimState

  init: ->
    @vimState.registerCommands
      'toggle-debug': ->
        settings.set('debug', not settings.get('debug'))
        console.log "#{settings.scope} debug:", settings.get('debug')
      'generate-introspection-report': => @generateIntrospectionReport()
      'jump-to-related': => @jumpToRelated()
      'report-key-binding': => @reportKeyBinding()
      'open-in-vim': => @openInVim()

  generateIntrospectionReport: ->
    excludeProperties = [
      'findClass'
      'extend', 'getParent', 'getAncestors',
    ]
    recursiveInspect = Base

    introspection = require './introspection'
    mods = [Operator, Motion, TextObject, Scroll, InsertMode, VisualBlockwise]
    introspection.generateIntrospectionReport(mods, {excludeProperties, recursiveInspect})

  jumpToRelated: ->
    isCamelCase  = (s) -> _.camelize(s) is s
    isDashCase   = (s) -> _.dasherize(s) is s
    getClassCase = (s) -> _.capitalize(_.camelize(s))

    range = @editor.getLastCursor().getCurrentWordBufferRange(wordRegex: /[-\w/\.]+/)
    srcName = @editor.getTextInBufferRange(range)
    return unless srcName

    if isDashCase(srcName)
      klass2file =
        Motion:     'motion.coffee'
        Operator:   'operator.coffee'
        TextObject: 'text-object.coffee'
        Scroll:     'scroll.coffee'
        InsertMode: 'insert-mode.coffee'
        VisualBlockwise: 'visual-blockwise.coffee'

      klassName = getClassCase(srcName)
      unless klass = Base.findClass(klassName)
        return
      parentNames = (parent.name for parent in klass.getAncestors())
      parentNames.pop() # trash Base
      parent = _.last(parentNames)
      if parent in _.keys(klass2file)
        fileName = klass2file[parent]
        filePath = atom.project.resolvePath("lib/#{fileName}")
        atom.workspace.open(filePath).done (editor) ->
          editor.scan ///^class\s+#{klassName}///, ({range, stop}) ->
            editor.setCursorBufferPosition(range.start.translate([0, 'class '.length]))
            stop()
    else if isCamelCase(srcName)
      files = [
        "keymaps/vim-mode-plus.cson"
        "lib/vim-state.coffee"
      ]
      dashName = _.dasherize(srcName)
      fileName = files[0]
      filePath = atom.project.resolvePath fileName
      atom.workspace.open(filePath).done (editor) ->
        editor.scan ///#{dashName}///, ({range, stop}) ->
          editor.setCursorBufferPosition(range.start)
          stop()

  reportKeyBinding: ->
    range = @editor.getLastCursor().getCurrentWordBufferRange(wordRegex: /[-\w/\.]+/)
    klass = @editor.getTextInBufferRange(range)
    {getKeyBindingInfo} = require './introspection'

    if keymaps = getKeyBindingInfo(klass)
      content = keymaps.map (keymap) ->
        {keystrokes, selector} = keymap
        "#{selector}: `#{keystrokes}`\n"
      content = content.join('\n')
    else
      content = "No keymap for #{klass}"
    atom.notifications.addInfo content, dismissable: true

  inspectOperationStack: ->
    {stack} = @vimState.operationStack

    debug "  [@stack] size: #{stack.length}"
    for op, i in stack
      debug "  <idx: #{i}>"
      if settings.get('debug')
        debug introspection.inspectInstance op,
          indent: 2
          colors: settings.get('debugOutput') is 'file'
          excludeProperties: [
            'vimState', 'editorElement'
            'report', 'reportAll'
            'extend', 'getParent', 'getAncestors',
          ] # vimState have many properties, occupy DevTool console.
          recursiveInspect: Base

  openInVim: ->
    {BufferedProcess} = require 'atom'
    {row} = @editor.getCursorBufferPosition()
    new BufferedProcess
      command: "/Applications/MacVim.app/Contents/MacOS/mvim"
      args: [@editor.getPath(), "+#{row+1}"]
