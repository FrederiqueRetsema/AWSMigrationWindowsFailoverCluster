# Dockerfile for creating container elb_health_status_to_asg

FROM python:3-alpine
RUN mkdir /var/python && \
    pip install boto3
WORKDIR /var/python
ENV SLEEP_IN_SECONDS=5
ENV LOGGING_LEVEL="DEBUG"
COPY ./elb_health_status_to_asg.py .
ENTRYPOINT ["python","./elb_health_status_to_asg.py"]
