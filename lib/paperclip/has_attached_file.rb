module Paperclip
  class HasAttachedFile
    def self.define_on(klass, name, options)
      new(klass, name, options).define
    end

    def initialize(klass, name, options)
      puts "here1"
      @klass = klass
      puts "here2"
      @name = name
      puts "here3"
      @options = options
    end

    def define
      puts "here4"
      define_flush_errors
      puts "here5"
      define_getters
      puts "here6"
      define_setter
      puts "here7"
      define_query
      puts "here8"
      register_new_attachment
      puts "here9"
      add_active_record_callbacks
      puts "here10"
      add_paperclip_callbacks
      puts "here11"
      add_required_validations
      puts "here12"
    end

    private

    def define_flush_errors
      @klass.send(:validates_each, @name) do |record, attr, value|
        attachment = record.send(@name)
        attachment.send(:flush_errors)
      end
    end

    def define_getters
      define_instance_getter
      define_class_getter
    end

    def define_instance_getter
      name = @name
      options = @options

      @klass.send :define_method, @name do |*args|
        ivar = "@attachment_#{name}"
        attachment = instance_variable_get(ivar)

        if attachment.nil?
          attachment = Attachment.new(name, self, options)
          instance_variable_set(ivar, attachment)
        end

        if args.length > 0
          attachment.to_s(args.first)
        else
          attachment
        end
      end
    end

    def define_class_getter
      @klass.extend(ClassMethods)
    end

    def define_setter
      name = @name
      @klass.send :define_method, "#{@name}=" do |file|
        send(name).assign(file)
      end
    end

    def define_query
      name = @name
      @klass.send :define_method, "#{@name}?" do
        send(name).file?
      end
    end

    def register_new_attachment
      #Paperclip::AttachmentRegistry.register(@klass, @name, @options) #SS
      Paperclip::AttachmentRegistry.register(@klass, @name, @options)
    end

    def add_required_validations
      options = Paperclip::Attachment.default_options.deep_merge(@options)
      if options[:validate_media_type] != false
        name = @name
        @klass.validates_media_type_spoof_detection name,
          :if => ->(instance){ instance.send(name).dirty? }
      end
    end

    def add_active_record_callbacks
      name = @name
      @klass.send(:after_save) { send(name).send(:save) }
      @klass.send(:before_destroy) { send(name).send(:queue_all_for_delete) }
      if @klass.respond_to?(:after_commit)
        @klass.send(:after_commit, on: :destroy) do
          send(name).send(:flush_deletes)
        end
      else
        @klass.send(:after_destroy) { send(name).send(:flush_deletes) }
      end
    end

    def add_paperclip_callbacks
      @klass.send(
        :define_paperclip_callbacks,
        :post_process, :"#{@name}_post_process")
    end

    #module ClassMethods
      def attachment_definitions
        #Paperclip::AttachmentRegistry.definitions_for(self) #SS
        Paperclip::AttachmentRegistry.definitions_for(self.class)
      end
    #end
  end
end
