FROM elswork/cwebp:1.0.0


RUN apk add --no-cache bash findutils


COPY entrypoint.sh /


ENTRYPOINT ["bash"]
CMD ["/entrypoint.sh"]
