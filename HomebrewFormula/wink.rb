class Wink < Formula
  desc "Wink command-line application"
  homepage "https://github.com/allspiritseve/wink-cli"

  def install
    system "make", "install"
  end
end
