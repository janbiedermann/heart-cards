# // This is a manifest file that'll be compiled into application.js, which will include all the files
# // listed below.
# //
# // Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
# // vendor/assets/javascripts directory can be referenced here using a relative path.
# //
# // It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# // compiled file. JavaScript code in this file should be added after the last require_* statement.
# //
# // Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
# // about supported directives.

require 'react_ujs'
require 'jquery'
require 'jquery_ujs'
require 'cable'

require 'opal'
require 'hyper-component'

if React::IsomorphicHelpers.on_opal_client?
  require 'opal-jquery'
  require 'browser'
  require 'browser/interval'
  require 'browser/delay'
end

require 'hyper-model'
require 'hyper-store'
require 'hyper-operation'
require 'reactrb/auto-import'
# require 'hyper-router/react-router-source'
require 'hyper-router'
require 'hyper-console'

require 'autoloader'

require 'components'
Opal.load('components')

console

require 'test_one'
require 'test_two'
require 'test_three'
