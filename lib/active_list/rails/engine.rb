module ActiveList
  module Rails
    class Engine < ::Rails::Engine
      engine_name "active_list"
      initializer "active_list.integrate_methods" do |app|
        ::ActionController::Base.send(:include, ActiveList::Rails::Integration::ActionController)
        ::ActionView::Base.send(:include, ActiveList::Rails::Integration::ViewsHelper)
        # Adds locales
        for file in Dir.glob(Pathname.new(__FILE__).dirname.join("..", "locales", "*.yml"))
          ::I18n.load_path << file unless ::I18n.load_path.include?(file)
        end
      end
    end
  end
end
