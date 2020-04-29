FROM debian:bullseye-slim

# Variables
ENV RUBY_VERSION "2.6.3"
ENV ANDROID_SDK_VERSION "6200805"
ENV ANDROID_BUILD_TOOLS_VERSION "29.0.2"
ENV ANDROID_BUILD_PLATFORM "29"

# Prerequisites
RUN mkdir -p /usr/share/man/man1
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y \
      curl git unzip xz-utils zip libglu1-mesa default-jdk wget \
      autoconf bison build-essential libssl-dev libyaml-dev libreadline-dev \
      zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev sudo

# Set up new user
RUN useradd -ms /bin/bash developer
RUN adduser developer sudo
RUN echo 'developer ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers.d/developer
USER developer
WORKDIR /home/developer

# Prepare Android directories and system variables
RUN mkdir -p Android/sdk/cmdline-tools
ENV ANDROID_SDK_ROOT /home/developer/Android/sdk
ENV ANDROID_HOME /home/developer/Android/sdk
RUN mkdir -p .android && touch .android/repositories.cfg

# Set up Android SDK
RUN wget -O sdk-tools.zip "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip"
RUN unzip sdk-tools.zip && rm sdk-tools.zip
RUN mv tools "${ANDROID_HOME}/cmdline-tools/tools"
ENV PATH "$PATH:${ANDROID_HOME}/cmdline-tools/tools/bin"
RUN yes | sdkmanager --licenses
RUN sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" "patcher;v4" "platform-tools" "platforms;android-${ANDROID_BUILD_PLATFORM}" "sources;android-${ANDROID_BUILD_PLATFORM}"
ENV PATH "$PATH:${ANDROID_HOME}/platform-tools"

# Hack to make flutter work
RUN mkdir -p "${ANDROID_HOME}/tools/bin"
RUN ln -s "${ANDROID_HOME}/cmdline-tools/tools/bin/sdkmanager" "${ANDROID_HOME}/tools/bin/sdkmanager"

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git
ENV PATH "$PATH:/home/developer/flutter/bin"

# Run basic check to download Dark SDK
RUN flutter doctor

# Install asdf
RUN git clone https://github.com/asdf-vm/asdf.git .asdf
RUN echo '. $HOME/.asdf/asdf.sh' >> .bashrc
RUN echo '. $HOME/.asdf/completions/asdf.bash' >> .bashrc
ENV PATH "$PATH:/home/developer/.asdf/bin:/home/developer/.asdf/shims"

# Install Ruby
RUN echo "ruby $RUBY_VERSION" >> "$HOME/.tool-versions"
RUN echo 'bundler' >> "$HOME/.default_gems"
RUN asdf plugin-add ruby
RUN asdf install
RUN asdf reshim

# Install Fastlane
RUN gem install fastlane -NV

# Start
CMD ["bash"]
