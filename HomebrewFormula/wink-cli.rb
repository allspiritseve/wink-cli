class WinkCli < Formula
  desc 'Wink command-line application'
  homepage 'https://github.com/allspiritseve/wink-cli'
  url 'https://github.com/allspiritseve/wink-cli.git'

  def install
    system "gem install wink-cli"
    bin.install "wink"
  end
end
