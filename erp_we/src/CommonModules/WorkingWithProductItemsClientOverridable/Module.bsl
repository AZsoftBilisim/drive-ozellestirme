
////////////////////////////////////////////////////////////////////////////////
// Subsystem "Working with nomenclature".
// General module.The work of the nomenclature of the client is undefined.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ProductSearchFormByBarcode

// Procedure called from the form event handler when Opening the search nomenclature form by Barcode.
//
// Parameters:
//  Form - ClientApplicationForm - the form from the event handler where the procedure is called.
//
Procedure SearchForProductsByBarcodeWhenOpening(Form) Export
	ProcessingOfItemsClientTM.SearchForProductsByBarcodeWhenOpening(Form);
EndProcedure

// Procedure called from the event handler of the form when the search nomenclature form is Closed by the Barcode.
//
// Parameters:
//  Form - ClientApplicationForm - the form from the event handler where the procedure is called.
//  Exit - Boolean - indicates that the job is finished.
//
Procedure SearchForProductsByBarcodeWhenClosing(Form, Exit) Export
	ProcessingOfItemsClientTM.SearchForProductsByBarcodeWhenClosing(Form, Exit);
EndProcedure

// Procedure called from the notification handler of the search nomenclature form by Barcode.
//
// Parameters:
//  Form - ClientApplicationForm - the form from the event handler where the procedure is called.
//  EventName	 - String - event name.
//  Parameter	 - Arbitrary - notification parameters.
//  Source	 - String - source of the alert.
//  Barcodes	 - Array - an array of strings of marks. Filled in when processing notifications from the equipment (Line).
//
Procedure ProductSearchByBarcodeNotificationProcessing(Form, EventName, Parameter, Source, Barcodes) Export
	ProcessingOfItemsClientTM.ProductSearchByBarcodeNotificationProcessing(Form, EventName, Parameter, Source, Barcodes);
EndProcedure

// Procedure that is called when processing the selection of the search nomenclature form by Barcode.
//
// Parameters:
//  Form - ClientApplicationForm - the form from the event handler where the procedure is called.
//  ValueSelected - Arbitrary - selected value.
//  ChoiceSource - Arbitrary - source of selection.
//
Procedure ProductSearchByBarcodeSelectionProcessing(Form, ValueSelected, ChoiceSource) Export
	ProcessingOfItemsClientTM.ProductSearchByBarcodeSelectionProcessing(Form, ValueSelected, ChoiceSource);
EndProcedure

// Procedure called when you change the Item field in the search nomenclature form by Barcode.
//
// Parameters:
//  Form	 - ClientApplicationForm - bar code search form for an item.
//  Item	 - FormField - a form field that can be changed.
//
Procedure SearchForProductsByBarcodeProductsWhenChanged(Form, Item) Export
	ProcessingOfItemsClientTM.SearchForProductsByBarcodeProductsWhenChanged(Form, Item);
EndProcedure

// Procedure called when creating the search nomenclature form in the Nomenclature field by Barcode.
//
// Parameters:
//  Form - ClientApplicationForm - the form from the event handler where the procedure is called.
//  Item				 - FormField - form element.
//  StandardProcessing - Boolean - indicates standard processing.
//
Procedure SearchForProductsByBarcodeProductsCreation(Form, Item, StandardProcessing) Export
	ProcessingOfItemsClientTM.SearchForProductsByBarcodeProductsCreation(Form, Item, StandardProcessing);
EndProcedure

// Procedure that is called when you start selecting items in the Nomenclature field of the search nomenclature form by Barcode.
//
// Parameters:
//  Form - ClientApplicationForm - the form from the event handler where the procedure is called.
//  Item				 - FormField - form element.
//  ChoiceData		 - ValueList - the selection data..
//  StandardProcessing - Boolean -  indicates standard processing.
//
Procedure SearchForProductsByBarcodeProductsStartSelection(Form, Item, ChoiceData, StandardProcessing) Export
	ProcessingOfItemsClientTM.SearchForProductsByBarcodeProductsStartSelection(Form, Item, ChoiceData, StandardProcessing);
EndProcedure

// Procedure that is called when changing the Feature field of the search nomenclature form by Barcode.
//
// Parameters:
//  Form	 - ClientApplicationForm - bar code search form for an item.
//  Item	 - FormField - a form field that can be changed.
//
Procedure SearchForProductsByBarcodeCharacteristicWhenChanging(Form, Item) Export
	ProcessingOfItemsClientTM.SearchForProductsByBarcodeCharacteristicWhenChanging(Form, Item);
EndProcedure

// Procedure that is called when creating the search nomenclature field in the Search nomenclature field by Barcode.
//
// Parameters:
//  Form - ClientApplicationForm - the form from the event handler where the procedure is called.
//  Item				 - FormField - form element.
//  StandardProcessing - Boolean - indicates standard processing.
//
Procedure ProductSearchByBarcodeFeatureCreation(Form, Item, StandardProcessing) Export
	
EndProcedure

// Procedure that is called when you start selecting in the Characteristics field of the search nomenclature form by Barcode.
//
// Parameters:
//  Form - ClientApplicationForm - the form from the event handler where the procedure is called.
//  Item				 - FormField - form element.
//  ChoiceData		 - ValueList - the selection data..
//  StandardProcessing - Boolean -  indicates standard processing.
//
Procedure SearchForProductsByBarcodeCharacteristicsStartOfSelection(Form, Item, ChoiceData, StandardProcessing) Export
	
EndProcedure

// The procedure that is called when the connected commands are executed.
//
// Parameters:
//   Form                   - ClientApplicationForm - the form from which the procedure is called.
//   Command                 - FormCommand - form command.
//   AdditionalParameters - Undefined, Structure of KeyAndValue - advanced setting.
//
Procedure SearchForItemsByBarcodeRunCommand(Form, Command, AdditionalParameters = Undefined) Export
	
EndProcedure

// The procedure that is called ON changing the Form element.
//
// Parameters:
//   Form                   - ClientApplicationForm - the form from which the procedure is called.
//   Item                 - FormField - form element.
//   AdditionalParameters - Undefined, Structure of KeyAndValue - advanced setting.
//
Procedure SearchForItemsByBarcodeONChange(Form, Item, AdditionalParameters = Undefined) Export
	ProcessingOfItemsClientTM.SearchForItemsByBarcodeONChange(Form, Item);
EndProcedure

// The procedure called when clearing the value of a Form element.
//
// Parameters:
//   Form                   - ClientApplicationForm - the form from which the procedure is called.
//   Item                 - FormField - form element.
//   StandardProcessing    - Boolean - This parameter is passed to indicate that the standard (system)
//                               event processing has been performed. If you set this parameter to False in the body of the handler procedure, 
//                               the standard event processing will not be performed.
//   AdditionalParameters - Undefined, Structure of KeyAndValue - advanced setting.
//
Procedure ItemSearchByBarcodeCleaning(Form, Item, StandardProcessing = True, 
			AdditionalParameters = Undefined) Export
	
EndProcedure

// The procedure that is called when the user selects the create command in the input field.
//
// Parameters:
//   Form                   - ClientApplicationForm - the form from which the procedure is called.
//   Item                 - FormField - form element.
//   StandardProcessing    - Boolean - This parameter is passed to indicate that the standard (system)
//                               event processing has been performed. If you set this parameter to False in the body of the handler procedure, 
//                               the standard event processing will not be performed.
//   AdditionalParameters - Undefined, Structure of KeyAndValue - advanced setting.
//
Procedure SearchProductsByBarcodeCreating(Form, Item, StandardProcessing = True, 
			AdditionalParameters = Undefined) Export
	
EndProcedure

// The procedure that is called when the selection button is pressed in the input field.
//
// Parameters:
//   Form                   - ClientApplicationForm - the form from which the procedure is called.
//   Item                 - FormField - form element.
//   ChoiceData            - ValueList of Arbitrary - in the handler, you can generate and pass selection data in this 
//                               parameter. In this case, the Standard Processing parameter must be 
//                               set to False.
//   StandardProcessing    - Boolean - This parameter is passed to indicate that the standard (system)
//                               event processing has been performed. If you set this parameter to False in the body of the handler procedure, 
//                               the standard event processing will not be performed.
//   AdditionalParameters - Undefined, Structure of KeyAndValue - advanced setting.
//
Procedure ItemSearchByBarcodeStartOfSelection(Form, Item, ChoiceData, StandardProcessing = True, 
			AdditionalParameters = Undefined) Export
	
EndProcedure

#EndRegion

#Region CreatingApplicationObjects

// The procedure opens the item item form in the case of interactive filling.
//
// Parameters:
//  FormParameters				 - Structure		 - the parameters that need to be passed to the form element.
//  OnCloseNotifyDescription	 - CallbackDescription	 - notification when the form is closed. Handler must be passed
//                                                         option Nomenclaturally with a link to the item.
//
Procedure CreateProductsInteractively(FormParameters, OnCloseNotifyDescription) Export 
	ProcessingOfItemsClientTM.CreateProductsInteractively(FormParameters, OnCloseNotifyDescription);
EndProcedure

// This procedure opens the item form in the item type in the case of interactive filling.
//  The window opening mode must be set to Independent.
//
// Parameters:
//  FormParameters				 - Structure		 - the parameters that need to be passed to the form element.
//  OnCloseNotifyDescription	 - CallbackDescription	 - Notification of closure.
//
Procedure CreateProductViewInteractively(FormParameters, OnCloseNotifyDescription) Export
	ProcessingOfItemsClientTM.CreateProductViewInteractively(FormParameters, OnCloseNotifyDescription);
EndProcedure

#EndRegion

#Region OpeningApplicationForms

// Opening the form for the value of an additional detail.
//
// Parameters:
//  FormParameters - Structure - Keys:
//                   * AttributeRef - DefinedType.AdditionalAttributesProcessingOfItems - Link to additional banking details.
//                   * Description   - String - Name of the value of the additional default details.
//  Form          - ClientApplicationForm - the owner form.
//
Procedure OpenAdditionalValueForm(FormParameters, Form) Export
	ProcessingOfItemsClientTM.OpenAdditionalValueForm(FormParameters, Form);
EndProcedure

// Opening the form for additional details.
//
// Parameters:
//  FormParameters	 - Structure - shape parameter.
//  Owner			 - ClientApplicationForm - owner form.
//
Procedure OpenFormForAdditionalBankingDetails(FormParameters, Owner) Export
	ProcessingOfItemsClientTM.OpenFormForAdditionalBankingDetails(FormParameters, Owner);
EndProcedure

// Open the item form.
//
// Parameters:
//  ProductsLink	 - DefinedType.ItemsProcessingOfItems - link to the item.
//  Owner			 - ClientApplicationForm - owner form.
//
Procedure OpenProductsForm(ProductsLink, Owner) Export
	ProcessingOfItemsClientTM.OpenProductsForm(ProductsLink, Owner);
EndProcedure

// The opening shape of the item.
//
// Parameters:
//  ProductKindReference - DefinedType.ProductsKindProcessingOfItems - link to the item type.
//  Owner			 - ClientApplicationForm - owner form.
//
Procedure OpenProductItemForm(ProductKindReference, Owner) Export
	ProcessingOfItemsClientTM.OpenProductItemForm(ProductKindReference, Owner);
EndProcedure

// Opens the item type list form.
//
// Parameters:
//  ProductKindReference		 - DefinedType.ProductsKindProcessingOfItems - link to the item type.
//  Owner					 - ClientApplicationForm - owner form.
//  OnCloseNotifyDescription	 - CallbackDescription, Undefined	 - Notification of closure.
//
Procedure OpenListFormInProductsView(ProductKindReference, Owner, OnCloseNotifyDescription = Undefined) Export
	ProcessingOfItemsClientTM.OpenListFormInProductsView(ProductKindReference, Owner, OnCloseNotifyDescription);
EndProcedure

// Opening the nomenclature selection form.
// The expected result of closing the form is an array of links of the Definable type type.The nomenclature is worked by the nomenclature.
//
// Parameters:
//  FormParameters              - Structure                  - shape parameter.
//  Owner                    - ClientApplicationForm - owner of the form.
//  OnCloseNotifyDescription - CallbackDescription         - notification when the form is closed.
//  Var_FormWindowOpeningMode      - FormWindowOpeningMode     - options for opening the client application form.
//
Procedure OpenProductSelectionForm(FormParameters, 
	Owner = Undefined,
	OnCloseNotifyDescription = Undefined, 
	Var_FormWindowOpeningMode = Undefined) Export
	ProcessingOfItemsClientTM.OpenProductSelectionForm(FormParameters, Owner, OnCloseNotifyDescription, Var_FormWindowOpeningMode);
EndProcedure

// Opening an item selection form with characteristics.
// The expected result of closing the form is a string - address in the temporary storage,
//   or a structure with a key addressingresults - string - address in the temporary storage,
//  A table with columns Nomenclature, Characteristics should be located at the address in the temporary storage.
//  The table may contain other columns, they will be ignored during processing. 
//
// Parameters:
//  Owner                    - ClientApplicationForm - owner of the form.
//  OnCloseNotifyDescription - CallbackDescription         - notification when the form is closed.
//  Var_FormWindowOpeningMode      - FormWindowOpeningMode     - options for opening the client application form.
//
Procedure OpenFormForSelectingProductsWithCharacteristics(Owner = Undefined,
	OnCloseNotifyDescription = Undefined, 
	Var_FormWindowOpeningMode = Undefined) Export
	ProcessingOfItemsClientTM.OpenFormForSelectingProductsWithCharacteristics(Owner, OnCloseNotifyDescription, Var_FormWindowOpeningMode);
EndProcedure

// Opens the product card form associated with signing in the National Catalog.
// 
// Parameters:
//   DataToSign - Structure - data for signing:
//     * Organization                - DefinedType.Organization - Organization.
//     * Products               - DefinedType.ItemsProcessingOfItems - Nomenclature.
//     * ProductCharacteristic - DefinedType.CharacteristicProcessingOfItems - characteristic.
//     * ProductIdentifier        - Number - product ID in the National Catalog.
//     * Data                     - BinaryData - the xml string of the product card, encoded using the base64 algorithm.
//   Owner            - ClientApplicationForm - the form from which the procedure is called.
//
Procedure OpenFormBasedOnDataForSigning(DataToSign, Owner) Export
	
	OpenProductsForm(DataToSign.Products, Owner);
	
EndProcedure


#Region ObsoleteProceduresAndFunctions

// Deprecated. There is no need to use.
// Opening the nomenclature list form.
//
// Parameters:
//  ProductsLink	 - DefinedType.ItemsProcessingOfItems - link to the item.
//  Owner			 - ClientApplicationForm - owner form.
//
Procedure OpenProductListForm(ProductsLink, Owner) Export
	ProcessingOfItemsClientTM.OpenProductListForm(ProductsLink, Owner);
EndProcedure

#EndRegion

#EndRegion

#EndRegion
