FROM elswork/cwebp:1.0.0


COPY entrypoint.sh /


ENTRYPOINT ["bash"]
CMD ["/entrypoint.sh"]
