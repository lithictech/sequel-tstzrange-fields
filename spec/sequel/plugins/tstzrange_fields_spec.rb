# frozen_string_literal: true

require "sequel"
require "sequel/model"
require "sequel/extensions/pg_range"
require "sequel/plugins/tstzrange_fields"

RSpec.describe Sequel::Plugins::TstzrangeFields do
  before(:each) do
    @db = Sequel.connect("postgres://sequel_tstzrange:sequel_tstzrange@localhost:18101/sequel_tstzrange_test")
    @db.extension(:pg_range)
  end
  after(:each) do
    @db.disconnect
  end

  it "errors if the db does not have pg_range registered" do
    db = Sequel.connect("postgres://sequel_tstzrange:sequel_tstzrange@localhost:18101/sequel_tstzrange_test")
    db.create_table(:tstzrange_fields_test, temp: true) do
      primary_key :id
    end
    expect do
      mc = Class.new(Sequel::Model(db[:tstzrange_fields_test]))
      mc.plugin(:tstzrange_fields)
    end.to raise_error(/tstzrange_fields plugin requires/)
  end

  context "with no fields given" do
    let(:model_class) do
      @db.create_table(:tstzrange_fields_test, temp: true) do
        primary_key :id
        tstzrange :period
      end
      mc = Class.new(Sequel::Model(@db[:tstzrange_fields_test]))
      mc.class_eval do
        def initialize(*)
          super
          self[:period] ||= self.class.new_tstzrange(nil, nil)
        end
      end
      mc.plugin(:tstzrange_fields)
      mc
    end

    let(:model_object) { model_class.new }

    it "uses :period as the high-level accessor" do
      expect(model_object).to respond_to(:period, :period=, :period_begin, :period_begin=, :period_end, :period_end=)
    end

    it "sets a default empty range" do
      expect(model_object.period).to be_empty
    end
  end

  context "for the given field" do
    let(:model_class) do
      @db.create_table(:tstzrange_fields_test, temp: true) do
        primary_key :id
        tstzrange :range
      end
      mc = Class.new(Sequel::Model(@db[:tstzrange_fields_test]))
      mc.plugin(:tstzrange_fields, :range)
      mc.class_eval do
        def initialize(*)
          super
          self[:range] ||= self.class.new_tstzrange(nil, nil)
        end
      end
      mc
    end

    let(:model_object) { model_class.new }

    let(:minute) { 60 }
    let(:hour) { 60 * minute }
    let(:day) { 24 * hour }
    let(:year) { 365 * day }

    def round_time(t)
      f = t.to_f
      f = f.round(3)
      Time.at(f)
    end

    def now
      round_time(Time.now)
    end

    def ago(n, unit)
      now - (n * unit)
    end

    def from_now(n, unit)
      now + (n * unit)
    end

    let(:t) { ago(3, year) }
    let(:ts) { t.iso8601(3) }

    it "sets a default empty range" do
      expect(model_object.range).to be_empty
    end

    it "can set an infinite range by assigning the field to Float::INFINITY" do
      expect(model_object.range).to be_empty

      model_object.range = Float::INFINITY
      expect(model_object.range_begin).to be_nil
      expect(model_object.range_end).to be_nil
      expect(model_object.range).not_to be_empty
      model_object.save_changes
      expect(model_class.where(Sequel.function(:lower_inf, :range)).count).to eq(1)
      expect(model_class.where(Sequel.function(:upper_inf, :range)).count).to eq(1)
    end

    it 'can set an empty range by assigning the field to the string "empty"' do
      model_object.range_begin = t
      model_object.range_end = t + (1 * day)
      expect(model_object.range).not_to be_empty

      model_object.range = "empty"
      expect(model_object.range).to be_empty
      expect(model_object.range_begin).to be_nil
      expect(model_object.range_end).to be_nil
      model_object.save_changes
      expect(model_class.where(Sequel.function(:lower_inf, :range)).count).to eq(0)
      expect(model_class.where(Sequel.function(:upper_inf, :range)).count).to eq(0)
    end

    it "can get/set the start" do
      model_object.range_begin = t
      expect(model_object.range_begin).to be_within(0.001).of(t)
      expect(model_object.save_changes.refresh.range_begin).to be_within(0.001).of(t)

      model_object.range_begin = ts
      expect(model_object.range_begin).to be_within(0.001).of(t)
      expect(model_object.save_changes.refresh.range_begin).to be_within(0.001).of(t)

      model_object.range_begin = nil
      expect(model_object.range_begin).to be_nil
      expect(model_object.save_changes.refresh.range_begin).to be_nil
    end

    it "can get/set the end" do
      model_object.range_end = t
      expect(model_object.range_end).to be_within(0.001).of(t)
      expect(model_object.save_changes.refresh.range_end).to be_within(0.001).of(t)

      model_object.range_end = ts
      expect(model_object.range_end).to be_within(0.001).of(t)
      expect(model_object.save_changes.refresh.range_end).to be_within(0.001).of(t)

      model_object.range_end = nil
      expect(model_object.range_end).to be_nil
      expect(model_object.save_changes.refresh.range_end).to be_nil
    end

    it "can initialize an instance using accessors" do
      o = model_class.create(range_begin: nil, range_end: nil)
      expect(o.range).to be_empty

      o = model_class.create(range_begin: Time.now, range_end: from_now(1, hour))
      expect(o.range).not_to be_cover(ago(30, minute))
      expect(o.range).to be_cover(from_now(30, minute))
      expect(o.range).not_to be_cover(from_now(90, minute))

      o = model_class.create(range_begin: nil, range_end: Time.now)
      expect(o.range).to be_cover(ago(30, minute))
      expect(o.range).not_to be_cover(from_now(30, minute))

      o = model_class.create(range_begin: Time.now, range_end: nil)
      expect(o.range).not_to be_cover(ago(30, minute))
      expect(o.range).to be_cover(from_now(30, minute))
    end

    it "creates an empty range for a nil value" do
      o = model_class.create(range: nil)
      expect(o.range).to_not be_nil
    end

    it "can initialize an instance with a nil range" do
      o = model_class.new
      o[:range] = nil
      expect(o.range).to be_nil
      t = Time.now
      o.range_end = t
      expect(o.range).to have_attributes(begin: nil, end: t)
      o[:range] = nil
      o.range_begin = t
      expect(o.range).to have_attributes(begin: t, end: nil)
    end

    it "can be assigned to directly with an object with begin/end methods or keys" do
      early = ago(1, day)
      late = from_now(2, day)

      cls_form = Struct.new(:begin, :end)

      forms = [
        early...late,
        cls_form.new(early, late),
        {begin: early, end: late},
        {"begin" => early, "end" => late},
      ]

      forms.each do |value|
        model_object.range = value
        model_object.save_changes.refresh
        expect(model_object.range_begin).to be_within(1).of(early)
        expect(model_object.range_end).to be_within(1).of(late)
      end

      model_object.range = {}
      expect(model_object.range).to be_empty

      expect { model_object.range = 1 }.to raise_error(TypeError)
    end
  end
end
