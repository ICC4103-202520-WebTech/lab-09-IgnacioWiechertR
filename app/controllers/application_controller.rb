class ApplicationController < ActionController::Base
  rescue_from CanCan::AccessDenied do |exception|
    redirect_back fallback_location: root_path, alert: "You are not authorized to perform this action."
  end
end
