## DHRep

This Puppet module sets up an instance of the DARIAH-DE or TextGrid Repository.

If changes are made here, they are deployed to trep.de dariah.eu and repository.de.dariah.eu (scope:dariah) AND textgrid-esx1.gwdg.de and textgrid-esx2.gwdg.de (scope:textgrid).

If you want to have different configuration for development and productive servers, please configure in YAML server files in dariah_de_puppet.

Then please so:

1. Add new variable in service's manifest file (such as manifest/services/publikator.pp)
2. Add new variable to classes' config file(s), such as templates/etc/dhrep/publikator/dariah/context.xml.erb
3. Commit and push to dhrep (this) puppet module
4. Copy new dhrep hash from git log.
5. Add new variables to yaml files (such as dariah_de_puppet/hieradata/trep.de.dariah.eu)
6. Add new dhrep hash (full hash!) to dariah_de_puppet configuration (Puppetfile.lock)
7. Commit and push to dariah_de_puppet repo.
8. Fini
