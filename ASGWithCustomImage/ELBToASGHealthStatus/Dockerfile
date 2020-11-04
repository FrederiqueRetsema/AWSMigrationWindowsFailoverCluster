# Dockerfile for creating my boto3 program
FROM python:3-alpine
RUN mkdir /var/python && \
    pip install boto3
WORKDIR /var/python
ENV SLEEP_IN_SECONDS=5
COPY ./elb_to_asg_health_status.py .
CMD ["python","./elb_to_asg_health_status.py"]
