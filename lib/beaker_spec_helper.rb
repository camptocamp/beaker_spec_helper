module BeakerSpecHelper

  hosts.each do |host|
    # Workaround for Ubuntu utopic and vivid
    if host['platform'] =~ /ubuntu-(14.10|15.04)/
      # Ugly Monkey patching...
      module Beaker::DSL::InstallUtils::PuppetUtils
        def install_puppet_from_deb( host, opts )
          if ! host.check_for_package 'lsb-release'
            host.install_package('lsb-release')
          end

          if ! host.check_for_command 'curl'
            on host, 'apt-get install -y curl'
          end

          on host, 'curl -O http://apt.puppetlabs.com/puppetlabs-release-trusty.deb'
          on host, 'dpkg -i puppetlabs-release-trusty.deb'
          on host, 'apt-get update'

          if opts[:facter_version]
            on host, "apt-get install -y facter=#{opts[:facter_version]}-1puppetlabs1"
          end

          if opts[:hiera_version]
            on host, "apt-get install -y hiera=#{opts[:hiera_version]}-1puppetlabs1"
          end

          if opts[:version]
            on host, "apt-get install -y puppet-common=#{opts[:version]}-1puppetlabs1"
            on host, "apt-get install -y puppet=#{opts[:version]}-1puppetlabs1"
          else
            on host, 'apt-get install -y puppet'
          end
        end
      end
    end
  end

  ###
  # Copied/pasted/adapted from puppetlabs_spec_helper's lib/puppetlabs_spec_helper/rake_tasks.rb
  #
  def fixtures(host, category)
    begin
      fixtures = YAML.load_file(".fixtures.yml")["fixtures"]
    rescue Errno::ENOENT
      return {}
    end

    if not fixtures
      abort("malformed fixtures.yml")
    end

    result = {}
    if fixtures.include? category and fixtures[category] != nil
      fixtures[category].each do |fixture, opts|
        if opts.instance_of?(String)
          source = opts
          target = "#{host['distmoduledir']}/#{fixture}"
          real_source = eval('"'+source+'"')
          result[real_source] = target
        elsif opts.instance_of?(Hash)
          target = "#{host['distmoduledir']}/#{fixture}"
          real_source = eval('"'+opts["repo"]+'"')
          result[real_source] = { "target" => target, "ref" => opts["ref"], "branch" => opts["branch"], "scm" => opts["scm"] }
        end
      end
    end
    return result
  end

  def clone_repo(host, scm, remote, target, ref=nil, branch=nil)
    args = []
    case scm
    when 'hg'
      args.push('clone')
      args.push('-u', ref) if ref
      args.push(remote, target)
    when 'git'
      args.push('clone')
      args.push('--depth 1') unless ref
      args.push('-b', branch) if branch
      args.push(remote, target)
    else
      fail "Unfortunately #{scm} is not supported yet"
    end
    on host, "#{scm} #{args.flatten.join ' '} || true"
  end

  def revision(host, scm, target, ref)
    args = []
    case scm
    when 'hg'
      args.push('update', 'clean', '-r', ref)
    when 'git'
      args.push('reset', '--hard', ref)
    else
      fail "Unfortunately #{scm} is not supported yet"
    end
    on host, "cd #{target} && #{scm} #{args.flatten.join ' '}"
  end

  def spec_prep(host)
    fixtures(host, "repositories").each do |remote, opts|
      scm = 'git'
      if opts.instance_of?(String)
        target = opts
      elsif opts.instance_of?(Hash)
        target = opts["target"]
        ref = opts["ref"]
        scm = opts["scm"] if opts["scm"]
        branch = opts["branch"] if opts["branch"]
      end

      unless File::exists?(target) || clone_repo(host, scm, remote, target, ref, branch)
        fail "Failed to clone #{scm} repository #{remote} into #{target}"
      end
      revision(host, scm, target, ref) if ref
    end

    fixtures(host, "forge_modules").each do |remote, opts|
      if opts.instance_of?(String)
        target = opts
        ref = ""
      elsif opts.instance_of?(Hash)
        target = opts["target"]
        ref = "--version #{opts['ref']}"
      end
      next if File::exists?(target)
      on host, puppet('module', 'install', ref, '--ignore-dependencies', '--force', remote), { :acceptable_exit_codes => [0,1] }
    end
  end

  #
  #
  ###
end
