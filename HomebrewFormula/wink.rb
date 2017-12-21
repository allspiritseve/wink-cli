class Wink < Formula
  desc 'Wink command-line application'
  homepage 'https://github.com/allspiritseve/wink-cli'
  url "https://github.com/allspiritseve/wink-cli/archive/v0.1.5.tar.gz"
  sha256 "b936fb99b7cdfdbef80bdc1ed3c90ede3bf4c90fb8bf48eb0e9a5ae6daee7ee8"

  def install
    system "make", "install"
  end
end
