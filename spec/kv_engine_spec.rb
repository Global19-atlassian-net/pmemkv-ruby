# coding: utf-8

# Copyright 2017-2018, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'pmemkv/all'

ENGINE = 'kvtree2'
PATH = '/dev/shm/pmemkv-ruby'
SIZE = 1024 * 1024 * 8

describe KVEngine do

  before do
    File.delete(PATH) if File.exist?(PATH)
    expect(File.exist?(PATH)).to be false
  end

  after do
    File.delete(PATH) if File.exist?(PATH)
    expect(File.exist?(PATH)).to be false
  end

  it 'uses module to publish types' do
    expect(KVEngine.class.equal?(Pmemkv::KVEngine.class)).to be true
  end

  it 'uses blackhole engine' do
    kv = KVEngine.new('blackhole', PATH)
    expect(kv.count).to eql 0
    expect(kv.exists('key1')).to be false
    expect(kv.get('key1')).to be nil
    kv.put('key1', 'value123')
    expect(kv.count).to eql 0
    expect(kv.exists('key1')).to be false
    expect(kv.get('key1')).to be nil
    kv.remove('key1')
    expect(kv.exists('key1')).to be false
    expect(kv.get('key1')).to be nil
    kv.close
  end

  it 'creates instance' do
    size = 1024 * 1024 * 11
    kv = KVEngine.new(ENGINE, PATH, size)
    expect(kv).not_to be nil
    expect(kv.closed?).to be false
    kv.close
    expect(kv.closed?).to be true
  end

  it 'creates instance from existing pool' do
    size = 1024 * 1024 * 13
    kv = KVEngine.new(ENGINE, PATH, size)
    kv.close
    expect(kv.closed?).to be true
    kv = KVEngine.new(ENGINE, PATH, 0)
    expect(kv.closed?).to be false
    kv.close
    expect(kv.closed?).to be true
  end

  it 'closes instance multiple times' do
    size = 1024 * 1024 * 15
    kv = KVEngine.new(ENGINE, PATH, size)
    expect(kv.closed?).to be false
    kv.close
    expect(kv.closed?).to be true
    kv.close
    expect(kv.closed?).to be true
    kv.close
    expect(kv.closed?).to be true
  end

  it 'gets missing key' do
    kv = KVEngine.new(ENGINE, PATH)
    expect(kv.exists('key1')).to be false
    expect(kv.get('key1')).to be nil
    kv.close
  end

  it 'puts basic value' do
    kv = KVEngine.new(ENGINE, PATH)
    expect(kv.exists('key1')).to be false
    kv.put('key1', 'value1')
    expect(kv.exists('key1')).to be true
    expect(kv.get('key1')).to eql 'value1'
    kv.close
  end

  it 'puts binary key' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put("A\0B\0\0C", 'value1')
    expect(kv.exists("A\0B\0\0C")).to be true
    expect(kv.get("A\0B\0\0C")).to eql 'value1'
    kv.close
  end

  it 'puts binary value' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('key1', "A\0B\0\0C")
    expect(kv.get('key1')).to eql "A\0B\0\0C"
    kv.close
  end

  it 'puts complex value' do
    kv = KVEngine.new(ENGINE, PATH)
    val = 'one\ttwo or <p>three</p>\n {four}   and ^five'
    kv.put('key1', val)
    expect(kv.get('key1')).to eql val
    kv.close
  end

  it 'puts empty key' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('', 'empty')
    kv.put(' ', 'single-space')
    kv.put('\t\t', 'two-tab')
    expect(kv.exists('')).to be true
    expect(kv.get('')).to eql 'empty'
    expect(kv.exists(' ')).to be true
    expect(kv.get(' ')).to eql 'single-space'
    expect(kv.exists('\t\t')).to be true
    expect(kv.get('\t\t')).to eql 'two-tab'
    kv.close
  end

  it 'puts empty value' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('empty', '')
    kv.put('single-space', ' ')
    kv.put('two-tab', '\t\t')
    expect(kv.get('empty')).to eql ''
    expect(kv.get('single-space')).to eql ' '
    expect(kv.get('two-tab')).to eql '\t\t'
    kv.close
  end

  it 'puts multiple values' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('key1', 'value1')
    kv.put('key2', 'value2')
    kv.put('key3', 'value3')
    expect(kv.exists('key1')).to be true
    expect(kv.get('key1')).to eql 'value1'
    expect(kv.exists('key2')).to be true
    expect(kv.get('key2')).to eql 'value2'
    expect(kv.exists('key3')).to be true
    expect(kv.get('key3')).to eql 'value3'
    kv.close
  end

  it 'puts overwriting existing value' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('key1', 'value1')
    expect(kv.get('key1')).to eql 'value1'
    kv.put('key1', 'value123')
    expect(kv.get('key1')).to eql 'value123'
    kv.put('key1', 'asdf')
    expect(kv.get('key1')).to eql 'asdf'
    kv.close
  end

  it 'puts utf-8 key' do
    kv = KVEngine.new(ENGINE, PATH)
    val = 'to remember, note, record'
    kv.put('记', val)
    expect(kv.exists('记')).to be true
    expect(kv.get('记')).to eql val
    kv.close
  end

  it 'puts utf-8 value' do
    kv = KVEngine.new(ENGINE, PATH)
    val = '记 means to remember, note, record'
    kv.put('key1', val)
    expect(kv.get_string('key1')).to eql val
    kv.close
  end

  it 'puts very large value' do
    # todo finish
  end

  it 'removes key and value' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('key1', 'value1')
    expect(kv.exists('key1')).to be true
    expect(kv.get('key1')).to eql 'value1'
    kv.remove('key1')
    expect(kv.exists('key1')).to be false
    expect(kv.get('key1')).to be nil
    kv.close
  end

  it 'throws exception on create when engine is invalid' do
    kv = nil
    begin
      kv = KVEngine.new('nope.nope', PATH)
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'unable to open persistent pool'
    end
    expect(kv).to be nil
  end

  it 'throws exception on create when path is invalid' do
    kv = nil
    begin
      kv = KVEngine.new(ENGINE, '/tmp/123/234/345/456/567/678/nope.nope')
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'unable to open persistent pool'
    end
    expect(kv).to be nil
  end

  it 'throws exception on create with huge size' do
    kv = nil
    begin
      kv = KVEngine.new(ENGINE, PATH, 9223372036854775807) # 9.22 exabytes
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'unable to open persistent pool'
    end
    expect(kv).to be nil
  end

  it 'throws exception on create with tiny size' do
    kv = nil
    begin
      kv = KVEngine.new(ENGINE, PATH, SIZE - 1) # too small
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'unable to open persistent pool'
    end
    expect(kv).to be nil
  end

  it 'throws exception on put when out of space' do
    kv = KVEngine.new(ENGINE, PATH)
    begin
      100000.times do |i|
        istr = i.to_s
        kv.put(istr, istr)
      end
      expect(true).to be false
    rescue RuntimeError => e
      expect(e.message).to start_with 'unable to put key:'
    end
    kv.close
  end

  it 'uses each test' do
    kv = KVEngine.new('btree', PATH) # todo switch back to ENGINE
    expect(kv.count).to eql 0
    kv.put('1', '2')
    expect(kv.count).to eql 1
    kv.put('RR', 'BBB')
    expect(kv.count).to eql 2
    result = ''
    kv.each {|k, v| result += "<#{k}>,<#{v}>|"}
    expect(result).to eql '<1>,<2>|<RR>,<BBB>|'
    kv.close
  end

  it 'uses each string test' do
    kv = KVEngine.new('btree', PATH) # todo switch back to ENGINE
    expect(kv.count).to eql 0
    kv.put('one', '2')
    expect(kv.count).to eql 1
    kv.put('red', '记!')
    expect(kv.count).to eql 2
    result = ''
    kv.each_string {|k, v| result += "<#{k}>,<#{v}>|"}
    expect(result).to eql '<one>,<2>|<red>,<记!>|'
    kv.close
  end

  it 'uses like test' do
    kv = KVEngine.new('btree', PATH) # todo switch back to ENGINE
    kv.put('10', '10!')
    kv.put('11', '11!')
    kv.put('20', '20!')
    kv.put('21', '21!')
    kv.put('22', '22!')
    kv.put('30', '30!')

    expect(kv.exists_like('.*')).to be true
    expect(kv.exists_like('A')).to be false
    expect(kv.exists_like('10')).to be true
    expect(kv.exists_like('100')).to be false
    expect(kv.exists_like('1.*')).to be true
    expect(kv.exists_like('2.*')).to be true
    expect(kv.exists_like('.*1')).to be true

    expect(kv.count_like('.*')).to eql 6
    expect(kv.count_like('A')).to eql 0
    expect(kv.count_like('10')).to eql 1
    expect(kv.count_like('100')).to eql 0
    expect(kv.count_like('1.*')).to eql 2
    expect(kv.count_like('2.*')).to eql 3
    expect(kv.count_like('.*1')).to eql 2

    s = ''
    kv.each_like('1.*') {|k, v| s += "<#{k}>,"}
    expect(s).to eql '<10>,<11>,'
    kv.each_string_like('3.*') {|k, v| s += "<#{v}>,"}
    expect(s).to eql '<10>,<11>,<30!>,'

    kv.close
  end

  it 'uses like with bad pattern test' do
    kv = KVEngine.new('btree', PATH) # todo switch back to ENGINE
    kv.put('10', '10')
    kv.put('20', '20')
    kv.put('30', '30')

    expect(kv.exists_like('')).to be false
    expect(kv.exists_like('*')).to be false
    expect(kv.exists_like('(')).to be false
    expect(kv.exists_like(')')).to be false
    expect(kv.exists_like('()')).to be false
    expect(kv.exists_like(')(')).to be false
    expect(kv.exists_like('[')).to be false
    expect(kv.exists_like(']')).to be false
    expect(kv.exists_like('[]')).to be false
    expect(kv.exists_like('][')).to be false

    expect(kv.count_like('')).to eql 0
    expect(kv.count_like('*')).to eql 0
    expect(kv.count_like('(')).to eql 0
    expect(kv.count_like(')')).to eql 0
    expect(kv.count_like('()')).to eql 0
    expect(kv.count_like(')(')).to eql 0
    expect(kv.count_like('[')).to eql 0
    expect(kv.count_like(']')).to eql 0
    expect(kv.count_like('[]')).to eql 0
    expect(kv.count_like('][')).to eql 0

    s = ''
    kv.each_like('') { s += '!'}
    kv.each_like('*') { s += '!'}
    kv.each_like('(') { s += '!'}
    kv.each_like(')') { s += '!'}
    kv.each_like('()') { s += '!'}
    kv.each_like(')(') { s += '!'}
    kv.each_like('[') { s += '!'}
    kv.each_like(']') { s += '!'}
    kv.each_like('[]') { s += '!'}
    kv.each_like('][') { s += '!'}
    kv.each_string_like('') { s += '!'}
    kv.each_string_like('*') { s += '!'}
    kv.each_string_like('(') { s += '!'}
    kv.each_string_like(')') { s += '!'}
    kv.each_string_like('()') { s += '!'}
    kv.each_string_like(')(') { s += '!'}
    kv.each_string_like('[') { s += '!'}
    kv.each_string_like(']') { s += '!'}
    kv.each_string_like('[]') { s += '!'}
    kv.each_string_like('][') { s += '!'}
    expect(s).to eql ''

    kv.close
  end

end
