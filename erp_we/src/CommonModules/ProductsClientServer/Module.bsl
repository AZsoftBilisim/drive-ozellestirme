#Region Public

// Returns a string representation of the item with the characteristic and other fields to display in messages.
//
// Parameters:
//  Products	 - String, CatalogRef.Products			 - nomenclature;
//  Characteristic	 - String, CatalogRef.ItemsCharacteristics	 - a characteristic of an item;
//  Package		 - String, CatalogRef.PackagesAndUnitsOfMeasure	 - packaging / item unit of measurement;
//  Series			 - String, CatalogRef.ItemsBatches			 - item series;
//  Purpose		 - String, CatalogRef.Assignments					 - the purpose of the nomenclature.
// 
// Returns:
//  String - presentation of the nomenclature.
//
Function ProductPresentation(Products, Characteristic, Package = "", Series = "", Purpose = "") Export

	Page1Presentation = TrimAll(Products);

	If ValueIsFilled(Characteristic)Then
		Page1Presentation = Page1Presentation + " / " + TrimAll(Characteristic);
	EndIf;
	
	If ValueIsFilled(Purpose) Then
		Page1Presentation = Page1Presentation + " / " + TrimAll(Purpose);
	EndIf;
	
	If ValueIsFilled(Series) Then
		Page1Presentation = Page1Presentation + " / " + TrimAll(Series);
	EndIf;

	Return Page1Presentation;

EndFunction

// Calculates the performance of the series. The calculation can be made using the template for the working name of the series
// . in this case, the function must be called from the server. If the template is not specified or the function is called from the client, the calculation is performed
// using a predefined template.
//
// Parameters:
//	TemplateParameters	 - See Catalogs.ItemKinds.SeriesUseSettings.
//	AttributesValues	 - Structure, ClientApplicationForm, CatalogObject.ItemsBatches, FormDataCollectionItem - 
//							a collection of data structures that stores the values of properties used as 
//							a data source to form a representation of an item in the directory 'Series of Nomenclature'.
//	AddWordNew	 - Boolean - indicates whether a predefined suffix must be added to the view 
//									of the 'item Series' reference element.
//
// Returns:
//	String - representation of the reference book element 'Series of nomenclature'.
//
Function PresentationOfSeriesWithoutCalculationByNameTemplate(TemplateParameters, AttributesValues, AddWordNew = False) Export
	
	Presentation = "";
	
	PresentationParts = New Array;
	
	If AddWordNew Then
		PresentationParts.Add(NStr("vi = '<Mới>';
									|ru = '<Новая>';
									|en = '<New>'; fa = '<New>';
									|it = '<Nuova>';
									|pl = '<New>';
									|tr = '<Yeni>'"));
	EndIf;
	
	For Each LongDesc In TemplateParameters.DescriptionsOfUseOfSeriesProps Do
		If LongDesc.Use
			And Not IsBlankString(LongDesc.NameTemplateText) Then 
			
			PartOfTheView = LongDesc.NameTemplateText;
			If Not IsBlankString(LongDesc.Format) Then
				StringPropsValue = Format(AttributesValues[LongDesc.AttributeName], LongDesc.Format);
			Else
				StringPropsValue = String(AttributesValues[LongDesc.AttributeName]);
			EndIf;
			
			PartOfTheView = StrReplace(PartOfTheView, "%" + LongDesc.AttributeName + "%", StringPropsValue);
			PresentationParts.Add(PartOfTheView);
		EndIf;
	EndDo;
	
	Presentation = StrConcat(PresentationParts, " ");
	
	Return Presentation;
	
EndFunction

// Additional parameters of the Nomenclatureclientserver function.Representationof the nomenclature for printing.
// 
// Returns:
//  Structure - with properties:
//  * Content - String - if non-empty content is passed, it will be the view, and other parameters are ignored
//  * ReturnContainers - Boolean - if TRUE, the phrase "returnable container" will be added to the view in parentheses.
//  * FEACNCode - String - if specified, the HS code will be added to the view in parentheses.
//  * Prefix - String - if specified, a prefix will be added to the view before the item name.
//  * DefaultLanguageCode - String - specified to Refine the main language code when displaying localized strings.
//
Function AdditionalParametersPresentationOfProductsForPrinting() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Content", "");
	AdditionalParameters.Insert("ReturnContainers", False);
	AdditionalParameters.Insert("FEACNCode", "");
	AdditionalParameters.Insert("Prefix", "");
	AdditionalParameters.Insert("DefaultLanguageCode", "");
	Return AdditionalParameters; 
	
EndFunction

// Returns a representation of the item for printing.
//
// Parameters:
//  ProductNameForPrinting	 - String		 - you must strictly pass the string with the name to print. The link will not work, because when
//  		you get a string representation from it, the platform will take the name, not the name for printing;
//  CharacteristicNameForPrinting	 - String		 - you must strictly pass the string with the name to print. The link will not work, because when
//  		you get a string representation from it, the platform will take the name, not the name for printing;
//  Package							 - String, Undefined	- package or unit of measurement;
//  Series								 - String, CatalogRef.ItemsBatches	 - item series;
//  AdditionalParameters				 - See ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting.
// 
// Returns:
//  String - presentation of the nomenclature for printing.
//
Function PresentationOfProductsForPrinting(ProductNameForPrinting,
	                                       CharacteristicNameForPrinting,
	                                       Package = Undefined,
	                                       Series = Undefined,
	                                       AdditionalParameters = Undefined) Export
										   
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalParametersPresentationOfProductsForPrinting();
	EndIf;
	
	If TypeOf(ProductNameForPrinting) <> Type("String") Then
		ExceptionText = NStr("vi = 'Trong hàm %1 chưa chuyển tên gọi mặt hàng để in.';
							|ru = 'В функцию %1 не передано наименование номенклатуры для печати.';
							|en = 'Item name for printing is not passed to the %1 function.'; fa = 'Item name for printing is not passed to the %1 function.';
							|it = 'Nella funzione %1 non è data la denominazione della nomenclatura per la stampa.';
							|pl = 'Do funkcji %1 nie przekazano nazwy pozycji dla drukowania.';
							|tr = 'Yazdırma için öğe tanımı %1 işlevine transfer edilmedi.'");	
		ExceptionText = StrTemplate(ExceptionText, "ProductsClientServer.PresentationOfProductsForPrinting");
		
		Raise ExceptionText;	
	EndIf;
	
	If ValueIsFilled(CharacteristicNameForPrinting) 
		And TypeOf(CharacteristicNameForPrinting) <> Type("String") Then
		ExceptionText = NStr("vi = 'Trong hàm %1 chưa điền tên gọi đặc tính để in.';
							|ru = 'В функцию %1 не передано наименование характеристики для печати.';
							|en = 'Item variant name for printing is not passed to the %1 function.'; fa = 'Item variant name for printing is not passed to the %1 function.';
							|it = 'Nella funzione %1 non è data la denominazione della caratteristica per la stampa.';
							|pl = 'Do funkcji %1 nie przekazano nazwy charakterystyki dla drukowania.';
							|tr = 'Yazdırma için varyant tanımı %1 işlevine transfer edilmedi.'");	
		ExceptionText = StrTemplate(ExceptionText, "ProductsClientServer.PresentationOfProductsForPrinting");
		
		Raise ExceptionText;	
	EndIf;
	
	If ValueIsFilled(AdditionalParameters.Content) Then
		
		ProductPresentation = TrimAll(AdditionalParameters.Content);
		
	Else
		TextInBrackets = New Array;
		
		If ValueIsFilled(CharacteristicNameForPrinting) Then
			TextInBrackets.Add(TrimAll(CharacteristicNameForPrinting));
		EndIf;
		
		If ValueIsFilled(Package) Then
			TextInBrackets.Add(TrimAll(Package));
		EndIf;
		
		If ValueIsFilled(Series) Then
			TextInBrackets.Add(TrimAll(Series));
		EndIf;
		
		If AdditionalParameters.ReturnContainers Then
			TextInBrackets.Add(NStr("vi = 'bao bì trả lại';
									|ru = 'возвратная тара';
									|en = 'returnable packaging'; fa = 'returnable packaging';
									|it = 'imballo restituibile';
									|pl = 'tara zwrotna';
									|tr = 'iade edilebilir ambalaj'", AdditionalParameters.DefaultLanguageCode));
		EndIf;
		
		If ValueIsFilled(AdditionalParameters.FEACNCode) Then
			TextInBrackets.Add(NStr("vi = 'Mã hàng hóa xuất nhập khẩu:';
									|ru = 'Код ТН ВЭД:';
									|en = 'FEACN code:'; fa = 'کد FEACN:';
									|it = 'Codice di Articolo delle merci del commercio estero:';
									|pl = 'Kod NTZDG:';
									|tr = 'GTİP kodu:'", AdditionalParameters.DefaultLanguageCode)+ Chars.NBSp + AdditionalParameters.FEACNCode);
		EndIf;
		
		TextInParenthesesString = StrConcat(TextInBrackets, ", ");
		
		If ValueIsFilled(TextInParenthesesString) Then
			ProductPresentation = NStr("vi = '%ProductNameForPrinting% (%TextInBrackets%)';
										|ru = '%ProductNameForPrinting% (%TextInBrackets%)';
										|en = '%ProductNameForPrinting% (%TextInBrackets%)'; fa = '%ProductNameForPrinting% (%TextInBrackets%)';
										|it = '%ProductNameForPrinting% (%TextInBrackets%)';
										|pl = '%ProductNameForPrinting% (%TextInBrackets%)';
										|tr = '%ProductNameForPrinting% (%TextInBrackets%)'", AdditionalParameters.DefaultLanguageCode);
			ProductPresentation = StrReplace(ProductPresentation, "%TextInBrackets%", TrimAll(TextInParenthesesString));
		Else
			ProductPresentation = NStr("vi = '%ProductNameForPrinting%';
										|ru = '%ProductNameForPrinting%';
										|en = '%ProductNameForPrinting%'; fa = '%ProductNameForPrinting%';
										|it = '%ProductNameForPrinting%';
										|pl = '%ProductNameForPrinting%';
										|tr = '%ProductNameForPrinting%'");
		EndIf;
		
		ProductPresentation = StrReplace(ProductPresentation, "%ProductNameForPrinting%", TrimAll(ProductNameForPrinting));
		If ValueIsFilled(AdditionalParameters.Prefix) Then
			ProductPresentation = AdditionalParameters.Prefix + " " + ProductPresentation;
		EndIf;
	EndIf;
	
	Return ProductPresentation;
	
EndFunction

// Generates an array of selections by item and multi-turn Item types
//
// Parameters:
//  IncludeSet	 			- Boolean - indicates whether a set is included in the selection.
//  IncludeMultiTurnContainers	- Boolean - a sign of inclusion in the selection of multi-turn containers.
// 
// Returns:
//  Array - It consists of elements of the Link Enumeration type.Types of nomenclature.
//
Function SelectionByProductMultiTurnContainer(IncludeSet = True, IncludeMultiTurnContainers = True) Export
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	
	If IncludeSet Then
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	EndIf;
	
	If IncludeMultiTurnContainers Then
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	EndIf;
		
	Return ArrayOfProductTypes;
	
EndFunction

// Generates an array of selections by product, multi-turn item, And Service item types
//
// Parameters:
//  IncludeSet	 - Boolean	 - indicates whether a set is included in the selection.
// 
// Returns:
//  Array - It consists of elements of the Link Enumeration type.Types of nomenclature.
//
Function SelectionByProductReusablePackagingService(IncludeSet = True) Export
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
	If IncludeSet Then
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	EndIf;
	
	Return ArrayOfProductTypes;
	
EndFunction

// Generates an array of selections by product and multi-Turn product, Service, and Work item types.
//
// Parameters:
//  IncludeSet	 - Boolean	 - indicates whether a set is included in the selection.
// 
// Returns:
//  Array - It consists of elements of the Link Enumeration type.Types of nomenclature.
//
Function SelectionByProductReusablePackagingServiceWork(IncludeSet = True) Export
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	If IncludeSet Then
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	EndIf;
	
	Return ArrayOfProductTypes;
	
EndFunction

// Generates an array of selections by the type of Work item.
//
// Parameters:
//  IncludeSet	 - Boolean	 - indicates whether a set is included in the selection.
// 
// Returns:
//  Array - It consists of elements of the Link Enumeration type.Types of nomenclature.
//
Function JobSelection(IncludeSet = True) Export
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	If IncludeSet Then
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	EndIf;
	
	Return ArrayOfProductTypes;
	
EndFunction

// Generates a selection array based on the type of Service and Work items.
//
// Parameters:
//  IncludeSet	 - Boolean	 - indicates whether a set is included in the selection.
// 
// Returns:
//  Array - It consists of elements of the Link Enumeration type.Types of nomenclature.
//
Function SelectionByServiceWork(IncludeSet = True) Export
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	If IncludeSet Then
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	EndIf;
	
	Return ArrayOfProductTypes;
	
EndFunction

#Region ProceduresForWorkingWithSeries

// Structure of parameters for specifying series returned by the corresponding procedure of the document Manager module (processing).
//
// Returns:
//	Structure - contains properties:
// 	[REQUIRED].
//		* UseItemsBatch - Boolean - indicates whether the Status of the series should be filled in in the document
//		* SeriesCommunicationFields - Array of String - array with names of Attributes of TS Goods and Series of TS, 
//						according to which the relationship between the table parts 
//						is established (the communication fields "Product" and "Characteristics" are always present, they do not need to be specified separately).
//		* WarehouseTransactions - Array of EnumRef.WarehouseTransactions - warehouse operations executed by a document
//		* FullObjectName - String - full name of the object. For example, A Document.Realizationstovarovuslug.
// [OPTIONAL].
//		* ReadOnly - Boolean - indicates that the series in the document can only be viewed (the default value is FALSE)
//		* ProductInHeader - Boolean - indicates that the parameters for specifying the series are defined for the product in the header (otherwise - for the product in TS) (the default value is FALSE)
//		* BlockFormData - Boolean - indicates that before opening the serial indication form, 
//								you need to block the document form (the default value is TRUE)
//								if only the survey = True, then the form data is not blocked.
//		* NameTSGoods - String - the name of the table part with the list of products (the default value is "Products")
//		* TSSeriesName - String - the name of the table part with the list of series (the default value is "Series")
//		* FieldNameQuantity - String - the name of the field in the TS "Products" in which the user edits the quantity (the default value is "Quantity of packages")
//		* WarehouseFieldName - String - the name of the warehouse Attribute (the default value is "Warehouse")
//		* FieldNameControlledLotReference - Undefined,String - the name of the Attribute associated with the controlled Lot reference,
//		                                Undefined if there is no such Attribute. If the Attribute is in the table part, then "." is placed before its name.
//		* FieldNameRoom - String - the Attribute name of the premises, if not specified, means that there are no premises in the document
//		* FieldNameOfOrderDocument - String - if the series is specified in the spending order, 
//								then the name of the shipment order field is recorded in this parameter.
//								If the series is indicated in the receipt invoice 
//								, then the name of the receipt order field is written in this parameter. The field value is used to display Balances in forms.
//		* ItSWarrant - Boolean - indicates that the document is an order (the default value is FALSE)
//		* ThisIsOrder - Boolean - indicates that the document is an order (the default value is FALSE)
//		* ThisIsAnInvoice - Boolean - indicates that the document is an invoice (the default value is FALSE).
//		* SeriesOnlyForCostPrice - Boolean - you only need to specify the series for which the cost is recorded (the default value is FALSE)
//		* ShipmentPlanning - Boolean - using the batch indication policy parameter "Specify loading scheduling" (the default value is FALSE)
//		* SelectionPlanning - Boolean - using the series indication policy parameter "Specify selection scheduling" (the default value is FALSE)
//		* PickingCheck - Boolean - At the address warehouse, all series for which Balances are recorded must be filled in before inspection.
//		* FactOfSelection  - Boolean - using the series indication policy parameter "Specify the selection effect" (the default value is FALSE)
//		* OrderPreparation - Boolean - This parameter indicates that the order is in the Status 
//								when the order is being prepared and the series is not required (the default value is FALSE).
//		* FieldNamesWithSuffix - Structure - a collection containing requesite names with a suffix. The collection key
//												is the name of the props without a suffix, for example, "Nomenclature",
//												and the value is set to the name of the props with a suffix,
//												for example, "Nomenclature".
//		* FieldNamesStatusOfSeriesIndication - Array of String - if there are several fields in the object with the Status of specifying the series, 
//								then you need to add their names to this array (the default value is an empty array).
//		* MatchesSeriesFieldNameToStatusOfSeriesIndication - Map - a collection containing the matching
//															of the Attribute name of the statusreferences of the Series of the Attribute name Series.
//															For example, the "Status of the Occurrence series" is the key,
//															and the "Arrival series" is the value of the collection.
//		* FieldNamesForOrderDefinition - Array - field names for determining the order 
//								by which the Balances are displayed in the series selection form. The names of the fields in the table part 
//								are specified in the Products format_Document reserveseries (default value is an empty array).
//		* UseBinLocationWarehousing - Boolean - address storage is used in the warehouse where the document is issued (the default value is FALSE)
//		* NameOfValueSourceInObjectForm - String - the default value is "Object", if the data is stored in the Attributes of the form, then you need to specify "This form"
//		* SelectingRowsToCheck - 
//		* OnlySeriesTakingIntoAccountLeftovers - Boolean - It is necessary to specify the series only when Balances are recorded for them. (the default value is FALSE)
//		* SpecialCheckingOfSeriesIndicationStatuses - Boolean - indicates that a procedure has been declared in the manager module 
//								The text of the query is to check the filling of the criteria (the parameters of the specification of the criteria) (the default value is FALSE).
//		* QueryOptions - Structure - Contains the query parameters used in the function of the text request to fill in the status of the series.
//		* SeriesWhenPlanningShipmentVHFSeriesAreIndicated - Boolean - the default value is FALSE.
//		* ParametersForGettingDataFromRegisters - Structure - contains additional request parameters used
//								in the function of the textquestionformatablityregister data.
//
Function SeriesSpecificationParameters() Export
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("UseItemsBatch",Undefined);
	ParametersStructure.Insert("UseCostAccountingByBatches",Undefined);
	ParametersStructure.Insert("WarehouseTransactions",New Array); 
	ParametersStructure.Insert("LinkFields", New Array);
	ParametersStructure.Insert("FullObjectName", "");
	
	ParametersStructure.Insert("ReadOnly",False);
	ParametersStructure.Insert("ProductInHeader",False);
	ParametersStructure.Insert("BlockFormData",True);
	ParametersStructure.Insert("NameTSGoods","Goods");
	ParametersStructure.Insert("TSSeriesName","SetOfSeries");
	ParametersStructure.Insert("FieldNameQuantity","Count");
	ParametersStructure.Insert("WarehouseFieldName","Warehouse");
	ParametersStructure.Insert("FieldNameControlledLotReference", Undefined);
	ParametersStructure.Insert("NameOfSenderWarehouseField",Undefined);
	ParametersStructure.Insert("NameOfRecipientWarehouseField",Undefined);
	ParametersStructure.Insert("FieldNameRoom",Undefined);
	ParametersStructure.Insert("ItSWarrant",False);
	ParametersStructure.Insert("ThisIsOrder",False);
	ParametersStructure.Insert("ThisIsAnInvoice",False);
	ParametersStructure.Insert("SeriesOnlyForCostPrice",False);
	ParametersStructure.Insert("ShipmentPlanning",False);
	ParametersStructure.Insert("SelectionPlanning",False);
	ParametersStructure.Insert("PickingCheck",False);
	ParametersStructure.Insert("FactOfSelection",False);
	ParametersStructure.Insert("OrderPreparation",False);
	ParametersStructure.Insert("RegisterSeries", True);
	ParametersStructure.Insert("Date",Date(1,1,1));
	ParametersStructure.Insert("FieldNamesWithSuffix",New Structure);
	ParametersStructure.Insert("FieldNamesStatusOfSeriesIndication",New Array);
	ParametersStructure.Insert("MatchesSeriesFieldNameToStatusOfSeriesIndication",New Map);
	ParametersStructure.Insert("FieldNamesForOrderDefinition",New Array);
	ParametersStructure.Insert("AdditionalFieldNames",New Array);
	ParametersStructure.Insert("UseBinLocationWarehousing",False);
	ParametersStructure.Insert("NameOfValueSourceInObjectForm","Object");
	ParametersStructure.Insert("SelectingRowsToCheck", Undefined);
	ParametersStructure.Insert("OnlySeriesTakingIntoAccountLeftovers", False);
	ParametersStructure.Insert("SpecialCheckingOfSeriesIndicationStatuses", False);
	ParametersStructure.Insert("NeedToRoundUpQuantity", True);
	ParametersStructure.Insert("QueryOptions", New Structure);
	ParametersStructure.Insert("SeriesWhenPlanningShipmentVHFSeriesAreIndicated", False);
	ParametersStructure.Insert("ParametersForGettingDataFromRegisters", New Structure);
	ParametersStructure.Insert("ProductLocationsAreUsed", False);
	ParametersStructure.Insert("SeriesCanBeSpecifiedInRefinementTable", False);
	ParametersStructure.Insert("IndependentCalculationOfSeveralStatusesOfSeriesIndicationIsRequired", False);
	
	ParametersStructure.Insert("DocumentOperation_", Undefined);
	
	Return ParametersStructure;
	
EndFunction

// Structure returned by the series selection form
// 
// Returns:
//  Structure - a structure with the following keys:
//  * Value - CatalogRef.ItemsBatches
//  * RowID - Number - ID of the row in the form table to insert the value in.
//
Function SelectedSeries() Export
	
	Return New Structure("Value,ValueOfDebitedSeries,CurrentRowID,TSName");
	
EndFunction

// The procedure updates the cache of key details of the current product line. Key details are
//  used to link the PM series and PM products.
//
// Parameters:
//  CurrentRow			 - FormDataCollectionItem - the string used to update the cache.
//  CachedValues	 - Structure - a form module variable that stores cached values
//  SeriesSpecificationParameters	 - See SeriesSpecificationParameters
//  Copy				 - Boolean - indicates that the cached string has been copied (parameter of the event at the start of Editing).
//
Procedure UpdateCachedValuesToAccountForSeries(CurrentRow,CachedValues,SeriesSpecificationParameters,Copy = False) Export
	
	If Not SeriesSpecificationParameters.UseItemsBatch Then
		Return;
	EndIf;
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	If CurrentRow <> Undefined
		And (Not Copy
		Or SeriesSpecificationParameters.NameTSGoods = SeriesSpecificationParameters.TSSeriesName) Then
		
		CachedValues.Insert("Products",CurrentRow.Products);
		CachedValues.Insert("Characteristic",CurrentRow.Characteristic);
		
		If CurrentRow.Property(SeriesSpecificationParameters.FieldNameQuantity) Then
			CachedValues.Insert(SeriesSpecificationParameters.FieldNameQuantity, CurrentRow[SeriesSpecificationParameters.FieldNameQuantity]);
		EndIf;
		
		If CurrentRow.Property("Canceled") Then
			CachedValues.Insert("Canceled",CurrentRow.Canceled);
		EndIf;
		
		For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
			If CurrentRow.Property(ArrRow) Then
				CachedValues.Insert(ArrRow,CurrentRow[ArrRow]);
			EndIf;
		EndDo;
		
		For Each ArrRow In SeriesSpecificationParameters.AdditionalFieldNames Do
			If CurrentRow.Property(ArrRow) Then
				CachedValues.Insert(ArrRow,CurrentRow[ArrRow]);
			EndIf;
		EndDo;
		
	Else
		CachedValues.Insert("Products",Undefined);
		CachedValues.Insert("Characteristic",Undefined);
		CachedValues.Insert(SeriesSpecificationParameters.FieldNameQuantity ,0);
		
		If SeriesSpecificationParameters.ThisIsOrder Then
			CachedValues.Insert("Canceled", Undefined);
		EndIf;
		
		For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
			CachedValues.Insert(ArrRow,Undefined);
		EndDo;
	EndIf;
	
EndProcedure

// This function determines whether new series can be registered when the series is specified in the document.
//
// Parameters:
//  SeriesSpecificationParameters - See SeriesSpecificationParameters
//  	  
// Returns:
//  Boolean - TRUE - it is possible to register new series, FALSE - series can be selected only by leftovers.
//
Function ItIsNecessaryToRegisterSeries(SeriesSpecificationParameters) Export
	
	If (SeriesSpecificationParameters.ShipmentPlanning
		   		Or SeriesSpecificationParameters.SelectionPlanning  
		   		Or SeriesSpecificationParameters.OrderPreparation)
				And Not SeriesSpecificationParameters.FactOfSelection Then
		
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Function is valid until the date of production
//
// Parameters:
//  ProductionDate				 - Date
//  ExpirationDate_					 - Number
//  ShelfLifeUnitOfMeasure	 - EnumRef.TimeMeasureUnits
//
// Returns:
//  Date - 
//
Function ValidUntilDateOfProduction(ProductionDate, ExpirationDate_, ShelfLifeUnitOfMeasure) Export
	
	ValidUntil_ = '00010101';
	
	If Not ValueIsFilled(ProductionDate)
		Or Not ValueIsFilled(ExpirationDate_) Then
		Return ValidUntil_;
	EndIf;
	
	If ShelfLifeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Year") Then
		ValidUntil_ = AddMonth(ProductionDate, ExpirationDate_ * 12);
	ElsIf ShelfLifeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Month") Then
		ValidUntil_ = AddMonth(ProductionDate, ExpirationDate_);
	ElsIf ShelfLifeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Days1") Then
		ValidUntil_ = ProductionDate + ExpirationDate_ * 86400;
	ElsIf ShelfLifeUnitOfMeasure =  PredefinedValue("Enum.TimeMeasureUnits.Hour") Then
		ValidUntil_ = ProductionDate + ExpirationDate_ * 3600;
	EndIf;
	
	Return ValidUntil_;
	
EndFunction

// Platform error 00110413.
// Recalculates the date value of the item in the "Seriinomenklatura" reference list, after selecting the value using platform tools.
//
// Parameters:
//	SeriesDate - Date - date of the item in the "Seriinomenklatura" directory, obtained by platform tools.
//
Procedure RecalculateSeriesDate(SeriesDate) Export
	
	If Not ValueIsFilled(SeriesDate) Then
		Return;
	EndIf;
	
	SeriesDate = ?(Date(2000, 1, 1) > SeriesDate, AddMonth(SeriesDate, 1200), SeriesDate);
	
EndProcedure

#EndRegion

// Generates an array of selections by item type And multi-turn item, Work.
//
// Parameters:
//  IncludeSet	 - Boolean	 - indicates whether a set is included in the selection.
// 
// Returns:
//  Array - It consists of elements of the Link Enumeration type.Types of nomenclature.
//
Function SelectionByProductReusablePackagingWork(IncludeSet = True) Export
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	If IncludeSet Then
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	EndIf;
	
	Return ArrayOfProductTypes;
	
EndFunction

// Parameters for selecting series accounting policies
// 
// Returns:
//  Structure: 
//  	* Warehouse - CatalogRef.Warehouses
//  	* ProductKind - CatalogRef.ItemKinds 
//  	* KeepAccountingByBatch - Boolean
//  	* UseShelfLifeOnBatchRegistration - Boolean
//  	* ItemsType - EnumRef.ItemsTypes 
//  	* AccountingFeature - EnumRef.ItemAccountingFeatures  
//  	* BatchUsageSettings - EnumRef.ItemsBatchUsageSettings
//
Function SelectionParametersForSeriesAccountingPolicies() Export
	SelectionParametersForSeriesAccountingPolicies = New Structure;
	
	SelectionParametersForSeriesAccountingPolicies.Insert("Warehouse");
	SelectionParametersForSeriesAccountingPolicies.Insert("ProductKind");	
	
	SelectionParametersForSeriesAccountingPolicies.Insert("KeepAccountingByBatch", False);
	SelectionParametersForSeriesAccountingPolicies.Insert("UseShelfLifeOnBatchRegistration", False);
	SelectionParametersForSeriesAccountingPolicies.Insert("ItemsType");
	SelectionParametersForSeriesAccountingPolicies.Insert("AccountingFeature");
	SelectionParametersForSeriesAccountingPolicies.Insert("BatchUsageSettings");
	
	Return SelectionParametersForSeriesAccountingPolicies;
EndFunction

// Returns a collection of traceability details initialized by default.
//
// Returns:
//	Structure - a collection of Traceability Attributes that contains the following fields:
//		* UnitOfMeasure			- CatalogRef.PackagesAndUnitsOfMeasure - unit of measurement.
//		* TracedGoods		- Boolean - indicates that the product is registered in the traceability system.
//
Function DefaultTraceabilityDetails() Export
	
	TraceabilityDetails = New Structure;
	TraceabilityDetails.Insert("UnitOfMeasure",
										PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	TraceabilityDetails.Insert("TracedGoods", False);
	
	Return TraceabilityDetails;
	
EndFunction

// Returns the name of the product header field by the specified field name parameter.
//
// Parameters:
//	FieldName - String - the name of the product field for which you want to get the associated name of the product header field.
//
// Returns:
//	String - the name of the product header field calculated using the specified field name parameter.
//
Function NameOfProductHeaderField(FieldName) Export
	
	If IsBlankString(FieldName) Then
		ExceptionText = StrTemplate(NStr("vi = 'Chưa chỉ ra tham số ""%1"".';
										|ru = 'Не указан параметр ""%1"".';
										|en = '""%1"" parameter is not specified.'; fa = '""%1"" parameter is not specified.';
										|it = 'Non è stato indicato il parametro ""%1"".';
										|pl = 'Nie jest określony parametr ""%1"".';
										|tr = '""%1"" parametresi belirtilmedi.'"),
									"FieldName");
		
		Raise ExceptionText;
	EndIf;
	
	NameOfProductHeaderField = "";
	
	If FieldName = "Products" Then
		NameOfProductHeaderField = "ProductHeader";
	ElsIf FieldName = "Characteristic" Then
		NameOfProductHeaderField = "CharacteristicCap";
	ElsIf FieldName = "Purpose" Then
		NameOfProductHeaderField = "DestinationHeader_";
	ElsIf FieldName = "Count" Then
		NameOfProductHeaderField = "NumberOfCaps";
	EndIf;
	
	If IsBlankString(NameOfProductHeaderField) Then
		ExceptionText = StrTemplate(NStr("vi = 'Không có trường trong phần đầu hàng hóa đối với tham số ""%1"".';
										|ru = 'Отсутствует поле шапки товара для параметра ""%1"".';
										|en = 'Goods header field for parameter ""%1"" is missing.'; fa = 'Goods header field for parameter ""%1"" is missing.';
										|it = 'Manca il campo della testata della merce per il parametro ""%1"".';
										|pl = 'Brak pola nagłówka towaru dla parametru ""%1"".';
										|tr = '""%1"" parametresi için ürün üst bilgi alanı eksik.'"),
									FieldName);
		
		Raise ExceptionText;
	EndIf;
	
	Return NameOfProductHeaderField;
	
EndFunction

#Region QualityCertificates

// Returns a collection of default parameters used when setting the Status of item certificates.
//
// Returns:
//	Structure - a collection of default parameters containing the following properties:
//		* Status - EnumRef.StatusesOfQualityCertificates - the Status value to set.
//																		The default value is Valid.
//		* DataForProcessing_ - Array of CatalogRef.QualityCertificates,
//								An array from the register of the record key.The domain of action of the classificationnomenclature is a collection of processed data.
//
Function ParametersForSettingStatusOfCertificatesOfDefaultNomenclature() Export
	
	FillParameters = New Structure;
	FillParameters.Insert("DataForProcessing_", New Array);
	FillParameters.Insert("Status",
		PredefinedValue("Enum.StatusesOfQualityCertificates.Valid_"));
	
	Return FillParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function SeriesStatusesSeriesNotSpecified() Export
	
	// The order of the following statuses is used in recalculating
	// the status of the seriesprocessing and must correspond to the order in other functions of the status of the serieseries.
	Statuses = New Array;
	Statuses.Add(1);
	Statuses.Add(3);
	Statuses.Add(5);
	Statuses.Add(7);
	Statuses.Add(9);
	Statuses.Add(13);
	Statuses.Add(17);
	Statuses.Add(19);
	
	Return Statuses;
	
EndFunction

Function SeriesStatusesSeriesIsSpecified() Export
	
	// The order of the following statuses is used in recalculating
	// the status of the seriesprocessing and must correspond to the order in other functions of the status of the serieseries.
	Statuses = New Array;
	Statuses.Add(2);
	Statuses.Add(4);
	Statuses.Add(6);
	Statuses.Add(8);
	Statuses.Add(10);
	Statuses.Add(14);
	Statuses.Add(18);
	Statuses.Add(20);
	
	Return Statuses;
	
EndFunction

Function SeriesStatusesYouCanSpecifySeries() Export
	
	// The order of the following statuses is used in recalculating
	// the status of the seriesprocessing and must correspond to the order in other functions of the status of the serieseries.
	Statuses = New Array;
	Statuses.Add(21);
	Statuses.Add(23);
	Statuses.Add(25);
	Statuses.Add(27);
	Statuses.Add(11);
	Statuses.Add(15);
	Statuses.Add(28);
	
	Return Statuses;
	
EndFunction

Procedure RecalculateStatusOfSpecifyingSeriesDuringProcessing(SeriesSpecificationParameters, CurrentStatus, SeriesAreIndicatedInFull, SeriesCount, SupplyOption = Undefined, CurrentData = Undefined) Export
	
	// If the series is specified in PM Goods, then the value of the Quantity parameter of the series should be Undefined, because in this case
	// the status of the indication of the series does not depend on the quantity - in this case, the status of the indication of the series depends only on whether the series 
	// is specified or not.
	
	// If the series is specified in the PM Goods, then in the Seriescription parameter, the attribute is fully transmitted - the series is filled or not,
	// otherwise - whether the number of goods is equal to the number of series (if the number of goods is 0, then the parameter must be FALSE).
	
	If CurrentStatus = 0 Then
		Return;
	EndIf;
	ThisIsTransferFromProductionShippedButNotAccepted = 
		(
			SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.ReturnMaterialsFromProductionShipment")) <> Undefined
			And SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.ReturnMaterialsFromProductionReceiving")) = Undefined
		)
		Or
		(
			SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.ShipProductsFromProduction")) <> Undefined
			And SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing")) = Undefined
		);
	TheseAreOutputProductsOfStage = 
		(
			SeriesSpecificationParameters.FullObjectName = "Document.ProductionStage2_2"
			Or SeriesSpecificationParameters.FullObjectName = "DataProcessor.EditProductionStageSequence"
			Or SeriesSpecificationParameters.FullObjectName = "DataProcessor.ProductionLotDivision"
		) 
		And SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing")) <> Undefined
		And Not CurrentData.Manufactured;
	TheseAreMaterialsMLOrProcOfOperationOrRAndM = 
		SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.ProductRM")) <> Undefined
		Or SeriesSpecificationParameters.WarehouseTransactions.Find(PredefinedValue("Enum.WarehouseTransactions.ConsumptionDuringProduction")) <> Undefined
			And (SeriesSpecificationParameters.FullObjectName = "Document.ProductionOperation2_2"
			);
	UseSeriesStatusCanBeSpecifiedLocalization = False;
	ProductsClientServerLocalization.UseSeriesStatusCanBeSpecified(
		UseSeriesStatusCanBeSpecifiedLocalization,
		SeriesSpecificationParameters);
	
	ApplyStatusCanBeSpecified = (SeriesSpecificationParameters.OrderPreparation
									Or ThisIsTransferFromProductionShippedButNotAccepted
									Or TheseAreOutputProductsOfStage
									Or TheseAreMaterialsMLOrProcOfOperationOrRAndM
										And (CommonClientServer.StructureProperty(CurrentData, "Canceled", False)
											Or Not (SeriesSpecificationParameters.FactOfSelection
													Or CommonClientServer.StructureProperty(CurrentData, "Status", Undefined)
														= PredefinedValue("Enum.StatusesOfProductionStages2_2.Initiated")
													Or CommonClientServer.StructureProperty(CurrentData, "Status", Undefined)
														= PredefinedValue("Enum.StatusesOfProductionStages2_2.Completed")))
									Or SeriesSpecificationParameters.ThisIsOrder
										And SupplyOption = PredefinedValue("Enum.SupplyOptions.FromWarehouse")
									Or SeriesSpecificationParameters.FullObjectName = "Document.InvoiceIssued"
									Or UseSeriesStatusCanBeSpecifiedLocalization)
									And Not SeriesAreIndicatedInFull
									And (SeriesCount = 0
										Or SeriesCount = Undefined);
		
	StatusIndex_3 = SeriesStatusesSeriesNotSpecified().Find(CurrentStatus);

	If StatusIndex_3 = Undefined Then
		StatusIndex_3 = SeriesStatusesSeriesIsSpecified().Find(CurrentStatus);
	EndIf;
	
	If StatusIndex_3 = Undefined Then
		StatusIndex_3 = SeriesStatusesYouCanSpecifySeries().Find(CurrentStatus);
	EndIf;
	
	If Not SeriesAreIndicatedInFull
		And ApplyStatusCanBeSpecified Then
		ResultsArray = SeriesStatusesYouCanSpecifySeries();
	ElsIf Not SeriesAreIndicatedInFull Then
		ResultsArray = SeriesStatusesSeriesNotSpecified();
	ElsIf SeriesAreIndicatedInFull Then
		ResultsArray = SeriesStatusesSeriesIsSpecified();
	EndIf;
	
	CurrentStatus = ResultsArray[StatusIndex_3];
	
EndProcedure

Function InThisStatusOfSeriesWHGoodsAreIndicated(BatchesIndicationStatus, SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters.NameTSGoods = SeriesSpecificationParameters.TSSeriesName Then
		Return True;
	EndIf;
	
	Statuses = New Array;
	Statuses.Add(0);
	Statuses.Add(13);
	Statuses.Add(14);
	Statuses.Add(15);
	Statuses.Add(17);
	Statuses.Add(18);
	Statuses.Add(19);
	Statuses.Add(20);
	
	If Not SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated Then
		Statuses.Add(9);
		Statuses.Add(10);
		Statuses.Add(11);
	EndIf;
	
	If Statuses.Find(BatchesIndicationStatus) = Undefined Then
		
		Return False;
		
	Else
		
		Return True;
		
	EndIf;
	
EndFunction

Function NoSeriesAreSpecifiedInThisStatus(BatchesIndicationStatus, SeriesSpecificationParameters) Export
	
	If BatchesIndicationStatus = 0 
		Or (SeriesStatusesYouCanSpecifySeries().Find(BatchesIndicationStatus) <> Undefined
			And Not SeriesSpecificationParameters.OrderPreparation) Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

Function ThisSeriesStatusIndicatesWHSeries(BatchesIndicationStatus, SeriesSpecificationParameters) Export
	
	Return Not NoSeriesAreSpecifiedInThisStatus(BatchesIndicationStatus, SeriesSpecificationParameters)
		And Not InThisStatusOfSeriesWHGoodsAreIndicated(BatchesIndicationStatus, SeriesSpecificationParameters);
	
EndFunction

Function FieldValuesToIdentifyReferences(Object, CurrentRow, SeriesSpecificationParameters) Export
	
	FieldValuesToIdentifyReferences = New Structure;
	
	For Each ArrRow In SeriesSpecificationParameters.FieldNamesForOrderDefinition Do
		
		SeparatorLocation = StrFind(ArrRow, "_");
		
		If SeparatorLocation = 0 Then
			FieldValuesToIdentifyReferences.Insert(ArrRow, Object[ArrRow]);
		Else
			FieldName = Right(ArrRow, StrLen(ArrRow)- SeparatorLocation);
			FieldValuesToIdentifyReferences.Insert(ArrRow, CurrentRow[FieldName]);
		EndIf;
		
	EndDo;
	
	Return FieldValuesToIdentifyReferences;
EndFunction

#EndRegion
