@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@Search.searchable: true
@ObjectModel.semanticKey: ['TravelID']
@AccessControl.authorizationCheck: #CHECK
define root view entity ZRAP100_C_TRAVELTP_MHF
  provider contract transactional_query
  as projection on ZRAP100_R_TRAVELTP_MHF
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.90
  key TravelId,
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['AgencyName']
      @Consumption.valueHelpDefinition: [{ entity : {name: '/DMO/I_Agency_StdVH',
                                           element: 'AgencyID' },
                                           useForValidation: true }]

      AgencyId,
      _Agency.Name              as AgencyName,
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['CustomerName']
      @Consumption.valueHelpDefinition: [{ entity : {name: '/DMO/I_Customer_StdVH',
                                           element: 'CustomerID' },
                                           useForValidation: true }]
      CustomerId,
      _Customer.LastName        as CustomerName,
      BeginDate,
      EndDate,
      BookingFee,
      TotalPrice,
      @Consumption.valueHelpDefinition: [{ entity: {name: 'I_CurrencyStdVH', 
                                           element: 'Currency' }, 
                                           useForValidation: true }]
      @Semantics.currencyCode: true
      CurrencyCode,
      Description,
      @ObjectModel.text.element: ['OverallStatusText']
      @Consumption.valueHelpDefinition: [{ entity: {name: '/DMO/I_Overall_Status_VH', 
                                                    element: 'OverallStatus' }, 
                                                    useForValidation: true }]
      OverallStatus,
      _OverallStatus._Text.Text as OverallStatusText : localized,
      Attachment,
      MimeType,
      FileName,
      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt

}