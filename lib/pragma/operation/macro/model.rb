module Pragma
  module Operation
    module Macro
      def self.Model
        step = -> (input, options) { Model.for(input, options) }
        [step, name: 'model']
      end

      module Model
        class << self
          def for(input, options)
            options['model'] = options['model.class'].find(options['params']['id']).tap do |result|
              options['result.response'] = Response::NotFound.new unless result
            end
          end
        end
      end
    end
  end
end
