#Region Public

// Redefines the opening of the product selection form in the processing of print labels.
//
// Parameters:
//  OpeningParameters - Structure:
//   * OwnerForm - ClientApplicationForm - owner form.
//   * CloseHandler - CallbackDescription - notification when the form is closed.
//   * LockMode - FormWindowOpeningMode - owner form window lock mode.
//   * RetailFacility - DefinedType.RetailFacilityCEL - a trading object for determining the properties of goods.
//
Procedure OpenSelectionForm(OpeningParameters) Export
	
	
	
EndProcedure

// Overrides the notification closing the selection form and processing the results. For processing to work, it is necessary to fill in the parameter Array of goods for printing.
//
// Parameters:
//  Result - Structure - the structure of the result of the goods selection procedure.
//  OperationParametersList - Structure - parameters of the goods selection procedure.
//  ArrayOfProductsForPrinting - Array of SeePrintPLLabelsAndPriceTagsClientServer.ProductForPrinting - an array of products to fill in.
//
Procedure SelectGoodsCompletion(Result, OperationParametersList, ArrayOfProductsForPrinting) Export
	
	
EndProcedure

// Overrides the notification closing the selection form and processing the results. For processing to work, it is necessary to fill in the parameter Array of goods for printing.
//
// Parameters:
//  OperationParametersList - Structure - parameters of the goods selection procedure.
//  ArrayOfProductsForPrinting - Array of SeePrintPLLabelsAndPriceTagsClientServer.ProductForPrinting - an array of products to fill in.
//
Procedure FillInByPicking(OperationParametersList, ArrayOfProductsForPrinting) Export

EndProcedure

// Overrides the notification closing the barcode search form and processing the results. For processing to work, it is necessary to fill in the parameter Array of goods for printing.
//
// Parameters:
//  Result - Structure - the structure of the result of the goods selection procedure.
//  OperationParametersList - Structure - parameters of the goods selection procedure.
//  ArrayOfProductsForPrinting - Array of SeePrintPLLabelsAndPriceTagsClientServer.ProductForPrinting - an array of products to fill in.
//
Procedure NotificationOfBarCodeSearchForBPOLabelsAndPriceTags(Result, OperationParametersList, ArrayOfProductsForPrinting) Export
	
	
EndProcedure

// Parameters of the opening command.
// 
// Parameters:
//  FormParameters - Structure - Shape parameter
//
Procedure ParametersOfOpeningCommand(FormParameters) Export
	
	
EndProcedure

// Overrides data upload to the TSD
// 
// Parameters:
//  Object - ClientApplicationForm - owner form.
//  FormParameters - Structure - shape parameter.
//
Procedure UploadVTSD(Object, FormParameters) Export
	
	
EndProcedure

// Overrides data loading on the TSD
// 
// Parameters:
//  Object - ClientApplicationForm - owner form.
//  FormParameters - Structure - shape parameter.
//  CallbackDescription - CallbackDescription - notification for the end of data loading.
//
Procedure DownloadFromTSD(Object, FormParameters, CallbackDescription) Export
	
	
EndProcedure

// Overrides the notification of data loading from the TSD. For processing to work, it is necessary to fill in the parameter Array of goods for printing.
//
// Parameters:
//  Object - Structure - the structure of the result of the goods selection procedure.
//  FormParameters - Structure - parameters of the goods selection procedure.
//  ArrayOfProductsForPrinting - Array of SeePrintPLLabelsAndPriceTagsClientServer.ProductForPrinting - an array of products to fill in.
//
Procedure NotificationOfLoadingOfLabelsAndPriceTagsOfBPOFromTSD(Object, FormParameters, ArrayOfProductsForPrinting) Export
	
	
EndProcedure

// Parameters of unloading and loading in the TSD.
// 
// Parameters:
//  AdditionalParameters - Undefined - it will be transferred to the procedure to unload the VTSD
Procedure VTSDUploadAndDownloadParameters(AdditionalParameters) Export
	
EndProcedure

// Called when creating the form of the template element, the label of the price tags is called.
//
// Parameters:
//   Form - ClientApplicationForm - processing form
//
Procedure WhenChangingPriceType(Form) Export

EndProcedure

// Overrides the opening of the skd editing form.
//
// Parameters:
//  OpeningParameters - Structure
//
Procedure EditDCS(OpeningParameters) Export

EndProcedure

// Overrides the SKD editing alert.
//
// Parameters:
//  Result - Structure - the structure of the result of the goods selection procedure.
//  OperationParametersList - Structure - parameters of the goods selection procedure.
//
Procedure ProcessingOpeningOfDCSSettings(Result, OperationParametersList) Export

EndProcedure

// Overrides the form notification processing.
//
// Parameters:
//  EventName - String - name of the notification event,
//  Parameter - String - notification parameter,
//  Source - String - source of the alert call,
//  Form - ClientApplicationForm - object form.
//
Procedure NotificationProcessing(EventName, Parameter, Source, Form) Export

EndProcedure

// Overrides the SKD editing alert.
//
// Parameters:
//  SelectedProductItems - Array
//  Goods - ValueTable - goods for installing barcodes.
//  Barcodes - Map
//
Procedure SetItemBarcodes(SelectedProductItems, Goods, Barcodes) Export

EndProcedure

Procedure LabelEditorFormOfEditingTemplateWhenOpening(ThisForm, Cancel) Export
	
EndProcedure

#EndRegion