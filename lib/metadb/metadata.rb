
require_relative 'metadata/crosswalk'
require_relative 'metadata/terms'
require_relative 'metadata/technical_metadata_attribute'
require_relative 'metadata/metadata_attribute'
require_relative 'metadata/metadata_record'
require_relative 'metadata/admin_desc_record'
require_relative 'metadata/admin_record'
require_relative 'metadata/desc_record'
require_relative 'metadata/technical_metadata_record'

module MetaDB
  module Metadata

    CUSTOM_LABELS = [
      'location.image',
      'location.postmark',
      'location.producer',
      'location.recipient',
      'location.sender',
      'location.state',
      'place.birth',
      'place.death',
      'creator.work.agent.creator.display',
      'creator.work.agent.creator.name',
      'approximate',
      'birth.display',
      'death.display',
      'image',
      'period',
      'postmark',
      'semester',
      'work.date.creation.display',
      'work.date.creation.earliestDate',
      'work.date.creation.latestDate',
      'work.date.discovery.display',
      'work.date.discovery.earliestDate',
      'work.date.discovery.latestDate',
      'image.lower',
      'image.upper',
      'artifact.lower',
      'artifact.upper',
      'original',
      'annotation',
      'Artifact',
      'Artifact_Date',
      'Artifact_Material',
      'Artifact_Type',
      'assignment',
      'catalogingNotes',
      'Category',
      'cause.death',
      'citation',
      'condition',
      'critical',
      'Culture_of_Artifact_&_Artist',
      'Date_Created',
      'Date_Modified',
      'Department',
      'ethnicity',
      'FileName',
      'geologic.feature',
      'geologic.process',
      'honors',
      'image.title',
      'inscription.french',
      'inscription.german',
      'indicia',
      'inscription.english',
      'inscription.french',
      'inscription.german',
      'inscription.japanese',
      'Item',
      'military.branch',
      'military.rank',
      'note',
      'Notes',
      'priorityStatus',
      'provenance',
      'Record_ID',
      'Registration_Number',
      'reviewStatus',
      'series',
      'size',
      'unfieldedData',
      'UserName_Created',
      'UserName_Modified',
      'vantagepoint',
      'work.description',
      'work.inscription.display',
      'work.stateEdition.description',
      'work.material',
      'work.materials.display',
      'work.measurements.display',
      'work.technique',
      'relation.work.textref.name',
      'subject.work.subject.term'
    ]

    FILTERED_FIELDS = [
      'url.zoom',
      'dmrecord'
    ]

    DC_ELEMENTS = [
      'created',
      'identifier',
      'rights',
      'source',
      'title',
      'type'
    ]

  end
end

