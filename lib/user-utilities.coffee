$ = require 'jquery'
os = require 'os'
fs = require 'fs'
plist = require 'plist'
semver = require 'semver'
{BufferedProcess} = require 'atom'

###
A collection of methods for retrieving information about the user's system for
bug report purposes.
###

module.exports =

  ###
  Section: System Information
  ###

  getPlatform: ->
    os.platform()

  # OS version strings lifted from https://github.com/lee-dohm/bug-report
  getOSVersion: ->
    new Promise (resolve, reject) =>
      switch @getPlatform()
        when 'darwin' then resolve(@macVersionText())
        when 'win32' then resolve(@winVersionText())
        else resolve("#{os.platform()} #{os.release()}")

  macVersionText: ->
    @macVersionInfo().then (info) ->
      return 'Unknown OS X version' unless info.ProductName and info.ProductVersion
      "#{info.ProductName} #{info.ProductVersion}"

  macVersionInfo: ->
    new Promise (resolve, reject) ->
      try
        fs.readFile '/System/Library/CoreServices/SystemVersion.plist', 'utf8', (error, text) ->
          resolve(plist.parse(text))
      catch e
        resolve('Unknown OSX version')

  winVersionText: ->
    new Promise (resolve, reject) ->
      data = []
      systemInfo = new BufferedProcess
        command: 'systeminfo'
        stdout: (oneLine) -> data.push(oneLine)
        exit: =>
          info = data.join('\n')
          info = if (res = /OS.Name.\s+(.*)$/im.exec(info)) then res[1] else 'Unknown Windows Version'
          resolve(info)

      systemInfo.onWillThrowError ({handle}) ->
        handle()
        resolve('Unknown Windows Version')

  ###
  Section: Config Values
  ###

  getConfigForPackage: (packageName) ->
    config = core: atom.config.settings.core
    if packageName?
      config[packageName] = atom.config.settings[packageName]
    else
      config.editor = atom.config.settings.editor
    config

  ###
  Section: Installed Packages
  ###

  # Returns a promise. Resolves with object of arrays {dev: ['some-package, v0.2.3', ...], user: [...]}
  getInstalledPackages: ->
    new Promise (resolve, reject) =>
      data = []
      new BufferedProcess
        command: atom.packages.getApmPath()
        args: ['ls', '--json', '--no-color']
        stdout: (oneLine) -> data.push(oneLine)
        exit: =>
          stdout = data.join('\n')
          packages = JSON.parse(stdout)
          resolve
            dev: @filterActivePackages(packages.dev)
            user: @filterActivePackages(packages.user)
      return

  filterActivePackages: (packages) ->
    "#{pack.name}, v#{pack.version}" for pack in (packages ? []) when atom.packages.getActivePackage(pack.name)?

  getPackageVersion: (packageName) ->
    pack = atom.packages.getLoadedPackage(packageName)
    pack.metadata.version

  getLatestPackageData: (packageName) ->
    packagesUrl = 'https://atom.io/api/packages'
    new Promise (resolve, reject) ->
      $.ajax "#{packagesUrl}/#{packageName}",
        accept: 'application/vnd.github.v3+json'
        contentType: "application/json"
        success: (data) -> resolve(data)
        error: (error) -> reject(error)

  checkPackageUpToDate: (packageName) ->
    @getLatestPackageData(packageName).then (latestPackageData) =>
      installedVersion = @getPackageVersion(packageName)
      upToDate = semver.gte(installedVersion, latestPackageData.releases.latest)
      latestVersion = latestPackageData.releases.latest
      isCore = latestPackageData.repository.url.startsWith('https://github.com/atom/')
      { isCore, upToDate, latestVersion, installedVersion }
