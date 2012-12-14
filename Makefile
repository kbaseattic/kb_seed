TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common

SRC_PERL = $(wildcard scripts/*.pl)
BIN_PERL = $(addprefix $(BIN_DIR)/,$(basename $(notdir $(SRC_PERL))))

DEPLOY_PERL = $(addprefix $(TARGET)/bin/,$(basename $(notdir $(SRC_PERL))))

SERVER_MODULE = CDMI_API
SERVICE = cdmi_api
SERVICE_PORT = 7032

SPHINX_PORT = 7038
SPHINX_HOST = localhost

TPAGE_ARGS = --define kb_top=$(TARGET) --define kb_runtime=$(DEPLOY_RUNTIME) --define kb_service_name=$(SERVICE) \
	--define kb_service_port=$(SERVICE_PORT) --define kb_service_dir=$(SERVICE_DIR) \
	--define kb_sphinx_port=$(SPHINX_PORT) --define kb_sphinx_host=$(SPHINX_HOST)

JARFILE = $(PWD)/lib/cdmi.jar

all: bin

bin: $(BIN_PERL)

deploy: deploy-service
deploy-service: deploy-dir deploy-scripts deploy-libs deploy-services deploy-monit deploy-sphinx deploy-java
deploy-client: deploy-dir deploy-scripts deploy-libs  deploy-doc 
#deploy-client: deploy-dir deploy-scripts deploy-libs  deploy-doc deploy-java

deploy-java: java-client
	cp $(JARFILE) $(TARGET)/lib/.

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

deploy-doc:
	$(DEPLOY_RUNTIME)/bin/pod2html -t "Central Store Application API" lib/CDMI_APIImpl.pm > doc/application_api.html
	$(DEPLOY_RUNTIME)/bin/pod2html -t "Central Store Entity/Relationship API" lib/CDMI_EntityAPIImpl.pm > doc/er_api.html
	cp doc/*html $(SERVICE_DIR)/webroot/.

java-client: java.out/built_flag

java.out/built_flag: lib/CDMI-API.spec lib/CDMI-EntityAPI.spec 
	rm -rf java.out
	mkdir java.out
	gen_java_client lib/CDMI-API.spec lib/CDMI-EntityAPI.spec us.kbase.CDMI_API java.out
	#
	# Ugh. Until we fix the XML or the compiler, patch the subsystem class to remove the reserved word
	#
	perl -pi.bak -e 's/private/m_private/' java.out/us/kbase/CDMI_API/fields_Subsystem.java
	cd java.out; find us -type f -name \*.java -print > tmp.files
	cd java.out; $(JAVAC) $(JAVAC_FLAGS) @tmp.files
	cd java.out; find us -type f -name \*.class -print > tmp.files
	cd java.out; $(JAR) cf $(JAR) @tmp.files
	touch java.out/built_flag

include $(TOP_DIR)/tools/Makefile.common.rules
