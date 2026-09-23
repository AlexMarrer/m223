# Shared base for the resources that hang off a single concert. Only the lookup is common: which
# rule guards the resource differs, so every subclass authorizes for itself.
class Concerts::BaseController < ApplicationController
  before_action :set_concert

  private
    def set_concert
      @concert = Concert.find(params[:concert_id])
    end
end
