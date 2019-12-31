# ---------------------------
# ---- Base Python image ----
FROM python:3.8-alpine AS base

# Copy basic setup files to the image
# (not all of them so that the docker cache can skip some lengthy steps)
COPY scripts/.profile scripts/init.sh scripts/entrypoint.sh scripts/backupjob /setupfiles/

# debug only
COPY scripts/aws/config scripts/aws/credentials /setupfiles/aws/

# run the setup script
ARG BACKUP_USER=backup
ARG BACKUP_UID=1000
RUN chmod +x /setupfiles/*.sh \
    && /setupfiles/init.sh

# create and set working directory owned by non-root user; set that user
#WORKDIR /home/${BACKUP_USER}
#USER ${BACKUP_USER}
