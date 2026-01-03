# frozen_string_literal: true

require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.inflector.inflect(
  'github-issues' => 'Github',
  'version' => 'VERSION'
)
loader.collapse("#{__dir__}/github/issues/mixins")
loader.collapse("#{__dir__}/github/issues/app/mixins")
loader.setup

##
# Namespace for Github modules
module Github; end
