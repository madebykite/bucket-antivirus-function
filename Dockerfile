FROM amazonlinux:2

# Set up working directories
RUN mkdir -p /opt/app
RUN mkdir -p /opt/app/build
RUN mkdir -p /opt/app/bin/

# Copy in the lambda source
WORKDIR /opt/app
COPY ./*.py /opt/app/
COPY requirements.txt /opt/app/requirements.txt

# Install packages
RUN yum update -y
RUN yum install -y cpio python3-pip yum-utils zip unzip less
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# This had --no-cache-dir, tracing through multiple tickets led to a problem in wheel
RUN pip3 install -r requirements.txt
RUN rm -rf /root/.cache/pip

# Download libraries we need to run in lambda
WORKDIR /tmp
RUN yumdownloader --archlist=aarch64 clamav clamav-lib clamav-update json-c pcre2 libprelude gnutls libtasn1 lib64nettle nettle libtool-ltdl libxml2 libxml2-devel xz-libs binutils libcurl libcurl-devel libnghttp2 libidn2 libssh2 openldap libunistring cyrus-sasl-lib nss libcrypt
RUN rpm2cpio clamav-0*.rpm | cpio -idmv
RUN rpm2cpio clamav-lib*.rpm | cpio -idmv
RUN rpm2cpio clamav-update*.rpm | cpio -idmv
RUN rpm2cpio json-c*.rpm | cpio -idmv
RUN rpm2cpio pcre*.rpm | cpio -idmv
RUN rpm2cpio gnutls* | cpio -idmv
RUN rpm2cpio nettle* | cpio -idmv
RUN rpm2cpio lib* | cpio -idmv
RUN rpm2cpio *.rpm | cpio -idmv
RUN rpm2cpio libtasn1* | cpio -idmv
RUN rpm2cpio libtool-ltdl* | cpio -idmv
RUN rpm2cpio libxml2* | cpio -idmv
RUN rpm2cpio xz-libs* | cpio -idmv
RUN rpm2cpio binutils* | cpio -idmv
RUN rpm2cpio libcurl* | cpio -idmv
RUN rpm2cpio libnghttp2* | cpio -idmv
RUN rpm2cpio libidn2* | cpio -idmv
RUN rpm2cpio libssh2* | cpio -idmv
RUN rpm2cpio openldap* | cpio -idmv
RUN rpm2cpio libunistring* | cpio -idmv
RUN rpm2cpio cyrus-sasl-lib* | cpio -idmv
RUN rpm2cpio nss* | cpio -idmv
RUN rpm2cpio libcrypt* | cpio -idmv

# Copy over the binaries and libraries
RUN cp /tmp/usr/lib64/sasl2/* /opt/app/bin/
RUN rm -rf /tmp/usr/lib64/sasl2
RUN cp /tmp/usr/lib64/nss/* /opt/app/bin/
RUN rm -rf /tmp/usr/lib64/nss
RUN cp /tmp/usr/bin/clamscan /tmp/usr/bin/freshclam /tmp/lib64/* /tmp/usr/lib64/* /opt/app/bin/
RUN cp /tmp/usr/bin/ld.bfd /opt/app/bin/ld
RUN cp /opt/app/bin/libcrypt-2.26.so /opt/app/bin/libcrypt.so.1

# Fix the freshclam.conf settings
RUN echo "DatabaseMirror database.clamav.net" > /opt/app/bin/freshclam.conf
RUN echo "CompressLocalDatabase yes" >> /opt/app/bin/freshclam.conf

# Create the zip file
WORKDIR /opt/app
RUN zip -r9 --exclude="*test*" /opt/app/build/lambda.zip *.py bin

WORKDIR /usr/local/lib/python3.7/site-packages
RUN zip -r9 /opt/app/build/lambda.zip *

WORKDIR /opt/app
