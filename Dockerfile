FROM python:3.9-alpine3.14

# Install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Add executable
COPY render.sh /render.sh
RUN chmod +x /render.sh
CMD [ "/render.sh" ]
