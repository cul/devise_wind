module Devise
  module Models
    module WindAuthenticatable
      extend ActiveSupport::Concern
      
      included do
        @wind_config = {}
      end
      
      def affiliations=(affils)
        # do nothing with affiliations by default, let implementers override this
      end
    
      def wind_login
        self.send self.class.wind_login_field
      end

      module ClassMethods
        # The name of the wind login field in the database.
        #
        # * <tt>Default:</tt> :wind_login, :login, or :username, if they exist
        # * <tt>Accepts:</tt> Symbol
        def wind_login_field(value = nil)
          configure_property(:wind_login_field, value, first_column_to_exist(nil, :wind_login, :login, :username))
        end
        alias_method :wind_login_field=, :wind_login_field

        def wind_service(value=nil)
          configure_property(:wind_service, value)
        end
        alias_method :wind_service=, :wind_login_field
        
        def wind_host(value=nil)
          configure_property(:wind_host, value)
        end
        alias_method :wind_host=, :wind_host
        # Whether or not to validate the wind_login field. If set to false ALL wind validation will need to be
        # handled by you.
        #
        # * <tt>Default:</tt> true
        # * <tt>Accepts:</tt> Boolean
        def validate_wind_login(value = true)
          self.validates wind_login_field, :presence => value
        end
        alias_method :validate_wind_login=, :validate_wind_login

        def find_by_wind_login_field(login)
          # we should create a user here if login was valid but record is missing?
          self.send( ("find_by_" + wind_login_field.to_s).to_sym, login )
        end

        def find_or_create_by_wind_login_field(login)
          # we should create a user here if login was valid but record is missing
          mname = ("find_or_create_by_" + wind_login_field.to_s)
          Rails.logger.debug "#{self.name}.#{mname}(#{login})"
          self.send mname.to_sym, login
        end

        private
          def configure_property(prop, value=nil, default=nil)
            value ||= default
            if value
              @wind_config[prop] = value
            else
              @wind_config[prop]
            end
          end
          # shamelessly riped from authlogic
          def db_setup?
            begin
              column_names
              true
            rescue Exception
              false
            end
          end
          
          def first_column_to_exist(*columns_to_check)
            if db_setup?
              columns_to_check.each { |column_name| return column_name.to_sym if column_names.include?(column_name.to_s) }
            end
            columns_to_check.first && columns_to_check.first.to_sym
          end  

      end # ClassMethods
      
    end # WindAuthenticatable
  end # Models
end # Devise