////////////////////////////////////////////////////////////////////////////////
// The module "Provision in documents (Client-Server)" contains procedures and functions
// that serve the operation of the mechanism for reserving and ensuring the needs for documents on the client and on the server"
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

////////////////////////////////////////////
// Filling in security options and series.

// Constructor of the structure of the key parameters of the quantity and series request form.
//
//  Returns:
//  Structure - structure with fields:
//   * Mode - String - the mode of opening the form.
//   * SelectGoods - Boolean - indicates that the form opens from the selection of products.
//   * SelectSupplyOptions - Boolean - indicates that you need to select security options in the form.
//   * SelectSeries - Boolean - indicates that the form is open for series selection.
//   * SelectionOfWarehouses - Boolean - indicates that the form is open for selecting warehouses.
//   * HidePrice - Boolean - indicates that the price information should be hidden in the form that is being opened.
//   * EditPriceType - Boolean - indicates that the price view can be edited in the form that is being opened.
//   * EditThePrice - Boolean -  - indicates that prices can be edited in the form being opened.
//   * SeriesSelection_3 - Boolean - indicates that the form is opened exclusively for specifying series.
//   * HideManualDiscounts - Boolean - indicates that the manual discounts should be hidden in the form that is being opened.
//   * UseDiscountAdjustmentsInSales - Boolean - indicates whether discounts are being used.
//   * LimitSupplyOptions - Boolean - indicates that the security options are being passed to the form.
//   * AdditionalColumnsForSpecifyingSeries - String - a comma-separated list of additional columns.
//   * TheDisplayOfGoods - String, Undefined - "All "or " freestates".
//   * TheShipmentDateOfAllLinesIsASingleDate - Date, Undefined - the date of shipment from the document header.
//   * DateWhenTheNewLinesWereShipped - Date, Undefined - the date of shipment of the lines changed in the form.
//
Function KeyParametersOfQuantityAndSeriesRequestForm() Export
	
	FormParameters = New Structure();
	
	// Key parameters.
	FormParameters.Insert("Mode",                             Undefined);
	FormParameters.Insert("SelectGoods",                     False);
	FormParameters.Insert("SelectSupplyOptions",        False);
	FormParameters.Insert("SelectSeries",                       False);
	FormParameters.Insert("SelectionOfWarehouses",                     False);
	FormParameters.Insert("HidePrice",                        True);
	FormParameters.Insert("EditPriceType",              False);
	FormParameters.Insert("EditThePrice",                 False);
	FormParameters.Insert("SeriesSelection_3",                        False);
	FormParameters.Insert("HideManualDiscounts",              True);
	FormParameters.Insert("UseDiscountAdjustmentsInSales", False);
	FormParameters.Insert("LimitSupplyOptions",   False);
	FormParameters.Insert("AdditionalColumnsForSpecifyingSeries",        Undefined);
	
	// For tincture of the form display.
	FormParameters.Insert("TheDisplayOfGoods",           Undefined);
	
	// For the question of shipment by one date.
	FormParameters.Insert("AllLinesOfDocumentAreSelected",       False);
	FormParameters.Insert("TheShipmentDateOfAllLinesIsASingleDate", Undefined);
	FormParameters.Insert("DateWhenTheNewLinesWereShipped",          Undefined);
	
	Return FormParameters;
	
EndFunction

// Constructor of the structure of parameters for specifying series.
//
// Parameters:
//  All - Boolean - if true, all parameters will be received, otherwise not the key parameters will be received.
// 
// Returns:
//  Structure - structure with fields:
//   * Mode - String - the mode of opening the form.
//   * SelectGoods - Boolean - indicates that the form opens from the selection of products.
//   * SelectSupplyOptions - Boolean - indicates that you need to select security options in the form.
//   * SelectSeries - Boolean - indicates that the form is open for series selection.
//   * SelectionOfWarehouses - Boolean - indicates that the form is open for selecting warehouses.
//   * HidePrice - Boolean - indicates that the price information should be hidden in the form that is being opened.
//   * EditPriceType - Boolean - indicates that the price view can be edited in the form that is being opened.
//   * EditThePrice - Boolean -  - indicates that prices can be edited in the form being opened.
//   * SeriesSelection_3 - Boolean - indicates that the form is opened exclusively for specifying series.
//   * HideManualDiscounts - Boolean - indicates that the manual discounts should be hidden in the form that is being opened.
//   * UseDiscountAdjustmentsInSales - Boolean - indicates whether discounts are being used.
//   * LimitSupplyOptions - Boolean - indicates that the security options are being passed to the form.
//   * AdditionalColumnsForSpecifyingSeries - String - a comma-separated list of additional columns.
//   * TheDisplayOfGoods - String, Undefined - "All "or " freestates".
//   * TheShipmentDateOfAllLinesIsASingleDate - Date, Undefined - the date of shipment from the document header.
//   * DateWhenTheNewLinesWereShipped - Date, Undefined - the date of shipment of the lines changed in the form.
//   * ReadOnly - Boolean - True, if the form needs to be opened only for viewing.
//   * Products - CatalogRef.Products - analytics for getting the product balances displayed in the form.
//   * Characteristic - CatalogRef.ItemsCharacteristics - analytics for getting the product balances displayed in the form.
//   * Purpose - CatalogRef.Assignments - analytics for getting the product balances displayed in the form.
//   * Department - CatalogRef.BusinessStructure - analytics for getting the product balances displayed in the form.
//   * Warehouse - CatalogRef.Warehouses - analytics for getting the product balances displayed in the form.
//   * Warehouses - Array of CatalogRef.Warehouses - an array of warehouses for getting the balances, if the document specifies a group of warehouses.
//   * TableAddressSelectedEarlier - String - the address of the table containing the previously selected products, for reversing the balances.
//   * AddressAvailableBalances - String - the address of the table with the ready-made calculated Balances, used in the mode of pickups = True.
//   * ShippingOrders - Array of DefinedType.ExpectedShipment - orders specified in the document.
//   * Recorder - DefinedType.ExpectedShipment - link to the document.
//   * SecurityOptionForTheDocument - EnumRef.SupplyOptions - a security option from the current line of the document.
//   * SupplyOptionBeforeChange - EnumRef.SupplyOptions - a security option from the current line of the document before the change.
//   * SeparatelyInTheDocument - Boolean - the value of the "Detached" flag2 from the current line of the document before the change.
//   * CountByDocument - Number - the number from the current document line before the change.
//   * WarehouseByDocument - CatalogRef.Warehouses - the warehouse from the current document line before the change.
//   * QuantityRegistered - Number - The amount for which invoices and orders are issued for the current document line.
//   * Price - Number - the price of the product.
//   * PriceKind - CatalogRef.TypesOfPrices - the type of price at which you want to get the price.
//   * Package - CatalogRef.PackagesAndUnitsOfMeasure - packaging for which you need to get the price for the product.
//   * Currency - CatalogRef.Currencies - the currency for which to get the price for the product.
//   * Date - Date - the date on which to get the price for the product.
//   * PriceIncludesVAT - Boolean - if True, then you need to get prices including VAT, otherwise-without VAT.
//   * WithoutFilterByVATInclusionInPrice - Boolean - if True, then you need to search for the price without selection by including VAT.
//   * Terms - CatalogRef.TermsOfSale - the agreement on which to search for a price.
//   * AddressInTempStorage - String - the address of the data about discounts for the goods.
//   * AcceptableSeparateActions - Array of EnumRef.SupplyOptions - available stand-alone actions for wrapping in a form.
//   * AllowedNonIsolatedActions - Array of EnumRef.SupplyOptions - available non-stand-alone actions for wrapping in a form.
//   * SecurityOptionAndFlagSeparately - Structure - a structure containing a security option and a separate attribute, if the selected values of these fields are hard-coded in the form.
//   * ItIsForbiddenToSplitStrings - Boolean - if true, then the form cannot split the source string into two or more specifying the number.
//   * SeriesSpecificationParameters - See ProductsServer.SeriesSpecificationParameters
//   * Series - CatalogRef.ItemsBatches, Array of CatalogRef.ItemsBatches - a series from the current line of the document.
//   * FieldsToFillIn - String - fields to fill in when returning from the warehouse and batch selection form to the document form.
//
Function ParametersOfQuantityAndSeriesRequestForm(All = True) Export
	
	FormParameters = New Structure();
	If All Then
		FormParameters = KeyParametersOfQuantityAndSeriesRequestForm();
	EndIf;
	
	FormParameters.Insert("ReadOnly",                  False);

	// To get the leftovers.
	FormParameters.Insert("Products",                    Undefined);
	FormParameters.Insert("Characteristic",                  Undefined);
	FormParameters.Insert("Purpose",                      Undefined);
	FormParameters.Insert("Department",                   Undefined);
	FormParameters.Insert("ControlledLotReference",            Undefined);
	FormParameters.Insert("Warehouse",                           Undefined);
	FormParameters.Insert("Warehouses",                          New Array);
	FormParameters.Insert("TableAddressSelectedEarlier",      Undefined);
	FormParameters.Insert("AddressAvailableBalances",           Undefined);
	FormParameters.Insert("ShippingOrders",                New ValueList);
	FormParameters.Insert("Recorder",                     Undefined);

	// To highlight the current line of the document.
	FormParameters.Insert("SecurityOptionForTheDocument",   Undefined);
	FormParameters.Insert("SupplyOptionBeforeChange",   Undefined);
	FormParameters.Insert("SeparatelyInTheDocument",          Undefined);
	FormParameters.Insert("CountByDocument",           Undefined);
	FormParameters.Insert("WarehouseByDocument",                Undefined);
	FormParameters.Insert("QuantityRegistered",             Undefined);
	
	// to get prices.
	FormParameters.Insert("Price",                            Undefined);
	FormParameters.Insert("PriceKind",                         Undefined);
	FormParameters.Insert("Package",                        Undefined);
	FormParameters.Insert("Currency",                          Undefined);
	FormParameters.Insert("Date",                            Undefined);
	FormParameters.Insert("PriceIncludesVAT",                 Undefined);
	FormParameters.Insert("WithoutFilterByVATInclusionInPrice",    Undefined);
	FormParameters.Insert("Terms",                      Undefined);
	FormParameters.Insert("Partner",                         Undefined);
	FormParameters.Insert("UsePriceManagementSystem25",   False);
	
	// To get discounts.
	FormParameters.Insert("AddressInTempStorage",       Undefined);
	
	// To manage the list of available actions.
	FormParameters.Insert("AcceptableSeparateActions",     New ValueList);
	FormParameters.Insert("AllowedNonIsolatedActions",   New ValueList);
	FormParameters.Insert("SecurityOptionAndFlagSeparately", Undefined);
	FormParameters.Insert("WithAssignment",                        False);
	FormParameters.Insert("ItIsForbiddenToSplitStrings",           False);
	
	// To fill in the series.
	FormParameters.Insert("SeriesSpecificationParameters",          Undefined);
	FormParameters.Insert("Series",                           Undefined);
	FormParameters.Insert("DetachedSet",               False);
	
	FormParameters.Insert("FieldsToFillIn", "");
	
	Return FormParameters;
	
EndFunction

// Constructor of the structure of the key parameters of the quantity and series request form.
//
// Parameters:
//  ItemsType - EnumRef.ItemsTypes - the type of item.
//
// Returns:
//  String - the key of the structure containing data for the specified item type.
//
Function NameOfStructurePropertySoftwareOptionsByProductType(ItemsType) Export
	
	If ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods") Then
		PropertyName = "OwnGoods";
	ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		PropertyName = "Work_5";
	ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		PropertyName = "OperationService";
	ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
		PropertyName = "Tara";
	EndIf;
	
	Return PropertyName;
	
EndFunction

// Calculates the default software option for selecting products based on the incoming parameters.
//
// Parameters:
//  ItemsType - EnumRef.ItemsTypes - the type of item.
//  AcceptableSeparateActions - Array of EnumRef.SupplyOptions - separate security options allowed for selection.
//  AllowedNonIsolatedActions - Array of EnumRef.SupplyOptions - non-isolated security options are acceptable for selection.
//  LimitSupplyOptions - Boolean - indicates whether the security option should be restricted to the form that is being opened.
//  SecurityOptionAndFlagSeparately - Structure - structure with fields:
//   * SupplyOption - EnumRef.SupplyOptions - the value of the security option.
//   * WithAssignment - Boolean - the value of the "Isolated"attribute.
//  ParameterIsSeparate - Boolean - the value of the "Isolated"attribute.
//
// Returns:
//  Structure - structure with fields:
//   * SupplyOption - EnumRef.SupplyOptions - the value of the security option.
//   * WithAssignment - Boolean - the value of the "Isolated"attribute.
//
Function DefaultOptionAndFlagForMatching(
	ItemsType,
	AcceptableSeparateActions,
	AllowedNonIsolatedActions,
	LimitSupplyOptions,
	Val SecurityOptionAndFlagSeparately,
	ParameterIsSeparate) Export
	
	If SecurityOptionAndFlagSeparately = Undefined Then
		SecurityOptionAndFlagSeparately = ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault(
			ParameterIsSeparate);
	EndIf;
	
	Result = New Structure("WithAssignment,SupplyOption",
		False, PredefinedValue("Enum.SupplyOptions.EmptyRef"));
	
	AcceptableSecurityOptions = AcceptableSecurityOptions(
		ItemsType,
		AcceptableSeparateActions,
		AllowedNonIsolatedActions,
		LimitSupplyOptions,
		SecurityOptionAndFlagSeparately);
	PropertyName = NameOfStructurePropertySoftwareOptionsByProductType(ItemsType);
	
	WithAssignment = SecurityOptionAndFlagSeparately[PropertyName].WithAssignment;
	SupplyOption = SecurityOptionAndFlagSeparately[PropertyName].SupplyOption;
	
	If WithAssignment = Undefined Then
		
		OptionAndFlagAreTemporary = ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault(
			ParameterIsSeparate);
		WithAssignment = OptionAndFlagAreTemporary[PropertyName].WithAssignment;
		If PropertyName = "Work_5" Then
			If WithAssignment And SupplyOption = PredefinedValue("Enum.SupplyOptions.NotRequired") Then
				SupplyOption = PredefinedValue("Enum.SupplyOptions.ToSupply")
			ElsIf Not WithAssignment And SupplyOption = PredefinedValue("Enum.SupplyOptions.ToSupply") Then
				SupplyOption = PredefinedValue("Enum.SupplyOptions.NotRequired");
			EndIf;
		EndIf;
		
	EndIf;
	
	If WithAssignment And AcceptableSecurityOptions.Separate_.Find(SupplyOption) <> Undefined 
			Or Not WithAssignment And AcceptableSecurityOptions.NonIsolated.Find(SupplyOption) <> Undefined Then
			
			Result.WithAssignment = WithAssignment;
			Result.SupplyOption = SecurityOptionAndFlagSeparately[PropertyName].SupplyOption;
		
	ElsIf WithAssignment And AcceptableSecurityOptions.NonIsolated.Find(SupplyOption) <> Undefined
				Or Not WithAssignment And AcceptableSecurityOptions.Separate_.Find(SupplyOption) <> Undefined Then
			
			Result.WithAssignment = Not WithAssignment;
			Result.SupplyOption = SupplyOption;
			
	Else
		
		If WithAssignment And AcceptableSecurityOptions.Separate_.Count() > 0
				Or Not WithAssignment And AcceptableSecurityOptions.NonIsolated.Count() = 0 Then
				
				Result.WithAssignment = True;
				Result.SupplyOption = AcceptableSecurityOptions.Separate_[0];
				
		Else
			
			Result.WithAssignment = False;
			Result.SupplyOption = AcceptableSecurityOptions.NonIsolated[0];
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Calculates the default software option for selecting products based on the incoming parameters.
//
// Parameters:
//  ItemsType - EnumRef.ItemsTypes - the type of item.
//  AcceptableSeparateActions - Array of EnumRef.SupplyOptions - separate security options allowed for selection.
//  AllowedNonIsolatedActions - Array of EnumRef.SupplyOptions - non-isolated security options are acceptable for selection.
//  LimitSupplyOptions - Boolean - indicates whether the security option should be restricted to the form that is being opened.
//  SecurityOptionAndFlagSeparately - Structure - structure with fields:
//   * SupplyOption - EnumRef.SupplyOptions - the value of the security option.
//   * WithAssignment - Boolean - the value of the "Isolated"attribute.
//
// Returns:
//  Structure - structure with fields:
//   * SupplyOption - EnumRef.SupplyOptions - the value of the security option.
//   * WithAssignment - Boolean - the value of the "Isolated"attribute.
//
Function AcceptableSecurityOptions(ItemsType, AcceptableSeparateActions, AllowedNonIsolatedActions, LimitSupplyOptions, SecurityOptionAndFlagSeparately) Export
	
	Separate_ = New Array();
	NonIsolated = New Array(); 
	If LimitSupplyOptions Then
		
		PropertyName = NameOfStructurePropertySoftwareOptionsByProductType(ItemsType);
		
		If SecurityOptionAndFlagSeparately[PropertyName].WithAssignment = Undefined Then
			
			Separate_.Add(SecurityOptionAndFlagSeparately[PropertyName].SupplyOption);
			NonIsolated.Add(SecurityOptionAndFlagSeparately[PropertyName].SupplyOption);
			
		ElsIf SecurityOptionAndFlagSeparately[PropertyName].WithAssignment Then
			
			Separate_.Add(SecurityOptionAndFlagSeparately[PropertyName].SupplyOption);
			
		Else
			
			NonIsolated.Add(SecurityOptionAndFlagSeparately[PropertyName].SupplyOption);
			
		EndIf;
		
	Else
		
		If ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods") Then
			
			Separate_.Add(PredefinedValue("Enum.SupplyOptions.NotRequired"));
			Separate_.Add(PredefinedValue("Enum.SupplyOptions.ToSupply"));
			Separate_.Add(PredefinedValue("Enum.SupplyOptions.ReserveAsReceived"));
			Separate_.Add(PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
			Separate_.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
			
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.NotRequired"));
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.ToSupply"));
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.ReserveAsReceived"));
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
			
		ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
			
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.NotRequired"));
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.ToSupply"));
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.ReserveAsReceived"));
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
			
		ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
			
			Separate_.Add(PredefinedValue("Enum.SupplyOptions.ToSupply"));
			Separate_.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
			
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.NotRequired"));
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
			
		ElsIf ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
			
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.NotRequired"));
			NonIsolated.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
			
		EndIf;
		
		TotalItems = Separate_.Count();
		For Counter = 1 To TotalItems Do
			
			If AcceptableSeparateActions.FindByValue(Separate_[TotalItems - Counter]) = Undefined Then
				Separate_.Delete(TotalItems - Counter);
			EndIf;
			
		EndDo;
		
		TotalItems = NonIsolated.Count();
		For Counter = 1 To TotalItems Do
			
			If AllowedNonIsolatedActions.FindByValue(NonIsolated[TotalItems - Counter]) = Undefined Then
				NonIsolated.Delete(TotalItems - Counter);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Result = New Structure("Separate_,NonIsolated", Separate_,NonIsolated);
	Return Result;
	
EndFunction

// Returns a list of values containing all available software options.
//
// Returns:
//  - ValueList - a list of all security options.
//
Function AllActions() Export
	
	AllActions = New ValueList();
	AllActions.Add(PredefinedValue("Enum.SupplyOptions.NotRequired"));
	AllActions.Add(PredefinedValue("Enum.SupplyOptions.ToSupply"));
	AllActions.Add(PredefinedValue("Enum.SupplyOptions.ReserveAsReceived"));
	AllActions.Add(PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
	AllActions.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
	Return AllActions;
	
EndFunction

// Returns a list of actions available for selection in the default order line.
// Returns:
//  Array - Array of actions.
Function AvailableActionsForSelectingCollateralInDefaultRow() Export
	
	AllActions = New Array();
	AllActions.Add(PredefinedValue("Enum.SupplyOptions.NotRequired"));
	AllActions.Add(PredefinedValue("Enum.SupplyOptions.ReserveAsReceived"));
	AllActions.Add(PredefinedValue("Enum.SupplyOptions.ToSupply"));
	AllActions.Add(PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
	AllActions.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
	Return AllActions;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Service forms of documents

// Adding an action to the action structure to fill in the details of the table part and the form header,
// as well as the service details of the table part and the form required for conditional registration.
// Action for filling in the service details of the form:
//  - Form.Dataload required
//  - Form.Warehouse required
//  - Stringcollections.Dataload required
//  - Stringcollections.Warehouse required
// Event for processing table parts:
//  "When changing the nomenclature or support options"
// Event for processing table parts:
//  "Fill in the column is not available"
// Action for filling in the table part details:
//  Collection string.Available
//  Stringcollections.Redistribute reserves
// Action to fill in the table part details:
//  Collection string.Support options
//  Stringcollections.Download dataload
// Event for processing table parts:
//  "checkfillingsupplyingdocumentsand"
// Action for filling in the table part details:
//  Collection string.Support options
// Event for processing table parts, only on the server:
//  "Increase the document's datatload".
// 
// Parameters:
//  StructureOfActions - Structure - the structure to which the action is added.
//  StringFields_ - String - "Supply options" and/or "dataload", "Warehouse required", "dataload required"," dataload deferred " separated by commas.
//  DocumentParameters - Structure - Form data:
//   * ShipmentDateInLine                - Date, Undefined   - The date of shipment from the document line.
//   * FieldNameShipmentDate                - String               - The name of the "Shipment Date" field in the document header.
//   * SecurityOptionAndFlagSeparately - See ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault
//   * Object                             - FormDataStructure - the form object associated with the shipment order,
//                                                                 including the "Link" field for determining the type of the shipment order.
//
Procedure AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters) Export
	
	CallingFromObject = Not DocumentParameters.Property("Form");
	
	Form = ?(CallingFromObject,
		New Structure("Object",
		DocumentParameters.Object), DocumentParameters.Form);
	EmbeddingParameters = ?(CallingFromObject,
		DocumentParameters.EmbeddingParameters,
		DocumentParameters.Form.AvailableRemainingEmbeddingOptions);
	
	Fields = New Structure(StringFields_);
	
	If Fields.Property("SupplyOption") Then
		
		ActionParameters = New Structure();
		
		ActionParameters.Insert("SecurityOptionAndFlagSeparately", DocumentParameters.SecurityOptionAndFlagSeparately);
		ActionParameters.Insert("Form",                              Form);
		ActionParameters.Insert("EmbeddingParameters",               EmbeddingParameters);
		ActionParameters.Insert("CallingFromObject",                     CallingFromObject);
		
		StructureOfActions.Insert("CheckSoftwareInSalesDocument", ActionParameters);
		
	EndIf;
	
	If Fields.Property("AvailableInOtherLines") Then
		
		ActionParameters = New Structure();
		
		ActionParameters.Insert("Form",                Form);
		ActionParameters.Insert("EmbeddingParameters", EmbeddingParameters);
		ActionParameters.Insert("CallingFromObject",       False);
		
		StructureOfActions.Insert("FillInAvailableColumn", ActionParameters);
		
		Address = EmbeddingParameters.InternalParameters.AddressProductRange;
		CurLineCache_ = Form.CachedLines[EmbeddingParameters.FormTableName];
		
		ActionParameters = New Structure();
		
		ActionParameters.Insert("AddressProductRange",                               Address);
		ActionParameters.Insert("UpdateColumnAvailable",                         False);
		ActionParameters.Insert("CurLineCache_",                                CurLineCache_);
		StructureOfActions.Insert("CheckNeedToUpdateColumnIsAvailable", ActionParameters);
		
	EndIf;
	
	If Fields.Property("Available") Then
		
		ActionParameters = New Structure();
		
		ActionParameters.Insert("Form",                Form);
		ActionParameters.Insert("EmbeddingParameters", EmbeddingParameters);
		ActionParameters.Insert("CallingFromObject",       False);
		
		StructureOfActions.Insert("FillInAvailableColumn", ActionParameters);
		
	EndIf;
	
	If Fields.Property("UpdateProductCache_") Then
		
		ActionParameters = New Structure();
		
		Address = EmbeddingParameters.InternalParameters.AddressProductRange;
		ActionParameters = New Structure("AddressProductRange", Address, False);
		StructureOfActions.Insert("UpdateProductCache_", ActionParameters);
		
	EndIf;
	
	If Fields.Property("WarehouseIsRequired") Or Fields.Property("DateOfShipmentRequired_") Then
		
		ActionParameters = New Structure();
		
		ActionParameters.Insert("Form",                Form);
		ActionParameters.Insert("EmbeddingParameters", EmbeddingParameters);
		ActionParameters.Insert("CallingFromObject",       False);
		
		StructureOfActions.Insert("WhenChangingTypeOfProductOrSoftwareOption", ActionParameters);
		
	EndIf;
	
EndProcedure

// Removes software-related actions from the action structure.
//
// Parameters:
//  StructureOfActions - Structure - Structure of actions.
//
Procedure RemoveCollateralActions(StructureOfActions) Export
	
	StructureOfActions.Delete("CheckSoftwareInSalesDocument");
	StructureOfActions.Delete("FillInAvailableColumn");
	StructureOfActions.Delete("CheckNeedToUpdateColumnIsAvailable");
	StructureOfActions.Delete("UpdateProductCache_");
	StructureOfActions.Delete("WhenChangingTypeOfProductOrSoftwareOption");
	
EndProcedure

// Fills in the service details of the security in the header of the form, based on changes in the service details of the table part.
// Must be used in conjunction with Add Support actions on the client after processing the table part row.
// 
// Parameters:
//  Collection - FormDataCollection - the tabular part in which the service details were changed.
//  DateOfShipmentRequired_ - Boolean - the eponymous form prop that needs to be updated.
//  WarehouseIsRequired - Boolean - the eponymous form prop that needs to be updated.
//
Procedure FillInServiceDetails(Collection, DateOfShipmentRequired_, WarehouseIsRequired) Export
	
	DateOfShipmentRequired_  = ?(Collection.Total("DateOfShipmentRequired_") = 0, 0, 1);
	WarehouseIsRequired          = ?(Collection.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndProcedure

// Returns default provisioning options for each item type, depending on the provisioning strategy.
// The structure of the collateral options should be initialized in the documents only if it is necessary to completely override the rules used
// when filling in the default collateral option. If the security option for each item type is known and hard-coded.
// 
// Parameters:
//  FillInSeparately_ - Boolean - indicates that a separate security strategy is being used.
//
// Returns:
//  Structure - structure with properties:
//   * OwnGoods - Structure - structure with keys:
//      ** SupplyOption - EnumRef.SupplyOptions - default security option.
//      ** WithAssignment - Boolean - the flag value is Isolated by default.
//   * ReusablePackage - Structure - structure with keys:
//      ** SupplyOption - EnumRef.SupplyOptions - default security option.
//      ** WithAssignment - Boolean - the flag value is Isolated by default.
//   * Work_5 - Structure - structure with keys:
//      ** SupplyOption - EnumRef.SupplyOptions - default security option.
//      ** WithAssignment - Boolean - the flag value is Isolated by default.
//   * OperationService - Structure - structure with keys:
//      ** SupplyOption - EnumRef.SupplyOptions - default security option.
//      ** WithAssignment - Boolean - the flag value is Isolated by default.
//
Function ProvisionOptionAndFlagAreSeparateByDefault(FillInSeparately_) Export
	
	ToSupply   = PredefinedValue("Enum.SupplyOptions.ToSupply");
	NotProvide = PredefinedValue("Enum.SupplyOptions.NotRequired");
	
	Result = New Structure();
	Result.Insert("OwnGoods",  New Structure("SupplyOption,WithAssignment", ToSupply,   False));
	Result.Insert("Tara",   New Structure("SupplyOption,WithAssignment", ToSupply,   False));
	Result.Insert("Work_5", New Structure("SupplyOption,WithAssignment", NotProvide, False));
	Result.Insert("OperationService", New Structure("SupplyOption,WithAssignment", NotProvide, False));
	
	If FillInSeparately_ Then
		
		Result.OwnGoods.WithAssignment         = True;
		Result.Work_5.WithAssignment        = True;
		Result.Work_5.SupplyOption = ToSupply;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the symbol of the warehouse collection mode.
//
// Returns:
//  String - the line "Selection".
//
Function SeriesSelectionMode() Export
	Return "SelectSeries";
EndFunction

// Returns the symbol of the warehouse collection mode.
//
// Returns:
//  String - the "Action selection" line.
//
Function ActionSelectionMode() Export
	Return "ActionChoice";
EndFunction

// Returns the security status mode symbol.
//
// Returns:
//  String - the "Support status" line.
//
Function SoftwareStateMode() Export
	Return "SecurityStates";
EndFunction

// Returns the symbol of the action fill mode from the list.
//
// Returns:
//  String - the line "Filling in the action of the list".
//
Function FillActionFromListMode() Export
	Return "CompletingActionFromList";
EndFunction

// Returns the action selection mode symbol in the line itself.
//
// Returns:
//  String - the line "Select actions indirectly".
//
Function ModeSelectActionDirectly() Export
	Return "SelectingActionDirectly";
EndFunction

// Returns the symbol of the warehouse collection mode.
//
// Returns:
//  String - the line "PodborSkladov".
//
Function WarehouseSelectionMode() Export
	Return "SelectionOfWarehouses";
EndFunction

// Returns the symbol of the warehouse collection mode.
//
// Returns:
//  Undefined - The value is Undefined.
//
Function ViewAvailabilityMode() Export
	Return Undefined;
EndFunction

// Determines whether to check or fill in the shipment date after changing the security option in the document lines.
//
// Parameters:
//  Mode - String - execution mode of action.
//
// Returns:
//  Boolean - True if you need to check or fill in the shipment date.
//
Function YouNeedToCheckFillInShipmentDateForShipLines(Mode) Export
	
	Return ThisIsSoftwareChangeMode(Mode);
	
EndFunction

// Defines the mode of changing the security option
//
// Parameters:
//  Mode - String - execution mode of action.
//
// Returns:
//  Boolean - True if the security option changes.
//
Function ThisIsSoftwareChangeMode(Mode) Export
	
	Return Mode = Undefined
		Or Mode = ActionSelectionMode()
		Or Mode = SoftwareStateMode()
		Or Mode = ModeSelectActionDirectly()
		Or Mode = FillActionFromListMode();
	
EndFunction

// Returns a structure containing fields involved in batch processing of rows of table parts.
// 
// Returns:
//  Structure - Field Structure Check If Column Updates Are Available:
// * Products - CatalogRef.Products, Undefined - nomenclature,
// * Characteristic - CatalogRef.ItemsCharacteristics, Undefined - Characteristics,
// * SupplyOption - EnumRef.SupplyOptions, Undefined - the version of the software.
//
Function FieldStructureCheckIfColumnUpdatesAreAvailable() Export
	
	FieldsStructure = New Structure();
	FieldsStructure.Insert("Products", Undefined);
	FieldsStructure.Insert("Characteristic", Undefined);
	FieldsStructure.Insert("SupplyOption", Undefined);
	Return FieldsStructure;
	
EndFunction

// The structure of the parameters of the calculation of the supply cycle.
// Returns:
//  Structure - structure with fields:
//   * OrderFulfillmentPeriod - See Catalog.ProcurementStrategies.OrderFulfillmentPeriod
//   * GenerateOrdersByReorderPoint - See Catalog.ProcurementStrategies.GenerateOrdersByReorderPoint
//   * GenerateOrdersOnSchedule - See Catalog.ProcurementStrategies.GenerateOrdersOnSchedule
//   * DeliverySchedule - See Catalog.ProcurementStrategies.DeliverySchedule
//   * FirstDateInDeliverySchedule - See Catalog.ProcurementStrategies.FirstDateInDeliverySchedule
//   * DeliveryScheduleFrequency - See Catalog.ProcurementStrategies.DeliveryScheduleFrequency
//   * NumberOfPeriodsBetweenDeliveries - See Catalog.ProcurementStrategies.NumberOfPeriodsBetweenDeliveries
//   * CoveredPeriodOption - See Catalog.ProcurementStrategies.CoveredPeriodOption
//   * CoveredPeriod - See Catalog.ProcurementStrategies.CoveredPeriod
Function SupplyCycleCalculationParameters() Export
	
	Result = New Structure(
		"OrderFulfillmentPeriod,
		|GenerateOrdersByReorderPoint,
		|GenerateOrdersOnSchedule,
		|DeliverySchedule,
		|FirstDateInDeliverySchedule,
		|DeliveryScheduleFrequency,
		|NumberOfPeriodsBetweenDeliveries,
		|CoveredPeriodOption,
		|CoveredPeriod");
	Return Result;
	
EndFunction
#EndRegion

#Region Internal

// The data structure of the software option selection.
// Returns:
//  Structure - structure with fields:
//   * SupplyOption - EnumRef.SupplyOptions,Undefined -
//   * OpenWarehouseAndSeriesSelectionForm - Boolean
//   * SplitRow - Boolean -
//   * OpenLineSplittingForm - Boolean -
//   * AvailableQuantityWhenSplittingLine - Number -
//   * AcceptableDeviationOnChoiceSupplyOption - Number -
//   * TotalNumberWhenSplittingLine - Number -
//   * Available - Number -
Function ValueOfChoosingSecurityOption() Export
	
	Result = New Structure();
	Result.Insert("SupplyOption", Undefined);
	Result.Insert("OpenWarehouseAndSeriesSelectionForm", False);
	Result.Insert("SplitRow", False);
	Result.Insert("OpenLineSplittingForm", False);
	Result.Insert("AvailableQuantityWhenSplittingLine", 0);
	Result.Insert("AcceptableDeviationOnChoiceSupplyOption", 0);
	Result.Insert("TotalNumberWhenSplittingLine", 0);
	Result.Insert("Available", 0);
	
	Return Result;
	
EndFunction

Function CollectionOnForm(Form, EmbeddingParameters) Export
	
	If EmbeddingParameters.TableName = Undefined Then
		Return Undefined;
	EndIf;
	
	CollectionOnForm = Undefined;
	DataPaths = StrSplit(EmbeddingParameters.TableName, ".");
	If EmbeddingParameters.InternalParameters.IsDocument Then
		CollectionOnForm = Form.Object[DataPaths[2]];
	Else
		CollectionOnForm = Form;
		For Counter = 1 To DataPaths.UBound() Do
			CollectionOnForm = CollectionOnForm[DataPaths[Counter]];
		EndDo;
	EndIf;
	Return CollectionOnForm;
	
EndFunction

Function ProgramObjectData(ActionParameters, TabSectionRow) Export
	
	Form                = ActionParameters.Form;
	EmbeddingParameters = ActionParameters.EmbeddingParameters;
	
	RowData = EmbeddingParameters.InternalParameters.RowData;
	SerializationPattern = EmbeddingParameters.FormDataSerializationPattern;
	NamesArray = StrSplit(EmbeddingParameters.TableName, ".");
	TSName = NamesArray[NamesArray.UBound()];
	
	SerializeFormData(
		RowData,
		Form,
		SerializationPattern,
		EmbeddingParameters.RelationshipFieldsOfTableParts,
		TabSectionRow,
		TSName,
		"");
	
	Return RowData;
	
EndFunction

Function BatchProcessingStructureOfFieldsOfCurrentLine(ActionParameters) Export
	
	StructureOfTable = Undefined;
	
	EmbeddingParameters = ActionParameters.EmbeddingParameters;
	SerializationPattern = EmbeddingParameters.FormDataSerializationPattern;
	NameParts = StrSplit(EmbeddingParameters.TableName, ".");
	TableName = NameParts[NameParts.Count() - 1];
	
	If EmbeddingParameters.TableName = Undefined Then
		StructureOfTable = SerializationPattern.Object;
	ElsIf Not SerializationPattern.Property(TableName, StructureOfTable) Then
		
		For Each KeyAndValue In SerializationPattern Do
			
			If TypeOf(KeyAndValue.Value) = Type("Structure") Then
				
				If KeyAndValue.Value.Property(TableName, StructureOfTable) Then
					Break;
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return StructureOfTable;
	
EndFunction

Function WithAssignmentOnChange(WithAssignment, SupplyOption, ItemsType) Export
	
	NewSoftwareOption = SupplyOption;
	
	If ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		
		If WithAssignment And SupplyOption = PredefinedValue("Enum.SupplyOptions.NotRequired") Then
			
			NewSoftwareOption = PredefinedValue("Enum.SupplyOptions.ToSupply");
			
		ElsIf Not WithAssignment And SupplyOption = PredefinedValue("Enum.SupplyOptions.ToSupply") Then
			
			NewSoftwareOption = PredefinedValue("Enum.SupplyOptions.NotRequired");
			
		EndIf;
		
	EndIf;
	
	Return NewSoftwareOption;
	
EndFunction

#EndRegion

#Region Private

Procedure SerializeFormData(RowData, DataObject, SerializationPattern, LinkFields, TabSectionRow, TSName, PropertyName)
	
	QuickSearch = New Map();
	If TSName = PropertyName Then
		
		FillingData = TabSectionRow;
		
	ElsIf TypeOf(DataObject) <> Type("FormDataCollection") Then
		
		FillingData = DataObject;
		
	Else
		
		MapItem = QuickSearch;
		If TabSectionRow <> Undefined Then
			
			Filter = New Structure;
			
			For Each KeyAndValue In LinkFields[PropertyName] Do
				Filter.Insert(KeyAndValue.Key, KeyAndValue.Value);
			EndDo;
			
			For Each Property In LinkFields[PropertyName] Do
				Filter[Property.Key] = TabSectionRow[Property.Value];
				
				CurItem = MapItem.Get(Filter[Property.Key]);
				If CurItem = Undefined Then
					MapItem.Insert(Filter[Property.Key], New Map());
					CurItem = MapItem.Get(Filter[Property.Key]);
				EndIf;
				MapItem = CurItem;
				
			EndDo;
		EndIf;
		
		FillingData = MapItem.Get("Value");
		If TabSectionRow <> Undefined Then
			If FillingData = Undefined Then
				FoundRows = DataObject.FindRows(Filter);
				FillingData = ?(FoundRows.Count() > 0, FoundRows[0], Undefined);
				MapItem.Insert("Value", FillingData);
			EndIf;
		EndIf;
		
	EndIf;
	
	For Each Property In SerializationPattern Do
		
		If TypeOf(Property.Value) = Type("Structure") Then
			
			SerializeFormData(
				RowData[Property.Key],
				DataObject[Property.Key],
				Property.Value,
				LinkFields,
				TabSectionRow,
				TSName,
				Property.Key);
				
		ElsIf FillingData <> Undefined Then
			RowData[Property.Key] = FillingData[Property.Key];
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion
