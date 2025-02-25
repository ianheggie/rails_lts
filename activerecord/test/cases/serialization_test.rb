require "cases/helper"
require 'models/contact'

class SerializationTest < ActiveRecord::TestCase
  FORMATS = [ :xml, :json ]

  def setup
    @contact_attributes = {
      :name        => 'aaron stack',
      :age         => 25,
      :avatar      => 'binarydata',
      :created_at  => Time.utc(2006, 8, 1),
      :awesome     => false,
      :preferences => { 'gem' => '<strong>ruby</strong>' }
    }

    @contact = Contact.new(@contact_attributes)
  end

  def test_serialize_should_be_reversible
    for format in FORMATS
      # Cannot test XML-serialization for the serialized attribute Contact#preferences
      # because that serializes to `<preferences type="yaml">` and deserialization of Yaml was
      # removed in commit
      #
      #   "CVE-2013-0156: Safe XML params parsing. Doesn't allow symbols or yaml."
      #   70adb9613e4a40c5645c99da374639c41012e4fc
      #
      @serialized = Contact.new.send("to_#{format}", :except => :preferences)
      contact = Contact.new.send("from_#{format}", @serialized)

      assert_equal @contact_attributes.keys.collect(&:to_s).sort, contact.attributes.keys.collect(&:to_s).sort, "For #{format}"
    end
  end

  def test_serialize_should_allow_attribute_only_filtering
    for format in FORMATS
      @serialized = Contact.new(@contact_attributes).send("to_#{format}", :only => [ :age, :name ])
      contact = Contact.new.send("from_#{format}", @serialized)
      assert_equal @contact_attributes[:name], contact.name, "For #{format}"
      assert_nil contact.avatar, "For #{format}"
    end
  end

  def test_serialize_should_allow_attribute_except_filtering
    for format in FORMATS
      # Cannot test XML-serialization for the serialized attribute Contact#preferences
      # because that serializes to `<preferences type="yaml">` and deserialization of Yaml was
      # removed in commit
      #
      #   "CVE-2013-0156: Safe XML params parsing. Doesn't allow symbols or yaml."
      #   70adb9613e4a40c5645c99da374639c41012e4fc
      #
      @serialized = Contact.new(@contact_attributes).send("to_#{format}", :except => [ :age, :name, :preferences ])
      contact = Contact.new.send("from_#{format}", @serialized)
      assert_nil contact.name, "For #{format}"
      assert_nil contact.age, "For #{format}"
      assert_equal @contact_attributes[:awesome], contact.awesome, "For #{format}"
    end
  end
end
