FROM livekit/sip:latest

# Copy configuration
COPY sip.yaml /etc/sip.yaml

# Expose SIP port
EXPOSE 5060

# Use the config file
CMD ["--config", "/etc/sip.yaml"]

