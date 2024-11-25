"! <p class="shorttext synchronized">Consumption model for client proxy - generated</p>
"! This class has been generated based on the metadata with namespace
"! <em>cds_zmhf_sd_shop</em>
CLASS zcl_scm_shop_mhf DEFINITION
  PUBLIC
  INHERITING FROM /iwbep/cl_v4_abs_pm_model_prov
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      "! <p class="shorttext synchronized">OnlineShopType</p>
      BEGIN OF tys_online_shop_type,
        "! <em>Key property</em> Order_Uuid
        order_uuid   TYPE sysuuid_x16,
        "! Order_Id
        order_id     TYPE c LENGTH 10,
        "! Ordereditem
        ordereditem  TYPE c LENGTH 10,
        "! Deliverydate
        deliverydate TYPE datn,
        "! Creationdate
        creationdate TYPE datn,
        "! PackageId
        package_id   TYPE int1,
        "! CostCenter
        cost_center  TYPE c LENGTH 10,
        "! Purchasereqn
        purchasereqn TYPE c LENGTH 256,
      END OF tys_online_shop_type,
      "! <p class="shorttext synchronized">List of OnlineShopType</p>
      tyt_online_shop_type TYPE STANDARD TABLE OF tys_online_shop_type WITH DEFAULT KEY.


    CONSTANTS:
      "! <p class="shorttext synchronized">Internal Names of the entity sets</p>
      BEGIN OF gcs_entity_set,
        "! OnlineShop
        "! <br/> Collection of type 'OnlineShopType'
        online_shop TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name VALUE 'ONLINE_SHOP',
      END OF gcs_entity_set .

    CONSTANTS:
      "! <p class="shorttext synchronized">Internal names for entity types</p>
      BEGIN OF gcs_entity_type,
        "! <p class="shorttext synchronized">Internal names for OnlineShopType</p>
        "! See also structure type {@link ..tys_online_shop_type}
        BEGIN OF online_shop_type,
          "! <p class="shorttext synchronized">Navigation properties</p>
          BEGIN OF navigation,
            "! Dummy field - Structure must not be empty
            dummy TYPE int1 VALUE 0,
          END OF navigation,
        END OF online_shop_type,
      END OF gcs_entity_type.


    METHODS /iwbep/if_v4_mp_basic_pm~define REDEFINITION.


  PRIVATE SECTION.

    "! <p class="shorttext synchronized">Model</p>
    DATA mo_model TYPE REF TO /iwbep/if_v4_pm_model.


    "! <p class="shorttext synchronized">Define OnlineShopType</p>
    "! @raising /iwbep/cx_gateway | <p class="shorttext synchronized">Gateway Exception</p>
    METHODS def_online_shop_type RAISING /iwbep/cx_gateway.

ENDCLASS.



CLASS ZCL_SCM_SHOP_MHF IMPLEMENTATION.


  METHOD /iwbep/if_v4_mp_basic_pm~define.

    mo_model = io_model.
    mo_model->set_schema_namespace( 'cds_zmhf_sd_shop' ) ##NO_TEXT.

    def_online_shop_type( ).

  ENDMETHOD.


  METHOD def_online_shop_type.

    DATA:
      lo_complex_property    TYPE REF TO /iwbep/if_v4_pm_cplx_prop,
      lo_entity_type         TYPE REF TO /iwbep/if_v4_pm_entity_type,
      lo_entity_set          TYPE REF TO /iwbep/if_v4_pm_entity_set,
      lo_navigation_property TYPE REF TO /iwbep/if_v4_pm_nav_prop,
      lo_primitive_property  TYPE REF TO /iwbep/if_v4_pm_prim_prop.


    lo_entity_type = mo_model->create_entity_type_by_struct(
                                    iv_entity_type_name       = 'ONLINE_SHOP_TYPE'
                                    is_structure              = VALUE tys_online_shop_type( )
                                    iv_do_gen_prim_props         = abap_true
                                    iv_do_gen_prim_prop_colls    = abap_true
                                    iv_do_add_conv_to_prim_props = abap_true ).

    lo_entity_type->set_edm_name( 'OnlineShopType' ) ##NO_TEXT.


    lo_entity_set = lo_entity_type->create_entity_set( 'ONLINE_SHOP' ).
    lo_entity_set->set_edm_name( 'OnlineShop' ) ##NO_TEXT.


    lo_primitive_property = lo_entity_type->get_primitive_property( 'ORDER_UUID' ).
    lo_primitive_property->set_edm_name( 'Order_Uuid' ) ##NO_TEXT.
    lo_primitive_property->set_edm_type( 'Guid' ) ##NO_TEXT.
    lo_primitive_property->set_is_key( ).

    lo_primitive_property = lo_entity_type->get_primitive_property( 'ORDER_ID' ).
    lo_primitive_property->set_edm_name( 'Order_Id' ) ##NO_TEXT.
    lo_primitive_property->set_edm_type( 'String' ) ##NO_TEXT.
    lo_primitive_property->set_max_length( 10 ) ##NUMBER_OK.
    lo_primitive_property->set_is_nullable( ).

    lo_primitive_property = lo_entity_type->get_primitive_property( 'ORDEREDITEM' ).
    lo_primitive_property->set_edm_name( 'Ordereditem' ) ##NO_TEXT.
    lo_primitive_property->set_edm_type( 'String' ) ##NO_TEXT.
    lo_primitive_property->set_max_length( 10 ) ##NUMBER_OK.
    lo_primitive_property->set_is_nullable( ).

    lo_primitive_property = lo_entity_type->get_primitive_property( 'DELIVERYDATE' ).
    lo_primitive_property->set_edm_name( 'Deliverydate' ) ##NO_TEXT.
    lo_primitive_property->set_edm_type( 'Date' ) ##NO_TEXT.
    lo_primitive_property->set_is_nullable( ).
    lo_primitive_property->set_edm_type_v2( 'DateTime' ) ##NO_TEXT.

    lo_primitive_property = lo_entity_type->get_primitive_property( 'CREATIONDATE' ).
    lo_primitive_property->set_edm_name( 'Creationdate' ) ##NO_TEXT.
    lo_primitive_property->set_edm_type( 'Date' ) ##NO_TEXT.
    lo_primitive_property->set_is_nullable( ).
    lo_primitive_property->set_edm_type_v2( 'DateTime' ) ##NO_TEXT.

    lo_primitive_property = lo_entity_type->get_primitive_property( 'PACKAGE_ID' ).
    lo_primitive_property->set_edm_name( 'PackageId' ) ##NO_TEXT.
    lo_primitive_property->set_edm_type( 'Byte' ) ##NO_TEXT.
    lo_primitive_property->set_is_nullable( ).

    lo_primitive_property = lo_entity_type->get_primitive_property( 'COST_CENTER' ).
    lo_primitive_property->set_edm_name( 'CostCenter' ) ##NO_TEXT.
    lo_primitive_property->set_edm_type( 'String' ) ##NO_TEXT.
    lo_primitive_property->set_max_length( 10 ) ##NUMBER_OK.
    lo_primitive_property->set_is_nullable( ).

    lo_primitive_property = lo_entity_type->get_primitive_property( 'PURCHASEREQN' ).
    lo_primitive_property->set_edm_name( 'Purchasereqn' ) ##NO_TEXT.
    lo_primitive_property->set_edm_type( 'String' ) ##NO_TEXT.
    lo_primitive_property->set_max_length( 256 ) ##NUMBER_OK.
    lo_primitive_property->set_is_nullable( ).

  ENDMETHOD.
ENDCLASS.
