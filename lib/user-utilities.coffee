os = require 'os'
fs = require 'fs'
plist = require 'plist'
spawnSync = require('child_process').spawnSync

###
A collection of methods for retrieving information about the user's system for
bug report purposes.
###

module.exports =

  ###
  Section: System Information
  ###

  # OS version strings lifted from https://github.com/lee-dohm/bug-report
  getOSVersion: ->
    switch os.platform()
      when 'darwin' then @macVersionText()
      when 'win32' then @winVersionText()
      else "#{os.platform()} #{os.release()}"

  macVersionText: (info = @macVersionInfo()) ->
    return 'Unknown OS X version' unless info.ProductName and info.ProductVersion
    "#{info.ProductName} #{info.ProductVersion}"

  macVersionInfo: ->
    try
      text = fs.readFileSync('/System/Library/CoreServices/SystemVersion.plist', 'utf8')
      plist.parse(text)
    catch e
      {}

  winVersionText: ->
    info = spawnSync('systeminfo').stdout.toString()
    if (res = /OS.Name.\s+(.*)$/im.exec(info)) then res[1] else 'Unknown Windows Version'

  ###
  Section: Installed Packages
  ###

  # Returns an object of arrays {dev: ['some-package, v0.2.3', ...], user: [...]}
  getInstalledPackages: (callback) ->
    args = ['ls', '--json']
    runCommand args, (code, stdout, stderr) ->
      if code is 0
        packages = JSON.parse(stdout)
        activePackages =
          dev: filterActivePackages(packages.dev)
          user: filterActivePackages(packages.user)
        console.log activePackages
        callback(activePackages) if callback?

  filterActivePackages: (packages) ->
    "#{pack.name}, v#{pack.version}" for pack in (packages ? []) when atom.packages.getActivePackage(pack.name)?

  runCommand: (args, callback) ->
    command = atom.packages.getApmPath()
    outputLines = []
    stdout = (lines) -> outputLines.push(lines)
    errorLines = []
    stderr = (lines) -> errorLines.push(lines)
    exit = (code) ->
      callback(code, outputLines.join('\n'), errorLines.join('\n'))

    args.push('--no-color')
    {BufferedProcess} = require 'atom'
    new BufferedProcess({command, args, stdout, stderr, exit})
