# -*- coding: utf-8 -*-

require 'spec_helper'

describe Shck::ConfigLoader do
  subject(:config) { described_class.new(yml) }
  let(:yml) do
    { 'host' => %w(hostA hostB),
      'group' => %w(groupA groupB),
      'def' => [
        { 'regex' => 'hostA' },
        { 'regex' => 'hostB',
          'from' => 'hostA',
          'ssh' => 'my_ssh_program',
        },
      ]
    }
  end

  describe '#hosts' do
    it 'returns hosts' do
      expect(config.hosts).to eq(%w(hostA hostB))
    end
  end

  describe '#groups' do
    it 'returns group' do
      expect(config.groups).to eq(%w(groupA groupB))
    end
  end

  describe '#include?' do
    context 'when the host included' do
      it 'returns true' do
        expect(config.include?('hostA')).to be_true
      end

      it 'returns false' do
        expect(config.include?('hostC')).to be_false
      end
    end
  end

  describe '#definitions' do
    it 'returns definietions' do
      expect(config.definitions).to eq([
          { 'regex' => 'hostA',
            'from' => 'localhost',
            'ssh' => 'ssh -t',
          },
          { 'regex' => 'hostB',
            'from' => 'hostA',
            'ssh' => 'my_ssh_program',
          },
        ])
    end
  end

  describe '#definition' do
    context 'when the hostA' do
      it 'returns hostA definition' do
        expect(config.definition('hostA')).to eq({
            'from' => 'localhost',
            'dst' => 'hostA',
            'ssh' => 'ssh -t',
          })
      end
    end

    context 'when the hostA' do
      it 'returns hostB definition' do
        expect(config.definition('hostB')).to eq({
            'from' => 'hostA',
            'dst' => 'hostB',
            'ssh' => 'my_ssh_program',
          })
      end
    end
  end
end
