USE ROLE DOG_DATA5035_ROLE;

CREATE TABLE test_table (
    id          INT           NOT NULL,
    name        VARCHAR(100)  NOT NULL,
    email       VARCHAR(255),
    created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);