/* Small reference table used by 03_organization_and_region/org_location_map.
   It lists which subledger mapping sets translate an organization into a
   GL location segment. Keeping the codes in a table (not hard-coded in the
   procedure) means a new mapping set only needs one INSERT.

   Replace the example codes with the mapping set codes from your own system. */

CREATE TABLE ref.location_mapping_sets (
    mapping_set_code  VARCHAR(30)  NOT NULL,
    description       VARCHAR(100) NULL
);

INSERT INTO ref.location_mapping_sets (mapping_set_code, description)
VALUES ('PPM_LOCATION_MAPPING_1', 'Project organization to location segment'),
       ('PPM_LOCATION_MAPPING_2', 'Second business unit mapping');

SELECT * FROM ref.location_mapping_sets;
