
/*
A collection of methods for retrieving information about the user's system for
bug report purposes.
*/

module.exports = {

  generateException: function () {
    try {
      // eslint-disable-next-line no-undef
      return a + 1
    } catch (e) {
      let errMsg = `${e.toString()} in ${process.env.ATOM_HOME}/somewhere`
      return window.onerror(errMsg, '/dev/null', 2, 3, e)
    }
  },

  // shortenerResponse
  // packageResponse
  // issuesResponse
  generateFakeFetchResponses: function (options) {
    if (!window.fetch.isSpy) { spyOn(window, 'fetch') }

    return fetch.and.callFake(function (url) {
      if (url.indexOf('is.gd') > -1) {
        return textPromise((options != null ? options.shortenerResponse : undefined) != null ? (options != null ? options.shortenerResponse : undefined) : 'http://is.gd/cats')
      }

      if (url.indexOf('atom.io/api/packages') > -1) {
        return jsonPromise((options != null ? options.packageResponse : undefined) != null ? (options != null ? options.packageResponse : undefined) : {
          repository: { url: 'https://github.com/atom/notifications'
          },
          releases: { latest: '0.0.0'
          }
        })
      }

      if (url.indexOf('atom.io/api/updates') > -1) {
        return (jsonPromise((options != null ? options.atomResponse : undefined) != null ? (options != null ? options.atomResponse : undefined) : {name: atom.getVersion()}))
      }

      if ((options != null ? options.issuesErrorResponse : undefined) != null) {
        return Promise.reject(options != null ? options.issuesErrorResponse : undefined)
      }

      return jsonPromise((options != null ? options.issuesResponse : undefined) != null ? (options != null ? options.issuesResponse : undefined) : {items: []})
    })
  }
}

var jsonPromise = object => Promise.resolve({ok: true, json () { return Promise.resolve(object) }})
var textPromise = text => Promise.resolve({ok: true, text () { return Promise.resolve(text) }})
