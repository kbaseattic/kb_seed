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


