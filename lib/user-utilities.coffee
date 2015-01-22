$ = require 'jquery'
os = require 'os'
fs = require 'fs'
plist = require 'plist'
semver = require 'semver'
{spawnSync} = require 'child_process'

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
    switch @getPlatform()
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
    info = spawnSync('systeminfo').stdout?.toString() ? ''
    if (res = /OS.Name.\s+(.*)$/im.exec(info)) then res[1] else 'Unknown Windows Version'

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

  # Returns an object of arrays {dev: ['some-package, v0.2.3', ...], user: [...]}
  getInstalledPackages: ->
    args = ['ls', '--json', '--no-color']
    stdout = spawnSync(atom.packages.getApmPath(), args).stdout.toString()
    packages = JSON.parse(stdout)
    activePackages =
      dev: @filterActivePackages(packages.dev)
      user: @filterActivePackages(packages.user)

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
