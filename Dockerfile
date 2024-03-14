# Start from the Python base image
FROM python:3.10.0

# Install cron
RUN apt-get update && apt-get install -y cron

# Set the working directory
WORKDIR /app

# Copy requirements and toml files
COPY package_requirements.txt /app/package_requirements.txt
COPY service_acc.json /app/service_acc.json
COPY .dlt/* /app/.dlt/
COPY .dlt/* /root/.dlt/


# Install necessary dependencies
RUN pip install -r package_requirements.txt

# Copy the Python scripts to the working directory
COPY *.py /app/

# Set timezone
RUN apt-get install -y tzdata
ENV TZ="Europe/Zurich"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Copy the cron file to the container
COPY cronfile /etc/cron.d/cronfile

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/cronfile

# Give execution rights to the script(s)
RUN chmod 0744 /app/*.py

# Apply the cron job
RUN crontab /etc/cron.d/cronfile

# Download data and upload to storage
RUN python upload_to_storage.py

# Start the cron daemon in the foreground
CMD ["cron", "-f"]

# Building the image with name incidents:
# $ docker build -t incidents .

# Running the container:
# $ docker run -it --rm --entrypoint /bin/bash incidents --> for testing
# $ docker run --name mycontainer --privileged -d incidents --> for production