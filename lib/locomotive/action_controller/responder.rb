module Locomotive
  module ActionController
    class Responder < ::ActionController::Responder

      include ::Responders::FlashResponder

      # by default flash_now messages if the resource has errors
      def set_flash_now?
        super || has_errors?
      end

      def options
        current_site    = self.controller.send(:current_site)
        current_account = self.controller.send(:current_locomotive_account)
        ability         = current_site.nil? || current_account.nil? ? nil : self.controller.send(:current_ability)

        super.merge({
          current_site:     current_site,
          current_account:  current_account,
          ability:          ability
        })
      end

      def to_json
        if get?
          add_pagination_header if resource.respond_to?(:num_pages)
          display resource
        elsif has_errors?
          with_flash_message(:alert) do
            display resource.errors, status: :unprocessable_entity
          end
        elsif post?
          in_header = controller.request.headers['X-Flash'] == 'true'
          with_flash_message(:notice, in_header) do
            display resource, location: api_location
          end
        elsif put?
          with_flash_message do |message|
            display resource, status: :ok, location: api_location
          end
        elsif delete?
          with_flash_message do |message|
            display resource, status: :ok, location: api_location
          end
        elsif has_empty_resource_definition?
          display empty_resource, status: :ok
        else
          with_flash_message do
            head :ok
          end
        end
      end

      protected

      def with_flash_message(type = :notice, in_header = true)
        if in_header
          set_flash_message!
          message = URI::escape(controller.flash[type].to_str) if controller.flash[type]

          unless message.blank?
            controller.headers['X-Message']       = ActiveSupport::JSON::Encoding.escape(message)
            controller.headers['X-Message-Type']  = type.to_s
          end

          yield if block_given?

          controller.flash.discard # reset flash messages !
        else
          set_flash_message!

          yield if block_given?
        end
      end

      def add_pagination_header
        controller.headers['X-Total-Pages']   = resource.num_pages.to_s
        controller.headers['X-Per-Page']      = resource.limit_value.to_s
        controller.headers['X-Total-Entries'] = resource.total_count.to_s
      end

    end
  end
end
