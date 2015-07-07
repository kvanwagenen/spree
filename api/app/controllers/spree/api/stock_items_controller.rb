module Spree
  module Api
    class StockItemsController < Spree::Api::BaseController
      before_filter :stock_location, except: [:update, :destroy]

      def index
        authorize! :read, StockItem
        @stock_items = scope.ransack(params[:q]).result.page(params[:page]).per(params[:per_page])
        respond_with(@stock_items)
      end

      def show
        authorize! :read, StockItem
        @stock_item = scope.find(params[:id])
        respond_with(@stock_item)
      end

      def create
        authorize! :create, StockItem

        count_on_hand = 0
        if params[:stock_item].has_key?(:count_on_hand)
          count_on_hand = params[:stock_item][:count_on_hand].to_i
          params[:stock_item].delete(:count_on_hand)
        end

        @stock_item = scope.new(params[:stock_item])
        if @stock_item.save
          @stock_item.adjust_count_on_hand(count_on_hand)
          respond_with(@stock_item, status: 201, default_template: :show)
        else
          invalid_resource!(@stock_item)
        end
      end

      def update
        authorize! :update, StockItem
        @stock_item = StockItem.find(params[:id])

        count_on_hand = 0
        if params[:stock_item].has_key?(:count_on_hand)
          count_on_hand = params[:stock_item][:count_on_hand].to_i
          params[:stock_item].delete(:count_on_hand)
        end

        updated = params[:stock_item][:force] ? @stock_item.set_count_on_hand(count_on_hand)
                                              : @stock_item.adjust_count_on_hand(count_on_hand)

        if updated
          respond_with(@stock_item, status: 200, default_template: :show)
        else
          invalid_resource!(@stock_item)
        end
      end

      def update_batch
        authorize! :update, StockItem        
        
        if params[:stock_items].nil?
          render status: :bad_request, content_type: :json, message: "Request contained no stock_items parameter" and return
        end

        stock_items = params[:stock_items]
        updated = []
        failed = []
        stock_items.each do |item|
          next if item.nil? || item["variant_id"].nil? || item["count_on_hand"].nil?
          stock_item = @stock_location.stock_items.find_by_variant_id(item["variant_id"])
          if stock_item && stock_item.respond_to?(:set_count_on_hand)
            stock_item.set_count_on_hand(item["count_on_hand"])
            updated << item["variant_id"]
          else
            failed << item["variant_id"]
          end
        end
        @data = { message: "Successfully updated #{updated.length} stock items. #{failed.length} failed.", updated_ids: updated, failed_ids: failed }
      end

      def destroy
        authorize! :delete, StockItem
        @stock_item = StockItem.find(params[:id])
        @stock_item.destroy
        respond_with(@stock_item, status: 204)
      end

      private

      def stock_location
        render 'spree/api/shared/stock_location_required', status: 422 and return unless params[:stock_location_id]
        @stock_location ||= StockLocation.find(params[:stock_location_id])
      end

      def scope
        includes = {:variant => [{ :option_values => :option_type }, :product] }
        @stock_location.stock_items.includes(includes)
      end
    end
  end
end
