const { createRunner } = require('atom-jasmine2-test-runner');

// optional options to customize the runner
const extraOptions = {
  suffix: "-spec.js",
  legacySuffix: "-spec.coffee",
  specHelper: {
    customMatchers: true,
  },
};

module.exports = createRunner(extraOptions);
