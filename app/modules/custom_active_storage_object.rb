class CustomActiveStorageObject
  def initialize(object, attachment)
    @object     = object
    @attachment = attachment
    @base_url   = @object.class::ATTACHMENTS_URLS[attachment.to_s]
  end

  def attach(io, filename)
    if as_attached.attached?
      begin
        FileUtils.rm path, force: true
      rescue
        nil
      end

      as_attached.purge
    end

    as_attached.attach(io: io, filename: filename)
  end

  def path(style = '', to_tmp=false)
    if as_attached.attached?
      generate_file style, to_tmp
      @base_path
    else
      pc_attached.path(style.to_s.to_sym)
    end
  end

  def reload
    FileUtils.remove_entry(path, true)
    FileUtils.remove_entry(path('', true), true)
    self
  end

  def service_url()
    if as_attached.attached?
      begin
        as_attached.service_url
      rescue
        path
      end
    else
      pc_attached.url(:original)
    end
  end

  def url(style = '')
    if as_attached.attached?
      return nil unless @base_url
      @base_url.gsub(':id', @object.id.to_s)
               .gsub(':style', style.to_s)
               .gsub(':filename', @object.try(:filename).to_s)
               .gsub(':basename', @object.try(:basename).to_s)
               .gsub(':extension', @object.try(:extension).to_s)
    else
      pc_attached.url(style.to_s.to_sym)
    end
  end

  def size
    if as_attached.attached?
      retries = 0
      begin
        as_attached.blob.byte_size
      rescue
        retries += 1
        if retries <= 2
          sleep retries * 2
          retry
        end
        raise
      end
    else
      target_file_size = @attachment.to_s.gsub('cloud_', '') + '_file_size'
      @object.send(target_file_size.to_sym)
    end
  end

  def filename
    if as_attached.attached?
      retries = 0
      begin
        as_attached.filename.sanitized.gsub('-', '_')
      rescue
        retries += 1
        if retries <= 2
          sleep retries * 2
          retry
        end
        raise
      end
    else
      target_file_name = @attachment.to_s.gsub('cloud_', '') + '_file_name'
      @object.send(target_file_name.to_sym)
    end
  end

  private

  #active storage attached
  def as_attached
    @object.send(@attachment.to_sym)
  end

  #paper clip attached
  def pc_attached
    @object.send(@attachment.to_s.gsub('cloud_', '').to_sym)
  end

  def object_class_name
    @object.class.name.to_s.gsub('::', '_').downcase
  end

  def generate_file(style = '', to_tmp=false)
    retries = 0

    p "========== First ============="

    if to_tmp || Rails.env != 'production'
      base_dir = "#{Rails.root}/tmp/#{object_class_name}/#{@object.id}/"
    else
      ### TEMP FIX : Move base dir to /nfs
      base_dir = "/nfs/local_files/#{object_class_name}/#{@object.id}/"
    end

    begin
      if style.to_s == 'medium' || style.to_s == 'thumb'
        size_limit = if style.to_s == 'medium'
                      [92, 133]
                     else
                      [46, 67]
                     end
        #TODO: resize limit doesn't work
        blob = as_attached.preview(resize_to_limit: size_limit).processed.image
        dir  = "#{base_dir}#{style.to_s}/"
        tmp_file_path = File.join(dir, @object.id + '.png')
      else
        blob = as_attached
        dir  = base_dir
        tmp_file_path = File.join(dir, filename)
      end

      p "=========== #{tmp_file_path} =============="

      unless File.exist? tmp_file_path
        FileUtils.makedirs(dir)
        FileUtils.chmod(0755, dir)

        FileUtils.delay_for(48.hours, queue: :high).remove_entry(dir, true)

        tmp_file = File.open(tmp_file_path, 'wb')
        tmp_file.write blob.download
        tmp_file.close
      end


      p "=========== #{tmp_file_path.present?} =============="
      if !tmp_file_path.present?
        System::Log.info('active_storage_logs', "[Generate File] #{object_class_name} - #{@object.id} - Not generated")

        log_document = {
          subject: "[CustomActiveStorageObject] not generated file",
          name: "CustomActiveStorageObject",
          error_group: "[custom-active-storage-object] not generated file",
          erreur_type: "Active Storage, Not generated file",
          date_erreur: Time.now.strftime('%Y-%M-%d %H:%M:%S'),
          more_information: {
            object: @object.inspect,
            style: style.to_s,
            path: tmp_file.try(:path)
          }
        }

        ErrorScriptMailer.error_notification(log_document).deliver
      end

      @base_path = tmp_file_path
    rescue => e

      p "=========== #{e.to_s} =============="
      System::Log.info('active_storage_logs', "[Generate File] #{object_class_name} - #{@object.id} - #{e.to_s} - Retry: #{retries}")

      retries += 1
      if retries <= 2
        sleep retries * 2
        retry
      end

      @base_path = nil
    end
  end
end