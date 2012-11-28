TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common

SRC_PERL = $(wildcard scripts/*.pl)
BIN_PERL = $(addprefix $(BIN_DIR)/,$(basename $(notdir $(SRC_PERL))))

DEPLOY_PERL = $(addprefix $(TARGET)/bin/,$(basename $(notdir $(SRC_PERL))))

SERVER_MODULE = CDMI_API
SERVICE = cdmi_api
SERVICE_PORT = 7032

CLIENT_TESTS = $(wildcard t/*.t)

SPHINX_PORT = 7038
SPHINX_HOST = localhost

TPAGE_ARGS = --define kb_top=$(TARGET) --define kb_runtime=$(DEPLOY_RUNTIME) --define kb_service_name=$(SERVICE) \
	--define kb_service_port=$(SERVICE_PORT) --define kb_service_dir=$(SERVICE_DIR) \
	--define kb_sphinx_port=$(SPHINX_PORT) --define kb_sphinx_host=$(SPHINX_HOST)

all: bin

bin: $(BIN_PERL)

deploy: deploy-service
deploy-service: deploy-dir deploy-scripts deploy-libs deploy-services deploy-monit deploy-sphinx
deploy-client: deploy-dir deploy-scripts deploy-libs  deploy-doc

deploy-dir:
	if [ ! -d $(SERVICE_DIR) ] ; then mkdir $(SERVICE_DIR) ; fi
	if [ ! -d $(SERVICE_DIR)/webroot ] ; then mkdir $(SERVICE_DIR)/webroot ; fi
	if [ ! -d $(SERVICE_DIR)/sphinx ] ; then mkdir $(SERVICE_DIR)/sphinx ; fi

deploy-sphinx:
	$(TPAGE) $(TPAGE_ARGS) service/reindex_sphinx.tt > $(TARGET)/services/$(SERVICE)/reindex_sphinx
	chmod +x $(TARGET)/services/$(SERVICE)/reindex_sphinx
	$(TPAGE) $(TPAGE_ARGS) service/start_sphinx.tt > $(TARGET)/services/$(SERVICE)/start_sphinx
	chmod +x $(TARGET)/services/$(SERVICE)/start_sphinx
	$(TPAGE) $(TPAGE_ARGS) service/stop_sphinx.tt > $(TARGET)/services/$(SERVICE)/stop_sphinx
	chmod +x $(TARGET)/services/$(SERVICE)/stop_sphinx
	$(DEPLOY_RUNTIME)/bin/perl scripts/gen_cdmi_sphinx_conf.pl lib/KSaplingDBD.xml lib/sphinx.conf.tt $(TPAGE_ARGS) > $(TARGET)/services/$(SERVICE)/sphinx.conf

deploy-services:
	$(TPAGE) $(TPAGE_ARGS) service/start_service.tt > $(TARGET)/services/$(SERVICE)/start_service
	chmod +x $(TARGET)/services/$(SERVICE)/start_service
	$(TPAGE) $(TPAGE_ARGS) service/stop_service.tt > $(TARGET)/services/$(SERVICE)/stop_service
	chmod +x $(TARGET)/services/$(SERVICE)/stop_service

deploy-monit:
	$(TPAGE) $(TPAGE_ARGS) service/process.$(SERVICE).tt > $(TARGET)/services/$(SERVICE)/process.$(SERVICE)

deploy-docs:
	$(DEPLOY_RUNTIME)/bin/pod2html -t "Central Store Application API" lib/CDMI_APIImpl.pm > doc/application_api.html
	$(DEPLOY_RUNTIME)/bin/pod2html -t "Central Store Entity/Relationship API" lib/CDMI_EntityAPIImpl.pm > doc/er_api.html
	cp doc/*html $(SERVICE_DIR)/webroot/.

test: test-client 
	echo "running client and script tests"

# What does it mean to test a client. This is a test of a client
# library. If it is a client-server module, then it should be
# run against a running server. You can say that this also tests
# the server, and I agree. You can add a test-server dependancy
# to the test-client target if it makes sense to you. This test
# example assumes there is already a tested running server.
test-client:
        # run each test
	for t in $(CLIENT_TESTS) ; do \
		if [ -f $$t ] ; then \
			$(DEPLOY_RUNTIME)/bin/perl $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done

include $(TOP_DIR)/tools/Makefile.common.rules
