FROM python:3.10.1-alpine3.15

WORKDIR /opt/app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY src/render.sh .
RUN chmod +x render.sh

CMD /opt/app/render.sh
