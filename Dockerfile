FROM python:3.11-slim

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY . .

# Create config directory and place default config
RUN mkdir -p /app/config && cp config.json /app/config/config.json

# Environment variable defaults
ENV PORT=5000
ENV CONFIG_PATH=/app/config/config.json

EXPOSE 5000

# Run with Gunicorn production WSGI server
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
