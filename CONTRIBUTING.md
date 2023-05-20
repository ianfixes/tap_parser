# Contributing to the TapParser gem

TapParser uses a very standard GitHub workflow.

1. Fork the repository on github
2. Make your desired changes on top of the latest `master` branch, document them in [CHANGELOG.md](CHANGELOG.md)
3. Push to your personal fork
4. Open a pull request
    * If you are submitting code, use `master` as the base branch
    * If you are submitting broken unit tests (illustrating a bug that should be fixed), use `tdd` as the base branch.

Pull requests will trigger a CI job.  The following two commands will be expected to pass (so you may want to run them locally before opening the pull request):

* `bundle exec rubocop -D .` - code style tests
* `bundle exec rspec` - functional tests
* `bundle exec rspec spec/some_file_spec.rb` - functional tests for just some file

 If you do not already have a working ruby development environment set up, run the following commands:

```shell
# One of the following
apt-get install ruby ruby-dev    # For Debian/Ubuntu
dnf install ruby ruby-devel      # For Fedora/newer Centos/RHEL
yum install ruby ruby-devel      # For older Centos/RHEL

# All below
gem install bundler
gem install rspec
# Now you are ready to install dependencies with bundle (as described in the
# README file) and to run unit tests.
```

Be prepared to write tests to accompany any code you would like to see merged.


## Packaging the Gem

* Merge pull request with new features
* Execute `release-new-version.sh` with the appropriate argument (e.g. `--increment-patch`), which does the following:
    * `git stash save` (at least before the gem build step, but easiest here).
    * `git pull --rebase`
    * Update the sections of `CHANGELOG.md` by running `bundle exec keepachangelog_manager.rb --increment-patch`
    * Bump the version in lib/tap_parser/version.rb and change it in README.md (since rubydoc.info doesn't always redirect to the latest version)
    * `git add README.md CHANGELOG.md lib/tap_parser/version.rb`
    * `git commit -m "vVERSION bump"`
    * `git tag -a vVERSION -m "Released version VERSION"`
    * `gem build tap_parser.gemspec`
    * `git stash pop`
    * `gem push tap_parser-VERSION.gem`
    * `git push upstream`
    * `git push upstream --tags`
* Visit http://www.rubydoc.info/gems/tap_parser/VERSION to initiate the doc generation process
