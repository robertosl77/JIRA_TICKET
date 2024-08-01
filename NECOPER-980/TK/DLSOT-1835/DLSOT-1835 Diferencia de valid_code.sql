SELECT 
    LINKVALUE,  
    TRIM(EDENOR_CARTOGRAFIA.EM_VALID_CODE(LINKVALUE)) PROPOSED_VALID_CODE
    --,edenor_cartografia.em_valid_code(linkvalue) current_valid_code
FROM 
    (select 'S8.830MO' linkvalue from dual
    UNION
    select 'S04-1130' linkvalue from dual);