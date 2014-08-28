module Spree
  module Api
    class OptionValuesController < Spree::Api::BaseController
      before_filter :variant

      def index
        if params[:ids]
          @option_values = scope.where(:id => params[:ids])
        else
          @option_values = scope.ransack(params[:q]).result
        end
        respond_with(@option_values)
      end

      def show
      	@option_value = scope.find(params[:id])
      	respond_with(@option_value)
      end

      def create
      	authorize! :create, Spree::OptionValue
        if @variant
          @variant.set_option_value(params[:option_value][:option_type_name], params[:option_value][:name])
          render :template => 'spree/api/variants/show', :locals => {:variant => @variant}
        else
        	@option_value = scope.new(params[:option_value])
          if @option_value.save
            render :show, :status => 201
          else
            invalid_resource!(@option_value)
          end
        end
      end

      def update
        authorize! :update, Spree::OptionValue
        @option_value = scope.find(params[:id])
        if @option_value.update_attributes(params[:option_value])
          render :show
        else
          invalid_resource!(@option_value)
        end
      end

      def destroy
        authorize! :destroy, Spree::OptionValue
        @option_value = scope.find(params[:id])
        @option_value.destroy
        render :text => nil, :status => 204
      end

      private

        def scope
          if params[:option_type_id]
            @scope ||= Spree::OptionType.find(params[:option_type_id]).option_values
          else
            @scope ||= Spree::OptionValue.scoped
          end
        end

        def variant
          @variant = nil
          if params[:variant_id]
            @variant = Spree::Variant.find(params[:variant_id])
          end
        end
    end
  end
end
