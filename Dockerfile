FROM python:3-alpine
WORKDIR /curator
RUN ln -s /curator /root/.curator
RUN pip install elasticsearch-curator

COPY curator.yml .
COPY actions.yml .
COPY run.sh /.
CMD /run.sh