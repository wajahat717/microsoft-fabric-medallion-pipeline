CREATE TABLE ref.po_style_rule (
    style_id  BIGINT      NOT NULL,
    rule_name VARCHAR(50) NOT NULL
);

INSERT INTO ref.po_style_rule (style_id, rule_name)
VALUES (100000000000001, 'Manifest PO');

SELECT * FROM ref.po_style_rule;
