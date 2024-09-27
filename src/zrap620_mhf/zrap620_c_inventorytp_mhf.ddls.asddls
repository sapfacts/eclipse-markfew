@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZRAP620_C_InventoryTP_MHF
  provider contract transactional_query
  as projection on ZRAP620_R_InventoryTP_MHF
{
  key Uuid,
      InventoryId,
      @Consumption.valueHelpDefinition: [{ 
          entity : {
            name: 'ZRAP620_CE_PRODUCTS_MHF', 
            element: 'Product'  
          } , useForValidation: true }]
      ProductId,
      Quantity,
      @Consumption.valueHelpDefinition: [ {
          entity: {
            name: 'I_UnitOfMeasure',
            element: 'UnitOfMeasure'
          }
          } ]
      QuantityUnit,
      Price,
      @Consumption.valueHelpDefinition: [ {
          entity: {
            name: 'I_Currency',
            element: 'Currency'
          }
          } ]
      CurrencyCode,
      Description,
      OverallStatus,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt

}
