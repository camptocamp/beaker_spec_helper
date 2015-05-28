Beaker Spec Helper
==================

Collection of helpers/temporary workaround for Beaker

Usage
-----

Add this to your project's `Gemfile`:

```ruby
require 'beaker_spec_helper'
```

Add this to your project's `spec_helper_acceptance.rb`:

```ruby
require 'beaker_spec_helper'
include BeakerSpecHelper
```

Using spec_prep
---------------

You can use `spec_prep` to prepare your environment.
It acts like puppetlabs_spec_helper's `rake spec_prep` by using `.fixtures.yaml`

Ex:

```ruby
require 'beaker-rspec'
require 'beaker_spec_helper'
include BeakerSpecHelper

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  module_name = module_root.split('-').last

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    puppet_module_install(:source => module_root, :module_name => module_name)
    hosts.each do |host|
      BeakerSpecHelper::spec_prep(host)
    end
  end
end
```
