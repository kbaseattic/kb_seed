To rebuild the ERDB scripts from an updated CDMI spec file:

dbd=/home/parrello/CdmiData/Published/KSaplingDBD.xml

compile_dbd_to_typespec CDMI_API CDMI_EntityAPI $dbd CDMI-EntityAPI.spec  \
        Bio/KBase/CDMI/CDMI_EntityAPIImpl.pm er_scripts

compile_typespec \
        -impl Bio::KBase::CDMI::%sImpl \
        -service Bio::KBase::CDMI::Service \
        -psgi CDMI.psgi \
        -client Bio::KBase::CDMI::Client \
        -js CDMI \
        -py CDMI \
        CDMI-API.spec CDMI-EntityAPI.spec .

This service uses the standard deploy.cfg configuration format:
Example:
[cdmi]
DBD = /home/ubuntu/KSaplingDBD.xml
dbName = experiment
userData = root/
dbhost = localhost
dbms = mysql


and invoke setting the KB_SERVICE_NAME variable to cdmi and the
KB_DEPLOYMENT_CONFIG variable to the config file above you can
override the various settings.


