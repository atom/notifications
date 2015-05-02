# truncates title to 100 characters (adds ... in the end)

TRUNCATE_TO = 100

module.exports =
  format: (title) ->
    @truncate(title)

  truncate: (str) ->
    if str.length > TRUNCATE_TO
      str.substring(0, TRUNCATE_TO-3) + '...'
    else
      str
