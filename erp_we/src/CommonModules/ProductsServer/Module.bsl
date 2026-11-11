////////////////////////////////////////////////////////////////////////////////
// Server procedures for working with nomenclature and related reference books
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates the name of the reference list element based on the template specified for the item type.
// Returns an empty string if the name could not be formed or the operands of the algorithm are not filled in.
//
// Parameters:
//	DescriptionTemplate - String - name template specified as an item;
//	ObjectCatalog - CatalogObject.Products, CatalogObject.ItemsCharacteristics, CatalogRef.Products, CatalogRef.ItemsCharacteristics -
//	 	an item or characteristic that you want to get a name for using the template specified in the settings.
//
// Returns:
//	String - The name obtained by the calculation algorithm
//
Function NameByTemplate (Val DescriptionTemplate, ObjectCatalog) Export
	
	NamingFormulaStructure = NamingFormula(DescriptionTemplate, ObjectCatalog);
	NamingFormula = """"" + " + StrReplace(NamingFormulaStructure.NamingFormula,
		"ArrayOfPropsValues[",
		"Parameters[");
	
	Description = "";
	
	If ValueIsFilled(NamingFormula) Then
		
		Try
			
			Description = Common.CalculateInSafeMode(
				NamingFormula,
				NamingFormulaStructure.ArrayOfPropsValues);
			
		Except
			
			ErrorMessageTemplate = NStr("vi = 'Không thể tạo tên gọi theo khuôn mẫu đã đặt đối với dạng mặt hàng ""%ProductKind%"". Hãy kiểm tra tính chính xác của khuôn mẫu.';
										|ru = 'Невозможно сформировать наименование по заданному для вида номенклатуры ""%ProductKind%"" шаблону. Проверьте правильность шаблона.';
										|en = 'Cannot generate a name according to the ""%ProductKind%"" template specified for the item kind. Check whether the template is correct.'; fa = 'Cannot generate a name according to the ""%ProductKind%"" template specified for the item kind. Check whether the template is correct.';
										|it = 'Non è possibile generare un nome per la vista articolo specificata ""%ProductKind%"" modello. Verificare che il modello sia corretto.';
										|pl = 'Nie jest możliwe wygenerowanie nazwy wg podanego dla rodzaju nomenklatury ""%ProductKind%"" szablonu. Sprawdź poprawność szablonu.';
										|tr = '""%ProductKind%"" öğe türü için belirtilen numuneye göre tanım oluşturmak mümkün değildir. Numunenin doğru olup olmadığını kontrol et.'");
			
			If TypeOf(ObjectCatalog) = Type("CatalogObject.Products")
			 Or TypeOf(ObjectCatalog) = Type("CatalogObject.ItemsBatches") Then
				
				ProductKind = ObjectCatalog.ProductKind;
				
			Else
				
				If TypeOf(ObjectCatalog.Owner) = Type("CatalogRef.Products") Then
					
					ProductKind = Common.ObjectAttributeValue(ObjectCatalog.Owner, "ProductKind");
					
				ElsIf TypeOf(ObjectCatalog.Owner) = Type("CatalogRef.ItemKinds") Then
					
					ProductKind = ObjectCatalog.Owner;
					
				EndIf;
				
			EndIf;
			
			ErrorMessage = StrReplace(ErrorMessageTemplate, "%ProductKind%", ProductKind);
			Raise ErrorMessage;
			
		EndTry;
		
	EndIf;
	
	Return Description;
	
EndFunction

// Substitutes the details ' values in the name template.
//
// Parameters:
//  DescriptionTemplate	 - String								 - name template specified as an item
//  ObjectCatalog	 - CatalogObject, CatalogRef	 - the object for which you want to calculate the name.
// 
// Returns:
//  Structure - structure with keys:
//  * NamingFormula - String - program code to run using the Run function to calculate the name
//  * ArrayOfPropsValues - Array - values of the details used in the name formula
//  * IndexesOfNameInArrayOfPropsValues - Array - array of element indexes
//  	array of requisit Values that store the value of the "Name"attribute.
//
Function NamingFormula(Val DescriptionTemplate, Val ObjectCatalog) Export
	
	Result = New Structure(
		"NamingFormula, ArrayOfPropsValues, IndexesOfNameInArrayOfPropsValues",
		"" + DescriptionTemplate, New Array, New Array);
		
	FormulaOperands = ProcessingOfFormulasClientServer.OperandsOfTextFormula(DescriptionTemplate, True);
	If FormulaOperands.Count() > 0 Then
		// Since the name can be formed from an element that is not written in the database
		// , we get the first part of the operands from the object, the rest are calculated
		// in the appropriate methods.
		Table_Calculation = New ValueTable;
		SourceDataString = Table_Calculation.Add();
		MatchesNamesOfStandardProps = ProcessingOfFormulasCached.MatchesNamesOfStandardProps();
		FeatureColumnNames = New Map;
		CalculationExpressions = New Map;
		ExpressionCounter = 0;
		For Each FormulaOperand In FormulaOperands Do
			OperandParts = ProcessingOfFormulasClientServer.OperandParts(FormulaOperand);
			AttributeName = OperandParts[0];
			ThisIsCharacteristic = StrFind(AttributeName, "{") > 0;
			
			OperandValue = Undefined;
			MetadataObjectName = ObjectCatalog.Metadata().FullName();
			ValueType = Undefined;
			ExpressionCounter = ExpressionCounter + 1;
			NameOfResultColumn = "ResultOfCalculatingFormulaExpression" + Format(ExpressionCounter, "NZ=0; NG=0;");
			CalculationExpressions.Insert(FormulaOperand, NameOfResultColumn);
			
			If Not ThisIsCharacteristic Then
				// This is a prop.
				ObjectMetadata = ObjectCatalog.Metadata();
				Attribute = ObjectMetadata.Attributes.Find(AttributeName);
				If Not Attribute = Undefined Then
					ValueType = Attribute.Type;
				Else
					For Each Attribute In ObjectMetadata.StandardAttributes Do
						If Attribute.Name = AttributeName
							Or MatchesNamesOfStandardProps.Get(Attribute.Name) = AttributeName Then
							ValueType = Attribute.Type;
							Break;
						EndIf;
					EndDo;
				EndIf;
				If ValueType = Undefined Then
					RaiseExceptionForNameTemplateError(FormulaOperand, AttributeName);
				Else
					If Common.IsReference(TypeOf(ObjectCatalog)) Then
						OperandValue = Common.ObjectAttributeValue(ObjectCatalog, AttributeName);
					Else
						OperandValue = ObjectCatalog[AttributeName];
					EndIf;
					
					If Table_Calculation.Columns.Find(AttributeName) = Undefined Then
						Table_Calculation.Columns.Add(AttributeName, ValueType);
						SourceDataString[AttributeName] = OperandValue;
					EndIf;
				EndIf;
			Else
				// This is an additional props or additional information.
				
				ObjectProperties = PropertyManager.ObjectProperties(ObjectCatalog);
				
				If ObjectProperties.Count() > 0 Then
					Query = New Query;
					QueryText =
					"SELECT
					|	AdditionalAttributesAndInfo.Ref AS AdditionalAttribute5,
					|	AdditionalAttributesAndInfo.ValueType AS ValueType,
					|	AdditionalAttributesAndInfo.IsAdditionalInfo AS IsAdditionalInfo
					|FROM
					|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AdditionalAttributesAndInfo
					|WHERE
					|	NOT AdditionalAttributesAndInfo.DeletionMark
					|	AND AdditionalAttributesAndInfo.Ref IN(&ObjectProperties)
					|	AND &ExpressionIDForFormulas = &IDOfAdditionalBankingDetails";
					ExpressionIDForFormulas = StringFunctionsClientServer.SubstituteParametersToString(
						"AdditionalAttributesAndInfo.%1",
						ProcessingOfFormulas.IdFieldForAdditionalBankingDetails());
					QueryText = StrReplace(QueryText, "&ExpressionIDForFormulas", ExpressionIDForFormulas);
					Query.Text = QueryText;
					
					IDOfAdditionalBankingDetails = ProcessingOfFormulas.PropertiesCharacteristics(AttributeName).Id;
					Query.SetParameter("ObjectProperties", ObjectProperties);
					Query.SetParameter("IDOfAdditionalBankingDetails", IDOfAdditionalBankingDetails);
					
					AddAttributes = Query.Execute().Unload();
					
					If AddAttributes.Count() = 0 Then
						// An error in the operand - the current prop is not a non-prop of the previous value, and it is not an additional prop.
						RaiseExceptionForNameTemplateError(FormulaOperand, AttributeName);
					ElsIf AddAttributes.Count() > 1 Then
						ErrorMessageText =
						NStr("vi = 'Không thể tính đến mặt hàng theo khuôn mẫu.
						|Trong cơ sở thông tin có lưu nhiều bản ghi mục tin và thông tin bổ sung với tên định danh ""%AttributeName%"", thuộc thành phần tập hợp mục tin và thông tin bổ sung của phần tử danh mục đã ghi lại ""%ObjectName%"".';
						|ru = 'Невозможно рассчитать наименование по шаблону.
						|В информационной базе хранится несколько записей дополнительных реквизитов и сведений с идентификатором ""%AttributeName%"", входящих в состав набора дополнительных реквизитов и сведений записываемого элемента справочника ""%ObjectName%"".';
						|en = 'Cannot calculate the name under the template.
						|The infobase stores several records of additional attributes and data with the ""%AttributeName%"" ID included into the set of additional attributes and data of the recorded directory item ""%ObjectName%"".'; fa = 'Cannot calculate the name under the template.
						|The infobase stores several records of additional attributes and data with the ""%AttributeName%"" ID included into the set of additional attributes and data of the recorded directory item ""%ObjectName%"".';
						|it = 'Impossibile calcolare il nome del modello.
						|Il database di informazioni contiene diversi record di dettagli aggiuntivi e informazioni con l''identificatore ""%AttributeName%"", come parte di un insieme di dettagli aggiuntivi e informazioni sull''elemento di riferimento scrivibile""%ObjectName%"".';
						|pl = 'Nie można obliczyć nazwę według szablonu.
						|W bazie informacyjnej są przechowywane kilka wpisów atrybutów dodatkowych i informacji o identyfikatorze ""%AttributeName%"", wchodzących do składu zestawu atrybutów dodatkowych i informacji zapisywanego elementu katalogu""%ObjectName%"".';
						|tr = 'Tanımı numuneye göre hesaplamak imkansızdır.
						|Infobase, ""%AttributeName%"" tanımlayıcısı ile, ""%ObjectName%"" kayıtlı katalog öğesinin ek öznitelikleri ve bilgileri set kapsamına ait ek özniteliklerin ve bilgilerin birkaç kaydını saklar.'");
						
						ErrorMessageText = StrReplace(ErrorMessageText, "%AttributeName%", AttributeName);
						ErrorMessageText = StrReplace(ErrorMessageText,
															"%ObjectName%",
															ObjectCatalog.Metadata().Presentation());
						
						Raise ErrorMessageText;
					Else
						AdditionalAttribute5 = AddAttributes[0].AdditionalAttribute5;
						ValueType = AddAttributes[0].ValueType;
						IsAdditionalInfo = AddAttributes[0].IsAdditionalInfo;
					EndIf;
				Else
					// An error in the operand - the current prop is not a non-prop of the previous value, and it is not an additional prop.
					RaiseExceptionForNameTemplateError(FormulaOperand, AttributeName);
				EndIf;
				
				If Common.IsReference(TypeOf(ObjectCatalog)) Then
					
					Query = New Query;
					Query.Text =
					"SELECT TOP 1
					|	AdditionalAttributes.Value AS Value
					|FROM
					|	&NameOfMetadataObjectAdditionalDetails AS AdditionalAttributes
					|WHERE
					|	AdditionalAttributes.Ref = &Ref
					|	AND AdditionalAttributes.Property = &Property
					|	AND NOT &IsAdditionalInfo
					|
					|UNION ALL
					|
					|SELECT TOP 1
					|	AdditionalInfo.Value AS Value
					|FROM
					|	InformationRegister.AdditionalInfo AS AdditionalInfo
					|WHERE
					|	AdditionalInfo.Object = &ObjectReference
					|	AND AdditionalInfo.Property = &Property
					|	AND &IsAdditionalInfo";
					
					Query.Text = StrReplace(Query.Text, "&NameOfMetadataObjectAdditionalDetails", ""+MetadataObjectName + ".AdditionalAttributes");
					
					Query.SetParameter("Ref", ObjectCatalog);
					Query.SetParameter("Property", AdditionalAttribute5);
					Query.SetParameter("IsAdditionalInfo", IsAdditionalInfo);
					
					Selection = Query.Execute().Select();
					If Selection.Next() Then
						OperandValue = Selection.Value;
					Else
						OperandValue = "";
					EndIf;
					
				Else
					
					If Not IsAdditionalInfo Then
						AdditionalPropsLine = ObjectCatalog.AdditionalAttributes.Find(AdditionalAttribute5, "Property");
						OperandValue = ?(AdditionalPropsLine <> Undefined, AdditionalPropsLine.Value, "");
					Else
						ReferenceCatalogObject = ObjectCatalog.Ref;
						If Not ValueIsFilled(ReferenceCatalogObject) Then
							OperandValue = Undefined;
						Else
							Query = New Query;
							Query.Text =
							"SELECT TOP 1
							|	AdditionalInfo.Value AS Value
							|FROM
							|	InformationRegister.AdditionalInfo AS AdditionalInfo
							|WHERE
							|	AdditionalInfo.Object = &ObjectReference
							|	AND AdditionalInfo.Property = &Property";
							Query.SetParameter("ObjectReference", ReferenceCatalogObject);
							Query.SetParameter("Property", AdditionalAttribute5);
							Selection = Query.Execute().Select();
							If Selection.Next() Then
								OperandValue = Selection.Value;
							Else
								OperandValue = "";
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				ColumnName = "AdditionalAttribute5_" + StrReplace(AdditionalAttribute5.UUID(), "-", "_");
				
				If Table_Calculation.Columns.Find(ColumnName) = Undefined Then
					Table_Calculation.Columns.Add(ColumnName, ValueType);
					SourceDataString[ColumnName] = OperandValue;
					FeatureColumnNames.Insert(AttributeName, ColumnName);
				EndIf;
			EndIf;
			
		EndDo;
		CalculationResult_ = ProcessingOfFormulas.GetOperandDataForDataTable(Table_Calculation,
			CalculationExpressions,
			FeatureColumnNames,
			True);
		If CalculationResult_.HasErrors Then
			For Each OriginalExpressionAndErrorText In CalculationResult_.ConversionErrorMessages Do
				ErrorText = OriginalExpressionAndErrorText.Value;
				Raise ErrorText;
			EndDo;
		Else
			ResultsTable = CalculationResult_.ResultsTable; // ValueTable -
			For Each ResultColumnExpressionAndName In CalculationExpressions Do
				OriginalExpression = ResultColumnExpressionAndName.Key;
				NameOfResultColumn = ResultColumnExpressionAndName.Value;
				CalculationResult = ResultsTable[0][NameOfResultColumn];
				OperandWithBrackets = ProcessingOfFormulasClientServer.GetOperandTextToInsert(OriginalExpression);
				IndexInArray = Result.ArrayOfPropsValues.Count();
				Result.ArrayOfPropsValues.Add(?(ValueIsFilled(CalculationResult), CalculationResult, ""));
				ReplacementStringInTemplate = "ArrayOfPropsValues[" + IndexInArray + "]";
				Result.NamingFormula = StrReplace(Result.NamingFormula, OperandWithBrackets, ReplacementStringInTemplate);
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Function - Acceptable item types to select by Business transaction
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - Business transaction of the document;
//  UseSets - Boolean - Indicates whether item sets are used.
// 
// Returns:
//  Array of EnumRef.ItemsTypes - Item types allowed for the specified business transaction.
//
Function AcceptableItemTypesToChooseFrom(BusinessOperation, UseSets = False) Export

	ArrayOfProductTypes = New Array();
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	
	If Not BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal 
		And Not BusinessOperation = Enums.BusinessTransactions.GoodsShipmentToCustomer
		And Not BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		And Not BusinessOperation = Enums.BusinessTransactions.GoodsReceiptFromCustomer Then
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	EndIf;
	
	ListOfOperationsWithoutServices = ListOfBusinessOperationsExcludingServices();
	If ListOfOperationsWithoutServices.FindByValue(BusinessOperation) = Undefined Then
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
	EndIf;
	
	ListOfOperationsWithoutJobs = ListOfBusinessOperationsExcludingWork();
	If ListOfOperationsWithoutJobs.FindByValue(BusinessOperation) = Undefined Then
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	EndIf;
	
	If UseSets Then
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Set"));
	EndIf;

	Return ArrayOfProductTypes;

EndFunction

// The procedure sets the selection parameters for the item.
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document,
//	ProductItem - FormField - The field for entering the item,
//	UseSets - Boolean - True-indicates that the item sets are being used.
//
Procedure SetProductSelectionParameters(BusinessOperation, ProductItem, UseSets = False) Export
	
	ParametersArray = New Array;
	
	ArrayOfProductTypes = AcceptableItemTypesToChooseFrom(BusinessOperation, UseSets);
	
	FixedArrayOfProductTypes = New FixedArray(ArrayOfProductTypes);
	ParametersArray.Add(New ChoiceParameter("Filter.ItemsType", FixedArrayOfProductTypes));
	
	ProductItem.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure // Set the parameters of the Nomenclature Selection()

// The function returns a list of business operations that do not use the item
// with the "Service"type.
//
// Returns:
//	ValueList - list of operations.
//
Function ListOfBusinessOperationsExcludingServices() Export
	
	TransactionList = ListOfBusinessOperationsExcludingServicesAndWorks();
	TransactionList.Add(Enums.BusinessTransactions.DeliveryForPrincipal);
	
	Return TransactionList;
	
EndFunction

// The function returns a list of business operations that do not use the item
// with the "Work"type.
//
// Returns:
//	ValueList - list of operations.
//
Function ListOfBusinessOperationsExcludingWork() Export
	
	TransactionList = ListOfBusinessOperationsExcludingServicesAndWorks();
	TransactionList.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	TransactionList.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	TransactionList.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	
	Return TransactionList;
	
EndFunction

// The function returns a list of business operations that do not use the item
// with both the "Service" and "Work"types.
//
// Returns:
//	ValueList - list of operations.
//
Function ListOfBusinessOperationsExcludingServicesAndWorks() Export
	
	TransactionList = New ValueList;
	TransactionList.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
	TransactionList.Add(Enums.BusinessTransactions.ConsignmentProcurement);
	TransactionList.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);
	TransactionList.Add(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
	TransactionList.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	TransactionList.Add(Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit); 
	TransactionList.Add(Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
	TransactionList.Add(Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit);
	TransactionList.Add(Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit);
	TransactionList.Add(Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
	TransactionList.Add(Enums.BusinessTransactions.GoodsShipmentToCustomer);
	TransactionList.Add(Enums.BusinessTransactions.TransferOfTitleToGoods);
	TransactionList.Add(Enums.BusinessTransactions.GoodsReceiptFromCustomer);
	TransactionList.Add(Enums.BusinessTransactions.TransferToMaterialProvider2_5);
	TransactionList.Add(Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5);
	TransactionList.Add(Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
	TransactionList.Add(Enums.BusinessTransactions.GoodsQualityControl);
	
	Return TransactionList;
	
EndFunction

// The function returns a list of operations that do not use
// the "Work" type of item with the traceability attribute enabled by the CCD/ProductBatchID number.
//
// Returns:
//	ValueList - list of operations.
//
Function ListOfBusinessOfOperationsExcludingTraceableWorks() Export
	
	TransactionList = ListOfBusinessOperationsExcludingServicesAndWorks();
	TransactionList.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	
	TransactionList.Add(Enums.BusinessTransactions.PurchaseByImport);
	TransactionList.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	
	TransactionList.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	TransactionList.Add(Enums.BusinessTransactions.ImportFromEAEU);
	TransactionList.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	
	Return TransactionList;
	
EndFunction

// The function returns parameters for checking whether the item characteristics are filled in
//
//	Returns:
//		Structure  - a structure with the following keys:
//			* TSName - String - the default value is "Products".
//			* FieldNamesWithSuffix - Structure - a collection containing requesite names with a suffix. The collection key
//													is the name of the props without a suffix, for example, "Nomenclature",
//													and the value is set to the name of the props with a suffix,
//													for example, "Nomenclature".
//			* StringsList - Array of LineOfATabularSection, Undefined - the default value is Undefined.
//			* OutputLineNumbers - Boolean - the default value is True.
//			* IssueMessages - Boolean - the default value is empty TRUE - if it is FALSE, but no messages will be issued, it will simply be Rejected.
//			* ThisIsCheckOfCurrentLine - Boolean - Enables the mode of checking the row output from the table in separate input fields
//			* PathToFormTableData - String - the default value "Object" is the path to the form details containing the table part to be checked.
//																					If you check a table that is itself a form detail, you need
//																					to pass "" (i.e. an empty string).
//			* ColumnNameCharacteristicOfFormTable - String - the default value "characteristic" is the name of the column in the form table that you want
//																to display the message next to. You need to redefine when some
//																other column is displayed instead of the characteristics column, for example, with some string representations.
//
Function ParametersForCheckingWhetherCharacteristicsAreFilledIn() Export
	
	CheckParameters = New Structure;
	CheckParameters.Insert("TSName",						"Goods");
	CheckParameters.Insert("PresentationOfTS",			"");
	CheckParameters.Insert("FieldNamesWithSuffix",		New Structure);
	CheckParameters.Insert("StringsList",				Undefined);
	CheckParameters.Insert("OutputLineNumbers",		True);
	CheckParameters.Insert("SelectingRowsToCheck",		New Structure);
	CheckParameters.Insert("IssueMessages",			True);
	CheckParameters.Insert("PathToFormTableData",	"Object");
	CheckParameters.Insert("ColumnNameCharacteristicOfFormTable", "Characteristic");
	CheckParameters.Insert("ThisIsCheckOfCurrentLine",	False);
	
	Return CheckParameters;
	
EndFunction

// Procedure for checking whether the "Characteristic" columns in objects are filled in.
//
// Parameters:
//	Object  - DocumentObject, CatalogObject - object for which you want to check whether the "Characteristic" column is filled in in the table part;
//			- ClientApplicationForm - the object for which you want to check the filling of the "Characteristic" column in the table part contains, among other things:
//				* Ref - DocumentRef - 
//	NotCheckedAttributeArray - Array - banking details that don't need to be verified by platform verification;
//	Cancel - Boolean - True-indicates that the operation refused to continue;
//	CheckParameters - See ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn
//
Procedure CheckWhetherCharacteristicsAreFilledIn(Object,NotCheckedAttributeArray,Cancel,CheckParameters = Undefined) Export
	
	If Not GetFunctionalOption("UseItemVariants") Then
		Return;
	EndIf;
	
	If CheckParameters = Undefined Then
		CheckParameters = ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	EndIf;
	
	TSName                 = CheckParameters.TSName;
	FieldNamesWithSuffix  = CheckParameters.FieldNamesWithSuffix;
	StringsList           = CheckParameters.StringsList;
	OutputLineNumbers   = CheckParameters.OutputLineNumbers;
	
	NotCheckedAttributeArray.Add(TSName + ".Characteristic");
	
	If FieldNamesWithSuffix.Property("Characteristic") Then
		NotCheckedAttributeArray.Add(TSName + "." + FieldNamesWithSuffix.Characteristic);
	EndIf;
	
	If CheckParameters.ThisIsCheckOfCurrentLine Then
		// When an error is displayed, an object cannot be specified in the "element".
		DataKey  = Undefined;
		DataPath = Undefined;
	Else
		DataKey  = TMCommonUse.DataKeyForMessageToUser(Object);
		DataPath = CheckParameters.PathToFormTableData;
	EndIf;
	
	Query = New Query;
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber,
	|	&ProductNameSuffixOfAdditionalAttributes1,
	|	&CharacteristicSuffixAdditionalProps1,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic
	|INTO LinesWithErrors
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	OR &CharacteristicSuffixAdditionalProps2
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LinesWithErrors.LineNumber,
	|	&PropertySuffixOfAdditionalPropsIsNotFilledIn,
	|	CASE
	|		WHEN CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|																												VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|																												VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			AND LinesWithErrors.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef) THEN TRUE
	|		ELSE FALSE
	|	END AS CharacteristicNotFilledIn
	|FROM
	|	LinesWithErrors AS LinesWithErrors
	|WHERE
	|	CAST(LinesWithErrors.Products AS Catalog.Products).UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|																												VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|																												VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	| 	AND LinesWithErrors.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	OR &ProductNameSuffixOfAdditionalAttributes2";
	
	
	If FieldNamesWithSuffix.Count() Then
		QueryText = StrReplace(QueryText, "&ProductNameSuffixOfAdditionalAttributes1", "TableOfGoods." + FieldNamesWithSuffix.Products + " AS " + FieldNamesWithSuffix.Products);
		QueryText = StrReplace(QueryText, "&CharacteristicSuffixAdditionalProps1", "TableOfGoods." + FieldNamesWithSuffix.Characteristic + " AS " + FieldNamesWithSuffix.Characteristic);
		QueryText = StrReplace(QueryText, "&CharacteristicSuffixAdditionalProps2", "TableOfGoods." + FieldNamesWithSuffix.Characteristic + " = VALUE(Catalog.ItemsCharacteristics.EmptyRef)");
		QueryText = StrReplace(QueryText, "&PropertySuffixOfAdditionalPropsIsNotFilledIn", "
		|	CASE
		|		WHEN CAST(LinesWithErrors." + FieldNamesWithSuffix.Products + " AS Catalog.Products).UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|																																		VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
		|																																		VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
		|			AND LinesWithErrors." + FieldNamesWithSuffix.Characteristic + " = VALUE(Catalog.ItemsCharacteristics.EmptyRef) THEN TRUE
		|		ELSE FALSE
		|	END AS NotFilledIn" + FieldNamesWithSuffix.Characteristic);
		QueryText = StrReplace(QueryText, "&ProductNameSuffixOfAdditionalAttributes2", "
		|	CAST(LinesWithErrors." + FieldNamesWithSuffix.Products + " AS Catalog.Products).UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|																																		VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
		|																																		VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
		|			AND LinesWithErrors." + FieldNamesWithSuffix.Characteristic + " = VALUE(Catalog.ItemsCharacteristics.EmptyRef)");
		
	Else
		QueryText = StrReplace(QueryText, "&ProductNameSuffixOfAdditionalAttributes1,", "");
		QueryText = StrReplace(QueryText, "&CharacteristicSuffixAdditionalProps1,", "");
		QueryText = StrReplace(QueryText, "OR &CharacteristicSuffixAdditionalProps2", "");
		QueryText = StrReplace(QueryText, "&PropertySuffixOfAdditionalPropsIsNotFilledIn,", "");
		QueryText = StrReplace(QueryText, "OR &ProductNameSuffixOfAdditionalAttributes2", "");
	EndIf;
	
	Query.Text = QueryText;
	
	AdditionalBankingDetailsLine = ?(FieldNamesWithSuffix.Count(),
							"," + FieldNamesWithSuffix.Products + "," + FieldNamesWithSuffix.Characteristic,
							"");
	
	SelectingRowsToCheck_ = Undefined;
	
	If StringsList = Undefined
		And CheckParameters.SelectingRowsToCheck.Count() > 0 Then
		SelectingRowsToCheck_ = CheckParameters.SelectingRowsToCheck;
	Else
		SelectingRowsToCheck_ = StringsList;
	EndIf;
	
	Query.SetParameter("TableOfGoods",
		Object[TSName].Unload(SelectingRowsToCheck_, "LineNumber,Products,Characteristic"+AdditionalBankingDetailsLine));
		
	If CheckParameters.ThisIsCheckOfCurrentLine Then
		MessageTemplate = NStr("ru = 'Поле ""%Characteristic%"" не заполнено.';
								|vi = '""%Characteristic%"" is not filled in.';
								|en = '""%Characteristic%"" is not filled in.'; fa = '""%Characteristic%"" is not filled in.';
								|it = '""%Characteristic%"" is not filled in.';
								|pl = '""%Characteristic%"" is not filled in.';
								|tr = '""%Characteristic%"" alanı doldurulmadı.'");
	ElsIf OutputLineNumbers Then
		MessageTemplate = NStr("vi = 'Chưa điền cột ""%Characteristic%"" tại dòng %LineNumber% của danh sách ""%GoodsTable%"".';
								|ru = 'Не заполнена колонка ""%Characteristic%"" в строке %LineNumber% списка ""%GoodsTable%"".';
								|en = 'Column ""%Characteristic%"" in line %LineNumber% of the ""%GoodsTable%"" list is not filled in.'; fa = 'Column ""%Characteristic%"" in line %LineNumber% of the ""%GoodsTable%"" list is not filled in.';
								|it = 'Colonna ""%Characteristic% nella riga %LineNumber% dell''elenco ""%GoodsTable%"" non compilata.';
								|pl = 'Nie wypełniono kolumny ""%Characteristic%"" w wierszu %LineNumber% listy ""%GoodsTable%"".';
								|tr = '""%GoodsTable%"" listesinin %LineNumber% satırındaki ""%Characteristic%"" sütunu doldurulmadı.'");
	Else
		MessageTemplate = NStr("vi = 'Chưa điền cột ""%Characteristic%"" trong danh sách ""%GoodsTable%"".';
								|ru = 'Не заполнена колонка ""%Characteristic%"" в списке ""%GoodsTable%"".';
								|en = 'Column ""%Characteristic%"" in list ""%GoodsTable%"" is not filled in.'; fa = 'Column ""%Characteristic%"" in list ""%GoodsTable%"" is not filled in.';
								|it = 'Colonna non riempita ""%Characteristic%"" nella lista""%GoodsTable%"".';
								|pl = 'Nie wypełniono kolumny ""%Characteristic%"" w liście ""%GoodsTable%"".';
								|tr = '""%GoodsTable%"" listesindeki ""%Characteristic%"" sütunu doldurulmadı.'");
	EndIf;
	
	QueryResult = Query.Execute();
	
	If Not CheckParameters.IssueMessages Then
		
		If Not QueryResult.IsEmpty() Then
			Cancel = True;
		EndIf;
		
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	If TypeOf(Object) <> Type("ClientApplicationForm") Then
		ObjectMetadata = Object.Metadata();
	Else
		ObjectMetadata = Object.Ref.Metadata();
	EndIf;
	
	PresentationOfTS = ?(Not CheckParameters.Property("PresentationOfTS")
							Or Not ValueIsFilled(CheckParameters.PresentationOfTS),
						ObjectMetadata.TabularSections[TSName].Synonym,
						CheckParameters.PresentationOfTS);
	PresentationOfPropsCharacteristic = ObjectMetadata.TabularSections[TSName].Attributes.Characteristic.Synonym;
	
	While Selection.Next() Do
		
		If Selection.CharacteristicNotFilledIn Then
			
			MessageText = StrReplace(MessageTemplate, "%Characteristic%", PresentationOfPropsCharacteristic);
			MessageText = StrReplace(MessageText, "%GoodsTable%", PresentationOfTS);
			MessageText = StrReplace(MessageText, "%LineNumber%", Selection.LineNumber);
			
			Field = PathToTableField(CheckParameters,
									Selection.LineNumber,
									CheckParameters.ColumnNameCharacteristicOfFormTable);
			
			Common.MessageToUser(MessageText,
													DataKey,
													Field,
													DataPath,
													Cancel);
		EndIf;
		
		If FieldNamesWithSuffix.Property("Characteristic")
			And Selection["NotFilledIn" + FieldNamesWithSuffix.Characteristic] Then
			
			PresentationOfPropsCharacteristicOfDoP = ObjectMetadata.TabularSections[TSName].Attributes[FieldNamesWithSuffix.Characteristic].Synonym;
			
			MessageText = StrReplace(MessageTemplate, "%Characteristic%", PresentationOfPropsCharacteristicOfDoP);
			MessageText = StrReplace(MessageText, "%GoodsTable%", PresentationOfTS);
			MessageText = StrReplace(MessageText, "%LineNumber%", Selection.LineNumber);
			
			Field = PathToTableField(CheckParameters,
									Selection.LineNumber,
									FieldNamesWithSuffix.Characteristic);
			
			Common.MessageToUser(MessageText,
													DataKey,
													Field,
													DataPath,
													Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

// Procedure for checking whether the "Content" columns in forms are filled in.
//
// Parameters:
//	Object - DocumentObject - object for which you want to check whether the "Content" column is filled in in the table part;
//	Cancel - Boolean - True-indicates that the operation refused to continue;
//	TSName - String - name of the table part in the object.
//
Procedure CheckContentCompletion(Object, Cancel, TSName) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.LineNumber,
	|	TableOfGoods.Products
	|INTO LinesWithErrors
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Content = """"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LinesWithErrors.LineNumber AS LineNumber
	|FROM
	|	LinesWithErrors AS LinesWithErrors
	|WHERE
	|	LinesWithErrors.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
	|";
	Query.SetParameter("TableOfGoods", Object[TSName].Unload(,"LineNumber,Products,Content"));
	Selection = Query.Execute().Select();
	
	DataKey = TMCommonUse.DataKeyForMessageToUser(Object);
	
	ObjectMetadata = Object.Metadata();

	PresentationOfTS                 = ObjectMetadata.TabularSections[TSName].Synonym;

	MessageTemplate = NStr("vi = 'Chưa điền cột ""Nội dung"" trong dòng %LineNumber% của danh sách ""%GoodsTable%"".';
							|ru = 'Не заполнена колонка ""Содержание"" в строке %LineNumber% списка ""%GoodsTable%"".';
							|en = 'Column ""Content"" in line  %LineNumber% of the ""%GoodsTable%"" list is not filled in.'; fa = 'Column ""Content"" in line  %LineNumber% of the ""%GoodsTable%"" list is not filled in.';
							|it = 'Colonna non riempita ""Содержание"" nella riga %LineNumber% della lista ""%GoodsTable%"".';
							|pl = 'Nie wypełniono kolumny ""Opis"" w wierszu %LineNumber% listy ""%GoodsTable%"".';
							|tr = '""%GoodsTable%"" listesinin %LineNumber% satırındaki ""İçerik"" sütunu doldurulmadı.'");

	While Selection.Next() Do
					
		MessageText = StrReplace(MessageTemplate, "%GoodsTable%", PresentationOfTS);
		MessageText = StrReplace(MessageText, "%LineNumber%", Selection.LineNumber);
					
		Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "Content");
		
		CommonClientServer.MessageToUser(MessageText,DataKey,Field,"Object",Cancel);

	EndDo;
		
EndProcedure

// The function determines whether the table part contains works.
//
// Parameters:
//	TS - FormDataCollection - the table part to check.
//
// Returns:
//	Structure:
//		* ThereAreWorks - Boolean - Truth - used in the PM work.
//
Function CheckAvailabilityOfWorks(TS) Export
	
	Query = New Query();
	Query.Text =
	"SELECT 
	|	GoodsTable.Products AS Products
	|INTO GoodsTable
	|FROM 
	|	&GoodsTable AS GoodsTable
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 1 
	|	TRUE AS ThereAreWorks
	|FROM 
	|	GoodsTable AS GoodsTable
	|WHERE 
	|	CAST(GoodsTable.Products AS Catalog.Products).ItemsType 
	|	= VALUE(Enum.ItemsTypes.Work_5)";
	
	Query.SetParameter("GoodsTable", TS.Unload(, "Products"));
	QueryResult = Query.Execute();
	ItemsTypes = New Structure("ThereAreWorks", False);
	
	If Not QueryResult.IsEmpty() Then
		
		ItemsTypes.ThereAreWorks = True;
		
	EndIf;
	
	Return ItemsTypes;
	
EndFunction //Check the cash of the job()

// Returns parameters for checking the filling of packages.
//
//	Returns:
//		Structure - a structure with the following keys:
//			* TSName - String - the default value is "Products".
//			* PackagingFieldName - String - the default value is "Packaging".
//			* OtherPresentationPackagingUnits - String - the meaning of a different representation of the package, other than the synonym of the TS Attribute.
//			* OutputLineNumbers - Boolean - the default value is True.
//			* SelectingRowsToCheck - Structure - the default value is an empty Structure.
//			* FieldNamesWithSuffix - Structure - a collection containing requesite names with a suffix. The collection key
//													is the name of the props without a suffix, for example, "Nomenclature",
//													and the value is set to the name of the props with a suffix,
//													for example, "Nomenclature".
//
Function ParametersForCheckingFillingOfPackages() Export
	
	CheckParameters = New Structure;
	CheckParameters.Insert("TSName",						"Goods");
	CheckParameters.Insert("PackagingFieldName",			"Package");
	CheckParameters.Insert("OtherPresentationPackagingUnits",	"");
	CheckParameters.Insert("OutputLineNumbers",		True);
	CheckParameters.Insert("SelectingRowsToCheck",		New Structure);
	CheckParameters.Insert("FieldNamesWithSuffix",		New Structure);
	
	Return CheckParameters;
	
EndFunction

// Checks the filling of the "Packaging" columns in the documents for the address warehouse. The indication of packages is mandatory for goods
// and optional for multi-turn containers.
//
// Parameters:
//	Object	- DocumentObject, CatalogObject - the object for which you want to check the filling of the "Packaging" column in the table part.
//			- ClientApplicationForm - the object for which you want to check the filling of the "Characteristic" column in the table part contains, among other things:
//				* Ref - DocumentRef - link to the document in the information database.
//	NotCheckedAttributeArray - Array of String - Attributes that don't need to be checked by platform verification.
//	Cancel - Boolean - The truth is a sign of refusal to continue the operation.
//	CheckParameters - See ParametersForCheckingFillingOfPackages
//
Procedure CheckFillingOfPackages(Object,NotCheckedAttributeArray,Cancel,CheckParameters = Undefined) Export
	
	If Not GetFunctionalOption("UseItemPackages") Then
		Return;
	EndIf;
	
	If CheckParameters = Undefined Then
		CheckParameters = ParametersForCheckingFillingOfPackages();
	EndIf;
	
	TSName					= CheckParameters.TSName;
	PackagingFieldName			= CheckParameters.PackagingFieldName;
	OutputLineNumbers		= CheckParameters.OutputLineNumbers;
	SelectingRowsToCheck	= CheckParameters.SelectingRowsToCheck;
	FieldNamesWithSuffix	= CheckParameters.FieldNamesWithSuffix;
	
	If NotCheckedAttributeArray.Find(TSName + "." + PackagingFieldName) <> Undefined Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray.Add(TSName + "." + PackagingFieldName);
	
	If FieldNamesWithSuffix.Property("Package") Then
		NotCheckedAttributeArray.Add(TSName + "." + FieldNamesWithSuffix.Package);
	EndIf;
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber			AS LineNumber,
	|	&ProductNameSuffixOfAdditionalAttributes1,
	|	&PackagingSuffixAdditionalAttributes1,
	|	TableOfGoods.Products			AS Products,
	|	&PackagingFieldName					AS Package
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber			AS LineNumber,
	|	&ProductNameSuffixOfAdditionalAttributes1,
	|	&PackagingSuffixAdditionalAttributes1,
	|	TableOfGoods.Products			AS Products,
	|	&PackagingFieldName					AS Package
	|INTO LinesWithErrors
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|
	|WHERE
	|	ISNULL(CAST(TableOfGoods.Package AS Catalog.PackagesAndUnitsOfMeasure).MeasuredValueType, FALSE) <> VALUE(Enum.TypesOfMeasuredValues.Package)
	|	AND CAST(TableOfGoods.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND CAST(TableOfGoods.Products AS Catalog.Products).UnitOfMeasure.MeasuredValueType IN(VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces),
	|																												VALUE(Enum.TypesOfMeasuredValues.EmptyRef))
	|	OR &PackagingSuffixAdditionalAttributes2
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LinesWithErrors.LineNumber,
	|	&PackageIsNotFilledInSuffixOfAdditionalAttributes,
	|	CASE
	|		WHEN ISNULL(CAST(LinesWithErrors.Package AS Catalog.PackagesAndUnitsOfMeasure).MeasuredValueType, FALSE) <> VALUE(Enum.TypesOfMeasuredValues.Package)
	|				AND CAST(LinesWithErrors.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|				AND CAST(LinesWithErrors.Products AS Catalog.Products).UnitOfMeasure.MeasuredValueType IN(VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces),
	|																																VALUE(Enum.TypesOfMeasuredValues.EmptyRef))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS PackageIsNotFilled
	|FROM
	|	LinesWithErrors AS LinesWithErrors
	|
	|ORDER BY
	|	LineNumber";
	
	If FieldNamesWithSuffix.Count() > 0 Then
		QueryText = StrReplace(QueryText, "OR &PackagingSuffixAdditionalAttributes2", "
		|UNION
		|
		|SELECT
		|	TableOfGoods.LineNumber			AS LineNumber,
		|	&ProductNameSuffixOfAdditionalAttributes1,
		|	&PackagingSuffixAdditionalAttributes1,
		|	TableOfGoods.Products			AS Products,
		|	&PackagingFieldName					AS Package
		|FROM
		|	TTTableOfGoods AS TableOfGoods
		|
		|WHERE
		|	ISNULL(CAST(&PackagingSuffixAdditionalAttributes3 AS Catalog.PackagesAndUnitsOfMeasure).MeasuredValueType, FALSE) <> VALUE(Enum.TypesOfMeasuredValues.Package)
		|	AND CAST(&ProductNameSuffixOfAdditionalAttributes2 AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|	AND CAST(&ProductNameSuffixOfAdditionalAttributes2 AS Catalog.Products).UnitOfMeasure.MeasuredValueType IN(VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces),
		|																														VALUE(Enum.TypesOfMeasuredValues.EmptyRef))");
		
		QueryText = StrReplace(QueryText, "&PackageIsNotFilledInSuffixOfAdditionalAttributes", "CASE
		|		WHEN ISNULL(CAST(&PackagingSuffixAdditionalAttributes4 AS Catalog.PackagesAndUnitsOfMeasure).MeasuredValueType, FALSE) <> VALUE(Enum.TypesOfMeasuredValues.Package)
		|				AND CAST(&ProductNameSuffixOfAdditionalAttributes3 AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|				AND CAST(&ProductNameSuffixOfAdditionalAttributes3 AS Catalog.Products).UnitOfMeasure.MeasuredValueType IN(VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces),
		|																																	VALUE(Enum.TypesOfMeasuredValues.EmptyRef))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS PackageIsNotFilled1");
		
		QueryText = StrReplace(QueryText,
									"&ProductNameSuffixOfAdditionalAttributes1",
									"TableOfGoods." + FieldNamesWithSuffix.Products + " AS " + FieldNamesWithSuffix.Products);
		QueryText = StrReplace(QueryText,
									"&ProductNameSuffixOfAdditionalAttributes2",
									"TableOfGoods." + FieldNamesWithSuffix.Products);
		QueryText = StrReplace(QueryText,
									"&ProductNameSuffixOfAdditionalAttributes3",
									"LinesWithErrors." + FieldNamesWithSuffix.Products);
		QueryText = StrReplace(QueryText,
									"&PackagingSuffixAdditionalAttributes1",
									"TableOfGoods." + FieldNamesWithSuffix.Package + " AS " + FieldNamesWithSuffix.Package);
		QueryText = StrReplace(QueryText,
									"&PackagingSuffixAdditionalAttributes3",
									"TableOfGoods." + FieldNamesWithSuffix.Package);
		QueryText = StrReplace(QueryText,
									"&PackagingSuffixAdditionalAttributes4",
									"LinesWithErrors." + FieldNamesWithSuffix.Package);
	Else
		QueryText = StrReplace(QueryText, "OR &PackagingSuffixAdditionalAttributes2", "");
		QueryText = StrReplace(QueryText, "&ProductNameSuffixOfAdditionalAttributes1,", "");
		QueryText = StrReplace(QueryText, "&PackagingSuffixAdditionalAttributes1,", "");
		QueryText = StrReplace(QueryText, "&PackageIsNotFilledInSuffixOfAdditionalAttributes,", "");
	EndIf;
	
	QueryText = StrReplace(QueryText, "&PackagingFieldName", "TableOfGoods." + PackagingFieldName);
	
	Query = New Query;
	Query.Text = QueryText;
	
	NamesOfAdditionalAttributes = New Array;
	NamesOfAdditionalAttributes.Add(PackagingFieldName);
	
	If FieldNamesWithSuffix.Count() > 0 Then
		NamesOfAdditionalAttributes.Add(FieldNamesWithSuffix.Products);
		NamesOfAdditionalAttributes.Add(FieldNamesWithSuffix.Package);
	EndIf;
	
	NamesOfAttributesToUpload = StrConcat(NamesOfAdditionalAttributes, ", ");
	
	If SelectingRowsToCheck.Count() > 0 Then
		Query.SetParameter("TableOfGoods",
									Object[TSName].Unload(SelectingRowsToCheck, "LineNumber, Products," + NamesOfAttributesToUpload));
	Else
		Query.SetParameter("TableOfGoods",
									Object[TSName].Unload(, "LineNumber, Products, " + NamesOfAttributesToUpload));
	EndIf;
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If TypeOf(Object) <> Type("ClientApplicationForm") Then
		ObjectMetadata = Object.Metadata();
	Else
		ObjectMetadata = Object.Ref.Metadata();
	EndIf;
	
	If OutputLineNumbers Then
		MessageTemplate = NStr("vi = 'Chưa điền cột ""%Package%"" tại dòng %LineNumber% trong danh sách ""%GoodsTable%"".';
								|ru = 'Не заполнена колонка ""%Package%"" в строке %LineNumber% списка ""%GoodsTable%"".';
								|en = 'Column ""%Package%"" in line %LineNumber% of the ""%GoodsTable%"" list is not filled in.'; fa = 'Column ""%Package%"" in line %LineNumber% of the ""%GoodsTable%"" list is not filled in.';
								|it = 'Colonna ""%Package%"" nella riga %LineNumber% dell''elenco ""%GoodsTable%"" non compilata.';
								|pl = 'Nie wypełniono kolumny ""%Package%"" w wierszu %LineNumber% listy ""%GoodsTable%"".';
								|tr = '""%GoodsTable%"" listesinin %LineNumber% satırındaki ""%Package%"" sütunu doldurulmadı.'");
	Else
		MessageTemplate = NStr("vi = 'Chưa điền cột ""%Package%"" trong danh sách ""%GoodsTable%"".';
								|ru = 'Не заполнена колонка ""%Package%"" в списке ""%GoodsTable%"".';
								|en = 'Column ""%Package%"" in list ""%GoodsTable%"" is not filled in.'; fa = 'Column ""%Package%"" in list ""%GoodsTable%"" is not filled in.';
								|it = 'Colonna non riempita ""%Package%"" nella lista""%GoodsTable%"".';
								|pl = 'Nie wypełniono kolumny ""%Package%"" w liście ""%GoodsTable%"".';
								|tr = '""%GoodsTable%"" listesindeki ""%Package%"" sütunu doldurulmadı.'");
	EndIf;
	
	PresentationOfTS					= ObjectMetadata.TabularSections[TSName].Synonym;
	PresentationOfPropsPackaging	= ?(IsBlankString(CheckParameters.OtherPresentationPackagingUnits),
		ObjectMetadata.TabularSections[TSName].Attributes[PackagingFieldName].Synonym,
		CheckParameters.OtherPresentationPackagingUnits);
	
	DataKey = TMCommonUse.DataKeyForMessageToUser(Object);
	
	While Selection.Next() Do
		If Selection.PackageIsNotFilled Then
			MessageText = StrReplace(MessageTemplate,	"%Package%",		PresentationOfPropsPackaging);
			MessageText = StrReplace(MessageText,	"%GoodsTable%",	PresentationOfTS);
			MessageText = StrReplace(MessageText,	"%LineNumber%",	Selection.LineNumber);
			
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, PackagingFieldName);
			
			Common.MessageToUser(MessageText, DataKey, Field, "Object", Cancel);
		EndIf;
		
		If FieldNamesWithSuffix.Property("Package")
			And Selection.PackageIsNotFilled1 Then
			
			PresentationOfAttributesPackagingAdditional = ObjectMetadata.TabularSections[TSName].Attributes[FieldNamesWithSuffix.Package].Synonym;
			
			MessageText = StrReplace(MessageTemplate,	"%Package%",		PresentationOfAttributesPackagingAdditional);
			MessageText = StrReplace(MessageText,	"%GoodsTable%",	PresentationOfTS);
			MessageText = StrReplace(MessageText,	"%LineNumber%",	Selection.LineNumber);
			
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, FieldNamesWithSuffix.Package);
			
			Common.MessageToUser(MessageText, DataKey, Field, "Object", Cancel);
		EndIf;
	EndDo;
	
EndProcedure

// Procedure for checking whether a type of item of a different quality corresponds to the type of item of the original quality.
// For the item for which the series is recorded, products of a different quality must be of the same type as the original ones.
//
// Parameters:
//	Object - DocumentObject - the document for which the item is checked for compliance;
//	Cancel - Boolean - failure to continue the operation;
//	TSNameToCheck - String - the default value is " Products";
//	TableToCheck_ - ValueTable, Undefined - if a table of values is passed, it is checked, and no attempt is made to unload from the object:
//		* LineNumber - Number
//		* Products - CatalogRef.Products
//		* ProductsRecordingAsReceived - CatalogRef.Products
//
Procedure CheckTypeOfProductDescription(Object, Cancel, TSNameToCheck = "Goods", TableToCheck_ = Undefined) Export
	
	// The nomenclature with different quality must be compatible according to the settings of the series:
	// - either the series should have one owner (then the accounting settings are the same)
	// - or there should be no accounting of the series.
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Goods.LineNumber,
	|	Goods.Products,
	|	Goods.ProductsRecordingAsReceived AS OtherQualityGoods
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsToRequest.LineNumber,
	|	ProductsToRequest.Products,
	|	ProductsToRequest.OtherQualityGoods,
	|	CASE
	|		WHEN CAST(ProductsToRequest.Products AS Catalog.Products).BatchOwner = VALUE(Catalog.ItemKinds.EmptyRef)
	|			THEN CAST(ProductsToRequest.Products AS Catalog.Products).ProductKind
	|		ELSE CAST(ProductsToRequest.Products AS Catalog.Products).BatchOwner
	|	END AS BatchOwner,
	|	CASE
	|		WHEN CAST(ProductsToRequest.OtherQualityGoods AS Catalog.Products).BatchOwner = VALUE(Catalog.ItemKinds.EmptyRef)
	|			THEN CAST(ProductsToRequest.OtherQualityGoods AS Catalog.Products).ProductKind
	|		ELSE CAST(ProductsToRequest.OtherQualityGoods AS Catalog.Products).BatchOwner
	|	END AS OwnerOfDefectiveSeries
	|INTO ProductsToRequest
	|FROM
	|	Goods AS ProductsToRequest
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsToRequest.LineNumber,
	|	ProductsToRequest.Products AS Products,
	|	ProductsToRequest.OtherQualityGoods AS OtherQualityGoods
	|FROM
	|	ProductsToRequest AS ProductsToRequest
	|WHERE
	|	ProductsToRequest.BatchOwner <> ProductsToRequest.OwnerOfDefectiveSeries
	|	AND (ProductsToRequest.BatchOwner.KeepAccountingByBatch
	|		OR ProductsToRequest.OwnerOfDefectiveSeries.KeepAccountingByBatch)";
	
	If TableToCheck_ <> Undefined Then
		Query.SetParameter("Goods", TableToCheck_);
	Else
		Query.SetParameter("Goods",
			Object[TSNameToCheck].Unload(,"LineNumber,Products,ProductsRecordingAsReceived"));
	EndIf;
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ErrorText = NStr("vi = 'Theo mặt hàng %Products% và %OtherQualityGoods%(hàng hỏng) cài đặt ghi nhận theo sê-ri là khác nhau.';
						|ru = 'По номенклатурам %Products% и %OtherQualityGoods%(испорченный товар) различаются настройки учета по сериям.';
						|en = 'Settings of batch accounting differ for items %Products% and %OtherQualityGoods% (spoiled goods).'; fa = 'Settings of batch accounting differ for items %Products% and %OtherQualityGoods% (spoiled goods).';
						|it = 'Per gli articoli %Products% e %OtherQualityGoods% (articolo danneggiato), le impostazioni di contabilità per serie variano.';
						|pl = 'Wg nomenklatur %Products% i %OtherQualityGoods%(zepsuty towar) różnią się ustawienia ewidencji wg serii.';
						|tr = '%Products% ve %OtherQualityGoods%(hasarlı ürünler) kalemleri için, partinin muhasebe ayarları farklıdır.'");
		ErrorText = StrReplace(ErrorText, "%Products%", Selection.Products);
		ErrorText = StrReplace(ErrorText, "%OtherQualityGoods%", Selection.OtherQualityGoods);
		If TableToCheck_ = Undefined Then
			Field = CommonClientServer.PathToTabularSection(TSNameToCheck,Selection.LineNumber,"ProductsRecordingAsReceived");
			CommonClientServer.MessageToUser(ErrorText,Object,Field,,Cancel);
		Else
			CommonClientServer.MessageToUser(ErrorText,,,,Cancel);
		EndIf;
	EndDo;
	
EndProcedure

// Returns the value of the unit conversion factor to metric tons.
// For example, for a kilogram, the coefficient = 0.001.
//
// Parameters:
//	PackagingUnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - package / unit of measurement 
//		to be recalculated for.
//
// Returns:
//	Number - ratio.
//
Function TonConversionFactor(PackagingUnitOfMeasure) Export
	
	TonConversionFactor = 0;
	
	If Not ValueIsFilled(PackagingUnitOfMeasure) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Không thể tính hệ số chuyển đổi thành tấn vì đơn vị trọng lượng không được điền. Liên hệ với quản trị viên của bạn.';
												|ru = 'Не удалось рассчитать коэффициент пересчета в тонны, т.к. единица измерения веса не заполнена. Обратитесь к администратору.';
												|en = 'Cannot convert the unit to tons because ""Unit of weight"" is not specified. Please contact the administrator.'; fa = 'Cannot convert the unit to tons because ""Unit of weight"" is not specified. Please contact the administrator.';
												|it = 'Impossibile calcolare il fattore di conversione in tonnellate perché l''unità di misura del peso non è piena. Contattare l''amministratore.';
												|pl = 'Nie udało się obliczyć współczynnik przeliczenia na tony, ponieważ jednostka miary ciężaru nie jest wypełniona. Zwróć się do administratora.';
												|tr = 'Ton cinsinden dönüştürme oranı hesaplamak mümkün değildi, çünkü ağırlık birimi doldurulmadı. Yöneticiyle iletişime geç.'"));
		Return TonConversionFactor;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CASE
	|		WHEN PackagesAndUnitsOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
	|				AND PackagesAndUnitsOfMeasure.Denominator <> 0
	|			THEN PackagesAndUnitsOfMeasure.Numerator / PackagesAndUnitsOfMeasure.Denominator
	|		WHEN PackagesAndUnitsOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|				AND PackagesAndUnitsOfMeasure.WeightUnitOfMeasure.Denominator <> 0
	|			THEN PackagesAndUnitsOfMeasure.Weight * PackagesAndUnitsOfMeasure.WeightUnitOfMeasure.Numerator / PackagesAndUnitsOfMeasure.WeightUnitOfMeasure.Denominator
	|		ELSE 0
	|	END / 1000 AS TonConversionFactor
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|WHERE
	|	PackagesAndUnitsOfMeasure.Ref = &PackagingUnitOfMeasure";
	
	Query.SetParameter("PackagingUnitOfMeasure", PackagingUnitOfMeasure);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		TonConversionFactor = Selection.TonConversionFactor;
	EndIf;
	
	If TonConversionFactor = 0 Then
		MessageText = NStr("vi = 'Không thể tính hệ số chuyển đổi thành tấn cho đơn vị ""%1"". Liên hệ với quản trị viên của bạn.';
							|ru = 'Не удалось рассчитать коэффициент пересчета в тонны для единицы ""%1"". Обратитесь к администратору.';
							|en = 'Cannot calculate ratio of conversion to tons for unit ""%1"". Please contact the administrator.'; fa = 'Cannot calculate ratio of conversion to tons for unit ""%1"". Please contact the administrator.';
							|it = 'Impossibile calcolare il fattore di conversione in tonnellate per l''unità ""%1"". Contattare l''amministratore.';
							|pl = 'Nie udało się obliczyć współczynnik przeliczenia na tony dla jednostki ""%1"". Zwróć się do administratora.';
							|tr = '""%1"" birimi için ton dönüştürme oranı hesaplanamadı. Yöneticiyle iletişime geç.'");
		MessageText = StrReplace(MessageText, "%1", String(PackagingUnitOfMeasure));
		CommonClientServer.MessageToUser(MessageText);
	EndIf;
	
	Return TonConversionFactor;
	
EndFunction

// Returns the value of the unit coefficient in cubic meters.
//
// Parameters:
//  PackagingUnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - package / unit of measurement
//  	to be recalculated for.
// 
// Returns:
//  Number - conversion factor.
//
Function CubicMeterConversionFactor(PackagingUnitOfMeasure) Export
	
	CubicMeterConversionFactor = 0;
	
	If Not ValueIsFilled(PackagingUnitOfMeasure) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Không thể tính hệ số chuyển đổi thành mét khối, bởi vì đơn vị khối lượng không được điền. Liên hệ với quản trị viên của bạn.';
												|ru = 'Не удалось рассчитать коэффициент пересчета в кубические метры, т.к. единица измерения объема не заполнена. Обратитесь к администратору.';
												|en = 'Cannot convert the unit to cubic meters because ""Unit of volume"" is not specified. Please contact the administrator.'; fa = 'Cannot convert the unit to cubic meters because ""Unit of volume"" is not specified. Please contact the administrator.';
												|it = 'Impossibile calcolare il fattore di conversione in metri cubi perché l''unità di misura del volume non è piena. Contattare l''amministratore.';
												|pl = 'Nie udało się obliczyć współczynnik konwersji na metry sześcienne, ponieważ jednostka miary objętości nie została wypełniona. Skontaktuj się z administratorem.';
												|tr = 'Metreküp dönüştürme oranı hesaplanamadı çünkü hacim birimi doldurulmadı. Yöneticiyle iletişime geç.'"));
		Return CubicMeterConversionFactor;
	EndIf;

	Query = New Query;
	Query.Text = 
	"SELECT
	|	CASE
	|		WHEN PackagesAndUnitsOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
	|				AND PackagesAndUnitsOfMeasure.Denominator <> 0
	|			THEN PackagesAndUnitsOfMeasure.Numerator / PackagesAndUnitsOfMeasure.Denominator
	|		WHEN PackagesAndUnitsOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|				AND PackagesAndUnitsOfMeasure.VolumeUnitOfMeasure.Denominator <> 0
	|			THEN PackagesAndUnitsOfMeasure.VolumeM3 * PackagesAndUnitsOfMeasure.VolumeUnitOfMeasure.Numerator / PackagesAndUnitsOfMeasure.VolumeUnitOfMeasure.Denominator
	|		ELSE 0
	|	END AS CubicMeterConversionFactor
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|WHERE
	|	PackagesAndUnitsOfMeasure.Ref = &PackagingUnitOfMeasure";
	
	Query.SetParameter("PackagingUnitOfMeasure", PackagingUnitOfMeasure);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		CubicMeterConversionFactor = Selection.CubicMeterConversionFactor;
	EndIf;
	
	If CubicMeterConversionFactor = 0 Then
		MessageText = NStr("vi = 'Không thể tính hệ số chuyển đổi theo mét khối cho đơn vị ""%1"". Liên hệ với quản trị viên của bạn.';
							|ru = 'Не удалось рассчитать коэффициент пересчета в кубические метры для единицы ""%1"". Обратитесь к администратору.';
							|en = 'Cannot calculate a ratio of conversion to cubic meters for unit ""%1"". Please contact the administrator.'; fa = 'Cannot calculate a ratio of conversion to cubic meters for unit ""%1"". Please contact the administrator.';
							|it = 'Impossibile calcolare il fattore di conversione in metro cubo per l''unità ""%1"". Contattare l''amministratore.';
							|pl = 'Nie udało się obliczyć współczynnik przeliczenia na metry sześcienne dla jednostki ""%1"". Zwróć się do administratora.';
							|tr = '""%1"" birimi için metreküp dönüştürme oranı hesaplanamadı. Yöneticiyle iletişime geç.'");
		MessageText = StrReplace(MessageText, "%1", String(PackagingUnitOfMeasure));
		CommonClientServer.MessageToUser(MessageText);
	EndIf;
	
	Return CubicMeterConversionFactor;
	
EndFunction

// Defines the supported item types by document selection parameters
// 
// Parameters:
//  Ref - DocumentRef - Defines the type of document for which you want to get the appropriate item types
//  TabularSectionName - String - Name of the tabular part where the item is stored
//  NameOfProductItemDetails - String - Name Of The Product Item Details
// 
// Returns:
//  Array of EnumRef.ItemsTypes - Supported Document Item Types
Function SupportedDocumentItemTypes(Ref, TabularSectionName = "Goods", NameOfProductItemDetails = "Products") Export

	ChoiceParameters = Ref.Metadata().TabularSections[TabularSectionName].Attributes[NameOfProductItemDetails].ChoiceParameters;
	
	ReturnValue = Undefined;
	For Each ChoiceParameter In ChoiceParameters Do
		If ChoiceParameter.Name = "Filter.ItemsType" Then
			If TypeOf(ChoiceParameter.Value) = Type("FixedArray") Then
				ReturnValue = ChoiceParameter.Value;
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	If ReturnValue = Undefined Then
		// All values:
		ReturnValue = ProductsClientServer.SelectionByProductReusablePackagingServiceWork(True);
	EndIf;
	
	Return ReturnValue;
	
EndFunction

#Region ProceduresForWorkingWithSeries

// The procedure fills in the series indication statuses in the PM goods lines (the comment contains a description of the series subsystem).
//  
//  Possible series indication statuses:
//  
//  -1 - series are indicated in the clarification table (no picture)
//  0 - series is not required to be specified (no picture)
//  the first specified status - the number of series does not match the number of products or series are not specified (red picture)
//  the second specified status - the number of series matches the number of products (green picture)
//  the third specified status - the series are not specified, they can be specified, or they can not be specified (blue picture)
// 	 1,2,21 - the series are indicated for reference
// 	 3,4,23 - the leftovers are taken into account for the series, the series are indicated upon selection
// 	 5,6,25 - residues are taken into account by series, the series are indicated when planning the selection,
// 		 are filled in according to FEFO (used only in documents of shipment of goods)
// 	 7,8,27 - residues are taken into account by series, the series are indicated when planning the selection
// 	 9,10,11 - balances are taken into account by series, series are indicated when planning shipment,
//  	movements are formed by series according to the register of goods for shipment (both at arrival and at consumption)
//   13,14,15 - are taken into account as well as 9,10,11 + cost is taken into account by series
//   17,18,28 - according to the series, goods from partners are taken into account (goods in transit, unfactured deliveries)
//   19,20,22 - according to the series, goods from partners are taken into account (goods in transit, unfactured deliveries).
//
// Parameters:
//  Object						 - FormDataStructure, DocumentObject - the object in which you need to fill in statuses.
//  SeriesSpecificationParameters		 - Structure - The composition of the fields is set by the Nomenclature Clientserver function.Parameters
//  	of the series (see the description of the fields in the comments to this function).
//  RowsOfProductsToProcess	 - Array - product lines where you need to fill in the statuses for specifying the series
//  	. if "Undefined" is passed, the statuses are filled in in all product lines.
//  SeriesRowsToProcess		 - Array - series lines that need to be used to fill in the statuses for specifying series
//  	. if "Undefined" is passed, all series lines are taken into account.
//
Procedure FillInStatusesForSpecifyingSeries(Object,
											SeriesSpecificationParameters,
											RowsOfProductsToProcess = Undefined,
											SeriesRowsToProcess = Undefined) Export
	
	If Not (SeriesSpecificationParameters.ProductInHeader
		Or Object[SeriesSpecificationParameters.NameTSGoods].Count() <> 0 ) Then
		Return;
	EndIf;
	
	If Not SeriesSpecificationParameters.UseItemsBatch Then
		
		If GetFunctionalOption("UseItemsBatch") Then
			If SeriesSpecificationParameters.ProductInHeader Then
				Object.BatchesIndicationStatus = 0;	
			Else
				For Each RowOfTables In Object[SeriesSpecificationParameters.NameTSGoods] Do
					If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
						RowOfTables.BatchesIndicationStatus = 0;
					Else
						For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
							RowOfTables[NameOfStatusField] = 0;
						EndDo;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		Return;
	EndIf;
	
	VHFWarehouses = SeriesSpecificationParameters.LinkFields.Find(SeriesSpecificationParameters.WarehouseFieldName) <> Undefined
		Or SeriesSpecificationParameters.AdditionalFieldNames.Find(SeriesSpecificationParameters.WarehouseFieldName) <> Undefined;
	
	If Not VHFWarehouses
		And SeriesSpecificationParameters.WarehouseFieldName <> Undefined Then
		
		If SeriesSpecificationParameters.NameOfSenderWarehouseField <> Undefined
			And SeriesSpecificationParameters.NameOfRecipientWarehouseField <> Undefined Then
			Warehouse = New Structure("Sender,Recipient");
			Warehouse.Sender = Object[SeriesSpecificationParameters.NameOfSenderWarehouseField];
			Warehouse.Recipient  = Object[SeriesSpecificationParameters.NameOfRecipientWarehouseField];
		Else
			Warehouse = Object[SeriesSpecificationParameters.WarehouseFieldName];
		EndIf;
		
	Else
		Warehouse = Undefined;
	EndIf;
	
	If SeriesSpecificationParameters.ProductInHeader Then
		
		TableOfGoods = New ValueTable;
		TableOfGoods.Columns.Add("Products",New TypeDescription("CatalogRef.Products"));
		TableOfGoods.Columns.Add("Characteristic",New TypeDescription("CatalogRef.ItemsCharacteristics"));
		TableOfGoods.Columns.Add("Series",New TypeDescription("CatalogRef.ItemsBatches"));
		TableOfGoods.Columns.Add("Count",TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
		TableOfGoods.Columns.Add("LineNumber",New TypeDescription("Number",New NumberQualifiers(5,0,AllowedSign.Nonnegative)));
		
		If ValueIsFilled(SeriesSpecificationParameters.TSSeriesName) Then
			TableOfSeries = Object[SeriesSpecificationParameters.TSSeriesName];
		Else
			TableOfSeries = New ValueTable;
			TableOfSeries.Columns.Add("Products",New TypeDescription("CatalogRef.Products"));
			TableOfSeries.Columns.Add("Characteristic",New TypeDescription("CatalogRef.ItemsCharacteristics"));
			TableOfSeries.Columns.Add("Series",New TypeDescription("CatalogRef.ItemsBatches"));
			TableOfSeries.Columns.Add("Purpose",New TypeDescription("CatalogRef.Assignments"));
			TableOfSeries.Columns.Add("Count",TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
			
			RowSeries = TableOfSeries.Add();
			FillPropertyValues(RowSeries, Object);
		EndIf;
		
		CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, TableOfGoods);
		
		RowOfProduct = TableOfGoods.Add();
		FillPropertyValues(RowOfProduct,Object);
		If SeriesSpecificationParameters.ThisIsOrder
			And SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipSetsForDisassembly) <> Undefined
			And Not Object.WithAssignment Then
			// In the order header, when changing the security option, the destination is not cleared,
			//	so for an unsociable shipment, we will clear the destination here.
			RowOfProduct.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
		RowOfProduct.LineNumber = 1;
		
		TheStructureOfTheSearch = New Structure("Products, Characteristic, Purpose");
		FillPropertyValues(TheStructureOfTheSearch, RowOfProduct);
		FoundSeriesRows_ = TableOfSeries.FindRows(TheStructureOfTheSearch);
		
		Selection = SelectionFromRequestForCalculatingStatusesForSpecifyingSeries(SeriesSpecificationParameters,
																TableOfGoods,
																TableOfSeries,
																Warehouse,
																,
																FoundSeriesRows_);
		
		If Selection.Next() Then
			
			Object.BatchesIndicationStatus = Selection.BatchesIndicationStatus;
			
			FieldStatuses = New Array;
			
			FieldStatuses.Add(14);
			FieldStatuses.Add(18);
			FieldStatuses.Add(20);
			If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ProductRM) <> Undefined Then
				FieldStatuses.Add(2);
				FieldStatuses.Add(21);
			EndIf;
			If FieldStatuses.Find(Selection.BatchesIndicationStatus) = Undefined Then
				Object.Series = Catalogs.ItemsBatches.EmptyRef();
			EndIf;
		EndIf;
	Else
		
		Selection = SelectionFromRequestForCalculatingStatusesForSpecifyingSeries(SeriesSpecificationParameters,
																Object[SeriesSpecificationParameters.NameTSGoods],
																Object[SeriesSpecificationParameters.TSSeriesName],
																Warehouse,
																RowsOfProductsToProcess,
																SeriesRowsToProcess);
		
		While Selection.Next() Do
			RowOfTables = Object[SeriesSpecificationParameters.NameTSGoods][Selection.LineNumber - 1];
			If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
				RowOfTables.BatchesIndicationStatus = Selection.BatchesIndicationStatus;
			Else
				For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
					RowOfTables[NameOfStatusField] = Selection[NameOfStatusField];
				EndDo;
			EndIf;
			
		EndDo;
	EndIf;
	
EndProcedure

// The procedure recalculates the status of specifying series in product lines, if necessary,
//  and reassigns the series lines to other lines of the PM "Products".
//
// Parameters:
//  Object						 - FormDataStructure	 - the main details of the document form.
//  SeriesSpecificationParameters		 - Structure - structure of parameters for specifying series returned by the corresponding procedure in the document Manager module.
//  IDCurrentRow	 - Number - ID of the current product line in the document form.
//  CachedValues		 - Structure - structure of the cache of details of the current product line.
//
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,
																			SeriesSpecificationParameters,
																			IDCurrentRow,
																			CachedValues) Export
	
	If Not SeriesSpecificationParameters.UseItemsBatch Then
		Return;
	EndIf;
	
	If SeriesSpecificationParameters.NameTSGoods = SeriesSpecificationParameters.TSSeriesName Then
		Return; // If there is no PM Series, then all statuses are recalculated when the PM details are changed, and not at the end of editing
	EndIf;
	
	If IDCurrentRow <> Undefined Then
		CurrentRow = Object[SeriesSpecificationParameters.NameTSGoods].FindByID(IDCurrentRow); // DocumentTabularSectionRow.DiscrepancyReportFollowingReceipt.Goods - specified for typing
	Else
		CurrentRow = Undefined //so the line was deleted;
	EndIf;
	
	LinkFieldText = "";
	
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		LinkFieldText = LinkFieldText + "," + ArrRow  ;
	EndDo;
	
	ThereArePackages = SeriesSpecificationParameters.LinkFields.Find("Package") <> Undefined; 
	
	// If the line is new (including copied) or the division by sales options is used, it will be cached Undefined
	// Then there is no need to search for rows with old values.
	If CachedValues.Products <> Undefined Then
		
		SearchStructureOldValues = New Structure("Products,Characteristic"+LinkFieldText);
		FillPropertyValues(SearchStructureOldValues,CachedValues);
		
		FoundProductLines = Object[SeriesSpecificationParameters.NameTSGoods].FindRows(SearchStructureOldValues);
		FoundSeriesRows_ = Object[SeriesSpecificationParameters.TSSeriesName].FindRows(SearchStructureOldValues);
	Else
		FoundProductLines = New Array;
		FoundSeriesRows_   = New Array;
	EndIf;
	
	// If the key fields have changed:
	// - perhaps you need to reassign the series
	// - the status of specifying the series needs to be recalculated in rows by new key fields and by old ones.
	If CurrentRow <> Undefined 
		And Not TMCommonUseClientServer.StructuresAreEqual(CachedValues, CurrentRow, "Products,Characteristic"+LinkFieldText) Then
		
		ConsiderBalance      = False;
		ReassignSeries    = False;
		RecalculateQuantity = False;
		// Let's determine whether it is necessary to reassign the series. This is necessary if:
		// - the series referred to only one line
		// - new and old key fields support the same accounting policy
		// - the series referred to several lines, but the meaning of the action to reflect the discrepancy with the line has changed
		// If the lines need to be reassigned, then we will determine whether the quantity needs to be recalculated.
		If CachedValues.Products <> Undefined
			And ((CachedValues.Property("Action")
					And CachedValues.Action <> CurrentRow.Action)
				Or FoundProductLines.Count() = 0) Then//since there are no lines with such key fields left, it means there was only one such line
			
			If FoundProductLines.Count() > 0 Then
				ConsiderBalance   = True;
				ReassignSeries = True;
			ElsIf CachedValues.Products = CurrentRow.Products Then //that is, the fields on which the accounting policy does not depend have changed
				ReassignSeries = True;
			Else //we will reassign, if the type of nomenclature has not changed
				CurProductType = Common.ObjectAttributeValue(CachedValues.Products,"ProductKind");
				NewTypeOfProducts   = Common.ObjectAttributeValue(CurrentRow.Products, "ProductKind");
				
				ReassignSeries = (CurProductType = NewTypeOfProducts);
			EndIf;
			
			If ReassignSeries
				And ThereArePackages
				And CachedValues.Package <> CurrentRow.Package Then
				
				RecalculateQuantity = True;
				
			EndIf;
			
		EndIf;	
		
		// If the row is deleted, then Undefined will be passed as the current values
		// Then there is no need to search for rows with new values.
		SearchStructureNewValues = New Structure("Products,Characteristic"+LinkFieldText);
		FillPropertyValues(SearchStructureNewValues,CurrentRow);
		
		FoundProductLinesAreNew = Object[SeriesSpecificationParameters.NameTSGoods].FindRows(SearchStructureNewValues);    
		
		// Let's add rows by new key fields to the array of rows to recalculate the status of specifying the series.
		
		// When combining arrays, we will bypass the smaller array
		If FoundProductLines.Count() < FoundProductLinesAreNew.Count() Then
			For Each ArrRow In FoundProductLines Do
				FoundProductLinesAreNew.Add(ArrRow);
			EndDo;
			FoundProductLines = FoundProductLinesAreNew;
		Else
			For Each ArrRow In FoundProductLinesAreNew Do
				FoundProductLines.Add(ArrRow);
			EndDo;
		EndIf;
		
		// Let's define an array of series rows that should participate in the recalculation of statuses,
		If ReassignSeries Then		
			// First, we will reassign the series
			
			If ConsiderBalance Then
				If CurrentRow.CountByDocument > CurrentRow.Count Then
					CountBalance = CurrentRow.Count;
				Else
					
					ThereAreNewSeries = False;
					
					NumberOfRowsWithExcess = 0;
					
					For Each ArrRow In FoundSeriesRows_ Do
						If ArrRow.CountByDocument = 0 Then
							ThereAreNewSeries = True;
						ElsIf ArrRow.CountByDocument < ArrRow.Count Then
							NumberOfRowsWithExcess = NumberOfRowsWithExcess + 1;
						EndIf;
					EndDo;
					
					If ThereAreNewSeries
						And NumberOfRowsWithExcess > 0 Then //Let's reassign the number of series minus the number of lines with surpluses
						
						CountBalance = CurrentRow.CountByDocument - NumberOfRowsWithExcess;
						
					ElsIf ThereAreNewSeries Then //Reassign the number of series equal to the number of series in the document
						CountBalance = CurrentRow.CountByDocument;
					Else //Reassign the number of series equal to the actual number of series in the processed line
						CountBalance = CurrentRow.CountByDocument
											- (CurrentRow.Count - CurrentRow.CountByDocument);
					EndIf;
					
				EndIf;
			EndIf;
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateNumberOfPackages");
			
			For Each ArrRow In FoundSeriesRows_ Do
				
				If ConsiderBalance Then
					If CountBalance > 0
						Or ArrRow.Count <> ArrRow.CountByDocument Then
						
						CountBalance = CountBalance - ArrRow.Count;
						
						FillPropertyValues(ArrRow, CurrentRow, LinkFieldText);
					EndIf;
				Else
					FillPropertyValues(ArrRow, CurrentRow, "Products,Characteristic" + LinkFieldText);
				EndIf;
				
				
			EndDo;
			
			If RecalculateQuantity Then
				BatchProcessingOfTablePartServer.ProcessTSStrings(
					FoundSeriesRows_,
					StructureOfActions,
					Object[SeriesSpecificationParameters.TSSeriesName],
					CachedValues);
			EndIf;
			
			If Not ConsiderBalance Then
				// If the series are reassigned, then it is enough to search for new search fields
				FoundSeriesRows_ = Object[SeriesSpecificationParameters.TSSeriesName].FindRows(SearchStructureNewValues);
			EndIf;
			
		Else	
			FoundSeriesRowsAreNew = Object[SeriesSpecificationParameters.TSSeriesName].FindRows(SearchStructureNewValues);
			
			// If the series are not reassigned, then the rows for the old key fields should be added to the rows for the new key fields.
			
			// When combining arrays, we will bypass the smaller array
			If FoundSeriesRows_.Count() < FoundSeriesRowsAreNew.Count() Then
				For Each ArrRow In FoundSeriesRows_ Do
					FoundSeriesRowsAreNew.Add(ArrRow);
				EndDo;
				FoundSeriesRows_ = FoundSeriesRowsAreNew;
			Else
				For Each ArrRow In FoundSeriesRowsAreNew Do
					FoundSeriesRows_.Add(ArrRow);
				EndDo;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If FoundProductLines.Count() > 0 Then 
		FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters,FoundProductLines,FoundSeriesRows_);
	EndIf;
	
EndProcedure

// The procedure recalculates the statuses of specifying series for the product in the document header, and if necessary, reassigns
// the series lines.
//
// Parameters:
//  Object					 - FormDataStructure	 - the main details of the document form.
//  SeriesSpecificationParameters	 - Structure - structure of parameters for specifying series returned by the corresponding procedure in the document Manager module.
//  CachedValues	 - Structure - structure of the cache of details of the current product line.
//
Procedure FillInStatusesOfSpecifyingSeriesWhenChangingProductInHeader(Object, Val SeriesSpecificationParameters, CachedValues) Export
	
	LinkFieldText = "";
	
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		LinkFieldText = LinkFieldText + "," + ArrRow;
	EndDo;
	
	ThereArePackages = SeriesSpecificationParameters.LinkFields.Find("Package") <> Undefined; 
	
	// If the key fields have changed:
	// - perhaps you need to reassign the series
	// - the status of specifying the series needs to be recalculated in rows by new key fields and by old ones.
	
	KeyFieldsChanged = False;
	
	If CachedValues.ProductHeader <> Object.Products
		Or CachedValues.CharacteristicCap <> Object.Characteristic
		Or CachedValues.DestinationHeader_ <> Object.Purpose Then
		
		KeyFieldsChanged = True;
		
	Else
		For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
			NameOfProductHeaderField = ProductsClientServer.NameOfProductHeaderField(ArrRow);
			
			If CachedValues[NameOfProductHeaderField] <> Object[ArrRow] Then
				KeyFieldsChanged = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	RecalculateStatus = False;

	If KeyFieldsChanged Then
		
		ReassignSeries    = False;
		RecalculateQuantity = False;
		// Let's determine whether it is necessary to reassign the series. This is necessary if:
		// - the series referred to only one line
		// - new and old key fields support the same accounting policy
		// If the lines need to be reassigned, then we will determine whether the quantity needs to be recalculated.
		
		If CachedValues.ProductHeader = Object.Products Then //that is, the fields on which the accounting policy does not depend have changed
			ReassignSeries = True;
		Else //we will reassign, if the type of nomenclature has not changed
			CurProductType = Common.ObjectAttributeValue(CachedValues.ProductHeader,"ProductKind");
			NewTypeOfProducts   = Common.ObjectAttributesValues(Object.Products, "ProductKind");
			
			ReassignSeries = (CurProductType = NewTypeOfProducts);
			RecalculateStatus  = Not (CurProductType = NewTypeOfProducts);
		EndIf;
		
		If ReassignSeries
			And ThereArePackages
			And CachedValues.PackingCap <> Object.Package Then
			
			RecalculateQuantity = True;
			
		EndIf;
		
		If ReassignSeries Then
			
			If ValueIsFilled(SeriesSpecificationParameters.TSSeriesName) Then
				
				SearchStructureOldValues = New Structure("Products,Characteristic"+LinkFieldText);
				For Each KeyAndValue In SearchStructureOldValues Do
					NameOfProductHeaderField = ProductsClientServer.NameOfProductHeaderField(KeyAndValue.Key);
					
					SearchStructureOldValues[KeyAndValue.Key] = CachedValues[NameOfProductHeaderField];
				EndDo;
				
				FoundSeriesRows_ = Object[SeriesSpecificationParameters.TSSeriesName].FindRows(SearchStructureOldValues);
				
				For Each ArrRow In FoundSeriesRows_ Do
					
					FillPropertyValues(ArrRow,Object, "Products,Characteristic"+LinkFieldText);
					
					If RecalculateQuantity Then
						BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesInTSLine(
							ArrRow,
							New Structure("RecalculateNumberOfPackages"),
							CachedValues);
					EndIf;
					
				EndDo;
				
			EndIf;
			
		Else
			Object.Series = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
		
	EndIf;
	
	If ThereArePackages Then
		If CachedValues.NumberOfPackagesCap <> Object.NumberOfPackages Then
			RecalculateStatus = True;
		EndIf;
	Else
		If CachedValues.NumberOfCaps <> Object.Count Then
			RecalculateStatus = True;
		EndIf;
	EndIf;
	
	If RecalculateStatus Then 
		FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters,Undefined,Undefined);
	EndIf;
	
EndProcedure

// The procedure deletes PM "Series" lines that do not have corresponding lines in PM "Products" for the link fields
//  , or the status of specifying series in these lines is 0 (do not specify).
//
// Parameters:
//  DocumentObject			 - FormDataCollection, DocumentObject - Document object to delete unused series lines in.
//  SeriesSpecificationParameters	 - Structure - LongDesc See ProductsClientServer.SeriesSpecificationParameters.
//
Procedure ClearUnusedSeries(DocumentObject, SeriesSpecificationParameters) Export
	
	If Not GetFunctionalOption("UseItemsBatch") Then
		Return;
	EndIf;
	
	If SeriesSpecificationParameters.Property("Header")
		Or SeriesSpecificationParameters.ProductInHeader Then 
		ClearUnusedSeriesBasedOnItemInHeader(DocumentObject, SeriesSpecificationParameters);
	Else
		ClearUnusedSeriesWHGoods(DocumentObject, SeriesSpecificationParameters, DocumentObject[SeriesSpecificationParameters.NameTSGoods]);
		ClearUnusedSeriesWHSeries(DocumentObject, SeriesSpecificationParameters, DocumentObject[SeriesSpecificationParameters.NameTSGoods].Unload());
	EndIf;
	
EndProcedure

// If by series for the transferred Items/If the cost price is taken into account, it calculates the status of specifying the series.
//  Checks whether the specified series belongs to the passed item.
//
// Parameters:
//  CurrentRow			 - Structure - for which the status of specifying series is calculated;
//  Warehouse					 - CatalogRef.Warehouses	 - warehouse for which the status of specifying series is calculated;
//  SeriesSpecificationParameters	 - Structure				 - the structure described in the function Nomenclaturales.Parametrizatsii.
// 
// Returns:
//  Structure - a structure with the following keys:
//  * Series - CatalogRef.ItemsBatches - if the series is specified and it can be used with a new item value
//  	in the specified warehouse, the passed value is returned, if not, an empty link.
//  * BatchesIndicationStatus - Number - if the series is specified in the PM "Goods", the calculated status is returned
//  	. if the series is not used for the transferred item/warehouse, 0 is returned
//  	otherwise, the transmitted status is returned.
//
Function CheckAndCalculateStatusWhenChangingDetailsOfVHF(CurrentRow, Warehouse, SeriesSpecificationParameters) Export
	
	ObjectMetadata = TMCommonUse.ObjectMetadataByFullName(SeriesSpecificationParameters.FullObjectName);
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Series");
	ReturnStructure.Insert("SpecifyBatches");
	
	ReturnStructure.Series = CurrentRow.Series;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TRUE AS DifferentOwnersOfSeriesAndProducts
	|FROM
	|	Catalog.Products AS Products,
	|	Catalog.ItemsBatches AS SetOfSeries
	|WHERE
	|	Products.Ref = &Products
	|	AND SetOfSeries.Ref = &Series
	|	AND NOT(SetOfSeries.ProductKind.BatchOwner = Products.ProductKind.BatchOwner
	|					AND SetOfSeries.ProductKind.BatchOwner <> VALUE(Catalog.ItemKinds.EmptyRef)
	|					AND Products.ProductKind.BatchOwner <> VALUE(Catalog.ItemKinds.EmptyRef)
	|				OR Products.BatchOwner = SetOfSeries.ProductKind
	|				OR Products.ProductKind = SetOfSeries.ProductKind)";
	Query.SetParameter("Products", CurrentRow.Products);
	Query.SetParameter("Series", CurrentRow.Series);
	If Not Query.Execute().IsEmpty() Then
		ReturnStructure.Series = Catalogs.ItemsBatches.EmptyRef();
	EndIf;
	
	If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
		ReturnStructure.Insert("BatchesIndicationStatus");
	Else
		For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
			ReturnStructure.Insert(NameOfStatusField);
		EndDo;
	EndIf;
	
	If Not SeriesSpecificationParameters.UseItemsBatch Then
		
		ReturnStructure.Series               = Catalogs.ItemsBatches.EmptyRef();
		If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
			ReturnStructure.BatchesIndicationStatus = 0;
		Else
			For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
				ReturnStructure[NameOfStatusField] = 0;
			EndDo;
		EndIf;
		ReturnStructure.SpecifyBatches      = False;
		
		Return ReturnStructure;
	EndIf;
	
	TypeProducts = New TypeDescription("CatalogRef.Products");
	TypeOfProductCharacteristics = New TypeDescription("CatalogRef.ItemsCharacteristics");
	ProductSeriesType = New TypeDescription("CatalogRef.ItemsBatches");
	
	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("Products", TypeProducts);
	TableOfGoods.Columns.Add("Characteristic", TypeOfProductCharacteristics);
	TableOfGoods.Columns.Add("Series", ProductSeriesType);
	
	If SeriesSpecificationParameters.FieldNamesWithSuffix.Count() Then
		FieldNamesWithSuffix = SeriesSpecificationParameters.FieldNamesWithSuffix;
		
		If FieldNamesWithSuffix.Property("Products") Then
			AttributeName = FieldNamesWithSuffix.Products;
			
			AddColumnToProductTable(TableOfGoods, AttributeName, TypeProducts);
		EndIf;
		
		If FieldNamesWithSuffix.Property("Characteristic") Then
			AttributeName = FieldNamesWithSuffix.Characteristic;
			
			AddColumnToProductTable(TableOfGoods, AttributeName, TypeOfProductCharacteristics);
		EndIf;
		
		If FieldNamesWithSuffix.Property("Series") Then
			AttributeName = FieldNamesWithSuffix.Series;
			
			AddColumnToProductTable(TableOfGoods, AttributeName, ProductSeriesType);
		EndIf;
	EndIf;
	
	TableOfGoods.Columns.Add(SeriesSpecificationParameters.FieldNameQuantity,TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
	TableOfGoods.Columns.Add("LineNumber",New TypeDescription("Number",New NumberQualifiers(5,0,AllowedSign.Nonnegative)));
	
	CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, TableOfGoods, ObjectMetadata);
	
	TableOfSeries = New ValueTable;
	TableOfSeries.Columns.Add("Products",New TypeDescription("CatalogRef.Products"));
	TableOfSeries.Columns.Add("Characteristic",New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfSeries.Columns.Add(SeriesSpecificationParameters.FieldNameQuantity,TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
	
	CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, TableOfSeries, ObjectMetadata, True);
	
	RowOfProduct = TableOfGoods.Add();
	FillPropertyValues(RowOfProduct,CurrentRow);
	RowOfProduct.LineNumber = 1;
	RowOfProduct.Series = ReturnStructure.Series;
	
	Selection = SelectionFromRequestForCalculatingStatusesForSpecifyingSeries(SeriesSpecificationParameters, TableOfGoods, TableOfSeries, Warehouse);
	
	If Selection.Next() Then
		
		// If the series are specified in a separate PM, then when the details are changed
		// , only the statuses associated with the series specified
		// in PM "Goods" (i.e., for which cost accounting is maintained) will be recalculated.
		If ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(Selection.BatchesIndicationStatus, SeriesSpecificationParameters) Then
			
			If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
				ReturnStructure.BatchesIndicationStatus = Selection.BatchesIndicationStatus;
			Else
				For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
					ReturnStructure[NameOfStatusField] = Selection[NameOfStatusField];
				EndDo;
			EndIf;
			
		Else
			
			If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
				ReturnStructure.BatchesIndicationStatus = CurrentRow.BatchesIndicationStatus;
			Else
				For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
					ReturnStructure[NameOfStatusField] = CurrentRow[NameOfStatusField];
				EndDo;
			EndIf;
			
		EndIf;
		
		If ProductsClientServer.NoSeriesAreSpecifiedInThisStatus(ReturnStructure.BatchesIndicationStatus, SeriesSpecificationParameters) Then
			ReturnStructure.SpecifyBatches = False;
			ReturnStructure.Series = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
		
	Else
		If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
			ReturnStructure.BatchesIndicationStatus = CurrentRow.BatchesIndicationStatus;
		Else
			For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
				ReturnStructure[NameOfStatusField] = CurrentRow[NameOfStatusField];
			EndDo;
		EndIf;
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// The procedure selects the FEFO series and fills in the selected PM values for the " Series"
//  Document movements are taken into account, and filled-in series are re-filled.
//
// Parameters:
//  Object							 - FormDataCollection, DocumentObject - the object in which you need to fill in statuses.
//  SeriesSpecificationParameters			 - Structure - parameters for specifying series returned by the corresponding procedure in the document Manager module.
//  StatusesOfSpecifyingSeriesAreFilledIn	 - Boolean - if the statuses for specifying the series in PM are not filled in.
//
Procedure FillInSeriesByFEFO(Object,SeriesSpecificationParameters, StatusesOfSpecifyingSeriesAreFilledIn = True) Export
	
	If Not SeriesSpecificationParameters.UseItemsBatch Then
		Return;
	EndIf;
	
	If Object[SeriesSpecificationParameters.NameTSGoods].Count() = 0 Then
		Return;
	EndIf;
	
	
	If Not StatusesOfSpecifyingSeriesAreFilledIn Then
        ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
    EndIf;
	
	If SeriesSpecificationParameters.NameTSGoods = SeriesSpecificationParameters.TSSeriesName Then
			FillSeriesOnFefoTWhProducts(Object, SeriesSpecificationParameters);
	Else
		FillSeriesByFefoUHFSeries(Object, SeriesSpecificationParameters);
	EndIf;	
		
EndProcedure

// The function checks whether there are rows in the PM "Products" for which the series are filled in by FEFO.
//
// Parameters:
//  TS	 - FormDataCollection	 - the object's PM being checked.
// 
// Returns:
//  Boolean - a sign of the presence of FEFO-filled lines in the PM "Goods".
//
Function ThereAreLinesWithFEFOFilledSeries(TS) Export
	Return TS.FindRows(New Structure("BatchesIndicationStatus",6)).Count() > 0;	
EndFunction

// The function checks whether there are lines in the PM "Products" for which the series can be filled in by FEFO.
//
// Parameters:
//  TS	 - FormDataCollection	 - the object's PM being checked.
// 
// Returns:
//  Boolean - a sign of the presence in the PM "Goods" of lines for which the series can be filled in by FEFO.
//
Function ThereAreLinesWithFEFOFilledSeries_(TS) Export
	Return TS.FindRows(New Structure("BatchesIndicationStatus",6)).Count() > 0
		Or TS.FindRows(New Structure("BatchesIndicationStatus",5)).Count() > 0
		Or TS.FindRows(New Structure("BatchesIndicationStatus",25)).Count() > 0;
EndFunction

// Checks whether the policy for specifying series in the transferred warehouse provides for specifying series
//  and checks whether the series belongs.
//
// Parameters:
//  Warehouse							 - CatalogRef.Warehouses	 - warehouse where the item is stored;
//  Products					 - CatalogRef.Products - nomenclature;
//  Series							 - CatalogRef.ItemsBatches	 - item series;
//  NameOfSeriesAccountingPolicyParameter	 - String								 - name of the series accounting policy detail to check
//  								the status of specifying series for.
// 
// Returns:
//  Structure - a structure with the following keys:
//  *BatchesIndicationStatus - String - the status indication of the series;
//  *Series - CatalogRef.ItemsBatches - if the series belongs to the same type of item,
//  	then the transmitted series, otherwise - an empty link.
//
Function SeriesIsSpecifiedCorrectly(Warehouse, Products, Series, NameOfSeriesAccountingPolicyParameter) Export
	Result = New Structure("BatchesIndicationStatus,Series");
		
	Query = New Query;
	Query.Text =
	"SELECT
	|	TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy." + NameOfSeriesAccountingPolicyParameter + "
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.ItemKinds.BatchAccountingPolicies AS TypesOfProductPolicyAccountingSeries
	|		ON Products.ProductKind = TypesOfProductPolicyAccountingSeries.Ref
	|WHERE
	|	Products.Ref = &Products
	|	AND TypesOfProductPolicyAccountingSeries.Warehouse = &Warehouse
	|	AND TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy." + NameOfSeriesAccountingPolicyParameter;
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("Warehouse", Warehouse);
	
	If Query.Execute().IsEmpty() Then
		Result.BatchesIndicationStatus = 0;
	Else
		If NameOfSeriesAccountingPolicyParameter = "CostAccountingByBatches" Then
			Result.BatchesIndicationStatus = 14;
		ElsIf NameOfSeriesAccountingPolicyParameter = "SpecifyWhenPlanningShipment" Then 
			Result.BatchesIndicationStatus = 10;
		ElsIf NameOfSeriesAccountingPolicyParameter = "SpecifyWhenPlanningPicking" Then
			Result.BatchesIndicationStatus = 8;
		ElsIf NameOfSeriesAccountingPolicyParameter = "BatchesAccountingByFEFO" Then
			Result.BatchesIndicationStatus = 6;
		ElsIf NameOfSeriesAccountingPolicyParameter = "SpecifyByPickingResult" Then
			Result.BatchesIndicationStatus = 4;
		Else
			Result.BatchesIndicationStatus = 2;
		EndIf;
	EndIf;
	
	If Result.BatchesIndicationStatus = 0 Then
		Result.Series = Catalogs.ItemsBatches.EmptyRef();
	Else
		If Common.ObjectAttributeValue(Series, "ProductKind")
			 = Common.ObjectAttributeValue(Products, "ProductKind") Then
			Result.Series = Series;
		Else
			Result.Series = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

// For the specified parameters, the function returns the status of specifying the series.
//
// Parameters:
//	Warehouse - CatalogRef.Warehouses - warehouse for which the status of specifying series is calculated;
//	Products - CatalogRef.Products - the item for which the status of specifying series is calculated;
//	NameOfSeriesAccountingPolicyParameter - String - the name of the policy setting that you want to validate.
//
// Returns:
//	Number - the status of specifying the series.
//
Function StatusOfSeriesIndication(Warehouse, Products, NameOfSeriesAccountingPolicyParameter) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy.UseCostAccountingByBatches 	AS UseCostAccountingByBatches,
	|	TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy.SpecifyWhenPlanningShipment 	AS SpecifyWhenPlanningShipment,
	|	TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy.SpecifyWhenPlanningPicking 	AS SpecifyWhenPlanningPicking,
	|	TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy.BatchesAccountingByFEFO 					AS BatchesAccountingByFEFO,
	|	TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy.SpecifyByPickingResult 			AS SpecifyByPickingResult
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.ItemKinds.BatchAccountingPolicies AS TypesOfProductPolicyAccountingSeries
	|		ON Products.ProductKind = TypesOfProductPolicyAccountingSeries.Ref
	|WHERE
	|	Products.Ref = &Products
	|	AND TypesOfProductPolicyAccountingSeries.Warehouse = &Warehouse
	|	AND TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy." + NameOfSeriesAccountingPolicyParameter;
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("Warehouse", Warehouse);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		BatchesIndicationStatus = 0;
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		If Selection.UseCostAccountingByBatches Then 
			BatchesIndicationStatus = 14;
		ElsIf Selection.SpecifyWhenPlanningShipment Then 
			BatchesIndicationStatus = 10;
		ElsIf Selection.SpecifyWhenPlanningPicking Then
			BatchesIndicationStatus = 8;
		ElsIf Selection.BatchesAccountingByFEFO Then
			BatchesIndicationStatus = 6;
		ElsIf Selection.SpecifyByPickingResult Then
			BatchesIndicationStatus = 4;
		Else
			BatchesIndicationStatus = 2;
		EndIf;
	EndIf;
	
	Return BatchesIndicationStatus;
	
EndFunction

// The function returns parameters for checking whether the item characteristics are filled in
//
//	Returns:
//		Structure  - a structure with the following keys:
//			* IssueMessages - Boolean - the default value is TRUE. If FALSE, then no messages will be issued,
//											just a Refusal will be issued.
//			* PresentationOfTS - String - representation of the table part being checked. If the parameter value is not specified,
//											then the view takes the value equal to the synonym OF the Attribute
//											OF the metadata object.
//			* PropsNameSeries - String - representation of the Attributes of the series being checked. If the parameter value is not specified,
//											then the view takes the value equal to the synonym OF the Attribute
//											OF the metadata object.
//			* PathToFormTableData - String - the default value "object" is the path to the form Attribute containing
//													the table part to be checked. if the table is checked, which itself
//													is the Attribute of the form, you need to pass "" (i.e. an empty string).
//
Function SeriesFillCheckParameters() Export
	
	CheckParameters = New Structure;
	CheckParameters.Insert("IssueMessages",			True);
	CheckParameters.Insert("PresentationOfTS",			"");
	CheckParameters.Insert("PropsNameSeries",			"");
	CheckParameters.Insert("PathToFormTableData",	"Object");
	
	Return CheckParameters;
	
EndFunction

// The procedure checks whether the product series are specified correctly by status in the PM " Products"
//  If the status
//  	1 - the number of lots does not match the number of goods (and of the series do not need)
//  	3 - the number of lots does not match the number of goods (it is necessary to do movements series)
//  	5 - the number of lots does not match the number of goods (you need to make traffic series, a series filled according to FEFO terms)
//  	7 - the number of lots does not match the number of goods (of a series are specified in the planning selection)
//  	9 - the number of lots does not match the number of goods (of a series are specified in shipping planning)
//  	13-the quantity for the series does not match the number of products or the series is not specified (accounting for the cost of the series)
// 			, an error is issued.
//
// Parameters:
//  DocumentObject - DocumentObject, ClientApplicationForm - the object where you want to check the indication of the series.
//  SeriesSpecificationParameters - Structure, An array Of the Series specification parameter structure returned by the corresponding procedure of the document manager module.
//  Cancel - Boolean - indicates a verification error.
//  NotCheckedAttributeArray - Array of String, String - array of names of Attributes to exclude from platform verification.
//  Issue messages - Boolean - a sign that you need to issue verification error messages.
//  CheckParameters - See SeriesFillCheckParameters
//
Procedure CheckSeriesCompletion(DocumentObject, Val SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray = Undefined, CheckParameters = Undefined) Export

	If TypeOf(SeriesSpecificationParameters) = Type("Structure") Then
		ArrayOfParametersForSpecifyingSeries = New Array;
		ArrayOfParametersForSpecifyingSeries.Add(SeriesSpecificationParameters);
		SeriesSpecificationParameters = ArrayOfParametersForSpecifyingSeries;
	EndIf;
	
	If CheckParameters = Undefined Then
		CheckParameters = SeriesFillCheckParameters();
	EndIf;
	
	MetadataOfDocument = TMCommonUse.ObjectMetadataByFullName(SeriesSpecificationParameters[0].FullObjectName);
	
	If NotCheckedAttributeArray <> Undefined Then
		For Each Parameters In SeriesSpecificationParameters Do
			If Parameters.ProductInHeader Then
				NotCheckedAttributeArray.Add("Series");
			Else
				NotCheckedAttributeArray.Add(StrTemplate("%1.Series", Parameters.NameTSGoods));
			EndIf;
			
			If Parameters.FieldNamesWithSuffix.Count() Then
				FieldNamesWithSuffix = Parameters.FieldNamesWithSuffix;
				
				If FieldNamesWithSuffix.Property("Series") Then
					FieldNameSeries = FieldNamesWithSuffix.Series;
					
					If TypeOf(FieldNameSeries) = Type("Array") Then
						For Each Name In FieldNameSeries Do
							NotCheckedAttributeArray.Add(StrTemplate("%1.%2", Parameters.NameTSGoods, Name));
						EndDo;
					Else
						If Parameters.ProductInHeader Then
							NotCheckedAttributeArray.Add(StrTemplate("%1", FieldNameSeries));
						Else
							NotCheckedAttributeArray.Add(StrTemplate("%1.%2", Parameters.NameTSGoods, FieldNameSeries));
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If (CommonClientServer.HasAttributeOrObjectProperty(DocumentObject, "AdditionalProperties")
			And CommonClientServer.HasAttributeOrObjectProperty(DocumentObject.AdditionalProperties, "FillCheckDisableSeriesControl")) Then
		Return;
	EndIf;
	
	DataKey = TMCommonUse.DataKeyForMessageToUser(DocumentObject);
	ArrayOfRequestTexts = New Array;
	OutcomeTables = New Array;
	Query = New Query;
	
	For Each Parameters In SeriesSpecificationParameters Do
		
		If Not Parameters.UseItemsBatch Then
			Continue;
		EndIf;
		
		QueryNumber = SeriesSpecificationParameters.Find(Parameters);
		
		If Parameters.ProductInHeader Then
			
			If ProductsClientServer.SeriesStatusesSeriesNotSpecified().Find(DocumentObject.BatchesIndicationStatus) <> Undefined
				And DocumentObject.BatchesIndicationStatus <> 13
				And Parameters.NameTSGoods <> Parameters.TSSeriesName Then
				
				MessageText = NStr("vi = 'Số lượng sản phẩm ""%OwnGoods%"" không tương ứng với số lượng sê-ri được chỉ định cho sản phẩm đó. Sửa lại sê-ri.';
									|ru = 'Количество товара ""%OwnGoods%"" не соответствует указанному для него количеству серий. Исправьте серии.';
									|en = 'Quantity of the %OwnGoods% goods does not correspond to the quantity of batch specified for them. Correct the batch.'; fa = 'Quantity of the %OwnGoods% goods does not correspond to the quantity of batch specified for them. Correct the batch.';
									|it = 'La quantità di merce ""%OwnGoods%"" non corrisponde al numero di serie specificato per esso. Correggi le serie.';
									|pl = 'Ilość towaru ""%OwnGoods%"" nie odpowiada wskazanej dla niego ilości serii. Popraw serie.';
									|tr = '""%OwnGoods%"" ürünün miktarı, kendisi için belirtilen parti sayısıyla eşleşmiyor. Partiyi düzelt.'");
					
				MessageText = StrReplace(MessageText,
					"%OwnGoods%", ProductsClientServer.ProductPresentation(DocumentObject.Products, DocumentObject.Characteristic));
				
				Common.MessageToUser(MessageText,
														DataKey,
														"Products",
														CheckParameters.PathToFormTableData,
														Cancel);
				
			ElsIf DocumentObject.BatchesIndicationStatus = 1
				Or DocumentObject.BatchesIndicationStatus = 13 Then
				
				FieldNameSeries = ?(Parameters.FieldNamesWithSuffix.Count() > 0
									And FieldNamesWithSuffix.Property("Series"),
								FieldNamesWithSuffix.Series,
								"Series");
				PropsNameSeries = ?(IsBlankString(CheckParameters.PropsNameSeries),
										MetadataOfDocument.Attributes[FieldNameSeries].Synonym,
										CheckParameters.PropsNameSeries);
				
				MessageText = NStr("vi = 'Chưa điền trường ""%1""';
									|ru = 'Поле ""%1"" не заполнено';
									|en = 'Field ""%1"" cannot be empty.'; fa = 'Field ""%1"" cannot be empty.';
									|it = 'Il campo ""%1"" non è compilato';
									|pl = 'Pole ""%1"" nie jest wypełnione';
									|tr = '""%1"" alanı doldurulmamış'");
				MessageText = StrTemplate(MessageText, PropsNameSeries);
				
				Common.MessageToUser(MessageText,
														DataKey,
														FieldNameSeries,
														CheckParameters.PathToFormTableData,
														Cancel);
				
			EndIf;
			
			ProductsLocalization.CheckSeriesCompletion(DocumentObject, Parameters, Cancel, NotCheckedAttributeArray, CheckParameters);
			
		ElsIf Parameters.NameTSGoods = Parameters.TSSeriesName Then
			
			If Parameters.SpecialCheckingOfSeriesIndicationStatuses Then
				
				// In the texts of arbitrary queries, all temporary tables must be destroyed except for the "Query Series table".
				ManagerModule = Common.ObjectManagerByFullName(Parameters.FullObjectName);
				QueryText =	ManagerModule.TextOfRequestToCheckSeriesFilling(Parameters);
				
				NumberOfSubqueries = StrOccurrenceCount(QueryText, ";") + 1;
				For Counter = 1 To NumberOfSubqueries Do
					OutcomeTables.Add(String(New UUID));
				EndDo;
				
			Else
				
				QueryText = 
					"SELECT
					|	TableOfSeries.LineNumber AS LineNumber,
					|	TableOfSeries.Products AS Products,
					|	TableOfSeries.Characteristic AS Characteristic,
					|	TableOfSeries.Series AS Series,
					|	""Series"" AS FieldNameSeries,
					|	&PackagingFieldName AS Package,
					|	&FieldNameQuantity AS NumberOfPackages
					|INTO SeriesTableForQuery
					|FROM
					|	&TableOfSeries_QueryNumber AS TableOfSeries
					|WHERE
					|	TableOfSeries.BatchesIndicationStatus > 0
					|	AND NOT TableOfSeries.BatchesIndicationStatus IN (&SeriesStatusesYouCanSpecifySeries)";
				
				UsePackages = Parameters.ProductLocationsAreUsed
										Or Parameters.LinkFields.Find("Package") <> Undefined;
				QueryText = StrReplace(QueryText,
											"&PackagingFieldName",
											?(UsePackages,
												"TableOfSeries.Package",
												"VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)"));
				QueryText = StrReplace(QueryText,
											"&FieldNameQuantity",
											"TableOfSeries." + Parameters.FieldNameQuantity);
				
				OutcomeTables.Add("SeriesTableForQuery" + QueryNumber);
				
			EndIf;
			
			QueryText = QueryText + Common.QueryBatchSeparator() +
				"SELECT
				|	SeriesTableForQuery.Products AS Products,
				|	SeriesTableForQuery.Characteristic AS Characteristic,
				|	SeriesTableForQuery.Series AS Series,
				|	SeriesTableForQuery.FieldNameSeries AS FieldNameSeries,
				|	CASE
				|		WHEN ISNULL(PackagesAndUnitsOfMeasure.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
				|			THEN SeriesTableForQuery.Package
				|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
				|	END AS Package,
				|	SUM(CASE
				|			WHEN ISNULL(PackagesAndUnitsOfMeasure.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
				|				THEN SeriesTableForQuery.NumberOfPackages / PackagesAndUnitsOfMeasure.NumberOfPackages
				|			ELSE SeriesTableForQuery.NumberOfPackages
				|		END) AS Count
				|INTO ProductsWithErrorsInQuantity
				|FROM
				|	SeriesTableForQuery AS SeriesTableForQuery
				|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
				|		ON SeriesTableForQuery.Package = PackagesAndUnitsOfMeasure.Ref
				|WHERE
				|	NOT CAST(SeriesTableForQuery.Products AS Catalog.Products).ProductKind.SpecifyQuantityWhenRegisteringBatch
				|
				|GROUP BY
				|	SeriesTableForQuery.Products,
				|	SeriesTableForQuery.Characteristic,
				|	SeriesTableForQuery.Series,
				|	SeriesTableForQuery.FieldNameSeries,
				|	CASE
				|		WHEN ISNULL(PackagesAndUnitsOfMeasure.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
				|			THEN SeriesTableForQuery.Package
				|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
				|	END
				|
				|HAVING
				|	SUM(CASE
				|			WHEN ISNULL(PackagesAndUnitsOfMeasure.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
				|				THEN SeriesTableForQuery.NumberOfPackages / PackagesAndUnitsOfMeasure.NumberOfPackages
				|			ELSE SeriesTableForQuery.NumberOfPackages
				|		END) > 1
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	PRESENTATION(SeriesTableForQuery.Products) AS ProductsPresentation,
				|	SeriesTableForQuery.Series AS Series,
				|	SeriesTableForQuery.Series = VALUE(Catalog.ItemsBatches.EmptyRef) AS SeriesIsNotFilled,
				|	NOT ProductsWithErrorsInQuantity.Products IS NULL AS QuantityError,
				|	CASE
				|		WHEN ISNULL(PackagesAndUnitsOfMeasure.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
				|			THEN FALSE
				|		ELSE ISNULL(PackagesAndUnitsOfMeasure.Numerator, 1) / ISNULL(PackagesAndUnitsOfMeasure.Denominator, 1) <> 1
				|	END AS PackagingError,
				|	ISNULL(PackagesAndUnitsOfMeasure.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem) AS ItIsACargoItem,
				|	ISNULL(PackagesAndUnitsOfMeasure.NumberOfPackages, 0) AS NumberOfItems,
				|	ISNULL(ProductsWithErrorsInQuantity.Count, 0) AS SeriesCount,
				|	SeriesTableForQuery.FieldNameSeries AS FieldNameSeries,
				|	SeriesTableForQuery.LineNumber AS LineNumber
				|FROM
				|	SeriesTableForQuery AS SeriesTableForQuery
				|		LEFT JOIN ProductsWithErrorsInQuantity AS ProductsWithErrorsInQuantity
				|		ON (ProductsWithErrorsInQuantity.Products = SeriesTableForQuery.Products)
				|			AND (ProductsWithErrorsInQuantity.Characteristic = SeriesTableForQuery.Characteristic)
				|			AND (ProductsWithErrorsInQuantity.Series = SeriesTableForQuery.Series)
				|			AND (ProductsWithErrorsInQuantity.FieldNameSeries = SeriesTableForQuery.FieldNameSeries)
				|			AND (CASE
				|				WHEN ProductsWithErrorsInQuantity.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
				|					THEN TRUE
				|				ELSE ProductsWithErrorsInQuantity.Package = SeriesTableForQuery.Package
				|			END)
				|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
				|		ON SeriesTableForQuery.Package = PackagesAndUnitsOfMeasure.Ref
				|WHERE
				|	NOT CAST(SeriesTableForQuery.Products AS Catalog.Products).ProductKind.SpecifyQuantityWhenRegisteringBatch
				|		AND (NOT ProductsWithErrorsInQuantity.Products IS NULL
				|			OR CASE
				|				WHEN ISNULL(PackagesAndUnitsOfMeasure.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
				|					THEN FALSE
				|				ELSE ISNULL(PackagesAndUnitsOfMeasure.Numerator, 1) / ISNULL(PackagesAndUnitsOfMeasure.Denominator, 1) <> 1
				|			END) 
				|	OR NOT ProductsWithErrorsInQuantity.Products IS NULL
				|	OR SeriesTableForQuery.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
				|
				|
				|ORDER BY
				|	SeriesTableForQuery.LineNumber
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP SeriesTableForQuery
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP ProductsWithErrorsInQuantity";
			
			If TypeOf(DocumentObject[Parameters.NameTSGoods]) = Type("ValueTable") Then
				TableOfSeries = DocumentObject[Parameters.NameTSGoods].Copy(Parameters.SelectingRowsToCheck);
			Else
				TableOfSeries = DocumentObject[Parameters.NameTSGoods].Unload(Parameters.SelectingRowsToCheck);
			EndIf;
			
			ParameterName = "TableOfSeries_" + QueryNumber;
			QueryText = StrReplace(QueryText, "TableOfSeries_QueryNumber", ParameterName);
			Query.SetParameter(ParameterName, TableOfSeries);
			
			Query.SetParameter("SeriesStatusesYouCanSpecifySeries",
										ProductsClientServer.SeriesStatusesYouCanSpecifySeries());
			
			ArrayOfRequestTexts.Add(QueryText);
			
			OutcomeTables.Add("ProductsWithErrorsInQuantity" + QueryNumber);
			OutcomeTables.Add("Result" + QueryNumber);
			OutcomeTables.Add("DestroySeriesTableForQuery" + QueryNumber);
			OutcomeTables.Add("DestroyGoodsWithErrorsInQuantity" + QueryNumber);
			
		Else
			
			QueryText = 
				"SELECT
				|	&TextOfProductsSelectionField,
				|	TableOfGoods.Products AS Products,
				|	TableOfGoods.Characteristic AS Characteristic,
				|	&NameOfQuantityProductsField AS Count,
				|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
				|	TableOfGoods.LineNumber AS LineNumber
				|INTO TableOfGoods
				|FROM
				|	&TableOfGoods_QueryNumber AS TableOfGoods
				|
				|WHERE
				|	TableOfGoods.BatchesIndicationStatus IN (&SeriesStatusesSeriesNotSpecified)
				|
				|INDEX BY
				|	&TextOfProductsSelectionField,
				|	Products,
				|	Characteristic
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	&TextOfProductsSelectionField,
				|	&NameOfUnitField AS UnitOfMeasure,
				|	TableOfGoods.Products AS Products,
				|	TableOfGoods.Characteristic AS Characteristic,
				|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
				|	SUM(TableOfGoods.Count) AS Count
				|INTO TableOfProductsToRequest
				|FROM
				|	TableOfGoods AS TableOfGoods
				|
				|GROUP BY
				|	&TextOfProductsSelectionField,
				|	TableOfGoods.Products,
				|	TableOfGoods.Characteristic,
				|	TableOfGoods.BatchesIndicationStatus
				|
				|INDEX BY
				|	&TextOfProductsSelectionField,
				|	Products,
				|	Characteristic
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	&TextOfSeriesSelectionField,
				|	TableOfSeries.Series AS Series,
				|	TableOfSeries.Products AS Products,
				|	TableOfSeries.Characteristic AS Characteristic,
				|	&FieldNameNumberOfSeries AS Count
				|INTO TableOfSeries
				|FROM
				|	&TableOfSeries_QueryNumber AS TableOfSeries
				|
				|INDEX BY
				|	&TextOfSeriesSelectionField,
				|	Products,
				|	Characteristic
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	&TextOfSeriesSelectionField,
				|	TableOfSeries.Products AS Products,
				|	TableOfSeries.Characteristic AS Characteristic,
				|	SUM(TableOfSeries.Count) AS Count
				|INTO SeriesTableForQuery
				|FROM
				|	TableOfSeries AS TableOfSeries
				|
				|GROUP BY
				|	&TextOfSeriesSelectionField,
				|	TableOfSeries.Products,
				|	TableOfSeries.Characteristic
				|
				|INDEX BY
				|	&TextOfSeriesSelectionField,
				|	Products,
				|	Characteristic
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ISNULL(SeriesTableForQuery.Count, 0) AS SeriesCount,
				|	TableOfProductsToRequest.Count AS GoodsQuantity,
				|	TableOfGoods.LineNumber AS LineNumber,
				|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
				|	TableOfGoods.BatchesIndicationStatus = 13
				|		OR &SeriesWhenPlanningShipmentWHGoodsAreIndicated_QueryNumber
				|			AND TableOfGoods.BatchesIndicationStatus = 9 AS NoErrorSpecified,
				|	ISNULL(SeriesTableForQuery.Count, 0) <> TableOfProductsToRequest.Count AS ErrorDoesNotEqualQuantity,
				|	PRESENTATION(TableOfGoods.Products) AS Products,
				|	PRESENTATION(TableOfGoods.Characteristic) AS Characteristic,
				|	PRESENTATION(TableOfProductsToRequest.UnitOfMeasure) AS UnitOfMeasure
				|FROM
				|	TableOfGoods AS TableOfGoods
				|		INNER JOIN TableOfProductsToRequest AS TableOfProductsToRequest
				|		ON &LinkFieldTextConnectionProductsAllProducts
				|			AND TableOfGoods.Products = TableOfProductsToRequest.Products
				|			AND TableOfGoods.Characteristic = TableOfProductsToRequest.Characteristic
				|		LEFT JOIN SeriesTableForQuery AS SeriesTableForQuery
				|		ON &CommunicationFieldTextConnectionProductsSeries
				|			AND TableOfGoods.Products = SeriesTableForQuery.Products
				|			AND TableOfGoods.Characteristic = SeriesTableForQuery.Characteristic
				|WHERE
				|	(TableOfGoods.BatchesIndicationStatus = 13
				|			OR &SeriesWhenPlanningShipmentWHGoodsAreIndicated_QueryNumber
				|				AND TableOfGoods.BatchesIndicationStatus = 9
				|			OR ISNULL(SeriesTableForQuery.Count, 0) <> TableOfProductsToRequest.Count)
				|
				|ORDER BY
				|	LineNumber
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP TableOfGoods
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP TableOfProductsToRequest
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP TableOfSeries
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP SeriesTableForQuery";
			
			If Parameters.LinkFields.Count() = 0 Then
				LinkFieldTextConnectionProductsAllProducts = "TRUE";
				CommunicationFieldTextConnectionProductsSeries = "TRUE";
				TextOfProductsSelectionField = "TRUE,";
				TextOfSeriesSelectionField = "TRUE,";
			Else
				CommunicationFieldsConnectionSeriesItems = New Array;
				For Each LinksField In Parameters.LinkFields Do
					CommunicationFieldsConnectionSeriesItems.Add(StrTemplate("TableOfGoods.%1 = SeriesTableForQuery.%1", LinksField));
				EndDo;
				CommunicationFieldTextConnectionProductsSeries = StrConcat(CommunicationFieldsConnectionSeriesItems, "
					|			AND ");
				LinkFieldTextConnectionProductsAllProducts = StrReplace(CommunicationFieldTextConnectionProductsSeries, "SeriesTableForQuery", "TableOfProductsToRequest");
				TextOfProductsSelectionField = StrTemplate("TableOfGoods.%1,", StrConcat(Parameters.LinkFields, ",
					|	TableOfGoods."));
				TextOfSeriesSelectionField = StrTemplate("TableOfSeries.%1,", StrConcat(Parameters.LinkFields, ",
					|	TableOfSeries."));
			EndIf;
			
			QueryText = StrReplace(QueryText, "&TextOfProductsSelectionField,", TextOfProductsSelectionField);
			QueryText = StrReplace(QueryText, "&TextOfSeriesSelectionField,", TextOfSeriesSelectionField);
			QueryText = StrReplace(QueryText, "&CommunicationFieldTextConnectionProductsSeries", CommunicationFieldTextConnectionProductsSeries);
			QueryText = StrReplace(QueryText, "&LinkFieldTextConnectionProductsAllProducts", LinkFieldTextConnectionProductsAllProducts);
			QueryText = StrReplace(QueryText, "&NameOfQuantityProductsField", "TableOfGoods." + Parameters.FieldNameQuantity);
			QueryText = StrReplace(QueryText, "&FieldNameNumberOfSeries", "TableOfSeries." + Parameters.FieldNameQuantity);
			QueryText = StrReplace(QueryText, "&NameOfUnitField",
				?(Parameters.LinkFields.Find("Package") <> Undefined, "TableOfGoods.Package", "CAST(TableOfGoods.Products AS Catalog.Products).UnitOfMeasure"));
			
			If Parameters.Property("SelectingRowsToCheck") Then
				TableOfGoods = DocumentObject[Parameters.NameTSGoods].Unload(Parameters.SelectingRowsToCheck);
			Else
				TableOfGoods = DocumentObject[Parameters.NameTSGoods].Unload();
			EndIf;
			ParameterName = "TableOfGoods_" + QueryNumber;
			QueryText = StrReplace(QueryText, "TableOfGoods_QueryNumber", ParameterName);
			Query.SetParameter(ParameterName, TableOfGoods);
			
			Query.SetParameter("SeriesStatusesSeriesNotSpecified", ProductsClientServer.SeriesStatusesSeriesNotSpecified());
			
			ParameterName = "TableOfSeries_" + QueryNumber;
			QueryText = StrReplace(QueryText, "TableOfSeries_QueryNumber", ParameterName);
			Query.SetParameter(ParameterName, DocumentObject[Parameters.TSSeriesName].Unload());
			
			SeriesWhenPlanningShipmentWHGoodsAreIndicated = Not Parameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated;
			ParameterName = "SeriesWhenPlanningShipmentWHGoodsAreIndicated_" + QueryNumber;
			QueryText = StrReplace(QueryText, "SeriesWhenPlanningShipmentWHGoodsAreIndicated_QueryNumber", ParameterName);
			Query.SetParameter(ParameterName, SeriesWhenPlanningShipmentWHGoodsAreIndicated);
			
			PresentationOfTS = ?(IsBlankString(CheckParameters.PresentationOfTS),
								MetadataOfDocument.TabularSections[Parameters.NameTSGoods].Synonym,
								CheckParameters.PresentationOfTS);
			ThereAreAttributeBatch = MetadataOfDocument.TabularSections[Parameters.NameTSGoods].Attributes.Find("Series") <> Undefined;
			
			ArrayOfRequestTexts.Add(QueryText);
			
			OutcomeTables.Add("TableOfGoods" + QueryNumber);
			OutcomeTables.Add("TableOfProductsToRequest" + QueryNumber);
			OutcomeTables.Add("TableOfSeries" + QueryNumber);
			OutcomeTables.Add("SeriesTableForQuery" + QueryNumber);
			OutcomeTables.Add("Result" + QueryNumber);
			OutcomeTables.Add("DestroyGoodsTable" + QueryNumber);
			OutcomeTables.Add("DestroyGoodsTableForQuery" + QueryNumber);
			OutcomeTables.Add("DestroySeriesTable" + QueryNumber);
			OutcomeTables.Add("DestroySeriesTableForQuery" + QueryNumber);
			
		EndIf;
		
	EndDo;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return;
	EndIf;
	QueryText = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	Query.Text = QueryText;
	QueryResult = Query.ExecuteBatch();
	
	For Each Parameters In SeriesSpecificationParameters Do
		
		If Not Parameters.UseItemsBatch Then
			Continue;
		EndIf;
		
		QueryNumber = SeriesSpecificationParameters.Find(Parameters);
		ResultIndex = OutcomeTables.Find("Result" + QueryNumber);
		If ResultIndex = Undefined Then
			Continue;
		EndIf;
		Result = QueryResult[ResultIndex];
		PresentationOfTS = ?(IsBlankString(CheckParameters.PresentationOfTS),
						MetadataOfDocument.TabularSections[Parameters.NameTSGoods].Synonym,
						CheckParameters.PresentationOfTS);
									
		If Parameters.NameTSGoods = Parameters.TSSeriesName Then
			
			Selection = Result.Select();
				
			If CheckParameters.IssueMessages Then
				
				While Selection.Next() Do
					If Selection.SeriesIsNotFilled Then
						
						PropsNameSeries = ?(IsBlankString(CheckParameters.PropsNameSeries),
												MetadataOfDocument.TabularSections[Parameters.NameTSGoods].Attributes[Selection.FieldNameSeries].Synonym,
												CheckParameters.PropsNameSeries);
						
						MessageTemplate = NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 của danh sách ""%3""';
												|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3""';
												|en = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.'; fa = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.';
												|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata';
												|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3""';
												|tr = '""%2"" listesinin %3 satırındaki ""%1"" sütunu doldurulmadı'");
						MessageText = StrTemplate(MessageTemplate, PropsNameSeries, Format(Selection.LineNumber, "NZ=0; NG="), PresentationOfTS);
						
						Field = CommonClientServer.PathToTabularSection(Parameters.NameTSGoods, Selection.LineNumber, Selection.FieldNameSeries);
						Common.MessageToUser(MessageText, DataKey, Field, CheckParameters.PathToFormTableData, Cancel);
						Continue;
					EndIf;
					If Selection.QuantityError Then
						If Selection.ItIsACargoItem Then
							MessageTemplate = NStr("vi = 'Chính sách kế toán sê-ri hàng hóa ""%1"" quy định rằng, số lượng mặt hàng sẽ tương ứng với số lượng hàng hóa bằng 1, tức là %2';
													|ru = 'Политика учета серий товара ""%1"" предусматривает, что количество товарных мест будет соответствовать количеству товара равному 1, т.е. %2';
													|en = 'According to the batch accounting policy of the ""%1"" item, the number of cargo items matches the number of items equal to 1, that is, %2'; fa = 'According to the batch accounting policy of the ""%1"" item, the number of cargo items matches the number of items equal to 1, that is, %2';
													|it = 'Политика учета серий товара ""%1"" предусматривает, что количество товарных мест будет соответствовать количеству товара равному 1, т.е. %2';
													|pl = 'According to the batch accounting policy of the ""%1"" item, the number of cargo items matches the number of items equal to 1, that is, %2';
													|tr = '""%1"" ürün partisi için toplu muhasebe politikası, kargo paketlerinin sayısının 1''e eşit ürün sayısına karşılık gelmesini sağlar, yani %2'");
							MessageText = StrTemplate(MessageTemplate, Selection.ProductsPresentation, Format(Selection.NumberOfItems, "NZ=0; NG="));
						Else
							MessageTemplate = NStr("vi = 'Số lượng được chỉ định của hàng hóa ""%1"" với sê-ri ""%2"" bằng %3. Chính sách ghi nhận sê-ri của hàng hóa này quy định rằng, số lượng theo sê-ri bất kỳ của hàng hóa này sẽ luôn bằng 1.';
													|ru = 'Указанное количество товара ""%1"" с серией ""%2"" равно %3. Политика учета серий данного товара предусматривает, что количество по любой серии этого товара всегда будет равно 1.';
													|en = 'The specified quantity of the ""%1"" item with batch ""%2"" is equal to %3. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.'; fa = 'The specified quantity of the ""%1"" item with batch ""%2"" is equal to %3. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
													|it = 'Указанное количество товара ""%1"" с серией ""%2"" равно %3. Политика учета серий данного товара предусматривает, что количество по любой серии этого товара всегда будет равно 1.';
													|pl = 'The specified quantity of the ""%1"" item with batch ""%2"" is equal to %3. According to the batch accounting policy of this item, the quantity by any item batch always equals 1.';
													|tr = '""%2"" partisine sahip ""%1"" ürünün belirtilen miktarı %3''tür. Bu ürün için toplu muhasebe politikası, bu ürünün herhangi bir partisi için miktarın her zaman 1 olacağını öngörür.'");
							MessageText = StrTemplate(MessageTemplate, Selection.ProductsPresentation, Selection.Series, Format(Selection.SeriesCount, "NZ=0; NG="));
						EndIf;
						// It is not universal, because in all documents where the reference series are indicated only in the same PM as the
						// goods, there is a field for the quantity of packages.
						Field = CommonClientServer.PathToTabularSection(Parameters.NameTSGoods, Selection.LineNumber, "NumberOfPackages");
						Common.MessageToUser(MessageText, DataKey, Field, CheckParameters.PathToFormTableData, Cancel);
					EndIf;
					If Selection.PackagingError Then
						MessageTemplate = NStr("vi = 'Chính sách kế toán sê-ri của hàng hóa ""%1"" quy định rằng, chỉ ra sê-ri đối với mỗi mặt hàng. Hãy chỉ ra đóng gói theo đơn vị trong dòng %2 của danh sách ""%3"".';
												|ru = 'Политика учета серий товара ""%1"" предусматривает, что серии указываются для каждого экземпляра. Укажите единичную упаковку в строке %2 списка ""%3"".';
												|en = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit in line %2 of the ""%3"" list.'; fa = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit in line %2 of the ""%3"" list.';
												|it = 'Политика учета серий товара ""%1"" предусматривает, что серии указываются для каждого экземпляра. Укажите единичную упаковку в строке %2 списка ""%3"".';
												|pl = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit in line %2 of the ""%3"" list.';
												|tr = '""%1"" ürünü için toplu muhasebe politikası, her bir örnek için partilerin belirtildiğini belirtir. ""%3"" listesinin %2 satırında tek paketleme ünitesi belirt.'");
						MessageText = StrTemplate(MessageTemplate, Selection.ProductsPresentation, Format(Selection.LineNumber, "NZ=0; NG="), PresentationOfTS);
						
						// It is not universal, because in all documents where the reference series are indicated only in the same PM as the
						// goods, there is a field for the quantity of packages.
						Field = CommonClientServer.PathToTabularSection(Parameters.NameTSGoods, Selection.LineNumber, "Package");
						Common.MessageToUser(MessageText, DataKey, Field, CheckParameters.PathToFormTableData, Cancel);
					EndIf;
				EndDo;
			Else
				If Not Result.IsEmpty() Then
					Cancel = True;
				EndIf;
			EndIf;
			
			ProductsLocalization.CheckSeriesCompletion(DocumentObject,
															Parameters,
															Cancel,
															NotCheckedAttributeArray,
															CheckParameters);
			
		ElsIf Not Parameters.ProductInHeader Then
			
			If CheckParameters.IssueMessages Then
				
				Selection = Result.Select();
				
				While Selection.Next() Do
					
					If Selection.NoErrorSpecified
						Or Selection.ErrorDoesNotEqualQuantity Then
						If (Selection.BatchesIndicationStatus = 13
								Or SeriesWhenPlanningShipmentWHGoodsAreIndicated 
									And Selection.BatchesIndicationStatus = 9)
								And ThereAreAttributeBatch Then
							MessageTemplate = NStr("vi = 'Chưa điền cột ""Sê-ri"" trong dòng %1 của danh sách ""%2""';
													|ru = 'Не заполнена колонка ""Серия"" в строке %1 списка ""%2""';
													|en = 'The ""Batch"" column is not filled in line %1 of the ""%2"" list'; fa = 'The ""Batch"" column is not filled in line %1 of the ""%2"" list';
													|it = 'Не заполнена колонка ""Серия"" в строке %1 списка ""%2""';
													|pl = 'The ""Batch"" column is not filled in line %1 of the ""%2"" list';
													|tr = '""%2"" listesinin %1 satırında ""Parti"" sütunu doldurulmadı'");
							MessageText = StrTemplate(MessageTemplate, Format(Selection.LineNumber, "NZ=0; NG="), PresentationOfTS);
								
							Field = CommonClientServer.PathToTabularSection(Parameters.NameTSGoods, Selection.LineNumber, "Series");
							Common.MessageToUser(MessageText, DataKey, Field, CheckParameters.PathToFormTableData, Cancel);
						Else
							MessageTemplate = NStr("vi = 'Đối với hàng hóa ""%1"", đã chỉ ra theo sê-ri %2%4. Cần chỉ ra %3 %4. Hãy chỉnh sửa sê-ri.';
													|ru = 'Для товара ""%1"" указано по сериям %2 %4. Необходимо указать %3 %4. Исправьте серии.';
													|en = 'For the ""%1"" item, %2 %4 is specified by batches. Specify %3 %4. Correct the batches.'; fa = 'For the ""%1"" item, %2 %4 is specified by batches. Specify %3 %4. Correct the batches.';
													|it = 'Для товара ""%1"" указано по сериям %2 %4. Необходимо указать %3 %4. Исправьте серии.';
													|pl = 'For the ""%1"" item, %2 %4 is specified by batches. Specify %3 %4. Correct the batches.';
													|tr = '%2 %4 partisi tarafından belirtilen ""%1"" ürünü için. %3 %4belirtilmeli. Partileri düzelt.'");
							MessageText = StrTemplate(MessageTemplate,
								ProductsClientServer.ProductPresentation(Selection.Products, Selection.Characteristic),
								Format(Selection.SeriesCount, "NZ=0; NG="),
								Format(Selection.GoodsQuantity, "NZ=0; NG="),
								Selection.UnitOfMeasure);
							
							Field = CommonClientServer.PathToTabularSection(Parameters.NameTSGoods, Selection.LineNumber, "BatchesIndicationStatus");
							Common.MessageToUser(MessageText, DataKey , Field, CheckParameters.PathToFormTableData, Cancel);
						EndIf;
					EndIf;
				EndDo;
			Else
				If Not Result.IsEmpty() Then
					Cancel = True;
				EndIf;
			EndIf;
			
			ProductsLocalization.CheckSeriesCompletion(DocumentObject, Parameters, Cancel, NotCheckedAttributeArray, CheckParameters);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// The function determines which form to open for specifying series (registration or selection),
// prepares parameters (including putting the necessary data in temporary storage) for opening it, and returns them.
//
// Parameters:
//	Object						 - FormDataStructure	 - the main Attributes of the document form, including:
//									* Ref - DocumentRef, CatalogRef - 
//	SeriesSpecificationParameters		 - See ProductsClientServer.SeriesSpecificationParameters
//	CurDataId	 - Number				 - ID of the current product line in the document form;
//	Form						 - ClientApplicationForm		 - the form from which the series was initiated;
//	Var_Metadata					 - MetadataObject 	 - metadata of the object for which the series are stored, the default value is Undefined.
//															If this parameter is omitted, the metadata is extracted from the reference (Object.Link).
//	ColumnHeadingQuantity	 - String				 - title of the column with the number in the opened form for specifying series, the default value is "".
//															If the header is not passed, the column will be named in the "Quantity" form.
//
// Returns:
//	Structure - structure with the name and parameters of the series indication form:
//  The main fields.
//		* FormName - String - name of the form to open. This is either a registration form or a series selection form. Depends on the parameterationseries
//		* AddressInTempStorage - String - the address in the temporary storage of selected series lines.
//												If the series selection form is called, then there is a structure in the temporary storage (Product tables, series tables).
//												The series table is a TS Series, the Goods table is a table of goods grouped by communication fields.
//		* RegisterSeries - Boolean - is it necessary, according to the series specification parameters, to give the opportunity to register a series (or only select from the available ones);
//		* ReadOnly - Boolean - True - the form field is viewable only;
//		* Count - Number - the number of products by the dates for which the series is specified. It makes sense for the registration form of the series, because the selection form opens for all TS Products;
//		* WHSeriesProducts - Boolean - indicates that the series are specified in the same TS as the products;
//		* Recorder - DocumentRef - makes sense for the series selection form. Balances are displayed in this form, and when displayed
//										 , the change in Balances by the Cur document is reversed.
//		* SeriesSpecificationParameters - Structure - the value of the parameter parametersthe series of this function for transmission to the series indication form;
//		* FieldValuesToIdentifyReferences - Structure - it makes sense for the series selection form, in which the Balances are shown. To request Balances, you need
//													parameters. Returned by the function See ProductsClientServer.FieldValuesToIdentifyReferences.
//  The values of the Cur row or object fields, if there are no such fields in the row.
//		* Products - CatalogRef.Products - nomenclature;
//		* Characteristic - CatalogRef.ItemsCharacteristics - a characteristic of an item;
//		* BatchesIndicationStatus - Number - the status indication of the series;
//		* ItemVariantsAreUsed - Boolean - Truth is an indication of the use of Product characteristics;
//		* Values communication fields from the parameterationseries.Communication fields;
//		* Warehouse - CatalogRef.Warehouses - warehouse;
//		* Premise - CatalogRef.Warerooms - warehouse;
//		* PackagingForSubstitution - CatalogRef.PackagesAndUnitsOfMeasure, Undefined - the package in which you need to display the quantity in the batch registration form.
//								If there is one package in the TS "Products" for all product lines and the package is not included in the link fields, this value is passed, if the packages
//								are different, it is Undefined.
//
Function ParametersOfSeriesIndicationForm(Object,SeriesSpecificationParameters,CurDataId,Form, Var_Metadata = Undefined, ColumnHeadingQuantity = "") Export
	MetadataOfDocument = TMCommonUse.ObjectMetadataByFullName(SeriesSpecificationParameters.FullObjectName);
	
	FormUniqueID = Form.UUID;
	
	// If you need to change the quantity, then you need to block the form data
	// If the block fails, an exception will be thrown.
	If Not SeriesSpecificationParameters.ReadOnly
		And SeriesSpecificationParameters.BlockFormData Then
		Form.LockFormDataForEdit();
	EndIf;
	
	If Not SeriesSpecificationParameters.ReadOnly Then
		Form.Modified = True;
	EndIf;
	
	LinkFieldText = "";
	ProductSelectionText = "";
	
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		ProductSelectionText = ProductSelectionText + "
		|	TableOfGoods."  + ArrRow + ", ";
		
		LinkFieldText = LinkFieldText + "," + ArrRow  ;
	EndDo;
	
	If SeriesSpecificationParameters.ProductInHeader Then
		CurrentData = Object; // DocumentTabularSectionRow.DiscrepancyReportFollowingReceipt.Goods - specified for typing
	Else
		CurrentData = Object[SeriesSpecificationParameters.NameTSGoods].FindByID(CurDataId); // DocumentTabularSectionRow.DiscrepancyReportFollowingReceipt.Goods - specified for typing
	EndIf;

	ThereArePackages = SeriesSpecificationParameters.LinkFields.Find("Package") <> Undefined;
	ThereIsAction = SeriesSpecificationParameters.LinkFields.Find("Action") <> Undefined;
	PackagingForSubstitution = Undefined;
	ProcessingOfGoodsPlacesIsUnderway = False;
	If SeriesSpecificationParameters.ProductLocationsAreUsed Then
		ProcessingOfGoodsPlacesIsUnderway = (Common.ObjectAttributeValue(CurrentData.Package, "PackageType")
										= Enums.TypesOfItemsPackages.CargoItem);
	EndIf;
	
	If ThereIsAction Then
		RegisterSeries = ?(CurrentData.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick, False, True);
	Else
		RegisterSeries = SeriesSpecificationParameters.RegisterSeries;
	EndIf;
	
	If RegisterSeries Then
		DocumentRowsNumbers = "";
		
		If ThereArePackages
			And ValueIsFilled(CurrentData.Package) Then //not filled for containers
			PackageData = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(CurrentData.Package, CurrentData.Products);
			PackagingFactor      = PackageData.ZoomRatio; 
			NeedToRoundUpQuantity = PackageData.NeedToRoundUpQuantity;
		Else
			PackagingFactor = 1;
			NeedToRoundUpQuantity = False;
		EndIf;
		
		Packages = New Array();
		
		If SeriesSpecificationParameters.ProductInHeader Then
			ThereArePackagingWHGoods = False;
			If Object.Property("Package") Then
				Packages.Add(Object.Package);
			EndIf;
		Else
			TableColumns1 = Object[SeriesSpecificationParameters.NameTSGoods].Unload(New Array); // ValueTable
			ThereArePackagingWHGoods = TableColumns1.Columns.Find("Package") <> Undefined;
		EndIf;
		
		TableColumns1 = Object[SeriesSpecificationParameters.TSSeriesName].Unload(New Array); // ValueTable
		ThereArePackagesOfVTCHSeries = TableColumns1.Columns.Find("Package") <> Undefined;
		
		If ThereArePackagingWHGoods Then
			PackagingTSGoods = Object[SeriesSpecificationParameters.NameTSGoods].Unload(, "Package").UnloadColumn("Package");
			CommonClientServer.SupplementArray(Packages, PackagingTSGoods);
		EndIf;
		If ThereArePackagesOfVTCHSeries Then
			TSSeriesPackaging = Object[SeriesSpecificationParameters.TSSeriesName].Unload(, "Package").UnloadColumn("Package");
			CommonClientServer.SupplementArray(Packages, TSSeriesPackaging);
		EndIf;
		
		Packages = CommonClientServer.CollapseArray(Packages);
		PackageTypes = Common.ObjectsAttributeValue(Packages, "PackageType");
		
		If SeriesSpecificationParameters.ProductInHeader Then
			QuantityOfGoodsInDocument = Object[SeriesSpecificationParameters.FieldNameQuantity]*PackagingFactor;
			TheStructureOfTheSearch = New Structure("Products,Characteristic"+LinkFieldText);
			FillPropertyValues(TheStructureOfTheSearch,Object);
		Else
			TheStructureOfTheSearch = New Structure("Products,Characteristic"+LinkFieldText);
			FillPropertyValues(TheStructureOfTheSearch,CurrentData);
			
			TextOfLinkFieldPackaging = ?(ThereArePackagingWHGoods And Not ThereArePackages, ", Package", "");
			
			UnloadedFields = "Products,Characteristic" + LinkFieldText + TextOfLinkFieldPackaging;
			GoodsTable = Object[SeriesSpecificationParameters.NameTSGoods].Unload(, UnloadedFields + ", " + SeriesSpecificationParameters.FieldNameQuantity);
			GoodsTable.GroupBy(UnloadedFields, SeriesSpecificationParameters.FieldNameQuantity);
			
			ProductLinesFoundGrouped = GoodsTable.FindRows(TheStructureOfTheSearch);
			
			QuantityOfGoodsInDocument = 0;
			MinimumNumberOfIntegerSets = 0;
			For Each ArrRow In ProductLinesFoundGrouped Do
				
				If ThereArePackagingWHGoods Then
					
					ProductLocationsInLine = (PackageTypes.Get(ArrRow.Package)
												= Enums.TypesOfItemsPackages.CargoItem);
					// If the series indication form is called for a line with a package - a place of sale,
					// then it is necessary to exclude lines with other types of packages from the algorithm. And vice versa.
					If ProcessingOfGoodsPlacesIsUnderway
						And Not ProductLocationsInLine Then
						Continue;
					ElsIf Not ProcessingOfGoodsPlacesIsUnderway
						And ProductLocationsInLine Then
						Continue;
					EndIf;
				
					// Calculate the package in which you need to display the quantity in the package editing form
					// If one package is specified for all lines, then we will display the quantity in it
					// If the package is included in the connection fields, then it will be the only one for all lines.
					If PackagingForSubstitution = Undefined Then
						PackagingForSubstitution = ArrRow.Package;
					ElsIf PackagingForSubstitution <> ArrRow.Package Then
						PackagingForSubstitution = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
					EndIf;
					
				EndIf;
				
				If NeedToRoundUpQuantity Then
					ArrRow[SeriesSpecificationParameters.FieldNameQuantity] = Round(ArrRow[SeriesSpecificationParameters.FieldNameQuantity], 0, RoundMode.Round15as20);
				EndIf;
				
				If ProcessingOfGoodsPlacesIsUnderway Then
					// The number of packages that make up one piece of goods
					PackagingFactor = Common.ObjectAttributeValue(ArrRow.Package, "NumberOfPackages");
					
					NumberOfWholeSets = ArrRow[SeriesSpecificationParameters.FieldNameQuantity];
					
					MinimumNumberOfIntegerSets = ?(MinimumNumberOfIntegerSets = 0,
															NumberOfWholeSets,
															Min(NumberOfWholeSets, MinimumNumberOfIntegerSets));
															
					QuantityOfGoodsInDocument = MinimumNumberOfIntegerSets;
				Else
					QuantityOfGoodsInDocument = QuantityOfGoodsInDocument + ArrRow[SeriesSpecificationParameters.FieldNameQuantity]*PackagingFactor;
				EndIf;
				
			EndDo;
			
			FoundProductLines = Object[SeriesSpecificationParameters.NameTSGoods].FindRows(TheStructureOfTheSearch);
			For Each ArrRow In FoundProductLines Do
				If ThereArePackagingWHGoods Then
					
					ProductLocationsInLine = (PackageTypes.Get(ArrRow.Package)
												= Enums.TypesOfItemsPackages.CargoItem);
					// If the series indication form is called for a line with a package - a place of sale,
					// then it is necessary to exclude lines with other types of packages from the algorithm. And vice versa.
					If ProcessingOfGoodsPlacesIsUnderway
						And Not ProductLocationsInLine Then
						Continue;
					ElsIf Not ProcessingOfGoodsPlacesIsUnderway
						And ProductLocationsInLine Then
						Continue;
					EndIf;
				EndIf;
				
				DocumentRowsNumbers = DocumentRowsNumbers + String(ArrRow.LineNumber) + ", ";
			EndDo;
			
			If Not IsBlankString(DocumentRowsNumbers) Then
				DocumentRowsNumbers = Left(DocumentRowsNumbers, StrLen(DocumentRowsNumbers)-2);
			EndIf;
		EndIf;
		
		TableOfSeries = New ValueTable;
		TableOfSeries.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
		TableOfSeries.Columns.Add("Count", TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
		TableOfSeries.Columns.Add("NumberOfPackages", TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
		
		FoundSeriesRows_ = Object[SeriesSpecificationParameters.TSSeriesName].FindRows(TheStructureOfTheSearch);
		
		If ProcessingOfGoodsPlacesIsUnderway Then
			For Each ArrRow In FoundSeriesRows_ Do
				
				If ThereArePackagesOfVTCHSeries Then
					
					ProductLocationsInLine = (PackageTypes.Get(ArrRow.Package)
												= Enums.TypesOfItemsPackages.CargoItem);
					// If the series indication form is called for a line with a package - a place of sale,
					// then it is necessary to exclude lines with other types of packages from the algorithm.
					If Not ProductLocationsInLine Then
						Continue;
					EndIf;
					
				EndIf;
				
				// When using product placements, it is necessary to obtain a collapsed table with the quantity reduced
				// to the maximum - for proper use in the subsequent distribution algorithm in the method of processing Series designations.
				SeriesString = TableOfSeries.Find(ArrRow.Series, "Series");
				If SeriesString <> Undefined Then
					
					SeriesString.Count = Max(SeriesString.Count, ArrRow[SeriesSpecificationParameters.FieldNameQuantity]);
					SeriesString.NumberOfPackages = SeriesString.Count;
					
				Else
					
					NewRow = TableOfSeries.Add();
					FillPropertyValues(NewRow, ArrRow);
					
					// Made non-universally. If there are packages in the communication fields, then the fields with the quantity in all documents are called as standard.
					If Not ThereArePackages Then
						NewRow.Count = ArrRow[SeriesSpecificationParameters.FieldNameQuantity];
						NewRow.NumberOfPackages = NewRow.Count;
					EndIf;
				EndIf;
				
			EndDo;
		Else
			For Each ArrRow In FoundSeriesRows_ Do

				If ArrRow.Series.IsEmpty() Then
					Continue;
				EndIf;

				If SeriesSpecificationParameters.ProductLocationsAreUsed
					And ThereArePackagesOfVTCHSeries Then
					
					ProductLocationsInLine = (PackageTypes.Get(ArrRow.Package)
												= Enums.TypesOfItemsPackages.CargoItem);
					// If the series indication form is called for a line with a package - not a place of sale,
					// then it is necessary to exclude from the algorithm lines with the type of packaging "place of sale".
					If ProductLocationsInLine Then
						Continue;
					EndIf;
					
				EndIf;
				
				NewRow = TableOfSeries.Add();
				FillPropertyValues(NewRow, ArrRow);
				
				// Made non-universally. If there are packages in the communication fields, then the fields with the quantity in all documents are called as standard.
				If Not ThereArePackages Then
					NewRow.Count = ArrRow[SeriesSpecificationParameters.FieldNameQuantity];
					NewRow.NumberOfPackages = NewRow.Count;
				EndIf;
				
			EndDo;
		EndIf;
		
		AddressInTempStorage = PutToTempStorage(TableOfSeries,FormUniqueID);
		
	Else
		TableOfGoods = New ValueTable;
		TableOfGoods.Columns.Add("Products",New TypeDescription("CatalogRef.Products"));
		TableOfGoods.Columns.Add("Characteristic",New TypeDescription("CatalogRef.ItemsCharacteristics"));
		TableOfGoods.Columns.Add("Count",TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
		If Not ThereArePackages Then
			TableOfGoods.Columns.Add("Package",New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		EndIf;
		TableOfGoods.Columns.Add("DocumentRowsNumbers",New TypeDescription("String",,New StringQualifiers(100)));
		
		CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, TableOfGoods, Var_Metadata); 
		
		If SeriesSpecificationParameters.ProductInHeader Then
			RowOfProduct = TableOfGoods.Add();
			FillPropertyValues(RowOfProduct,Object);
			If SeriesSpecificationParameters.ThisIsOrder
				And SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipSetsForDisassembly) <> Undefined
				And Not Object.WithAssignment Then
				// In the order header, when changing the security option, the assignment is not cleared,
				//	so for an unsociable shipment, we will reset the assignment here.
				RowOfProduct.Purpose = Catalogs.Assignments.EmptyRef();
			EndIf;
		Else
			
			QueryText = 
			"SELECT
			|	TableOfGoods.ProductSelectionText,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	TableOfGoods.Count,
			|	CAST(TableOfGoods.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
			|	TableOfGoods.LineNumber
			|INTO TableOfGoods
			|FROM
			|	&TableOfGoods AS TableOfGoods
			|WHERE
			|	TableOfGoods.BatchesIndicationStatus IN(&SelectionByStatus)
			|	AND &ActionCondition
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.ProductSelectionText,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	TableOfGoods.Count AS Count,
			|	TableOfGoods.LineNumber AS LineNumber
			|FROM
			|	(SELECT
			|		TableOfGoods.ProductSelectionText,
			|		TableOfGoods.Products AS Products,
			|		TableOfGoods.Characteristic AS Characteristic,
			|		MIN(TableOfGoods.Count) AS Count,
			|		MIN(TableOfGoods.LineNumber) AS LineNumber
			|	FROM
			|		TableOfGoods AS TableOfGoods
			|	WHERE
			|		ISNULL(TableOfGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
			|	
			|	GROUP BY
			|		TableOfGoods.ProductSelectionText,
			|		TableOfGoods.Products,
			|		TableOfGoods.Characteristic,
			|		TableOfGoods.Count
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		TableOfGoods.ProductSelectionText,
			|		TableOfGoods.Products,
			|		TableOfGoods.Characteristic,
			|		TableOfGoods.Count,
			|		TableOfGoods.LineNumber
			|	FROM
			|		TableOfGoods AS TableOfGoods
			|	WHERE
			|		ISNULL(TableOfGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)) AS TableOfGoods
			|
			|ORDER BY
			|	TableOfGoods.ProductSelectionText,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	TableOfGoods.LineNumber";
			
			QueryText = StrReplace(QueryText, "TableOfGoods.ProductSelectionText,", ProductSelectionText); 
			
			If Not ThereArePackages Then
				QueryText = StrReplace(QueryText, "TableOfGoods.Package,", ""); 
			EndIf;
			
			If ThereIsAction Then
				QueryText = StrReplace(QueryText,
											"&ActionCondition",
											"TableOfGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)");
			Else
				QueryText = StrReplace(QueryText, "&ActionCondition", "TRUE");
			EndIf;		
			
			Query = New Query;
			Query.Text = QueryText;
			
			If SeriesSpecificationParameters.NeedToRoundUpQuantity
				And StrFind(SeriesSpecificationParameters.FieldNameQuantity, "NumberOfPackages") = 0 Then
				
				If SeriesSpecificationParameters.ProductInHeader Then
					PackageData = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(Object.Package, Object.Products);
					If PackageData.NeedToRoundUpQuantity Then
						Object[SeriesSpecificationParameters.FieldNameQuantity] = Round(Object[SeriesSpecificationParameters.FieldNameQuantity], 0, RoundMode.Round15as20);
					EndIf;
				Else
					RoundingParameters = ParametersForRoundingNumberOfUnitProducts();
					RoundingParameters.TSName = SeriesSpecificationParameters.NameTSGoods;
					
					LengthFieldNameQuantity = StrLen(SeriesSpecificationParameters.FieldNameQuantity);
					
					If LengthFieldNameQuantity > 10 Then
						RoundingParameters.AdditionalPropsSuffix = Right(SeriesSpecificationParameters.FieldNameQuantity, LengthFieldNameQuantity - 10);
					EndIf;
					
					RoundUpNumberOfUnitItems(Object, Undefined, RoundingParameters);
				EndIf;
				
			EndIf;
			
			TS = Object[SeriesSpecificationParameters.NameTSGoods].Unload();
			
			Query.SetParameter("TableOfGoods",TS);

			SelectionBySeriesIndicationStatus = New Array;
			SelectionBySeriesIndicationStatus.Add(3);
			SelectionBySeriesIndicationStatus.Add(23);
			SelectionBySeriesIndicationStatus.Add(4);
			SelectionBySeriesIndicationStatus.Add(5);
			SelectionBySeriesIndicationStatus.Add(25);
			SelectionBySeriesIndicationStatus.Add(6);
			SelectionBySeriesIndicationStatus.Add(7);
			SelectionBySeriesIndicationStatus.Add(27);
			SelectionBySeriesIndicationStatus.Add(8);
			If SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated
				Or SeriesSpecificationParameters.NameTSGoods = SeriesSpecificationParameters.TSSeriesName Then
				SelectionBySeriesIndicationStatus.Add(9);
				SelectionBySeriesIndicationStatus.Add(10);
				SelectionBySeriesIndicationStatus.Add(11);
			EndIf;
			If SeriesSpecificationParameters.NameTSGoods = SeriesSpecificationParameters.TSSeriesName Then
				SelectionBySeriesIndicationStatus.Add(13);
				SelectionBySeriesIndicationStatus.Add(14);
				SelectionBySeriesIndicationStatus.Add(15);
				SelectionBySeriesIndicationStatus.Add(17);
				SelectionBySeriesIndicationStatus.Add(18);
				SelectionBySeriesIndicationStatus.Add(28);
				SelectionBySeriesIndicationStatus.Add(19);
				SelectionBySeriesIndicationStatus.Add(20);
				SelectionBySeriesIndicationStatus.Add(22);
			EndIf;
			
			Query.SetParameter("SelectionByStatus", SelectionBySeriesIndicationStatus);
			
			GroupFields = "Products,Characteristic" + LinkFieldText;
			
			CurrentGroup = New Structure(GroupFields);
			
			Selection = Query.Execute().Select();
			
			TableOfGoods.Columns.Add("RowNumberToSort",
				New TypeDescription("Number",
				New NumberQualifiers(5,0,AllowedSign.Nonnegative)));
			
			Count               = 0;
			DocumentRowsNumbers     = "";
			RowNumberToSort = 0;
			
			NewProductRow = Undefined;
			
			While Selection.Next() Do
				
				If Not TMCommonUseClientServer.StructuresAreEqual(CurrentGroup, Selection, GroupFields) Then
					
					If NewProductRow <> Undefined Then
						FillPropertyValues(NewProductRow,CurrentGroup);
						NewProductRow.Count = Count;
						
						DocumentRowsNumbers = Left(DocumentRowsNumbers, StrLen(DocumentRowsNumbers)-2);
						NewProductRow.DocumentRowsNumbers     = DocumentRowsNumbers;
						NewProductRow.RowNumberToSort = RowNumberToSort;
					EndIf;
					
					FillPropertyValues(CurrentGroup,Selection);
					NewProductRow       = TableOfGoods.Add();
					RowNumberToSort = Selection.LineNumber;
					Count           = 0;
					DocumentRowsNumbers = "";
					
				EndIf;
				
				Count           = Count + Selection.Count;
				DocumentRowsNumbers = DocumentRowsNumbers + Selection.LineNumber + ", ";
				
			EndDo;
			
			If NewProductRow <> Undefined Then
				FillPropertyValues(NewProductRow,CurrentGroup);
				NewProductRow.Count = Count;
				
				DocumentRowsNumbers = Left(DocumentRowsNumbers, StrLen(DocumentRowsNumbers)-2);
				NewProductRow.DocumentRowsNumbers = DocumentRowsNumbers;
				NewProductRow.RowNumberToSort = RowNumberToSort;
			EndIf;
			
			TableOfGoods.Sort("RowNumberToSort");
			TableOfGoods.Columns.Delete("RowNumberToSort");
			
		EndIf;
		StructureForTemporaryStorage = New Structure;
		StructureForTemporaryStorage.Insert("TableOfGoods",TableOfGoods);
		
		TableOfSeries = Object[SeriesSpecificationParameters.TSSeriesName].Unload(); 
		
		If SeriesSpecificationParameters.ProductLocationsAreUsed Then
			
			QueryText = 
			"SELECT
			|	TableOfGoods.LineNumber AS LineNumber,
			|	TableOfGoods.ProductSelectionText,
			|	CAST(TableOfGoods.Products AS Catalog.Products) AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Series AS Series,
			|	CAST(TableOfGoods.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
			|	TableOfGoods.Count AS Count
			|INTO TableOfGoods
			|FROM
			|	&TableOfGoods AS TableOfGoods
			|WHERE
			|	TableOfGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	TableOfGoods.ProductSelectionText,
			|	TableOfGoods.Products AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Series AS Series,
			|	Packages.Ref AS Package
			|INTO PackingOfGoodsByCommodityPlaces
			|FROM
			|	TableOfGoods AS TableOfGoods
			|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
			|		ON TableOfGoods.Products.PackagingGroup = Packages.Owner
			|			AND (Packages.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem))
			|WHERE
			|	NOT Packages.DeletionMark
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	TableOfGoods.ProductSelectionText,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	TableOfGoods.Series,
			|	Packages.Ref
			|FROM
			|	TableOfGoods AS TableOfGoods
			|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
			|		ON (TableOfGoods.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem))
			|			AND TableOfGoods.Products = Packages.Owner
			|			AND (Packages.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem))
			|WHERE
			|	NOT Packages.DeletionMark
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	MIN(TableOfGoods.LineNumber) AS LineNumber,
			|	TableOfGoods.ProductSelectionText,
			|	TableOfGoods.Products AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Package AS Package,
			|	TableOfGoods.Series AS Series
			|INTO FirstLineNumbersOfProductsByProductLocations
			|FROM
			|	TableOfGoods AS TableOfGoods
			|WHERE
			|	ISNULL(TableOfGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
			|
			|GROUP BY
			|	TableOfGoods.ProductSelectionText,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	TableOfGoods.Package,
			|	TableOfGoods.Series
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.ProductSelectionText,
			|	TableOfGoods.Products AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Series AS Series,
			|	TableOfGoods.Package AS Package,
			|	SUM(TableOfGoods.Count) AS Count
			|INTO CompleteSetsOfGoodsByProductLocations
			|FROM
			|	(SELECT
			|		Packages.ProductSelectionText,
			|		Packages.Products AS Products,
			|		Packages.Characteristic AS Characteristic,
			|		Packages.Series AS Series,
			|		Packages.Package AS Package,
			|		ISNULL(TableOfGoods.Count, 0) AS Count
			|	FROM
			|		PackingOfGoodsByCommodityPlaces AS Packages
			|			LEFT JOIN TableOfGoods AS TableOfGoods
			|			ON Packages.Products = TableOfGoods.Products
			|				AND Packages.Characteristic = TableOfGoods.Characteristic
			|				AND Packages.Series = TableOfGoods.Series
			|				AND Packages.Package = TableOfGoods.Package
			|				AND (&ConnectionCondition)) AS TableOfGoods
			|
			|GROUP BY
			|	TableOfGoods.ProductSelectionText,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	TableOfGoods.Series,
			|	TableOfGoods.Package
			|
			|HAVING
			|	SUM(TableOfGoods.Count) > 0
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.ProductSelectionText,
			|	TableOfGoods.Products AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Package AS Package,
			|	TableOfGoods.Series AS Series,
			|	TableOfGoods.Count AS Count,
			|	TableOfGoods.LineNumber AS LineNumber
			|FROM
			|	(SELECT
			|		MIN(Packages.LineNumber) AS LineNumber,
			|		TableOfGoods.ProductSelectionText,
			|		TableOfGoods.Products AS Products,
			|		TableOfGoods.Characteristic AS Characteristic,
			|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
			|		TableOfGoods.Series AS Series,
			|		MIN(TableOfGoods.Count) AS Count
			|	FROM
			|		CompleteSetsOfGoodsByProductLocations AS TableOfGoods
			|			LEFT JOIN FirstLineNumbersOfProductsByProductLocations AS Packages
			|			ON TableOfGoods.Products = Packages.Products
			|				AND TableOfGoods.Products = Packages.Products
			|				AND TableOfGoods.Characteristic = Packages.Characteristic
			|				AND TableOfGoods.Series = Packages.Series
			|				AND (&ConnectionCondition)
			|	
			|	GROUP BY
			|		TableOfGoods.ProductSelectionText,
			|		TableOfGoods.Products,
			|		TableOfGoods.Characteristic,
			|		TableOfGoods.Series
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		TableOfGoods.LineNumber,
			|		TableOfGoods.ProductSelectionText,
			|		TableOfGoods.Products,
			|		TableOfGoods.Characteristic,
			|		TableOfGoods.Package,
			|		TableOfGoods.Series,
			|		TableOfGoods.Count
			|	FROM
			|		TableOfGoods AS TableOfGoods
			|	WHERE
			|		ISNULL(TableOfGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)) AS TableOfGoods
			|
			|ORDER BY
			|	TableOfGoods.LineNumber,
			|	TableOfGoods.ProductSelectionText,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	TableOfGoods.Package";
			
			TextsForJoiningTables = New Array;
			TextsForJoiningTables.Add("TRUE");
			
			ProductSelectionText= StrReplace(ProductSelectionText, "TableOfGoods.Package,", "");
			PackageSelectionText = StrReplace(ProductSelectionText, "TableOfGoods", "Packages");
			
			For Each LinksField In SeriesSpecificationParameters.LinkFields Do
				
				If StrFind(ProductSelectionText, LinksField) = 0
					Or LinksField = "Package" Then
					
					Continue;
					
				EndIf;
				
				TextsForJoiningTables.Add(" Packages." + LinksField + " = TableOfGoods." + LinksField);
				
			EndDo;
			
			QueryText = StrReplace(QueryText, "TableOfGoods.ProductSelectionText,", ProductSelectionText);
			QueryText = StrReplace(QueryText, "Packages.ProductSelectionText,", PackageSelectionText);
			QueryText = StrReplace(QueryText, "&ConnectionCondition", 
				StrConcat(TextsForJoiningTables, Chars.LF +"And " ));
				
			TempTableManager = New TempTablesManager;
			
			Query = New Query;
			Query.Text = QueryText;
			Query.TempTablesManager = TempTableManager;
			Query.SetParameter("TableOfGoods", TableOfSeries);
			TableOfSeries = Query.Execute().Unload();
			
		Else
			
			RowsReadyForDeletion = TableOfSeries.FindRows(New Structure("Series",Catalogs.ItemsBatches.EmptyRef()));
			
			For Each ArrRow In RowsReadyForDeletion Do
				TableOfSeries.Delete(ArrRow);
			EndDo;
			
		EndIf;
		
		StructureForTemporaryStorage.Insert("TableOfSeries",TableOfSeries);
		
		AddressInTempStorage = PutToTempStorage(StructureForTemporaryStorage,FormUniqueID);
	EndIf;
	
	ParametersOfSeriesIndicationForm = New Structure("Products,Characteristic,BatchesIndicationStatus,ItemVariantsAreUsed"+LinkFieldText);
	ParametersOfSeriesIndicationForm.Insert("DocumentRowsNumbers", DocumentRowsNumbers); 
	
	If SeriesSpecificationParameters.ProductInHeader Then
		FillPropertyValues(ParametersOfSeriesIndicationForm,Object);
	Else
		FillPropertyValues(ParametersOfSeriesIndicationForm,CurrentData);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseFieldName = Undefined Then
		ParametersOfSeriesIndicationForm.Insert("Warehouse", Undefined);
	ElsIf SeriesSpecificationParameters.LinkFields.Find(SeriesSpecificationParameters.WarehouseFieldName) <> Undefined Then
		ParametersOfSeriesIndicationForm.Insert("Warehouse", CurrentData[SeriesSpecificationParameters.WarehouseFieldName]);
	Else
		ParametersOfSeriesIndicationForm.Insert("Warehouse", Object[SeriesSpecificationParameters.WarehouseFieldName]);
	EndIf;
	
	ControlledLotReference = Undefined;
	If SeriesSpecificationParameters.FieldNameControlledLotReference = Undefined Then
		ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	ElsIf StrFind(SeriesSpecificationParameters.FieldNameControlledLotReference, ".") > 0 Then
		ControlledLotReference = CurrentData[StrReplace(SeriesSpecificationParameters.FieldNameControlledLotReference, ".", "")];
	Else
		ControlledLotReference = Object[SeriesSpecificationParameters.FieldNameControlledLotReference];
	EndIf;
	ParametersOfSeriesIndicationForm.Insert("ControlledLotReference", ControlledLotReference);
	
	If SeriesSpecificationParameters.LinkFields.Find("Premise") <> Undefined Then
		ParametersOfSeriesIndicationForm.Insert("Premise", CurrentData.Premise);
	ElsIf SeriesSpecificationParameters.FieldNameRoom = Undefined Then
		ParametersOfSeriesIndicationForm.Insert("Premise", Catalogs.Warerooms.EmptyRef());
	Else
		ParametersOfSeriesIndicationForm.Insert("Premise", Object[SeriesSpecificationParameters.FieldNameRoom]);
	EndIf;
	
	ParametersOfSeriesIndicationForm.Insert("PackagingForSubstitution",PackagingForSubstitution);
	ParametersOfSeriesIndicationForm.Insert("ProcessingOfGoodsPlacesIsUnderway", ProcessingOfGoodsPlacesIsUnderway);
	
	ParametersOfSeriesIndicationForm.Insert("AddressInTempStorage",AddressInTempStorage);
	ParametersOfSeriesIndicationForm.Insert("RegisterSeries", RegisterSeries);
	ParametersOfSeriesIndicationForm.Insert("ReadOnly", SeriesSpecificationParameters.ReadOnly);
	ParametersOfSeriesIndicationForm.Insert("OnlyQuantityEditing", False);
	ParametersOfSeriesIndicationForm.Insert("Count",QuantityOfGoodsInDocument);
	ParametersOfSeriesIndicationForm.Insert("AddressInTempStorage",AddressInTempStorage);
	ParametersOfSeriesIndicationForm.Insert("WHSeriesProducts", SeriesSpecificationParameters.TSSeriesName = SeriesSpecificationParameters.NameTSGoods);
	If Object.Property("Ref") Then
		ParametersOfSeriesIndicationForm.Insert("Recorder",Object.Ref);
	EndIf;
	ParametersOfSeriesIndicationForm.Insert("SeriesSpecificationParameters",SeriesSpecificationParameters);
	
	FieldValuesToIdentifyReferences = ProductsClientServer.FieldValuesToIdentifyReferences(Object,
																							  CurrentData,
																							  SeriesSpecificationParameters);

	ParametersOfSeriesIndicationForm.Insert("FieldValuesToIdentifyReferences", FieldValuesToIdentifyReferences);
	
	If RegisterSeries Then
		FormName = "DataProcessor.SelectBatchToDocuments.Form.RegisterAndSelectBatchByOneGoodsRow";
	Else
		FormName = "DataProcessor.SelectBatchToDocuments.Form.SelectLotsByRemainingQuantityOfAllGoodsRows";
	EndIf;
	
	ParametersOfSeriesIndicationForm.Insert("FormName", FormName);
	
	If ValueIsFilled(ColumnHeadingQuantity) Then
		ParametersOfSeriesIndicationForm.Insert("ColumnHeadingQuantity", ColumnHeadingQuantity);
	EndIf;
	
	Return ParametersOfSeriesIndicationForm;
	
EndFunction

// Retrieves the series specified in the series editing form from the temporary storage, places these lines in the PM "Series" of the document,
//	and recalculates the statuses for specifying series in product lines.
//
// Parameters:
//  Object						 - FormDataStructure - main details of the document form,
//  SeriesSpecificationParameters		 - Structure - parameters for specifying series returned by the corresponding procedure in the document Manager module,
//  ParametersOfSeriesIndicationForm	 - See ParametersOfSeriesIndicationForm.
//  Actions					 - Structure - description of actions to be performed with strings after specifying the series, See BatchProcessingOfTablePartServer.ProcessTSString
//  Cached_Values		 - Structure - Saved values of parameters used when processing strings.
//
Procedure ProcessSeriesIndication_(Object, SeriesSpecificationParameters,ParametersOfSeriesIndicationForm, Actions = Undefined, Cached_Values = Undefined) Export
	
	ThereArePackages = SeriesSpecificationParameters.LinkFields.Find("Package") <> Undefined;
	
#Region ProcessingSeriesSelection
	// If the results of the series selection form are being processed,
	// then the entire series are loaded from processing.
	
	If Not ParametersOfSeriesIndicationForm.RegisterSeries Then 
		
		ReturnStructure = GetFromTempStorage(ParametersOfSeriesIndicationForm.AddressInTempStorage);
		
		If SeriesSpecificationParameters.NameTSGoods = SeriesSpecificationParameters.TSSeriesName Then
			
			FillInWHSeriesAccordingToSeriesTable(Object,
											SeriesSpecificationParameters,
											ReturnStructure.TableOfSeries,
											Actions);
											
			If SeriesSpecificationParameters.ProductLocationsAreUsed
				And Not SeriesSpecificationParameters.UseBinLocationWarehousing Then
				ProductsServer.SplitProductsByProductLocations(Object[SeriesSpecificationParameters.NameTSGoods]);									
			EndIf;
			
		Else
			Object[SeriesSpecificationParameters.TSSeriesName].Load(ReturnStructure.TableOfSeries);
			FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		EndIf;
		
		Return;
		
	EndIf;
#EndRegion

#Region ProcessingSeriesRegistration
// Delete the previous lines of the series
	LinkFieldText = "";
	
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		LinkFieldText = LinkFieldText + "," + ArrRow  ;
	EndDo;
	TheStructureOfTheSearch = New Structure("Products,Characteristic"+LinkFieldText);
	
	If TheStructureOfTheSearch.Property("Package")
		And SeriesSpecificationParameters.ProductLocationsAreUsed
		And ParametersOfSeriesIndicationForm.ProcessingOfGoodsPlacesIsUnderway Then
		
		// When using product spaces, the changes in the line relate to each package - the product space.
		TheStructureOfTheSearch.Delete("Package");
		
	EndIf;
	
	LineNumberToInsert = 0;
	
	Packages = New Array();
	
	If SeriesSpecificationParameters.ProductInHeader Then
		ThereArePackagingWHGoods = False;
		If Object.Property("Package") Then
			Packages.Add(Object.Package);
		EndIf;
	Else
		TableColumns1 = Object[SeriesSpecificationParameters.NameTSGoods].Unload(New Array); // ValueTable
		ThereArePackagingWHGoods = TableColumns1.Columns.Find("Package") <> Undefined;
	EndIf;
	
	TableColumns1 = Object[SeriesSpecificationParameters.TSSeriesName].Unload(New Array); // ValueTable
	ThereArePackagesOfVTCHSeries = TableColumns1.Columns.Find("Package") <> Undefined;
	
	If ThereArePackagingWHGoods Then
		PackagingTSGoods = Object[SeriesSpecificationParameters.NameTSGoods].Unload(, "Package").UnloadColumn("Package");
		CommonClientServer.SupplementArray(Packages, PackagingTSGoods);
	EndIf;
	
	If ThereArePackagesOfVTCHSeries Then
		TSSeriesPackaging = Object[SeriesSpecificationParameters.TSSeriesName].Unload(, "Package").UnloadColumn("Package");
		CommonClientServer.SupplementArray(Packages, TSSeriesPackaging);
	EndIf;

	Packages = CommonClientServer.CollapseArray(Packages);
	PackageTypes = Common.ObjectsAttributeValue(Packages, "PackageType");
	
	FillPropertyValues(TheStructureOfTheSearch,ParametersOfSeriesIndicationForm);
	FoundSeriesRows_ = Object[SeriesSpecificationParameters.TSSeriesName].FindRows(TheStructureOfTheSearch);
	
	NumberOfPackagesBeforeSeriesRemoval = 0;
	PackagingOfGoodsPlaces = New Array();
	
	TableOfSeries = GetFromTempStorage(ParametersOfSeriesIndicationForm.AddressInTempStorage);
	
	For Each ArrRow In FoundSeriesRows_ Do
		
		If ThereArePackagingWHGoods
			And SeriesSpecificationParameters.ProductLocationsAreUsed
			And ParametersOfSeriesIndicationForm.ProcessingOfGoodsPlacesIsUnderway Then
			ProductLocationsInLine = (PackageTypes.Get(ArrRow.Package)
										= Enums.TypesOfItemsPackages.CargoItem);
			If Not ProductLocationsInLine Then
				Continue;
			EndIf;
			
			If ProductLocationsInLine
				And PackagingOfGoodsPlaces.Find(ArrRow.Package) = Undefined Then
				PackagingOfGoodsPlaces.Add(ArrRow.Package);
			EndIf;
			
		ElsIf ThereArePackagingWHGoods
			And SeriesSpecificationParameters.ProductLocationsAreUsed 
			And Not ParametersOfSeriesIndicationForm.ProcessingOfGoodsPlacesIsUnderway Then
			ProductLocationsInLine = (PackageTypes.Get(ArrRow.Package)
										= Enums.TypesOfItemsPackages.CargoItem);
			If ProductLocationsInLine Then
				Continue;
			EndIf;
		EndIf;
		
		If SeriesSpecificationParameters.TSSeriesName = SeriesSpecificationParameters.NameTSGoods Then
			If ThereArePackagingWHGoods Then
				NumberOfPackagesBeforeSeriesRemoval = NumberOfPackagesBeforeSeriesRemoval + ArrRow.NumberOfPackages;
			Else
				NumberOfPackagesBeforeSeriesRemoval = NumberOfPackagesBeforeSeriesRemoval + ArrRow[SeriesSpecificationParameters.FieldNameQuantity];
			EndIf;
		EndIf;
		
		If TableOfSeries.FindRows(New Structure("Series", ArrRow.Series)).Count() = 0 Then 
			If LineNumberToInsert = 0 Then
				LineNumberToInsert = ArrRow.LineNumber;
			EndIf;
			If ParametersOfSeriesIndicationForm.OnlyQuantityEditing Then
				ArrRow[SeriesSpecificationParameters.FieldNameQuantity] = 0;
			Else
				Object[SeriesSpecificationParameters.TSSeriesName].Delete(ArrRow);
			EndIf;
		EndIf;
	EndDo;
	
	// Add new series lines
	SeriesRowsToProcess =  New Array;
	
	NumberOfPackagesAfterRemovalOfSeries = 0;
	
	If ThereArePackagingWHGoods
		And SeriesSpecificationParameters.ProductLocationsAreUsed
		And ParametersOfSeriesIndicationForm.ProcessingOfGoodsPlacesIsUnderway Then
		
		DocumentTable = Object[SeriesSpecificationParameters.TSSeriesName].Unload(); // ValueTable
		DocumentTable.Columns.Add("ReadyForProcessing", New TypeDescription("Boolean"));
		DocumentTable.Columns.Add("QuantityBySeries", New TypeDescription("Number"));
		
		OldLines = DocumentTable.FindRows(TheStructureOfTheSearch);
		
		// Preparing rows for processing
		For Each String In OldLines Do
			
			ProductLocationsInLine = (PackageTypes.Get(String.Package)
										= Enums.TypesOfItemsPackages.CargoItem);
			
			If ProductLocationsInLine Then
				String.ReadyForProcessing = True;
			EndIf;
		
		EndDo;
		
		// Multiplication of series by packages with the "place of sale" type
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Table.Series      AS Series,
		|	Table.Count AS Count
		|INTO TTSeries
		|FROM
		|	&Table AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Ref AS Package
		|INTO TTPacking
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS Table
		|WHERE
		|	Table.Ref IN(&ArrayOfPackages_)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Series           AS Series,
		|	ListOfPackagings.Package AS Package,
		|	Table.Count      AS QuantityBySeries,
		|	TRUE                  AS ReadyForProcessing
		|FROM
		|	TTSeries AS Table
		|		FULL JOIN TTPacking AS ListOfPackagings
		|		ON (TRUE)";
		Query.SetParameter("Table", TableOfSeries);
		Query.SetParameter("ArrayOfPackages_", PackagingOfGoodsPlaces);
		
		SeriesAndPackagingTable = Query.Execute().Unload();
		
		// 1. Distribution into lines with the specified packages and series
		
		// Adding the number of orders
		Var_Key = "ReadyForProcessing, Package, Series";
		
		Condition = "On [Count]";
		InvoicesServer.AllocateQuantity(SeriesAndPackagingTable, DocumentTable, "QuantityBySeries", Var_Key, Condition, False);
		
		// 2. Distribution to lines with specified packages
		Var_Key = "ReadyForProcessing, Package";
		
		Condition = "On [Count]";
		InvoicesServer.AllocateQuantity(SeriesAndPackagingTable, DocumentTable, "QuantityBySeries", Var_Key, Condition, False);
		
		// 3. Creating new lines for the remaining unallocated part
		If SeriesSpecificationParameters.TSSeriesName = SeriesSpecificationParameters.NameTSGoods Then
			StructureOfActions = Common.CopyRecursive(Actions); // Structure
			StructureOfActions.Insert("RecalculateNumberOfPackages");
			StructureOfActions.Delete("RecalculateNumberOfUnits");
		EndIf;
		
		RowsToProcess = New Array();
		BatchAtTSItems = SeriesSpecificationParameters.TSSeriesName = SeriesSpecificationParameters.NameTSGoods;
		
		For Each String In SeriesAndPackagingTable Do
			If String.QuantityBySeries = 0 Then
				Continue;
			EndIf;
			
			NewRow = Object[SeriesSpecificationParameters.TSSeriesName].Add();
			FillPropertyValues(NewRow, ParametersOfSeriesIndicationForm);
			FillPropertyValues(NewRow, String, "Series, Package");
			NewRow.Count = String.QuantityBySeries;
			
			SeriesRowsToProcess.Add(NewRow);
			
			If BatchAtTSItems Then
				RowsToProcess.Add(NewRow);
			EndIf;
			
		EndDo;
		
		If BatchAtTSItems Then
			
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				RowsToProcess,
				StructureOfActions,
				Object[SeriesSpecificationParameters.TSSeriesName],
				Cached_Values);
				
			For Each ProcessedString In RowsToProcess Do
				NumberOfPackagesAfterRemovalOfSeries = NumberOfPackagesAfterRemovalOfSeries 
					+ ProcessedString.NumberOfPackages; 
			EndDo;
		EndIf;
		
	Else

		RowsToProcess = New Array;
		For Each RowOfTables In TableOfSeries Do
			SearchStructureBySeries = CommonClientServer.CopyStructure(TheStructureOfTheSearch);
			SearchStructureBySeries.Insert("Series", RowOfTables.Series);
			
			OldLines = Object[SeriesSpecificationParameters.TSSeriesName].FindRows(SearchStructureBySeries);
			
			If OldLines.Count() = 0 Then 
				If LineNumberToInsert = 0 Then
					NewRow = Object[SeriesSpecificationParameters.TSSeriesName].Add();
				Else
					NewRow = Object[SeriesSpecificationParameters.TSSeriesName].Insert(LineNumberToInsert - 1);
				EndIf;
			Else
				NewRow = OldLines[0];
				
				If OldLines.Count() > 1 Then
					
					For Each RowArrOldLines In OldLines Do
						If RowArrOldLines <> NewRow Then
							If ParametersOfSeriesIndicationForm.OnlyQuantityEditing Then
								RowArrOldLines[SeriesSpecificationParameters.FieldNameQuantity] = 0;
							Else
								Object[SeriesSpecificationParameters.TSSeriesName].Delete(RowArrOldLines);
							EndIf;
						EndIf;
					EndDo;
					
				EndIf;
				
			EndIf;
			LineNumberToInsert = NewRow.LineNumber + 1;
			
			FillPropertyValues(NewRow,ParametersOfSeriesIndicationForm);
			FillPropertyValues(NewRow,RowOfTables);
			
			If ThereArePackagesOfVTCHSeries
				And ParametersOfSeriesIndicationForm.Property("PackagingForSubstitution") Then
				
				NewRow.Package = ParametersOfSeriesIndicationForm.PackagingForSubstitution;
				
			EndIf;
			
			If SeriesSpecificationParameters.FieldNameQuantity <> "Count"
				And SeriesSpecificationParameters.FieldNameQuantity <> "NumberOfPackages" Then
				If ThereArePackages Then
					NewRow[SeriesSpecificationParameters.FieldNameQuantity] = RowOfTables.NumberOfPackages;
				Else
					NewRow[SeriesSpecificationParameters.FieldNameQuantity] = RowOfTables.Count;
				EndIf;
			EndIf;
			
			SeriesRowsToProcess.Add(NewRow);
			
			If SeriesSpecificationParameters.TSSeriesName = SeriesSpecificationParameters.NameTSGoods Then
				
				If Actions <> Undefined Then
					
					RowsToProcess.Add(NewRow);
					
				EndIf;
				
			EndIf;
			
		EndDo;

		If Actions <> Undefined Then
			
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				RowsToProcess,
				Actions,
				Object[SeriesSpecificationParameters.TSSeriesName],
				Cached_Values);
			
			For Each ProcessedString In RowsToProcess Do
				If ThereArePackagingWHGoods Then
					NumberOfPackagesAfterRemovalOfSeries = NumberOfPackagesAfterRemovalOfSeries + ProcessedString.NumberOfPackages; 
				Else
					NumberOfPackagesBeforeSeriesRemoval = NumberOfPackagesBeforeSeriesRemoval + ArrRow[SeriesSpecificationParameters.FieldNameQuantity];
				EndIf;
			EndDo;
			
		EndIf;

	EndIf;
	
	If SeriesSpecificationParameters.TSSeriesName = SeriesSpecificationParameters.NameTSGoods Then
		
		Delta = NumberOfPackagesAfterRemovalOfSeries - NumberOfPackagesBeforeSeriesRemoval;
		
		If GetFunctionalOption("UseReusablePackage") 
			And ThereArePackages Then
			PackageTable = ReusablePackageServer.ReusablePackagingOfProductRange(ParametersOfSeriesIndicationForm.Products,
																					ParametersOfSeriesIndicationForm.Package); 
			
			For Each RowOfTables In PackageTable Do
				TheStructureOfTheSearch = New Structure;
				TheStructureOfTheSearch.Insert("Products", RowOfTables.Products);
				TheStructureOfTheSearch.Insert("Characteristic", RowOfTables.Characteristic);
				
				TareLines = Object[SeriesSpecificationParameters.NameTSGoods].FindRows(TheStructureOfTheSearch);
				
				If TareLines.Count() = 0 Then
					// If the serial indication form was opened after scanning the barcode of the product,
					// the packaging was added to the document by processing the barcode scan.
					// This means that this condition can work only when manually opening the series form, which is equivalent
					// to manually editing the quantity of goods.
					// When manually editing the quantity of goods, we do not recalculate the packaging.
					Continue;	
				Else
					TareString = TareLines[0];
				EndIf;
				
				TareString.Count         = TareString.Count + Delta * RowOfTables.Count;
				TareString.NumberOfPackages = TareString.Count;
				
			EndDo;
			
		EndIf;
		
		Return;
	EndIf;
	
	If ThereArePackages
		And ValueIsFilled(ParametersOfSeriesIndicationForm.Package) Then //not filled for containers
		SeriesCount = TableOfSeries.Total("NumberOfPackages");
		GoodsQuantity = ParametersOfSeriesIndicationForm.Count 
							/Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(ParametersOfSeriesIndicationForm.Package, ParametersOfSeriesIndicationForm.Products); 
	Else
		SeriesCount = TableOfSeries.Total("Count");
		GoodsQuantity = ParametersOfSeriesIndicationForm.Count;
	EndIf;	
	
	If SeriesSpecificationParameters.ProductInHeader Then
		
		If SeriesCount <> GoodsQuantity 
			And Actions <> Undefined
			And Actions.Property("UpdateNumberOfProductsWhenRegistering")
			And Actions.UpdateNumberOfProductsWhenRegistering Then
			
			Object[SeriesSpecificationParameters.FieldNameQuantity] = SeriesCount;
			GoodsQuantity = SeriesCount;
			BatchProcessingOfTablePartServer.ProcessTSString(Object, Actions, Cached_Values);
			
		EndIf;
		
		SeriesAreIndicatedInFull = (SeriesCount = GoodsQuantity);
		
		ProductsClientServer.RecalculateStatusOfSpecifyingSeriesDuringProcessing(SeriesSpecificationParameters,
																			Object.BatchesIndicationStatus,
																			SeriesAreIndicatedInFull,
																			SeriesCount);
		
	Else

		FoundProductLines = Object[SeriesSpecificationParameters.NameTSGoods].FindRows(TheStructureOfTheSearch);
		
		If SeriesCount <> GoodsQuantity 
			And Actions <> Undefined
			And Actions.Property("UpdateNumberOfProductsWhenRegistering")
			And Actions.UpdateNumberOfProductsWhenRegistering Then
			
			ThereIsRecalculationOfQuantity = False;
			NumberOfUnitsSuffix = "";
			
			If Actions.Property("RecalculateNumberOfUnits") Then
				Actions.Delete("RecalculateNumberOfUnits");
				ThereIsRecalculationOfQuantity = True;
			ElsIf Actions.Property("RecalculateNumberOfSuffixUnits") Then
				NumberOfUnitsSuffix = Actions.RecalculateNumberOfSuffixUnits;
				Actions.Delete("RecalculateNumberOfSuffixUnits");
				ThereIsRecalculationOfQuantity = True;
			EndIf;
			
			If Actions.Property("RecalculateNumberOfPackages") Then
				Actions.Delete("RecalculateNumberOfPackages");
				ThereIsRecalculationOfQuantity = True;
			EndIf;
			
			If ThereIsRecalculationOfQuantity Then
				If ThereArePackages Then
					If NumberOfUnitsSuffix <> "" Then
						Actions.Insert("RecalculateNumberOfSuffixUnits", NumberOfUnitsSuffix);
					Else
						Actions.Insert("RecalculateNumberOfUnits");
					EndIf; 
				Else
					If NumberOfUnitsSuffix <> "" Then
						Actions.Insert("RecalculateNumberOfSuffixPacks", NumberOfUnitsSuffix);
					Else
						Actions.Insert("RecalculateNumberOfPackages");
					EndIf;
				EndIf;
			EndIf;
			
			QuantityToDistribution = SeriesCount - GoodsQuantity;
			
			RowsToProcess = New Array;

			For Each RowOfGoods In FoundProductLines Do
				Delta = QuantityToDistribution;
				
				If -Delta > RowOfGoods[SeriesSpecificationParameters.FieldNameQuantity] Then
					Delta = -RowOfGoods[SeriesSpecificationParameters.FieldNameQuantity];
					RowOfGoods[SeriesSpecificationParameters.FieldNameQuantity] = 0;
				Else
					RowOfGoods[SeriesSpecificationParameters.FieldNameQuantity] = RowOfGoods[SeriesSpecificationParameters.FieldNameQuantity] + Delta;
				EndIf;
				
				GoodsQuantity = GoodsQuantity + Delta;
				
				QuantityToDistribution = QuantityToDistribution - Delta;
				
				RowsToProcess.Add(RowOfGoods);
				
				If ThereArePackages
					And GetFunctionalOption("UseReusablePackage") Then
					PackageTable = ReusablePackageServer.ReusablePackagingOfProductRange(RowOfGoods.Products, RowOfGoods.Package); 
					
					For Each RowOfTables In PackageTable Do
						TheStructureOfTheSearch = New Structure;
						TheStructureOfTheSearch.Insert("Products", RowOfTables.Products);
						TheStructureOfTheSearch.Insert("Characteristic", RowOfTables.Characteristic);
						
						TareLines = Object[SeriesSpecificationParameters.NameTSGoods].FindRows(TheStructureOfTheSearch);
						
						If TareLines.Count() = 0 Then
							// If the serial indication form was opened after scanning the barcode of the product,
							// the packaging was added to the document by processing the barcode scan.
							// This condition can work only when manually opening the series form, which is equivalent
							// to manually editing the quantity of goods. When manually editing the quantity
							// of goods, we do not recalculate the packaging.
							Continue;	
						Else
							TareString = TareLines[0];
						EndIf;
						
						// It is written non-universally, because in all documents in which there is a container, the "Quantity" fields are called as standard.
						TareString.Count         = TareString.Count + Delta * RowOfTables.Count;
						TareString.NumberOfPackages = TareString.Count;
						
						RowsToProcess.Add(TareString);

					EndDo;
					
				EndIf;
				
				If QuantityToDistribution = 0 Then
					Break;
				EndIf;
			EndDo;

			BatchProcessingOfTablePartServer.ProcessTSStrings(
				RowsToProcess,
				Actions,
				Object[SeriesSpecificationParameters.NameTSGoods],
				Cached_Values);

		EndIf;
		
		SeriesAreIndicatedInFull = (SeriesCount = GoodsQuantity
			And (GoodsQuantity > 0
				Or ParametersOfSeriesIndicationForm.OnlyQuantityEditing));
		 // In the mode of only editing the quantity, zero quantity is allowed in both PM Goods and PM Series.
		For Each ArrRow In FoundProductLines Do
				
			If ArrRow.BatchesIndicationStatus = 0 Then
				FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters, FoundProductLines, SeriesRowsToProcess);
				Break;
			EndIf;
		
			If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
				ProductsClientServer.RecalculateStatusOfSpecifyingSeriesDuringProcessing(SeriesSpecificationParameters,
																					ArrRow.BatchesIndicationStatus,
																					SeriesAreIndicatedInFull,
																					SeriesCount,,
																					ArrRow);
			Else
				
				For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
					ProductsClientServer.RecalculateStatusOfSpecifyingSeriesDuringProcessing(SeriesSpecificationParameters,
																						ArrRow[NameOfStatusField],
																						SeriesAreIndicatedInFull,
																						SeriesCount,,
																						ArrRow);
				EndDo;
				
			EndIf;
				
		EndDo;
	EndIf;
#EndRegion	

EndProcedure

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object			 - DocumentObject, FormDataStructure - the document for which you want to form validation settings,
//  ObjectManager	 - DocumentManager - document Manager for which you want to generate validation parameters.
// 
// Returns:
//  Structure - parameters specifying the specifics of specifying the series in each document, the composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object, ObjectManager) Export
	
	AttributesNames = ObjectManager.NamesOfDetailsForFillingInParametersForSpecifyingSeries();
	AttributesValues = ValuesOfDetailsForFillingInParametersForSpecifyingSeries(Object, AttributesNames);
	Return ObjectManager.SeriesSpecificationParameters(AttributesValues);
	
EndFunction

// Saves the scan mode of the series. Used to ensure that the scanning mode is the same for all forms.
//
// Parameters:
//		Form - ClientApplicationForm - the form that should contain the details of the string type scan mode Series.
//
Procedure SaveSeriesScanModeSetting(Form) Export
	
	Common.FormDataSettingsStorageSave("SeriesScanMode","",Form.SeriesScanMode);
	
EndProcedure

// Loads the series scan mode from the settings. If the setting was not previously saved, the product Series mode is used.
//
// Parameters:
//		Form - ClientApplicationForm - the form that should contain the details of the string type scan mode Series.
//
Procedure LoadSeriesScanModeSetting(Form) Export
	
	Form.SeriesScanMode = Common.FormDataSettingsStorageLoad("SeriesScanMode", "",
		"ProductAllSeries");
	
EndProcedure

// Checks whether the series indication form can be opened
//
// Parameters:
//  SeriesUseSettings	 - Structure, FixedStructure - See Catalogs.ItemKinds.SeriesUseSettings
//  SeriesSpecificationParameters		 - Structure, FixedStructure - See ProductsClientServer.SeriesSpecificationParameters
//  ConnectionFieldValues			 - Structure, FixedStructure -
//
Procedure CheckWhetherSeriesIndicationFormCanBeOpened(SeriesUseSettings, SeriesSpecificationParameters, ConnectionFieldValues) Export
	
	If Not SeriesUseSettings.KeepAccountingByBatch Then
		ExceptionText = NStr("vi = 'Đối với dạng mặt hàng ""%ProductKind%"" không sử dụng sê-ri';
							|ru = 'Для вида номенклатуры ""%ProductKind%"" серии не используются';
							|en = 'Batches are not used for the ""%ProductKind%"" item kind'; fa = 'Batches are not used for the ""%ProductKind%"" item kind';
							|it = 'Per tipo di articolo""%ProductKind%"" della serie non si utilizzano';
							|pl = 'Dla rodzaju nomenklatury ""%ProductKind%"" serie nie są wykorzystywane';
							|tr = 'Öğe türü için ""%ProductKind%"" partiler kullanılmıyor ​'");
		
		ExceptionText = StrReplace(ExceptionText, "%ProductKind%",SeriesUseSettings.ProductKind);
		
		Raise ExceptionText;
	EndIf;
	
	ProductsLocalization.CheckWhetherSeriesIndicationFormCanBeOpened(SeriesUseSettings, SeriesSpecificationParameters, ConnectionFieldValues);
	
EndProcedure

// Creates a view of the product for which the series are entered, for display in the headers of the series indication form
//
// Parameters:
//  ConnectionFieldValues	 - Structure, FixedStructure -
// 
// Returns:
//   String 
//
Function PresentationOfGoodsInFormOfIndicationOfSeries(ConnectionFieldValues) Export
	
	OwnGoodsPresentation = ProductsClientServer.ProductPresentation(ConnectionFieldValues.Products, ConnectionFieldValues.Characteristic);
	
	ProductsLocalization.PresentationOfGoodsInFormOfIndicationOfSeries(OwnGoodsPresentation, ConnectionFieldValues);
	
	Return OwnGoodsPresentation;
EndFunction

// Parses the scanned bar code string of the series and returns it as the details values
//
// Parameters:
//  EnteredString				 - String 
//  SeriesUseSettings	 - Structure, FixedStructure - See Catalogs.ItemKinds.SeriesUseSettings
// 
// Returns:
//  Structure - the composition of the fields depends on the entered string and the settings of the use of the series 
//
Function DetailsOfSeriesFromLine(Val EnteredString, SeriesUseSettings) Export
	
	SeriesAttributes = New Structure;
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If LongDesc.Use Then
			SeriesAttributes.Insert(LongDesc.AttributeName);
		EndIf;
	EndDo;
	
	ProductsLocalization.DetailsOfSeriesFromLine(SeriesAttributes, EnteredString, SeriesUseSettings);
		
	Return SeriesAttributes;
	
EndFunction

// Adds the details of the series indication statuses to the tabular part of the products of the client application form.
// It is recommended to use in the event handler of the form of a connection to the server.
//
// Parameters:
// Form - ClientApplicationForm - a form in the tabular part of which the details are added.
// SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters.
//
Procedure AddStatusFieldsForSpecifyingSeries(Form, SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters.ProductInHeader Then
		Return;
	EndIf;
	
	If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() Then
		
		NameTSGoods = SeriesSpecificationParameters.NameTSGoods;
		NameOfValueSourceInObjectForm = SeriesSpecificationParameters.NameOfValueSourceInObjectForm;
		
		If NameOfValueSourceInObjectForm = "ThisForm" Then
			SourceOfDetailsTSGoods = NameTSGoods;
		Else
			SourceOfDetailsTSGoods = NameOfValueSourceInObjectForm + "." + NameTSGoods;
		EndIf;
		
		NamesOfDetailsTSGoods	= Form.GetAttributes(SourceOfDetailsTSGoods);
		TypeOfStatusForSpecifyingSeries	= New TypeDescription("Number", New NumberQualifiers(2, 0));
		AttributesToBeAdded	= New Array;
		
		For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
			ThereAreProps = False;
			
			For Each PropsNamesTSGoods In NamesOfDetailsTSGoods Do
				If PropsNamesTSGoods.Name = NameOfStatusField Then
					ThereAreProps = True;
					
					Break;
				EndIf;
			EndDo;
			
			If Not ThereAreProps Then
				AttributeToAdd = New FormAttribute(NameOfStatusField, TypeOfStatusForSpecifyingSeries, SourceOfDetailsTSGoods);
				
				AttributesToBeAdded.Add(AttributeToAdd);
			EndIf;
		EndDo;
		
		If AttributesToBeAdded.Count() Then
			Form.ChangeAttributes(AttributesToBeAdded);
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in information about the warehouse.
//
// Parameters:
//	Object - FormDataCollection, DocumentObject - the document for which you need to get information about the warehouse.
//	ParametersOfWarehouse - See BarcodingOfItemsClientServer.BarcodeProcessingParameters.
//	SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters.
//
Procedure FillInWarehouseAccordingToParametersOfBatchIndication(Object, ParametersOfWarehouse, SeriesSpecificationParameters) Export
	
	Warehouse = Undefined;
	
	If Not SeriesSpecificationParameters.UseItemsBatch Then
		Return;
	EndIf;
	
	WarehouseFieldName	= SeriesSpecificationParameters.WarehouseFieldName;
	VHFWarehouses		= WarehousesAreIndicatedInTabularPart(SeriesSpecificationParameters);
	
	If WarehouseFieldName <> Undefined Then
		If Not VHFWarehouses
			And SeriesSpecificationParameters.NameOfRecipientWarehouseField <> Undefined
			And SeriesSpecificationParameters.NameOfSenderWarehouseField <> Undefined Then
			
			Warehouse = New Structure;
			Warehouse.Insert("Sender", Object[SeriesSpecificationParameters.NameOfSenderWarehouseField]);
			Warehouse.Insert("Recipient", Object[SeriesSpecificationParameters.NameOfRecipientWarehouseField]);
			
		ElsIf CommonClientServer.HasAttributeOrObjectProperty(Object, WarehouseFieldName) Then
			Warehouse = Object[WarehouseFieldName];
		EndIf;
	EndIf;
	
	ParametersOfWarehouse.Warehouse = Warehouse
	
EndProcedure

// Returns an indication of series accounting by warehouses of the tabular part of goods.
//
// Parameters:
//	SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters.
//
// Returns:
//	Boolean - indicates whether the series is accounted for by warehouses of the tabular part of the goods.
//
Function WarehousesAreIndicatedInTabularPart(SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters = Undefined Then
		Return False;
	EndIf;
	
	If Not SeriesSpecificationParameters.UseItemsBatch Then
		Return False;
	EndIf;
	
	Return SeriesSpecificationParameters.LinkFields.Find(SeriesSpecificationParameters.WarehouseFieldName) <> Undefined
		Or SeriesSpecificationParameters.AdditionalFieldNames.Find(SeriesSpecificationParameters.WarehouseFieldName) <> Undefined;
	
EndFunction

// Returns the Status of specifying the default series for the passed parameters "Item" and "Warehouse".
//
// Parameters:
//	Products			- CatalogRef.Products - The item for which the series indication Status is calculated
//																.
//	Warehouse					- CatalogRef.Warehouses, Structure, Undefined - information about the document warehouse.
//	SeriesSpecificationParameters	- See ProductsClientServer.SeriesSpecificationParameters.
//
// Returns:
//	Number - The Status of specifying the default series.
//
Function DefaultBatchIndicationStatus(Products, Warehouse, SeriesSpecificationParameters) Export
	
	TableOfGoods = TableOfGoodsForCalculatingStatusOfSpecifyingBatches(SeriesSpecificationParameters);
	
	RowOfProduct = TableOfGoods.Add();
	RowOfProduct.LineNumber	= 1;
	RowOfProduct.Products	= Products;
	
	If SeriesSpecificationParameters.ThisIsOrder Then
		If TableOfGoods.Columns.Find("SupplyOption") <> Undefined Then
			RowOfProduct.SupplyOption = Enums.SupplyOptions.Ship;
		EndIf;
	EndIf;
	
	If SeriesSpecificationParameters.ItSWarrant
		And SeriesSpecificationParameters.LinkFields.Find("Action") <> Undefined Then
		
		RowOfProduct.Action = Enums.ActionsWithGoodsIssueNoteRows.Ship;
		
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseFieldName <> Undefined
		And WarehousesAreIndicatedInTabularPart(SeriesSpecificationParameters) Then
		
		RowOfProduct[SeriesSpecificationParameters.WarehouseFieldName] = Warehouse;
		
	EndIf;
	
	TableOfSeries = BatchTableForCalculatingStatusesOfSpecifyingBatches(SeriesSpecificationParameters);
	
	Selection = SelectionFromRequestForCalculatingStatusesForSpecifyingSeries(SeriesSpecificationParameters,
															TableOfGoods,
															TableOfSeries,
															Warehouse);
	
	BatchesIndicationStatus = 0;
	
	If Selection.Next() Then
		BatchesIndicationStatus = Selection.BatchesIndicationStatus;
	EndIf;
	
	Return BatchesIndicationStatus;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsOfFillingInServiceDetailsForProductRange

// Gets service details for the item in the structure
//
// Parameters:
// 		StructureOfData - Structure, ValueTableRow - Data structure to fill in the fields in
// 		StructureOfActions - Structure - Structure with actions for getting service details.
//
Procedure FillInServiceDetailsForProductInStructure(StructureOfData, StructureOfActions) Export
	
	BatchProcessingOfTablePartServer.NormalizeActions(StructureOfActions);
	
	DatabaseStructure = BatchProcessingOfTablePartServer.DescriptionOfAdditionalInformation(StructureOfActions);
	
	ExportedTable = New ValueTable;
	ExportedTable.Columns.Add("LineNumber", New TypeDescription("Number"));
	For Each Source In DatabaseStructure.SourceStructure_1 Do
		ExportedTable.Columns.Add(Source.Key, TMCommonUse.DescriptionOfTypesByType(TypeOf(StructureOfData[Source.Key])));
	EndDo;
	FillPropertyValues(ExportedTable.Add(), StructureOfData);
	
	Query = New Query(BatchProcessingOfTablePartServer.GetRequestTextUsingServiceDetailsOfTS(StructureOfActions, DatabaseStructure));
	Query.SetParameter("DataCollection", ExportedTable);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(StructureOfData, Selection, DatabaseStructure.DetailsOfFillingInForm);
	EndIf;
	
EndProcedure // Fill out the Service Requestionstructure()

// Fills in service details for the item in the collection
//
// Parameters:
//  DataCollection		 - FormDataCollection, ValueTable - Table where you need to fill in your Bank details
//  StructureOfActions	 - Structure							 - Structure with actions for getting service details
//  FillInLines	 - Array, FormDataCollectionItem	 - lines that need to be filled in.
//
Procedure FillInServiceDetailsForProductInCollection(DataCollection, StructureOfActions, FillInLines = Undefined) Export
	
	BatchProcessingOfTablePartServer.NormalizeActions(StructureOfActions);
	
	DatabaseStructure = BatchProcessingOfTablePartServer.DescriptionOfAdditionalInformation(StructureOfActions);
	Columns = "LineNumber" + DatabaseStructure.UploadDetails;
	
	If FillInLines = Undefined Then
		
		If TypeOf(DataCollection) = Type("ValueTable") Then
			CollectionParameter = DataCollection;
		Else
			CollectionParameter = DataCollection.Unload(, Columns);
		EndIf;
		
	ElsIf FillInLines.Count() > 0 Then
		
		If TypeOf(DataCollection) = Type("ValueTable") Then
			CollectionParameter = DataCollection.Copy(FillInLines, Columns);
		Else
			CollectionParameter = DataCollection.Unload(FillInLines, Columns);
		EndIf;
		
	Else
		Return;
	EndIf;
	
	Query = New Query(BatchProcessingOfTablePartServer.GetRequestTextUsingServiceDetailsOfTS(StructureOfActions, DatabaseStructure));
	Query.SetParameter("DataCollection", CollectionParameter);
	
	If FillInLines <> Undefined Then
		
		VTResult = Query.Execute().Unload(); // TabularSection
		For Each Page1 In VTResult Do
			FillPropertyValues(DataCollection[Page1.LineNumber - 1], Page1, DatabaseStructure.DetailsOfFillingInForm);
		EndDo;
		
	Else
		
		Selection = Query.Execute().Select();
		For Number = 0 To DataCollection.Count()-1 Do
			Selection.Next(); // The number of rows in the query selection is always equal to the number of rows in the collection
			FillPropertyValues(DataCollection[Number], Selection, DatabaseStructure.DetailsOfFillingInForm);
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the Attributes for the Item field
// when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextDetailsForItem(StructureOfActions, QueryDetails, CachedValues) Export
	
	For Each Query In QueryDetails.QueriesTexts Do
		If Query.Presentation = "DetailsOfItem" Then
			Return;
		EndIf;
	EndDo;
	
	StructureOfFillingActions = ActionsForFillingInDetailsOfItem(StructureOfActions);
	
	For Each FillingAction In StructureOfFillingActions Do
		If Not BatchProcessingOfTablePartServer.YouNeedToPerformAction(
				FillingAction.Key,
				StructureOfActions,
				CachedValues) Then 
				StructureOfFillingActions.Delete(FillingAction.Key);
		EndIf;
	EndDo;
	
	If StructureOfFillingActions.Count() <> 0 Then
		BatchProcessingOfTablePartServer.NormalizeActions(StructureOfFillingActions);
	
		DatabaseStructure = BatchProcessingOfTablePartServer.DescriptionOfAdditionalInformation(StructureOfFillingActions);
		Columns = "LineNumber" + DatabaseStructure.UploadDetails;
		
		QueryText = BatchProcessingOfTablePartServer.GetRequestTextUsingServiceDetailsOfTS(
									StructureOfFillingActions,
									DatabaseStructure,
									True);
		
		QueryText = StrReplace(QueryText,"&DataCollection", "TTDataSource");
		
		CachedValues.Insert("DetailsOfFillingInItem", DatabaseStructure.DetailsOfFillingInForm);
		
		RequestsForItemData = StrSplit(QueryText, ";");
		QueryDetails.QueriesTexts.Add(RequestsForItemData[0], "TTTableOfProducts");
		QueryDetails.QueriesTexts.Add(RequestsForItemData[1], "DetailsOfItem");

	EndIf;
	
EndProcedure

// Adds a query to the query package to get the data needed to fill in the item barcode
// when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddItemBarcodesToQueryText(StructureOfActions, QueryDetails, CachedValues) Export
	
	If Not BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInGTINInLine", StructureOfActions, CachedValues) Then
		Return;
	EndIf;
	
	QueryText = "SELECT
	|	Goods.IdOfTTRow AS IdOfTTRow,
	|	Barcodes.Barcode    AS GTIN
	|FROM
	|	TTDataSource AS Goods
	|	LEFT JOIN InformationRegister.ItemsBarcodes AS Barcodes
	|		ON Barcodes.Products  = Goods.Products
	|		AND Barcodes.Characteristic = Goods.Characteristic
	|";
	QueryDetails.QueriesTexts.Add(QueryText, "TTTableOfBarcodes");
	
EndProcedure

// Fills in the service Attributes for the nomenclature during batch processing of rows in the table part.
//
// Parameters:
//  StructureOfData - See BatchProcessingOfTablePartServer.ProcessTSString.CurrentRow
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure FillInServiceDetailsForItemInBatchStructure(StructureOfData, StructureOfActions, CachedValues) Export
	
	FillingData = BatchProcessingOfTablePartServer.DataForStringProcessing(
		"DetailsOfItem", CachedValues);
	
	If FillingData <> Undefined Then
		FillPropertyValues(StructureOfData, FillingData[0],
			CachedValues.DetailsOfFillingInItem);
	EndIf;
	
EndProcedure // Fill out the Service Requestionstructure()

// Returns only those actions with the table part string that relate to filling in Attributes 
// 
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
// 
// Returns:
//  Structure - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//
Function ActionsForFillingInDetailsOfItem(StructureOfActions) Export
	
	Var StructureOfActionParameters;
	StructureOfFillingActions = New Structure;
	
	If StructureOfActions.Property("FillInProductTypeAttribute_", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInProductTypeAttribute_", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillInProductTypeAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInProductTypeAttribute", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillInUnitOfMeasurementAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInUnitOfMeasurementAttribute", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillInMeasuredValueTypeAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInMeasuredValueTypeAttribute", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillPackageWeight", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillPackageWeight", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillPackageVolume", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillPackageVolume", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillInUnitOfWeight", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInUnitOfWeight", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillInVolumeUnit", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInVolumeUnit", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("NumberOfPackagesPerUnitOfWeight", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("NumberOfPackagesPerUnitOfWeight", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillInArticleAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInArticleAttribute", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillInCodeAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then

		StructureOfFillingActions.Insert("FillInCodeAttribute", StructureOfActionParameters);
	EndIf;

	If StructureOfActions.Property("FillInDescriptionAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then

		StructureOfFillingActions.Insert("FillInDescriptionAttribute", StructureOfActionParameters);
	EndIf;

	If StructureOfActions.Property("FillInFeatureAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInFeatureAttribute", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillInCCDTrackingAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInCCDTrackingAttribute", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillInRnptTrackingAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInRnptTrackingAttribute", StructureOfActionParameters);
	
	EndIf;
	
	If StructureOfActions.Property("FillInUnitOfMeasurementOfFEA", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInUnitOfMeasurementOfFEA", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillInFeatureThisIsService", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInFeatureThisIsService", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("FillInSalesOptionAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInSalesOptionAttribute", StructureOfActionParameters);
	EndIf;	
	
	If StructureOfActions.Property("FillInSeriesAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		StructureOfFillingActions.Insert("FillInSeriesAttribute", StructureOfActionParameters);
	EndIf;
	
	If StructureOfActions.Property("RecalculateWeightVolume") Then
		StructureOfFillingActions.Insert("RecalculateWeightVolume", StructureOfActions.RecalculateWeightVolume);
	EndIf;
	
	BatchProcessingOfTablePartServerLocalization.FillInServiceDetailsForProductInLineTS(StructureOfActions, 
		StructureOfFillingActions);
	
	Return StructureOfFillingActions;
	
EndFunction

// Procedure for filling in the "characteristics Used" columns in forms.
//
// Parameters:
//  FormTable		 - FormDataCollection		 - table part of the object where you need to fill
//  		in the column " characteristics are Used";
//  FillParameters	 - Structure, Undefined	 - advanced setting.
//
Procedure FillInAttributeForUsingCharacteristics(FormTable,FillParameters = Undefined) Export
	
	Var AdditionalPropsSuffix;
	
	If FormTable.Count() = 0
		Or Not GetFunctionalOption("UseItemVariants") Then
		Return;
	EndIf;
	
	If FillParameters <> Undefined Then
		
		FillParameters.Property("AdditionalPropsSuffix",AdditionalPropsSuffix);	
		
	EndIf;
	
	Query = New Query;
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber,
	|	&ProductNameSuffixOfAdditionalAttributes1,
	|	TableOfGoods.Products AS Products
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber,
	|	&ProductNameSuffixOfAdditionalAttributes2,
	|	CASE
	|		WHEN CAST(TableOfGoods.Products AS Catalog.Products).UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|																											VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|																											VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed
	|FROM
	|	TableOfGoods AS TableOfGoods
	|
	|ORDER BY
	|	LineNumber";
	
	If ValueIsFilled(AdditionalPropsSuffix) Then
		QueryText = StrReplace(QueryText, "&ProductNameSuffixOfAdditionalAttributes1", "TableOfGoods.Products" + AdditionalPropsSuffix + " AS Products" + AdditionalPropsSuffix);
		QueryText = StrReplace(QueryText, "&ProductNameSuffixOfAdditionalAttributes2", "
		|	CASE
		|		WHEN CAST(TableOfGoods.Products" + AdditionalPropsSuffix + " AS Catalog.Products).UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|																																		VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),	
		|																																		VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))	
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ItemVariantsAreUsed" + AdditionalPropsSuffix);
	Else
		QueryText = StrReplace(QueryText, "&ProductNameSuffixOfAdditionalAttributes1,", "");
		QueryText = StrReplace(QueryText, "&ProductNameSuffixOfAdditionalAttributes2,", "");
	EndIf;
	
	Query.Text = QueryText;
	
	AdditionalBankingDetailsLine = ?(Not ValueIsFilled(AdditionalPropsSuffix), "", ",Products"+AdditionalPropsSuffix);
	Query.SetParameter("TableOfGoods",  FormTable.Unload(,"LineNumber,Products"+AdditionalBankingDetailsLine));
	
	TableOfFeatures = Query.Execute().Unload();
	
	For Each RowOfTables In FormTable Do
		
		CharacteristicsString = TableOfFeatures[RowOfTables.LineNumber-1];
		
		RowOfTables.ItemVariantsAreUsed = CharacteristicsString.ItemVariantsAreUsed;
		If ValueIsFilled(AdditionalPropsSuffix) Then
			RowOfTables["ItemVariantsAreUsed"+AdditionalPropsSuffix] = CharacteristicsString["ItemVariantsAreUsed"+AdditionalPropsSuffix];
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ConditionalAppearance

// Set the conditional registration for purposes of item
//
// Parameters:
//		Form - ClientApplicationForm - Contains this form 
//		NameOfDestinationInputField - String - Name of the form element containing the item's characteristics,
//											   if it differs from"product Characteristics".
//		PathToSelectionFieldProductType - String - The full path to the "item Type" attribute,
//									if it differs from " Object.Goods.Type of nomenclature".
//		GoodsOnly - Boolean - True - indicates that conditional registration applies only to goods.
// 
Procedure SetConditionalAppearanceOfProductAssignment(Form,
	                                                            NameOfDestinationInputField = "GoodsPurpose",
																PathToSelectionFieldProductType = "Object.Goods.ItemsType",
																GoodsOnly = True) Export
	
	If Not GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		Return;
	EndIf;
																
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField    = FormItems[NameOfDestinationInputField]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);
	
	FilterGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldProductType);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OperationService;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldProductType);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldProductType);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.EmptyRef();
	
	If GoodsOnly Then
		Text = NStr("vi = '<cho hàng hóa>';
					|ru = '<для товаров>';
					|en = '<for goods>'; fa = '<for goods>';
					|it = '<per le merci>';
					|pl = '<dla towarów>';
					|tr = '<ürünler için>'");
	Else
		Text = NStr("vi = '<dành cho hàng hóa và công việc>';
					|ru = '<для товаров и работ>';
					|en = '<for goods and labor>'; fa = '<for goods and labor>';
					|it = '<per beni e opere>';
					|pl = '<dla towarów i robót>';
					|tr = '<ürünler ve işler için>'");
	EndIf;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", Text);
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
		
EndProcedure

// Returns conditional design parameters for an item field of a different quality.
//
// Returns:
//	Structure - a collection containing the following parameters:
//		* NameOfProductsField - String - the name of the item field of a different quality.
//		* PathToSourceQualityItemField - String - the path to the source quality item field.
//		* StockQualityChangeAttributeIsUsed - Boolean - determines whether there is a feature that stores information about the use
//												of a product of a different quality.
//		* PathToStockQualityChangeField - String - the path to the field that stores information about the use of a product of a different quality.
//
Function ParametersOfConditionalAppearanceOfDifferentQualityItem() Export
	
	ConditionalDesignParameters= New Structure;
	ConditionalDesignParameters.Insert("NameOfProductsField", "GoodsProductsRecordingAsReceived");
	ConditionalDesignParameters.Insert("PathToSourceQualityItemField", "Object.Goods.Products");
	ConditionalDesignParameters.Insert("StockQualityChangeAttributeIsUsed", False);
	ConditionalDesignParameters.Insert("PathToStockQualityChangeField", "");

	Return ConditionalDesignParameters;
	
EndFunction

// Sets the Conditional appearance for the item field of a different quality.
//
// Parameters:
//	Form - ClientApplicationForm - the form in which the Conditional appearance is set.
//	ConditionalDesignParameters - See ParametersOfConditionalAppearanceOfDifferentQualityItem.
//
Procedure SetConditionalAppearanceOfDifferentQualityItem(Form, ConditionalDesignParameters = Undefined) Export
	
	If Not GetFunctionalOption("UseGoodsQuality") Then
		Return;
	EndIf;
	
	If ConditionalDesignParameters = Undefined Then
		ConditionalDesignParameters = ParametersOfConditionalAppearanceOfDifferentQualityItem();
	EndIf;
	
	ConditionalAppearanceItem = Form.ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ConditionalDesignParameters.NameOfProductsField);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToSourceQualityItemField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	If ConditionalDesignParameters.StockQualityChangeAttributeIsUsed Then
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(ConditionalDesignParameters.PathToStockQualityChangeField);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
	EndIf;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("ru = '<укажите товар исходного качества>';
																		|vi = '<specify the goods of original quality>';
																		|en = '<specify the goods of original quality>'; fa = '<specify the goods of original quality>';
																		|it = '<specify the goods of original quality>';
																		|pl = '<specify the goods of original quality>';
																		|tr = '<başlangıç kalitesindeki ürünü belirtin>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

// Setting the conditional design for the item characteristics
//
// Parameters:
// 		Form - ClientApplicationForm - Contains this form 
// 		NameOfCharacteristicInputField - String - Name of the form element containing the item's characteristics,
//											   if it differs from"product Characteristics".
// 		PathToSelectionField - String - The full path to the "characteristics used" attribute,
//									if it differs from " Object.Goods.Characteristics are used".
// 
Procedure EstablishConditionalAppearanceOfProductCharacteristics(Form,
	                                                            NameOfCharacteristicInputField = "GoodsCharacteristic",
																PathToSelectionField = "Object.Goods.ItemVariantsAreUsed") Export
	
	If Not GetFunctionalOption("UseItemVariants") Then
		Return;
	EndIf;
																
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField    = FormItems[NameOfCharacteristicInputField]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
																		|ru = '<характеристики не используются>';
																		|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
																		|it = '<le caratteristiche non vengono usate>';
																		|pl = '<charakterystyki nie dotyczą>';
																		|tr = '<varyantlar kullanılmamaktadır>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

// Setting the conditional design for the item series
//
// Parameters:
//		Form - ClientApplicationForm - Contains this form
//		SpecialOptionForSpecifyingSeries - Boolean, String - False if the series are specified in a separate PM,
//			"Seriivsegdavtchtovary" - if the object does not have a special PM for specifying the series,
//			"seriipriplanirovaniyotgruzkiyavtchtovary" - if the series can be specified in different PM,
//				while the series with the accounting policy "when planning shipment" are specified in PM Goods.
//		SeriesInputFieldName - String - Name of the form element containing the item series,
//									   if it differs from the "product Series".
//		PathToSelectionFieldStatusOfSeriesIndication - String - Full path to the "series indication Status" attribute,
//														if it differs from " Object.Goods.Statuskazaniyasery".
//		PathToSelectionFieldProductType - String - The full path to the "item Type" attribute,
//														if it differs from " Object.Goods.Type of nomenclature".
//
Procedure EstablishConditionalAppearanceOfProductSeries(Form,
														SpecialOptionForSpecifyingSeries,
														SeriesInputFieldName = "GoodsSeries",
														PathToSelectionFieldStatusOfSeriesIndication = "Object.Goods.BatchesIndicationStatus",
														PathToSelectionFieldProductType = "Object.Goods.ItemsType") Export
														
	If Not GetFunctionalOption("UseItemsBatch") Then
		Return;
	EndIf;
	
	SeriesAlwaysWHGoods = (SpecialOptionForSpecifyingSeries = "SeriesAlwaysWHGoods");
	SeriesWhenPlanningShipmentWHGoodsAreIndicated = (SpecialOptionForSpecifyingSeries = "SeriesWhenPlanningShipmentWHGoodsAreIndicated");
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ListOfTypesForSeries = New ValueList;
	ListOfTypesForSeries.Add(Enums.ItemsTypes.OwnGoods);
	ListOfTypesForSeries.Add(Enums.ItemsTypes.ReusablePackage);
	
	// For goods
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	SeriesFormField = FormItems[SeriesInputFieldName]; // FormField
	ItemField.Field = New DataCompositionField(SeriesFormField.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldProductType);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ListOfTypesForSeries;

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
																		|ru = '<для товаров>';
																		|en = '<for goods>'; fa = '<for goods>';
																		|it = '<per le merci>';
																		|pl = '<dla towarów>';
																		|tr = '<ürünler için>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	// The series is not specified
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(SeriesFormField.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldStatusOfSeriesIndication);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldProductType);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfTypesForSeries;

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
																		|ru = '<серия не указывается>';
																		|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
																		|it = '<serie non è indicata>';
																		|pl = '<seria nie jest określana>';
																		|tr = '<parti belirtilmemektedir>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	If Not SeriesAlwaysWHGoods Then
		// The series is specified separately
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(SeriesFormField.Name);
		
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldStatusOfSeriesIndication);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = 0;
		
		FilterGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		ListOfSeriesStatuses = New ValueList;
		ListOfSeriesStatuses.LoadValues(ProductsClientServer.SeriesStatusesYouCanSpecifySeries());
		ListOfSeriesStatuses.Delete(ListOfSeriesStatuses.FindByValue(15));
		If SeriesWhenPlanningShipmentWHGoodsAreIndicated Then
			ListOfSeriesStatuses.Delete(ListOfSeriesStatuses.FindByValue(11));
		EndIf;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldStatusOfSeriesIndication);
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = ListOfSeriesStatuses;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldStatusOfSeriesIndication);
		ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
		
		If SeriesWhenPlanningShipmentWHGoodsAreIndicated Then
			ItemFilter.RightValue = 8;
		Else
			ItemFilter.RightValue = 11;
		EndIf;
		
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldProductType);
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = ListOfTypesForSeries;
		
		ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
		ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<chỉ ra số sê-ri riêng biệt>';
																			|ru = '<серия указывается отдельно>';
																			|en = '<batch is specified separately>'; fa = '<batch is specified separately>';
																			|it = '<la serie è specificata separatamente>';
																			|pl = '<seria jest wskazywana oddzielnie>';
																			|tr = '<parti ayrı olarak belirtilmektedir>'"));
		ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
		
		//
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(SeriesFormField.Name);
		
		ListOfSeriesStatuses = New ValueList;
		ListOfSeriesStatuses.Add(15);
		If SeriesWhenPlanningShipmentWHGoodsAreIndicated Then
			ListOfSeriesStatuses.Add(11);
		EndIf; 
		
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldStatusOfSeriesIndication);
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = ListOfSeriesStatuses;
		
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldProductType);
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = ListOfTypesForSeries;
		
		ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
		
		
	Else
		// The series is indicated in PM Goods
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(SeriesFormField.Name);
		
		ListOfSeriesStatuses = New ValueList;
		ListOfSeriesStatuses.LoadValues(ProductsClientServer.SeriesStatusesYouCanSpecifySeries());
	
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldStatusOfSeriesIndication);
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = ListOfSeriesStatuses;
		
		ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	EndIf;
	
EndProcedure

// Sets the Conditional appearance for the units of measurement of the nomenclature
//
// Parameters:
//		Form - ClientApplicationForm - Contains this form
//		AdditionalParameters - Structure - See NewParametersForConditionalDesignOfUnitsOfMeasurement()
//
Procedure SetConditionalAppearanceOfUnitsOfMeasurement(Form, AdditionalParameters = Undefined) Export

	If AdditionalParameters = Undefined Then
		AdditionalParameters = NewParametersForConditionalDesignOfUnitsOfMeasurement();
	EndIf;

	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.Appearance.SetParameterValue("Show", False);

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField    = FormItems[AdditionalParameters.NameOfUnitField]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);

	If ValueIsFilled(AdditionalParameters.PathToFieldUseBinLocationSystem) Then
		FilterGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		Container = FilterGroup.Items;
	Else
		Container = ConditionalAppearanceItem.Filter.Items;
	EndIf;

	FilterElement = Container.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField(AdditionalParameters.PathToPackagingUnitField);
	FilterElement.ComparisonType = DataCompositionComparisonType.Filled;
	
	If ValueIsFilled(AdditionalParameters.PathToFieldUseBinLocationSystem) Then
		
		If ValueIsFilled(AdditionalParameters.PathToFieldIsTypeOfMeasuredValue) Then
			FilterGroup = Container.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			Container = FilterGroup.Items;
		EndIf;

		FilterElement = Container.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = New DataCompositionField(AdditionalParameters.PathToFieldUseBinLocationSystem);
		FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = True;

		If ValueIsFilled(AdditionalParameters.PathToFieldIsTypeOfMeasuredValue) Then
			DimensionalUnits = New ValueList;
			DimensionalUnits.Add(PredefinedValue("Enum.TypesOfMeasuredValues.Weight"));
			DimensionalUnits.Add(PredefinedValue("Enum.TypesOfMeasuredValues.VolumeM3"));
			DimensionalUnits.Add(PredefinedValue("Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement"));
			DimensionalUnits.Add(PredefinedValue("Enum.TypesOfMeasuredValues.Length"));

			FilterElement = Container.Add(Type("DataCompositionFilterItem"));
			FilterElement.LeftValue = New DataCompositionField(AdditionalParameters.PathToFieldIsTypeOfMeasuredValue);
			FilterElement.ComparisonType = DataCompositionComparisonType.NotInList;
			FilterElement.RightValue = DimensionalUnits;
		EndIf;

	EndIf;
	
EndProcedure

// Additional parameters of the Nomenclaturserver function.Set the conditional formalization of the measurement unit.
// 
// Parameters:
//	BinLocationWarehousingIsUsed - Boolean - Indicates whether address storage is being used.
//	TypeOfMeasuredValueIsUsed - Boolean - Indicates whether the type of measured value is used.
// 
// Returns:
//   Structure - Properties:
// 		* NameOfUnitField - String - The name of the "Measurement unit" form element,
//									   		the default value is "Product nomenclature of the measurement unit".
// 		* PathToPackagingUnitField - String - The name of the form element is "Content",
//									   		the default value is "Object.Products.Packaging".
// 		* PathToFieldUseBinLocationSystem - String - Name of the "Packaging" form element,
//									   		the default value is "product Packaging".
// 		* PathToFieldIsTypeOfMeasuredValue - String - The full path to the props "Variantarticlepath",
//														the default value "Object.Goods.Variantarticlepath".
//
Function NewParametersForConditionalDesignOfUnitsOfMeasurement(BinLocationWarehousingIsUsed = False, TypeOfMeasuredValueIsUsed = False) Export

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NameOfUnitField", "GoodsProductsUnitOfMeasure");
	AdditionalParameters.Insert("PathToPackagingUnitField", "Object.Goods.Package");
	If TypeOfMeasuredValueIsUsed Then
		AdditionalParameters.Insert("PathToFieldIsTypeOfMeasuredValue", "Object.Goods.MeasuredValueType");
	Else
		AdditionalParameters.Insert("PathToFieldIsTypeOfMeasuredValue", "");
	EndIf;
	If BinLocationWarehousingIsUsed Then
		AdditionalParameters.Insert("PathToFieldUseBinLocationSystem", "UseBinLocationWarehousing");
	Else
		AdditionalParameters.Insert("PathToFieldUseBinLocationSystem", "");
	EndIf;

	Return AdditionalParameters;

EndFunction

// Additional options Nomenclaturally.Set the conditional form of the content.
// 
// Returns:
//   Structure - Properties:
// 		* NameOfContentInputField - String - Name of the "Content" form element,
//									   		the default value is "product Content".
// 		* NameOfPackageInputField - String - Name of the "Packaging" form element,
//									   		the default value is "product Packaging".
// 		* PathToDesignOptionSelectionField - String - The full path to the props "Variantarticlepath",
//														the default value "Object.Goods.Variantarticlepath".
// 		* PathToContentSelectionField - String - Full path to the "Content" attribute,
//												the default value is " Object.Goods.Content".
//
Function AdditionalParametersSetConditionalAppearanceOfContent() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NameOfContentInputField", "GoodsContent");
	AdditionalParameters.Insert("NameOfPackageInputField", "GoodsPackage");
	AdditionalParameters.Insert("PathToDesignOptionSelectionField", "Object.Goods.SaleRegistrationOption");
	AdditionalParameters.Insert("PathToContentSelectionField", "Object.Goods.Content");
	
	Return AdditionalParameters;
	
EndFunction

// We set the conditional design of the content depending on the version of the sale design.
//
// Parameters:
//	Form - ClientApplicationForm - a form for which elements are configured for conditional formatting;
//	AdditionalParameters - Structure - LongDesc See ProductsServer.AdditionalParametersSetConditionalAppearanceOfContent.
//
Procedure EstablishConditionalAppearanceOfContent(Form, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalParametersSetConditionalAppearanceOfContent();
	EndIf;
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField = FormItems[AdditionalParameters.NameOfContentInputField]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(AdditionalParameters.PathToDesignOptionSelectionField);
	
	ListOfTypesOfSalesDesignOptions = New ValueList;
	ListOfTypesOfSalesDesignOptions.Add(Enums.SalesRegistrationOptions.CustomerInvoice);
	ListOfTypesOfSalesDesignOptions.Add(Enums.SalesRegistrationOptions.DeedOfTransfer);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfTypesOfSalesDesignOptions;

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<cho công việc, tạo biên bản>';
																		|ru = '<для работ, оформляемых актом>';
																		|en = '<for works registered with the certificate>'; fa = '<for works registered with the certificate>';
																		|it = '<per le opere eseguite in atto>';
																		|pl = '<dla robót, sporządzanych w akcie>';
																		|tr = '<TİS ile düzenlenen işler için>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", GetFunctionalOption("NotBaseVersion"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField = FormItems[AdditionalParameters.NameOfContentInputField]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(AdditionalParameters.PathToDesignOptionSelectionField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SalesRegistrationOptions.CustomerInvoiceServices;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(AdditionalParameters.PathToContentSelectionField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);	
	
	//

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField = FormItems[AdditionalParameters.NameOfPackageInputField]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(AdditionalParameters.PathToDesignOptionSelectionField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SalesRegistrationOptions.CustomerInvoiceServices;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Enabled", False);
	
EndProcedure

// Returns the parameters used when setting the Conditional appearance of the CCD number field.
//
// Returns:
//	Structure - parameters used when setting the Conditional appearance of the CCD number field, with the following properties:
//		* NameOfFieldForEnteringCCDNumber - String - the name of the CCD number field.
//		* PathToFieldIsRecordedAccordingToCCD - String - the path to the value of the field that stores information about CCD accounting.
//		* PathToItemTypeField - String - path to the field value that stores information about the item type.
//		* PathToFieldOfCorrectionAttributePUPA - String - the path to the field value that stores information about the use of the document for adjusting the purchase of services and other assets.
//
Function ParametersForSettingConditionalAppearanceOfCCDNumber() Export
	
	ConditionalDesignParameters = New Structure;
	ConditionalDesignParameters.Insert("NameOfFieldForEnteringCCDNumber",					"GoodsCCDNumber");
	ConditionalDesignParameters.Insert("PathToFieldIsRecordedAccordingToCCD",				"Object.Goods.TheRecordsAreKeptByCCD");
	ConditionalDesignParameters.Insert("PathToItemTypeField",				"Object.Goods.ItemsType");
	ConditionalDesignParameters.Insert("PathToFieldOfCorrectionAttributePUPA",	"");
	
	Return ConditionalDesignParameters;
	
EndFunction

// Setting the conditional registration of GTD numbers
//
// Parameters:
//	Form - ClientApplicationForm - contains form data
//	ConditionalDesignParameters - See ParametersForSettingConditionalAppearanceOfCCDNumber.
//
Procedure SetConditionalAppearanceOfCCDNumber(Form, ConditionalDesignParameters = Undefined) Export
	
	If ConditionalDesignParameters = Undefined Then
		ConditionalDesignParameters = ParametersForSettingConditionalAppearanceOfCCDNumber();
	EndIf;
	
	NameOfFieldForEnteringCCDNumber			= ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber;
	PathToFieldIsRecordedAccordingToCCD		= ConditionalDesignParameters.PathToFieldIsRecordedAccordingToCCD;
	PathToFieldOfProductBatchIDSelectionFeature	= ConditionalDesignParameters.PathToFieldOfCorrectionAttributePUPA;
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField    = FormItems[NameOfFieldForEnteringCCDNumber]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldIsRecordedAccordingToCCD);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	If PathToFieldOfProductBatchIDSelectionFeature <> "" Then
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToFieldOfProductBatchIDSelectionFeature);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
	EndIf;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", ProductsLocalization.TextOfCCDField());
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	If PathToFieldOfProductBatchIDSelectionFeature <> "" Then
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		FormField    = FormItems[NameOfFieldForEnteringCCDNumber]; // FormField
		ItemField.Field = New DataCompositionField(FormField.Name);
		
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToFieldIsRecordedAccordingToCCD);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToFieldOfProductBatchIDSelectionFeature);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<Số đăng ký lô hàng không được sử dụng>';
																			|ru = '<РНПТ не используются>';
																			|en = '<RNPT is not used>'; fa = '<RNPT is not used>';
																			|it = '<РНПТ не используются>';
																			|pl = '<RNPT is not used>';
																			|tr = '<RNPT kullanılmamaktadır>'"));
		ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	EndIf;
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField    = FormItems[NameOfFieldForEnteringCCDNumber]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);
	
	FilterGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldIsRecordedAccordingToCCD);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RestrictGoodsReceiptWithoutCCDNumbers");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

// Setting the conditional design for the statuses of specifying series
//
// Parameters:
//		Form - ClientApplicationForm - Contains this form
//		SeriesAlwaysWHGoods - Boolean - True if the object does not have a special PM for specifying the series
//		NameOfSeriesIndicationStatusInputField - String - The name of the form element that contains the status indication
//									   				series nomenclature,if it differs from the "Touristhouseliberty"
//		PathToSelectionField - String - Full path to the "Statuskazaniyasery" props,
//									if it differs from " Object.Goods.Statuskazaniyasery".
//
Procedure SetConditionalAppearanceOfStatusIndicationSeries(Form,
															SeriesAlwaysWHGoods,	
													  		NameOfSeriesIndicationStatusInputField = "GoodsBatchesIndicationStatus",
													 		PathToSelectionField = "Object.Goods.BatchesIndicationStatus") Export
	
	If SeriesAlwaysWHGoods Then
		If Not GetFunctionalOption("UseItemsBatch") Then
			Return;
		EndIf;												
	ElsIf Not GetFunctionalOption("UseCostAccountingByBatchesWarehouse") Then
		Return;
	EndIf;
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField = FormItems[NameOfSeriesIndicationStatusInputField]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Show", False);	
	
EndProcedure

#EndRegion

#Region DivisionIntoProductLocationsCollectionIntoSet

Procedure SplitProductsByProductLocations(TabularPartProducts) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	Products.Ref AS Products,
	|	PackagesAndUnitsOfMeasure.Ref AS CargoItem,
	|	PackagesAndUnitsOfMeasure.NumberOfPackages AS NumberOfItems
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON (CASE
	|				WHEN Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|					THEN PackagesAndUnitsOfMeasure.Owner = Products.Ref
	|				WHEN Products.PackagingGroup <> VALUE(Catalog.PackagingGroups.EmptyRef)
	|					THEN PackagesAndUnitsOfMeasure.Owner = Products.PackagingGroup
	|				ELSE FALSE
	|			END)
	|WHERE
	|	Products.Ref IN(&ItemList)
	|	AND NOT PackagesAndUnitsOfMeasure.DeletionMark
	|	AND PackagesAndUnitsOfMeasure.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	TableOfGoods = TabularPartProducts.Unload();
	Query.SetParameter("ItemList", TableOfGoods.UnloadColumn("Products"));
	ProductsAndPackaging = Query.Execute().Unload();
	PackagingProductLocations = ProductsAndPackaging.UnloadColumn("CargoItem");
	
	If ProductsAndPackaging.Count() > 0 Then
		
		TabularPartProducts.Clear();
		
		For Each String In TableOfGoods Do
			If PackagingProductLocations.Find(String.Package) <> Undefined Then
				AddAndFillLine(TabularPartProducts, String);
			Else
				ProductPackages = ProductsAndPackaging.FindRows(New Structure("Products", String.Products));
				If ProductPackages.Count() = 0 Then
					AddAndFillLine(TabularPartProducts, String);
				Else
					For Each StringPacking In ProductPackages Do
						NewRow = AddAndFillLine(TabularPartProducts, String);
						NewRow.NumberOfPackages = NewRow.Count * StringPacking.NumberOfItems;  
						NewRow.Package = StringPacking.CargoItem;
					EndDo;
				EndIf;
			EndIf;
		EndDo;
		
	EndIf;
EndProcedure

Procedure CheckCompletenessOfProductLocations(TabularPartOfGoods, Cancel, CheckParameters = Undefined) Export  
	
	If CheckParameters = Undefined Then
		CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	EndIf;
	
	TableOfGoods = TabularPartOfGoods.Unload();
	
	HasErrors = False;	
	
	Query = New Query;
	QueryText =
	"SELECT
	|	CAST(Table.Products AS Catalog.Products) AS Products,
	|	CAST(Table.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(Table.Series AS Catalog.ItemsBatches) AS Series,
	|	&GroupFields,
	|	CAST(Table.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages
	|INTO TableOfGoods
	|FROM
	|	&Table AS Table
	|WHERE
	|	&ConditionForSelectingCompletenessCheckLines
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Series AS Series,
	|	&GroupFields,
	|	Table.Package AS Package,
	|	Table.Products.Description AS ProductsPresentation,
	|	Table.Characteristic.Description AS CharacteristicPresentation,
	|	PRESENTATION(Table.Series) AS SeriesPresentation,
	|	SUM(Table.Count) AS Count,
	|	SUM(Table.NumberOfPackages) AS NumberOfPackages
	|FROM
	|	TableOfGoods AS Table
	|WHERE
	|	ISNULL(Table.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|GROUP BY
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Series,
	|	&GroupFields,
	|	Table.Package,
	|	Table.Characteristic.Description,
	|	Table.Products.Description
	|TOTALS BY
	|	Products,
	|	Characteristic,
	|	&GroupFields,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Products.Ref AS Products,
	|	Products.UnitOfMeasure AS UnitOfMeasure,
	|	PackagesAndUnitsOfMeasure.Ref AS Package,
	|	PackagesAndUnitsOfMeasure.NumberOfPackages AS NumberOfItems
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON (PackagesAndUnitsOfMeasure.Owner = Products.Ref)
	|WHERE
	|	Products.Ref IN
	|			(SELECT
	|				TableOfGoods.Products AS Products
	|			FROM
	|				TableOfGoods AS TableOfGoods)
	|	AND PackagesAndUnitsOfMeasure.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	AND PackagesAndUnitsOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|	AND NOT PackagesAndUnitsOfMeasure.DeletionMark
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Products.Ref,
	|	Products.UnitOfMeasure,
	|	PackagesAndUnitsOfMeasure.Ref,
	|	PackagesAndUnitsOfMeasure.NumberOfPackages
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON (PackagesAndUnitsOfMeasure.Owner = Products.PackagingGroup)
	|WHERE
	|	Products.Ref IN
	|			(SELECT
	|				TableOfGoods.Products AS Products
	|			FROM
	|				TableOfGoods AS TableOfGoods)
	|	AND PackagesAndUnitsOfMeasure.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	AND PackagesAndUnitsOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|	AND NOT PackagesAndUnitsOfMeasure.DeletionMark";
	
	If CheckParameters.ConditionForSelectingCompletenessCheckLines <> "" Then
		QueryText = StrReplace(QueryText, "&ConditionForSelectingCompletenessCheckLines", 
									StrReplace(CheckParameters.ConditionForSelectingCompletenessCheckLines, CheckParameters.TSName + ".", "Table."));
	Else
		QueryText = StrReplace(QueryText, "&ConditionForSelectingCompletenessCheckLines", "TRUE");
	EndIf;
	
	TextOfDimensionField = CheckParameters.FieldsForCheckingCompleteness;
	
	If TabularPartOfGoods.Count() <> 0 Then
		If CommonClientServer.HasAttributeOrObjectProperty(TabularPartOfGoods[0], "Purpose") Then
			DestinationField_ = ?(ValueIsFilled(TextOfDimensionField), "Purpose,", "Purpose");
			TextOfDimensionField = DestinationField_ + TextOfDimensionField;
		EndIf;
	EndIf;
	
	TextOfDimensionField = StrReplace(TextOfDimensionField, " ", "");
	TextOfDimensionField = StrReplace(TextOfDimensionField, ",", ",Table.");
	If ValueIsFilled(TextOfDimensionField) Then
		TextOfDimensionField = "Table." + TextOfDimensionField;
		QueryText = StrReplace(QueryText, "&GroupFields", TextOfDimensionField);
	Else
		QueryText = StrReplace(QueryText, "&GroupFields,", "");
	EndIf;
	
	MaximumFieldNumber = StrSplit(TextOfDimensionField, ",").Count();
	
	Query.Text = QueryText;
	Query.SetParameter("Table", TableOfGoods);
	QueryResult 		= Query.ExecuteBatch();
	SelectionByProductType_ 	= QueryResult[1].Select(QueryResultIteration.ByGroups);
	TableOfProductLocations 	= QueryResult[2].Unload();
		
	While SelectionByProductType_.Next() Do
		ProductLocationsByProductType = TableOfProductLocations.Copy(New Structure("Products", SelectionByProductType_.Products));
		If ProductLocationsByProductType.Count() = 0 Then
			Continue;
		EndIf;
		SelectionByCharacteristic = SelectionByProductType_.Select(QueryResultIteration.ByGroups);	
		While SelectionByCharacteristic.Next() Do
			
			RecursivelyTraverseDimensionFields(SelectionByCharacteristic, ProductLocationsByProductType, 1, MaximumFieldNumber, HasErrors);
				
		EndDo;
	EndDo;
	
	Cancel = ?(HasErrors, True, Cancel);
				
EndProcedure

// Parameters:
// 	Selection - QueryResultSelection
//
Procedure RecursivelyTraverseDimensionFields(Selection, ProductLocationsByProductType, CurFieldNumber, MaximumFieldNumber, HasErrors)
	
	If CurFieldNumber > MaximumFieldNumber Then
		ContinueTraversingSeries(Selection, ProductLocationsByProductType, HasErrors);
	Else
		SelectingNextLevel = Selection.Select(QueryResultIteration.ByGroups);			
		While SelectingNextLevel.Next() Do
			RecursivelyTraverseDimensionFields(SelectingNextLevel, ProductLocationsByProductType, CurFieldNumber + 1, MaximumFieldNumber, HasErrors); 
		EndDo;
	EndIf;
	
EndProcedure

Procedure ContinueTraversingSeries(Selection, ProductLocationsByProductType, HasErrors)
	
	ThereIsDestinationField = CommonClientServer.HasAttributeOrObjectProperty(Selection, "Purpose");
	
	SamplingBySeries = Selection.Select(QueryResultIteration.ByGroups);
	While SamplingBySeries.Next() Do 
		SampleByPackage = SamplingBySeries.Select();
		
		NumberOfWholeSets = 999999999;
		MaximumNumberOfSets = 0;
		
		If SampleByPackage.Count() <> ProductLocationsByProductType.Count() Then
			NumberOfWholeSets = 0;
		EndIf;
		
		ColumnQuantityInDocument = ProductLocationsByProductType.Columns.Find("QuantityOfGoodsInDocument");
		
		If ColumnQuantityInDocument = Undefined Then
			ProductLocationsByProductType.Columns.Add("QuantityOfGoodsInDocument", New TypeDescription("Number"));
		Else
			ProductLocationsByProductType.FillValues(0, "QuantityOfGoodsInDocument");
		EndIf;
		
		While SampleByPackage.Next() Do
			
			FoundRows = ProductLocationsByProductType.FindRows(New Structure("Package", SampleByPackage.Package));
			If FoundRows.Count() > 0 Then 
				ProductLocationLine = FoundRows[0];
			Else 
				Continue;
			EndIf;
			
			NumberOfItems = ProductLocationLine.NumberOfItems;
			NumberOfWholeSets = Min(NumberOfWholeSets, Int(SampleByPackage.NumberOfPackages / NumberOfItems));
			MaximumNumberOfCurSets = RoundUpRoughly(SampleByPackage.NumberOfPackages / NumberOfItems);
			MaximumNumberOfSets = Max(MaximumNumberOfSets, MaximumNumberOfCurSets);
			
			ProductLocationLine.QuantityOfGoodsInDocument = SampleByPackage.NumberOfPackages;

		EndDo;
		
		ShortageDescriptions = New Array;
		SurplusDescriptions = New Array;
		
		For Each ProductLocationLine_ In ProductLocationsByProductType Do
			ExcessQuantity = ProductLocationLine_.QuantityOfGoodsInDocument - NumberOfWholeSets * ProductLocationLine_.NumberOfItems;
			QuantityShortage_ = MaximumNumberOfSets * ProductLocationLine_.NumberOfItems - ProductLocationLine_.QuantityOfGoodsInDocument;
			If ExcessQuantity > 0 Then
				SurplusDescriptions.Add(String(ExcessQuantity) + Chars.NBSp + ProductLocationLine_.Package);					
			EndIf;
			If QuantityShortage_ > 0 Then
				ShortageDescriptions.Add(String(QuantityShortage_) + Chars.NBSp + ProductLocationLine_.Package);
			EndIf;
		EndDo;
		
		If SurplusDescriptions.Count() <> 0 Or ShortageDescriptions.Count() <> 0 Then
			HasErrors = True;
			UserMessage = NStr("vi = 'Từ các mục sau đây, không thể thu thập số nguyên %Ed% của sản phẩm ""%OwnGoods%"":%DescriptionOfSurpluses%. Bạn phải xóa các mục này hoặc thêm các mục: %DescriptionOfDeficiencies%.';
								|ru = 'Из следующих товарных мест нельзя собрать целое количество %Ed% товара ""%OwnGoods%"": %DescriptionOfSurpluses%. Необходимо или удалить эти товарные места, или дополнить товарными местами: %DescriptionOfDeficiencies%.';
								|en = 'Cannot assemble the entire quantity %Ed% of ""%OwnGoods%"" goods from the following cargo items: %DescriptionOfSurpluses%. Either delete these cargo items, or add the following cargo items: %DescriptionOfDeficiencies%.'; fa = 'Cannot assemble the entire quantity %Ed% of ""%OwnGoods%"" goods from the following cargo items: %DescriptionOfSurpluses%. Either delete these cargo items, or add the following cargo items: %DescriptionOfDeficiencies%.';
								|it = 'Dai seguenti luoghi di prodotto, non è possibile raccogliere un numero intero di %Ed% del prodotto ""%OwnGoods%"": %DescriptionOfSurpluses%. È necessario o eliminare questi marchi di luogo, o di integrare marchi posti: %DescriptionOfDeficiencies%.';
								|pl = 'Z następujących miejsc towarowych nie można zebrać całą ilość %Ed% towaru ""%OwnGoods%"": %DescriptionOfSurpluses%. Należy albo usunąć te miejsca towarowe, albo dodać miejsca towarowe: %DescriptionOfDeficiencies%.';
								|tr = 'Aşağıdaki kargo paketlerinden ""%OwnGoods%"" ürünün %Ed% tamsayı miktarını toplamak mümkün değildir: %DescriptionOfSurpluses%. Bu kargo paketlerinin silinmesi veya bunları şu kargo paketleriyle tamamlanması gerekir: %DescriptionOfDeficiencies%.'");
			DescriptionOfSurpluses = StrConcat(SurplusDescriptions, ", ");
			DescriptionOfDeficiencies = StrConcat(ShortageDescriptions, ", ");
			UserMessage = StrReplace(UserMessage, "%DescriptionOfSurpluses%", 	DescriptionOfSurpluses);
			UserMessage = StrReplace(UserMessage, "%DescriptionOfDeficiencies%", 	DescriptionOfDeficiencies);
			UserMessage = StrReplace(UserMessage, "%Ed%", 				ProductLocationsByProductType[0].UnitOfMeasure);
			Purpose = ?(ThereIsDestinationField, SamplingBySeries.Purpose, "");
			GoodsPresentation = ProductsClientServer.ProductPresentation(
											SamplingBySeries.ProductsPresentation,
											SamplingBySeries.CharacteristicPresentation,
											, // Package
											SamplingBySeries.SeriesPresentation,
											Purpose);
			UserMessage = StrReplace(UserMessage, "%OwnGoods%", GoodsPresentation);
			CommonClientServer.MessageToUser(UserMessage);
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks the completeness of the items in the shipment orders 
//
// Parameters:
//  Object - DocumentObject.GoodsIssueNote, DocumentObject.GoodsTransferNote - the document being processed.
//
Procedure FillInActionOnCompletenessOfProductPlaces(Object) Export 
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	CAST(ShippedGoods.Products AS Catalog.Products) AS Products,
	|	ShippedGoods.Characteristic,
	|	ShippedGoods.Purpose,
	|	ShippedGoods.Series,
	|	CAST(ShippedGoods.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	ShippedGoods.NumberOfPackages AS NumberOfPackages,
	|	ShippedGoods.Action
	|INTO ShippedGoods
	|FROM
	|	&ShippedGoods AS ShippedGoods
	|WHERE
	|	&ConditionOnPackingLists
	|	AND ShippedGoods.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShippedGoods.Products,
	|	ShippedGoods.Characteristic,
	|	ShippedGoods.Purpose,
	|	ShippedGoods.Series,
	|	ShippedGoods.Package,
	|	ShippedGoods.Action,
	|	SUM(ShippedGoods.NumberOfPackages) AS NumberOfPackages
	|INTO ShippingItems
	|FROM
	|	ShippedGoods AS ShippedGoods
	|WHERE
	|	ISNULL(ShippedGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|GROUP BY
	|	ShippedGoods.Products,
	|	ShippedGoods.Characteristic,
	|	ShippedGoods.Purpose,
	|	ShippedGoods.Series,
	|	ShippedGoods.Package,
	|	ShippedGoods.Action
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.Action,
	|	PackagesAndUnitsOfMeasure.Ref AS CargoItem,
	|	PackagesAndUnitsOfMeasure.NumberOfPackages
	|INTO ProductItemsLocations
	|FROM
	|	ShippingItems AS Goods
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON Goods.Products.PackagingGroup = PackagesAndUnitsOfMeasure.Owner
	|WHERE
	|	NOT PackagesAndUnitsOfMeasure.DeletionMark
	|	AND PackagesAndUnitsOfMeasure.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.Action,
	|	PackagesAndUnitsOfMeasure.Ref,
	|	PackagesAndUnitsOfMeasure.NumberOfPackages
	|FROM
	|	ShippingItems AS Goods
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON Goods.Products = PackagesAndUnitsOfMeasure.Owner
	|WHERE
	|	NOT PackagesAndUnitsOfMeasure.DeletionMark
	|	AND PackagesAndUnitsOfMeasure.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductItemsLocations.Products,
	|	ProductItemsLocations.Characteristic,
	|	ProductItemsLocations.Purpose,
	|	ProductItemsLocations.Series,
	|	ProductItemsLocations.Action,
	|	MIN(CASE
	|			WHEN ISNULL(ShippingItems.NumberOfPackages, 0) / ProductItemsLocations.NumberOfPackages - (CAST(ISNULL(ShippingItems.NumberOfPackages, 0) / ProductItemsLocations.NumberOfPackages AS NUMBER(12, 0))) >= 0
	|				THEN CAST(ISNULL(ShippingItems.NumberOfPackages, 0) / ProductItemsLocations.NumberOfPackages AS NUMBER(12, 0))
	|			ELSE (CAST(ISNULL(ShippingItems.NumberOfPackages, 0) / ProductItemsLocations.NumberOfPackages AS NUMBER(12, 0))) - 1
	|		END) AS NumberOfSets
	|INTO TableNumberOfSetsToShip
	|FROM
	|	ProductItemsLocations AS ProductItemsLocations
	|		LEFT JOIN ShippingItems AS ShippingItems
	|		ON ProductItemsLocations.Products = ShippingItems.Products
	|			AND ProductItemsLocations.Characteristic = ShippingItems.Characteristic
	|			AND ProductItemsLocations.Purpose = ShippingItems.Purpose
	|			AND ProductItemsLocations.Series = ShippingItems.Series
	|			AND ProductItemsLocations.Action = ShippingItems.Action
	|			AND ProductItemsLocations.CargoItem = ShippingItems.Package
	|WHERE
	|	ProductItemsLocations.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship)
	|
	|GROUP BY
	|	ProductItemsLocations.Products,
	|	ProductItemsLocations.Characteristic,
	|	ProductItemsLocations.Purpose,
	|	ProductItemsLocations.Series,
	|	ProductItemsLocations.Action
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InternalQuery.Products,
	|	InternalQuery.Characteristic,
	|	InternalQuery.Purpose,
	|	InternalQuery.Series,
	|	InternalQuery.Action,
	|	InternalQuery.Package,
	|	SUM(InternalQuery.NumberOfPackages) AS NumberOfPackages
	|INTO TableNumberOfPackagesToSelect
	|FROM
	|	(SELECT
	|		ShippingItems.Products AS Products,
	|		ShippingItems.Characteristic AS Characteristic,
	|		ShippingItems.Purpose AS Purpose,
	|		ShippingItems.Series AS Series,
	|		ShippingItems.Action AS Action,
	|		ShippingItems.Package AS Package,
	|		ShippingItems.NumberOfPackages - ISNULL(TableNumberOfSetsToShip.NumberOfSets, 0) * ShippingItems.Package.NumberOfPackages AS NumberOfPackages
	|	FROM
	|		ShippingItems AS ShippingItems
	|			LEFT JOIN TableNumberOfSetsToShip AS TableNumberOfSetsToShip
	|			ON ShippingItems.Products = TableNumberOfSetsToShip.Products
	|				AND ShippingItems.Characteristic = TableNumberOfSetsToShip.Characteristic
	|				AND ShippingItems.Purpose = TableNumberOfSetsToShip.Purpose
	|				AND ShippingItems.Series = TableNumberOfSetsToShip.Series
	|				AND ShippingItems.Action = TableNumberOfSetsToShip.Action
	|	WHERE
	|		ShippingItems.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShippingItems.Products,
	|		ShippingItems.Characteristic,
	|		ShippingItems.Purpose,
	|		ShippingItems.Series,
	|		ShippingItems.Action,
	|		ShippingItems.Package,
	|		ShippingItems.NumberOfPackages
	|	FROM
	|		ShippingItems AS ShippingItems
	|	WHERE
	|		ShippingItems.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)) AS InternalQuery
	|
	|GROUP BY
	|	InternalQuery.Products,
	|	InternalQuery.Characteristic,
	|	InternalQuery.Purpose,
	|	InternalQuery.Series,
	|	InternalQuery.Action,
	|	InternalQuery.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductItemsLocations.Products,
	|	ProductItemsLocations.Characteristic,
	|	ProductItemsLocations.Purpose,
	|	ProductItemsLocations.Series,
	|	ProductItemsLocations.Action,
	|	MIN(CASE
	|			WHEN ISNULL(TableNumberOfPackagesToSelect.NumberOfPackages, 0) / ProductItemsLocations.NumberOfPackages - (CAST(ISNULL(TableNumberOfPackagesToSelect.NumberOfPackages, 0) / ProductItemsLocations.NumberOfPackages AS NUMBER(12, 0))) >= 0
	|				THEN CAST(ISNULL(TableNumberOfPackagesToSelect.NumberOfPackages, 0) / ProductItemsLocations.NumberOfPackages AS NUMBER(12, 0))
	|			ELSE (CAST(ISNULL(TableNumberOfPackagesToSelect.NumberOfPackages, 0) / ProductItemsLocations.NumberOfPackages AS NUMBER(12, 0))) - 1
	|		END) AS NumberOfSets
	|INTO TableNumberOfSetsToSelect
	|FROM
	|	ProductItemsLocations AS ProductItemsLocations
	|		LEFT JOIN TableNumberOfPackagesToSelect AS TableNumberOfPackagesToSelect
	|		ON ProductItemsLocations.Products = TableNumberOfPackagesToSelect.Products
	|			AND ProductItemsLocations.Characteristic = TableNumberOfPackagesToSelect.Characteristic
	|			AND ProductItemsLocations.Purpose = TableNumberOfPackagesToSelect.Purpose
	|			AND ProductItemsLocations.Series = TableNumberOfPackagesToSelect.Series
	|			AND ProductItemsLocations.Action = TableNumberOfPackagesToSelect.Action
	|			AND ProductItemsLocations.CargoItem = TableNumberOfPackagesToSelect.Package
	|
	|GROUP BY
	|	ProductItemsLocations.Products,
	|	ProductItemsLocations.Characteristic,
	|	ProductItemsLocations.Purpose,
	|	ProductItemsLocations.Series,
	|	ProductItemsLocations.Action
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InternalTable.Products,
	|	InternalTable.Characteristic,
	|	InternalTable.Purpose,
	|	InternalTable.Series,
	|	InternalTable.Package,
	|	InternalTable.NumberOfPackagesInSet,
	|	InternalTable.Action,
	|	SUM(InternalTable.NumberOfPackages) AS NumberOfPackages
	|FROM
	|	(SELECT
	|		ShippingItems.Products AS Products,
	|		ShippingItems.Characteristic AS Characteristic,
	|		ShippingItems.Purpose AS Purpose,
	|		ShippingItems.Series AS Series,
	|		ShippingItems.Package AS Package,
	|		ShippingItems.Package.NumberOfPackages AS NumberOfPackagesInSet,
	|		ShippingItems.Action AS Action,
	|		ISNULL(TableNumberOfSetsToShip.NumberOfSets, 0) * ShippingItems.Package.NumberOfPackages AS NumberOfPackages
	|	FROM
	|		ShippingItems AS ShippingItems
	|			LEFT JOIN TableNumberOfSetsToShip AS TableNumberOfSetsToShip
	|			ON ShippingItems.Products = TableNumberOfSetsToShip.Products
	|				AND ShippingItems.Characteristic = TableNumberOfSetsToShip.Characteristic
	|				AND ShippingItems.Purpose = TableNumberOfSetsToShip.Purpose
	|				AND ShippingItems.Series = TableNumberOfSetsToShip.Series
	|				AND ShippingItems.Action = TableNumberOfSetsToShip.Action
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShippingItems.Products,
	|		ShippingItems.Characteristic,
	|		ShippingItems.Purpose,
	|		ShippingItems.Series,
	|		ShippingItems.Package,
	|		ShippingItems.Package.NumberOfPackages,
	|		ShippingItems.Action,
	|		ISNULL(TableNumberOfSetsToSelect.NumberOfSets, 0) * ShippingItems.Package.NumberOfPackages
	|	FROM
	|		ShippingItems AS ShippingItems
	|			LEFT JOIN TableNumberOfSetsToSelect AS TableNumberOfSetsToSelect
	|			ON ShippingItems.Products = TableNumberOfSetsToSelect.Products
	|				AND ShippingItems.Characteristic = TableNumberOfSetsToSelect.Characteristic
	|				AND ShippingItems.Purpose = TableNumberOfSetsToSelect.Purpose
	|				AND ShippingItems.Series = TableNumberOfSetsToSelect.Series
	|				AND ShippingItems.Action = TableNumberOfSetsToSelect.Action) AS InternalTable
	|
	|GROUP BY
	|	InternalTable.Products,
	|	InternalTable.Characteristic,
	|	InternalTable.Purpose,
	|	InternalTable.Series,
	|	InternalTable.Package,
	|	InternalTable.NumberOfPackagesInSet,
	|	InternalTable.Action";
	
	ConditionOnPackingLists = "NOT ShippedGoods.ThisIsAPackingList";
	ThisIsMovingOrder = TypeOf(Object.Ref) = Type("DocumentRef.GoodsTransferNote");
	If ThisIsMovingOrder Then
		ConditionOnPackingLists = "TRUE";
	EndIf;
	QueryText = StrReplace(QueryText, "&ConditionOnPackingLists", ConditionOnPackingLists);
	
	Query.Text = QueryText;
	
	TableOfGoods = Object.ShippedGoods.Unload();
	
	Query.SetParameter("ShippedGoods", TableOfGoods);
	TableNumberOfPackages = Query.Execute().Unload();
	
	TableOfGoodsSelect = TableOfGoods.CopyColumns();
	TableOfGoodsDoNotShip = TableOfGoods.CopyColumns();
		
	LinesToDelete = New Array;
	For Each String In TableOfGoods Do
		
		If String.Action = Enums.ActionsWithGoodsIssueNoteRows.DoNotShip
			Or Common.ObjectAttributeValue(String.Package, "PackageType") <> Enums.TypesOfItemsPackages.CargoItem Then
			Continue;
		EndIf;
		
		TheStructureOfTheSearch = New Structure("Products, Characteristic, Purpose, Series, Package, Action");
		FillPropertyValues(TheStructureOfTheSearch, String);
		
		FoundRows = TableNumberOfPackages.FindRows(TheStructureOfTheSearch);//Array
		
		If FoundRows.Count() > 0 Then
			
			FoundRow = FoundRows[0];//ValueTableRow
			
			NumberOfPackagesToDistribute = Min(FoundRow.NumberOfPackages, String.NumberOfPackages);
			If NumberOfPackagesToDistribute = 0 Then
				LinesToDelete.Add(String);
			EndIf;
			FoundRow.NumberOfPackages = FoundRow.NumberOfPackages - NumberOfPackagesToDistribute;
			
			NewAction = Undefined;
			
			If String.NumberOfPackages > NumberOfPackagesToDistribute Then // The remaining amount is lowered in action
				
				If String.Action = Enums.ActionsWithGoodsIssueNoteRows.Ship Then
					NewAction = Enums.ActionsWithGoodsIssueNoteRows.Pick;
					ReserveTable = TableOfGoodsSelect;
				Else
					NewAction = Enums.ActionsWithGoodsIssueNoteRows.DoNotShip;
					ReserveTable = TableOfGoodsDoNotShip;
				EndIf;
								
				NewRow = ReserveTable.Add(); // DocumentTabularSectionRow.DiscrepancyReportFollowingReceipt.Goods - specified for typing
				FillPropertyValues(NewRow, String);
				NewRow.NumberOfPackages = String.NumberOfPackages - NumberOfPackagesToDistribute;
				NewRow.Count = NewRow.NumberOfPackages / FoundRow.NumberOfPackagesInSet;
				NewRow.Action = NewAction;
				String.NumberOfPackages = NumberOfPackagesToDistribute;
				String.Count = NumberOfPackagesToDistribute / FoundRow.NumberOfPackagesInSet;
				
				TheStructureOfTheSearch.Insert("Action", NewAction);
				FoundRowsNewAction = TableNumberOfPackages.FindRows(TheStructureOfTheSearch);
				If FoundRowsNewAction.Count() = 0 Then 
					FoundRow.Action = NewAction;
				EndIf;
				
			EndIf;
			
			If FoundRow.NumberOfPackages = 0 And FoundRow.Action <> NewAction Then 
				TableNumberOfPackages.Delete(FoundRow);
			EndIf;
			
		EndIf;	
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		TableOfGoods.Delete(RowToDelete);
	EndDo;
	
	LinesToDelete.Clear();
	For Each String In TableOfGoodsSelect Do
		
		TheStructureOfTheSearch = New Structure("Products, Characteristic, Purpose, Series, Package, Action");
		FillPropertyValues(TheStructureOfTheSearch, String);
		
		FoundRows = TableNumberOfPackages.FindRows(TheStructureOfTheSearch);
		
		If FoundRows.Count() > 0 Then
			
			NumberOfPackagesToDistribute = Min(FoundRows[0].NumberOfPackages, String.NumberOfPackages);
			If NumberOfPackagesToDistribute <> 0 Then
				NewObjectLine = TableOfGoods.Add();
				FillPropertyValues(NewObjectLine, String);
				NewObjectLine.NumberOfPackages = NumberOfPackagesToDistribute;
				NewObjectLine.Count = NumberOfPackagesToDistribute / FoundRows[0].NumberOfPackagesInSet;
			EndIf;
			
			FoundRows[0].NumberOfPackages = FoundRows[0].NumberOfPackages - NumberOfPackagesToDistribute;
			
			If String.NumberOfPackages > NumberOfPackagesToDistribute Then // The remaining amount is lowered in action
				
				NewRow = TableOfGoodsDoNotShip.Add(); // DocumentTabularSectionRow.DiscrepancyReportFollowingReceipt.Goods - specified for typing
				FillPropertyValues(NewRow, String);
				NewRow.NumberOfPackages = String.NumberOfPackages - NumberOfPackagesToDistribute;
				NewRow.Count = NewRow.NumberOfPackages / FoundRows[0].NumberOfPackagesInSet;
				NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.DoNotShip;					
				
			EndIf;
			
			If FoundRows[0].NumberOfPackages = 0 Then 
				TableNumberOfPackages.Delete(FoundRows[0]);
			EndIf;
			
		EndIf;	
		
	EndDo;
	
	For Each StringOfUnloaded In TableOfGoodsDoNotShip Do
		NewRow = TableOfGoods.Add();
		FillPropertyValues(NewRow, StringOfUnloaded);
		If Not ThisIsMovingOrder Then
			NewRow.PackingListParent = Documents.PackingList.EmptyRef();
		EndIf;
	EndDo;
	
	If Not ThisIsMovingOrder Then
		GroupingColumns = "Products, Characteristic, Purpose, Series, BatchesIndicationStatus, ThisIsAPackingList, PackingListParent, PackingList, Package, Action";	
	ElsIf ThisIsMovingOrder Then 
		GroupingColumns = "Products, Characteristic, Purpose, Series, BatchesIndicationStatus, Package, Action";
	EndIf;
	
	TableOfGoods.GroupBy(GroupingColumns, "Count, NumberOfPackages");
	
	Object.ShippedGoods.Load(TableOfGoods);
			
EndProcedure

#EndRegion

#Region FillingInTabularPartsOfDocument

// Returns parameters for checking the filling of the quantity.
//
// Returns:
//	Structure - verification parameters:
//		*TSName - String - the name of the table part. The default value is "Products".
//		*FieldNamesWithSuffix - Structure - a collection containing the names of the Quantity and Quantity of packages fields with a suffix.
//											The collection key is the name of the props without a suffix, for example, "Quantity",
//											and the value is set to the name of the props with a suffix, for example, "Quantity".
//											If the table part does not contain fields with a suffix, then you do not need
//											to initialize the collection.
//		*CheckPossibilityOfRounding - Boolean - a sign that it is necessary to check the possibility of rounding.
//		*ConditionForSelectingRowsForRounding - String - condition for selecting rows to check for rounding. As the name
//													of the table, you need to use the name passed to the Name parameter.
//		*CheckCompletenessOfProductLocations - Boolean - a sign of the need to check the completeness of the items.
//		*ConditionForSelectingCompletenessCheckLines - String - conditions for the request. For example, "Not tabletables.This is a packing list."
//		*FieldsForCheckingCompleteness - String - fields by which goods are grouped to form whole
//															goods from product locations. The fields "Nomenclature",
//															"Characteristic" and "Series" will be added by default.
//															Field "<Prefix>Assignment" should be added if
//															the column name is different from the string "Assignment". For example,
//															"New assignment".
//		*ConditionForSelectingRowsByAdditionalFields - String - a complex string selection condition, for example,
//															<table>.<field>.<field>
//															or <table>.<field> In (SELECT ....), where
//															you need to use the name
//															passed to the Name parameter as the table name.
//		* ThisIsCheckOfCurrentLine - Boolean - Enables the mode of checking the row output from the table in separate input fields
//		*AdditionalFields - Structure - fields involved in a complex row selection condition (use the name passed to the name parameter as the table name):
//			** Key - String - field name.
//			** Value - String - representation of the field in the request.
//		*QueryOptions - Structure - request parameters.
//										The collection key is the name of the request parameter,
//										and the value is set to the set value of the request parameter.
//		*TableToCheck - ValueTable, Undefined - if a table of values is passed, it is checked,
//																otherwise it is an Object or PM with the name passed to the parameter name.
//
Function ParametersForCheckingFillingQuantity() Export
	
	CheckParameters = New Structure;
	CheckParameters.Insert("TSName",										"Goods");
	CheckParameters.Insert("PresentationOfTS",							"");
	CheckParameters.Insert("DataPath",								"Object");
	CheckParameters.Insert("FieldNamesWithSuffix",						New Structure);
	CheckParameters.Insert("FieldNameQuantitySuffix",					"");
	CheckParameters.Insert("CheckPossibilityOfRounding",			True);
	CheckParameters.Insert("ConditionForSelectingRowsForRounding",			"");
	CheckParameters.Insert("CheckCompletenessOfProductLocations",		False);
	CheckParameters.Insert("ConditionForSelectingCompletenessCheckLines",	"");
	CheckParameters.Insert("FieldsForCheckingCompleteness",		"");
	CheckParameters.Insert("ConditionForSelectingRowsByAdditionalFields",	"");
	CheckParameters.Insert("AdditionalFields",						New Structure);
	CheckParameters.Insert("TableToCheck",						Undefined);
	CheckParameters.Insert("QueryOptions",							New Structure);
	CheckParameters.Insert("ThisIsCheckOfCurrentLine",					False);
	
	Return CheckParameters;
	
EndFunction

// Checks the filling in of the details of the number and quantity of packages in the documents.
//
// Parameters:
//	Object - DocumentObject - The document being checked.
//	CheckedAttributes - Array of String - Verified banking details.
//	Cancel - Boolean - a sign of refusal to continue the operation with the document.
//	CheckParameters - See ParametersForCheckingFillingQuantity.
//
Procedure CheckQuantityFilling(Object, CheckedAttributes, Cancel, CheckParameters = Undefined) Export
	
	Var YouMustFillInDetails;
	Var YouMustFillInAdditionalDetails;
	
	If CheckParameters = Undefined Then
		CheckParameters = ParametersForCheckingFillingQuantity();
	EndIf;
	
	TSName = CheckParameters.TSName;
	FieldNamesWithSuffix = CheckParameters.FieldNamesWithSuffix;
	
	If CheckParameters.ThisIsCheckOfCurrentLine Then
		// When an error is displayed, an object cannot be specified in the "element".
		DataKey  = Undefined;
		DataPath = Undefined;
	Else
		DataKey  = TMCommonUse.DataKeyForMessageToUser(Object);
		DataPath = CheckParameters.DataPath;
	EndIf;
	
	If TSName = "Object" Then
		
		CheckedAttributes.Delete(CheckedAttributes.Find("Count"));
		CheckedAttributes.Delete(CheckedAttributes.Find("NumberOfPackages"));
		
		If Object.Count = 0 And Object.NumberOfPackages <> 0 Then
			
			Common.MessageToUser(NStr("vi = 'Tìm thấy số lượng bằng 0 khi tính lại theo đơn vị lưu kho';
										|ru = 'Обнаружено нулевое количество при пересчете в единицу хранения';
										|en = 'Zero quantity is detected when converted to storage unit'; fa = 'Zero quantity is detected when converted to storage unit';
										|it = 'Durante il calcolo in unità di memoria si è rilevato un importo zero';
										|pl = 'Ujawniona jest zerowa ilość podczas przeliczenia do jednostki przechowywania';
										|tr = 'Stok ölçü birimine dönüştürülürken sıfır miktar bulundu'"),
													Object,
													"NumberOfPackages",
													,
													Cancel);
			
		ElsIf Object.Count = 0 Or Object.NumberOfPackages = 0 Then
			
			MessageText = NStr("vi = 'Chưa điền trường ""%PresentationOfQuantityField%""';
								|ru = 'Не заполнено поле ""%PresentationOfQuantityField%""';
								|en = '""%PresentationOfQuantityField%"" is required'; fa = '""%PresentationOfQuantityField%"" is required';
								|it = 'Campo  ""%PresentationOfQuantityField%"" non compilato';
								|pl = 'Nie jest wypełnione pole ""%PresentationOfQuantityField%""';
								|tr = '""%PresentationOfQuantityField%"" alanı doldurulmadı'");
			MessageText = StrReplace(MessageText,
										"%PresentationOfQuantityField%",
										Object.Metadata().Attributes.Count.Synonym);
			
			Common.MessageToUser(MessageText,
													Object,
													"NumberOfPackages",
													,
													Cancel);
			
		EndIf;
		
	Else
		
		ObjectMetadata = Object.Metadata();
		
		VerificationAttribute =  CheckedAttributes.Find(TSName + ".NumberOfPackages");
		YouMustFillInDetails = VerificationAttribute <> Undefined;
		
		If VerificationAttribute <> Undefined Then
			CheckedAttributes.Delete(VerificationAttribute);
			CheckedAttributes.Delete(CheckedAttributes.Find(TSName + ".Count"));
		EndIf;
		
		PresentationOfTS = ?(CheckParameters.PresentationOfTS = "",
							ObjectMetadata.TabularSections[TSName].Synonym,
							CheckParameters.PresentationOfTS);
		
		PresentationOfPropsNumberOfPackages = ObjectMetadata.TabularSections[TSName].Attributes.NumberOfPackages.Synonym;
		
		If FieldNamesWithSuffix.Property("Count") Then
			VerificationAttribute = CheckedAttributes.Find(TSName + "." + FieldNamesWithSuffix.NumberOfPackages);
			YouMustFillInAdditionalDetails = VerificationAttribute <> Undefined;
			
			If VerificationAttribute <> Undefined Then
				CheckedAttributes.Delete(VerificationAttribute);
				CheckedAttributes.Delete(CheckedAttributes.Find(TSName + "." + FieldNamesWithSuffix.Count));
			EndIf;
			
			PresentationOfPropsNumberOfPackagesAdditional  = ObjectMetadata.TabularSections[TSName].Attributes[FieldNamesWithSuffix.NumberOfPackages].Synonym;
		Else
			YouMustFillInAdditionalDetails = False;
			PresentationOfPropsNumberOfPackagesAdditional = "";
		EndIf;
		
		If CheckParameters.ThisIsCheckOfCurrentLine Then 
			
			TemplateQuantityError = NStr("ru = 'Не заполнено поле ""%ColumnPresentation%""';
										|vi = 'The ""%ColumnPresentation%"" field is not filled in';
										|en = 'The ""%ColumnPresentation%"" field is not filled in'; fa = 'The ""%ColumnPresentation%"" field is not filled in';
										|it = 'The ""%ColumnPresentation%"" field is not filled in';
										|pl = 'The ""%ColumnPresentation%"" field is not filled in';
										|tr = '""%ColumnPresentation%"" alanı doldurulmadı'");
			TemplateRecalculationError = NStr("vi = 'Tìm thấy số lượng bằng 0 khi tính lại theo đơn vị lưu kho';
												|ru = 'Обнаружено нулевое количество при пересчете в единицу хранения';
												|en = 'Zero quantity is detected when converted to storage unit'; fa = 'Zero quantity is detected when converted to storage unit';
												|it = 'Durante il calcolo in unità di memoria si è rilevato un importo zero';
												|pl = 'Ujawniona jest zerowa ilość podczas przeliczenia do jednostki przechowywania';
												|tr = 'Stok ölçü birimine dönüştürülürken sıfır miktar bulundu'");	
			
		Else
			TemplateQuantityError = NStr("vi = 'Chưa điền cột ""%ColumnPresentation%"" tại dòng %LineNumber% của danh sách ""%PresentationOfTS%""';
										|ru = 'Не заполнена колонка ""%ColumnPresentation%"" в строке %LineNumber% списка ""%PresentationOfTS%""';
										|en = 'Column ""%ColumnPresentation%"" in line %LineNumber% of the ""%PresentationOfTS%"" list is not filled in'; fa = 'Column ""%ColumnPresentation%"" in line %LineNumber% of the ""%PresentationOfTS%"" list is not filled in';
										|it = 'Non è compilata la colonna ""%ColumnPresentation%"" nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
										|pl = 'Nie wypełniono kolumny ""%ColumnPresentation%"" w wierszu %LineNumber% listy ""%PresentationOfTS%""';
										|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında ""%ColumnPresentation%"" sütunu doldurulmadı'");
			TemplateQuantityError = StrReplace(TemplateQuantityError, "%PresentationOfTS%", PresentationOfTS);
			
			TemplateRecalculationError = NStr("vi = 'Đã phát hiện số lượng bằng 0 khi tính lại theo đơn vị lưu kho tại dòng %LineNumber% trong danh sách ""%PresentationOfTS%""';
												|ru = 'Обнаружено нулевое количество при пересчете в единицу хранения в строке %LineNumber% списка ""%PresentationOfTS%""';
												|en = 'Zero quantity is detected when converted to storage unit in line %LineNumber% of list ""%PresentationOfTS%""'; fa = 'Zero quantity is detected when converted to storage unit in line %LineNumber% of list ""%PresentationOfTS%""';
												|it = 'È stata rilevata la quantità pari a zero nel corso di ricalcolo in unità di stoccaggio nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
												|pl = 'Ujawniona jest zerowa ilość podczas przeliczenia do jednostki przechowywania w wierszu %LineNumber% listy ""%PresentationOfTS%""';
												|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında stok ölçü birimine dönüştürülürken sıfır miktar bulundu'");
			TemplateRecalculationError = StrReplace(TemplateRecalculationError, "%PresentationOfTS%", PresentationOfTS);
			
		EndIf;
			
		For Each TabRow In Object[TSName] Do
			
			If TabRow.Count = 0
				And TabRow.NumberOfPackages <> 0 Then
				
				MessageText = StrReplace(TemplateRecalculationError, "%LineNumber%", String(TabRow.LineNumber));
				Field = PathToTableField(CheckParameters, TabRow.LineNumber, "NumberOfPackages");
				
				Common.MessageToUser(MessageText,
														DataKey,
														Field,
														DataPath,
														Cancel);
				
			ElsIf YouMustFillInDetails
				And (TabRow.Count = 0
					Or TabRow.NumberOfPackages = 0) Then
				
				MessageText = StrReplace(TemplateQuantityError, "%LineNumber%", String(TabRow.LineNumber));
				MessageText = StrReplace(MessageText, "%ColumnPresentation%", PresentationOfPropsNumberOfPackages);
				
				Field = PathToTableField(CheckParameters, TabRow.LineNumber, "NumberOfPackages");
				
				Common.MessageToUser(MessageText,
														DataKey,
														Field,
														DataPath,
														Cancel);
				
			EndIf;
			
			If Not FieldNamesWithSuffix.Property("Count") Then
				Continue;
			EndIf;
			
			If TabRow[FieldNamesWithSuffix.Count] = 0
				And TabRow[FieldNamesWithSuffix.NumberOfPackages] <> 0 Then
				
				MessageText = StrReplace(TemplateRecalculationError, "%LineNumber%", String(TabRow.LineNumber));
				MessageText = StrReplace(MessageText, "%PresentationOfTS%", PresentationOfTS);
				
				Field = PathToTableField(CheckParameters, TabRow.LineNumber, FieldNamesWithSuffix.NumberOfPackages);
				
				Common.MessageToUser(MessageText,
														DataKey,
														Field,
														DataPath,
														Cancel);
				
			ElsIf YouMustFillInAdditionalDetails
				And (TabRow[FieldNamesWithSuffix.Count] = 0
					Or TabRow[FieldNamesWithSuffix.NumberOfPackages] = 0) Then
				
				MessageText = StrReplace(TemplateQuantityError, "%LineNumber%", String(TabRow.LineNumber));
				MessageText = StrReplace(MessageText, "%PresentationOfTS%", PresentationOfTS);
				MessageText = StrReplace(MessageText, "%ColumnPresentation%", PresentationOfPropsNumberOfPackagesAdditional);
				
				Field = PathToTableField(CheckParameters, TabRow.LineNumber, FieldNamesWithSuffix.NumberOfPackages);
				
				Common.MessageToUser(MessageText,
														DataKey,
														Field,
														DataPath,
														Cancel);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	CheckQuantityRounding(Object, Cancel, CheckParameters);
	
	If CheckParameters.CheckCompletenessOfProductLocations Then 
		CheckCompletenessOfProductLocations(Object[TSName], Cancel, CheckParameters);
	EndIf;
	
EndProcedure

// Checks the correctness of the rounding of the Quantity in the documents.
//
// Parameters:
//	Object				- DocumentObject 			- document Object being checked
//	Cancel				- Boolean 					- failure to continue the operation.
//	CheckParameters	- Structure, Undefined	- See ParametersForCheckingFillingQuantity
//
Procedure CheckQuantityRounding(Object, Cancel, CheckParameters = Undefined) Export
	
	If CheckParameters = Undefined Then
		CheckParameters = ParametersForCheckingFillingQuantity();
	EndIf;
	
	TSName = CheckParameters.TSName;

	If CheckParameters.TableToCheck <> Undefined
		And CheckParameters.TableToCheck.Count() = 0 Then
		Return;
	ElsIf TSName <> "Object"
		And Object[TSName].Count() = 0 Then
		Return;
	EndIf;

	FieldNamesWithSuffix = CheckParameters.FieldNamesWithSuffix;
	
	If CheckParameters.CheckPossibilityOfRounding Then
		AcceptablePercentageOfDeviation = Constants.AllowableDeviationOfAutomaticRounding.Get();
	Else
		AcceptablePercentageOfDeviation = 0;
	EndIf;
	
	If CheckParameters.ThisIsCheckOfCurrentLine Then
		// When an error is displayed, an object cannot be specified in the "element".
		DataKey  = Undefined;
		DataPath = Undefined;
	Else
		DataKey  = TMCommonUse.DataKeyForMessageToUser(Object);
		DataPath = CheckParameters.DataPath;
	EndIf;
	
	Result = CheckRoundingOfInternalQuantity(Object, CheckParameters, AcceptablePercentageOfDeviation); // QueryResult
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	If TSName = "Object"
		Or CheckParameters.ThisIsCheckOfCurrentLine Then
		
		If Not CheckParameters.CheckPossibilityOfRounding Then
			PatternRoundingError = NStr("vi = 'Số lượng theo ""%Package%"" được chuyển đổi thành số lượng theo ""%BasicUnitOfMeasurement%"" với lỗi %DeviationInStorageUnits%%Package%, không chấp nhận được, cho thấy có lỗi trong chương trình. Hãy liên hệ với quản trị hệ thống.';
										|ru = 'Количество в ""%Package%"" переведено в количество в ""%BasicUnitOfMeasurement%"" с погрешностью - %DeviationInStorageUnits% %Package%, что недопустимо, что свидетельствует об ошибке в работе программы. Обратитесь к администратору.';
										|en = 'Quantity in ""%Package%"" is transferred to quantity in ""%BasicUnitOfMeasurement%"" with error – %DeviationInStorageUnits% %Package%, which is invalid and shows that there is an application error. Please contact the administrator.'; fa = 'Quantity in ""%Package%"" is transferred to quantity in ""%BasicUnitOfMeasurement%"" with error – %DeviationInStorageUnits% %Package%, which is invalid and shows that there is an application error. Please contact the administrator.';
										|it = 'La quantità in""%Package%"" traferità nella quantità in ""%BasicUnitOfMeasurement%""con errore - %DeviationInStorageUnits% %Package%, non è disponibile, il che indica un errore nel programma. Contattare l''amministratore';
										|pl = 'Ilość w ""%Package%"" została przekazana do ilości w ""%BasicUnitOfMeasurement%"" z błędem - %DeviationInStorageUnits% %Package%, co jest niedopuszczalne i świadczy o błędzie w pracy programu. Zwróć się do administratora.';
										|tr = '""%Package%"" içindeki miktar, ""%BasicUnitOfMeasurement%"" içindeki miktara hatayla dönüştürülür - %DeviationInStorageUnits% %Pack% %Package%, ​​​​geçersizdir ve programda hata olduğunu gösterir. Yöneticiyle iletişime geç.'");
		ElsIf AcceptablePercentageOfDeviation > 0 Then
			PatternRoundingError = NStr("vi = 'Sau khi làm tròn, số lượng hàng hóa sẽ bằng %RoundedQuantity% %BasicUnitOfMeasurement%, trong khi lỗi làm tròn là %DeviationInStorageUnits% %Package%, vượt quá lỗi tối đa - %QuantityMaximumError% %Package%.';
										|ru = 'После округления количество товара будет равно %RoundedQuantity% %BasicUnitOfMeasurement%, при этом погрешность округления составит %DeviationInStorageUnits% %Package%, что превышает максимальную погрешность - %QuantityMaximumError% %Package%.';
										|en = 'After rounding the quantity of goods will be %RoundedQuantity% %BasicUnitOfMeasurement%; but the rounding error will be %DeviationInStorageUnits% %Package%, it exceeds the maximum rounding error - %QuantityMaximumError% %Package%.'; fa = 'After rounding the quantity of goods will be %RoundedQuantity% %BasicUnitOfMeasurement%; but the rounding error will be %DeviationInStorageUnits% %Package%, it exceeds the maximum rounding error - %QuantityMaximumError% %Package%.';
										|it = 'Dopo l''arrotondamento, la quantità di merci sarà pari %RoundedQuantity% %BasicUnitOfMeasurement%,  dunque l''errore di arrotondamento sta %DeviationInStorageUnits% %Package%, che supera l''errore massimo %QuantityMaximumError% %Package%.';
										|pl = 'Po zaokrągleniu ilość towaru będzie równa %RoundedQuantity% %BasicUnitOfMeasurement%, przy tym błąd zaokrąglenia wyniesie %DeviationInStorageUnits% %Package%, co przekracza błąd maksymalny - %QuantityMaximumError% %Package%.';
										|tr = 'Yuvarlamadan sonra, ürünün miktarı %RoundedQuantity% %BasicUnitOfMeasurement% olurken, yuvarlama hatası %DeviationInStorageUnits% %Package% olur ve maksimum hatayı %QuantityMaximumError% %Package%''i aşar.'");
		Else
			PatternRoundingError = NStr("vi = 'Số lượng theo ""%Package%"" không phải là bội số của ""%BasicUnitOfMeasurement%"". Độ lệch - %DeviationInStorageUnits%%Package%.';
										|ru = 'Количество в ""%Package%"" некратно количеству в ""%BasicUnitOfMeasurement%"". Отклонение - %DeviationInStorageUnits% %Package%.';
										|en = 'Quantity in ""%Package%"" is not a multiple of quantity in ""%BasicUnitOfMeasurement%"". Variance - %DeviationInStorageUnits% %Package%.'; fa = 'Quantity in ""%Package%"" is not a multiple of quantity in ""%BasicUnitOfMeasurement%"". Variance - %DeviationInStorageUnits% %Package%.';
										|it = 'L''importo in ""%Package%"" è più volte l''importo in ""%BasicUnitOfMeasurement%"". Variazione- %DeviationInStorageUnits% %Package%.';
										|pl = 'Ilość w ""%Package%"" nie jest krotna ilości w ""%BasicUnitOfMeasurement%"". Odchylenie - %DeviationInStorageUnits% %Package%.';
										|tr = '""%Package%"" içindeki miktar, ""%BasicUnitOfMeasurement%"" içindeki miktarın katı değil. Sapma - %DeviationInStorageUnits% %Package%.'");
		EndIf;
		
	Else
		
		PresentationOfTS	= ?(CheckParameters.PresentationOfTS = "",
							Object.Metadata().TabularSections[TSName].Synonym,
							CheckParameters.PresentationOfTS);
		
		If Not CheckParameters.CheckPossibilityOfRounding Then
			PatternRoundingError = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""%PresentationOfTS%"", số lượng theo ""%Package%"" được chuyển đổi thành số lượng theo ""%BasicUnitOfMeasurement%"" với độ lệch -%DeviationInStorageUnits%%Package%, cho biết có lỗi trong chương trình. Hãy liên hệ với quản trị hệ thống.';
										|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" количество в ""%Package%"" переведено в количество в ""%BasicUnitOfMeasurement%"" с отклонением - %DeviationInStorageUnits% %Package%, что свидетельствует об ошибке в работе программы. Обратитесь к администратору.';
										|en = 'Quantity in ""%Package%"" is transferred to quantity in ""%BasicUnitOfMeasurement%"" in line %LineNumber% of list ""%PresentationOfTS%"" with variance – %DeviationInStorageUnits% %Package%, that shows the application error. Please contact the administrator.'; fa = 'Quantity in ""%Package%"" is transferred to quantity in ""%BasicUnitOfMeasurement%"" in line %LineNumber% of list ""%PresentationOfTS%"" with variance – %DeviationInStorageUnits% %Package%, that shows the application error. Please contact the administrator.';
										|it = 'Nella riga %LineNumber% dell''elenco ""%PresentationOfTS%"" la quantità in ""%Package%"" è trasferità nella quantità in  ""%BasicUnitOfMeasurement%"" con variazione - %DeviationInStorageUnits% %Package%, indica un errore nel programma. Contattare l''amministratore.';
										|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" ilość w ""%Package%"" przekazano do ilości w ""%BasicUnitOfMeasurement%"" z odchyleniem - %DeviationInStorageUnits% %Package%, co świadczy o błędzie w pracy programu. Zwróć się do administratora.';
										|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında, ""%Package%"" içindeki miktar bir sapma ile ""%BasicUnitOfMeasurement%"" içindeki miktara dönüştürülür - %DeviationInStorageUnits% %Package%, ​​​​bu, programda hata olduğunu gösterir. Yöneticiyle iletişime geç.'");
		ElsIf AcceptablePercentageOfDeviation > 0 Then
			PatternRoundingError = NStr("vi = 'Sau khi làm tròn, số lượng hàng hóa sẽ bằng %RoundedQuantity% %BasicUnitOfMeasurement% trong dòng %LineNumber% của danh sách ""%PresentationOfTS%"", trong khi lỗi làm tròn là %DeviationInStorageUnits% %Package%, vượt quá lỗi tối đa - %QuantityMaximumError% %Package%.';
										|ru = 'После округления количество товара будет равно %RoundedQuantity% %BasicUnitOfMeasurement% в строке %LineNumber% списка ""%PresentationOfTS%"", при этом погрешность округления составит %DeviationInStorageUnits% %Package%, что превышает максимальную погрешность - %QuantityMaximumError% %Package%.';
										|en = 'After rounding, quantity of goods will be %RoundedQuantity% %BasicUnitOfMeasurement% in line %LineNumber% of the ""%PresentationOfTS%"" list; but the rounding error will be %DeviationInStorageUnits% %Package%, it exceeds the maximum rounding error - %QuantityMaximumError% %Package%.'; fa = 'After rounding, quantity of goods will be %RoundedQuantity% %BasicUnitOfMeasurement% in line %LineNumber% of the ""%PresentationOfTS%"" list; but the rounding error will be %DeviationInStorageUnits% %Package%, it exceeds the maximum rounding error - %QuantityMaximumError% %Package%.';
										|it = 'Dopo l''arrotondamento la quantità di merce sarà parti%RoundedQuantity% %BasicUnitOfMeasurement% nella riga %LineNumber% dell''elenco ""%PresentationOfTS%"" dunque l''errore di arrotondamento sta %DeviationInStorageUnits% %Package%, che supera l''errore massimo %QuantityMaximumError% %Package%.';
										|pl = 'Po zaokrągleniu ilość towaru będzie równa %RoundedQuantity% %BasicUnitOfMeasurement% w wierszu %LineNumber% listy ""%PresentationOfTS%"", przy tym błąd zaokrąglenia wyniesie %DeviationInStorageUnits% %Package%, co przekracza błąd maksymalny - %QuantityMaximumError% %Package%.';
										|tr = 'Yuvarlama işleminden sonra ""%PresentationOfTS%"" listesinin %LineNumber% satırında ürün miktarı %RoundedQuantity% %BasicUnitOfMeasurement%''e eşit olurken, yuvarlama hatası %DeviationInStorageUnits% %Package% olacak ve bu maksimum hatayı aşıyor - %QuantityMaximumError% %Package%.'");
		Else 
			PatternRoundingError = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""%PresentationOfTS%"", số lượng trong ""%Package%"" không phải là bội số của số lượng trong ""%BasicUnitOfMeasurement%"". Độ lệch - %DeviationInStorageUnits% %Package%.';
										|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" количество в ""%Package%"" некратно количеству в ""%BasicUnitOfMeasurement%"". Отклонение - %DeviationInStorageUnits% %Package%.';
										|en = 'Quantity in ""%Package%"" is not a multiple of quantity  in ""%BasicUnitOfMeasurement%"" in line %LineNumber% of list ""%PresentationOfTS%"". Variance - %DeviationInStorageUnits% %Package%.'; fa = 'Quantity in ""%Package%"" is not a multiple of quantity  in ""%BasicUnitOfMeasurement%"" in line %LineNumber% of list ""%PresentationOfTS%"". Variance - %DeviationInStorageUnits% %Package%.';
										|it = 'Nella riga %LineNumber% dell''elenco""%PresentationOfTS%"" la quantità in ""%Package%è più volte la quantità in ""%BasicUnitOfMeasurement%"". Variazione- %DeviationInStorageUnits% %Package%.';
										|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" ilość w ""%Package%"" nie jest krotna ilości w ""%BasicUnitOfMeasurement%"". Odchylenie - %DeviationInStorageUnits% %Package%.';
										|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında, ""%Package%"" içindeki miktar ""%BasicUnitOfMeasurement%"" içindeki miktarın katı değil. Sapma - %DeviationInStorageUnits% %Package%.'");
		EndIf;
		
		PatternRoundingError = StrReplace(PatternRoundingError, "%PresentationOfTS%", PresentationOfTS);
		
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		If Selection.DeviationInStorageUnits > Selection.QuantityMaximumError Then
			
			MessageText = PatternRoundingError;
			MessageText = StrReplace(MessageText, "%BasicUnitOfMeasurement%", Selection.BasicUnitOfMeasurement);
			MessageText = StrReplace(MessageText, "%DeviationInStorageUnits%", Selection.DeviationInStorageUnits);
			MessageText = StrReplace(MessageText, "%Package%", Selection.Package);
			MessageText = StrReplace(MessageText, "%QuantityMaximumError%", Selection.QuantityMaximumError);
			MessageText = StrReplace(MessageText, "%RoundedQuantity%", Selection.RoundedQuantity);
			
			If TSName = "Object" Then
				Common.MessageToUser(MessageText,
														DataKey,
														"NumberOfPackages",
														DataPath,
														Cancel);
			Else
				MessageText = StrReplace(MessageText, "%LineNumber%", String(Selection.LineNumber));
				
				Field = PathToTableField(CheckParameters, Selection.LineNumber, "NumberOfPackages");
				
				Common.MessageToUser(MessageText,
														DataKey,
														Field,
														DataPath,
														Cancel);
			EndIf;
			
		EndIf;
		
		If Selection.NumberOfSuffixDeviation > Selection.NumberOfSuffixMaximumError Then
			
			MessageText = PatternRoundingError;
			MessageText = StrReplace(MessageText, "%BasicUnitOfMeasurement%", Selection.BasicUnitOfMeasurement);
			MessageText = StrReplace(MessageText, "%DeviationInStorageUnits%", Selection.NumberOfSuffixDeviation);
			MessageText = StrReplace(MessageText, "%Package%", Selection.Package);
			MessageText = StrReplace(MessageText, "%QuantityMaximumError%", Selection.NumberOfSuffixMaximumError);
			MessageText = StrReplace(MessageText, "%RoundedQuantity%", Selection.SuffixNumberRounded);
			
			If TSName = "Object" Then
				Common.MessageToUser(MessageText,
														DataKey,
														FieldNamesWithSuffix.NumberOfPackages,
														DataPath,
														Cancel);
			Else
				MessageText = StrReplace(MessageText, "%LineNumber%", String(Selection.LineNumber));
				
				Field = PathToTableField(CheckParameters, Selection.LineNumber, FieldNamesWithSuffix.NumberOfPackages);
				
				Common.MessageToUser(MessageText,
														DataKey,
														Field,
														DataPath,
														Cancel);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks the correctness of the rounding of the Quantity in the documents.
// 
// Parameters:
//  Object - DocumentObject - document Object being checked
//  CheckParameters - Structure, Undefined - See ParametersForCheckingFillingQuantity
// 
// Returns:
//  ValueTable - table with column:
//   * LineNumber - Number - the line number of the tabular part in which the number is rounded incorrectly.
Function LineNumbersWithIncorrectRoundingOfQuantity(Object, CheckParameters = Undefined) Export
	
	If CheckParameters = Undefined Then
		CheckParameters = ParametersForCheckingFillingQuantity();
	EndIf;
	
	If CheckParameters.CheckPossibilityOfRounding Then
		AcceptablePercentageOfDeviation = Constants.AllowableDeviationOfAutomaticRounding.Get();
	Else
		AcceptablePercentageOfDeviation = 0;
	EndIf;
	
	Result = CheckRoundingOfInternalQuantity(Object, CheckParameters, AcceptablePercentageOfDeviation); // QueryResult
	If Result.IsEmpty() Then
		Table = New ValueTable();
		Table.Columns.Add(
			"LineNumber",
			New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
		Return Table;
	EndIf;
	Table = Result.Unload();
	Table.Columns.Add("RoundingWasPerformedCorrectly", New TypeDescription("Boolean"));
	For Each String In Table Do
		
		String.RoundingWasPerformedCorrectly = True;
		If String.DeviationInStorageUnits > String.QuantityMaximumError Then
			
			String.RoundingWasPerformedCorrectly = False;
			
		EndIf;
		
		If String.NumberOfSuffixDeviation > String.NumberOfSuffixMaximumError Then
			
			String.RoundingWasPerformedCorrectly = False;
			
		EndIf;
		
	EndDo;
	Return Table.Copy(New Structure("RoundingWasPerformedCorrectly", False), "LineNumber");
	
EndFunction

// Returns parameters for rounding.
//
//	Returns:
//		Structure - parameters for rounding:
//			*TSName - String - the name of the table part. The default value is "Products".
//			*FieldNameQuantitySuffix - String - the name of the field is a number with a suffix. If the table part contains two
//													props "Quantity", then the second one has a suffix in the name.
//													If the parameter is filled in, then both props are checked.
//													The default value is "".
//			*ConditionForSelectingRowsForRounding - String - condition for selecting rows to check for rounding.
//														As the name of the table, you need to use the name passed to the
//														Name parameter.
//			*ConditionForSelectingRowsByAdditionalFields - String - a complex string selection condition, for example,
//																<table>.<field>.<field>
//																or <table>.<field> In (SELECT ....), where
//																you need to use the name
//																passed to the Name parameter as the table name.
//			*AdditionalFields - Structure - fields involved in a complex row selection condition (use the name passed to the name parameter as the table name):
//				** Key - String - field name.
//				** Value - String - representation of the field in the request.
//			*QueryOptions - Structure - request parameters.
//											The collection key is the name of the request parameter,
//											and the value is set to the set value of the request parameter.
//
Function ParametersForRoundingNumberOfUnitProducts() Export
	
	RoundingParameters = New Structure;
	RoundingParameters.Insert("TSName",									"Goods");
	RoundingParameters.Insert("FieldNameQuantitySuffix",				"");
	RoundingParameters.Insert("ConditionForSelectingRowsForRounding",			"");
	RoundingParameters.Insert("ConditionForSelectingRowsByAdditionalFields",	"");
	RoundingParameters.Insert("AdditionalFields",						New Structure);
	RoundingParameters.Insert("QueryOptions",						New Structure);
	
	Return RoundingParameters;
	
EndFunction

// Rounds the quantity of the product to whole units when specifying the quantity in the document in dimensional units.
//
// Parameters:
//	Object - DocumentObject - Document object.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//	RoundingParameters - See ParametersForRoundingNumberOfUnitProducts.
//
Procedure RoundUpNumberOfUnitItems(Object, WriteMode = Undefined, RoundingParameters = Undefined) Export
	
	If WriteMode <> Undefined
		And WriteMode <> DocumentWriteMode.Posting
		And TypeOf(WriteMode) = Type("DocumentWriteMode")
		And Object.Metadata().Posting = Metadata.ObjectProperties.Posting.Allow Then
		
		Return;
		
	EndIf;
	
	If RoundingParameters = Undefined Then
		RoundingParameters = ParametersForRoundingNumberOfUnitProducts();
	EndIf;
	
	TSName = RoundingParameters.TSName;
	FieldNameQuantitySuffix = RoundingParameters.FieldNameQuantitySuffix;
	ConditionForSelectingRowsByAdditionalFields = RoundingParameters.ConditionForSelectingRowsByAdditionalFields;
	ConditionForSelectingRowsForRounding = RoundingParameters.ConditionForSelectingRowsForRounding;
	
	QueryText =
	"SELECT
	|	TS.LineNumber AS LineNumber,
	|	TS.Products AS Products,
	|	TS.Package,
	|	CAST(TS.Count AS NUMBER(15, 0)) AS RoundedQuantity,
	|	CAST(&FieldNameQuantitySuffix AS NUMBER(15, 0)) AS SuffixNumberRounded,
	|	&AdditionalFields
	|INTO TT
	|FROM
	|	&TS AS TS
	|WHERE
	|	TS.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	AND (TS.Count <> (CAST(TS.Count AS NUMBER(15, 0)))
	|			OR &FieldNameQuantitySuffix <> (CAST(&FieldNameQuantitySuffix AS NUMBER(15, 0))))
	|	AND (&ConditionForSelectingRowsForRounding)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TS.LineNumber AS LineNumber,
	|	TS.RoundedQuantity AS RoundedQuantity,
	|	TS.SuffixNumberRounded AS SuffixNumberRounded
	|FROM
	|	TT AS TS
	|		INNER JOIN Catalog.Products AS TProducts
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS TPackingStorageUnits
	|			ON (TPackingStorageUnits.Ref = TProducts.UnitOfMeasure)
	|				AND (TPackingStorageUnits.MeasuredValueType = &PieceType)
	|		ON (TProducts.Ref = TS.Products)
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS TTs
	|		ON (TTs.Ref = TS.Package)
	|			AND (TTs.MeasuredValueType IN (&DimensionalTypes))
	|WHERE
	|	&ConditionForSelectingRowsByAdditionalFields";
	
	If ValueIsFilled(FieldNameQuantitySuffix) Then
		QueryText = StrReplace(QueryText, "&FieldNameQuantitySuffix", "TS." + FieldNameQuantitySuffix);
	Else
		QueryText = StrReplace(QueryText, "&FieldNameQuantitySuffix", "0");
	EndIf;
	
	If ConditionForSelectingRowsForRounding <> "" Then
		QueryText = StrReplace(QueryText,
									"&ConditionForSelectingRowsForRounding",
									StrReplace(ConditionForSelectingRowsForRounding, TSName + ".", "TS."));
	Else
		QueryText = StrReplace(QueryText, "&ConditionForSelectingRowsForRounding", "TRUE");
	EndIf;
	
	If ValueIsFilled(RoundingParameters.AdditionalFields) Then
		Template = "%1 AS %2,
					|%3";
		FieldTexts = Template;
		
		For Each Field In RoundingParameters.AdditionalFields Do
			FieldTexts = StrTemplate(FieldTexts, StrReplace(Field.Value, TSName + ".", "TS."), Field.Key, Template);
		EndDo;
		
		QueryText = StrReplace(QueryText,
									"&AdditionalFields", 
									Mid(FieldTexts, 1, StrFind(FieldTexts, ",", SearchDirection.FromEnd,, 2) - 1));
	Else
		QueryText = StrReplace(QueryText, "&AdditionalFields", "TRUE");
	EndIf;
	
	If ValueIsFilled(ConditionForSelectingRowsByAdditionalFields) Then
		QueryText = StrReplace(QueryText,
									"&ConditionForSelectingRowsByAdditionalFields",
									StrReplace(ConditionForSelectingRowsByAdditionalFields, TSName + ".", "TS."));
	Else
		QueryText = StrReplace(QueryText, "&ConditionForSelectingRowsByAdditionalFields", "TRUE");	
	EndIf;
	
	Query = New Query(QueryText);
		
	If TSName = "Object" Then
		Table = New ValueTable;
		Table.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers(5,0,AllowedSign.Nonnegative)));
		Table.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		Table.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		Table.Columns.Add("Count", TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
		
		TableRow = Table.Add();
		FillPropertyValues(TableRow, Object);
		
		Query.SetParameter("TS", Table);
	Else
		Query.SetParameter("TS", Object[TSName].Unload());
	EndIf;
	
	For Each QueryParameter In RoundingParameters.QueryOptions Do
		Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;
	
	DimensionalTypes = New Array;
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.Weight);
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.VolumeM3);
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement);
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.Length);
	
	Query.SetParameter("DimensionalTypes", DimensionalTypes);
	Query.SetParameter("PieceType", Enums.TypesOfMeasuredValues.NumberOfPieces);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If TSName = "Object" Then
			Object.Count = Selection.RoundedQuantity;
			If ValueIsFilled(FieldNameQuantitySuffix) Then
				Object[FieldNameQuantitySuffix] = Selection.SuffixNumberRounded;
			EndIf;
		Else
			Object[TSName][Selection.LineNumber - 1].Count = Selection.RoundedQuantity;
			If ValueIsFilled(FieldNameQuantitySuffix) Then
				Object[TSName][Selection.LineNumber - 1][FieldNameQuantitySuffix] = Selection.SuffixNumberRounded;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Adds a query to the query package to get the data needed to fill in the country of origin of the item
// when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddQueryTextToCountryOfOriginOfItem(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var Parameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInCountryOfOriginOfProduct",
		StructureOfActions,
		CachedValues,
		Parameters) Then
	
		QueryText = "
			|SELECT ALLOWED
			|	DataSource.IdOfTTRow AS IdOfTTRow,
			|	CASE
			|		WHEN NOT DataSource.TheRecordsAreKeptByCCD THEN
			|			VALUE(Catalog.WorldCountries.EmptyRef)
			|		WHEN &CCDNumberField <> VALUE(Catalog.CCDNumbers.EmptyRef) THEN
			|			CCDNumbers.OriginCountry
			|		ELSE
			|			CatProducts.OriginCountry
			|	END AS OriginCountry
			|FROM
			|	TTDataSource AS DataSource
			|	LEFT JOIN Catalog.CCDNumbers AS CCDNumbers
			|		ON CCDNumbers.Ref = &CCDNumberField
			|	LEFT JOIN Catalog.Products AS CatProducts
			|		ON CatProducts.Ref = &ProductsField";
		
		QueryText = StrReplace(QueryText, "&CCDNumberField", "DataSource." + Parameters.CCDNumber);
		QueryText = StrReplace(QueryText, "&ProductsField", "DataSource." + Parameters.Products);
		QueryDetails.QueriesTexts.Add(QueryText, "CountryOfOriginOfProduct");
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the content of the service by nomenclature 
// and characteristics.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddQueryTextToServiceContent(StructureOfActions, QueryDetails, CachedValues) Export
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInContent",
		StructureOfActions,
		CachedValues) Then
	
		QueryText = "
			|SELECT ALLOWED
			|	DataSource.IdOfTTRow AS IdOfTTRow,
			|	CatProducts.ItemsType AS ItemsType,
			|	CatProducts.SaleRegistrationOption AS SaleRegistrationOption,
			|	CatProducts.DescriptionFull AS ProductFullName,
			|	CatItemsCharacteristics.DescriptionFull AS CharacteristicFullName
			|FROM
			|	TTDataSource AS DataSource
			|	LEFT JOIN Catalog.ItemsCharacteristics AS CatItemsCharacteristics
			|		ON CatItemsCharacteristics.Ref = DataSource.Characteristic
			|	LEFT JOIN Catalog.Products AS CatProducts
			|		ON CatProducts.Ref = DataSource.Products"; 
		
		QueryDetails.QueriesTexts.Add(QueryText, "ServiceContent");
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the FEA code by item.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure SupplementQueryTextWithHSCodeByItem(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var VATTaxation;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInHSCode",
			StructureOfActions,
			CachedValues,
			VATTaxation) 
			And (VATTaxation = Enums.VATTaxationTypes.ExportSale 
			Or VATTaxation = Undefined) Then
	
		QueryText = "
			|SELECT
			|	DataSource.IdOfTTRow AS IdOfTTRow,
			|	ISNULL(CatProducts.FEACNCode, VALUE(Catalog.FEACN.EmptyRef)) AS FEACNCode
			|FROM
			|	TTDataSource AS DataSource
			|	LEFT JOIN Catalog.Products AS CatProducts
			|		ON CatProducts.Ref = DataSource.Products";
		
		QueryDetails.QueriesTexts.Add(QueryText, "HSCodeByItem");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region BatchProcessingOfTableParts

// Adds requests to the request package to get the data needed to check the correctness and fill in the characteristics.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure CompleteQueryTextCheckCorrectnessFillInCharacteristicsAndPackagingUnits(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"CheckCharacteristicsByOwner",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		ListOfRequests = QueryTextsCheckCharacteristicsByOwner();
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	EndIf;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"CheckFillPackageByOwner",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		ListOfRequests = QueryTextsToCheckFillInPackagingUnitsByOwner();
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	EndIf;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInDescriptionOfPoorQualityProduct",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		ListOfRequests = QueryTextsFillInCharacteristicsOfLowQualityItem();
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	EndIf;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInPackagingOfLowQualityGoods",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		ListOfRequests = QueryTextsFillInPackagingUnitsOfLowQualityItem();
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the inventory item count.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure CompleteQueryTextAndFillInAccountingNumberOfItems(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInAccountingQuantityOfProductItem",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		ListOfRequests = QueryTextsFillInAccountingNumberOfItems();
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
		QueryDetails.QueryOptions.Insert("Warehouse", ActionParameters.Warehouse);
		QueryDetails.QueryOptions.Insert("Recorder", ActionParameters.Recorder);
		QueryDetails.QueryOptions.Insert("Organization", ActionParameters.Organization);
		QueryDetails.QueryOptions.Insert("PointInTime", ActionParameters.PointInTime);
		
	EndIf;
	
EndProcedure

// Adds a request to the request package for recalculating the number of item packages.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure AddQueryTextRecalculateNumberOfPackagingUnits(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"RecalculateNumberOfPackages",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		ListOfRequests = QueryTextsRecalculateNumberOfPackagingUnits();
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds a request to the request package for recalculating the number of item packages with the suffix.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure AddToQueryTextRecalculateNumberOfPackagingUnitsSuffix(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"RecalculateNumberOfSuffixPacks",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
			
		RecalculationParameters = BatchProcessingOfTablePartClientServer.NormalizeUnitConversionParametersSuffix(Undefined, ActionParameters);
		QuantityWithSuffix = BatchProcessingOfTablePartClientServer.QuantityWithSuffix(RecalculationParameters.Suffix);
		
		QueryOptions = New Structure;
		QueryOptions.Insert("FieldNameQuantity", QuantityWithSuffix.Count);
		QueryOptions.Insert("FieldNameNumberOfPackages", QuantityWithSuffix.NumberOfPackages);
		QueryOptions.Insert("TableName", "RecalculateNumberOfSuffixPacks");
		
		ListOfRequests = QueryTextsRecalculateNumberOfPackagingUnits(QueryOptions);
		
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds a request to the request package for recalculating the number of packages of an item by weight.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure SupplementQueryTextRecalculateNumberOfPackagingUnitsByWeight(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"RecalculateNumberOfPackagesByWeight",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		RecalculationParameters = BatchProcessingOfTablePartClientServer.NormalizeUnitConversionParametersSuffix(Undefined, ActionParameters);
		QuantityWithSuffix = BatchProcessingOfTablePartClientServer.QuantityWithSuffix(RecalculationParameters.Suffix);
		
		ListOfRequests = QueryTextsRecalculateNumberOfPackagingUnitsByWeightVolume(
			"RecalculateNumberOfPackagesByWeight",
			QuantityWithSuffix.Count,
			QuantityWithSuffix.NumberOfPackages,
			"Weight");
			
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds a request to the request package for recalculating the number of packages of an item by volume.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure SupplementQueryTextRecalculateNumberOfPackagingUnitsByVolume(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"RecalculateNumberOfPackagesByVolume",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		RecalculationParameters = BatchProcessingOfTablePartClientServer.NormalizeUnitConversionParametersSuffix(Undefined, ActionParameters);
		QuantityWithSuffix = BatchProcessingOfTablePartClientServer.QuantityWithSuffix(RecalculationParameters.Suffix);
		
		ListOfRequests = QueryTextsRecalculateNumberOfPackagingUnitsByWeightVolume(
			"RecalculateNumberOfPackagesByVolume",
			QuantityWithSuffix.Count,
			QuantityWithSuffix.NumberOfPackages,
			"VolumeM3");
			
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds requests to the request package for checking and calculating the Status of specifying series.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure CompleteQueryTextCheckBatchCalculateStatus(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"CheckSeriesCalculateStatus",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
			
		SeriesSpecificationParameters = ActionParameters.SeriesSpecificationParameters;
		
		TableOfGoodsPreliminary = CachedValues.QueryDetails.QueryOptions.DataSource;
		
		ObjectMetadata = TMCommonUse.ObjectMetadataByFullName(SeriesSpecificationParameters.FullObjectName);
		
		TypeProducts = New TypeDescription("CatalogRef.Products");
		TypeOfProductCharacteristics = New TypeDescription("CatalogRef.ItemsCharacteristics");
		ProductSeriesType = New TypeDescription("CatalogRef.ItemsBatches");
		TypeQuantity = TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative);
		TypeLineNumber = New TypeDescription("String",, New StringQualifiers(36));
		
		TableOfGoods = New ValueTable;
		TableOfGoods.Columns.Add("Products", TypeProducts);
		TableOfGoods.Columns.Add("Characteristic", TypeOfProductCharacteristics);
		TableOfGoods.Columns.Add("Series", ProductSeriesType);
		
		If SeriesSpecificationParameters.FieldNamesWithSuffix.Count() Then
			
			FieldNamesWithSuffix = SeriesSpecificationParameters.FieldNamesWithSuffix;
			
			If FieldNamesWithSuffix.Property("Products") Then
				
				AddColumnToProductTable(
					TableOfGoods,
					FieldNamesWithSuffix.Products,
					TypeProducts);
				
			EndIf;
			
			If FieldNamesWithSuffix.Property("Characteristic") Then
				
				AddColumnToProductTable(
					TableOfGoods,
					FieldNamesWithSuffix.Characteristic,
					TypeOfProductCharacteristics);
				
			EndIf;
			
			If FieldNamesWithSuffix.Property("Series") Then
				
				AddColumnToProductTable(
					TableOfGoods,
					FieldNamesWithSuffix.Series,
					ProductSeriesType);
				
			EndIf;
			
		EndIf;
		
		TableOfGoods.Columns.Add(SeriesSpecificationParameters.FieldNameQuantity, TypeQuantity);
		TableOfGoods.Columns.Add("LineNumber", TypeLineNumber);
		
		CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, TableOfGoods, ObjectMetadata);
		
		TableOfSeries = New ValueTable;
		TableOfSeries.Columns.Add("Products", TypeProducts);
		TableOfSeries.Columns.Add("Characteristic", TypeOfProductCharacteristics);
		TableOfSeries.Columns.Add(SeriesSpecificationParameters.FieldNameQuantity, TypeQuantity);
		
		CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, TableOfSeries, ObjectMetadata, True);
		
		For Each TSRow In TableOfGoodsPreliminary Do
			FillPropertyValues(TableOfGoods.Add(), TSRow);
		EndDo;
		
		TableOfGoods.LoadColumn(
			TableOfGoodsPreliminary.UnloadColumn("IdOfTTRow"),
			"LineNumber");
		
		TableStatusesOfBatchIndication = SelectionFromRequestForCalculatingStatusesForSpecifyingSeries(
			ActionParameters.SeriesSpecificationParameters,
			TableOfGoods,
			TableOfSeries,
			CommonClientServer.StructureProperty(
				ActionParameters,
				"Warehouse",
				PredefinedValue("Catalog.Warehouses.EmptyRef")),,,
				True);
		
		QueryDetails.QueryOptions.Insert("TableStatusesOfBatchIndication", TableStatusesOfBatchIndication);
		
		ListOfRequests = QueryTextsCheckBatchCalculateStatus(
			SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication);
		
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to check whether the item series is specified correctly and filled in.
//
// Parameters:
//	StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails.
//	CachedValues - Structure
//
Procedure CompleteQueryTextCheckBatchByOwner(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"CheckBatchByOwner",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		ListOfRequests = QueryTextsCheckBatchByOwner();
		
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure RaiseExceptionForNameTemplateError(OperandName, AttributeName = "")
	
	ErrorMessageTemplate =
		NStr("vi = 'Không thể tính toán tên gọi theo khuôn mẫu.
				   |Lỗi trong tên toán hạng ""%OperandName%"".';
				   |ru = 'Невозможно рассчитать наименование по шаблону.
				   |Ошибка в имени операнда ""%OperandName%"".';
				   |en = 'Cannot calculate a name according to the template.
				   |Error in the ""%OperandName%"" operand name.'; fa = 'Cannot calculate a name according to the template.
				   |Error in the ""%OperandName%"" operand name.';
				   |it = 'Impossibile calcolare il nome del modello.
				   |Errore nel nome dell''operando ""%OperandName%"".';
				   |pl = 'Niemożliwe jest rozliczenie nazwy wg szablonu.
				   |Błąd w nazwie operandu ""%OperandName%"".';
				   |tr = 'Numuneye göre tanım hesaplanamıyor.
				   |""%OperandName%"" işlenen adında hata.'");
	ErrorMessageText  =
		StrReplace(ErrorMessageTemplate, "%OperandName%", OperandName + ?(AttributeName = "", "", ":" + AttributeName));
	
	Raise ErrorMessageText;
	
EndProcedure

Function RoundUpRoughly(Number)
	
	If Int(Number) <> Number Then
		Result = Int(Number) + 1;
	Else
		Result = Number;
	EndIf;
	
	Return Result;
	
EndFunction

// The function adds a new row to the value table and copies data from the source row to it
// 
// Parameters:
// 	Table - ValueTable
// 	SourceRow - ValueTableRow
// 	
// Returns:
// 	ValueTableRow
//
Function AddAndFillLine(Table, SourceRow)
	NewRow = Table.Add();
	FillPropertyValues(NewRow, SourceRow);
	Return NewRow;
EndFunction

Function OptionToTransferSettingsByCharacteristics(Receiver, Source, MatchesCopiedObjects) Export
	
	SourceAttributes = Common.ObjectAttributesValues(Source, "ItemVariantsOwner,ProductKind,UseVariants");
	
	If (Receiver.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind
		And Receiver.ProductKind = SourceAttributes.ProductKind)
		Or (Receiver.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind
		And (Receiver.ItemVariantsOwner = SourceAttributes.ProductKind 
		Or Receiver.ItemVariantsOwner = SourceAttributes.ItemVariantsOwner)) Then
		TransferOption = "TakeFromSource";
	ElsIf Receiver.UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems
		And SourceAttributes.UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems
		And MatchesCopiedObjects.Property("Characteristics") Then
		TransferOption = "TakeFromCorrespondence";
	ElsIf Receiver.UseVariants = Enums.ItemVariantsUsageOptions.DontUse
		And SourceAttributes.UseVariants = Enums.ItemVariantsUsageOptions.DontUse Then 
		TransferOption = "NotUsed_";
	Else
		TransferOption = "NoWrap";
	EndIf;
	
	Return TransferOption;
	
EndFunction

Function OptionToTransferSettingsByPackage(Receiver, Source, MatchesCopiedObjects) Export
	
	SourceAttributes = Common.ObjectAttributesValues(Source, "UsePackages,PackagingGroup");
	
	If Receiver.UsePackages
		And SourceAttributes.UsePackages
		And Receiver.PackagingGroup <> Catalogs.PackagingGroups.SpecialForItem
		And Receiver.PackagingGroup = SourceAttributes.PackagingGroup Then
		
		TransferOption = "TakeFromSource";
		
	ElsIf Receiver.UsePackages
		And SourceAttributes.UsePackages	
		And Receiver.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem
		And Receiver.PackagingGroup = SourceAttributes.PackagingGroup
		And MatchesCopiedObjects.Property("Packages") Then
		
		TransferOption = "TakeFromCorrespondence";
		
	ElsIf Not Receiver.UsePackages
		And Not SourceAttributes.UsePackages Then
		
		TransferOption = "NotUsed_";
		
	Else
		TransferOption = "NoWrap";
	EndIf;
	
	Return TransferOption;

EndFunction

#Region ProceduresForWorkingWithSeries

Function SelectionFromRequestForCalculatingStatusesForSpecifyingSeries(SeriesSpecificationParameters,
													GoodsTable,
													SeriesTable,
													Warehouse, //If the warehouses are in PM, then the parameter is ignored
													RowsOfProductsToProcess = Undefined,
													SeriesRowsToProcess = Undefined,
													ReturnATable = False) Export
	
	ManagerModule = Common.ObjectManagerByFullName(SeriesSpecificationParameters.FullObjectName);
	
	QueryText = ManagerModule.TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters);
	
	Query = New Query;
	Query.Text = QueryText;
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	If TypeOf(Warehouse) = Type("Structure") Then
		Query.SetParameter("SourceWarehouse", Warehouse.Sender);
		Query.SetParameter("DestinationWarehouse", Warehouse.Recipient);
	Else
		Query.SetParameter("Warehouse", Warehouse);
		Query.SetParameter("SourceWarehouse", Warehouse);
		Query.SetParameter("DestinationWarehouse", Warehouse);
	EndIf;
	
	SetRequestParametersBySpecifyingSeriesParameters(Query,SeriesSpecificationParameters);
	
	If TypeOf(GoodsTable) = Type("ValueTable") Then
		TableProductsQueryParameter = GoodsTable;
	Else
		If RowsOfProductsToProcess <> Undefined Then
			TableProductsQueryParameter = GoodsTable.Unload(RowsOfProductsToProcess);
		Else
			TableProductsQueryParameter = GoodsTable.Unload();
		EndIf;
	EndIf;
	
	If TypeOf(SeriesTable) = Type("ValueTable") Then
		QueryParameterSeriesTable = SeriesTable;
	Else
		If SeriesRowsToProcess <> Undefined Then
			QueryParameterSeriesTable = SeriesTable.Unload(SeriesRowsToProcess);
		Else
			QueryParameterSeriesTable = SeriesTable.Unload();
		EndIf;
	EndIf;
	
 	Query.SetParameter("Goods", TableProductsQueryParameter);
	Query.SetParameter("SetOfSeries", QueryParameterSeriesTable);
	
	SetPrivilegedMode(True); // During the movement of goods, one of the warehouses may not be available to the user
	
	If ReturnATable Then
		Result = Query.Execute().Unload();
	Else
		Result = Query.Execute().Select();
	EndIf;
	
	Return Result;
	
EndFunction

Function ValuesOfDetailsForFillingInParametersForSpecifyingSeries(Object, AttributesNames)
	
	If Documents.AllRefsType().ContainsType(TypeOf(Object)) Then
		Structure = Common.ObjectAttributesValues(Object, AttributesNames);
	Else
		Structure = New Structure(AttributesNames);
		FillPropertyValues(Structure, Object);
	EndIf;
	If Structure.Property("Date") And Not ValueIsFilled(Structure.Date) Then
		Structure.Date = CurrentSessionDate();
	EndIf;
	If Structure.Property("DateOfShipment") And Not ValueIsFilled(Structure.DateOfShipment) Then
		Structure.DateOfShipment = CurrentSessionDate();
	EndIf;
	Return Structure;
	
EndFunction

Procedure SetRequestParametersBySpecifyingSeriesParameters(Query,SeriesSpecificationParameters)
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.RetailShipment) <> Undefined Then
		Query.SetParameter("RetailShipment", True);
	Else
		Query.SetParameter("RetailShipment", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipmentToCustomer) <> Undefined Then
		Query.SetParameter("ShipmentToCustomer", True);
	Else
		Query.SetParameter("ShipmentToCustomer", False);
	EndIf;
		
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipComponentsForAssembly) <> Undefined Then
		Query.SetParameter("ShipComponentsForAssembly", True);
	Else
		Query.SetParameter("ShipComponentsForAssembly", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipSetsForDisassembly) <> Undefined Then
		Query.SetParameter("ShipSetsForDisassembly", True);
	Else
		Query.SetParameter("ShipSetsForDisassembly", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipmentForInternalNeeds) <> Undefined Then
		Query.SetParameter("ShipmentForInternalNeeds", True);
	Else
		Query.SetParameter("ShipmentForInternalNeeds", False);
	EndIf;

	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipmentUnderReturnToVendor) <> Undefined Then
		Query.SetParameter("ShipmentUnderReturnToVendor", True);
	Else
		Query.SetParameter("ShipmentUnderReturnToVendor", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipmentByTransfer) <> Undefined Then
		Query.SetParameter("ShipmentByTransfer", True);
	Else
		Query.SetParameter("ShipmentByTransfer", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceiptFromVendor) <> Undefined Then
		Query.SetParameter("ReceiptFromVendor", True);
	Else
		Query.SetParameter("ReceiptFromVendor", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingByReturnFromACustomer) <> Undefined Then
		Query.SetParameter("ReceivingByReturnFromACustomer", True);
	Else
		Query.SetParameter("ReceivingByReturnFromACustomer", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingByTransfer) <> Undefined Then
		Query.SetParameter("ReceivingByTransfer", True);
	Else
		Query.SetParameter("ReceivingByTransfer", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.GoodsReceiptByOtherTransactions) <> Undefined Then
		Query.SetParameter("GoodsReceiptByOtherTransactions", True);
	Else
		Query.SetParameter("GoodsReceiptByOtherTransactions", False);            
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingOfAssembledSets) <> Undefined Then
		Query.SetParameter("ReceivingOfAssembledSets", True);
	Else
		Query.SetParameter("ReceivingOfAssembledSets", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingOfComponentsAfterDisassembly) <> Undefined Then
		Query.SetParameter("ReceivingOfComponentsAfterDisassembly", True);
	Else
		Query.SetParameter("ReceivingOfComponentsAfterDisassembly", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.SurplusesRecord) <> Undefined Then
		Query.SetParameter("SurplusesRecord", True);
	Else
		Query.SetParameter("SurplusesRecord", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShortageRecord) <> Undefined Then
		Query.SetParameter("ShortageRecord", True);
	Else
		Query.SetParameter("ShortageRecord", False);
	EndIf;

	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.DamageRecord) <> Undefined Then
		Query.SetParameter("DamageRecord", True);
	Else
		Query.SetParameter("DamageRecord", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.Recalculate) <> Undefined Then
		Query.SetParameter("Recalculate", True);
	Else
		Query.SetParameter("Recalculate", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.RecalculationResultRecord) <> Undefined Then
		Query.SetParameter("RecalculationResultRecord", True);
	Else
		Query.SetParameter("RecalculationResultRecord", False);
	EndIf;

	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.PickingFromStorageBins) <> Undefined Then
		Query.SetParameter("PickingFromStorageBins", True);
	Else
		Query.SetParameter("PickingFromStorageBins", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipmentControl) <> Undefined Then
		Query.SetParameter("ShipmentControl", True);
	Else
		Query.SetParameter("ShipmentControl", False);
	EndIf;

	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.PlacementIntoBins) <> Undefined Then
		Query.SetParameter("PlacementIntoBins", True);
	Else
		Query.SetParameter("PlacementIntoBins", False);
	EndIf;

	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.TransferBetweenWarerooms) <> Undefined Then
		Query.SetParameter("TransferBetweenWarerooms", True);
	Else
		Query.SetParameter("TransferBetweenWarerooms", False);
	EndIf;

	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipProductsFromProduction) <> Undefined Then
		Query.SetParameter("ShipProductsFromProduction", True);
	Else
		Query.SetParameter("ShipProductsFromProduction", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ProductReceivingFromManufacturing) <> Undefined Then
		Query.SetParameter("ProductReceivingFromManufacturing", True);
	Else
		Query.SetParameter("ProductReceivingFromManufacturing", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.TransferToProductionShipment) <> Undefined Then
		Query.SetParameter("TransferToProductionShipment", True);
	Else
		Query.SetParameter("TransferToProductionShipment", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.TransferToProductionReceiving) <> Undefined Then
		Query.SetParameter("TransferToProductionReceiving", True);
	Else
		Query.SetParameter("TransferToProductionReceiving", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ProductionTransferShipment) <> Undefined Then
		Query.SetParameter("ProductionTransferShipment", True);
	Else
		Query.SetParameter("ProductionTransferShipment", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingByTransfersInProduction) <> Undefined Then
		Query.SetParameter("ReceivingByTransfersInProduction", True);
	Else
		Query.SetParameter("ReceivingByTransfersInProduction", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReturnMaterialsFromProductionShipment) <> Undefined Then
		Query.SetParameter("ReturnMaterialsFromProductionShipment", True);
	Else
		Query.SetParameter("ReturnMaterialsFromProductionShipment", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.AllocationForCosts) <> Undefined Then
		Query.SetParameter("AllocationForCosts", True);
	Else
		Query.SetParameter("AllocationForCosts", False);
	EndIf;
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ConsumptionDuringProduction) <> Undefined Then
		Query.SetParameter("ConsumptionDuringProduction", True);
	Else
		Query.SetParameter("ConsumptionDuringProduction", False);
	EndIf;
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReturnMaterialsFromProductionReceiving) <> Undefined Then
		Query.SetParameter("ReturnMaterialsFromProductionReceiving", True);
	Else
		Query.SetParameter("ReturnMaterialsFromProductionReceiving", False);
	EndIf;
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingInventoryInOperation) <> Undefined Then
		Query.SetParameter("ReceivingInventoryInOperation", True);
	Else
		Query.SetParameter("ReceivingInventoryInOperation", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.DisposalInventoryInOperation) <> Undefined Then
		Query.SetParameter("DisposalInventoryInOperation", True);
	Else
		Query.SetParameter("DisposalInventoryInOperation", False);
	EndIf;
	
	If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.RecordInventoryInOperation) <> Undefined Then
		Query.SetParameter("RecordInventoryInOperation", True);
	Else
		Query.SetParameter("RecordInventoryInOperation", False);
	EndIf;
	
	For Each AddnlParameter_ In SeriesSpecificationParameters.QueryOptions Do
		Query.SetParameter(AddnlParameter_.Key, AddnlParameter_.Value);
	EndDo;
	
	Query.SetParameter("ShipmentPlanning", SeriesSpecificationParameters.ShipmentPlanning);
	
	Query.SetParameter("SelectionPlanning", SeriesSpecificationParameters.SelectionPlanning);
	
	Query.SetParameter("FactOfSelection", SeriesSpecificationParameters.FactOfSelection);
	
	Query.SetParameter("PickingCheck", SeriesSpecificationParameters.PickingCheck);              
	
	Query.SetParameter("OrderPreparation", SeriesSpecificationParameters.OrderPreparation);
	
	Query.SetParameter("SeriesOnlyForCostPrice", SeriesSpecificationParameters.SeriesOnlyForCostPrice);
	
	Query.SetParameter("Date", SeriesSpecificationParameters.Date);
	
	Query.SetParameter("UseBinLocationWarehousing",SeriesSpecificationParameters.UseBinLocationWarehousing);
	
	Query.SetParameter("Date", SeriesSpecificationParameters.Date);
	Query.SetParameter("ProductInHeader", SeriesSpecificationParameters.ProductInHeader);
	
	Query.SetParameter("OnlySeriesTakingIntoAccountLeftovers", SeriesSpecificationParameters.OnlySeriesTakingIntoAccountLeftovers);
	
	Query.SetParameter("DocumentOperation_", SeriesSpecificationParameters.DocumentOperation_);

EndProcedure

Procedure ClearUnusedSeriesBasedOnItemInHeader(DocumentObject, SeriesSpecificationParameters)
	
	TSGoods = New Array;
	TSGoods.Add(DocumentObject);
	If SeriesSpecificationParameters.Property("Header") Then
		ClearUnusedSeriesWHGoods(DocumentObject, SeriesSpecificationParameters.Header, TSGoods);
	Else
		ClearUnusedSeriesWHGoods(DocumentObject, SeriesSpecificationParameters, TSGoods);
	EndIf;	
	
	If SeriesSpecificationParameters.Property("TS") Then
		ClearUnusedSeriesWHGoods(DocumentObject, SeriesSpecificationParameters.TS, DocumentObject[SeriesSpecificationParameters.TS.NameTSGoods]);	
	EndIf;
		
	If SeriesSpecificationParameters.Property("TS") Then
		GoodsTable = DocumentObject[SeriesSpecificationParameters.TS.NameTSGoods].Unload();
	Else
		GoodsTable = New ValueTable;
		GoodsTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		GoodsTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		GoodsTable.Columns.Add("BatchesIndicationStatus", New TypeDescription("Number",New NumberQualifiers(2,0, AllowedSign.Nonnegative)));
		
		For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
			TypesArray = New Array;
			TypesArray.Add(TypeOf(DocumentObject[ArrRow]));
			GoodsTable.Columns.Add(ArrRow, New TypeDescription(TypesArray));
		EndDo;
	EndIf;
		
	NewRow = GoodsTable.Add();
	FillPropertyValues(NewRow, DocumentObject);
	
	
	If SeriesSpecificationParameters.Property("Header") Then
		If SeriesSpecificationParameters.Header.ThisIsOrder
			And WarehousesClientServer.ThereIsShipment(SeriesSpecificationParameters.Header.WarehouseTransactions)
			And Not DocumentObject.WithAssignment Then
			
			NewRow.Purpose = Catalogs.Assignments.EmptyRef();
			
		EndIf;
		
		If SeriesSpecificationParameters.Header.SeriesWhenPlanningShipmentVHFSeriesAreIndicated
			And Not SeriesSpecificationParameters.TS.SeriesWhenPlanningShipmentVHFSeriesAreIndicated
			And (NewRow.BatchesIndicationStatus = 9
			Or NewRow.BatchesIndicationStatus = 10) Then
			NewRow.BatchesIndicationStatus = 8;
		EndIf;
	EndIf;
	
	If SeriesSpecificationParameters.Property("TS") Then
		ClearUnusedSeriesWHSeries(DocumentObject, SeriesSpecificationParameters.TS, GoodsTable);
	Else
		ClearUnusedSeriesWHSeries(DocumentObject, SeriesSpecificationParameters, GoodsTable);
	EndIf;	
EndProcedure

Procedure ClearUnusedSeriesWHGoods(DocumentObject, SeriesSpecificationParameters, TSGoods)
	
	ThereAreSeriesOfWHProducts = TSGoods.Count() > 0
		And TMCommonUseClientServer.HasObjectAttribute(TSGoods[0], "Series");
	
	If ThereAreSeriesOfWHProducts Then
		For Each RowOfTables In TSGoods Do
			
			If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
				If Not ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(RowOfTables.BatchesIndicationStatus, SeriesSpecificationParameters)
					Or ProductsClientServer.NoSeriesAreSpecifiedInThisStatus(RowOfTables.BatchesIndicationStatus, SeriesSpecificationParameters) Then
					
					RowOfTables.Series = Catalogs.ItemsBatches.EmptyRef();
					
				EndIf;
			Else
				For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
					If NameOfStatusField = "BatchesIndicationStatus" Then
						FieldNameSeries = "Series";
					Else
						MatchesSeriesFieldNameToStatusOfSeriesIndication = SeriesSpecificationParameters.MatchesSeriesFieldNameToStatusOfSeriesIndication; // Map -
						FieldNameSeries = MatchesSeriesFieldNameToStatusOfSeriesIndication.Get(NameOfStatusField);
					EndIf;
					
					If FieldNameSeries <> Undefined
						And TMCommonUseClientServer.HasObjectAttribute(RowOfTables, FieldNameSeries)
						And (ProductsClientServer.NoSeriesAreSpecifiedInThisStatus(RowOfTables[NameOfStatusField], SeriesSpecificationParameters)
							Or Not ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(RowOfTables.BatchesIndicationStatus, SeriesSpecificationParameters)) Then
						
						RowOfTables[FieldNameSeries] = Catalogs.ItemsBatches.EmptyRef();
						
					EndIf;
				EndDo;
			EndIf;
			
		EndDo;
	EndIf;
	
EndProcedure

Procedure ClearUnusedSeriesWHSeries(DocumentObject, SeriesSpecificationParameters, GoodsTable)
	
	If SeriesSpecificationParameters.NameTSGoods = SeriesSpecificationParameters.TSSeriesName
		Or DocumentObject[SeriesSpecificationParameters.TSSeriesName].Count() = 0 Then
		Return;
	EndIf;
		
	Query = New Query;
	
	TextOfProductsLinkField = "";
	SeriesLinkFieldText = "";
	CommunicationFieldTextConnectionProductsSeries = "";
	
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		TextOfProductsLinkField = TextOfProductsLinkField + "
		|	TableOfGoods." + ArrRow + ",";
		SeriesLinkFieldText = SeriesLinkFieldText + "
		|	TableOfSeries." + ArrRow + ",";
		CommunicationFieldTextConnectionProductsSeries = CommunicationFieldTextConnectionProductsSeries + "
		|			AND TableOfGoods."+ArrRow+" = TableOfSeries."+ArrRow;
	EndDo;
	
	QueryText =
	"SELECT 
	|	&TextOfProductsLinkField,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.BatchesIndicationStatus
	|INTO TableOfGoods
	|FROM
	|	&GoodsTable AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&SeriesLinkFieldText,
	|	TableOfSeries.LineNumber,
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic
	|INTO TableOfSeries
	|FROM
	|	&TableOfSeries AS TableOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.LineNumber AS LineNumber
	|FROM
	|	TableOfSeries AS TableOfSeries
	|		LEFT JOIN TableOfGoods AS TableOfGoods
	|		ON TableOfSeries.Products = TableOfGoods.Products
	|			AND TableOfSeries.Characteristic = TableOfGoods.Characteristic
	|			AND &CommunicationFieldTextConnectionProductsSeries
	|WHERE
	|	NOT ISNULL(TableOfGoods.BatchesIndicationStatus, 0) IN (&StatusesOfSeriesSpecifiedByVHFSeries)
	|
	|GROUP BY
	|	TableOfSeries.LineNumber
	|
	|ORDER BY
	|	LineNumber DESC";
	
	StatusesOfSeriesSpecifiedByVHFSeries = New Array;
	StatusesOfSeriesSpecifiedByVHFSeries.Add(1);
	StatusesOfSeriesSpecifiedByVHFSeries.Add(2);
	StatusesOfSeriesSpecifiedByVHFSeries.Add(3);
	StatusesOfSeriesSpecifiedByVHFSeries.Add(4);
	StatusesOfSeriesSpecifiedByVHFSeries.Add(5);
	StatusesOfSeriesSpecifiedByVHFSeries.Add(6);
	StatusesOfSeriesSpecifiedByVHFSeries.Add(7);
	StatusesOfSeriesSpecifiedByVHFSeries.Add(8);
	If SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated Then
		StatusesOfSeriesSpecifiedByVHFSeries.Add(9);
		StatusesOfSeriesSpecifiedByVHFSeries.Add(10);
	EndIf;
	
	ThereAreSeriesOfWHProducts = GoodsTable.Count() > 0
		And TMCommonUseClientServer.HasObjectAttribute(GoodsTable[0], "Series");
		
	If Not ThereAreSeriesOfWHProducts Then
		StatusesOfSeriesSpecifiedByVHFSeries.Add(13);
		StatusesOfSeriesSpecifiedByVHFSeries.Add(14);
		StatusesOfSeriesSpecifiedByVHFSeries.Add(17);
		StatusesOfSeriesSpecifiedByVHFSeries.Add(18);
		StatusesOfSeriesSpecifiedByVHFSeries.Add(19);
		StatusesOfSeriesSpecifiedByVHFSeries.Add(20);
	EndIf;
	
	Query.SetParameter("GoodsTable",GoodsTable);
	Query.SetParameter("TableOfSeries",
			DocumentObject[SeriesSpecificationParameters.TSSeriesName].Unload());
	Query.SetParameter("StatusesOfSeriesSpecifiedByVHFSeries", StatusesOfSeriesSpecifiedByVHFSeries);
	
	QueryText = StrReplace(QueryText, "&TextOfProductsLinkField,", TextOfProductsLinkField);
	QueryText = StrReplace(QueryText, "&SeriesLinkFieldText,", SeriesLinkFieldText);
	QueryText = StrReplace(QueryText, "AND &CommunicationFieldTextConnectionProductsSeries", CommunicationFieldTextConnectionProductsSeries);
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		DocumentObject[SeriesSpecificationParameters.TSSeriesName].Delete(DocumentObject[SeriesSpecificationParameters.TSSeriesName][Selection.LineNumber-1]);
		
	EndDo;

EndProcedure

// Sets the selection parameters from other parameters. Called from the processing of receiving selection data
// and when creating the series accounting policy selection form.
//
// Parameters:
//  Parameters - See ProductsClientServer.SelectionParametersForSeriesAccountingPolicies
//  
// Returns:
//  Structure - Contains:
//  	* PolicyType - FixedArray of EnumRef.TypesOfBatchSpecificationPolicies
//  	* ForWarehouse - Boolean
//  	* ForProduction - Boolean
//  	* SpecifyWhenRecordingSurpluses - Boolean
//  	* SpecifyWhenRecordingShortages - Boolean
//  	* BatchesAccountingOfGoodsInTransitFromVendor - Boolean
//  	* BatchesAccountingInUninvoicedGoodsDeliveries - Boolean
//  	* SeriesAccountingOfGoodsTransferredToSubcontractor - Boolean
//  	* AccountingOfBatchesInGoodsTransferredToCommissionAgent - Boolean
//  	* AccountingForGoodsBatchesShippedToCustomer - Boolean
//
Function SelectionOfSeriesAccountingPoliciesByParameters(Parameters) Export
	
	Filter = New Structure;
	
	If Not Parameters.Property("KeepAccountingByBatch") 
		Or Not Parameters.KeepAccountingByBatch Then
		Return Filter;
	EndIf;
	
	ArrayOfValidPolicyTypes = New Array;
	
	// To display the predefined "Series are not used" policy
	ArrayOfValidPolicyTypes.Add(Enums.TypesOfBatchSpecificationPolicies.EmptyRef());
	
	If Parameters.ItemsType = Enums.ItemsTypes.ReusablePackage Then
		
		ArrayOfValidPolicyTypes.Add(Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification);
		
	ElsIf Parameters.ItemsType = Enums.ItemsTypes.OwnGoods Then
		
		If Parameters.BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
			
			ArrayOfValidPolicyTypes.Add(Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification);
			
		ElsIf Parameters.UseShelfLifeOnBatchRegistration Then
			
			ArrayOfValidPolicyTypes.Add(Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification);
			ArrayOfValidPolicyTypes.Add(Enums.TypesOfBatchSpecificationPolicies.BatchesBalancesManagement);
			ArrayOfValidPolicyTypes.Add(Enums.TypesOfBatchSpecificationPolicies.FEFOAutoCalculationOfRemainingBatch);
			ArrayOfValidPolicyTypes.Add(Enums.TypesOfBatchSpecificationPolicies.BatchesBalancesFEFOManagement);
			ArrayOfValidPolicyTypes.Add(Enums.TypesOfBatchSpecificationPolicies.CostAccountingByBatches);
			
		Else	
			
			ArrayOfValidPolicyTypes.Add(Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification);
			ArrayOfValidPolicyTypes.Add(Enums.TypesOfBatchSpecificationPolicies.BatchesBalancesManagement);
			ArrayOfValidPolicyTypes.Add(Enums.TypesOfBatchSpecificationPolicies.CostAccountingByBatches);
			
		EndIf;
	EndIf;

	Filter.Insert("PolicyType", New FixedArray(ArrayOfValidPolicyTypes));
	
	Warehouse = Parameters.Warehouse;
	
	If ValueIsFilled(Warehouse) Then
		If TypeOf(Warehouse) = Type("CatalogRef.Warehouses") Then
			
			Filter.Insert("ForWarehouse", True);
			If Not WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse) Then
				Filter.Insert("SpecifyWhenRecordingSurpluses", False);
				Filter.Insert("SpecifyWhenRecordingShortages", False);
			EndIf;
			
		ElsIf TypeOf(Warehouse) = Type("CatalogRef.BusinessStructure") Then
			Filter.Insert("ForProduction", True);
		EndIf;
	Else
		
		If WarehousesServer.ThereAreWarehousesWithoutAnOrderSchemeWhenReflectingSurplusesAndShortages() Then
			Filter.Insert("SpecifyWhenRecordingSurpluses", False);
			Filter.Insert("SpecifyWhenRecordingShortages", False);
		EndIf;
		
	EndIf;
	
	ProductKind = Parameters.ProductKind;
	
	UseUninvoicedDeliveries = GetFunctionalOption("UseUninvoicedDeliveries");
	UseGoodsInTransitFromVendors  = GetFunctionalOption("UseGoodsInTransitFromVendors");
	ToUseTheTransferOfGoodsToStorage = GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	UseProductionByThirdParty     = False;
	UseProductionByThirdParty     = GetFunctionalOption("UseProductionByThirdParty2_5");
	UseSalesCommission       = GetFunctionalOption("UseSalesCommission")
											And GetFunctionalOption("UseCustomerContracts");
	UseShipmentWithDeferredTransferOfTitle2_5 =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5");
	
	// The Visible nomenclature parameter is passed only when the series accounting policy is selected in the header
	If ValueIsFilled(ProductKind)
		And (UseUninvoicedDeliveries
			Or UseGoodsInTransitFromVendors
			Or UseProductionByThirdParty
			Or ToUseTheTransferOfGoodsToStorage
			Or UseSalesCommission
			Or UseShipmentWithDeferredTransferOfTitle2_5) Then
		
		// The policy in the header can be changed, so it is not blocked by the BSP, but
		// if now the policy is indicated in the header, taking into account the series for goods in transit, non-invoicing, from keepers
		// and processors, then you can only change the policy to the one with the same flag values.

		AttributesNames = New Structure;
		AttributesNames.Insert(
			"BatchesAccountingInUninvoicedGoodsDeliveries",
			"BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries");
		AttributesNames.Insert(
			"BatchesAccountingOfGoodsInTransitFromVendor",
			"BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor");
		AttributesNames.Insert(
			"BatchesAccountingInDepositedGoods",
			"BatchAccountingPolicy.BatchesAccountingInDepositedGoods");
		AttributesNames.Insert(
			"SeriesAccountingOfGoodsTransferredToSubcontractor",
			"BatchAccountingPolicy.SeriesAccountingOfGoodsTransferredToSubcontractor");
		AttributesNames.Insert(
			"AccountingOfBatchesInGoodsTransferredToCommissionAgent",
			"BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent");
		AttributesNames.Insert(
			"AccountingForGoodsBatchesShippedToCustomer",
			"BatchAccountingPolicy.AccountingForGoodsBatchesShippedToCustomer");
		
		DetailsOfCurSeriesAccountingPolicy = Common.ObjectAttributesValues(ProductKind, AttributesNames);
		
		Filter.Insert(
			"BatchesAccountingInUninvoicedGoodsDeliveries",
			DetailsOfCurSeriesAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries);
		
		Filter.Insert(
			"BatchesAccountingOfGoodsInTransitFromVendor",
			DetailsOfCurSeriesAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor);
		
		Filter.Insert(
			"BatchesAccountingInDepositedGoods",
			DetailsOfCurSeriesAccountingPolicy.BatchesAccountingInDepositedGoods);
		Filter.Insert(
			"SeriesAccountingOfGoodsTransferredToSubcontractor",
			DetailsOfCurSeriesAccountingPolicy.SeriesAccountingOfGoodsTransferredToSubcontractor);
		Filter.Insert(
			"AccountingOfBatchesInGoodsTransferredToCommissionAgent",
			DetailsOfCurSeriesAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent);
		
		Filter.Insert(
			"AccountingForGoodsBatchesShippedToCustomer",
			DetailsOfCurSeriesAccountingPolicy.AccountingForGoodsBatchesShippedToCustomer);
		
	EndIf;
	
	Return Filter;
	
EndFunction

Function SelectionOfOwnerOfSubordinateCatalogs(ProductKind, PropsNameOwner) Export
	
	SelectionOfOwnerOfSubordinateCatalogs = New Structure;
	
	ItemsTypes = New Array;
	
	If PropsNameOwner = "ItemVariantsOwner" Then
		
		FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend = FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend(); 
		
		If FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend.Find(ProductKind.AccountingFeature) <> Undefined Then
			SelectionOfOwnerOfSubordinateCatalogs.Insert("AccountingFeature", ProductKind.AccountingFeature);
		Else
			ChoiceData = New ValueList;
			TMCommonUse.SelectableEnumerationValues("ItemAccountingFeatures", ChoiceData,, FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend);
			ChoiceData.Add(Enums.ItemAccountingFeatures.EmptyRef());
			
			SelectionOfOwnerOfSubordinateCatalogs.Insert("AccountingFeature", New FixedArray(ChoiceData.UnloadValues()));
		EndIf;
	
		SelectionOfOwnerOfSubordinateCatalogs.Insert("UseVariants",
			Enums.ItemVariantsUsageOptions.CommonForItemKind);
	ElsIf PropsNameOwner = "BatchOwner" Then
		
		ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
		
		If ProductKind.ItemsType <> Enums.ItemsTypes.ReusablePackage Then
			ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
		EndIf;
		
		AccountingFeaturesThatDependOnDetailsOfSeries = AccountingFeaturesThatDependOnDetailsOfSeries();
		
		If AccountingFeaturesThatDependOnDetailsOfSeries.Find(ProductKind.AccountingFeature) <> Undefined Then
			SelectionOfOwnerOfSubordinateCatalogs.Insert("AccountingFeature", 
				New FixedArray(CompatibleFeaturesOfAccountingBySeries(ProductKind.AccountingFeature)));
		Else
			ChoiceData = New ValueList;
			TMCommonUse.SelectableEnumerationValues("ItemAccountingFeatures", ChoiceData,, AccountingFeaturesThatDependOnDetailsOfSeries);
			ChoiceData.Add(Enums.ItemAccountingFeatures.EmptyRef());
			
			SelectionOfOwnerOfSubordinateCatalogs.Insert("AccountingFeature", New FixedArray(ChoiceData.UnloadValues()));
		EndIf;
	
		SelectionOfOwnerOfSubordinateCatalogs.Insert("BatchSettingsAreTakenFromOtherItemsKind", False);
		SelectionOfOwnerOfSubordinateCatalogs.Insert("KeepAccountingByBatch", True);
	ElsIf PropsNameOwner = "ProductCategoryOwner" Then
		
		If ProductKind.ItemsType = Enums.ItemsTypes.Work_5
			Or ProductKind.ItemsType = Enums.ItemsTypes.OperationService Then
			ItemsTypes.Add(Enums.ItemsTypes.Work_5);
			ItemsTypes.Add(Enums.ItemsTypes.OperationService);
		Else
			ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
			ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
			ItemsTypes.Add(Enums.ItemsTypes.Set);
		EndIf;

		
		SelectionOfOwnerOfSubordinateCatalogs.Insert("ProductCategoriesCommonWithAnotherKindOfItems", False);
	Else
		
		Raise StrTemplate(NStr("vi = 'Chưa xác định nhận bộ lọc của đối tượng chủ các danh mục trực thuộc đối với mục tin %1';
								|ru = 'Получение отбора владельца подчиненных справочников для реквизита %1 не определено';
								|en = 'Receipt of the subordinate catalogs owner filter for attribute %1 is not defined'; fa = 'Receipt of the subordinate catalogs owner filter for attribute %1 is not defined';
								|it = 'La procedura per ottenere il titolare delle directory subordinate per il requisito %1 non è definita';
								|pl = 'Nie określono otrzymania selekcji właściciela podporządkowanych katalogów dla atrybutu %1';
								|tr = '%1 özniteliği için alt katalogların sahibinin filtre alımı tanımlı değil'"), PropsNameOwner);
	EndIf;
	
	If ItemsTypes.Count() > 0 Then
		SelectionOfOwnerOfSubordinateCatalogs.Insert("ItemsType", New FixedArray(ItemsTypes));
	EndIf;
	
	Return SelectionOfOwnerOfSubordinateCatalogs;
	
EndFunction

// Returns:
// 	Array of EnumRef.ItemAccountingFeatures
// 
Function FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend()
	FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend = New Array;
	
	FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend.Add(Enums.ItemAccountingFeatures.PerformedByCompanyOnAgencyBasis);
	FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend.Add(Enums.ItemAccountingFeatures.PerformedByPartner);
	
	ProductsLocalization.FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend(FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend);
	
	Return FeaturesOfAccountingOnWhichDetailsOfCharacteristicsDepend;
	
EndFunction

Function AccountingFeaturesThatDependOnDetailsOfSeries()
	
	AccountingFeaturesThatDependOnDetailsOfSeries = New Array;
	
	DescriptionsOfUseOfSeriesProps = Catalogs.ItemKinds.DescriptionsOfUseOfSeriesProps();
	
	For Each DetailsList1 In DescriptionsOfUseOfSeriesProps Do
		
		If Not IsBlankString(DetailsList1.AccountingFeatures) Then
			
			FeatureNames = StrSplit(DetailsList1.AccountingFeatures, ",");
			
			For Each FeatureName In FeatureNames Do
				
				EnumerationValue = PredefinedValue("Enum.ItemAccountingFeatures." + FeatureName);
				
				If AccountingFeaturesThatDependOnDetailsOfSeries.Find(EnumerationValue) = Undefined Then
					AccountingFeaturesThatDependOnDetailsOfSeries.Add(EnumerationValue);
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return AccountingFeaturesThatDependOnDetailsOfSeries;
	
EndFunction

Function CompatibleFeaturesOfAccountingBySeries(AccountingFeature)
	
	AccountingFeatures = New Array;
	Exclude = New Map;
	FirstFeature = True;
	DescriptionsOfUseOfSeriesProps = Catalogs.ItemKinds.DescriptionsOfUseOfSeriesProps();
	
	For Each DetailsList1 In DescriptionsOfUseOfSeriesProps Do
		
		If Not IsBlankString(DetailsList1.AccountingFeatures) Then
			
			FeatureNames = StrSplit(DetailsList1.AccountingFeatures, ",");
			DescriptionFeatures = New Array;
			
			For Each FeatureName In FeatureNames Do
				EnumerationValue = PredefinedValue("Enum.ItemAccountingFeatures." + FeatureName);
				DescriptionFeatures.Add(EnumerationValue);
			EndDo;
			
			If DescriptionFeatures.Find(AccountingFeature) = Undefined Then
				For Each EnumerationValue In DescriptionFeatures Do
					Exclude.Insert(EnumerationValue);
				EndDo;
				Continue;
			EndIf;
			
			If FirstFeature Then
				AccountingFeatures = DescriptionFeatures;
				FirstFeature = False;
			Else 
				Intersection = New Array;
				For Each EnumerationValue In AccountingFeatures Do
					If DescriptionFeatures.Find(EnumerationValue) <> Undefined Then
						Intersection.Add(EnumerationValue);
					EndIf;
				EndDo;
				AccountingFeatures = Intersection;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each KeyAndValue In Exclude Do
		FeatureException = AccountingFeatures.Find(KeyAndValue.Key);
		If FeatureException <> Undefined Then
			AccountingFeatures.Delete(FeatureException);
		EndIf;
	EndDo;
	
	Return AccountingFeatures;
	
EndFunction

// Determines whether there is a view for which series are equally counted in all warehouses for the policy that needs
// an order scheme.
// 
// Returns:
//  Boolean
//
Function ThereIsTypeOfProductRequiringObligationOfOrderSchemeForSurplusesShortages(Warehouse) Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ItemKinds.Ref AS Ref
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS TypesOfProductPolicyAccountingSeries
	|		ON ItemKinds.Ref = TypesOfProductPolicyAccountingSeries.Ref
	|			AND (TypesOfProductPolicyAccountingSeries.Warehouse = &Warehouse)
	|WHERE
	|	NOT ItemKinds.IsFolder
	|	AND ItemKinds.KeepAccountingByBatch
	|	AND (TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy IS NULL
	|				AND ItemKinds.BatchAccountingPolicy <> VALUE(Catalog.BatchAccountingPolicies.SeriesAreNotUsed)
	|				AND (ItemKinds.BatchAccountingPolicy.SpecifyWhenRecordingShortages
	|					OR ItemKinds.BatchAccountingPolicy.SpecifyWhenRecordingSurpluses)
	|			OR NOT TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy IS NULL
	|				AND TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy <> VALUE(Catalog.BatchAccountingPolicies.SeriesAreNotUsed)
	|				AND (TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy.SpecifyWhenRecordingShortages
	|					OR TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy.SpecifyWhenRecordingSurpluses))";
	
	Query.SetParameter("Warehouse", Warehouse); 
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Procedure CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, Table, Val Var_Metadata = Undefined, ThisIsSeriesTable = False) Export
	
	If SeriesSpecificationParameters.LinkFields.Count() > 0
		Or Not ThisIsSeriesTable And SeriesSpecificationParameters.AdditionalFieldNames.Count() > 0 Then
		
		If Var_Metadata = Undefined Then
			Var_Metadata = TMCommonUse.ObjectMetadataByFullName(SeriesSpecificationParameters.FullObjectName);
		EndIf;
		
		If SeriesSpecificationParameters.ProductInHeader Then
			MetadataOfTSProductDetails = Var_Metadata.Attributes;
		Else
			MetadataOfTSProductDetails = Var_Metadata.TabularSections[SeriesSpecificationParameters.NameTSGoods].Attributes;
		EndIf;
		
	EndIf;
	
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		If Table.Columns.Find(ArrRow) = Undefined Then
			Table.Columns.Add(ArrRow,MetadataOfTSProductDetails[ArrRow].Type);
		EndIf;
	EndDo;
	
	If ThisIsSeriesTable Then
		Return;
	EndIf;
	
	For Each ArrRow In SeriesSpecificationParameters.AdditionalFieldNames Do
		If Table.Columns.Find(ArrRow) = Undefined Then
			Table.Columns.Add(ArrRow,MetadataOfTSProductDetails[ArrRow].Type);
		EndIf;
	EndDo;

	If SeriesSpecificationParameters.ThisIsOrder Then
		If Table.Columns.Find("Canceled") = Undefined Then
			Table.Columns.Add("Canceled",New TypeDescription("Boolean"));
		EndIf;
		If Table.Columns.Find("SupplyOption") = Undefined Then
			Table.Columns.Add("SupplyOption",New TypeDescription("EnumRef.SupplyOptions"));
		EndIf;
	EndIf;
	
	If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
		If Table.Columns.Find("BatchesIndicationStatus") = Undefined Then
			Table.Columns.Add("BatchesIndicationStatus",New TypeDescription("Number",New NumberQualifiers(2,0,AllowedSign.Nonnegative)));
		EndIf;
	Else
		For Each ArrRow In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
			If Table.Columns.Find(ArrRow) = Undefined Then
				Table.Columns.Add(ArrRow,New TypeDescription("Number",New NumberQualifiers(2,0,AllowedSign.Nonnegative)));
			EndIf;
		EndDo;
	EndIf;

EndProcedure

Procedure FillInWHSeriesAccordingToSeriesTable(Object, SeriesSpecificationParameters, SetOfSeries, Actions) Export
	LinkFieldText = "";
	
	For Each ArrRow In SeriesSpecificationParameters.LinkFields Do
		LinkFieldText = LinkFieldText + "," + ArrRow  ;
	EndDo;
	TheStructureOfTheSearch = New Structure("Products,Characteristic"+LinkFieldText);
	
	CollapsedProductTable = Object[SeriesSpecificationParameters.NameTSGoods].Unload(,"Products,Characteristic"+LinkFieldText); // ValueTable
	CollapsedProductTable.GroupBy("Products,Characteristic"+LinkFieldText);

	RowsToProcess = New Array;

	For Each RowOfTables In CollapsedProductTable Do
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfTables);
		
		FoundSeriesRows_ = SetOfSeries.FindRows(TheStructureOfTheSearch);
		
		If FoundSeriesRows_.Count() > 0 Then
			
			FoundProductLines = Object[SeriesSpecificationParameters.NameTSGoods].FindRows(TheStructureOfTheSearch); // Array of LineOfATabularSection
			NumberOfFirstLineToDelete = 0;
			For Each ArrRow In FoundProductLines Do
				
				If NumberOfFirstLineToDelete = 0 Then
					NumberOfFirstLineToDelete = ArrRow.LineNumber;
				EndIf;
				
				Object[SeriesSpecificationParameters.NameTSGoods].Delete(ArrRow);	
				
			EndDo;
			
			IndexOf = 0;
			
			For Each ArrRow In FoundSeriesRows_ Do
				
				If NumberOfFirstLineToDelete = 0 Then
					NewRow = Object[SeriesSpecificationParameters.NameTSGoods].Add();
				Else
					NewRow = Object[SeriesSpecificationParameters.NameTSGoods].Insert(NumberOfFirstLineToDelete - 1 + IndexOf);
					IndexOf = IndexOf + 1;
				EndIf;
				FillPropertyValues(NewRow, ArrRow);
				If SeriesSpecificationParameters.LinkFields.Find("Package") = Undefined Then 
					NewRow.NumberOfPackages = ArrRow.Count;
				EndIf;
				RowsToProcess.Add(NewRow);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		Actions,
		Object[SeriesSpecificationParameters.NameTSGoods],
		Undefined);

	FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
EndProcedure

// Returns the value of a constant
//
// Parameters:
//  TypeOfMeasuredValueString	 - String - type of measured value by string.
// 
// Returns:
//   CatalogRef.PackagesAndUnitsOfMeasure 
//
Function DefaultUnitOfMeasurement(TypeOfMeasuredValueString) Export
	
	If TypeOfMeasuredValueString = "Weight" Then
		Value = Constants.UnitOfMeasureForWeight.Get();
	ElsIf TypeOfMeasuredValueString = "VolumeM3" Then
		Value = Constants.UnitOfMeasureForVolume.Get();
	ElsIf TypeOfMeasuredValueString = "AreaTypeOfMeasurement" Then
		Value = Constants.UnitOfMeasureForArea.Get();
	ElsIf TypeOfMeasuredValueString = "Length" Then 
		Value = Constants.UnitOfMeasureForLength.Get();
	ElsIf TypeOfMeasuredValueString = "Piece" Then 
		Value = Constants.UnitOfMeasureOfQuantity.Get();
	ElsIf TypeOfMeasuredValueString = "Bottling" Then 
		Value = Constants.UnitOfMeasureOfDraughtProducts.Get();
	Else
		Value = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	EndIf;
	
	Return Value;
EndFunction

Procedure FillSeriesByFefoUHFSeries(Object, SeriesSpecificationParameters)
	
	If SeriesSpecificationParameters.FieldNameRoom <> Undefined Then
		// If the FEFO series is filled in in the PM "Series", then there can be no room in the document.
		ExceptionText = NStr("vi = 'Lỗi điền sê-ri theo FEFO. Có một nhà kho.';
							|ru = 'Ошибка заполнения серий по FEFO. Есть складское помещение.';
							|en = 'An error occurred while populating FEFO batch. There is a wareroom.'; fa = 'An error occurred while populating FEFO batch. There is a wareroom.';
							|it = 'Errore di riempimento della serie di FEFO. C''è un ripostiglio.';
							|pl = 'Błąd wypełnienia serii wg FEFO. Istnieje pomieszczenie magazynowe.';
							|tr = 'FEFO partisini doldururken hata oluştu. Depo mevcuttur.'");
		Raise ExceptionText;
	EndIf;
    
    VHFWarehouses = SeriesSpecificationParameters.LinkFields.Find(SeriesSpecificationParameters.WarehouseFieldName) <> Undefined
		Or SeriesSpecificationParameters.AdditionalFieldNames.Find(SeriesSpecificationParameters.WarehouseFieldName) <> Undefined;
    
	QueryText = RequestTextForFillingInSeriesfefo(SeriesSpecificationParameters);
	
	KeyFields = "Products,Characteristic";
    LinkFieldsInRequestText = "";
    For Each LinksField In SeriesSpecificationParameters.LinkFields Do
        KeyFields = KeyFields + "," + LinksField;
        LinkFieldsInRequestText = LinkFieldsInRequestText + "
        |DocumentData." + LinksField + ",";
    EndDo;
    
    QueryText = StrReplace(QueryText, "DocumentData.LinkFields,", LinkFieldsInRequestText);
    
	If SeriesSpecificationParameters.ThisIsAnInvoice
		And SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipmentByTransfer) <> Undefined Then
		WarehouseFieldName = "SourceWarehouse";
		QueryText = StrReplace(QueryText, "DocumentData.Purpose AS Purpose", "DocumentData.AssignmentSender AS Purpose");
	ElsIf SeriesSpecificationParameters.FullObjectName = "Document.TransferOfGoodsToBailee" Then
		QueryText = StrReplace(QueryText, "DocumentData.Purpose AS Purpose", "DocumentData.AssignmentSender AS Purpose");
	ElsIf SeriesSpecificationParameters.FullObjectName = "Document.MovementOfProductsAndMaterials"
		And (SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.TransferToProductionShipment) <> Undefined 
			Or SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ProductionTransferShipment) <> Undefined)  Then
		WarehouseFieldName = "Sender";
		QueryText = StrReplace(QueryText, "DocumentData.Purpose AS Purpose", "DocumentData.AssignmentSender AS Purpose");
	ElsIf SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ProductionTransferShipment) <> Undefined Then
		WarehouseFieldName = "SendingDepartment";
		QueryText = StrReplace(QueryText, "DocumentData.Purpose AS Purpose", "DocumentData.AssignmentSender AS Purpose");
    Else
        WarehouseFieldName = SeriesSpecificationParameters.WarehouseFieldName;
    EndIf;
    
    Query = New Query;
    TempTablesManager = New TempTablesManager;
   	Query.TempTablesManager = TempTablesManager;
    
    If Not VHFWarehouses Then
        QueryText = StrReplace(QueryText, "DocumentData.Warehouse", "&Warehouse");
        Query.SetParameter("Warehouse",Object[WarehouseFieldName]);
    EndIf;
    
	ControlledLotReference = Undefined;
	If SeriesSpecificationParameters.FieldNameControlledLotReference = Undefined Then
		ControlledLotReference = "VALUE(Catalog.ControlledLots.EmptyRef)";
	ElsIf StrFind(SeriesSpecificationParameters.FieldNameControlledLotReference, ".") > 0 Then
		ControlledLotReference = "DocumentData." + StrReplace(SeriesSpecificationParameters.FieldNameControlledLotReference, ".", "");
	Else
		ControlledLotReference = "&ControlledLotReference";
		Query.SetParameter("ControlledLotReference", Object[SeriesSpecificationParameters.FieldNameControlledLotReference]);
	EndIf;
	QueryText = StrReplace(QueryText, "&ControlledLotReferenceOverridable", ControlledLotReference);
	
    Query.Text = QueryText;
	TableOfSeries = Object[SeriesSpecificationParameters.TSSeriesName].Unload();
	Query.SetParameter("TableOfSeries", TableOfSeries);
	If SeriesSpecificationParameters.ProductInHeader Then
		TableOfSubstitutionProducts = TableOfSeries.CopyColumns(); // ValueTable
		TableOfSubstitutionProducts.Clear();
		TableOfSubstitutionProducts.Columns.Add("BatchesIndicationStatus",New TypeDescription("Number",New NumberQualifiers(2,0,AllowedSign.Nonnegative)));
		FillPropertyValues(TableOfSubstitutionProducts.Add(),Object);
		Query.SetParameter("TableOfGoods", TableOfSubstitutionProducts);
	Else
		Query.SetParameter("TableOfGoods", Object[SeriesSpecificationParameters.NameTSGoods].Unload());
	EndIf;
    Query.SetParameter("Ref", Object.Ref);

	If SeriesSpecificationParameters.FieldNameControlledLotReference <> Undefined
			And StrFind(SeriesSpecificationParameters.FieldNameControlledLotReference, ".") = 0 Then
		Query.SetParameter("ControlledLotReference", Object[SeriesSpecificationParameters.FieldNameControlledLotReference]);
	EndIf;

    QueryResult = Query.ExecuteBatch();
    
    Object[SeriesSpecificationParameters.TSSeriesName].Load(QueryResult[5].Unload()); //Series that do not need to be changed
    
    Selection = QueryResult[4].Select();
    QuantityStructure = New Structure("Count,NumberOfPackages");
	ProductLineBalances = New Map;
	
	While Selection.NextByFieldValue("Products") Do
		While Selection.NextByFieldValue("Characteristic") Do
			While Selection.NextByFieldValue("Warehouse") Do
				While Selection.NextByFieldValue("Series") Do
					RemainderOfSeries = Selection.AvailableStock;
					CacheOfKeyFields = New Structure(KeyFields);
					While Selection.Next() Do // Traversing product lines
						If SeriesSpecificationParameters.ProductInHeader Then
							CurRow = Object;
						Else
							CurRow = Object[SeriesSpecificationParameters.NameTSGoods][Selection.LineNumber - 1];
						EndIf;
						If ProductLineBalances[Selection.LineNumber] = Undefined Then
							ProductBalance = CurRow.Count;
						Else
							ProductBalance = ProductLineBalances[Selection.LineNumber];
						EndIf;
						
						If ProductBalance = 0 Then
							Continue;
						EndIf;
						
						If Not TMCommonUseClientServer.StructuresAreEqual(CurRow,CacheOfKeyFields,KeyFields) Then
							FillPropertyValues(CacheOfKeyFields,CurRow);
							// The selection is ordered by key fields,
							// so changing the key fields says you need to add a new row of series.
							NewRow = Object[SeriesSpecificationParameters.TSSeriesName].Add();
						EndIf;
						
						FillPropertyValues(NewRow,CurRow,,"Count");
						NewRow.Series = Selection.Series;
						QuantityToAdd = Min(ProductBalance,RemainderOfSeries);
						QuantityStructure.Count         = NewRow.Count + QuantityToAdd;
						QuantityStructure.NumberOfPackages = QuantityStructure.Count;
						FillPropertyValues(NewRow,QuantityStructure); 
						
						ProductBalance = ProductBalance - QuantityToAdd;
						ProductLineBalances.Insert(Selection.LineNumber,ProductBalance);
						
						If ProductBalance = 0 Then
							CurRow.BatchesIndicationStatus = 6;
							
							For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
								ProductsClientServer.RecalculateStatusOfSpecifyingSeriesDuringProcessing(SeriesSpecificationParameters,
										CurRow[NameOfStatusField],
										True,
										QuantityToAdd);
							EndDo;

						EndIf;
						RemainderOfSeries = RemainderOfSeries - QuantityToAdd;
						If RemainderOfSeries = 0 Then
							Break;
						EndIf;
						ProductLineBalances.Insert(Selection.LineNumber, ProductBalance)
						
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
	If SeriesSpecificationParameters.ProductInHeader Then
		FillPropertyValues(TableOfSubstitutionProducts[0],Object);
		TSGoods = TableOfSubstitutionProducts;
	Else
		TSGoods = Object[SeriesSpecificationParameters.NameTSGoods];
	EndIf;
	FoundGoods = TSGoods.FindRows(New Structure("BatchesIndicationStatus",5)); // Array of LineOfATabularSection
	If FoundGoods.Count() = 0 Then
		Return;
	EndIf;
	
	WarehouseFieldName = SeriesSpecificationParameters.WarehouseFieldName;
	VHFWarehouses = SeriesSpecificationParameters.LinkFields.Find(WarehouseFieldName) <> Undefined
		Or SeriesSpecificationParameters.AdditionalFieldNames.Find(WarehouseFieldName) <> Undefined;
    
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableOfGoods.Products AS Products,
	|	PRESENTATION(CAST(TableOfGoods.Products AS Catalog.Products).UnitOfMeasure) AS UnitOfMeasure
	|FROM
	|	TableOfGoods AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.Products";
	
	UnitsOfMeasurement = Query.Execute().Unload();
	
	For Each Page1 In FoundGoods Do
		
		If VHFWarehouses Then
			CurrentWarehouse = Page1.Warehouse;
		Else
			CurrentWarehouse = Object[WarehouseFieldName];
		EndIf;
		ThisDivision = (TypeOf(CurrentWarehouse) = Type("CatalogRef.BusinessStructure"));
		
		QuantityNotAllocated = 0;
		If Page1.Count = 0 Then
			
			MessageText = NStr("vi = 'Hàng hóa ""%GoodsPresentation%"" - chưa điền sê-ri. Trong phần bảng ""Hàng hóa"" chưa chỉ ra số lượng.""';
								|ru = 'Товар ""%GoodsPresentation%"" - серии не заполнены. В табличной части ""Товары"" не указано количество.""';
								|en = 'Batches are not filled in for the ""%GoodsPresentation%"" goods item. Quantity is not specified in the Goods table.""'; fa = 'Batches are not filled in for the ""%GoodsPresentation%"" goods item. Quantity is not specified in the Goods table.""';
								|it = 'La merce  ""%GoodsPresentation%"" - serie non sono pieni. La parte alta della ""Merce"" non indica la quantità.""';
								|pl = 'Towar ""%GoodsPresentation%"" - serie nie są wypełnione. W części tabelarycznej ""Товары"" nie jest wskazana ilość.""';
								|tr = 'Ürün ""%GoodsPresentation%"" - partisi doldurulmadı. ""Ürünler"" tablo bölümünde miktar belirtilmedi.""'");
			
		ElsIf ProductLineBalances[Page1.LineNumber] = Undefined Then 
			
			If ThisDivision Then
				MessageText = NStr("vi = 'Hàng hóa ""%GoodsPresentation%"" - chưa điền sê-ri.
					|Trong bộ phận ""%WarehousePresentation_%"" không đủ ""%Count%"" ""%UnitOfMeasure%""';
					|ru = 'Товар ""%GoodsPresentation%"" - серии не заполнены.
					|В подразделении ""%WarehousePresentation_%"" не хватает ""%Count%"" ""%UnitOfMeasure%""';
					|en = 'Batches are not filled in for the ""%GoodsPresentation%"" goods item.
					|""%Count%"" ""%UnitOfMeasure%"" is missing in the ""%WarehousePresentation_%"" business unit'; fa = 'Batches are not filled in for the ""%GoodsPresentation%"" goods item.
					|""%Count%"" ""%UnitOfMeasure%"" is missing in the ""%WarehousePresentation_%"" business unit';
					|it = 'La merce ""%GoodsPresentation%"" - serie non sono pieni.
					|La divisione ""%WarehousePresentation_%"" non è sufficiente ""%Count%"" ""%UnitOfMeasure%""';
					|pl = 'Towar ""%GoodsPresentation%"" - serie nie są wypełnione.
					|W dziale ""%WarehousePresentation_%"" brakuje ""%Count%"" ""%UnitOfMeasure%""';
					|tr = 'Ürün ""%GoodsPresentation%"" - partisi doldurulmadı.
					|""%WarehousePresentation_%"" departmanında ""%Count%"" ""%UnitOfMeasure%"" eksik'");
			Else
				MessageText = NStr("vi = 'Hàng hóa ""%GoodsPresentation%"" - chưa điền sê-ri.
					|Trong kho ""%WarehousePresentation_%"" không đủ ""%Count%"" ""%UnitOfMeasure%""';
					|ru = 'Товар ""%GoodsPresentation%"" - серии не заполнены.
					|На складе ""%WarehousePresentation_%"" не хватает ""%Count%"" ""%UnitOfMeasure%""';
					|en = 'Batches are not filled in for the ""%GoodsPresentation%"" goods item.
					|""%Count%"" ""%UnitOfMeasure%"" is missing in the ""%WarehousePresentation_%"" warehouse'; fa = 'Batches are not filled in for the ""%GoodsPresentation%"" goods item.
					|""%Count%"" ""%UnitOfMeasure%"" is missing in the ""%WarehousePresentation_%"" warehouse';
					|it = 'La merce ""%GoodsPresentation%"" - serie non sono pieni.
					|Nel magazzino ""%WarehousePresentation_%"" non è sufficiente ""%Count%"" ""%UnitOfMeasure%""';
					|pl = 'Towar ""%GoodsPresentation%"" - serie nie są wypełnione.
					|W magazynie ""%WarehousePresentation_%"" brakuje ""%Count%"" ""%UnitOfMeasure%""';
					|tr = '""%GoodsPresentation%"" ürün - partisi doldurulmadı.
					|""%WarehousePresentation_%"" ambarında yeterli ""%Count%"" ""%UnitOfMeasure%"" değil'");
			EndIf; 

			QuantityNotAllocated = Page1.Count;
			
		Else
			
			If ThisDivision Then
				MessageText = NStr("vi = 'Hàng hóa ""%GoodsPresentation%"" - chưa điền đầy đủ sê-ri.
					|Trong bộ phận ""%WarehousePresentation_%"" không đủ ""%Count%"" ""%UnitOfMeasure%""';
					|ru = 'Товар ""%GoodsPresentation%"" - серии заполнены не полностью.
					|В подразделении ""%WarehousePresentation_%"" не хватает ""%Count%"" ""%UnitOfMeasure%""';
					|en = 'The ""%GoodsPresentation%"" goods - batches are filled in incompletely.
					|""%Count%"" ""%UnitOfMeasure%"" is not enough in the ""%WarehousePresentation_%"" business unit'; fa = 'The ""%GoodsPresentation%"" goods - batches are filled in incompletely.
					|""%Count%"" ""%UnitOfMeasure%"" is not enough in the ""%WarehousePresentation_%"" business unit';
					|it = 'La merce ""%GoodsPresentation%"" - serie riempito completamente.
					|La divisione ""%WarehousePresentation_%"" non è sufficiente ""%Count%"" ""%UnitOfMeasure%""';
					|pl = 'Towar ""%GoodsPresentation%"" - serie są wypełnione nie w całości.
					|W dziale ""%WarehousePresentation_%"" brakuje ""%Count%"" ""%UnitOfMeasure%""';
					|tr = 'Ürün ""%GoodsPresentation%"" - partisi tamamen doldurulmadı.
					|""%WarehousePresentation_%"" departmanında ""%Count%"" ""%UnitOfMeasure%"" yeterli değil'");
			Else	
				MessageText = NStr("vi = 'Hàng hóa""%GoodsPresentation%"" - chưa điền đầy đủ sê-ri.
					|Trong kho ""%WarehousePresentation_%"" không đủ ""%Count%"" ""%UnitOfMeasure%""';
					|ru = 'Товар ""%GoodsPresentation%"" - серии заполнены не полностью.
					|На складе ""%WarehousePresentation_%"" не хватает ""%Count%"" ""%UnitOfMeasure%""';
					|en = 'The ""%GoodsPresentation%"" goods - batches are filled in incompletely.
					|""%Count%"" ""%UnitOfMeasure%"" is not enough in the ""%WarehousePresentation_%"" warehouse'; fa = 'The ""%GoodsPresentation%"" goods - batches are filled in incompletely.
					|""%Count%"" ""%UnitOfMeasure%"" is not enough in the ""%WarehousePresentation_%"" warehouse';
					|it = 'La merce ""%GoodsPresentation%"" - serie riempito completamente.
					|Nel magazzino ""%WarehousePresentation_%"" non è sufficiente ""%Count%"" ""%UnitOfMeasure%""';
					|pl = 'Towar ""%GoodsPresentation%"" - serie są wypełnione nie w całości.
					|W magazynie ""%WarehousePresentation_%"" brakuje ""%Count%"" ""%UnitOfMeasure%""';
					|tr = 'Ürün ""%GoodsPresentation%"" - partisi tamamen doldurulmadı.
					|""%WarehousePresentation_%"" ambarında yeterli ""%Count%"" ""%UnitOfMeasure%"" değil'");
			EndIf; 
			QuantityNotAllocated = ProductLineBalances[Page1.LineNumber];
			
		EndIf;	
		
		MessageText = StrReplace(MessageText,"%GoodsPresentation%", ProductsClientServer.ProductPresentation(Page1.Products, Page1.Characteristic));
		
		If VHFWarehouses Then
			MessageText = StrReplace(MessageText,"%WarehousePresentation_%", WarehousesServer.GetWarehousePresentation(CurrentWarehouse));
		Else
			MessageText = StrReplace(MessageText,"%WarehousePresentation_%", WarehousesServer.GetWarehousePresentation(Object[WarehouseFieldName]));
		EndIf;
			
		MessageText = StrReplace(MessageText,"%Count%", QuantityNotAllocated);
		MessageText = StrReplace(MessageText,"%UnitOfMeasure%",UnitsOfMeasurement.Find(Page1.Products,"Products").UnitOfMeasure);
		If SeriesSpecificationParameters.ProductInHeader Then
			Field = "Products";
		Else
			Field = CommonClientServer.PathToTabularSection(SeriesSpecificationParameters.NameTSGoods, Page1.LineNumber, "Products");
		EndIf;
		CommonClientServer.MessageToUser(MessageText,,Field,"Object");
		
	EndDo;

EndProcedure

Procedure FillSeriesOnFefoTWhProducts(Object, SeriesSpecificationParameters)
    
	If Not (
			SeriesSpecificationParameters.FullObjectName = "Document.GoodsIssueNote"
			Or SeriesSpecificationParameters.FullObjectName = "Document.GoodsTransferNote"
			Or SeriesSpecificationParameters.FullObjectName = "Document.ProductionStage2_2"
			Or SeriesSpecificationParameters.FullObjectName = "DataProcessor.EditProductionStageSequence"
			)Then
		ExceptionText = NStr("vi = 'Lỗi điền sê-ri theo FEFO. Thủ tục điền không hỗ trợ chứng từ này.';
							|ru = 'Ошибка заполнения серий по FEFO. Процедура заполнения не поддерживает данный документ.';
							|en = 'An error occurred while populating FEFO batch. Population procedure does not support this document.'; fa = 'An error occurred while populating FEFO batch. Population procedure does not support this document.';
							|it = 'Errore di riempimento della serie di  FEFO. La procedura di riempimento non supporta questo documento.';
							|pl = 'Błąd wypełnienia serii wg FEFO. Procedura wypełnienia nie obsługuje dany dokument.';
							|tr = 'FEFO partisini doldururken hata oluştu. Doldurma prosedürü bu belgeyi desteklemiyor.'");
		Raise ExceptionText;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("TableOfGoods", Object[SeriesSpecificationParameters.NameTSGoods].Unload());
	ItSWarrant = SeriesSpecificationParameters.ItSWarrant;
	
	If ItSWarrant Then
		If SeriesSpecificationParameters.FieldNameRoom <> Undefined Then
			Premise = Object[SeriesSpecificationParameters.FieldNameRoom];
		Else
			Premise = Catalogs.Warerooms.EmptyRef();
		EndIf;
		
		Query.SetParameter("Premise", Premise);
		Query.SetParameter("Ref", Object.Ref);
		
		Data = DataForFillingFefoSeriesInOrder(Object, SeriesSpecificationParameters, Query);
	Else
		Data = DataForFillingFefoSeriesInStage(Object, SeriesSpecificationParameters, Query);
	EndIf;
	FetchingLineNumbers = Data.FetchingLineNumbers;
	MapBalance = Data.MapBalance;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	If SeriesSpecificationParameters.FullObjectName = "Document.GoodsIssueNote"
		And TypeOf(Object) = Type("FormDataStructure") Then
		
		StructureOfRecalculationOfNumberOfPackages = New Structure("RecalculateNumberOfPackages, RecalculateWeightVolume");
		
	Else
		StructureOfRecalculationOfNumberOfPackages = New Structure("RecalculateNumberOfPackages");
	EndIf;
	
	LineNumber = 0;
	RowsToProcess = New Array;
	
	While FetchingLineNumbers.Next() Do
		
		RowOfGoods = Object[SeriesSpecificationParameters.NameTSGoods][FetchingLineNumbers.LineNumber + LineNumber - 1];
		
		ProductBalance_ = RowOfGoods.Count;
		
		VariableString = RowOfGoods; // LineOfATabularSection
		If ItSWarrant Then
			If SeriesSpecificationParameters.FieldNameControlledLotReference = Undefined Then
				ControlledLotReference = "VALUE(Catalog.ControlledLots.EmptyRef)";
			ElsIf StrFind(SeriesSpecificationParameters.FieldNameControlledLotReference, ".") > 0 Then
				ControlledLotReference = RowOfGoods[StrReplace(SeriesSpecificationParameters.FieldNameControlledLotReference, ".", "")];
			Else
				ControlledLotReference = Object[SeriesSpecificationParameters.FieldNameControlledLotReference];
			EndIf;
			
			SeriesBalancesByProduct = ProductSeriesBalancesOrders(RowOfGoods, MapBalance, ControlledLotReference);
		Else
			SeriesBalancesByProduct = RestOfSeriesOnGoods(RowOfGoods, MapBalance, FetchingLineNumbers.Purpose);
		EndIf;
		If SeriesBalancesByProduct = Undefined Then
			Continue;
		EndIf;
		
		For Each StructureBalance In SeriesBalancesByProduct Do
			If StructureBalance.AvailableStock = 0 Then
				Continue;
			EndIf;
			QuantityToString = Min(ProductBalance_, StructureBalance.AvailableStock);
			
			VariableString.Count = QuantityToString;
			VariableString.Series = StructureBalance.Series;
			
			RowsToProcess.Add(VariableString);
			
			ProductBalance_ = ProductBalance_ - VariableString.Count;
			StructureBalance.AvailableStock = StructureBalance.AvailableStock - VariableString.Count;
			
			If ProductBalance_ > 0 Then
				LineNumber = LineNumber + 1;
				VariableString = Object[SeriesSpecificationParameters.NameTSGoods].Insert(VariableString.LineNumber);
				
				PropertiesToExclude = "Count,NumberOfPackages,Series";
				If SeriesSpecificationParameters.FullObjectName = "Document.ProductionStage2_2"
					Or SeriesSpecificationParameters.FullObjectName = "DataProcessor.EditProductionStageSequence" Then
					PropertiesToExclude = PropertiesToExclude + ",KeyProducts";
				EndIf;
				FillPropertyValues(VariableString, RowOfGoods,,PropertiesToExclude);
				VariableString.Count = ProductBalance_;
				RowsToProcess.Add(VariableString);
			Else
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfRecalculationOfNumberOfPackages,
		Object[SeriesSpecificationParameters.NameTSGoods],
		CachedValues);

	FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	Query = New Query;
	If ItSWarrant Then
		Query.Text = RequestTextCheckingSeriesFillingByFefoInOrder(Object, SeriesSpecificationParameters);
		Query.SetParameter("Warehouse", Object[SeriesSpecificationParameters.WarehouseFieldName]);
	Else
		Query.Text = RequestTextCheckingSeriesFillingByFefoInStep(Object, SeriesSpecificationParameters);
	EndIf;
	Query.SetParameter("TableOfGoods", Object[SeriesSpecificationParameters.NameTSGoods].Unload());
	
	SelectionBlank = Query.Execute().Select();
	
	While SelectionBlank.Next() Do
		
		QuantityNotAllocated = 0;
		If SelectionBlank.ItIsACargoItem Then
			
			MessageText = NStr("vi = 'Trong dòng %LineNumber% đối với hàng hóa ""%GoodsPresentation%"", chưa điền sê-ri, bởi vì chưa chỉ ra đóng gói - nơi hàng hóa. Không hỗ trợ điền sê-ri FEFO theo nơi hàng hóa.';
								|ru = 'В строке %LineNumber% для товара ""%GoodsPresentation%"" серии не заполнены, т.к. указана упаковка - товарное место. Заполнение серий FEFO по товарным местам не поддерживается.';
								|en = 'Batches are not filled in for the ""%GoodsPresentation%"" goods item in line %LineNumber%. Cargo item is specified as packaging unit. Cannot fill in FEFO batch according to the cargo items.'; fa = 'Batches are not filled in for the ""%GoodsPresentation%"" goods item in line %LineNumber%. Cargo item is specified as packaging unit. Cannot fill in FEFO batch according to the cargo items.';
								|it = 'La riga %LineNumber% per l''articolo ""%GoodsPresentation%"" della serie non è piena, perché l''imballaggio è un luogo di vendita. Riempimento serie FEFO il marchio di luoghi non è supportato.';
								|pl = 'W wierszu %LineNumber% dla towaru ""%GoodsPresentation%"" serie nie są wypełnione, ponieważ jest wskazane opakowanie - miejsce towarowe. Wypełnienie serii FEFO wg miejsc towarowych nie jest obsługiwane.';
								|tr = '""%GoodsPresentation%"" ürünü için %LineNumber% satırındaki partiler doldurulmadı, çünkü paketleme ünitesi belirtilir - kargo paketi. FEFO partisinin kargo paketi bazında doldurulması desteklenmiyor.'");
			
		ElsIf SelectionBlank.Count = 0 Then
			
			MessageText = NStr("vi = 'Trong dòng %LineNumber% cho hàng hóa ""%GoodsPresentation%"" chưa điền sê-ri, chưa chỉ ra số lượng.';
								|ru = 'В строке %LineNumber% для товара ""%GoodsPresentation%"" серии не заполнены, т.к. не указано количество товаров.';
								|en = 'Batches are not filled in for the ""%GoodsPresentation%"" goods items in line %LineNumber%. Goods quantity is not specified.'; fa = 'Batches are not filled in for the ""%GoodsPresentation%"" goods items in line %LineNumber%. Goods quantity is not specified.';
								|it = 'La riga %LineNumber% per l''articolo ""%GoodsPresentation%"" della serie non è completa, perché non è specificato il numero di articoli.';
								|pl = 'W wierszu %LineNumber% dla towaru ""%GoodsPresentation%"" serie nie są wypełnione, ponieważ nie jest wskazana ilość towarów.';
								|tr = '""%GoodsPresentation%"" ürünü için %LineNumber% satırındaki partiler doldurulmadı, çünkü ürün sayısı belirtilmedi.'");
			
		Else
			
			MessageText = NStr("vi = 'Trong dòng %LineNumber% cho hàng hóa ""%GoodsPresentation%"" chưa điền sê-ri. Trong kho ""%WarehousePresentation_%"" không đủ ""%Count%"" ""%UnitOfMeasure%""';
								|ru = 'В строке %LineNumber% для товара ""%GoodsPresentation%"" серии не заполнены. На складе ""%WarehousePresentation_%"" не хватает ""%Count%"" ""%UnitOfMeasure%""';
								|en = 'Batches are not filled in for the ""%GoodsPresentation%"" goods item in line %LineNumber%. The ""%Count%"" ""%UnitOfMeasure%"" is missing in the ""%WarehousePresentation_%"" warehouse'; fa = 'Batches are not filled in for the ""%GoodsPresentation%"" goods item in line %LineNumber%. The ""%Count%"" ""%UnitOfMeasure%"" is missing in the ""%WarehousePresentation_%"" warehouse';
								|it = 'Nella riga %LineNumber% per merce ""%GoodsPresentation%"" le serie non sono piene. In magazzino ""%WarehousePresentation_%"" mancare ""%Count%"" ""%UnitOfMeasure%""';
								|pl = 'W wierszu %LineNumber% dla towaru ""%GoodsPresentation%"" serie nie są wypełnione. W magazynie ""%WarehousePresentation_%"" brakuje ""%Count%"" ""%UnitOfMeasure%""';
								|tr = 'Ürün için %LineNumber% satırında ""%GoodsPresentation%"" partisi doldurulmamıştır. ""%WarehousePresentation_%"" ambarında ""%Count%"" ""%UnitOfMeasure%"" yeterli değil'");
			QuantityNotAllocated = SelectionBlank.Count;
			
		EndIf;	
		
		MessageText = StrReplace(MessageText,"%LineNumber%", SelectionBlank.LineNumber);
		MessageText = StrReplace(MessageText,"%GoodsPresentation%", ProductsClientServer.ProductPresentation(SelectionBlank.Products, SelectionBlank.Characteristic));
		MessageText = StrReplace(MessageText,"%WarehousePresentation_%", WarehousesServer.GetWarehousePresentation(SelectionBlank.Warehouse,Premise));
		MessageText = StrReplace(MessageText,"%Count%", QuantityNotAllocated);
		MessageText = StrReplace(MessageText,"%UnitOfMeasure%",SelectionBlank.UnitOfMeasure);
		Field = CommonClientServer.PathToTabularSection(SeriesSpecificationParameters.NameTSGoods, SelectionBlank.LineNumber, "Series");
		CommonClientServer.MessageToUser(MessageText,,Field,"Object");
		
	EndDo;
	
EndProcedure

Function DataForFillingFefoSeriesInOrder(Object, SeriesSpecificationParameters, Query)
	
	QueryText =
	"SELECT
	|	DocumentData.LineNumber,
	|	CAST(DocumentData.Products AS Catalog.Products) AS Products,
	|	DocumentData.Characteristic AS Characteristic,
	|	DocumentData.Purpose AS Purpose,
	|	&ControlledLotReferenceOverridable AS ControlledLotReference,
	|	CAST(DocumentData.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS DocumentData
	|WHERE
	|	DocumentData.BatchesIndicationStatus IN (5, 6)
	|	AND (DocumentData.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
	|			OR &ConditionIfNoStatusesAreUsed)
	|	AND DocumentData.Count > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DocumentData.Products,
	|	DocumentData.Characteristic,
	|	DocumentData.Purpose,
	|	DocumentData.ControlledLotReference
	|INTO TableOfProductsToRequest
	|FROM
	|	TableOfGoods AS DocumentData
	|WHERE
	|	ISNULL(Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.LineNumber
	|FROM
	|	TableOfGoods AS DocumentData
	|WHERE
	|	ISNULL(Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsItemSeries.Products AS Products,
	|	ProductsItemSeries.Characteristic AS Characteristic,
	|	ProductsItemSeries.Purpose AS Purpose,
	|	ProductsItemSeries.ControlledLotReference AS ControlledLotReference,
	|	ProductsItemSeries.Series AS Series,
	|	SUM(ProductsItemSeries.AvailableStock) AS AvailableStock,
	|	ProductsItemSeries.Series.ValidUntil_ AS ValidUntil_,
	|	ProductsItemSeries.Series.Number AS Number
	|FROM
	|	(SELECT
	|		ProductStockBalance.Products AS Products,
	|		ProductStockBalance.Characteristic AS Characteristic,
	|		ProductStockBalance.Series AS Series,
	|		ProductStockBalance.Purpose AS Purpose,
	|		ProductStockBalance.ControlledLotReference AS ControlledLotReference,
	|		ProductStockBalance.InStockBalance - ProductStockBalance.ToShipBalance AS AvailableStock
	|	FROM
	|		AccumulationRegister.ProductStock.Balance(
	|				,
	|				(Products, Characteristic, Purpose, ControlledLotReference, Warehouse, Premise) IN
	|					(SELECT
	|						TableOfProductsToRequest.Products,
	|						TableOfProductsToRequest.Characteristic,
	|						TableOfProductsToRequest.Purpose,
	|						TableOfProductsToRequest.ControlledLotReference,
	|						&Warehouse,
	|						&Premise
	|					FROM
	|						TableOfProductsToRequest)) AS ProductStockBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductStock.Products,
	|		ProductStock.Characteristic,
	|		ProductStock.Series,
	|		ProductStock.Purpose,
	|		ProductStock.ControlledLotReference,
	|		CASE
	|			WHEN ProductStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -ProductStock.InStock + ProductStock.ToShip
	|			ELSE ProductStock.InStock - ProductStock.ToShip
	|		END
	|	FROM
	|		AccumulationRegister.ProductStock AS ProductStock
	|			INNER JOIN TableOfProductsToRequest AS TableOfGoods
	|			ON ProductStock.Products = TableOfGoods.Products
	|				AND ProductStock.Characteristic = TableOfGoods.Characteristic
	|				AND ProductStock.Purpose = TableOfGoods.Purpose
	|				AND ProductStock.ControlledLotReference = TableOfGoods.ControlledLotReference
	|				AND (ProductStock.Recorder = &Ref)) AS ProductsItemSeries
	|WHERE
	|	ProductsItemSeries.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|GROUP BY
	|	ProductsItemSeries.Products,
	|	ProductsItemSeries.Characteristic,
	|	ProductsItemSeries.Purpose,
	|	ProductsItemSeries.ControlledLotReference,
	|	ProductsItemSeries.Series,
	|	ProductsItemSeries.Series.ValidUntil_,
	|	ProductsItemSeries.Series.Number
	|
	|HAVING
	|	SUM(ProductsItemSeries.AvailableStock) > 0
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ControlledLotReference,
	|	ValidUntil_,
	|	Number,
	|	Series";
	
	ControlledLotReference = Undefined;
	If SeriesSpecificationParameters.FieldNameControlledLotReference = Undefined Then
		ControlledLotReference = "VALUE(Catalog.ControlledLots.EmptyRef)";
	ElsIf StrFind(SeriesSpecificationParameters.FieldNameControlledLotReference, ".") > 0 Then
		ControlledLotReference = "DocumentData." + StrReplace(SeriesSpecificationParameters.FieldNameControlledLotReference, ".", "");
	Else
		ControlledLotReference = "&ControlledLotReference";
		Query.SetParameter("ControlledLotReference", Object[SeriesSpecificationParameters.FieldNameControlledLotReference]);
	EndIf;
	QueryText = StrReplace(QueryText, "&ControlledLotReferenceOverridable", ControlledLotReference);
	
	UseGoodsIssueNoteStatuses = GetFunctionalOption("UseGoodsIssueNoteStatuses", New Structure("Warehouse", Object[SeriesSpecificationParameters.WarehouseFieldName]));
	
	If SeriesSpecificationParameters.FullObjectName = "Document.GoodsIssueNote"
		And Not UseGoodsIssueNoteStatuses Then
		
		ConditionIfNoStatusesAreUsed = 
		" (NOT DocumentData.ThisIsAPackingList
		| AND DocumentData.PackingListParent = VALUE(Document.PackingList.EmptyRef)
		| AND DocumentData.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip))";
		
		QueryText = StrReplace(QueryText, "&ConditionIfNoStatusesAreUsed", ConditionIfNoStatusesAreUsed);
	Else
		
		QueryText = StrReplace(QueryText, "&ConditionIfNoStatusesAreUsed", "FALSE");
		
	EndIf;
	
	Query.Text = QueryText;
	
	Query.SetParameter("Warehouse", Object[SeriesSpecificationParameters.WarehouseFieldName]);
	
	ResultsArray = Query.ExecuteBatch();
	
	QueryResult = ResultsArray[2]; // QueryResult
	
	FetchingLineNumbers = QueryResult.Select();
	
	MapBalance = New Map;
	
	QueryResult = ResultsArray[3]; // QueryResult
	SelectionBalance = QueryResult.Select();
	
	While SelectionBalance.NextByFieldValue("Products") Do
		MapBalance.Insert(SelectionBalance.Products, New Map);
		MatchingProducts = MapBalance[SelectionBalance.Products];
		While SelectionBalance.NextByFieldValue("Characteristic") Do
			MatchingProducts.Insert(SelectionBalance.Characteristic, New Map);
			ComplianceCharacteristic = MatchingProducts[SelectionBalance.Characteristic];
			While SelectionBalance.NextByFieldValue("Purpose") Do
				ComplianceCharacteristic.Insert(SelectionBalance.Purpose, New Map);
				MatchingPurpose = ComplianceCharacteristic[SelectionBalance.Purpose];
				While SelectionBalance.NextByFieldValue("ControlledLotReference") Do
					MatchingPurpose.Insert(SelectionBalance.ControlledLotReference, New Array);
					ArrayBalance = MatchingPurpose[SelectionBalance.ControlledLotReference]; // Array
					While SelectionBalance.Next() Do
						StructureBalance = New Structure("Series,AvailableStock");
						FillPropertyValues(StructureBalance,SelectionBalance);
						ArrayBalance.Add(StructureBalance);
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
	Return New Structure("FetchingLineNumbers, MapBalance", FetchingLineNumbers, MapBalance);
	
EndFunction

Function ProductSeriesBalancesOrders(RowOfGoods, MapBalance, ControlledLotReference)
	
	If MapBalance[RowOfGoods.Products] = Undefined			
		Or MapBalance[RowOfGoods.Products][RowOfGoods.Characteristic] = Undefined
		Or MapBalance[RowOfGoods.Products][RowOfGoods.Characteristic][RowOfGoods.Purpose] = Undefined
		Or MapBalance[RowOfGoods.Products][RowOfGoods.Characteristic][RowOfGoods.Purpose][ControlledLotReference] = Undefined Then
		
		Balance = Undefined;
		
	Else
		
		Balance = MapBalance[RowOfGoods.Products][RowOfGoods.Characteristic][RowOfGoods.Purpose][ControlledLotReference];
		
	EndIf;
	
	Return Balance;
	
EndFunction

Function RequestTextCheckingSeriesFillingByFefoInOrder(Object, SeriesSpecificationParameters)
	
	QueryText =
	"SELECT
	|	DocumentData.LineNumber AS LineNumber,
	|	DocumentData.Products AS Products,
	|	DocumentData.Characteristic AS Characteristic,
	|	DocumentData.Count AS Count,
	|	DocumentData.Package AS Package
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS DocumentData
	|WHERE
	|	DocumentData.BatchesIndicationStatus = 5
	|	AND (DocumentData.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Pick)
	|			OR &ConditionIfNoStatusesAreUsed)
	|;
	|///////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	&Warehouse AS Warehouse,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Count AS Count,
	|	PRESENTATION(CAST(TableOfGoods.Products AS Catalog.Products).UnitOfMeasure) AS UnitOfMeasure,
	|	CASE WHEN CAST(TableOfGoods.Package AS Catalog.PackagesAndUnitsOfMeasure).PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|		THEN TRUE
	|	ELSE FALSE END AS ItIsACargoItem
	|FROM
	|	TableOfGoods AS TableOfGoods";
	
	UseGoodsIssueNoteStatuses = GetFunctionalOption("UseGoodsIssueNoteStatuses", New Structure("Warehouse", Object[SeriesSpecificationParameters.WarehouseFieldName]));
	
	If SeriesSpecificationParameters.FullObjectName = "Document.GoodsIssueNote"
		And Not UseGoodsIssueNoteStatuses Then
		
		ConditionIfNoStatusesAreUsed = 
		" (NOT DocumentData.ThisIsAPackingList
		| AND DocumentData.PackingListParent = VALUE(Document.PackingList.EmptyRef)
		| AND DocumentData.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip))";
		
		QueryText = StrReplace(QueryText, "&ConditionIfNoStatusesAreUsed", ConditionIfNoStatusesAreUsed);
	Else
		
		QueryText = StrReplace(QueryText, "&ConditionIfNoStatusesAreUsed", "FALSE");
		
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestTextForFillingInSeriesfefo(SeriesSpecificationParameters)
	
	QueryTexts = New Array;
	
	QueryText =
	"SELECT
	|	DocumentData.LineNumber AS LineNumber,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.Products AS Products,
	|	DocumentData.Characteristic AS Characteristic,
	|	DocumentData.Purpose AS Purpose,
	|	&ControlledLotReferenceOverridable AS ControlledLotReferenceForRequest,
	|	DocumentData.LinkFields,
	|	DocumentData.Count AS Count
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS DocumentData
	|WHERE
	|	DocumentData.BatchesIndicationStatus IN (5, 6)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Products AS Products,
	|	DocumentData.Characteristic AS Characteristic,
	|	DocumentData.Series AS Series,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.LinkFields,
	|	DocumentData.Count AS Count
	|INTO TableOfSeries
	|FROM
	|	&TableOfSeries AS DocumentData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfProductsToRequest.Warehouse AS Warehouse,
	|	TableOfProductsToRequest.Products AS Products,
	|	TableOfProductsToRequest.Characteristic AS Characteristic,
	|	TableOfProductsToRequest.Purpose AS Purpose,
	|	TableOfProductsToRequest.ControlledLotReferenceForRequest AS ControlledLotReference,
	|	SUM(TableOfProductsToRequest.Count) AS Count
	|INTO TableOfProductsToRequest
	|FROM
	|	TableOfGoods AS TableOfProductsToRequest
	|WHERE
	|	TableOfProductsToRequest.Count > 0
	|
	|GROUP BY
	|	TableOfProductsToRequest.Warehouse,
	|	TableOfProductsToRequest.Products,
	|	TableOfProductsToRequest.Characteristic,
	|	TableOfProductsToRequest.Purpose,
	|	TableOfProductsToRequest.ControlledLotReferenceForRequest";
	
	QueryTexts.Add(QueryText);
	
	QueryText =
	"SELECT
	|	ProductsItemSeries.Products AS Products,
	|	ProductsItemSeries.Characteristic AS Characteristic,
	|	ProductsItemSeries.Purpose,
	|	ProductsItemSeries.ControlledLotReference,
	|	ProductsItemSeries.Warehouse,
	|	ProductsItemSeries.Series,
	|	SUM(ProductsItemSeries.AvailableStock) AS AvailableStock,
	|	ProductsItemSeries.Series.ValidUntil_ AS ValidUntil_,
	|	ProductsItemSeries.Series.Number AS Number
	|INTO TableOfBalancesBySeries
	|FROM
	|	(SELECT
	|		ProductStockBalance.Products AS Products,
	|		ProductStockBalance.Characteristic AS Characteristic,
	|		ProductStockBalance.Series AS Series,
	|		ProductStockBalance.Purpose AS Purpose,
	|		ProductStockBalance.ControlledLotReference AS ControlledLotReference,
	|		ProductStockBalance.Warehouse AS Warehouse,
	|		ProductStockBalance.InStockBalance - ProductStockBalance.ToShipBalance AS AvailableStock
	|	FROM
	|		AccumulationRegister.ProductStock.Balance(
	|				,
	|				(Products, Characteristic, Purpose, ControlledLotReference, Warehouse) IN
	|					(SELECT
	|						TableOfProductsToRequest.Products,
	|						TableOfProductsToRequest.Characteristic,
	|						TableOfProductsToRequest.Purpose,
	|						TableOfProductsToRequest.ControlledLotReference,
	|						TableOfProductsToRequest.Warehouse
	|					FROM
	|						TableOfProductsToRequest)) AS ProductStockBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductStock.Products,
	|		ProductStock.Characteristic,
	|		ProductStock.Series,
	|		ProductStock.Purpose,
	|		ProductStock.ControlledLotReference,
	|		ProductStock.Warehouse,
	|		CASE
	|			WHEN ProductStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -ProductStock.InStock + ProductStock.ToShip
	|			ELSE ProductStock.InStock - ProductStock.ToShip
	|		END
	|	FROM
	|		AccumulationRegister.ProductStock AS ProductStock
	|			INNER JOIN TableOfProductsToRequest AS TableOfProductsToRequest
	|			ON ProductStock.Products = TableOfProductsToRequest.Products
	|				AND ProductStock.Characteristic = TableOfProductsToRequest.Characteristic
	|				AND ProductStock.Purpose = TableOfProductsToRequest.Purpose
	|				AND ProductStock.ControlledLotReference = TableOfProductsToRequest.ControlledLotReference
	|				AND ProductStock.Warehouse = TableOfProductsToRequest.Warehouse
	|				AND (ProductStock.Recorder = &Ref)
	|	) AS ProductsItemSeries
	|WHERE
	|	ProductsItemSeries.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|GROUP BY
	|	ProductsItemSeries.Products,
	|	ProductsItemSeries.Characteristic,
	|	ProductsItemSeries.Purpose,
	|	ProductsItemSeries.ControlledLotReference,
	|	ProductsItemSeries.Warehouse,
	|	ProductsItemSeries.Series,
	|	ProductsItemSeries.Series.ValidUntil_,
	|	ProductsItemSeries.Series.Number
	|
	|HAVING
	|	SUM(ProductsItemSeries.AvailableStock) > 0";
	If SeriesSpecificationParameters.WarehouseFieldName = "Department"
		Or SeriesSpecificationParameters.WarehouseFieldName = "ReceivingBusinessUnit"
		Or SeriesSpecificationParameters.WarehouseFieldName = "SendingDepartment" Then
		
		QueryText =
		"SELECT
		|	ProductsItemSeries.Products AS Products,
		|	ProductsItemSeries.Characteristic AS Characteristic,
		|	ProductsItemSeries.Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	ProductsItemSeries.Warehouse,
		|	ProductsItemSeries.Series,
		|	SUM(ProductsItemSeries.AvailableStock) AS AvailableStock,
		|	ProductsItemSeries.Series.ValidUntil_ AS ValidUntil_,
		|	ProductsItemSeries.Series.Number AS Number
		|INTO TableOfBalancesBySeries
		|FROM
		|	(SELECT
		|		MaterialsInProductionBalance.Products AS Products,
		|		MaterialsInProductionBalance.Characteristic AS Characteristic,
		|		MaterialsInProductionBalance.Series AS Series,
		|		MaterialsInProductionBalance.Purpose AS Purpose,
		|		MaterialsInProductionBalance.Department AS Warehouse,
		|		MaterialsInProductionBalance.CountBalance AS AvailableStock
		|	FROM
		|		AccumulationRegister.MaterialsAndWorksInProduction.Balance(
		|				,
		|				(Products, Characteristic, Purpose, Department) IN
		|					(SELECT
		|						TableOfProductsToRequest.Products,
		|						TableOfProductsToRequest.Characteristic,
		|						TableOfProductsToRequest.Purpose,
		|						TableOfProductsToRequest.Warehouse
		|					FROM
		|						TableOfProductsToRequest)) AS MaterialsInProductionBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|	MaterialsAndWorksInProduction.Products,
		|	MaterialsAndWorksInProduction.Characteristic,
		|	MaterialsAndWorksInProduction.Series,
		|	MaterialsAndWorksInProduction.Purpose,
		|	MaterialsAndWorksInProduction.Department,
		|	-MaterialsAndWorksInProduction.Count
		|	FROM
		|	AccumulationRegister.MaterialsAndWorksInProduction AS MaterialsAndWorksInProduction
		|			INNER JOIN TableOfProductsToRequest AS TableOfProductsToRequest
		|		ON MaterialsAndWorksInProduction.Products = TableOfProductsToRequest.Products
		|			AND MaterialsAndWorksInProduction.Characteristic = TableOfProductsToRequest.Characteristic
		|			AND MaterialsAndWorksInProduction.Purpose = TableOfProductsToRequest.Purpose
		|			AND MaterialsAndWorksInProduction.Department = TableOfProductsToRequest.Warehouse
		|			AND (MaterialsAndWorksInProduction.Recorder = &Ref)
		|) AS ProductsItemSeries
		|WHERE
		|	ProductsItemSeries.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|
		|GROUP BY
		|	ProductsItemSeries.Products,
		|	ProductsItemSeries.Characteristic,
		|	ProductsItemSeries.Purpose,
		|	ProductsItemSeries.Warehouse,
		|	ProductsItemSeries.Series,
		|	ProductsItemSeries.Series.ValidUntil_,
		|	ProductsItemSeries.Series.Number
		|
		|HAVING
		|	SUM(ProductsItemSeries.AvailableStock) > 0";
		
	EndIf;
	QueryTexts.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	DocumentData.Products,
	|	DocumentData.Characteristic,
	|	DocumentData.Warehouse,
	|	DocumentData.LineNumber,
	|	TableOfBalancesBySeries.Series AS Series,
	|	ISNULL(TableOfBalancesBySeries.AvailableStock, 0) AS AvailableStock
	|FROM
	|	TableOfBalancesBySeries AS TableOfBalancesBySeries
	|		INNER JOIN TableOfGoods AS DocumentData
	|		ON (DocumentData.Products = TableOfBalancesBySeries.Products)
	|			AND (DocumentData.Characteristic = TableOfBalancesBySeries.Characteristic)
	|			AND (DocumentData.Purpose = TableOfBalancesBySeries.Purpose)
	|			AND (DocumentData.ControlledLotReferenceForRequest = TableOfBalancesBySeries.ControlledLotReference)
	|			AND (DocumentData.Warehouse = TableOfBalancesBySeries.Warehouse)
	|
	|ORDER BY
	|	DocumentData.Products,
	|	DocumentData.Characteristic,
	|	DocumentData.Warehouse,
	|	TableOfBalancesBySeries.ValidUntil_,
	|	TableOfBalancesBySeries.Number,
	|	TableOfBalancesBySeries.Series,
	|	DocumentData.LinkFields,
	|	DocumentData.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.LinkFields,
	|	DocumentData.Products,
	|	DocumentData.Characteristic,
	|	DocumentData.Series,
	|	DocumentData.Count
	|FROM
	|	TableOfSeries AS DocumentData
	|WHERE
	|	NOT (DocumentData.Products, DocumentData.Warehouse) IN
	|				(SELECT
	|					TableOfGoods.Products,
	|					TableOfGoods.Warehouse
	|				FROM
	|					TableOfGoods)";
	
	QueryTexts.Add(QueryText);
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

// Parameters:
// 	GoodsTable - ValueTable - 
// 	DocumentObject - DocumentObject - 
// 	FillInNegativeBalances - Boolean - 
// 
// Returns:
//  Structure - Fill Out A Series Based On Product Data From Partners:
// * GoodsTable - ValueTable -
// * HasChanges - Boolean -
// * NumberIsInitiallyCorrect - Boolean -
Function FillOutSeriesBasedOnProductDataFromPartners(GoodsTable, DocumentObject, FillInNegativeBalances) Export
	
	Query = New Query();
	QueryText = 
	"SELECT
	|	DocumentTable.Products   AS Products,
	|	DocumentTable.Characteristic AS Characteristic,
	|	DocumentTable.Purpose     AS Purpose,
	|	&ReferenceOrder                   AS DocumentInflow,
	|	DocumentTable.Warehouse          AS Warehouse
	|INTO TTLoadedTable
	|FROM
	|	&GoodsTable AS DocumentTable
	|WHERE
	|	DocumentTable.BatchesIndicationStatus <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.DocumentInflow AS DocumentInflow,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.Characteristic AS Characteristic,
	|	DocumentTable.Purpose AS Purpose,
	|	DocumentTable.Warehouse AS Warehouse
	|INTO TTDocumentTable
	|FROM
	|	TTLoadedTable AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	&Terms AS DocumentInflow,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.Characteristic AS Characteristic,
	|	DocumentTable.Purpose AS Purpose,
	|	DocumentTable.Warehouse AS Warehouse
	|FROM
	|	TTLoadedTable AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	&Contract AS DocumentInflow,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.Characteristic AS Characteristic,
	|	DocumentTable.Purpose AS Purpose,
	|	DocumentTable.Warehouse AS Warehouse
	|FROM
	|	TTLoadedTable AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref AS DocumentInflow,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.Characteristic AS Characteristic,
	|	DocumentTable.Purpose AS Purpose,
	|	DocumentTable.Warehouse AS Warehouse
	|FROM
	|	TTLoadedTable AS DocumentTable
	|
	|INDEX BY
	|	DocumentInflow,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	BalanceTable.Warehouse                                     AS Warehouse,
	|	BalanceTable.Products                              AS Products,
	|	BalanceTable.Characteristic                            AS Characteristic,
	|	BalanceTable.Series                                     AS Series,
	|	BalanceTable.Purpose                                AS Purpose,
	|	BalanceTable.DocumentInflow                       AS PurchaseOrder,
	|	SUM(BalanceTable.QuantityAccordingToPartnerData)         AS QuantityAccordingToPartnerData
	|FROM
	|	(SELECT
	|		GoodsToReceiveBalance.DocumentInflow AS DocumentInflow,
	|		GoodsToReceiveBalance.Warehouse AS Warehouse,
	|		GoodsToReceiveBalance.Products AS Products,
	|		GoodsToReceiveBalance.Characteristic AS Characteristic,
	|		GoodsToReceiveBalance.Purpose AS Purpose,
	|		GoodsToReceiveBalance.Series AS Series,
	|		&ZoomRatio * GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance AS QuantityAccordingToPartnerData
	|	FROM
	|		AccumulationRegister.GoodsToReceive.Balance(
	|				,
	|				(DocumentInflow, Products, Characteristic, Purpose, Warehouse) IN
	|					(SELECT
	|						DocumentTable.DocumentInflow AS DocumentInflow,
	|						DocumentTable.Products AS Products,
	|						DocumentTable.Characteristic AS Characteristic,
	|						DocumentTable.Purpose AS Purpose,
	|						DocumentTable.Warehouse AS Warehouse
	|					FROM
	|						TTDocumentTable AS DocumentTable)) AS GoodsToReceiveBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsToReceive.DocumentInflow,
	|		GoodsToReceive.Warehouse,
	|		GoodsToReceive.Products,
	|		GoodsToReceive.Characteristic,
	|		GoodsToReceive.Purpose,
	|		GoodsToReceive.Series,
	|		-&ZoomRatio * GoodsToReceive.ToRegisterReceiptsByInvoices
	|	FROM
	|		AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|	WHERE
	|		GoodsToReceive.Recorder = &Ref
	|		AND GoodsToReceive.Active) AS BalanceTable
	|
	|GROUP BY
	|	BalanceTable.DocumentInflow,
	|	BalanceTable.Warehouse,
	|	BalanceTable.Products,
	|	BalanceTable.Characteristic,
	|	BalanceTable.Purpose,
	|	BalanceTable.Series
	|
	|HAVING
	|	SUM(BalanceTable.QuantityAccordingToPartnerData) > 0";
	
	ReferenceOrder = Undefined;
	ZoomRatio  = 1;
	
	If FillInNegativeBalances Then
		QueryText = StrReplace(QueryText, "&ReferenceOrder", "DocumentTable.PurchaseOrder");
		ZoomRatio = -1;
	Else
		ReferenceOrder = DocumentObject.ReferenceOrder;
		ReferenceOrder = ?(ReferenceOrder <> Undefined, ReferenceOrder, Catalogs.CounterpartyContracts.EmptyRef());
	EndIf;
	
	Query.Text = QueryText;
	
	OriginalTable = GoodsTable.Copy();
	GoodsTable.Columns.Add("QuantityAccordingToPartnerData", New TypeDescription("Number"));
	
	Query.SetParameter("GoodsTable", GoodsTable);
	Query.SetParameter("Contract",       DocumentObject.Contract);
	Query.SetParameter("Ref",        DocumentObject.Ref);
	Query.SetParameter("Terms",    DocumentObject.Terms);
	Query.SetParameter("ReferenceOrder",  ReferenceOrder);
	Query.SetParameter("ZoomRatio",   ZoomRatio);
	
	TableProductsFromPartners = Query.Execute().Unload();
	
	OrderOrder = False;
	For Each String In TableProductsFromPartners Do
		DocumentInflow = String.PurchaseOrder;
		OrderOrder   = (TypeOf(DocumentInflow) = Type("DocumentRef.PurchaseOrder"));
		OrderOrder   = OrderOrder 
							  Or TypeOf(DocumentInflow) = Type("DocumentRef.MaterialProviderOrder2_5");
		If Not OrderOrder Then
			Break;
		EndIf;
	EndDo;
	
	// The distribution of the received table to the goods table is performed. In this case, the row of the Products table can be
	// divided into several if it corresponds to several rows in the Partner Products table.
	
	Var_Key = "%1 Warehouse, Products, Characteristic, Purpose";
	
	If OrderOrder And FillInNegativeBalances Then
		KeyField = "PurchaseOrder,";
	Else
		KeyField = "";
	EndIf;
	
	Var_Key = StrTemplate(Var_Key, KeyField);
	GoodsTable.Indexes.Add(Var_Key);
	
	Condition = "On [Count]";
	InvoicesServer.DistributeQuantityAndFill(TableProductsFromPartners, GoodsTable, "QuantityAccordingToPartnerData", Var_Key, Condition, False, "Series");
	
	// Filling in the quantity according to the partner's data is processing a situation when there are fewer series according to the partner's data
	// than the quantity specified in the current document. The number for which there were not enough episodes must be saved "as is".
	RowsCount = GoodsTable.Count() - 1;
	For IndexOf = 0 To RowsCount Do
		String = GoodsTable[RowsCount - IndexOf];
		If String.Count > String.QuantityAccordingToPartnerData
			And String.QuantityAccordingToPartnerData > 0
			And ValueIsFilled(String.Series) Then
			// It is required to split the row if the series is full. Otherwise, we leave it as it is.
			
			NewRow = GoodsTable.Add();
			FillPropertyValues(NewRow, String);
			
			QuantityWithoutSeries = String.Count - String.QuantityAccordingToPartnerData;
			
			String.Count = String.QuantityAccordingToPartnerData;
			NewRow.Count = QuantityWithoutSeries;
			NewRow.Series = Catalogs.ItemsBatches.EmptyRef();
			
		ElsIf String.QuantityAccordingToPartnerData > 0 Then
			// The number does not differ, or less than according to the partner
			String.Count = String.QuantityAccordingToPartnerData;
		EndIf;
	EndDo;
	
	HasChanges = False;
	NumberIsInitiallyCorrect = False;
	
	If OriginalTable.Count() <> GoodsTable.Count() Then
		HasChanges = True;
	Else
		NumberIsInitiallyCorrect = True;
		For IndexOf = 0 To OriginalTable.Count() - 1 Do
			OriginalLine = OriginalTable[IndexOf];
			ChangedRow = GoodsTable[IndexOf];
			
			// Calculation of the attribute only for rows with series
			If ChangedRow.BatchesIndicationStatus > 0
				And ChangedRow.Count <> ChangedRow.QuantityAccordingToPartnerData Then
				NumberIsInitiallyCorrect = False;
			EndIf;
			
			If OriginalLine.Series <> ChangedRow.Series Then
				HasChanges = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("GoodsTable",              GoodsTable);
	ReturnStructure.Insert("HasChanges",              HasChanges);
	ReturnStructure.Insert("NumberIsInitiallyCorrect", NumberIsInitiallyCorrect);
	
	Return ReturnStructure;
	
EndFunction


Function DataForFillingFefoSeriesInStage(Object, SeriesSpecificationParameters, Query)

	QueryText =
	"SELECT
	|	DocumentData.LineNumber                                                AS LineNumber,
	|	&Ref                                                                    AS Ref,
	|	&Warehouse                                                                     AS Warehouse,
	|	CAST(DocumentData.Products AS Catalog.Products)         AS Products,
	|	DocumentData.Characteristic                                             AS Characteristic,
	|	CAST(DocumentData.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	DocumentData.WithAssignment                                                AS WithAssignment,
	|	CAST(DocumentData.Purpose AS Catalog.Assignments)             AS Purpose
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS DocumentData
	|WHERE
	|	DocumentData.BatchesIndicationStatus IN (5, 6)
	|	AND DocumentData.Count > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.LineNumber,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.Products AS Products,
	|	DocumentData.Characteristic AS Characteristic,
	|	CASE
	|		WHEN DocumentData.WithAssignment
	|				AND ISNULL(DocumentData.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN DocumentData.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	DocumentData.Package
	|INTO TableOfProductsToRequest
	|FROM
	|	TableOfGoods AS DocumentData
	|WHERE
	|	ISNULL(DocumentData.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|INDEX BY
	|	Warehouse,
	|	Products,
	|	Characteristic,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.LineNumber,
	|	DocumentData.Purpose
	|FROM
	|	TableOfProductsToRequest AS DocumentData
	|
	|ORDER BY
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsItemSeries.Warehouse AS Warehouse,
	|	ProductsItemSeries.Products AS Products,
	|	ProductsItemSeries.Characteristic AS Characteristic,
	|	ProductsItemSeries.Purpose AS Purpose,
	|	ProductsItemSeries.Series AS Series,
	|	SUM(ProductsItemSeries.AvailableStock) AS AvailableStock,
	|	ProductsItemSeries.Series.ValidUntil_ AS ValidUntil_,
	|	ProductsItemSeries.Series.Number AS Number
	|FROM
	|	(SELECT
	|		ProductStockBalance.Warehouse AS Warehouse,
	|		ProductStockBalance.Products AS Products,
	|		ProductStockBalance.Characteristic AS Characteristic,
	|		ProductStockBalance.Series AS Series,
	|		ProductStockBalance.Purpose AS Purpose,
	|		ProductStockBalance.InStockBalance - ProductStockBalance.ToShipBalance AS AvailableStock
	|	FROM
	|		AccumulationRegister.ProductStock.Balance(
	|				,
	|				(Warehouse, Products, Characteristic, Purpose, ControlledLotReference) IN
	|					(SELECT
	|						TableOfProductsToRequest.Warehouse,
	|						TableOfProductsToRequest.Products,
	|						TableOfProductsToRequest.Characteristic,
	|						TableOfProductsToRequest.Purpose,
	|						VALUE(Catalog.ControlledLots.EmptyRef)
	|						
	|					FROM
	|						TableOfProductsToRequest)) AS ProductStockBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductStock.Warehouse,
	|		ProductStock.Products,
	|		ProductStock.Characteristic,
	|		ProductStock.Series,
	|		ProductStock.Purpose,
	|		ProductStock.InStock
	|	FROM
	|		AccumulationRegister.ProductStock AS ProductStock
	|	WHERE
	|		(ProductStock.Recorder, ProductStock.Warehouse, ProductStock.Products, ProductStock.Characteristic, ProductStock.Purpose, ProductStock.ControlledLotReference) IN
	|				(SELECT
	|					TableOfProductsToRequest.Ref AS Recorder,
	|					TableOfProductsToRequest.Warehouse,
	|					TableOfProductsToRequest.Products,
	|					TableOfProductsToRequest.Characteristic,
	|					TableOfProductsToRequest.Purpose,
	|					VALUE(Catalog.ControlledLots.EmptyRef)
	|				FROM
	|					TableOfProductsToRequest)) AS ProductsItemSeries
	|WHERE
	|	ProductsItemSeries.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|GROUP BY
	|	ProductsItemSeries.Warehouse,
	|	ProductsItemSeries.Products,
	|	ProductsItemSeries.Characteristic,
	|	ProductsItemSeries.Purpose,
	|	ProductsItemSeries.Series,
	|	ProductsItemSeries.Series.ValidUntil_,
	|	ProductsItemSeries.Series.Number
	|
	|HAVING
	|	SUM(ProductsItemSeries.AvailableStock) > 0
	|
	|ORDER BY
	|	Warehouse,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ValidUntil_,
	|	Number,
	|	Series";
	
	QueryText = StrReplace(QueryText, "&Warehouse", "DocumentData." + SeriesSpecificationParameters.WarehouseFieldName);
	
	If SeriesSpecificationParameters.FullObjectName = "Document.ProductionStage2_2" Then
		Query.SetParameter("Ref", Object.Ref);
	ElsIf SeriesSpecificationParameters.FullObjectName = "DataProcessor.EditProductionStageSequence" Then
		QueryText = StrReplace(QueryText, "&Ref", "DocumentData.Ref");
	EndIf;
	
	Query.Text = QueryText;
	
	ResultsArray = Query.ExecuteBatch();
	
	QueryResult = ResultsArray[2]; // QueryResult
	FetchingLineNumbers = QueryResult.Select();
	
	MapBalance = New Map;
	QueryResult = ResultsArray[3]; // QueryResult
	SelectionBalance = QueryResult.Select();
	
	While SelectionBalance.NextByFieldValue("Warehouse") Do
		MapBalance.Insert(SelectionBalance.Warehouse, New Map);
		ComplianceWarehouse = MapBalance[SelectionBalance.Warehouse];
		While SelectionBalance.NextByFieldValue("Products") Do
			ComplianceWarehouse.Insert(SelectionBalance.Products, New Map);
			MatchingProducts = ComplianceWarehouse[SelectionBalance.Products];
			While SelectionBalance.NextByFieldValue("Characteristic") Do
				MatchingProducts.Insert(SelectionBalance.Characteristic, New Map);
				ComplianceCharacteristic = MatchingProducts[SelectionBalance.Characteristic];
				While SelectionBalance.NextByFieldValue("Purpose") Do
					ComplianceCharacteristic.Insert(SelectionBalance.Purpose, New Array);
					ArrayBalance = ComplianceCharacteristic[SelectionBalance.Purpose]; // Array
					While SelectionBalance.Next() Do
						StructureBalance = New Structure("Series,AvailableStock");
						FillPropertyValues(StructureBalance,SelectionBalance);
						ArrayBalance.Add(StructureBalance);
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
	Return New Structure("FetchingLineNumbers, MapBalance", FetchingLineNumbers, MapBalance);
	
EndFunction

Function RestOfSeriesOnGoods(RowOfGoods, MapBalance, Purpose)
	
	If MapBalance[RowOfGoods.Warehouse] = Undefined			
		Or MapBalance[RowOfGoods.Warehouse][RowOfGoods.Products] = Undefined
		Or MapBalance[RowOfGoods.Warehouse][RowOfGoods.Products][RowOfGoods.Characteristic] = Undefined
		Or MapBalance[RowOfGoods.Warehouse][RowOfGoods.Products][RowOfGoods.Characteristic][Purpose] = Undefined Then
		
		Balance = Undefined;
		
	Else
		
		Balance = MapBalance[RowOfGoods.Warehouse][RowOfGoods.Products][RowOfGoods.Characteristic][Purpose];
		
	EndIf;
	
	Return Balance;
	
EndFunction

Function RequestTextCheckingSeriesFillingByFefoInStep(Object, SeriesSpecificationParameters)
	
	QueryText =
	"SELECT
	|	DocumentData.LineNumber AS LineNumber,
	|	&Warehouse AS Warehouse,
	|	DocumentData.Products AS Products,
	|	DocumentData.Characteristic AS Characteristic,
	|	DocumentData.Count AS Count,
	|	DocumentData.Package AS Package
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS DocumentData
	|WHERE
	|	DocumentData.BatchesIndicationStatus = 5
	|;
	|///////////////////////////////////////////////////
	|SELECT 
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Count AS Count,
	|	PRESENTATION(CAST(TableOfGoods.Products AS Catalog.Products).UnitOfMeasure) AS UnitOfMeasure,
	|	CASE WHEN CAST(TableOfGoods.Package AS Catalog.PackagesAndUnitsOfMeasure).PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|		THEN TRUE
	|	ELSE FALSE END AS ItIsACargoItem
	|FROM
	|	TableOfGoods AS TableOfGoods";
	
	QueryText = StrReplace(QueryText, "&Warehouse", "DocumentData." + SeriesSpecificationParameters.WarehouseFieldName);
	
	Return QueryText;
	
EndFunction

// Adds columns to the table.
//
// Parameters:
//	TableOfGoods - ValueTable - Table of products.
//	AttributeName - String, Array of String - the name of the column to be added to the table.
//	AttributeType - TypeDescription - description of the type of column to be added.
//
Procedure AddColumnToProductTable(TableOfGoods, AttributeName, AttributeType)
	
	If TypeOf(AttributeName) = Type("Array") Then
		For Each Name In AttributeName Do
			TableOfGoods.Columns.Add(Name, AttributeType);
		EndDo;
	Else
		TableOfGoods.Columns.Add(AttributeName, AttributeType);
	EndIf;
	
EndProcedure

// Creates a table of products for calculating the Status of the indication series.
//
// Parameters:
//	SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters.
//
// Returns:
//	ValueTable - Goods table, which contains the following columns:
//		* LineNumber - Number - row number of the table.
//		* Products - CatalogRef.Products - The goods for which the series indication Status is calculated.
//		* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of goods.
//		* Series - CatalogRef.ItemsBatches - product series.
//
Function TableOfGoodsForCalculatingStatusOfSpecifyingBatches(SeriesSpecificationParameters)
	
	ObjectMetadata	= TMCommonUse.ObjectMetadataByFullName(SeriesSpecificationParameters.FullObjectName);
	TypeLineNumber		= New TypeDescription("Number", New NumberQualifiers(5, 0, AllowedSign.Nonnegative));
	TypeProducts		= New TypeDescription("CatalogRef.Products");
	TypeCharacteristic	= New TypeDescription("CatalogRef.ItemsCharacteristics");
	TypeSeries			= New TypeDescription("CatalogRef.ItemsBatches");
	TypeQuantity		= New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	
	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("LineNumber", TypeLineNumber);
	TableOfGoods.Columns.Add("Products", TypeProducts);
	TableOfGoods.Columns.Add("Characteristic", TypeCharacteristic);
	TableOfGoods.Columns.Add("Series", TypeSeries);
	TableOfGoods.Columns.Add(SeriesSpecificationParameters.FieldNameQuantity, TypeQuantity);
	
	If SeriesSpecificationParameters.FieldNamesWithSuffix.Count() Then
		FieldNamesWithSuffix = SeriesSpecificationParameters.FieldNamesWithSuffix;
		
		If FieldNamesWithSuffix.Property("Products") Then
			AttributeName = FieldNamesWithSuffix.Products;
			
			AddColumnToProductTable(TableOfGoods, AttributeName, TypeProducts);
		EndIf;
		
		If FieldNamesWithSuffix.Property("Characteristic") Then
			AttributeName = FieldNamesWithSuffix.Characteristic;
			
			AddColumnToProductTable(TableOfGoods, AttributeName, TypeCharacteristic);
		EndIf;
		
		If FieldNamesWithSuffix.Property("Series") Then
			AttributeName = FieldNamesWithSuffix.Series;
			
			AddColumnToProductTable(TableOfGoods, AttributeName, TypeSeries);
		EndIf;
	EndIf;
	
	CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, TableOfGoods, ObjectMetadata);
	
	Return TableOfGoods;
	
EndFunction

// Creates a series table for calculating the Statuses of specifying a series.
//
// Parameters:
//	SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters.
//
// Returns:
//	ValueTable - Goods table, which contains the following columns:
//		* Products - CatalogRef.Products - The goods for which the series indication Status is calculated.
//		* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of goods.
//
Function BatchTableForCalculatingStatusesOfSpecifyingBatches(SeriesSpecificationParameters)
	
	ObjectMetadata = TMCommonUse.ObjectMetadataByFullName(SeriesSpecificationParameters.FullObjectName);
	
	TypeProducts		= New TypeDescription("CatalogRef.Products");
	TypeCharacteristic	= New TypeDescription("CatalogRef.ItemsCharacteristics");
	TypeQuantity		= New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	
	TableOfSeries = New ValueTable;
	TableOfSeries.Columns.Add("Products", TypeProducts);
	TableOfSeries.Columns.Add("Characteristic", TypeCharacteristic);
	TableOfSeries.Columns.Add(SeriesSpecificationParameters.FieldNameQuantity, TypeQuantity);
	
	CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters,
															TableOfSeries,
															ObjectMetadata,
															True);
	
	Return TableOfSeries;
	
EndFunction

#EndRegion

// Server-side event handler Obrabatyvaniya Handbook of Opakowaniowej.
//
// Parameters:
// 	ChoiceData - ValueList of ValueListItem - 
// 	Parameters - Structure - may contain:
// 		* SelectParent - Boolean
// 		* Ref - CatalogRef.PackagesAndUnitsOfMeasure - required if the select Parent property is filled in
// 		* Filter - Filter - required if the select Parent property is filled in
// 		* Products - CatalogRef.Products
// 		* Warehouse - CatalogRef.Warehouses
// 		* AlwaysChooseUnitOfMeasurement - Boolean
// 		* ShowMeasuredUnitsOfMeasure - Boolean
// 		* ShowCargoItems - Boolean
// 		* MeasuredValueType - EnumRef.TypesOfMeasuredValues
// 	StandardProcessing - Boolean
// 
Procedure PackingUnitsProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	ChoiceData = New ValueList;
	
	If Parameters.Property("SelectParent") Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	ProductPackages.Ref					AS Package,
		|	ProductPackages.DeletionMark		AS DeletionMark,
		|	PRESENTATION(ProductPackages.Ref)	AS PackagePresentation,
		|	ProductPackages.Description			AS PresentationOfMatch,
		|	0											AS Order
		|INTO PackagingItemsSearch
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|WHERE
		|	ProductPackages.Ref <> &Ref
		|	AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|	AND ProductPackages.Owner = &Owner
		|	AND (NOT &SelectionBySearchBar
		|		OR ProductPackages.Description LIKE &SearchString ESCAPE ""~"")
		|
		|UNION ALL
		|
		|SELECT
		|	ProductPackages.Ref					AS Package,
		|	ProductPackages.DeletionMark		AS DeletionMark,
		|	PRESENTATION(ProductPackages.Ref)	AS PackagePresentation,
		|	ProductPackages.DescriptionLanguage1		AS PresentationOfMatch,
		|	1											AS Order
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|WHERE
		|	&AdditionalLanguagesAreUsed
		|	AND ProductPackages.Ref <> &Ref
		|	AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|	AND ProductPackages.Owner = &Owner
		|	AND ProductPackages.DescriptionLanguage1 LIKE &SearchString ESCAPE ""~""
		|
		|UNION ALL
		|
		|SELECT
		|	ProductPackages.Ref					AS Package,
		|	ProductPackages.DeletionMark		AS DeletionMark,
		|	PRESENTATION(ProductPackages.Ref)	AS PackagePresentation,
		|	ProductPackages.DescriptionLanguage2		AS PresentationOfMatch,
		|	2											AS Order
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|WHERE
		|	&AdditionalLanguagesAreUsed
		|	AND ProductPackages.Ref <> &Ref
		|	AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|	AND ProductPackages.Owner = &Owner
		|	AND ProductPackages.DescriptionLanguage2 LIKE &SearchString ESCAPE ""~""
		|
		|INDEX BY
		|	Package,
		|	Order
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductPackages.Package			AS Package,
		|	MIN(ProductPackages.Order)	AS Order
		|INTO PackagingItemsInOrder
		|FROM
		|	PackagingItemsSearch AS ProductPackages
		|
		|GROUP BY
		|	ProductPackages.Package
		|
		|INDEX BY
		|	Package,
		|	Order
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	PackagingItemsInOrder.Package			AS Package,
		|	PackagingItemsSearch.DeletionMark		AS DeletionMark,
		|	PackagingItemsSearch.PackagePresentation	AS PackagePresentation,
		|	PackagingItemsInOrder.Order			AS Order,
		|	ISNULL(PackagingItemsSearch.PresentationOfMatch, """") AS PresentationOfMatch
		|FROM
		|	PackagingItemsInOrder AS PackagingItemsInOrder
		|		LEFT JOIN PackagingItemsSearch AS PackagingItemsSearch
		|		ON PackagingItemsInOrder.Package = PackagingItemsSearch.Package
		|			AND PackagingItemsInOrder.Order = PackagingItemsSearch.Order
		|
		|ORDER BY
		|	Order,
		|	PresentationOfMatch";
		
		SelectionBySearchBar		= Parameters.SearchString <> Undefined
									And Not IsBlankString(Parameters.SearchString);
		SearchString			= ?(SelectionBySearchBar,
									Common.GenerateSearchQueryString(Parameters.SearchString) + "%",
									"");
		AdditionalLanguagesAreUsed	= ?(SelectionBySearchBar,
									NationalLanguageSupportCached.ConfigurationUsesOnlyOneLanguage(False),
									False);
		
		Query.SetParameter("Ref",					Parameters.Ref);
		Query.SetParameter("Owner",				Parameters.Filter.Owner);
		Query.SetParameter("SelectionBySearchBar",	SelectionBySearchBar);
		Query.SetParameter("SearchString",			SearchString);
		Query.SetParameter("AdditionalLanguagesAreUsed",	AdditionalLanguagesAreUsed);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			ListValue = New Structure;
			ListValue.Insert("Value", Selection.Package);
			ListValue.Insert("DeletionMark", Selection.DeletionMark);
			
			ChoiceData.Add(ListValue, Selection.PackagePresentation);
		EndDo;
		
		StandardProcessing = False;
		
	ElsIf Parameters.Property("Products")
		And Not (Parameters.Property("AlwaysChooseUnitOfMeasurement")
			And Not ValueIsFilled(Parameters.Products)) Then 
		
		Products = Parameters.Products;
		
		If Not ValueIsFilled(Products) Then
			Return;
		EndIf;
		
		Warehouse		= Undefined;
		Premise	= Undefined;
		
		Parameters.Property("Products", Products);
		If Parameters.Property("Warehouse",Warehouse) Then
			Parameters.Property("Premise", Premise);
			AddStorageUnit = Not WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise)
		Else
			AddStorageUnit = True;
		EndIf;
		
		ShowMeasuredUnitsOfMeasure = Undefined;
		
		If Not Parameters.Property("ShowMeasuredUnitsOfMeasure", ShowMeasuredUnitsOfMeasure) Then
			ShowMeasuredUnitsOfMeasure = True;
		EndIf;
		
		ShowCargoItems = Undefined;
		
		If Not Parameters.Property("ShowCargoItems", ShowCargoItems) Then
			ShowCargoItems = False;
		EndIf;
		
		FillSelectionDataWithPackages(Products,
			ChoiceData,
			Parameters,
			ShowMeasuredUnitsOfMeasure,
			AddStorageUnit,
			ShowCargoItems);
		
		StandardProcessing = False;
		
	Else
		
		MeasuredValueType = Undefined;
		
		If Not Parameters.Property("Filter")
			Or Not Parameters.Filter.Property("MeasuredValueType", MeasuredValueType)
				And Not Parameters.Property("MeasuredValueType", MeasuredValueType) Then
			
			If Not Parameters.Property("Filter") Then
				Parameters.Insert("Filter", New Structure);
			EndIf;
			
			ArrayOfUnitTypes = New Array;
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.Weight);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.VolumeM3);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.Length);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.NumberOfPieces);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.Capacity);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.Energy);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.ElectricCharge);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.Time);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.EmptyRef());
			
			Parameters.Filter.Insert("MeasuredValueType", ArrayOfUnitTypes);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillSelectionDataWithPackages(Products, ChoiceData, Parameters, Val ShowMeasuredUnitsOfMeasure, AddStorageUnit, ShowCargoItems)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductPackages.Ref AS Ref,
	|	ProductPackages.DeletionMark AS DeletionMark,
	|	FALSE AS ItIsUnitOfStorage,
	|	3 AS Order,
	|	&QueryTextPackagingFactor AS ZoomRatio,
	|	&RequestTextAvailabilityPackingFactor AS AcceptableFactor
	|INTO PackagesAndUnitsOfMeasure
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON Products.WeightUse
	|			AND Products.YouCanSpecifyWeightInDocuments
	|			AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
	|WHERE
	|	Products.Ref = &Products
	|	AND (&ShowMeasuredUnitsOfMeasure
	|		OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight))
	|
	|UNION ALL
	|
	|SELECT
	|	ProductPackages.Ref,
	|	ProductPackages.DeletionMark,
	|	FALSE,
	|	4,
	|	&QueryTextPackagingFactor,
	|	&RequestTextAvailabilityPackingFactor
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON Products.VolumeUse
	|			AND Products.VolumeCanBeSpecifiedInDocuments
	|			AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
	|WHERE
	|	Products.Ref = &Products
	|	AND (&ShowMeasuredUnitsOfMeasure
	|		OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3))
	|
	|UNION ALL
	|
	|SELECT
	|	ProductPackages.Ref,
	|	ProductPackages.DeletionMark,
	|	FALSE,
	|	5,
	|	&QueryTextPackagingFactor,
	|	&RequestTextAvailabilityPackingFactor
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON Products.LengthUse
	|			AND Products.YouCanSpecifyLengthInDocuments
	|			AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
	|WHERE
	|	Products.Ref = &Products
	|	AND (&ShowMeasuredUnitsOfMeasure
	|		OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length))
	|
	|UNION ALL
	|
	|SELECT
	|	ProductPackages.Ref,
	|	ProductPackages.DeletionMark,
	|	FALSE,
	|	6,
	|	&QueryTextPackagingFactor,
	|	&RequestTextAvailabilityPackingFactor
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON Products.AreaUse
	|			AND Products.AreaCanBeSpecifiedInDocuments
	|			AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
	|WHERE
	|	Products.Ref = &Products
	|	AND (&ShowMeasuredUnitsOfMeasure
	|		OR Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement))
	|
	|UNION ALL
	|
	|SELECT
	|	ProductPackages.Ref,
	|	ProductPackages.DeletionMark,
	|	FALSE,
	|	7,
	|	&QueryTextPackagingFactor,
	|	&RequestTextAvailabilityPackingFactor
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Capacity)
	|WHERE
	|	Products.Ref = &Products
	|	AND Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Capacity)
	|
	|UNION ALL
	|
	|SELECT
	|	ProductPackages.Ref,
	|	ProductPackages.DeletionMark,
	|	FALSE,
	|	8,
	|	&QueryTextPackagingFactor,
	|	&RequestTextAvailabilityPackingFactor
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Energy)
	|WHERE
	|	Products.Ref = &Products
	|	AND Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Energy)
	|
	|UNION ALL
	|
	|SELECT
	|	ProductPackages.Ref,
	|	ProductPackages.DeletionMark,
	|	FALSE,
	|	9,
	|	&QueryTextPackagingFactor,
	|	&RequestTextAvailabilityPackingFactor
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)
	|WHERE
	|	Products.Ref = &Products
	|	AND Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)
	|
	|UNION ALL
	|
	|SELECT
	|	ProductPackages.Ref,
	|	ProductPackages.DeletionMark,
	|	FALSE,
	|	10,
	|	&QueryTextPackagingFactor,
	|	&RequestTextAvailabilityPackingFactor
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Time)
	|WHERE
	|	Products.Ref = &Products
	|	AND Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Time)
	|
	|UNION ALL
	|
	|SELECT
	|	CatPackages.Ref,
	|	CatPackages.DeletionMark,
	|	FALSE,
	|	1,
	|	CatPackages.Numerator / CatPackages.Denominator,
	|	TRUE
	|FROM
	|	Catalog.Products AS CatProducts
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS CatPackages
	|		ON (CASE
	|				WHEN CatProducts.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|					THEN CatPackages.Owner = CatProducts.Ref
	|				WHEN CatProducts.PackagingGroup <> VALUE(Catalog.PackagingGroups.EmptyRef)
	|					THEN CatPackages.Owner = CatProducts.PackagingGroup
	|				ELSE FALSE
	|			END)
	|WHERE
	|	CatProducts.Ref = &Products
	|	AND NOT CatPackages.DeletionMark
	|	AND CatPackages.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	CatPackages.Ref,
	|	CatPackages.DeletionMark,
	|	FALSE,
	|	1,
	|	CatPackages.Numerator / CatPackages.Denominator,
	|	TRUE
	|FROM
	|	Catalog.Products AS CatProducts
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS CatPackages
	|		ON (CASE
	|				WHEN CatProducts.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|					THEN CatPackages.Owner = CatProducts.Ref
	|				WHEN CatProducts.PackagingGroup <> VALUE(Catalog.PackagingGroups.EmptyRef)
	|					THEN CatPackages.Owner = CatProducts.PackagingGroup
	|				ELSE FALSE
	|			END)
	|WHERE
	|	CatProducts.Ref = &Products
	|	AND NOT CatPackages.DeletionMark
	|	AND &ShowCargoItems
	|	AND CatPackages.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	CatPackages.Ref,
	|	CatPackages.DeletionMark,
	|	TRUE,
	|	1,
	|	1,
	|	TRUE
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS CatPackages
	|		ON Products.UnitOfMeasure = CatPackages.Ref
	|WHERE
	|	Products.Ref = &Products
	|	AND (&AddStorageUnit
	|		OR CatPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
	|		OR CatPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3)
	|		OR CatPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length)
	|		OR CatPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)
	|		OR CatPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Capacity)
	|		OR CatPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Energy)
	|		OR CatPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.ElectricCharge)
	|		OR CatPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Time))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PackagesAndUnitsOfMeasure.Ref AS Package,
	|	PackagesAndUnitsOfMeasure.DeletionMark AS DeletionMark,
	|	MAX(PackagesAndUnitsOfMeasure.ItIsUnitOfStorage) AS ItIsUnitOfStorage,
	|	MIN(PackagesAndUnitsOfMeasure.Order) AS Order,
	|	PackagesAndUnitsOfMeasure.ZoomRatio AS ZoomRatio,
	|	PackagesAndUnitsOfMeasure.AcceptableFactor AS AcceptableFactor
	|INTO PackagingUnitsOfMeasurementGrouped
	|FROM
	|	PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|WHERE
	|	&AdditionalConditionsForChoiceParameters
	|	AND PackagesAndUnitsOfMeasure.AcceptableFactor
	|
	|GROUP BY
	|	PackagesAndUnitsOfMeasure.Ref,
	|	PackagesAndUnitsOfMeasure.DeletionMark,
	|	PackagesAndUnitsOfMeasure.ZoomRatio,
	|	PackagesAndUnitsOfMeasure.AcceptableFactor
	|
	|INDEX BY
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PackagesAndUnitsOfMeasure.Package AS Package,
	|	PackagesAndUnitsOfMeasure.DeletionMark AS DeletionMark,
	|	PackagesAndUnitsOfMeasure.ItIsUnitOfStorage AS ItIsUnitOfStorage,
	|	CatalogData.Description AS PresentationOfMatch,
	|	PackagesAndUnitsOfMeasure.Order AS Order,
	|	0 AS SearchOrder,
	|	PackagesAndUnitsOfMeasure.ZoomRatio AS ZoomRatio,
	|	PackagesAndUnitsOfMeasure.AcceptableFactor AS AcceptableFactor
	|INTO PackagingItemsSearch
	|FROM
	|	PackagingUnitsOfMeasurementGrouped AS PackagesAndUnitsOfMeasure
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS CatalogData
	|		ON PackagesAndUnitsOfMeasure.Package = CatalogData.Ref
	|
	|WHERE
	|	NOT &SelectionBySearchBar
	|	OR CatalogData.Description LIKE &SearchString ESCAPE ""~""
	|
	|UNION ALL
	|
	|SELECT
	|	PackagesAndUnitsOfMeasure.Package AS Package,
	|	PackagesAndUnitsOfMeasure.DeletionMark AS DeletionMark,
	|	PackagesAndUnitsOfMeasure.ItIsUnitOfStorage AS ItIsUnitOfStorage,
	|	CatalogData.DescriptionLanguage1 AS PresentationOfMatch,
	|	PackagesAndUnitsOfMeasure.Order AS Order,
	|	1 AS SearchOrder,
	|	PackagesAndUnitsOfMeasure.ZoomRatio AS ZoomRatio,
	|	PackagesAndUnitsOfMeasure.AcceptableFactor AS AcceptableFactor
	|FROM
	|	PackagingUnitsOfMeasurementGrouped AS PackagesAndUnitsOfMeasure
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS CatalogData
	|		ON PackagesAndUnitsOfMeasure.Package = CatalogData.Ref
	|
	|WHERE
	|	&AdditionalLanguagesAreUsed
	|	AND CatalogData.DescriptionLanguage1 LIKE &SearchString ESCAPE ""~""
	|
	|UNION ALL
	|
	|SELECT
	|	PackagesAndUnitsOfMeasure.Package AS Package,
	|	PackagesAndUnitsOfMeasure.DeletionMark AS DeletionMark,
	|	PackagesAndUnitsOfMeasure.ItIsUnitOfStorage AS ItIsUnitOfStorage,
	|	CatalogData.DescriptionLanguage2 AS PresentationOfMatch,
	|	PackagesAndUnitsOfMeasure.Order AS Order,
	|	2 AS SearchOrder,
	|	PackagesAndUnitsOfMeasure.ZoomRatio AS ZoomRatio,
	|	PackagesAndUnitsOfMeasure.AcceptableFactor AS AcceptableFactor
	|FROM
	|	PackagingUnitsOfMeasurementGrouped AS PackagesAndUnitsOfMeasure
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS CatalogData
	|		ON PackagesAndUnitsOfMeasure.Package = CatalogData.Ref
	|
	|WHERE
	|	&AdditionalLanguagesAreUsed
	|	AND CatalogData.DescriptionLanguage2 LIKE &SearchString ESCAPE ""~""
	|
	|INDEX BY
	|	Package,
	|	SearchOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PackagesAndUnitsOfMeasure.Package AS Package,
	|	MIN(PackagesAndUnitsOfMeasure.SearchOrder) AS SearchOrder
	|INTO PackagingItemsInOrder
	|FROM
	|	PackagingItemsSearch AS PackagesAndUnitsOfMeasure
	|
	|GROUP BY
	|	PackagesAndUnitsOfMeasure.Package
	|
	|INDEX BY
	|	Package,
	|	SearchOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	PackagingItemsInOrder.Package AS Package,
	|	PackagingItemsSearch.DeletionMark AS DeletionMark,
	|	PackagingItemsSearch.ItIsUnitOfStorage AS ItIsUnitOfStorage,
	|	PRESENTATION(PackagingItemsInOrder.Package) AS PackagePresentation,
	|	PackagingItemsSearch.Order AS Order,
	|	PackagingItemsInOrder.SearchOrder AS SearchOrder,
	|	ISNULL(PackagingItemsSearch.PresentationOfMatch, """") AS PresentationOfMatch,
	|	PackagingItemsSearch.ZoomRatio AS ZoomRatio,
	|	PackagingItemsSearch.AcceptableFactor AS AcceptableFactor
	|FROM
	|	PackagingItemsInOrder AS PackagingItemsInOrder
	|		LEFT JOIN PackagingItemsSearch AS PackagingItemsSearch
	|		ON PackagingItemsInOrder.Package = PackagingItemsSearch.Package
	|			AND PackagingItemsInOrder.SearchOrder = PackagingItemsSearch.SearchOrder
	|
	|ORDER BY
	|	Order,
	|	ZoomRatio DESC,
	|	SearchOrder,
	|	PresentationOfMatch";
	
	Query.SetParameter("AddStorageUnit", AddStorageUnit);
	Query.SetParameter("ShowMeasuredUnitsOfMeasure", ShowMeasuredUnitsOfMeasure);
	Query.SetParameter("ShowCargoItems", ShowCargoItems);
	Query.SetParameter("Products", Products);
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingFactorToSelect(
			"ProductPackages",
			"Products"));
	
	Query.Text = StrReplace(Query.Text,
		"&RequestTextAvailabilityPackingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextAvailabilityFactorForPackageSelection(
			"ProductPackages",
			"Products"));
	
	ConditionsForSelectionParameters = "";
	If Parameters.Property("ShowOnlyPackages")
		And Parameters.ShowOnlyPackages = True Then
		ConditionsForSelectionParameters = ConditionsForSelectionParameters + "PackagesAndUnitsOfMeasure.Ref.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)"
	EndIf;

	If Not ValueIsFilled(ConditionsForSelectionParameters) Then
		ConditionsForSelectionParameters = "TRUE";
	EndIf;
	
	Query.Text = StrReplace(Query.Text,
		"&AdditionalConditionsForChoiceParameters",
		ConditionsForSelectionParameters);
	
	SelectionBySearchBar		= Parameters.SearchString <> Undefined
								And Not IsBlankString(Parameters.SearchString);
	SearchString			= ?(SelectionBySearchBar,
								Common.GenerateSearchQueryString(Parameters.SearchString) + "%",
								"");
	AdditionalLanguagesAreUsed	= ?(SelectionBySearchBar,
								NationalLanguageSupportCached.ConfigurationUsesOnlyOneLanguage(False),
								False);
	
	Query.SetParameter("SelectionBySearchBar",	SelectionBySearchBar);
	Query.SetParameter("SearchString",			SearchString);
	Query.SetParameter("AdditionalLanguagesAreUsed",	AdditionalLanguagesAreUsed);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Selection.ItIsUnitOfStorage Then
			ChoiceData.Add(Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(), Selection.PackagePresentation);
		Else
			ListValue = New Structure;
			ListValue.Insert("Value", Selection.Package);
			ListValue.Insert("DeletionMark", Selection.DeletionMark);
			ChoiceData.Add(ListValue, Selection.PackagePresentation);
		EndIf;
	EndDo;
	
EndProcedure

// Server handler for the event processingreceiving data From the list of characteristics of the Nomenclature.
//
Procedure ProductCharacteristicsProcessingOfSelectionData(ChoiceData, Parameters, StandardProcessing) Export
	
	Var Products;
	
	If Not Parameters.Property("Products", Products) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	SearchString = Parameters.SearchString;
	
	Query = New Query;
	QueryText = 
	"SELECT TOP 50
	|	CatCharacteristics.Ref AS Characteristic,
	|	CatCharacteristics.DeletionMark AS DeletionMark,
	|	CatCharacteristics.Description AS CharacteristicPresentation
	|FROM
	|	Catalog.ItemsCharacteristics AS CatCharacteristics
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON (CatCharacteristics.Owner = CASE
	|				WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					THEN CatProducts.ProductKind
	|				WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					THEN CatProducts.Ref
	|				WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					THEN CatProducts.ItemVariantsOwner
	|				ELSE FALSE
	|			END)
	|WHERE
	|	CatProducts.Ref = &Products
	|	AND CASE
	|		WHEN &AdditionalLanguagesAreUsed = FALSE AND &SearchBarFilled = TRUE THEN
	|			CatCharacteristics.Description LIKE &SearchString ESCAPE ""~""
	|		WHEN &AdditionalLanguagesAreUsed = TRUE AND &SearchBarFilled = TRUE THEN
	|			(CatCharacteristics.Description LIKE &SearchString ESCAPE ""~""
	|			OR CatCharacteristics.DescriptionLanguage1 LIKE &SearchString ESCAPE ""~""
	|			OR CatCharacteristics.DescriptionLanguage2 LIKE &SearchString ESCAPE ""~"")
	|		ELSE TRUE
	|	END
	|	AND &FilterCriterion
	|ORDER BY
	|	CharacteristicPresentation
	|";
	Query.SetParameter("AdditionalLanguagesAreUsed", NationalLanguageSupportCached.ConfigurationUsesOnlyOneLanguage(False));
	Query.SetParameter("Products", Products);
	Query.SetParameter("SearchBarFilled", ValueIsFilled(SearchString));
	
	If SearchString <> Undefined Then
		Query.SetParameter("SearchString", Common.GenerateSearchQueryString(SearchString) + "%");
	EndIf;
	
	FilterCriterion = New Array;
	
	NamesOfNonStandardSelections = New Structure;
	NamesOfNonStandardSelections.Insert("ItemsType", "ItemsType");
	
	For Each SelectionKeyAndValue In Parameters.Filter Do
		FilterName = SelectionKeyAndValue.Key;
		FilterValue = SelectionKeyAndValue.Value;
		
		NameOfNonStandardSelection = "";
		If NamesOfNonStandardSelections.Property(FilterName, NameOfNonStandardSelection) Then
			
			If NameOfNonStandardSelection = "ItemsType" 
				And TypeOf(FilterValue) = Type("Array")
				And FilterValue.Find(Enums.ItemsTypes.Set) <> Undefined Then
				
				FilterValue = Common.CopyRecursive(FilterValue); // A copy for the immutability of the incoming parameter
				FilterValue.Delete(FilterValue.Find(Enums.ItemsTypes.Set));
				Query.SetParameter("ItemsType", FilterValue);
				
				LimitSetsByService = FilterValue.Find(Enums.ItemsTypes.OperationService) <> Undefined
					Or FilterValue.Find(Enums.ItemsTypes.Work_5) <> Undefined;
				LimitSetsByProduct = FilterValue.Find(Enums.ItemsTypes.ReusablePackage) <> Undefined
					Or FilterValue.Find(Enums.ItemsTypes.OwnGoods) <> Undefined;
						
				FilterText1 = "(CatProducts.ItemsType IN (&ItemsType)
				|		OR CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Set)
				|			AND &TextOfSetRestriction)";
				
				If LimitSetsByProduct And Not LimitSetsByService Then
					FilterText1 = StrReplace(
						FilterText1,
						"&TextOfSetRestriction",
						"NOT ProductKitConfigurations.ContainsServices AND ProductKitConfigurations.ContainsGoods");
				ElsIf Not LimitSetsByProduct And LimitSetsByService Then
					FilterText1 = StrReplace(
						FilterText1,
						"&TextOfSetRestriction",
						"ProductKitConfigurations.ContainsServices AND NOT ProductKitConfigurations.ContainsGoods");
				Else
					FilterText1 = StrReplace(
						FilterText1,
						"&TextOfSetRestriction",
						"TRUE");
				EndIf;
				
				FilterCriterion.Add(FilterText1);
					
				TableDetails = 
					RequestSchemes.TableDetails(
					Type("QuerySchemaTable"),
					"Catalog.ProductKitConfigurations",
					"ProductKitConfigurations",
					"Owner, ContainsGoods, ContainsServices");
				
				IConnectionShort =
					RequestSchemes.IConnectionShort(
					TableDetails,
					"ProductKitConfigurations.Owner = &Products
					|AND ProductKitConfigurations.Characteristic = CatCharacteristics.Ref
					|AND ProductKitConfigurations.Main",
					QuerySchemaJoinType.LeftOuter);
				
				QueryText =
					RequestSchemes.AddConnectionToRequest(
					QueryText,
					"CatCharacteristics",
					IConnectionShort,
					0);
					
				Continue;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Not ValueIsFilled(FilterCriterion) Then
		FilterCriterion.Add("TRUE");
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FilterCriterion", StrConcat(FilterCriterion, "
	|	AND "));
	Query.Text = QueryText;
	ChoiceData = New ValueList;

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ListValue = New Structure;
		ListValue.Insert("Value", Selection.Characteristic);
		ListValue.Insert("DeletionMark", Selection.DeletionMark);
	
		ChoiceData.Add(ListValue, Selection.CharacteristicPresentation);
	EndDo;	
	
EndProcedure

Function CheckRoundingOfInternalQuantity(Object, CheckParameters, AcceptablePercentageOfDeviation)
	
	TSName = CheckParameters.TSName;
	FieldNamesWithSuffix = CheckParameters.FieldNamesWithSuffix;

	QueryText = 
	"SELECT
	|	TS.LineNumber AS LineNumber,
	|	CAST(TS.Products AS Catalog.Products) AS Products,
	|	TS.NumberOfPackages AS NumberOfPackages,
	|	TS.Count AS QuantityOfGoodsInDocument,
	|	CAST(TS.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	&FieldNameNumberOfPackagesSuffix AS NumberOfPackagesSuffix,
	|	&FieldNameQuantitySuffix AS NumberOfSuffixesInDocument,
	|	&AdditionalFields
	|INTO WTableData
	|FROM
	|	&TS AS TS
	|WHERE
	|	TS.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	AND &ConditionForSelectingRowsForRounding
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WTableData.LineNumber AS LineNumber,
	|	WTableData.Products AS Products,
	|	WTableData.NumberOfPackages AS NumberOfPackages,
	|	WTableData.QuantityOfGoodsInDocument AS QuantityOfGoodsInDocument,
	|	WTableData.Package AS Package,
	|	WTableData.NumberOfPackagesSuffix AS NumberOfPackagesSuffix,
	|	WTableData.NumberOfSuffixesInDocument AS NumberOfSuffixesInDocument
	|INTO TTForRequest
	|FROM
	|	WTableData AS WTableData
	|WHERE
	|	ISNULL(WTableData.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	AND WTableData.Products.UnitOfMeasure.MeasuredValueType = &PieceType
	|	AND &ConditionForSelectingRowsByAdditionalFields
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP WTableData";

	If FieldNamesWithSuffix.Property("Count") Then
		QueryText = StrReplace(QueryText, "&FieldNameQuantitySuffix", "TS." + FieldNamesWithSuffix.Count);
		QueryText = StrReplace(QueryText, "&FieldNameNumberOfPackagesSuffix", "TS." + FieldNamesWithSuffix.NumberOfPackages);
	Else
		QueryText = StrReplace(QueryText, "&FieldNameQuantitySuffix", "0");
		QueryText = StrReplace(QueryText, "&FieldNameNumberOfPackagesSuffix", "0");
	EndIf;

	Query = New Query;

	If CheckParameters.TableToCheck <> Undefined Then
		
		Query.SetParameter("TS", CheckParameters.TableToCheck);
		
	ElsIf TSName = "Object" Then
		
		Table = New ValueTable;
		Table.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers(5,0,AllowedSign.Nonnegative)));
		Table.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		Table.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		Table.Columns.Add("Count", TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
		Table.Columns.Add("NumberOfPackages", TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
		
		TableRow = Table.Add();
		FillPropertyValues(TableRow, Object);
		
		Query.SetParameter("TS", Table);
		
	Else
		Query.SetParameter("TS", Object[TSName].Unload());
	EndIf;

	If ValueIsFilled(CheckParameters.AdditionalFields) Then
		Template = "%1 AS %2,
					|%3";
		FieldTexts = Template;
		
		For Each Field In CheckParameters.AdditionalFields Do
			FieldTexts = StrTemplate(FieldTexts, StrReplace(Field.Value, TSName + ".", "TS."), Field.Key, Template);
		EndDo;
		
		QueryText = StrReplace(QueryText,
									"&AdditionalFields",
									Mid(FieldTexts, 1, StrFind(FieldTexts, ",", SearchDirection.FromEnd,, 2) - 1));
	Else
		QueryText = StrReplace(QueryText, "&AdditionalFields", "TRUE");
	EndIf;

	If ValueIsFilled(CheckParameters.ConditionForSelectingRowsByAdditionalFields) Then
		QueryText = StrReplace(QueryText,
									"&ConditionForSelectingRowsByAdditionalFields",
									StrReplace(CheckParameters.ConditionForSelectingRowsByAdditionalFields,
												TSName + ".",
												"WTableData."));
	Else
		QueryText = StrReplace(QueryText, "&ConditionForSelectingRowsByAdditionalFields", "TRUE");	
	EndIf;

	If CheckParameters.ConditionForSelectingRowsForRounding <> "" Then
		QueryText = StrReplace(QueryText,
									"&ConditionForSelectingRowsForRounding",
									StrReplace(CheckParameters.ConditionForSelectingRowsForRounding, TSName + ".", "TS."));
	Else
		QueryText = StrReplace(QueryText, "&ConditionForSelectingRowsForRounding", "TRUE");
	EndIf;

	Query.SetParameter("PieceType", Enums.TypesOfMeasuredValues.NumberOfPieces);

	For Each QueryParameter In CheckParameters.QueryOptions Do
		Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;

	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	Query.Execute();
	Result = TempTablesManager.Tables[0].GetData();
	If Result.IsEmpty() Then
		Return Result;
	EndIf;

	QueryText =
	"SELECT
	|	TTForRequest.LineNumber AS LineNumber,
	|	TTForRequest.Package AS Package,
	|	PackagesAndUnitsOfMeasure.MeasuredValueType AS MeasuredValueType,
	|	PackagesAndUnitsOfMeasure.PackageType AS PackageType,
	|	&QueryTextPackagingFactor AS PackagingFactor
	|INTO TTCoefficients
	|FROM
	|	TTForRequest AS TTForRequest
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON TTForRequest.Package = PackagesAndUnitsOfMeasure.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTForRequest.LineNumber AS LineNumber,
	|	TTCoefficients.MeasuredValueType IN (&DimensionalTypes) AS CanBeRounded,
	|	TTForRequest.Products.UnitOfMeasure AS BasicUnitOfMeasurement,
	|	TTForRequest.Products AS Products,
	|	TTCoefficients.Package AS Package,
	|	TTCoefficients.PackagingFactor AS PackagingFactor,
	|	CAST(TTForRequest.NumberOfPackages * TTCoefficients.PackagingFactor AS NUMBER(15, 3)) AS Count,
	|	CAST(TTForRequest.NumberOfPackages * TTCoefficients.PackagingFactor AS NUMBER(15, 0)) AS RoundedQuantity,
	|	TTForRequest.QuantityOfGoodsInDocument AS QuantityOfGoodsInDocument,
	|	CAST(TTForRequest.NumberOfPackagesSuffix * TTCoefficients.PackagingFactor AS NUMBER(15, 3)) AS SuffixCount,
	|	CAST(TTForRequest.NumberOfPackagesSuffix * TTCoefficients.PackagingFactor AS NUMBER(15, 0)) AS SuffixNumberRounded,
	|	TTForRequest.NumberOfSuffixesInDocument AS NumberOfSuffixesInDocument
	|INTO TT
	|FROM
	|	TTForRequest AS TTForRequest
	|		LEFT JOIN TTCoefficients AS TTCoefficients
	|		ON TTForRequest.Package = TTCoefficients.Package
	|		AND TTForRequest.LineNumber = TTCoefficients.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TS.LineNumber AS LineNumber,
	|	PRESENTATION(TS.BasicUnitOfMeasurement) AS BasicUnitOfMeasurement,
	|	PRESENTATION(TS.Package) AS Package,
	|	TS.RoundedQuantity AS RoundedQuantity,
	|	TS.SuffixNumberRounded AS SuffixNumberRounded,
	|	CAST(CASE
	|			WHEN &CheckPossibilityOfRounding
	|					AND TS.CanBeRounded
	|				THEN CASE
	|						WHEN TS.Count - TS.RoundedQuantity > 0
	|							THEN TS.Count - TS.RoundedQuantity
	|						ELSE TS.RoundedQuantity - TS.Count
	|					END
	|			ELSE CASE
	|					WHEN TS.QuantityOfGoodsInDocument - TS.Count > 0
	|						THEN TS.QuantityOfGoodsInDocument - TS.Count
	|					ELSE TS.Count - TS.QuantityOfGoodsInDocument
	|				END
	|		END / TS.PackagingFactor AS NUMBER(15, 3)) AS DeviationInStorageUnits,
	|	CAST(CASE
	|			WHEN &CheckPossibilityOfRounding
	|					AND TS.CanBeRounded
	|				THEN &AcceptablePercentageOfDeviation * TS.RoundedQuantity / TS.PackagingFactor / 100
	|			ELSE 0
	|		END AS NUMBER(15, 3)) AS QuantityMaximumError,
	|	CAST(CASE
	|			WHEN &CheckPossibilityOfRounding
	|				THEN CASE
	|						WHEN TS.SuffixCount - TS.SuffixNumberRounded > 0
	|							THEN TS.SuffixCount - TS.SuffixNumberRounded
	|						ELSE TS.SuffixNumberRounded - TS.SuffixCount
	|					END
	|			ELSE CASE
	|					WHEN TS.NumberOfSuffixesInDocument - TS.SuffixCount > 0
	|						THEN TS.NumberOfSuffixesInDocument - TS.SuffixCount
	|					ELSE TS.SuffixCount - TS.NumberOfSuffixesInDocument
	|				END
	|		END / TS.PackagingFactor AS NUMBER(15, 3)) AS NumberOfSuffixDeviation,
	|	CAST(CASE
	|			WHEN &CheckPossibilityOfRounding
	|					AND TS.CanBeRounded
	|				THEN &AcceptablePercentageOfDeviation * TS.SuffixNumberRounded / TS.PackagingFactor / 100
	|			ELSE 0
	|		END AS NUMBER(15, 3)) AS NumberOfSuffixMaximumError
	|FROM
	|	TT AS TS
	|WHERE
	|	((CAST(CASE
	|					WHEN &CheckPossibilityOfRounding
	|							AND TS.CanBeRounded
	|						THEN CASE
	|								WHEN TS.Count - TS.RoundedQuantity > 0
	|									THEN TS.Count - TS.RoundedQuantity
	|								ELSE TS.RoundedQuantity - TS.Count
	|							END
	|					ELSE CASE
	|							WHEN TS.QuantityOfGoodsInDocument - TS.Count > 0
	|								THEN TS.QuantityOfGoodsInDocument - TS.Count
	|							ELSE TS.Count - TS.QuantityOfGoodsInDocument
	|						END
	|				END / TS.PackagingFactor AS NUMBER(15, 3))) > (CAST(CASE
	|					WHEN &CheckPossibilityOfRounding
	|							AND TS.CanBeRounded
	|						THEN &AcceptablePercentageOfDeviation * TS.RoundedQuantity / TS.PackagingFactor / 100
	|					ELSE 0
	|				END AS NUMBER(15, 3)))
	|			OR (CAST(CASE
	|					WHEN &CheckPossibilityOfRounding
	|							AND TS.CanBeRounded
	|						THEN CASE
	|								WHEN TS.SuffixCount - TS.SuffixNumberRounded > 0
	|									THEN TS.SuffixCount - TS.SuffixNumberRounded
	|								ELSE TS.SuffixNumberRounded - TS.SuffixCount
	|							END
	|					ELSE CASE
	|							WHEN TS.NumberOfSuffixesInDocument - TS.SuffixCount > 0
	|								THEN TS.NumberOfSuffixesInDocument - TS.SuffixCount
	|							ELSE TS.SuffixCount - TS.NumberOfSuffixesInDocument
	|						END
	|				END / TS.PackagingFactor AS NUMBER(15, 3))) > (CAST(CASE
	|					WHEN &CheckPossibilityOfRounding
	|							AND TS.CanBeRounded
	|						THEN &AcceptablePercentageOfDeviation * TS.SuffixNumberRounded / TS.PackagingFactor / 100
	|					ELSE 0
	|				END AS NUMBER(15, 3))))
	|
	|ORDER BY
	|	LineNumber";
	
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"TTForRequest.Package",
									"TTForRequest.Products"));
	
	Query.Text = QueryText;
	
	Query.SetParameter("AcceptablePercentageOfDeviation", AcceptablePercentageOfDeviation);
	Query.SetParameter("CheckPossibilityOfRounding", CheckParameters.CheckPossibilityOfRounding);
	
	DimensionalTypes = New Array;
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.Weight);
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.VolumeM3);
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement);
	DimensionalTypes.Add(Enums.TypesOfMeasuredValues.Length);
	
	Query.SetParameter("DimensionalTypes", DimensionalTypes);

	Result = Query.Execute();
	Return Result;
	
EndFunction

Function PathToTableField(CheckParameters, LineNumber, ColumnName)
	
	If CheckParameters.ThisIsCheckOfCurrentLine Then
		
		ReturnValue = TMCommonUseClientServer.PathToElementOfCurrentRowOfFormTable(
			CheckParameters.TSName, // We assume that the element has the same name as the TS
			ColumnName);
		
	Else
		
		ReturnValue = CommonClientServer.PathToTabularSection(
			CheckParameters.TSName,
			LineNumber,
			ColumnName);
		
	EndIf;
	
	Return ReturnValue;
	
EndFunction

#Region BatchProcessingOfTablePartsIsService

// Returns a list of requests to check the property by owner.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsCheckCharacteristicsByOwner()
	
	Result = New ValueList;
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	ISNULL(CharacteristicTable.Ref, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS
	|		Characteristic,
	|	CASE
	|		WHEN
	|			ProductsTable.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|		OR
	|			ProductsTable.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|		OR
	|			ProductsTable.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN Catalog.Products AS ProductsTable
	|		ON TTDataSource.Products = ProductsTable.Ref
	|		LEFT JOIN Catalog.ItemsCharacteristics AS CharacteristicTable
	|		ON TTDataSource.Characteristic = CharacteristicTable.Ref
	|		AND (CASE
	|			WHEN
	|				ProductsTable.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|				THEN ProductsTable.ProductKind
	|			WHEN
	|				ProductsTable.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|				THEN ProductsTable.Ref
	|			WHEN
	|				ProductsTable.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|				THEN ProductsTable.ItemVariantsOwner
	|			ELSE FALSE
	|		END = CharacteristicTable.Owner)";
	
	Result.Add(QueryText, "CheckCharacteristicsByOwner");
	
	Return Result;
	
EndFunction

// Returns a list of requests for checking and filling out the package by owner.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsToCheckFillInPackagingUnitsByOwner()
	
	Result = New ValueList;
	
	QueryText =
	"SELECT DISTINCT
	|	Subquery.IdOfTTRow AS IdOfTTRow
	|INTO CheckFillPackageByOwner_Validation
	|FROM
	|	(SELECT
	|		TTDataSource.IdOfTTRow AS IdOfTTRow
	|	FROM
	|		TTDataSource AS TTDataSource
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS TableWeight
	|			ON TTDataSource.Package = TableWeight.Ref
	|			AND (TTDataSource.Products.WeightUse)
	|			AND (TTDataSource.Products.YouCanSpecifyWeightInDocuments)
	|			AND (TableWeight.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TTDataSource.IdOfTTRow
	|	FROM
	|		TTDataSource AS TTDataSource
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS TableLength
	|			ON TTDataSource.Package = TableLength.Ref
	|			AND (TTDataSource.Products.LengthUse)
	|			AND (TTDataSource.Products.YouCanSpecifyLengthInDocuments)
	|			AND (TableLength.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Length))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TTDataSource.IdOfTTRow
	|	FROM
	|		TTDataSource AS TTDataSource
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS TableVolume
	|			ON TTDataSource.Package = TableVolume.Ref
	|			AND (TTDataSource.Products.VolumeUse)
	|			AND (TTDataSource.Products.VolumeCanBeSpecifiedInDocuments)
	|			AND (TableVolume.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.VolumeM3))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TTDataSource.IdOfTTRow
	|	FROM
	|		TTDataSource AS TTDataSource
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS TableAnArea
	|			ON TTDataSource.Package = TableAnArea.Ref
	|			AND (TTDataSource.Products.AreaUse)
	|			AND (TTDataSource.Products.AreaCanBeSpecifiedInDocuments)
	|			AND (TableAnArea.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TTDataSource.IdOfTTRow
	|	FROM
	|		TTDataSource AS TTDataSource
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS TableOfUnitsOfMeasurement
	|			ON TTDataSource.Package = TableOfUnitsOfMeasurement.Ref
	|			AND
	|				TTDataSource.Products.UnitOfMeasure.MeasuredValueType = TableOfUnitsOfMeasurement.MeasuredValueType
	|
	|	UNION ALL
	|
	|	SELECT
	|		TTDataSource.IdOfTTRow
	|	FROM
	|		TTDataSource AS TTDataSource
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS TableOfPackagingUnitsIndividual
	|			ON TTDataSource.Package = TableOfPackagingUnitsIndividual.Ref
	|			AND TTDataSource.Products.Ref = TableOfPackagingUnitsIndividual.Owner
	|
	|	UNION ALL
	|
	|	SELECT
	|		TTDataSource.IdOfTTRow
	|	FROM
	|		TTDataSource AS TTDataSource
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS TableOfPackagingUnitsSets
	|			ON TTDataSource.Package = TableOfPackagingUnitsSets.Ref
	|			AND TTDataSource.Products.PackagingGroup = TableOfPackagingUnitsSets.Owner
	|
	|	UNION ALL
	|
	|	SELECT
	|		TTDataSource.IdOfTTRow
	|	FROM
	|		TTDataSource AS TTDataSource
	|	WHERE
	|		TTDataSource.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Subquery
	|
	|INDEX BY
	|	IdOfTTRow";
	
	Result.Add(QueryText, "CheckFillPackageByOwner_Validation");
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	SearchForPackagingUnits.IdOfTTRow IS NOT NULL AS VerificationIsSuccessful
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN CheckFillPackageByOwner_Validation AS SearchForPackagingUnits
	|		ON TTDataSource.IdOfTTRow = SearchForPackagingUnits.IdOfTTRow";
	
	Result.Add(QueryText, "CheckFillPackageByOwner");
	
	Return Result;
	
EndFunction

// Returns a list of queries to search for identical characteristics.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsFillInCharacteristicsOfLowQualityItem()
	
	Result = New ValueList;
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	ISNULL(MAX(CharacteristicTable.Ref), VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS
	|		Characteristic,
	|	ISNULL(MAX(SourceNomenclatureTable.UseVariants),
	|				VALUE(Enum.ItemVariantsUsageOptions.EmptyRef)) AS ItemUsageCharacteristics
	|INTO CharacteristicsOfPoorQualityItem
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN Catalog.Products AS SourceNomenclatureTable
	|		ON TTDataSource.Products = SourceNomenclatureTable.Ref
	|		AND
	|			SourceNomenclatureTable.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|		LEFT JOIN Catalog.ItemsCharacteristics AS TableOfSourceCharacteristics
	|		ON TTDataSource.Characteristic = TableOfSourceCharacteristics.Ref
	|		LEFT JOIN Catalog.ItemsCharacteristics AS CharacteristicTable
	|		ON TTDataSource.Products = CharacteristicTable.Owner
	|		AND TableOfSourceCharacteristics.Ref <> CharacteristicTable.Ref
	|		AND TableOfSourceCharacteristics.Description = CharacteristicTable.Description
	|GROUP BY
	|	TTDataSource.IdOfTTRow";
	
	Result.Add(QueryText, "CharacteristicsOfPoorQualityItem");
	
	QueryText =
	"SELECT
	|	ResultTable1.IdOfTTRow AS IdOfTTRow,
	|	ResultTable1.Characteristic AS Characteristic,
	|	ResultTable1.ItemUsageCharacteristics AS ItemUsageCharacteristics
	|FROM
	|	CharacteristicsOfPoorQualityItem AS ResultTable1";
	
	Result.Add(QueryText, "FillInDescriptionOfPoorQualityProduct");
	
	Return Result;
	
EndFunction

// Returns a list of queries for searching for identical packaging.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsFillInPackagingUnitsOfLowQualityItem()
	
	Result = New ValueList;
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	ProductsTable.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem) AS
	|		ThisIsIndividualSet,
	|	TTDataSource.Products AS Products,
	|	TTDataSource.Package AS Package,
	|	CASE
	|		WHEN ProductsTable.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|			THEN TTDataSource.Products
	|		ELSE ISNULL(ProductsTable.PackagingGroup, VALUE(Catalog.PackagingGroups.EmptyRef))
	|	END AS PackageOwner_
	|INTO FillInPackagingOfLowQualityGoods_DataSource
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN Catalog.Products AS ProductsTable
	|		ON TTDataSource.Products = ProductsTable.Ref
	|
	|INDEX BY
	|	IdOfTTRow,
	|	Package,
	|	PackageOwner_";
	
	Result.Add(QueryText, "FillInPackagingOfLowQualityGoods_DataSource");
	
	QueryText =
	"SELECT
	|	DataSource.IdOfTTRow AS IdOfTTRow,
	|	DataSource.ThisIsIndividualSet AS ThisIsIndividualSet,
	|	ISNULL(MAX(PackagingOfLowQualityGoods.Ref),
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package
	|INTO PackagingUnitsOfSubstandardItem
	|FROM
	|	FillInPackagingOfLowQualityGoods_DataSource AS DataSource
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagingOfQualityGoods
	|		ON DataSource.Package = PackagingOfQualityGoods.Ref
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagingOfLowQualityGoods
	|		ON PackagingOfQualityGoods.UnitOfMeasure = PackagingOfLowQualityGoods.UnitOfMeasure
	|		AND PackagingOfQualityGoods.WarehouseGroup = PackagingOfLowQualityGoods.WarehouseGroup
	|		AND DataSource.PackageOwner_ = PackagingOfLowQualityGoods.Owner
	|		AND ISNULL(&QueryTextPackagingFactor1, 1) = ISNULL(&QueryTextPackagingFactor2, 1)
	|GROUP BY
	|	DataSource.IdOfTTRow,
	|	DataSource.ThisIsIndividualSet";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PackagingOfQualityGoods"));
		
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PackagingOfLowQualityGoods"));
	
	Result.Add(QueryText, "PackagingUnitsOfSubstandardItem");
	
	QueryText =
	"SELECT
	|	ResultTable1.IdOfTTRow AS IdOfTTRow,
	|	ResultTable1.ThisIsIndividualSet AS ThisIsIndividualSet,
	|	ResultTable1.Package AS Package
	|FROM
	|	PackagingUnitsOfSubstandardItem AS ResultTable1";
	
	Result.Add(QueryText, "FillInPackagingOfLowQualityGoods");
	
	Return Result;
	
EndFunction

// Returns a list of requests to fill in the item's inventory count.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsFillInAccountingNumberOfItems()
	
	Result = New ValueList;
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	TTDataSource.Products AS Products,
	|	TTDataSource.Package AS Package,
	|	ISNULL(InformationRegisterItemsLocationAttributes.DimensionKey,
	|		VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)) AS DimensionKey
	|INTO ItemTableWithInventoryTrackingAnalytics
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS InformationRegisterItemsLocationAttributes
	|		ON TTDataSource.Products = InformationRegisterItemsLocationAttributes.Products
	|		AND TTDataSource.Characteristic = InformationRegisterItemsLocationAttributes.Characteristic
	|		AND (InformationRegisterItemsLocationAttributes.StorageLocation = &Warehouse)
	|
	|INDEX BY
	|	DimensionKey";
	
	Result.Add(QueryText, "ItemTableWithInventoryTrackingAnalytics");
	
	QueryText =
	"SELECT
	|	Subquery.IdOfTTRow AS IdOfTTRow,
	|	SUM(ISNULL(Subquery.CountBalance, 0) / &QueryTextPackagingFactor) AS Count
	|FROM
	|	(SELECT
	|		TableOfGoods.IdOfTTRow AS IdOfTTRow,
	|		TableOfGoods.Products AS Products,
	|		TableOfGoods.Package AS Package,
	|		CompanyGoods.CountBalance AS CountBalance
	|	FROM
	|		ItemTableWithInventoryTrackingAnalytics AS TableOfGoods
	|			LEFT JOIN AccumulationRegister.CompanyGoods.Balance(&PointInTime, Organization = &Organization
	|			AND ItemsLocationAttributes IN
	|				(SELECT
	|					SetOfAnalyticsKeys.DimensionKey AS DimensionKey
	|				FROM
	|					ItemTableWithInventoryTrackingAnalytics AS SetOfAnalyticsKeys)) AS CompanyGoods
	|			ON TableOfGoods.DimensionKey = CompanyGoods.ItemsLocationAttributes
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableOfGoods.IdOfTTRow,
	|		TableOfGoods.Products,
	|		TableOfGoods.Package,
	|		-CompanyGoods.Count
	|	FROM
	|		ItemTableWithInventoryTrackingAnalytics AS TableOfGoods
	|			LEFT JOIN AccumulationRegister.CompanyGoods AS CompanyGoods
	|			ON CompanyGoods.Recorder = &Recorder
	|			AND TableOfGoods.DimensionKey = CompanyGoods.ItemsLocationAttributes) AS Subquery
	|GROUP BY
	|	Subquery.IdOfTTRow,
	|	Subquery.Products,
	|	Subquery.Package";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingFactorToSelect(
			"Subquery.Package",
			"Subquery.Products"));
	
	Result.Add(QueryText, "FillInAccountingQuantityOfProductItem");
	
	Return Result;
	
EndFunction

// Retrieves a list of requests for recalculating the number of item packages.
//
// Parameters:
// 	QueryOptions - Structure:
// 		* FieldNameQuantity - String - the name of the quantity field in the table part.
// 		* FieldNameNumberOfPackages - String - the name of the number of packages field in the table part.
// 		* TableName - String - the name of the table to include in the query package.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsRecalculateNumberOfPackagingUnits(QueryOptions = Undefined)
	
	If QueryOptions = Undefined Then
		
		FieldNameQuantity = "Count";
		FieldNameNumberOfPackages = "NumberOfPackages";
		TableName = "RecalculateNumberOfPackages";
		
	Else
		
		FieldNameQuantity = CommonClientServer.StructureProperty(
			QueryOptions,
			"FieldNameQuantity",
			"Count");
		
		FieldNameNumberOfPackages = CommonClientServer.StructureProperty(
			QueryOptions,
			"FieldNameNumberOfPackages",
			"NumberOfPackages");
		
		TableName = CommonClientServer.StructureProperty(
			QueryOptions,
			"TableName",
			"RecalculateNumberOfPackages");
		
	EndIf;
	
	Result = New ValueList;
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	&FieldNameNumberOfPackages AS FieldNameNumberOfPackages,
	|	CAST(&FieldNameQuantity AS NUMBER) / CASE
	|		WHEN TTDataSource.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE ISNULL(&QueryTextPackagingFactor, 1)
	|	END AS Count
	|FROM
	|	TTDataSource AS TTDataSource";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingFactorToSelect(
			"TTDataSource.Package",
			"TTDataSource.Products"));
		
	QueryText = StrReplace(QueryText,
		"&FieldNameNumberOfPackages",
		"""" + FieldNameNumberOfPackages + """");
	
	QueryText = StrReplace(QueryText,
		"&FieldNameQuantity",
		StrTemplate("TTDataSource.%1", FieldNameQuantity));
	
	Result.Add(QueryText, TableName);
	
	Return Result;
	
EndFunction

// Returns a list of requests for recalculating the number of packages of an item by weight or volume.
//
// Parameters:
// 	TableName - String - the name of the table to include in the query package.
// 	FieldNameQuantity - String - the name of the quantity field in the table part.
// 	FieldNameNumberOfPackages - String - the name of the number of packages field in the table part.
// 	RecalculationOption - String - the name of the conversion option, Weight, or Volume.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsRecalculateNumberOfPackagingUnitsByWeightVolume(TableName, FieldNameQuantity, FieldNameNumberOfPackages, RecalculationOption)
	
	Result = New ValueList;
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	&FieldNameQuantity AS FieldNameQuantity,
	|	&FieldNameNumberOfPackages AS FieldNameNumberOfPackages,
	|	ISNULL(&NumberOfPackagesField, 0) * ISNULL(&QueryTextPackagingFactor, 1) AS Count,
	|	ISNULL(&NumberOfPackagesField, 0) AS NumberOfPackages,
	|	ISNULL(&QueryTextFactorOfWeightUnitOfMeasure, 0) AS FactorWeight,
	|	ISNULL(&QueryTextFactorOfVolumeUnitOfMeasure, 0) AS FactorVolume
	|FROM
	|	TTDataSource AS TTDataSource";
	
	If RecalculationOption = "Weight" Then
		
		QueryText = StrReplace(QueryText,
			"&NumberOfPackagesField",
			"TTDataSource.Weight * CAST(&QueryTextFactorOfWeightUnitOfMeasure / TTDataSource.PackageWeight AS NUMBER(27, 11))");
		
	ElsIf RecalculationOption = "VolumeM3" Then
		
		QueryText = StrReplace(QueryText,
			"&NumberOfPackagesField",
			"TTDataSource.VolumeM3 * CAST(&QueryTextFactorOfVolumeUnitOfMeasure / TTDataSource.PackageVolume AS NUMBER(27, 11))");
		
	EndIf;
		
	QueryText = StrReplace(QueryText,
		"&QueryTextFactorOfWeightUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingFactorToSelect(
			"TTDataSource.UnitOfMeasureForWeight"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextFactorOfVolumeUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingFactorToSelect(
			"TTDataSource.UnitOfMeasureForVolume"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingFactorToSelect(
			"TTDataSource.Package",
			"TTDataSource.Products"));
	
	QueryText = StrReplace(QueryText,
		"&FieldNameNumberOfPackages",
		"""" + FieldNameNumberOfPackages + """");
	
	QueryText = StrReplace(QueryText,
		"&FieldNameQuantity",
		"""" + FieldNameQuantity + """");
	
	Result.Add(QueryText, TableName);
	
	Return Result;
	
EndFunction

// Returns a list of requests for calculating the Status of specifying series.
//
// Parameters:
// 	FieldNamesStatusOfSeriesIndication - Array of String - the names of the Status columns indicating the series.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsCheckBatchCalculateStatus(FieldNamesStatusOfSeriesIndication)
	
	Result = New ValueList;
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	CASE
	|		WHEN (TableOfSeries.Ref IS NULL 
	|				OR ProductsTable.Ref IS NULL)
	|		THEN
	|			FALSE
	|		ELSE
	|		NOT (TableOfSeries.ProductKind.BatchOwner = ProductsTable.ProductKind.BatchOwner
	|			AND TableOfSeries.ProductKind.BatchOwner <> VALUE(Catalog.ItemKinds.EmptyRef)
	|			AND ProductsTable.ProductKind.BatchOwner <> VALUE(Catalog.ItemKinds.EmptyRef)
	|				OR ProductsTable.BatchOwner = TableOfSeries.ProductKind
	|				OR ProductsTable.ProductKind = TableOfSeries.ProductKind)
	|	END AS DifferentOwnersOfSeriesAndProducts
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN Catalog.Products AS ProductsTable
	|			ON TTDataSource.Products = ProductsTable.Ref
	|		LEFT JOIN Catalog.ItemsBatches AS TableOfSeries
	|			ON TTDataSource.Series = TableOfSeries.Ref";
	
	Result.Add(QueryText, "CheckBatch");
	
	StatusSelectionFields = New Array;
	
	If FieldNamesStatusOfSeriesIndication.Count() = 0 Then
		StatusSelectionFields.Add("TableStatusesOfBatchIndication.BatchesIndicationStatus");
	Else
		
		For Each FieldName In FieldNamesStatusOfSeriesIndication Do
			StatusSelectionFields.Add(StrTemplate("TableStatusesOfBatchIndication.%1 AS %1", FieldName));
		EndDo;
		
	EndIf;
	
	TextOfBatchIndicationStatusField = StrConcat(StatusSelectionFields, "," + Chars.LF + Chars.Tab);
	
	QueryText =
	"SELECT
	|	TableStatusesOfBatchIndication.LineNumber AS LineNumber,
	|	&TextOfBatchIndicationStatusField
	|INTO TableStatusesOfBatchIndication
	|FROM
	|	&TableStatusesOfBatchIndication AS TableStatusesOfBatchIndication";
	
	QueryText = StrReplace(QueryText,
		"&TextOfBatchIndicationStatusField",
		TextOfBatchIndicationStatusField);
	
	Result.Add(QueryText, "TableStatusesOfBatchIndication");
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	&TextOfBatchIndicationStatusField
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN TableStatusesOfBatchIndication AS TableStatusesOfBatchIndication
	|		ON TTDataSource.IdOfTTRow = TableStatusesOfBatchIndication.LineNumber";
	
	QueryText = StrReplace(QueryText,
		"&TextOfBatchIndicationStatusField",
		TextOfBatchIndicationStatusField);
	
	Result.Add(QueryText, "ToCalculateStatus");
	
	Return Result;
	
EndFunction

// Returns a list of requests to check the series by owner.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsCheckBatchByOwner()
	
	Result = New ValueList;
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	CASE
	|		WHEN ProductsTable.ProductKind.KeepAccountingByBatch IS NULL
	|			THEN FALSE
	|		ELSE ProductsTable.ProductKind.KeepAccountingByBatch
	|	END AS SeriesAreUsed,
	|	CASE
	|		WHEN TableOfSeries.Ref IS NULL
	|				OR ProductsTable.Ref IS NULL
	|			THEN TRUE
	|		ELSE
	|			NOT (TableOfSeries.ProductKind.BatchOwner = ProductsTable.ProductKind.BatchOwner
	|				AND TableOfSeries.ProductKind.BatchOwner <> VALUE(Catalog.ItemKinds.EmptyRef)
	|				AND ProductsTable.ProductKind.BatchOwner <> VALUE(Catalog.ItemKinds.EmptyRef)
	|					OR ProductsTable.BatchOwner = TableOfSeries.ProductKind
	|					OR ProductsTable.ProductKind = TableOfSeries.ProductKind
	|				)
	|	END AS DifferentOwnersOfSeriesAndProducts
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN Catalog.Products AS ProductsTable
	|		ON TTDataSource.Products = ProductsTable.Ref
	|		
	|		LEFT JOIN Catalog.ItemsBatches AS TableOfSeries
	|		ON TTDataSource.Series = TableOfSeries.Ref";
	
	Result.Add(QueryText, "CheckBatchByOwner");
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
