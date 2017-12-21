class Wink < Formula
  desc 'Wink command-line application'
  homepage 'https://github.com/allspiritseve/wink-cli'
  url "https://github.com/allspiritseve/wink-cli/archive/v0.1.7.tar.gz"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end
end
