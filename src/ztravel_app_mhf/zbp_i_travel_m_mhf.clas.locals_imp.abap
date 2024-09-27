*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

  constants: begin of travel_status,
               open type string value 'O',
               accepted TYPE string value 'A',
               rejected type string value 'X',
             end of travel_status.

    TYPES tt_travel_update TYPE TABLE FOR UPDATE zi_travel_m_mhf.

    METHODS validate_customer          FOR VALIDATE ON SAVE IMPORTING keys FOR travel~validateCustomer.
    METHODS validate_dates             FOR VALIDATE ON SAVE IMPORTING keys FOR travel~validateDates.
    METHODS validate_agency            FOR VALIDATE ON SAVE IMPORTING keys FOR travel~validateAgency.

    METHODS set_status_completed       FOR MODIFY IMPORTING   keys FOR ACTION travel~acceptTravel              RESULT result.
*    METHODS get_features               FOR FEATURES IMPORTING keys REQUEST    requested_features FOR travel    RESULT result.

    METHODS CalculateTravelKey         FOR DETERMINE ON MODIFY IMPORTING keys FOR Travel~CalculateTravelKey.
    METHODS deductDiscount FOR MODIFY
      IMPORTING keys FOR ACTION Travel~deductDiscount RESULT result.
    METHODS copyTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~copyTravel.
    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.


ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.

********************************************************************************
*
* Implements the dynamic feature handling for travel instances
*
********************************************************************************
*  METHOD get_features.
*
*    "%control-<fieldname> specifies which fields are read from the entities
*
*    READ ENTITY zi_travel_m_mhf FROM VALUE #( FOR keyval IN keys
*                                                      (  %key                    = keyval-%key
*                                                      "  %control-travel_id      = if_abap_behv=>mk-on
*                                                        %control-overall_status = if_abap_behv=>mk-on
*                                                        ) )
*                                RESULT DATA(lt_travel_result).
*
*
*    result = VALUE #( FOR ls_travel IN lt_travel_result
*                      ( %key                           = ls_travel-%key
*                        %features-%action-acceptTravel = COND #( WHEN ls_travel-overall_status = 'A'
*                                                                    THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
*                      ) ).
*
*  ENDMETHOD.

  METHOD validate_agency.

    READ ENTITY zi_travel_m_mhf\\travel FROM VALUE #(
        FOR <root_key> IN keys ( %key-mykey     = <root_key>-mykey
                                %control = VALUE #( agency_id = if_abap_behv=>mk-on ) ) )
        RESULT DATA(lt_travel).

    DATA lt_agency TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.

    " Optimization of DB select: extract distinct non-initial customer IDs
    lt_agency = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING agency_id = agency_id EXCEPT * ).
    DELETE lt_agency WHERE agency_id IS INITIAL.
    CHECK lt_agency IS NOT INITIAL.

    " Check if customer ID exist
    SELECT FROM /dmo/agency FIELDS agency_id
      FOR ALL ENTRIES IN @lt_agency
      WHERE agency_id = @lt_agency-agency_id
      INTO TABLE @DATA(lt_agency_db).

    " Raise msg for non existing customer id
    LOOP AT lt_travel INTO DATA(ls_travel).
      IF ls_travel-agency_id IS NOT INITIAL AND NOT line_exists( lt_agency_db[ agency_id = ls_travel-agency_id ] ).
        APPEND VALUE #(  mykey = ls_travel-mykey ) TO failed-travel.
        APPEND VALUE #(  mykey = ls_travel-mykey
                        %msg      = new_message( id       = /dmo/cx_flight_legacy=>agency_unkown-msgid
                                                  number   = /dmo/cx_flight_legacy=>agency_unkown-msgno
                                                  v1       = ls_travel-agency_id
                                                  severity = if_abap_behv_message=>severity-error )
                        %element-agency_id = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

    ENDLOOP.


  ENDMETHOD.

METHOD calculatetravelkey.
  READ ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
      ENTITY Travel
        FIELDS ( travel_id )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_travel).

  DELETE lt_travel WHERE travel_id IS NOT INITIAL.
  CHECK lt_travel IS NOT INITIAL.

  "Get max travelID
  SELECT SINGLE FROM ztravel_mhf FIELDS MAX( travel_id ) INTO @DATA(lv_max_travelid).

  "update involved instances
  MODIFY ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
    ENTITY Travel
      UPDATE FIELDS ( travel_id )
      WITH VALUE #( FOR ls_travel IN lt_travel INDEX INTO i (
                         %key      = ls_travel-%key
                         travel_id  = lv_max_travelid + i ) )
  REPORTED DATA(lt_reported).


ENDMETHOD.

********************************************************************************
*
* Implements travel action (in our case: for setting travel overall_status to completed)
*
********************************************************************************
METHOD set_status_completed.

  " Modify in local mode: BO-related updates that are not relevant for authorization checks
  MODIFY ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
         ENTITY travel
            UPDATE FROM VALUE #( FOR key IN keys ( mykey = key-mykey
                                                   overall_status = 'A' " Accepted
                                                   %control-overall_status = if_abap_behv=>mk-on ) )
         FAILED   failed
         REPORTED reported.

  " Read changed data for action result
  READ ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
       ENTITY travel
       FROM VALUE #( FOR key IN keys (  mykey = key-mykey
                                        %control = VALUE #(
                                          agency_id       = if_abap_behv=>mk-on
                                          customer_id     = if_abap_behv=>mk-on
                                          begin_date      = if_abap_behv=>mk-on
                                          end_date        = if_abap_behv=>mk-on
                                          booking_fee     = if_abap_behv=>mk-on
                                          total_price     = if_abap_behv=>mk-on
                                          currency_code   = if_abap_behv=>mk-on
                                          overall_status  = if_abap_behv=>mk-on
                                          description     = if_abap_behv=>mk-on
                                          created_by      = if_abap_behv=>mk-on
                                          created_at      = if_abap_behv=>mk-on
                                          last_changed_by = if_abap_behv=>mk-on
                                          last_changed_at = if_abap_behv=>mk-on
                                        ) ) )
       RESULT DATA(lt_travel).

  result = VALUE #( FOR travel IN lt_travel ( mykey = travel-mykey
                                              %param    = travel
                                            ) ).

ENDMETHOD.



**********************************************************************
*
* Validate customer data when saving travel data
*
**********************************************************************
  METHOD validate_customer.

    READ ENTITY zi_travel_m_mhf\\travel FROM VALUE #(
        FOR <root_key> IN keys ( %key-mykey     = <root_key>-mykey
                                 %control = VALUE #( customer_id = if_abap_behv=>mk-on ) ) )
        RESULT DATA(lt_travel).

    DATA lt_customer TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    " Optimization of DB select: extract distinct non-initial customer IDs
    lt_customer = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING customer_id = customer_id EXCEPT * ).
    DELETE lt_customer WHERE customer_id IS INITIAL.
    CHECK lt_customer IS NOT INITIAL.

    " Check if customer ID exist
    SELECT FROM /dmo/customer FIELDS customer_id
      FOR ALL ENTRIES IN @lt_customer
      WHERE customer_id = @lt_customer-customer_id
      INTO TABLE @DATA(lt_customer_db).

    " Raise msg for non existing customer id
    LOOP AT lt_travel INTO DATA(ls_travel).
      IF ls_travel-customer_id IS NOT INITIAL AND NOT line_exists( lt_customer_db[ customer_id = ls_travel-customer_id ] ).
        APPEND VALUE #(  mykey = ls_travel-mykey ) TO failed-travel.
        APPEND VALUE #(  mykey = ls_travel-mykey
                         %msg      = new_message( id       = /dmo/cx_flight_legacy=>customer_unkown-msgid
                                                  number   = /dmo/cx_flight_legacy=>customer_unkown-msgno
                                                  v1       = ls_travel-customer_id
                                                  severity = if_abap_behv_message=>severity-error )
                         %element-customer_id = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


**********************************************************************
*
* Check validity of date
*
**********************************************************************
  METHOD validate_dates.

    READ ENTITY zi_travel_m_mhf\\travel FROM VALUE #(
      FOR <root_key> IN keys ( %key-mykey     = <root_key>-mykey
                               %control = VALUE #( begin_date = if_abap_behv=>mk-on
                                                   end_date   = if_abap_behv=>mk-on ) ) )
      RESULT DATA(lt_travel_result).

    LOOP AT lt_travel_result INTO DATA(ls_travel_result).

      IF ls_travel_result-end_date < ls_travel_result-begin_date.  "end_date before begin_date

        APPEND VALUE #( %key        = ls_travel_result-%key
                        mykey   = ls_travel_result-mykey ) TO failed-travel.

        APPEND VALUE #( %key     = ls_travel_result-%key
                        %msg     = new_message( id       = /dmo/cx_flight_legacy=>end_date_before_begin_date-msgid
                                                number   = /dmo/cx_flight_legacy=>end_date_before_begin_date-msgno
                                                v1       = ls_travel_result-begin_date
                                                v2       = ls_travel_result-end_date
                                                v3       = ls_travel_result-travel_id
                                                severity = if_abap_behv_message=>severity-error )
                        %element-begin_date = if_abap_behv=>mk-on
                        %element-end_date   = if_abap_behv=>mk-on ) TO reported-travel.

      ELSEIF ls_travel_result-begin_date < cl_abap_context_info=>get_system_date( ).  "begin_date must be in the future

        APPEND VALUE #( %key        = ls_travel_result-%key
                        mykey   = ls_travel_result-mykey ) TO failed-travel.

        APPEND VALUE #( %key = ls_travel_result-%key
                        %msg = new_message( id       = /dmo/cx_flight_legacy=>begin_date_before_system_date-msgid
                                            number   = /dmo/cx_flight_legacy=>begin_date_before_system_date-msgno
                                            severity = if_abap_behv_message=>severity-error )
                        %element-begin_date = if_abap_behv=>mk-on
                        %element-end_date   = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

*  METHOD deductDiscount.
***************************************************************************
** Instance-bound non-factory action:
** Deduct the specified discount from the booking fee (BookingFee)
***************************************************************************
*  DATA travels_for_update TYPE TABLE FOR UPDATE zi_travel_m_mhf.
*  DATA(keys_with_valid_discount) = keys.
*
*  " read relevant travel instance data (only booking fee)
*  READ ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
*      ENTITY Travel
*      FIELDS ( Booking_Fee )
*      WITH CORRESPONDING #( keys_with_valid_discount )
*      RESULT DATA(travels).
*
*  LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
*      DATA(reduced_fee) = <travel>-Booking_Fee * ( 1 - 3 / 10 ) .
*
*      APPEND VALUE #( %tky       = <travel>-%tky
*                    Booking_Fee = reduced_fee
*                  ) TO travels_for_update.
*  ENDLOOP.
*
*  " update data with reduced fee
*  MODIFY ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
*      ENTITY Travel
*      UPDATE FIELDS ( Booking_Fee )
*      WITH travels_for_update.
*
*  " read changed data for action result
*  READ ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
*      ENTITY Travel
*      ALL FIELDS WITH
*      CORRESPONDING #( travels )
*      RESULT DATA(travels_with_discount).
*
*  " set action result
*  result = VALUE #( FOR travel IN travels_with_discount ( %tky   = travel-%tky
*                                                            %param = travel ) ).
*  ENDMETHOD.

**************************************************************************
* Instance-bound non-factory action with parameter `deductDiscount`:
* Deduct the specified discount from the booking fee (BookingFee)
**************************************************************************
METHOD deductDiscount.
  DATA travels_for_update TYPE TABLE FOR UPDATE zi_travel_m_mhf.
  DATA(keys_with_valid_discount) = keys.

  " check and handle invalid discount values
  LOOP AT keys_with_valid_discount ASSIGNING FIELD-SYMBOL(<key_with_valid_discount>)
    WHERE %param-discount_percent IS INITIAL OR %param-discount_percent > 100 OR %param-discount_percent <= 0.

    " report invalid discount value appropriately
    APPEND VALUE #( %tky                       = <key_with_valid_discount>-%tky ) TO failed-travel.

    APPEND VALUE #( %tky                       = <key_with_valid_discount>-%tky
                    %msg                       = NEW /dmo/cm_flight_messages(
                                                      textid = /dmo/cm_flight_messages=>discount_invalid
                                                      severity = if_abap_behv_message=>severity-error )
                    %element-Total_Price        = if_abap_behv=>mk-on
                    %op-%action-deductDiscount = if_abap_behv=>mk-on
                  ) TO reported-travel.

    " remove invalid discount value
    DELETE keys_with_valid_discount.
  ENDLOOP.

  " check and go ahead with valid discount values
  CHECK keys_with_valid_discount IS NOT INITIAL.

  " read relevant travel instance data (only booking fee)
  READ ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
    ENTITY Travel
      FIELDS ( Booking_Fee )
      WITH CORRESPONDING #( keys_with_valid_discount )
    RESULT DATA(travels).

  LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
    DATA percentage TYPE decfloat16.
    DATA(discount_percent) = keys_with_valid_discount[ %tky = <travel>-%tky ]-%param-discount_percent.
    percentage =  discount_percent / 100 .
    DATA(reduced_fee) = <travel>-Booking_Fee * ( 1 - percentage ) .

    APPEND VALUE #( %tky       = <travel>-%tky
                    Booking_Fee = reduced_fee
                  ) TO travels_for_update.
  ENDLOOP.

  " update data with reduced fee
  MODIFY ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
    ENTITY Travel
      UPDATE FIELDS ( Booking_Fee )
      WITH travels_for_update.

  " read changed data for action result
  READ ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
    ENTITY Travel
      ALL FIELDS WITH
      CORRESPONDING #( travels )
    RESULT DATA(travels_with_discount).

  " set action result
  result = VALUE #( FOR travel IN travels_with_discount ( %tky   = travel-%tky
                                                          %param = travel ) ).
ENDMETHOD.

**************************************************************************
* Instance-bound factory action `copyTravel`:
* Copy an existing travel instance
**************************************************************************
METHOD copyTravel.
   DATA:
      travels       TYPE TABLE FOR CREATE zi_travel_m_mhf\\travel.

   " remove travel instances with initial %cid (i.e., not set by caller API)
   READ TABLE keys WITH KEY %cid = '' INTO DATA(key_with_inital_cid).
   ASSERT key_with_inital_cid IS INITIAL.

   " read the data from the travel instances to be copied
   READ ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
      ENTITY travel
      ALL FIELDS WITH CORRESPONDING #( keys )
   RESULT DATA(travel_read_result)
   FAILED failed.

   LOOP AT travel_read_result ASSIGNING FIELD-SYMBOL(<travel>).
      " fill in travel container for creating new travel instance
      APPEND VALUE #( %cid      = keys[ KEY entity %key = <travel>-%key ]-%cid
*                     %is_draft = keys[ KEY entity %key = <travel>-%key ]-%param-%is_draft
                     %data     = CORRESPONDING #( <travel> EXCEPT Travel_ID )
                  )
      TO travels ASSIGNING FIELD-SYMBOL(<new_travel>).

      " adjust the copied travel instance data
      "" BeginDate must be on or after system date
      <new_travel>-Begin_Date     = cl_abap_context_info=>get_system_date( ).
      "" EndDate must be after BeginDate
      <new_travel>-End_Date       = cl_abap_context_info=>get_system_date( ) + 30.
      "" OverallStatus of new instances must be set to open ('O')
      <new_travel>-Overall_Status = travel_status-open.
   ENDLOOP.

   " create new BO instance
   MODIFY ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
      ENTITY travel
      CREATE FIELDS ( Agency_ID Customer_ID Begin_Date End_Date Booking_Fee
                        Total_Price Currency_Code Overall_Status Description )
         WITH travels
      MAPPED DATA(mapped_create).

   " set the new BO instances
   mapped-travel   =  mapped_create-travel .
ENDMETHOD.

*************************************************************************************
* Instance-bound non-factory action: Set the overall travel status to 'X' (rejected)
*************************************************************************************
METHOD rejectTravel.
   " modify travel instance(s)
   MODIFY ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
      ENTITY Travel
      UPDATE FIELDS ( Overall_Status )
      WITH VALUE #( FOR key IN keys ( %tky          = key-%tky
                                       Overall_Status = travel_status-rejected ) )  " 'X'
   FAILED failed
   REPORTED reported.

   " read changed data for action result
   READ ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
      ENTITY Travel
      ALL FIELDS WITH
      CORRESPONDING #( keys )
      RESULT DATA(travels).

   " set the action result parameter
   result = VALUE #( FOR travel IN travels ( %tky   = travel-%tky
                                            %param = travel ) ).
ENDMETHOD.

**************************************************************************
* Instance-based dynamic feature control
**************************************************************************
  METHOD get_instance_features.
  " read relevant travel instance data
    READ ENTITIES OF zi_travel_m_mhf IN LOCAL MODE
      ENTITY travel
        FIELDS ( Travel_ID Overall_Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels)
      FAILED failed.

    " evaluate the conditions, set the operation state, and set result parameter
    result = VALUE #( FOR travel IN travels
                      ( %tky                   = travel-%tky

                        %features-%update      = COND #( WHEN travel-Overall_Status = travel_status-accepted
                                                        THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
                        %features-%delete      = COND #( WHEN travel-Overall_Status = travel_status-open
                                                        THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled   )
*                        %action-Edit           = COND #( WHEN travel-Overall_Status = travel_status-accepted
*                                                         THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
                        %action-acceptTravel   = COND #( WHEN travel-Overall_Status = travel_status-accepted
                                                          THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
                        %action-rejectTravel   = COND #( WHEN travel-Overall_Status = travel_status-rejected
                                                          THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
                        %action-deductDiscount = COND #( WHEN travel-Overall_Status = travel_status-open
                                                          THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled   )
                    ) ).

  ENDMETHOD.


ENDCLASS.
