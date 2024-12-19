## mix pyro.new

Provides `pyro.new` installer as an archive.

To install from Hex, run:

    $ mix archive.install hex pyro_cli

To build and install it locally,
ensure any previous archive versions are removed:

    $ mix archive.uninstall pyro_cli

Then run:

    $ cd cli
    $ MIX_ENV=prod mix do archive.build, archive.install
