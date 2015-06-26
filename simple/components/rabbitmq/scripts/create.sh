#!/bin/bash -e

. $(ctx download-resource "components/utils")


export ERLANG_SOURCE_URL=$(ctx node properties erlang_rpm_source_url)  # (e.g. "http://www.rabbitmq.com/releases/erlang/erlang-17.4-1.el6.x86_64.rpm")
export RABBITMQ_SOURCE_URL=$(ctx node properties rabbitmq_rpm_source_url)  # (e.g. "http://www.rabbitmq.com/releases/rabbitmq-server/v3.5.3/rabbitmq-server-3.5.3-1.noarch.rpm")

export RABBITMQ_LOG_BASE="/var/log/cloudify/rabbitmq"


ctx logger info "Installing RabbitMQ..."

copy_notice "rabbitmq"
create_dir "${RABBITMQ_LOG_BASE}"

ctx logger info "Installing logrotate"
yum_install ${ERLANG_SOURCE_URL}
yum_install ${RABBITMQ_SOURCE_URL}

# Dunno if required.. the key thing, that is... check please.
# curl --fail --location http://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-${RABBITMQ_VERSION}-1.noarch.rpm -o /tmp/rabbitmq.rpm
# sudo rpm --import https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
# sudo yum install /tmp/rabbitmq.rpm -y

ctx logger info "Starting RabbitMQ Server in Daemonized mode..."
sudo chkconfig rabbitmq-server on
sudo /sbin/service rabbitmq-server start

ctx logger info "Enabling RabbitMQ Plugins..."
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmq-plugins enable rabbitmq_tracing

# enable guest user access where cluster not on localhost
ctx logger info "Enabling RabbitMQ user access..."
echo "[{rabbit, [{loopback_users, []}]}]." | sudo tee --append /etc/rabbitmq/rabbitmq.config

ctx logger info "Chowning RabbitMQ logs path..."
sudo chown rabbitmq:rabbitmq ${RABBITMQ_LOG_BASE}

ctx logger info "Killing RabbitMQ..."
sudo /sbin/service rabbitmq-server stop