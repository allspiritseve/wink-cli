class Wink < Formula
  desc 'Wink command-line application'
  homepage 'https://github.com/allspiritseve/wink-cli'

  def head
    depends_on 'automake' => :build
  end

  def install
    system "make", "install"
  end
end
