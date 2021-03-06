# frozen_string_literal: true

require 'test_helper'
require 'zip/ioextras'

class AbstractInputStreamTest < MiniTest::Test
  # AbstractInputStream subclass that provides a read method

  TEST_LINES = [
    "Hello world#{$INPUT_RECORD_SEPARATOR}",
    "this is the second line#{$INPUT_RECORD_SEPARATOR}",
    'this is the last line'
  ].freeze
  TEST_STRING = TEST_LINES.join

  class TestAbstractInputStream
    include ::Zip::IOExtras::AbstractInputStream

    def initialize(string)
      super()
      @contents = string
      @read_ptr = 0
    end

    def sysread(chars_to_read, _buf = nil)
      ret_val = @contents[@read_ptr, chars_to_read]
      @read_ptr += chars_to_read
      ret_val
    end

    def produce_input
      sysread(100)
    end

    def input_finished?
      @contents[@read_ptr].nil?
    end
  end

  def setup
    @io = TestAbstractInputStream.new(TEST_STRING)
  end

  def test_gets
    assert_equal(TEST_LINES[0], @io.gets)
    assert_equal(1, @io.lineno)
    assert_equal(TEST_LINES[0].length, @io.pos)
    assert_equal(TEST_LINES[1], @io.gets)
    assert_equal(2, @io.lineno)
    assert_equal(TEST_LINES[2], @io.gets)
    assert_equal(3, @io.lineno)
    assert_nil(@io.gets)
    assert_equal(4, @io.lineno)
  end

  def test_gets_multi_char_seperator
    assert_equal('Hell', @io.gets('ll'))
    assert_equal("o world#{$INPUT_RECORD_SEPARATOR}this is the second l", @io.gets('d l'))
  end

  LONG_LINES = [
    "#{'x' * 48}\r\n",
    "#{'y' * 49}\r\n",
    'rest'
  ].freeze

  def test_gets_mulit_char_seperator_split
    io = TestAbstractInputStream.new(LONG_LINES.join)
    assert_equal(LONG_LINES[0], io.gets("\r\n"))
    assert_equal(LONG_LINES[1], io.gets("\r\n"))
    assert_equal(LONG_LINES[2], io.gets("\r\n"))
  end

  def test_gets_with_sep_and_index
    io = TestAbstractInputStream.new(LONG_LINES.join)
    assert_equal('x', io.gets("\r\n", 1))
    assert_equal("#{'x' * 47}\r", io.gets("\r\n", 48))
    assert_equal("\n", io.gets(nil, 1))
    assert_equal('yy', io.gets(nil, 2))
  end

  def test_gets_with_index
    assert_equal(TEST_LINES[0], @io.gets(100))
    assert_equal('this', @io.gets(4))
  end

  def test_each_line
    line_num = 0
    @io.each_line do |line|
      assert_equal(TEST_LINES[line_num], line)
      line_num += 1
    end
  end

  def test_readlines
    assert_equal(TEST_LINES, @io.readlines)
  end

  def test_readline
    test_gets
    begin
      @io.readline
      raise 'EOFError expected'
    rescue EOFError
    end
  end
end
