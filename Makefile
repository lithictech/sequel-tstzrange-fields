VERSION := `cat lib/sequel_tstzrange_fields/version.rb | grep 'VERSION =' | cut -d '"' -f2`

install:
	bundle install
cop:
	bundle exec rubocop
fix:
	bundle exec rubocop --autocorrect-all
fmt: fix

up:
	docker-compose up -d
test:
	RACK_ENV=test bundle exec rspec spec/
testf:
	RACK_ENV=test bundle exec rspec spec/ --fail-fast --seed=1

build:
ifeq ($(strip $(VERSION)),)
	echo "Could not parse VERSION"
else
	git tag $(VERSION)
	gem build sequel-tstzrange-fields.gemspec
	gem push sequel-tstzrange-fields-$(VERSION).gem
	git push origin $(VERSION)
endif

