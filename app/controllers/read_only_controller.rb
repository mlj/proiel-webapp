class ReadOnlyController < ResourceController::Base
  actions :all, :except => [ :new, :edit, :create, :update, :destroy ]
end
