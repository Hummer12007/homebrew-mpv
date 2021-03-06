require 'formula'

class Mpv < Formula
  url 'https://github.com/mpv-player/mpv/archive/v0.11.0.tar.gz'
  sha256 'a2157174e46db46dad5deb1fde94283e72ebe922fd15447cb16a2a243fae5bda'
  head 'https://github.com/mpv-player/mpv.git',
    :branch => ENV['MPV_BRANCH'] || "master"
  homepage 'https://github.com/mpv-player/mpv'

  depends_on 'pkg-config' => :build
  depends_on :python3

  option 'with-libmpv',          'Build shared library.'
  option 'without-optimization', 'Disable compiler optimization.'
  option 'without-bundle',       'Disable compilation of a Mac OS X Application bundle.'
  option 'without-zsh-comp',     'Install without zsh completion'

  depends_on 'libass'
  depends_on 'ffmpeg'

  depends_on 'mpg123'      => :recommended
  depends_on 'jpeg'        => :recommended
  depends_on 'little-cms2' => :recommended
  depends_on 'lua'         => :recommended
  depends_on 'youtube-dl'  => :recommended

  depends_on 'libcaca'     => :optional
  depends_on 'libdvdread'  => :optional
  depends_on 'libdvdnav'   => :optional
  depends_on 'libbluray'   => :optional
  depends_on 'libaacs'     => :optional
  depends_on 'vapoursynth' => :optional
  depends_on :x11          => :optional

  WAF_VERSION = "waf-1.8.12".freeze
  WAF_SHA256    = "01bf2beab2106d1558800c8709bc2c8e496d3da4a2ca343fe091f22fca60c98b".freeze

  resource 'waf' do
    url "https://waf.io/#{WAF_VERSION}"
    sha256 WAF_SHA256
  end

  resource 'docutils' do
    url 'https://pypi.python.org/packages/source/d/docutils/docutils-0.12.tar.gz'
    sha256 'c7db717810ab6965f66c8cf0398a98c9d8df982da39b4cd7f162911eb89596fa'
  end

  def caveats
    bundle_caveats if build.with? 'bundle'
  end

  def install
    ENV['PYTHONPATH'] = python3_site_packages
    ENV.prepend_create_path 'PATH', libexec/'bin'
    ENV.append 'LC_ALL', 'en_US.UTF-8'
    resource('docutils').stage { system "python3", "setup.py", "install", "--prefix=#{libexec}" }
    bin.env_script_all_files(libexec/'bin', :PYTHONPATH => ENV['PYTHONPATH'])

    if build.with? 'vapoursynth'
      ENV.append_path 'PKG_CONFIG_PATH', python3_pkg_config_path
    end

    args = [ "--prefix=#{prefix}" ]
    args << "--enable-libmpv-shared" if build.with? "libmpv"
    args << "--disable-optimize" if build.without? "optimization" and build.head?
    args << "--enable-zsh-comp" if build.with? "zsh-comp"

    buildpath.install resource('waf').files(WAF_VERSION => "waf")
    system "python3", "waf", "configure", *args
    system "python3", "waf", "install"

    if build.with? 'bundle'
      ohai "creating a OS X Application bundle"
      system "python3", "TOOLS/osxbundle.py", "build/mpv"
      prefix.install "build/mpv.app"
    end
  end

  private
  def python3_site_packages
    libexec/"lib/python#{python3_version}/site-packages"
  end

  def python3_pkg_config_path
    Formula['python3'].frameworks/'Python.framework/Versions'/python3_version/'python3/lib/pkgconfig'
  end

  def python3_version
    Language::Python.major_minor_version('python3')
  end


  def bundle_caveats; <<-EOS.undent
    mpv.app installed to:
      #{prefix}

    To link the application to a normal Mac OS X location:
        brew linkapps
    or:
        ln -s #{prefix}/mpv.app /Applications
    EOS
  end
end
