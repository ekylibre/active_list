module ActiveList
  module Rails
    class Engine < ::Rails::Engine
      engine_name "active_list"
      initializer "active_list.integrate_methods" do |app|
        ::ActionController::Base.send(:include, ActiveList::Rails::Integration::ActionController)
        ::ActionView::Base.send(:include, ActiveList::Rails::Integration::ViewsHelper)
        # files = Dir[Pathname.new(__FILE__).dirname.join("..", "..", "..", "config", "locales", "*.yml")]
        # puts ::I18n.load_path.map(&:red).to_sentence
        # ::I18n.load_path.concat(files)
      end
    end
  end
end
