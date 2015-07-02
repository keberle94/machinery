module ScopeFileAccessFlat
  def retrieve_files_from_system(system, paths)
    system.retrieve_files(paths, scope_file_store.path)
  end

  def write_file(system_file, target)
    raise Machinery::Errors::FileUtilsError, "Not a file" if !system_file.file?

    target_path = File.join(target, system_file.name)
    FileUtils.mkdir_p(File.dirname(target_path))
    FileUtils.cp(file_path(system_file), target_path)
  end

  def file_path(system_file)
    raise Machinery::Errors::FileUtilsError, "Not a file" if !system_file.file?

    File.join(scope_file_store.path, system_file.name)
  end

  def retrieve_file_content(filename)
    path = File.join(scope_file_store.path, filename)
    raise Machinery::Errors::FileUtilsError if !File.exist?(path)
    file = File.new(path, "r")
    file.read
  end
end

module ScopeFileAccessArchive
  def retrieve_files_from_system_as_archive(system, files, excluded_files)
    archive_path = File.join(scope_file_store.path, "files.tgz")
    system.create_archive(files, archive_path, excluded_files)
  end

  def retrieve_trees_from_system_as_archive(system, trees, excluded_files, &callback)
    trees.each_with_index do |tree, index|
      tree_name = File.basename(tree)
      parent_dir = File.dirname(tree)
      sub_dir = File.join("trees", parent_dir)

      scope_file_store.create_sub_directory(sub_dir)
      archive_path = File.join(scope_file_store.path, sub_dir, "#{tree_name}.tgz")
      system.create_archive(tree, archive_path, excluded_files)

      callback.call(index + 1) if callback
    end
  end

  def export_files_as_tarballs(destination)
    FileUtils.cp(File.join(scope_file_store.path, "files.tgz"), destination)

    target = File.join(destination, "trees")
    files.select(&:directory?).each do |system_file|
      raise Machinery::Errors::FileUtilsError if !system_file.directory?

      tarball_target = File.join(target, File.dirname(system_file.name))

      FileUtils.mkdir_p(tarball_target)
      FileUtils.cp(tarball_path(system_file), tarball_target)
    end
  end

  def tarball_path(system_file)
    if system_file.directory?
      File.join(
        system_file.scope.scope_file_store.path,
        "trees",
        File.dirname(system_file.name),
        File.basename(system_file.name) + ".tgz"
      )
    else
      File.join(system_file.scope.scope_file_store.path, "files.tgz")
    end
  end

  def retrieve_file_content(filename)
    if File.exist?(File.join(scope_file_store.path, filename))
      return "is here"
    else
      begin
        tar_file = File.join(scope_file_store.path, "files.tgz")
        Cheetah.run("tar", "xfO", tar_file, filename.gsub(/^\//, ""), stdout: :capture)
      rescue
        retrieve_file_content_recursively(filename, filename)
      end
    end
  end

  def retrieve_file_content_recursively(path, last_path)
    raise Machinery::Errors::FileUtilsError if last_path == "/"

    tar_file = File.join(scope_file_store.path, "trees", last_path) + ".tgz"
    if File.exist?(tar_file)
      Machinery.logger.info "reading tar_file #{tar_file}"
      return Cheetah.run("tar", "xfO", tar_file, path.gsub(/^\//, ""), stdout: :capture)
    else
      # Recursively go through parent directories
      # File.dirname removes the last sub directory from the path
      return retrieve_file_content_recursively(path, File.dirname(last_path))
    end
  end
end
